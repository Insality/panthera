local tweener = require("tweener.tweener")
local adapter_go = require("panthera.adapters.adapter_go")
local adapter_gui = require("panthera.adapters.adapter_gui")
local panthera_internal = require("panthera.panthera_internal")

---@class panthera.animation
---@field adapter panthera.adapter Adapter to use for animation
---@field speed number Animation speed multiplier
---@field current_time number Current animation time
---@field nodes table Animation nodes used in animation
---@field childs panthera.animation[]? List of active child animations
---@field get_node fun(node_id: string): node Function to get node by node_id
---@field animation_id string? Current animation ID
---@field previous_animation_id string? Previous animation ID
---@field animation_path string Animation path to JSON file
---@field animation_keys_index number Animation keys index
---@field events table? List of events triggered in this animation loop
---@field timer_id number? Timer ID for animation

---@class panthera.options
---@field is_loop boolean? Loop the animation. Triggers the callback at each loop end if set to `true`
---@field is_skip_init boolean? Start animation from its current state, skipping initial setup
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

local TIMER_DELAY = 1/60
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
---@param animation_path_or_data string|table Lua table with animation data or path to JSON animation file in custom resources
---@param collection_name string? Collection name to load nodes from. Pass nil if no collection is used
---@param objects table<string|hash, string|hash>? Table with game objects from collectionfactory. Pass nil if no objects are used
---@return panthera.animation animation Animation state or nil if animation can't be loaded
function M.create_go(animation_path_or_data, collection_name, objects)
	local get_node = adapter_go.create_get_node_function(collection_name, objects)
	return panthera_internal.create_animation_state(animation_path_or_data, adapter_go, get_node)
end


---Load and create a GUI animation state from a Lua table or JSON file.
---@param animation_path_or_data string|table Lua table with animation data or path to JSON animation file in custom resources
---@param template string? The GUI template ID to load nodes from. Pass nil if no template is used
---@param nodes table<string|hash, node>? Table with nodes from gui.clone_tree() function. Pass nil if no nodes are used
---@return panthera.animation animation Animation state or nil if animation can't be loaded
function M.create_gui(animation_path_or_data, template, nodes)
	local get_node = adapter_gui.create_get_node_function(template, nodes)
	return panthera_internal.create_animation_state(animation_path_or_data, adapter_gui, get_node)
end


---Load an animation from a Lua table or JSON file and create an animation state using a specified adapter.
---@param animation_path_or_data string|table Lua table with animation data or path to JSON animation file in custom resources
---@param adapter panthera.adapter An adapter object that specifies how Panthera Runtime interacts with Engine
---@param get_node (fun(node_id: string): node) Function to get node by node_id. A custom function to resolve nodes by their ID
---@return panthera.animation animation Animation state or nil if animation can't be loaded
function M.create(animation_path_or_data, adapter, get_node)
	return panthera_internal.create_animation_state(animation_path_or_data, adapter, get_node)
end


---Clone an existing animation state object, enabling multiple instances of the same animation to play simultaneously or independently.
---@param animation_state panthera.animation The animation state object to clone
---@return panthera.animation? New animation state object that is a copy of the original
function M.clone_state(animation_state)
	local adapter = animation_state.adapter
	local get_node = animation_state.get_node
	local animation_path = animation_state.animation_path

	return panthera_internal.create_animation_state(animation_path, adapter, get_node)
end


