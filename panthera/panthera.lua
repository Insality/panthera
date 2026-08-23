local tweener = require("tweener.tweener")
local adapter_go = require("panthera.adapters.adapter_go")
local adapter_gui = require("panthera.adapters.adapter_gui")
local panthera_internal = require("panthera.panthera_internal")

---@class panthera.collect_context
---@field values panthera.animation.state_value[] Collected values
---@field pool panthera.animation.state_value[] Released value objects
---@field event_callback (fun(event_id: string, node: node?, data: any, end_value: number))?

---@class panthera.collect_buffer
---@field pool panthera.animation.state_value[] Released value objects
---@field context panthera.collect_context Context of a non nested sample
---@field depth number Sample nesting depth

---@class panthera.animation
---@field adapter panthera.adapter Adapter to use for animation
---@field speed number Animation speed multiplier
---@field current_time number Current animation time
---@field nodes table Animation nodes used in animation
---@field childs panthera.animation[]? Detached child animations, each with its own timer
---@field clips panthera.animation[]? Running animation key clips, driven by this state
---@field get_node fun(node_id: string): node Function to get node by node_id
---@field animation_id string? Current animation ID
---@field previous_animation_id string? Previous animation ID
---@field animation_path string Animation path to JSON file
---@field animation_keys_index number Animation keys index
---@field events table? List of events triggered in this animation loop
---@field template_states table<string, panthera.animation>? Cached animation states of the template nodes
---@field collect_buffer panthera.collect_buffer? Reused collect buffers of this state
---@field timer_id number? Timer ID for animation, a clip has none
---@field play_animation panthera.animation.data.animation? Current playback animation
---@field play_options panthera.options? Current playback options
---@field play_sample_depth number? Current playback sample depth

---@class panthera.options
---@field is_loop boolean? Loop the animation. Triggers the callback at each loop end if set to `true`
---@field is_skip_init boolean? Start animation from its current state, skipping initial setup
---@field is_detached boolean? Play animation as a detached child of the current animation state, allowing multiple animations to run independently and simultaneously.
---@field speed number? Playback speed multiplier (default `1`). Values >1 increase speed, <1 decrease
---@field easing string|constant? Easing function for animation. Will use tweener for non-linear animation (slower performance)
---@field callback (fun(animation_id: string):nil)? Function called when the animation finishes. Receives `animation_id`
---@field callback_event (fun(event_id: string, node: node?, string_value: string, number_value: number): nil)? Function triggered by animation events

---@class panthera.options_tweener
---@field speed number|nil Animation speed multiplier, default is 1
---@field is_loop boolean|nil If true, the animation will loop with trigger callback each loop
---@field easing string|constant|nil Easing function for play animation with. Works currently only on play_tweener
---@field callback (fun(animation_id: string):nil)|nil Callback when animation is finished
---@field callback_event (fun(event_id: string, node: node|nil, string_value: string, number_value: number): nil)|nil Callback when animation trigger event
---@field is_reverse boolean|nil If true, the animation will play in reverse
---@field from number|nil Start value for tween animation
---@field to number|nil End value for tween animation

---@class panthera
---@field SPEED number Default speed of all animations
local M = {
	SPEED = 1
}

-- 0 = every frame. 1/60 skips frames and makes the playback stutter
local TIMER_DELAY = 0
local EMPTY_OPTIONS = {}

-- Set of predefined options
M.OPTIONS_LOOP = { is_loop = true }
M.OPTIONS_SKIP_INIT = { is_skip_init = true }
M.OPTIONS_SKIP_INIT_LOOP = { is_skip_init = true, is_loop = true }


---Customize the logging mechanism used by Panthera Runtime. You can use Defold Log library or provide a custom logger.
---@param logger_instance panthera.logger|table? A logger object that follows the specified logging interface. Pass nil to use empty logger
function M.set_logger(logger_instance)
	panthera_internal.logger = logger_instance or panthera_internal.empty_logger
end


---Load and create a game object animation state from a Lua table or JSON file.
---@param animation_or_path string|table Lua table with animation data or path to JSON animation file in custom resources
---@param collection_name string? Collection name to load nodes from. Pass nil if no collection is used
---@param objects table<string|hash, string|hash>? Table with game objects from collectionfactory. Pass nil if no objects are used
---@return panthera.animation animation New animation state object
function M.create_go(animation_or_path, collection_name, objects)
	local get_node = adapter_go.create_get_node_function(collection_name, objects)
	return panthera_internal.create_animation_state(animation_or_path, adapter_go, get_node)
