local adapter_go = require("panthera.adapters.adapter_go")
local adapter_gui = require("panthera.adapters.adapter_gui")
local panthera_system = require("panthera.panthera_system")

---@class panthera
local M = {}
local TIMER_DELAY = 1/60


---@param logger_instance panthera.logger|nil
function M.set_logger(logger_instance)
	panthera_system.logger = logger_instance or panthera_system.empty_logger
end


---Load animation from JSON file and create it with Panthera GO adapter
---@param animation_path string
---@param get_node (fun(node_id: string): hash|url)|nil @Function to get node by node_id. Default is defined in adapter
---@return panthera.animation.state|nil @Animation data or nil if animation can't be loaded, error message
function M.create_go(animation_path, get_node)
	return M.create(animation_path, adapter_go, get_node)
end


---Load animation from JSON file and create it with Panthera GUI adapter
---@param animation_path string
---@param get_node (fun(node_id: string): node)|nil @Function to get node by node_id. Default is defined in adapter
---@return panthera.animation.state|nil @Animation data or nil if animation can't be loaded, error message
function M.create_gui(animation_path, get_node)
	return M.create(animation_path, adapter_gui, get_node)
end


---Load animation from JSON file
---@param animation_path string
---@param adapter panthera.adapter
---@param get_node (fun(node_id: string): node)|nil @Function to get node by node_id. Default is defined in adapter
---@return panthera.animation.state|nil @Animation data or nil if animation can't be loaded, error message
function M.create(animation_path, adapter, get_node)
	local animation_data, error_reason = panthera_system.load(animation_path, false)
	if not animation_data then
		panthera_system.logger:error("Can't load Panthera animation", error_reason)
		return nil
	end

	-- Create a data structure for animation
	---@type panthera.animation.state
	local animation_state = {
		nodes = {},
		speed = 1,
		childs = nil,
		timer_id = nil,
		animation = nil,
		current_time = 0,
		adapter = adapter,
		animation_keys_index = 1,
		animation_path = animation_path,
		get_node = get_node or adapter.get_node,
	}

	return animation_state
end


---Create identical copy of animation state to run it in parallel
---@param animation_state panthera.animation.state
---@return panthera.animation.state|nil @New animation state or nil if animation can't be cloned
function M.clone_state(animation_state)
	local adapter = animation_state.adapter
	local get_node = animation_state.get_node
	local animation_path = animation_state.animation_path
	return M.create(animation_path, adapter, get_node)
end


---@param animation_state panthera.animation.state|nil @If nil - skip playing
---@param animation_id string
---@param options panthera.options|nil
function M.play(animation_state, animation_id, options)
	if not animation_state then
		panthera_system.logger:warn("Can't play animation, animation_state is nil", animation_id)
		return
	end

	local animation_data = panthera_system.get_animation_data(animation_state)
	if not animation_data then
		panthera_system.logger:warn("Can't play animation, animation_data is nil", {
			animation_path = animation_state.animation_path,
			animation_id = animation_id,
		})
		return nil
	end

	local animation = panthera_system.get_animation_by_animation_id(animation_data, animation_id)
	if not animation then
		panthera_system.logger:warn("Animation is not found", {
			animation_path = animation_state.animation_path,
			animation_id = animation_id,
		})
		return nil
	end

	if animation_state.animation then
		M.stop(animation_state)
	end

	options = options or {}
	animation_state.animation = animation
	animation_state.animation_keys_index = 1

	if not options.is_skip_init then
		-- Reset all previuosly animated nodes to initial state
		if animation_state.previous_animation then
			panthera_system.reset_animation_state(animation_state, animation_state.previous_animation.animation_id)
			animation_state.previous_animation = nil
		end

		-- If we have initial animation, we should set up it here?
		if animation.initial_state and animation_state ~= "" then
			local initial_animation = panthera_system.get_animation_by_animation_id(animation_data, animation.initial_state)
			if initial_animation then
				panthera_system.set_animation_state_at_time(animation_state, initial_animation.animation_id, initial_animation.duration)
			end
		end

		panthera_system.set_animation_state_at_time(animation_state, animation.animation_id, 0)
	end

	-- Start animation update timer
	local last_time = socket.gettime()
	animation_state.timer_id = timer.delay(TIMER_DELAY, true, function()
		local current_time = socket.gettime()
		local dt = (current_time - last_time)
		last_time = current_time
		local speed = (options.speed or 1) * animation_state.speed

		animation_state.current_time = animation_state.current_time + dt * speed
		M._update_animation(animation_state, options)
	end)
	timer.trigger(animation_state.timer_id)
end


