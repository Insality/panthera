local tweener = require("tweener.tweener")

local M = {}

--- Use empty function to save a bit of memory
local EMPTY_FUNCTION = function(_, message, context) end

---@type panthera.logger
M.empty_logger = {
	trace = EMPTY_FUNCTION,
	debug = EMPTY_FUNCTION,
	info = EMPTY_FUNCTION,
	warn = EMPTY_FUNCTION,
	error = EMPTY_FUNCTION,
}

---@type panthera.logger
M.logger = {
	trace = function(_, msg) print("TRACE: " .. msg) end,
	debug = function(_, msg, data) pprint("DEBUG: " .. msg, data) end,
	info = function(_, msg, data) pprint("INFO: " .. msg, data) end,
	warn = function(_, msg, data) pprint("WARN: " .. msg, data) end,
	error = function(_, msg, data) pprint("ERROR: " .. msg, data) end
}


---@type table<string, panthera.animation.data>
M.LOADED_ANIMATIONS = {}

M.PROJECT_FOLDER = nil -- Current game project folder, used for hot reload animations in debug mode
M.IS_HOTRELOAD_ANIMATIONS = nil
local IS_DEBUG = sys.get_engine_info().is_debug

---Load animation from file and store it in cache
---@param animation_path string
---@param is_cache_reset boolean @If true - animation will be reloaded from file
---@return panthera.animation.data|nil, string|nil @animation_data, error_reason
function M.load(animation_path, is_cache_reset)
	if is_cache_reset then
		M.LOADED_ANIMATIONS[animation_path] = nil
	end

	if not M.LOADED_ANIMATIONS[animation_path] then
		local animation, error_reason = M._get_animation_by_path(animation_path)
		if not animation then
			return nil, error_reason
		end

		M.LOADED_ANIMATIONS[animation_path] = animation
	end

	return M.LOADED_ANIMATIONS[animation_path], nil
end


---@param animation_state panthera.animation.state
---@return panthera.animation.data|nil
function M.get_animation_data(animation_state)
	return M.LOADED_ANIMATIONS[animation_state.animation_path]
end


---@param animation_data panthera.animation.data
---@param animation_id string
---@return panthera.animation.data.animation|nil
function M.get_animation_by_animation_id(animation_data, animation_id)
	return animation_data.animations_dict[animation_id]
end


---@param animation_data panthera.animation.data
---@param node_id string
---@param animation_id string
---@return string[]
function M.get_animated_node_properties(animation_data, node_id, animation_id)
	local node_properties = {}
	for index = 1, #animation_data.animations do
		local animation = animation_data.animations[index]
		if animation.animation_id == animation_id then
			local animation_keys = animation.animation_keys
			for key_index = 1, #animation_keys do
				local key = animation_keys[key_index]
				if key.node_id == node_id then
					node_properties[key.property_id] = true
				end
			end
		end
	end

	-- Return list of properties
	local result = {}
	for property_id in pairs(node_properties) do
		table.insert(result, property_id)
	end

	return result
end


---@param animation_state panthera.animation.state
---@param animation_id string
---@param time number
function M.set_animation_state_at_time(animation_state, animation_id, time)
	local animation_data = M.get_animation_data(animation_state) --[[@as panthera.animation.data]]
	local animation = M.get_animation_by_animation_id(animation_data, animation_id)
	if not animation then
		return nil
	end

	-- If we have initial animation, we should set up it here?
	if animation.initial_state then
		local initial_animation = M.get_animation_by_animation_id(animation_data, animation.initial_state)
		if initial_animation then
			M.set_animation_state_at_time(animation_state, initial_animation.animation_id, initial_animation.duration)
		end
	end

	local group_keys = animation_data.group_animation_keys[animation_id]
	for node_id, node_keys in pairs(group_keys) do
		if node_id ~= "" then
			-- Node keys
			for property_id, _ in pairs(node_keys) do
				M.set_node_value_at_time(animation_state, animation_id, node_id, property_id, time)
			end
		else
			-- Animation keys
			for key_animation_id, keys in pairs(node_keys) do
				-- Find the last triggered animation key
				---@type panthera.animation.data.animation_key|nil
				local last_key = nil
				for index = #keys, 1, -1 do
					local key = keys[index]
					if key.start_time <= time then
						last_key = key
						break
					end
				end

				if last_key and last_key.key_type == "animation" then
					local animation_time = time - last_key.start_time
					animation_time = math.min(animation_time, last_key.duration)
					M.set_animation_state_at_time(animation_state, key_animation_id, animation_time)
				end
			end
		end
	end