end


---Load and create a GUI animation state from a Lua table or JSON file.
---@param animation_or_path string|table Lua table with animation data or path to JSON animation file in custom resources
---@param template string? The GUI template ID to load nodes from. Pass nil if no template is used
---@param nodes table<string|hash, node>? Table with nodes from gui.clone_tree() function. Pass nil if no nodes are used
---@return panthera.animation animation New animation state object
function M.create_gui(animation_or_path, template, nodes)
	local get_node = adapter_gui.create_get_node_function(template, nodes)
	return panthera_internal.create_animation_state(animation_or_path, adapter_gui, get_node)
end


---Load an animation from a Lua table or JSON file and create an animation state using a specified adapter.
---@param animation_or_path string|table Lua table with animation data or path to JSON animation file in custom resources
---@param adapter panthera.adapter An adapter object that specifies how Panthera Runtime interacts with Engine
---@param get_node (fun(node_id: string): node) Function to get node by node_id. A custom function to resolve nodes by their ID
---@return panthera.animation animation New animation state object
function M.create(animation_or_path, adapter, get_node)
	return panthera_internal.create_animation_state(animation_or_path, adapter, get_node)
end


---Clone an existing animation state object, enabling multiple instances of the same animation to play simultaneously or independently.
---@param animation_state panthera.animation The animation state object to clone
---@return panthera.animation animation New animation state object that is a copy of the original
function M.clone_state(animation_state)
	local adapter = animation_state.adapter
	local get_node = animation_state.get_node
	local animation_path = animation_state.animation_path

	return panthera_internal.create_animation_state(animation_path, adapter, get_node)
end


---Play an animation with specified ID and options.
---One timer drives the whole tree, each tick finishes the running clips before starting new ones.
---@param animation_state panthera.animation The animation state object returned by `create_go` or `create_gui`
---@param animation_id string The ID of the animation to play
---@param options panthera.options? Options for the animation playback
function M.play(animation_state, animation_id, options)
	assert(animation_state, "Can't play animation, animation_state is nil")
	options = options or EMPTY_OPTIONS

	local animation, animation_data = M._find_animation(animation_state, animation_id)
	if not animation then
		panthera_internal.logger:error("Animation is not found", M._animation_log_data(animation_state, animation_data, animation_id))
		return nil
	end

	if options.easing and options.easing ~= "linear" then
		local tweener_options = options --[[@as panthera.options_tweener]]
		M.play_tweener(animation_state, animation_id, tweener_options)
		return nil
	end

	local is_playing = M._start_playback(animation_state, animation, options, panthera_internal.SAMPLE_DEPTH_ROOT)
	if not is_playing then
		return nil
	end

	animation_state.timer_id = timer.delay(TIMER_DELAY, true, function(_, _, time_elapsed)
		if time_elapsed < 0.001 then
			return
		end

		M.update_animation(animation_state, time_elapsed)
	end)
end


---Play animation with easing support using tweener. Allows for non-linear animation playback with custom easing functions.
---@param animation_state panthera.animation The animation state object
---@param animation_id string The ID of the animation to play
---@param options panthera.options_tweener? Options including easing function, speed, and callbacks
function M.play_tweener(animation_state, animation_id, options)
	options = options or EMPTY_OPTIONS

	if not animation_state then
		panthera_internal.logger:error("Can't play animation, animation_state is nil")
		return nil
	end

	local animation, animation_data = M._find_animation(animation_state, animation_id)
	if not animation_data then
		M._log_missing_animation(animation_state, animation_data, animation_id, "Can't play animation, animation_data is nil")
		return nil
	end
	if not animation then
		M._log_missing_animation(animation_state, animation_data, animation_id, "Animation is not found")
		return nil
	end

	local easing = options.easing or tweener.linear
	panthera_internal.reset_animation_events(animation_state)

	local total_duration = animation.duration / (options.speed or 1)
	local from = options.from or 0
	local to = options.to or animation.duration

	if animation_state.timer_id then
		timer.cancel(animation_state.timer_id)
		animation_state.timer_id = nil
	end

	animation_state.timer_id = tweener.tween(easing, from, to, total_duration, function(time, is_final_call)
		panthera_internal.apply_sample(animation_state, animation.animation_id, time, options.callback_event)

		if not is_final_call then
			return
		end
		if options.callback then
			options.callback(animation_id)
		end
		if options.is_loop then
			M.play_tweener(animation_state, animation_id, options)
		end
	end).timer_id

	timer.trigger(animation_state.timer_id)