---@private
---@param animation_state panthera.animation.state
---@param options panthera.options
function M._update_animation(animation_state, options)
	local animation = animation_state.animation
	if not animation then
		return
	end

	local keys = animation.animation_keys
	local key_start_index = animation_state.animation_keys_index
	for index = key_start_index, #keys do
		local key = keys[index]

		if key.start_time <= animation_state.current_time then
			animation_state.animation_keys_index = index + 1

			if key.key_type ~= "animation" then
				panthera_system.run_timeline_key(animation_state, key, options)
			else
				-- Create a new animation child track
				local animation_path = animation_state.animation_path
				local adapter = animation_state.adapter
				local get_node = animation_state.get_node

				local child_state = M.create(animation_path, adapter, get_node)
				if child_state then
					animation_state.childs = animation_state.childs or {}
					table.insert(animation_state.childs, child_state)
					local animation_duration = M.get_duration(child_state, key.property_id)

					if animation_duration > 0 and key.duration > 0 then
						local speed = (options.speed or 1) * animation_state.speed
						M.play(child_state, key.property_id, {
							is_skip_init = true,
							speed = (animation_duration / key.duration) * speed,
							callback = function()
								panthera_system.remove_child_animation(animation_state, child_state)
							end
						})
					end
				end
			end
		else
			break
		end
	end

	-- If current time >= animation duration - stop animation
	if animation_state.current_time >= animation_state.animation.duration then
		M.stop(animation_state)

		if options.callback then
			options.callback(animation.animation_id)
		end

		if options.is_loop then
			M.play(animation_state, animation.animation_id, options)
		end
	end
end


---Set animation state at specific time. This will stop animation if it's playing
---@param animation_state panthera.animation.state
---@param animation_id string
---@param time number
function M.set_time(animation_state, animation_id, time)
	local animation_data = panthera_system.get_animation_data(animation_state)
	assert(animation_data, "Animation data is not loaded")

	local animation = panthera_system.get_animation_by_animation_id(animation_data, animation_id)
	assert(animation, "Animation is not found: " .. animation_id)

	if M.is_playing(animation_state) then
		M.stop(animation_state)
	end

	if animation_state.previous_animation then
		panthera_system.reset_animation_state(animation_state, animation_state.previous_animation.animation_id)
		animation_state.previous_animation = nil
	end

	animation_state.current_time = time
	animation_state.animation = animation
	animation_state.animation_keys_index = 1

	panthera_system.set_animation_state_at_time(animation_state, animation.animation_id, time)
end


---Get current animation time in seconds
---@param animation_state panthera.animation.state
---@return number @Current animation time in seconds
function M.get_time(animation_state)
	return animation_state.current_time
end


---Stop playing animation. The animation will be stopped at current time.
---@param animation_state panthera.animation.state
---@return boolean @True if animation was stopped, false if animation is not playing
function M.stop(animation_state)
	if not animation_state then
		panthera_system.logger:warn("Can't stop animation, animation_state is nil")
		return false
	end

	if animation_state.timer_id then
		timer.cancel(animation_state.timer_id)
		animation_state.timer_id = nil
	end

	local previous_animation = animation_state.animation
	animation_state.previous_animation = previous_animation

	-- Stop all tweens started by animation
	if previous_animation then
		local adapter = animation_state.adapter
		local animation_data = panthera_system.get_animation_data(animation_state)
		if animation_data then
			local group_keys = animation_data.group_animation_keys[previous_animation.animation_id]

			for node_id, node_keys in pairs(group_keys) do
				for property_id, keys in pairs(node_keys) do
					if keys[1] and keys[1].key_type == "tween" then
						local key_end_time = keys[1].start_time + keys[1].duration
						local is_finished = key_end_time <= animation_state.current_time
						local node = panthera_system.get_node(animation_state, node_id)
						if node and not is_finished then
							adapter.stop_tween(node, property_id)
						end
					end
				end
			end
		else
			panthera_system.logger:warn("Can't stop animation, animation_data is nil", {
				animation_path = animation_state.animation_path,
				animation_id = previous_animation.animation_id
			})
		end
	end

	animation_state.animation = nil
	animation_state.current_time = 0
	animation_state.animation_keys_index = 1

	if animation_state.childs then
		for index = 1, #animation_state.childs do
			M.stop(animation_state.childs[index])
		end
	end

	return true
end


---Get animation duration
---@param animation_state panthera.animation.state
---@param animation_id string
---@return number
function M.get_duration(animation_state, animation_id)
	local animation_data = panthera_system.get_animation_data(animation_state)
	assert(animation_data, "Animation data is not loaded")

	local animation = panthera_system.get_animation_by_animation_id(animation_data, animation_id)
	assert(animation, "Animation is not found: " .. animation_id)

	return animation.duration
end


---Check if animation is playing
---@param animation_state panthera.animation.state
---@return boolean
function M.is_playing(animation_state)
	return animation_state.timer_id ~= nil
end


---Get current animation id
---@param animation_state panthera.animation.state @Animation state
---@return string|nil @Animation id or nil if animation is not playing
function M.get_latest_animation_id(animation_state)
	if animation_state.animation then
		return animation_state.animation.animation_id
	end
	return animation_state.previous_animation and animation_state.previous_animation.animation_id or nil
end


--- Return a list of animation ids from the created animation state
---@param animation_state panthera.animation.state
---@return string[]
function M.get_animations(animation_state)
	local animation_data = panthera_system.get_animation_data(animation_state)
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
---@param animation_path string|nil @If nil - reload all loaded animations
function M.reload_animation(animation_path)
	if animation_path then
		panthera_system.load(animation_path, true)
	else
		for path in pairs(panthera_system.LOADED_ANIMATIONS) do
			panthera_system.load(path, true)
		end
	end
end


return M