end


---@param animation_state panthera.animation.state
---@param animation_id string
---@param node_id string
---@param property_id string
---@param time number @Pass -1 to get initial value
---@return any|nil
function M.get_node_value_at_time(animation_state, animation_id, node_id, property_id, time)
	local animation_data = M.get_animation_data(animation_state) --[[@as panthera.animation.data]]
	local group_keys = animation_data.group_animation_keys[animation_id]

	local node_keys = group_keys[node_id]
	if not node_keys then
		return nil
	end

	local keys = node_keys[property_id]
	if not keys then
		return nil
	end

	local initial_key = keys[1]

	local set_value = nil
	if initial_key.key_type == "trigger" then
		set_value = initial_key.start_data
	end
	if initial_key.key_type == "tween" then
		set_value = initial_key.start_value
	end

	for index = #keys, 1, -1 do
		local key = keys[index]
		if key.start_time <= time  then
			if key.key_type == "tween" then
				set_value = M._get_key_value_at_time(key, time)
			end

			if key.key_type == "trigger" then
				set_value = key.data
			end

			break
		end
	end

	return set_value
end


---@param animation_state panthera.animation.state
---@param animation_id string
---@param node_id string
---@param property_id string
---@param time number
---@return any|nil
function M.set_node_value_at_time(animation_state, animation_id, node_id, property_id, time)
	local adapter = animation_state.adapter
	local animation_data = M.get_animation_data(animation_state) --[[@as panthera.animation.data]]
	if not animation_data then
		return nil
	end

	local node = M.get_node(animation_state, node_id)
	if node then
		local set_value = M.get_node_value_at_time(animation_state, animation_id, node_id, property_id, time)
		if set_value ~= nil then
			adapter.set_node_property(node, property_id, set_value)
			return set_value
		end
	end

	return nil
end


---Reset all animated values in animation id to initial state
---@param animation_state panthera.animation.state
---@param animation_id string
function M.reset_animation_state(animation_state, animation_id)
	local animation_data = M.get_animation_data(animation_state) --[[@as panthera.animation.data]]
	if not animation_data then
		return
	end

	local group_keys = animation_data.group_animation_keys[animation_id]
	if not group_keys then
		return
	end

	for node_id, node_keys in pairs(group_keys) do
		for property_id, keys in pairs(node_keys) do
			M.set_node_value_at_time(animation_state, animation_id, node_id, property_id, -1)
		end
	end
end


---@param animation_state panthera.animation.state
---@param node_id string
---@return node|nil
function M.get_node(animation_state, node_id)
	if node_id == "" then
		return nil
	end

	local node = animation_state.nodes[node_id]

	if not node then
		local is_ok, result = pcall(animation_state.get_node, node_id)
		if not is_ok then
			M.logger:warn("Can't get node", {
				animation_path = animation_state.animation_path,
				node_id = node_id,
			})
			return
		end
		node = result
	end

	if not node then
		M.logger:warn("Can't find node", {
			animation_path = animation_state.animation_path,
			node_id = node_id
		})
		return nil
	end

	return node
end