---Play an animation with specified ID and options.
---@param animation_state panthera.animation The animation state object returned by `create_go` or `create_gui`
---@param animation_id string The ID of the animation to play
---@param options panthera.options? Options for the animation playback
function M.play(animation_state, animation_id, options)
	assert(animation_state, "Can't play animation, animation_state is nil")
	options = options or EMPTY_OPTIONS

	local animation_data = panthera_internal.get_animation_data(animation_state)
	if not animation_data then
		panthera_internal.logger:error("Can't play animation, animation_data is nil", {
			animation_path = animation_state.animation_path,
			animation_id = animation_id,
		})
		return nil
	end

	local animation = panthera_internal.get_animation_by_animation_id(animation_data, animation_id)
	if not animation then
		panthera_internal.logger:error("Animation is not found", {
			animation_path = animation_state.animation_path,
			binded_to = animation_data.metadata and animation_data.metadata.gui_path,
			animation_id = animation_id,
		})
		return nil
	end

	if options.easing and options.easing ~= "linear" then
		local tweener_options = options --[[@as panthera.options_tweener]]

		M.play_tweener(animation_state, animation_id, tweener_options)
		return nil
	end

	if animation_state.animation_id then
		M.stop(animation_state)
	end

	animation_state.animation_id = animation.animation_id
	animation_state.animation_keys_index = 1
	animation_state.events = nil

	if not options.is_skip_init then
		-- Reset all previuosly animated nodes to initial state
		if animation_state.previous_animation_id then
			panthera_internal.reset_animation_state(animation_state, animation_state.previous_animation_id)
			animation_state.previous_animation_id = nil
		end

		-- If we have initial animation, we should set up it here?
		if animation.initial_state then
			local initial_animation = panthera_internal.get_animation_by_animation_id(animation_data, animation.initial_state)
			if initial_animation then
				panthera_internal.set_animation_state_at_time(animation_state, initial_animation.animation_id, initial_animation.duration)
			end
		end

		panthera_internal.set_animation_state_at_time(animation_state, animation.animation_id, 0)
	end

	-- Start animation update timer
	local last_time = socket.gettime()
	animation_state.timer_id = timer.delay(TIMER_DELAY, true, function()
		local current_time = socket.gettime()
		local dt = current_time - last_time

		if dt < 0.001 then
			return
		end

		last_time = current_time
		local speed = (options.speed or 1) * animation_state.speed * M.SPEED

		animation_state.current_time = animation_state.current_time + dt * speed
		M.update_animation(animation, animation_state, options)
	end)
	timer.trigger(animation_state.timer_id)
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

	local animation_data = panthera_internal.get_animation_data(animation_state)
	if not animation_data then
		panthera_internal.logger:warn("Can't play animation, animation_data is nil", {
			animation_path = animation_state.animation_path,
			animation_id = animation_id,
		})
		return nil
	end

	local animation = panthera_internal.get_animation_by_animation_id(animation_data, animation_id)
	if not animation then
		panthera_internal.logger:warn("Animation is not found", {
			animation_path = animation_state.animation_path,
			animation_meta = animation_data.metadata and animation_data.metadata.gui_path,
			animation_id = animation_id,
		})
		return nil
	end

	local easing = options.easing or tweener.linear
	animation_state.events = nil

	local total_duration = animation.duration / (options.speed or 1)
	local from = options.from or 0
	local to = options.to or animation.duration

	if animation_state.timer_id then
		timer.cancel(animation_state.timer_id)
		animation_state.timer_id = nil
	end

	animation_state.timer_id = tweener.tween(easing, from, to, total_duration, function(time, is_final_call)
		-- Off cause it stops current animation state
		--M.set_time(animation_state, animation_id, time, options.callback_event)

		do -- TODO: it's a copy paste from `M:play`, make better this little piece
			if animation_state.previous_animation_id then
				panthera_internal.reset_animation_state(animation_state, animation_state.previous_animation_id)
				animation_state.previous_animation_id = nil
			end

			if animation_state.current_time > time then
				-- We count this as a new animation loop, we want to update animation state data
				animation_state.events = nil
			end

			animation_state.current_time = time
			animation_state.animation_id = animation.animation_id
			animation_state.animation_keys_index = 1

			panthera_internal.set_animation_state_at_time(animation_state, animation.animation_id, time, options.callback_event)
		end

		if is_final_call then
			if options.callback then
				options.callback(animation_id)
			end

			if options.is_loop then
				M.play_tweener(animation_state, animation_id, options)
			end
		end
	end).timer_id

	timer.trigger(animation_state.timer_id)
end


