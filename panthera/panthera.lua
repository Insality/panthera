local tweener = require("tweener.tweener")
local adapter_go = require("panthera.adapters.adapter_go")
local adapter_gui = require("panthera.adapters.adapter_gui")
local panthera_internal = require("panthera.panthera_internal")

---@class panthera
---@field SPEED number Default speed of all animations
local M = {
	SPEED = 1
}

local TIMER_DELAY = 1/60
local EMPTY_OPTIONS = {}


---Customize the logging mechanism used by **Panthera Runtime**. You can use **Defold Log** library or provide a custom logger.
---@param logger_instance panthera.logger|table|nil
function M.set_logger(logger_instance)
	panthera_internal.logger = logger_instance or panthera_internal.empty_logger
end


---Load animation from JSON file or direct data and create it with Panthera GO adapter
---@param animation_path_or_data string|table Path to JSON animation file in custom resources or table with animation data
---@param collection_name string|nil Collection name to load nodes from. Pass nil if no collection is used
---@param objects table<string|hash, string|hash>|nil Table with game objects from collectionfactory. Pass nil if no objects are used
---@return panthera.animation Animation data or nil if animation can't be loaded, error message
function M.create_go(animation_path_or_data, collection_name, objects)
	local get_node = adapter_go.create_get_node_function(collection_name, objects)
	return panthera_internal.create_animation_state(animation_path_or_data, adapter_go, get_node)
end


---Load animation from JSON file or direct data and create it with Panthera GUI adapter
---@param animation_path_or_data string|table Path to JSON animation file in custom resources or table with animation data
---@param template string|nil The GUI template id to load nodes from. Pass nil if no template is used
---@param nodes table<string|hash, node>|nil Table with nodes from gui.clone_tree() function. Pass nil if no nodes are used
---@return panthera.animation Animation data or nil if animation can't be loaded, error message
function M.create_gui(animation_path_or_data, template, nodes)
	local get_node = adapter_gui.create_get_node_function(template, nodes)
	return panthera_internal.create_animation_state(animation_path_or_data, adapter_gui, get_node)
end


---Load animation from JSON file
---@param animation_path_or_data string|table Path to JSON animation file in custom resources or table with animation data
---@param adapter panthera.adapter
---@param get_node (fun(node_id: string): node) Function to get node by node_id. Default is defined in adapter
---@return panthera.animation Animation data or nil if animation can't be loaded, error message
function M.create(animation_path_or_data, adapter, get_node)
	return panthera_internal.create_animation_state(animation_path_or_data, adapter, get_node)
end


---Create identical copy of animation state to run it in parallel
---@param animation_state panthera.animation
---@return panthera.animation New animation state or nil if animation can't be cloned
function M.clone_state(animation_state)
	local adapter = animation_state.adapter
	local get_node = animation_state.get_node
	local animation_path = animation_state.animation_path

	return panthera_internal.create_animation_state(animation_path, adapter, get_node)
end


---@param animation_state panthera.animation
---@param animation_id string
---@param options panthera.options|nil
function M.play(animation_state, animation_id, options)
	options = options or EMPTY_OPTIONS

	if not animation_state then
		panthera_internal.logger:error("Can't play animation, animation_state is nil")
		return
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
		last_time = current_time
		local speed = (options.speed or 1) * animation_state.speed * M.SPEED

		animation_state.current_time = animation_state.current_time + dt * speed
		M.update_animation(animation, animation_state, options)
	end)
	timer.trigger(animation_state.timer_id)
end


-- TODO: make it inside play somehow
---@param animation_state panthera.animation
---@param animation_id string
---@param options panthera.options_tweener|nil
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
	if options.is_reverse then
		from, to = to, from
	end

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

					if animation_duration > 0 and key.duration > 0 then
						local speed = (options.speed or 1) * animation_state.speed * M.SPEED
						local key_duration = (key.duration - time_overflow)
						local play_speed = (animation_duration / key_duration) * speed

						M.play(child_state, key.property_id, {
							easing = key.easing,
							is_skip_init = true,
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
							is_skip_init = false,
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


-- TODO: make it inside play somehow
---Play animation as a child of the current animation state
---@param animation_state panthera.animation
---@param animation_id string
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


---Set animation state at specific time. This will stop animation if it's playing
---@param animation_state panthera.animation
---@param animation_id string
---@param time number
---@param event_callback fun(event_id: string, node: node|nil, string_value: string, number_value: number)|nil
---@return boolean result Animation state or nil if animation can't be set
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
---@param animation_state panthera.animation
---@return number Current animation time in seconds
function M.get_time(animation_state)
	return animation_state.current_time
end


---Stop playing animation. The animation will be stopped at current time.
---@param animation_state panthera.animation
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
---@param animation_state panthera.animation
---@param animation_id string
---@return number
function M.get_duration(animation_state, animation_id)
	local animation_data = panthera_internal.get_animation_data(animation_state)
	assert(animation_data, "Animation data is not loaded")

	local animation = panthera_internal.get_animation_by_animation_id(animation_data, animation_id)
	assert(animation, "Animation is not found: " .. animation_id)

	return animation.duration
end


---Check if an animation is currently playing.
---@param animation_state panthera.animation
---@return boolean
function M.is_playing(animation_state)
	return animation_state.timer_id ~= nil
end


---Get the ID of the last animation that was started.
---@param animation_state panthera.animation Animation state
---@return string|nil Animation id or nil if animation is not playing
function M.get_latest_animation_id(animation_state)
	return animation_state.animation_id or animation_state.previous_animation_id
end


--- Return a list of animation ids from the created animation state
---@param animation_state panthera.animation
---@return string[]
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


---Desktop Only. Reload animation from JSON file. All current animation will be updated on the next play() function
---or after the next set_time() function
---Animation will be reloaded only at desktop. Only if we have a Panthera file
---inside resources with the user folder directory path
---@param animation_path string|nil If nil - reload all loaded animations
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