--- Run animation key except "animation" key type
--- It should be processed before as a separate animation
---@param animation_state panthera.animation.state
---@param key panthera.animation.data.animation_key
---@param options panthera.options
---@return boolean @true if success
function M.run_timeline_key(animation_state, key, options)
	local speed = (options.speed or 1) * animation_state.speed
	assert(speed > 0, "Speed should be greater than 0")

	local adapter = animation_state.adapter
	local node = M.get_node(animation_state, key.node_id)

	if node and key.key_type == "tween" then
		local easing = adapter.get_easing(key.easing)
		local delta = key.end_value - key.start_value
		local start_value = key.start_value

		if options.is_relative then
			local current_value = adapter.get_node_property(node, key.property_id) --[[@as number]]
			if current_value then
				start_value = current_value
			end
		end

		local target_value = start_value + delta
		adapter.tween_animation_key(node, key.property_id, easing, key.duration / speed, target_value)

		return true
	end

	if node and key.key_type == "trigger" then
		adapter.trigger_animation_key(node, key.property_id, key.data)
		return true
	end

	if key.key_type == "event" then
		M.event_animation_key(node, key, options.callback_event)
		return true
	end

	return false
end


---@param node node|nil
---@param key panthera.animation.data.animation_key
---@param callback_event fun(event_id: string, node: node|nil, data: any, end_value: number): nil
function M.event_animation_key(node, key, callback_event)
	if not callback_event then
		return
	end

	if key.duration == 0 then
		callback_event(key.event_id, node, key.data, key.end_value)
	else
		local easing = tweener[key.easing] or tweener.linear
		tweener.tween(easing, key.start_value, key.end_value, key.duration, function(value)
			callback_event(key.event_id, node, key.data, value)
		end)
	end
end


---@param animation_state panthera.animation.state
---@param child_animation_state panthera.animation.state
---@return boolean
function M.remove_child_animation(animation_state, child_animation_state)
	local childs = animation_state.childs
	if not childs then
		return false
	end

	for index = 1, #childs do
		if childs[index] == child_animation_state then
			table.remove(childs, index)
			return true
		end
	end

	return false
end


---Load the file from full path (only desktop)
---@private
---@param path string The save path
---@return table|nil, string|nil
function M._load_by_path(path)
	local file = io.open(path)
	if file then
		local file_data = file:read("*all")
		file:close()
		if file_data then
			local is_ok, result = pcall(json.decode, file_data)
			if not is_ok then
				return nil, "Failed to parse json: " .. path
			end
			local parsed_data = result
			if parsed_data and type(parsed_data) == "table" then
				return parsed_data, nil
			end
		end
	end
end


---Load the file from resource folder inside game
---@private
---@param path string The resource path
---@return table|nil, string|nil
function M._load_by_resource_path(path)
	local data, error = sys.load_resource(path)
	if error then
		return nil, error
	end

	local is_ok, result = pcall(json.decode, data)
	if not is_ok then
		return nil, "Failed to parse json: " .. path
	end
	local parsed_data = result
	if parsed_data and type(parsed_data) == "table" then
		return parsed_data
	end

	return nil, "Failed to load resource by path: " .. path
end


local current_dir = nil
---Get current directory
---@private
---@return string|nil
function M._get_current_dir()
	if current_dir then
		return current_dir
	end

	local tmp_path = os.tmpname()
	os.execute("pwd > " .. tmp_path)
	local file = io.open(tmp_path, "r")
	if not file then
		return nil
	end

	local pwd_result = file:read("*l")
	file:close()
	os.remove(tmp_path)
	current_dir = pwd_result
	return current_dir
end


---Load animation from JSON file and return it
---@private
---@param path string
---@return panthera.animation.data|nil, string|nil
function M._get_animation_by_path(path)
	local resource, error

	if M.IS_HOTRELOAD_ANIMATIONS then
		local project_path = M.PROJECT_FOLDER .. path
		if not project_path then
			return nil, "Can't get current game project folder"
		end
		resource, error = M._load_by_path(project_path)

		M.logger:debug("Panthera animation reloaded", path)
	else
		resource, error = M._load_by_resource_path(path)
	end

	if not resource then
		return nil, error
	end

	local filetype = resource.type
	if filetype ~= "animation_editor" then
		return nil, "The JSON file is not an animation editor file"
	end

	---@type panthera.animation.data
	local data = resource.data
	M._preprocess_animation_keys(data)

	return data, nil