---@private
---@param animation panthera.animation.data.animation
---@param animation_state panthera.animation
---@param options panthera.options
function M.update_animation(animation, animation_state, options)
	if not animation then
		return
	end

	local keys = animation.animation_keys
	-- Process from the last processed key until the current time
	for index = animation_state.animation_keys_index, #keys do
		local key = keys[index]

		if key.start_time <= animation_state.current_time then
			animation_state.animation_keys_index = index + 1

			if key.key_type ~= panthera_internal.KEY_TYPE.ANIMATION then
				local speed = (options.speed or 1) * animation_state.speed * M.SPEED
				panthera_internal.run_timeline_key(animation_state, key, options, speed)
			else
				-- check if "" while only animation keys are working now
				if key.node_id == "" then
					local child_state = M.clone_state(animation_state)
					-- Time Overflow
					local time_overflow = math.max(0, animation_state.current_time - key.start_time)
					child_state.current_time = time_overflow

					animation_state.childs = animation_state.childs or {}
					table.insert(animation_state.childs, child_state)
					local animation_duration = M.get_duration(child_state, key.property_id)

					local key_duration = (key.duration - time_overflow)
					-- TODO: Do we need set time if key_duration is <= 0?
					if animation_duration > 0 and key_duration > 0 then
						local speed = (options.speed or 1) * animation_state.speed * M.SPEED
						local play_speed = (animation_duration / key_duration) * speed

						M.play(child_state, key.property_id, {
							easing = key.easing,
							is_skip_init = false, -- Editor works in "false" mode always, so until editor support this, we should use false
							speed = play_speed,
							callback = function()
								panthera_internal.remove_child_animation(animation_state, child_state)
							end
						})
					end
				end

				-- This is tempalte animations, the node_id is a template to run the new animations
				if key.node_id ~= "" then
					local animation_data = panthera_internal.get_animation_data(animation_state)
					local paths = animation_data and animation_data.metadata.template_animation_paths
					if not paths then
						break
					end
					local template_animation_path = paths[key.node_id]

					local get_node = function(node_id)
						return animation_state.get_node(key.node_id .. "/" .. node_id)
					end
					local template_state = panthera_internal.create_animation_state(template_animation_path, animation_state.adapter, get_node)

					local time_overflow = math.max(0, animation_state.current_time - key.start_time)
					template_state.current_time = time_overflow

					animation_state.childs = animation_state.childs or {}
					table.insert(animation_state.childs, template_state)
					local animation_duration = M.get_duration(template_state, key.property_id)

					if animation_duration > 0 and key.duration > 0 then
						local speed = (options.speed or 1) * animation_state.speed * M.SPEED
						local key_duration = (key.duration - time_overflow)
						local play_speed = (animation_duration / key_duration) * speed

						M.play(template_state, key.property_id, {
							-- TODO: is any cases when we want to use false here? Editor works like it false now
							-- Real case: looped animation should be reset to correct visuals
							is_skip_init = false, -- Editor works in "false" mode always, so until editor support this, we should use false
							easing = key.easing,
							speed = play_speed,
							callback = function()
								panthera_internal.remove_child_animation(animation_state, template_state)
							end,
							callback_event = options.callback_event
						})
					end
				end
			end
		else
			break
		end
	end

	-- If current time >= animation duration - stop animation
	if animation_state.current_time >= animation.duration then
		local time_overflow = animation_state.current_time - animation.duration
		M.stop(animation_state)

		if options.callback then
			options.callback(animation.animation_id)
		end

		if options.is_loop then
			-- Compensate the time overflow
			animation_state.current_time = time_overflow
			M.play(animation_state, animation.animation_id, options)
		end
	end
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
	local animation_data = panthera_internal.get_animation_data(animation_state)
	if not animation_data then
		panthera_internal.logger:warn("Can't set time, animation_data is nil", {
			animation_path = animation_state.animation_path,
			animation_id = animation_id
		})
		return false
	end

	local animation = panthera_internal.get_animation_by_animation_id(animation_data, animation_id)
	if not animation then
		panthera_internal.logger:warn("Animation is not found", {
			animation_path = animation_state.animation_path,
			animation_id = animation_id
		})
		return false
	end

	-- TODO: What if we don't stop animations?
	if M.is_playing(animation_state) then
		M.stop(animation_state)
	end

	if animation_state.previous_animation_id then
		panthera_internal.reset_animation_state(animation_state, animation_state.previous_animation_id)
		animation_state.previous_animation_id = nil
	end

	if animation_state.current_time > time then
		-- We count this as a new animation loop, we want to update animation state data
		animation_state.events = nil
	end

	animation_state.current_time = time
	animation_state.animation_id = animation.animation_id
	animation_state.animation_keys_index = 1

	panthera_internal.set_animation_state_at_time(animation_state, animation.animation_id, time, event_callback)

	return true
end


---Retrieve the current playback time in seconds of an animation. If the animation is not playing, the function returns 0.
---@param animation_state panthera.animation The animation state object
---@return number Current animation time in seconds
function M.get_time(animation_state)
	return animation_state.current_time
end


---Stop a currently playing animation. The animation will be stopped at current time.
---@param animation_state panthera.animation The animation state object to stop
---@return boolean True if animation was stopped, false if animation is not playing
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
---@return number The total duration of the animation in seconds
function M.get_duration(animation_state, animation_id)
	local animation_data = panthera_internal.get_animation_data(animation_state)
	assert(animation_data, "Animation data is not loaded")

	local animation = panthera_internal.get_animation_by_animation_id(animation_data, animation_id)
	assert(animation, "Animation is not found: " .. animation_id)

	return animation.duration
end


---Check if an animation is currently playing.
---@param animation_state panthera.animation The animation state object
---@return boolean True if the animation is currently playing, false otherwise
function M.is_playing(animation_state)
	return animation_state.timer_id ~= nil
end


---Get the ID of the last animation that was started.
---@param animation_state panthera.animation The animation state object
---@return string? Animation ID or nil if no animation was started
function M.get_latest_animation_id(animation_state)
	return animation_state.animation_id or animation_state.previous_animation_id
end


---Return a list of animation IDs from the created animation state.
---@param animation_state panthera.animation The animation state object
---@return string[] Array of animation IDs available in the animation state
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
		for path in pairs(panthera_internal.LOADED_ANIMATIONS) do
			panthera_internal.load(path, true)
		end
	end
end


return M