end


---Advance a playing state by one frame
---@private
---@param animation_state panthera.animation
---@param time_elapsed number Real seconds since the last frame
function M.update_animation(animation_state, time_elapsed)
	local animation = animation_state.play_animation
	if not animation or not animation_state.animation_id then
		return
	end

	local options = animation_state.play_options or EMPTY_OPTIONS
	local speed = M._playback_speed(options, animation_state)
	animation_state.current_time = animation_state.current_time + time_elapsed * speed

	-- Update inner clips
	M._update_clips(animation_state, time_elapsed)

	-- Start keys
	local keys = animation.animation_keys
	for index = animation_state.animation_keys_index, #keys do
		local key = keys[index]
		if not panthera_internal.is_key_started(key, animation_state.current_time) then
			break
		end

		animation_state.animation_keys_index = index + 1
		if key.key_type == panthera_internal.KEY_TYPE.ANIMATION then
			M.start_animation_key(animation_state, key, options)
		else
			panthera_internal.run_timeline_key(animation_state, key, options, speed)
		end
	end

	-- End of an animation
	if animation_state.current_time >= animation.duration then
		local time_overflow = animation_state.current_time - animation.duration
		panthera_internal.set_animation_state_at_time(animation_state, animation.animation_id, animation.duration, nil, animation_state.play_sample_depth)
		M.stop(animation_state)

		if options.callback then
			options.callback(animation.animation_id)
		end
		if options.is_loop then
			animation_state.current_time = time_overflow
			M.play(animation_state, animation.animation_id, options)
		end
	end
end


---Advance the running clips, drop the finished ones
---@private
---@param animation_state panthera.animation
---@param time_elapsed number
function M._update_clips(animation_state, time_elapsed)
	local clips = animation_state.clips
	if not clips then
		return
	end

	-- Compact in place, a callback can drop the list under us
	local write_index = 1
	for index = 1, #clips do
		local clip_state = clips[index]
		if not clip_state then
			break
		end

		M.update_animation(clip_state, time_elapsed)
		clips[index] = nil
		if clip_state.animation_id then
			clips[write_index] = clip_state
			write_index = write_index + 1
		end
	end
end