end


---@private
---@param a panthera.animation.data.animation_key
---@param b panthera.animation.data.animation_key
function M._sort_keys_function(a, b)
	if a.start_time ~= b.start_time then
		return a.start_time < b.start_time
	end
	if a.duration ~= b.duration then
		return a.duration < b.duration
	end
	if a.property_id ~= b.property_id then
		return a.property_id < b.property_id
	end
	if a.node_id ~= b.node_id then
		return a.node_id < b.node_id
	end

	return a.end_value < b.end_value
end


---@private
---@param data panthera.animation.data
function M._preprocess_animation_keys(data)
	for index = 1, #data.animations do
		local animation = data.animations[index]

		for key_index = 1, #animation.animation_keys do
			-- These default keys can be nil
			local key = animation.animation_keys[key_index]
			key.start_value = key.start_value or 0
			key.start_time = key.start_time or 0
			key.end_value = key.end_value or 0
			key.duration = key.duration or 0
			key.node_id = key.node_id or ""
		end

		table.sort(animation.animation_keys, M._sort_keys_function)
	end

	-- For fast search
	data.animations_dict = {}
	for index = 1, #data.animations do
		local animation = data.animations[index]
		data.animations_dict[animation.animation_id] = animation
	end

	data.group_animation_keys = M._get_group_animation_keys(data)
end


---Group keys in group[animation_id][node_id][property_id]
---@private
---@param animation_data panthera.animation.data
---@return table<string, table<string, panthera.animation.data.animation_key[]>>
function M._get_group_animation_keys(animation_data)
	local group_animations = {}
	for index = 1, #animation_data.animations do
		local animation = animation_data.animations[index]
		local animation_keys = animation.animation_keys
		local group_keys = {}
		for key_index = 1, #animation_keys do
			local key = animation_keys[key_index]
			group_keys[key.node_id] = group_keys[key.node_id] or {}
			group_keys[key.node_id][key.property_id] = group_keys[key.node_id][key.property_id] or {}

			table.insert(group_keys[key.node_id][key.property_id], key)
		end

		group_animations[animation.animation_id] = group_keys
	end

	return group_animations
end


---Return animation key value at time. If time is out of range - return start or end value
---@private
---@param key panthera.animation.data.animation_key
---@param time number
---@return number
function M._get_key_value_at_time(key, time)
	if time < key.start_time then
		return key.start_value
	end

	if time > key.start_time + key.duration then
		return key.end_value
	end

	local easing = tweener[key.easing] or tweener.linear
	local value = tweener.ease(easing, key.start_value, key.end_value, key.duration, time - key.start_time)

	return value
end


---Get current application folder (only desktop)
---@return string|nil @Current application folder, nil if failed
function M._get_current_game_project_folder()
	local tmpfile = os.tmpname()
	os.execute("pwd > " .. tmpfile)

	local file = io.open(tmpfile, "r")
	if not file then
		return nil
	end

	local pwd = file:read("*l")
	file:close()
	os.remove(tmpfile)

	if not pwd then
		return nil
	end

	-- Check the game.project file exists in this folder
	local game_project_path = pwd .. "/game.project"
	local game_project_file = io.open(game_project_path, "r")
	if not game_project_file then
		return nil
	end

	game_project_file:close()
	return pwd
end


-- Init hot reload animations
if IS_DEBUG then
	M.IS_HOTRELOAD_ANIMATIONS = sys.get_config_int("panthera.hotreload_animations", 0) == 1
	if M.IS_HOTRELOAD_ANIMATIONS then
		M.PROJECT_FOLDER = M._get_current_game_project_folder()
		if not M.PROJECT_FOLDER then
			M.logger:error("Can't get current game project folder")
			M.IS_HOTRELOAD_ANIMATIONS = false
		end
	end
end


return M