---Start a nested (`node_id == ""`) or template animation key
---@private
---@param animation_state panthera.animation
---@param key panthera.animation.data.animation_key
---@param options panthera.options
function M.start_animation_key(animation_state, key, options)
	local clip_state = M._create_clip_state(animation_state, key)
	if not clip_state then
		return
	end

	local clip_animation, clip_data = M._find_animation(clip_state, key.property_id)
	if not clip_animation then
		M._log_missing_animation(clip_state, clip_data, key.property_id, "Animation of the animation key is not found")
		return
	end
	if clip_animation.duration <= 0 then
		return
	end

	local time_overflow = math.max(0, animation_state.current_time - key.start_time)
	local key_duration = key.duration - time_overflow
	if key_duration <= 0 then
		-- Key already over: set final state
		panthera_internal.set_animation_state_at_time(clip_state, key.property_id, clip_animation.duration,
			options.callback_event, panthera_internal.SAMPLE_DEPTH_CLIP)
		return
	end

	local clip_options = {
		easing = key.easing,
		callback_event = options.callback_event,
		-- Fit the animation into the key duration, `M.SPEED` is applied by the clip tick
		speed = (clip_animation.duration / key_duration) * M._local_speed(options, animation_state),
	}

	local is_playing = M._start_playback(clip_state, clip_animation, clip_options,
		panthera_internal.SAMPLE_DEPTH_CLIP, time_overflow)
	if not is_playing then
		return
	end

	local clips = animation_state.clips
	if not clips then
		clips = {}
		animation_state.clips = clips
	end
	clips[#clips + 1] = clip_state
end


---Play animation as a child of the current animation state, allowing multiple animations to run independently and simultaneously.
---
---This creates a detached animation that runs in parallel with the main animation state without affecting it.
---The child animation will be automatically cleaned up when it completes.
---@param animation_state panthera.animation The parent animation state object
---@param animation_id string The ID of the animation to play as a detached child
---@param options panthera.options? Options for the detached animation playback
function M.play_detached(animation_state, animation_id, options)
	options = options or EMPTY_OPTIONS

	local child_state = M.clone_state(animation_state)
	if not child_state then
		return
	end

	animation_state.childs = animation_state.childs or {}
	table.insert(animation_state.childs, child_state)

	M.play(child_state, animation_id, {
		is_skip_init = options.is_skip_init,
		speed = options.speed,
		is_loop = options.is_loop,
		callback = function(...)
			if options.callback then
				options.callback(...)
			end
			panthera_internal.remove_child_animation(animation_state, child_state)
		end
	})
end


---Set the current time of an animation. This function stops any currently playing animation.
---@param animation_state panthera.animation The animation state object returned by `create_go` or `create_gui`.
---@param animation_id string The ID of the animation to modify.
---@param time number The target time in seconds to which the animation should be set.
---@param event_callback fun(event_id: string, node: node|nil, string_value: string, number_value: number)|nil
---@return boolean result True if animation state was set successfully, false if animation can't be set
function M.set_time(animation_state, animation_id, time, event_callback)
	local animation, animation_data = M._find_animation(animation_state, animation_id)
	if not animation_data then
		M._log_missing_animation(animation_state, animation_data, animation_id, "Can't set time, animation_data is nil")
		return false
	end
	if not animation then
		M._log_missing_animation(animation_state, animation_data, animation_id, "Animation is not found")
		return false
	end

	-- TODO: What if we don't stop animations?
	if M.is_playing(animation_state) then
		M.stop(animation_state)
	end

	panthera_internal.apply_sample(animation_state, animation.animation_id, time, event_callback)
	return true
end


---Retrieve the current playback time in seconds of an animation. If the animation is not playing, the function returns 0.
---@param animation_state panthera.animation The animation state object
---@return number seconds Current animation time in seconds
function M.get_time(animation_state)
	return animation_state.current_time
end


---Stop a currently playing animation. The animation will be stopped at current time.
---@param animation_state panthera.animation The animation state object to stop
---@return boolean is_stopped True if animation was stopped, false if animation is not playing
function M.stop(animation_state)
	if not animation_state then
		panthera_internal.logger:warn("Can't stop animation, animation_state is nil")
		return false
	end

	if animation_state.timer_id then
		timer.cancel(animation_state.timer_id)
		animation_state.timer_id = nil
	end

	local previous_animation_id = animation_state.animation_id
	animation_state.previous_animation_id = previous_animation_id

	-- Stop all tweens started by animation
	if previous_animation_id then
		panthera_internal.stop_tweens(animation_state, previous_animation_id)
	end

	animation_state.animation_id = nil
	animation_state.current_time = 0
	animation_state.animation_keys_index = 1

	local clips = animation_state.clips
	if clips then
		for index = #clips, 1, -1 do
			M.stop(clips[index])
			clips[index] = nil
		end
	end

	if animation_state.childs then
		for index = 1, #animation_state.childs do
			M.stop(animation_state.childs[index])
		end
	end

	return true
end


---Retrieve the total duration of a specific animation.
---@param animation_state panthera.animation The animation state object
---@param animation_id string The ID of the animation whose duration you want to retrieve
---@return number seconds The total duration of the animation in seconds
function M.get_duration(animation_state, animation_id)
	local animation, animation_data = M._find_animation(animation_state, animation_id)
	assert(animation_data, "Animation data is not loaded")
	assert(animation, "Animation is not found: " .. animation_id)
	return animation.duration
end


---Check if an animation is currently playing.
---@param animation_state panthera.animation The animation state object
---@return boolean is_playing True if the animation is currently playing, false otherwise
function M.is_playing(animation_state)
	return animation_state.timer_id ~= nil
end


---Get the ID of the last animation that was started.
---@param animation_state panthera.animation The animation state object
---@return string? animation_id Animation ID or nil if no animation was started
function M.get_latest_animation_id(animation_state)
	return animation_state.animation_id or animation_state.previous_animation_id
end


---Return a list of animation IDs from the created animation state.
---@param animation_state panthera.animation The animation state object
---@return string[] animation_ids Array of animation IDs available in the animation state
function M.get_animations(animation_state)
	local animation_data = panthera_internal.get_animation_data(animation_state)
	if not animation_data then
		return {}
	end

	local animations = {}
	for index = 1, #animation_data.animations do
		local animation_id = animation_data.animations[index].animation_id
		table.insert(animations, animation_id)
	end

	return animations
end


---Reload animations from JSON files, useful for development and debugging.
---
---The animations loaded from Lua tables will not be reloaded.
---Animation will be reloaded only at desktop.
---@param animation_path string? Specific animation to reload. If omitted, all loaded animations are reloaded
function M.reload_animation(animation_path)
	if animation_path then
		panthera_internal.load(animation_path, true)
	else
		-- Collect paths first, reloading replaces the keys in the table we would iterate over
		local paths = {}
		for path in pairs(panthera_internal.LOADED_ANIMATIONS) do
			table.insert(paths, path)
		end

		for index = 1, #paths do
			panthera_internal.load(paths[index], true)
		end
	end
end


---Speed without `M.SPEED`, the tick applies it once
---@param options panthera.options
---@param animation_state panthera.animation
---@return number
function M._local_speed(options, animation_state)
	return (options.speed or 1) * animation_state.speed
end


---@param options panthera.options
---@param animation_state panthera.animation
---@return number
function M._playback_speed(options, animation_state)
	return M._local_speed(options, animation_state) * M.SPEED
end


---Set the state up and run its first frame. No timer here, a clip is driven by its parent
---@private
---@param animation_state panthera.animation
---@param animation panthera.animation.data.animation
---@param options panthera.options
---@param sample_depth number
---@param start_time number? Time to start from, the time left in the state by default
---@return boolean is_playing False if the animation is over already
function M._start_playback(animation_state, animation, options, sample_depth, start_time)
	if animation_state.animation_id then
		M.stop(animation_state)
	end

	-- `stop` and the init sample reset the time, keep the overflow aside
	start_time = start_time or animation_state.current_time

	animation_state.play_animation = animation
	animation_state.play_options = options
	animation_state.play_sample_depth = sample_depth
	animation_state.animation_id = animation.animation_id
	animation_state.animation_keys_index = 1
	panthera_internal.reset_animation_events(animation_state)

	if not options.is_skip_init then
		panthera_internal.apply_sample(animation_state, animation.animation_id, 0, nil, sample_depth)
	end
	animation_state.current_time = start_time

	-- Run the first frame now, so clips don't wait for the next tick
	M.update_animation(animation_state, 0)

	return animation_state.animation_id ~= nil
end


---@param animation_state panthera.animation
---@param animation_id string
---@return panthera.animation.data.animation|nil
---@return panthera.animation.data|nil
function M._find_animation(animation_state, animation_id)
	local animation_data = panthera_internal.get_animation_data(animation_state)
	local animation = animation_data and panthera_internal.get_animation_by_animation_id(animation_data, animation_id)
	return animation, animation_data
end


---@param animation_state panthera.animation
---@param animation_data panthera.animation.data|nil
---@param animation_id string
---@return table
function M._animation_log_data(animation_state, animation_data, animation_id)
	return {
		animation_path = animation_state.animation_path,
		binded_to = animation_data and animation_data.metadata and animation_data.metadata.gui_path,
		animation_id = animation_id,
	}
end


---@param animation_state panthera.animation
---@param animation_data panthera.animation.data|nil
---@param animation_id string
---@param message string
function M._log_missing_animation(animation_state, animation_data, animation_id, message)
	panthera_internal.logger:warn(message, M._animation_log_data(animation_state, animation_data, animation_id))
end


---Clip state for an animation key: a clone for nested, a template state otherwise
---@private
---@param animation_state panthera.animation
---@param key panthera.animation.data.animation_key
---@return panthera.animation|nil
function M._create_clip_state(animation_state, key)
	if key.node_id == "" then
		return M.clone_state(animation_state)
	end

	local animation_data = panthera_internal.get_animation_data(animation_state)
	local template_path = animation_data and panthera_internal.get_template_animation_path(animation_data, key.node_id)
	if not template_path then
		return nil
	end

	local get_node = function(node_id)
		return animation_state.get_node(key.node_id .. "/" .. node_id)
	end
	return panthera_internal.create_animation_state(template_path, animation_state.adapter, get_node)
end


return M
