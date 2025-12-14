local tweener = require("tweener.tweener")

---@class panthera.adapter
---@field get_node fun(node_id: string): node Function to get node by node_id.
---@field get_easing fun(easing_id: string): hash Function to get defold easing by easing_id. Default is gui.EASING
---@field tween_animation_key fun(node: node, property_id: string, easing: hash|number[], duration: number, end_value: number): nil Function to tween animation key.
---@field trigger_animation_key fun(node: node, property_id: string, value: any): nil Function to trigger animation key.
---@field event_animation_key fun(node: node, key: panthera.animation.data.animation_key): nil Function to trigger event in animation.
---@field set_node_property fun(node: node, property_id: string, value: number|string): boolean Function to set node property. Return true if success
---@field stop_tween fun(node: node, property_id: string): nil Function to stop tween animation key
---@field is_node_valid fun(node: node): boolean Function to check if node is valid

---@class panthera.logger
---@field trace fun(logger: panthera.logger, message: string, data: any|nil)
---@field debug fun(logger: panthera.logger, message: string, data: any|nil)
---@field info fun(logger: panthera.logger, message: string, data: any|nil)
---@field warn fun(logger: panthera.logger, message: string, data: any|nil)
---@field error fun(logger: panthera.logger, message: string, data: any|nil)

---@class panthera.animation.data.node

---@class panthera.animation.data.metadata
---@field gui_path string
---@field fps number
---@field settings table
---@field gizmo_steps table
---@field template_animation_paths table<string, string> template_animation_paths[node_id]: path. Value filled at loading animation data

---@class panthera.animation.data.animation
---@field duration number
---@field animation_id string
---@field initial_state string
---@field animation_keys panthera.animation.data.animation_key[]

---@class panthera.animation.data
---@field name string
---@field nodes panthera.animation.data.node[]
---@field animations panthera.animation.data.animation[]
---@field metadata panthera.animation.data.metadata
---@field group_animation_keys table<string, table<string, table<string, panthera.animation.data.animation_key[]>>> group_animation_keys[animation_id][node_id][property_id]: keys[]. Value filled at loading animation data
---@field animations_dict table<string, panthera.animation.data.animation> animations_dict[animation_id]: animation. Value filled at loading animation data

---@class panthera.animation.project_file
---@field data panthera.animation.data Animation data
---@field format string Animation format
---@field version string Animation version
---@field type string Animation type. Example: "animation_editor", "atlas"

---@class panthera.animation.data.animation_key
---@field key_type number
---@field node_id string
---@field property_id string
---@field start_time number
---@field duration number
---@field start_value number
---@field end_value number
---@field easing string
---@field easing_custom number[]|vector|nil
---@field start_data string
---@field data string
---@field event_id string
---@field is_editor_only boolean


local M = {}

M.KEY_TYPE = {
	TRIGGER = 0,
	TWEEN = 1,
	EVENT = 2,
	ANIMATION = 3,
	["trigger"] = 0,
	["tween"] = 1,
	["event"] = 2,
	["animation"] = 3,
}

local TYPE_TABLE = "table"

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
	error = function(_, msg, data) pprint(data) error(msg) end
}


---The list of loaded animations.
---@type table<string, panthera.animation.data> Animation path -> animation data
M.LOADED_ANIMATIONS = {}

-- The list of animations that loaded directly from the table. We can't reload them on runtime, and we should not clear them on hot reload
---@type table<string, boolean> Animation fake path -> true
M.INLINE_ANIMATIONS = {}

M.PROJECT_FOLDER = nil -- Current game project folder, used for hot reload animations in debug mode
M.IS_HOTRELOAD_ANIMATIONS = nil
local IS_DEBUG = sys.get_engine_info().is_debug


---Create animation state
---@param animation_or_path string|table Path to JSON animation file in custom resources or table with animation data
---@param adapter panthera.adapter
---@param get_node (fun(node_id: string): node) Function to get node by node_id. Default is defined in adapter
---@return panthera.animation animation New animation state object
function M.create_animation_state(animation_or_path, adapter, get_node)
	local animation_data, animation_path, error_reason = M.load(animation_or_path, false)

	if not animation_data or not animation_path then
		M.logger:error("Can't load Panthera animation", error_reason)
		error(error_reason)
	end

	-- Create a data structure for animation
	---@type panthera.animation
	local animation_state = {
		nodes = {},
		speed = 1,
		childs = nil,
		timer_id = nil,
		animation = nil,
		current_time = 0,
		adapter = adapter,
		get_node = get_node,
		animation_keys_index = 1,
		animation_path = animation_path,
	}

	return animation_state
end


---Load animation from file and store it in cache
---@param animation_or_path string|panthera.animation.project_file Path to the animation file or animation table
---@param is_cache_reset boolean If true - animation will be reloaded from file. Will be ignored for inline animations
---@return panthera.animation.data|nil animation_data
---@return string|nil animation_path
---@return string|nil error_reason
function M.load(animation_or_path, is_cache_reset)
	-- If we have already loaded animation table
	local is_table = type(animation_or_path) == TYPE_TABLE
	if is_table then
		local animation_path = M.get_fake_animation_path()
		local project_data = animation_or_path --[[@as panthera.animation.project_file]]

		local data = project_data.data
		M.preprocess_animation_keys(data)
		M.LOADED_ANIMATIONS[animation_path] = data
		M.INLINE_ANIMATIONS[animation_path] = true

		return data, animation_path, nil
	end

	-- If we have path to the file
	assert(type(animation_or_path) == "string", "Path should be a string")
	local animation_path = animation_or_path --[[@as string]]
	local is_inline_animation = M.INLINE_ANIMATIONS[animation_path]
	if is_cache_reset and not is_inline_animation then
		M.LOADED_ANIMATIONS[animation_path] = nil
	end

	if not M.LOADED_ANIMATIONS[animation_path] then
		local animation, error_reason = M.get_animation_by_path(animation_path)
		if not animation then
			return nil, nil, error_reason
		end

		M.preprocess_animation_keys(animation)
		M.LOADED_ANIMATIONS[animation_path] = animation
	end

	return M.LOADED_ANIMATIONS[animation_path], animation_path, nil
end


---@param animation_state panthera.animation
---@return panthera.animation.data
function M.get_animation_data(animation_state)
	return M.LOADED_ANIMATIONS[animation_state.animation_path]
end


---@param animation_data panthera.animation.data
---@param animation_id string
---@return panthera.animation.data.animation|nil
function M.get_animation_by_animation_id(animation_data, animation_id)
	return animation_data.animations_dict[animation_id] or animation_data.animations_dict[hash(animation_id)]
end


---@param animation_state panthera.animation
---@param animation_id string
---@param time number
---@param event_callback fun(event_id: string, node: node|nil, data: any, end_value: number)|nil
function M.set_animation_state_at_time(animation_state, animation_id, time, event_callback)
	local animation_data = M.LOADED_ANIMATIONS[animation_state.animation_path]
	local animation = M.get_animation_by_animation_id(animation_data, animation_id)
	if not animation then
		return nil
	end

	-- If we have initial animation, we should set up it here?
	if animation.initial_state then
		local initial_animation = M.get_animation_by_animation_id(animation_data, animation.initial_state)
		if initial_animation then
			M.set_animation_state_at_time(animation_state, initial_animation.animation_id, initial_animation.duration, event_callback)
		end
	end

	local group_keys = animation_data.group_animation_keys[animation_id]
	for node_id, node_keys in pairs(group_keys) do
		-- It's a regular node
		if node_id ~= "" then
			-- Node keys
			for property_id, keys in pairs(node_keys) do
				local is_keys = #keys > 0
				local is_animation_keys = is_keys and keys[1].key_type == M.KEY_TYPE.ANIMATION
				local template_animation_id = property_id

				if is_keys and not is_animation_keys then
					M.set_node_value_at_time(animation_state, animation_id, node_id, property_id, time)
				end

				local template_paths = animation_data.metadata and animation_data.metadata.template_animation_paths or {}
				local template_path = template_paths[node_id]
				if template_path and is_keys and is_animation_keys then
					-- Grap template path and set it to the nodes
					local get_node = function(animation_node_id)
						return animation_state.get_node(node_id .. "/" .. animation_node_id)
					end
					local template_state = M.create_animation_state(template_path, animation_state.adapter, get_node)
					M.set_animation_state_at_time(template_state, template_animation_id, time, event_callback)
				end
			end

			local events = node_keys["event"]
			if events then
				for index = 1, #events do
					local key = events[index]
					if key.start_time <= time then
						animation_state.events = animation_state.events or {}

						if not animation_state.events[key] then
							M.event_animation_key(nil, key, key.duration, event_callback)
							animation_state.events[key] = key
						end
					end
				end
			end
		end

		-- It's Animation keys
		if node_id == "" then
			-- Animation keys
			local animation_keys_to_trigger = {}
			for _, animation_keys in pairs(node_keys) do
				for index = #animation_keys, 1, -1 do
					-- Find the last triggered animation key
					local key = animation_keys[index]
					if key.start_time <= time and key.key_type == M.KEY_TYPE.ANIMATION then
						table.insert(animation_keys_to_trigger, key)
						break
					end

					-- Trigger all not triggered events
					if key.start_time <= time and key.key_type == M.KEY_TYPE.EVENT then
						animation_state.events = animation_state.events or {}

						if not animation_state.events[key] then
							M.event_animation_key(nil, key, key.duration, event_callback)
							animation_state.events[key] = key
						end
					end
				end
			end

			table.sort(animation_keys_to_trigger, M.sort_keys_function)

			for index = 1,	#animation_keys_to_trigger do
				local animation_key = animation_keys_to_trigger[index]
				local inner_animation_id = animation_key.property_id

				local animation_time_to_set = time - animation_key.start_time
				local animation_to_play = M.get_animation_by_animation_id(animation_data, inner_animation_id)
				local animation_duration = animation_to_play and animation_to_play.duration or 0

				if animation_key.duration == 0 then
					animation_time_to_set = animation_duration
				else
					animation_time_to_set = animation_time_to_set * animation_duration / animation_key.duration
				end

				M.set_animation_state_at_time(animation_state, inner_animation_id, animation_time_to_set, event_callback)
			end
		end
	end
end


---@param animation_state panthera.animation
---@param animation_id string
---@param node_id string
---@param property_id string
---@param time number Pass -1 to get initial value
---@return any|nil
function M.get_node_value_at_time(animation_state, animation_id, node_id, property_id, time)
	local animation_data = M.get_animation_data(animation_state) --[[@as panthera.animation.data]]
	local group_keys = animation_data.group_animation_keys[animation_id]

	local group = group_keys[node_id]
	local keys = group and group[property_id]
	if not keys or #keys == 0 then
		return nil
	end

	local initial_key = keys[1]

	local set_value = nil
	if initial_key.key_type == M.KEY_TYPE.TRIGGER then
		set_value = initial_key.start_data
	end
	if initial_key.key_type == M.KEY_TYPE.TWEEN then
		set_value = initial_key.start_value
	end

	for index = #keys, 1, -1 do
		local key = keys[index]
		if key.start_time <= time  then
			if key.key_type == M.KEY_TYPE.TWEEN then
				set_value = M.get_key_value_at_time(key, time)
			end

			if key.key_type == M.KEY_TYPE.TRIGGER then
				set_value = key.data
			end

			break
		end
	end

	return set_value
end


---@param animation_state panthera.animation
---@param animation_id string
---@param node_id string
---@param property_id string
---@param time number
---@return any|nil
function M.set_node_value_at_time(animation_state, animation_id, node_id, property_id, time)
	local adapter = animation_state.adapter
	local node = M.get_node(animation_state, node_id)
	if not node then
		return nil
	end

	local set_value = M.get_node_value_at_time(animation_state, animation_id, node_id, property_id, time)
	if set_value ~= nil then
		adapter.set_node_property(node, property_id, set_value)
		return set_value
	end

	return nil
end


---@param animation_state panthera.animation
---@param animation_id string
---@return boolean is_success
function M.stop_tweens(animation_state, animation_id)
	local adapter = animation_state.adapter
	local animation_data = M.get_animation_data(animation_state)

	if not animation_data then
		M.logger:warn("Can't stop animation, animation_data is nil", {
			animation_path = animation_state.animation_path,
			animation_id = animation_id
		})
		return false
	end

	local group_keys = animation_data.group_animation_keys[animation_id]
	for node_id, node_keys in pairs(group_keys) do
		for property_id, keys in pairs(node_keys) do
			local first_key = keys[1]
			if first_key and first_key.key_type == M.KEY_TYPE.TWEEN then
				local node = M.get_node(animation_state, node_id)
				if node then
					adapter.stop_tween(node, property_id)
				end
			end
		end
	end

	return true
end


---Reset all animated values in animation id to initial state
---@param animation_state panthera.animation
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
			local is_animation_keys = #keys > 0 and keys[1].key_type == M.KEY_TYPE.ANIMATION
			if not is_animation_keys then
				M.set_node_value_at_time(animation_state, animation_id, node_id, property_id, -1)
			end
		end
	end
end


---@param animation_state panthera.animation
---@param node_id string
---@return node|nil
function M.get_node(animation_state, node_id)
	if node_id == "" then
		return nil
	end

	local node = animation_state.nodes[node_id]

	if node == nil then
		local is_ok, result = pcall(animation_state.get_node, node_id)
		local animation_data = M.get_animation_data(animation_state)
		local binded_to = animation_data.metadata and animation_data.metadata.gui_path

		if not is_ok then
			M.logger:warn("Can't get node", {
				binded_to = binded_to,
				animation_path = animation_state.animation_path,
				node_id = node_id,
			})
			return
		end
		node = result
		animation_state.nodes[node_id] = node
	end

	if node == nil then
		local animation_data = M.get_animation_data(animation_state)
		local binded_to = animation_data.metadata and animation_data.metadata.gui_path
		M.logger:warn("Can't find node", {
			binded_to = binded_to,
			animation_path = animation_state.animation_path,
			node_id = node_id
		})
		return nil
	end

	if node and not animation_state.adapter.is_node_valid(node) then
		animation_state.nodes[node_id] = false -- Mark as deleted if node is invalid
		return nil
	end

	return node
end


---Run animation key except "animation" key type
---It should be processed before as a separate animation
---@param animation_state panthera.animation
---@param key panthera.animation.data.animation_key
---@param options panthera.options
---@param speed number
---@return boolean result true if success
function M.run_timeline_key(animation_state, key, options, speed)
	assert(speed > 0, "Speed should be greater than 0")

	local adapter = animation_state.adapter
	local node = M.get_node(animation_state, key.node_id)
	local time_overflow = animation_state.current_time - key.start_time
	local key_duration = math.max(key.duration - time_overflow, 0) / speed

	if key.key_type == M.KEY_TYPE.TWEEN then
		if node then
			local easing = key.easing_custom or adapter.get_easing(key.easing)
			local delta = key.end_value - key.start_value
			local start_value = key.start_value

			adapter.tween_animation_key(node, key.property_id, easing, key_duration, start_value + delta)
			return true
		end
		return false
	elseif key.key_type == M.KEY_TYPE.TRIGGER then
		if node then
			adapter.trigger_animation_key(node, key.property_id, key.data)
			return true
		end
		return false
	elseif key.key_type == M.KEY_TYPE.EVENT then
		M.event_animation_key(node, key, key_duration, options.callback_event)
		return true
	end

	return false
end


---@param node node|nil
---@param key panthera.animation.data.animation_key
---@param duration number Duration of the key, calculated with animation speed and time overflow
---@param callback_event fun(event_id: string, node: node|nil, data: any, end_value: number)|nil
function M.event_animation_key(node, key, duration, callback_event)
	if not callback_event then
		return
	end

	if duration == 0 then
		callback_event(key.event_id, node, key.data, key.end_value)
	else
		local easing = key.easing_custom or tweener[key.easing] or tweener.linear
		-- TODO: need to keep tween reference to cancel it
		tweener.tween(easing, key.start_value, key.end_value, duration, function(value)
			callback_event(key.event_id, node, key.data, value)
		end)
	end
end


---@param animation_state panthera.animation
---@param child_animation_state panthera.animation
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
---@return table|nil data
---@return string|nil error_reason
function M.load_by_path(path)
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
			if parsed_data and type(parsed_data) == TYPE_TABLE then
				return parsed_data, nil
			end
		end
	end
end


---Load the file from resource folder inside game
---@private
---@param path string The resource path
---@return table|nil data
---@return string|nil error_reason
function M.load_by_resource_path(path)
	local data, error = sys.load_resource(path)
	if error then
		return nil, error
	end

	local is_ok, result = pcall(json.decode, data)
	if not is_ok then
		return nil, "Failed to parse json: " .. path
	end
	local parsed_data = result
	if parsed_data and type(parsed_data) == TYPE_TABLE then
		return parsed_data
	end

	return nil, "Failed to load resource by path: " .. path
end


---Load animation from JSON file and return it
---@private
---@param path string
---@return panthera.animation.data|nil animation_data
---@return string|nil error_reason
function M.get_animation_by_path(path)
	local resource, error

	if M.IS_HOTRELOAD_ANIMATIONS then
		local relative_path = M.PROJECT_FOLDER .. path
		resource, error = M.load_by_path(relative_path)

		M.logger:debug("Panthera animation reloaded", path)
	else
		resource, error = M.load_by_resource_path(path)
	end

	if not resource then
		return nil, error
	end

	resource = resource --[[@as panthera.animation.project_file]]
	local filetype = resource.type
	if filetype ~= "animation_editor" then
		return nil, "The JSON file is not an animation editor file"
	end

	return resource.data, nil
end


---@private
---@param a panthera.animation.data.animation_key
---@param b panthera.animation.data.animation_key
function M.sort_keys_function(a, b)
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
function M.preprocess_animation_keys(data)
	for index = 1, #data.animations do
		local animation = data.animations[index]

		for key_index = #animation.animation_keys, 1, -1 do
			-- These default keys can be nil
			local key = animation.animation_keys[key_index]
			key.start_value = key.start_value or 0
			key.start_time = key.start_time or 0
			key.end_value = key.end_value or 0
			key.duration = key.duration or 0
			key.node_id = key.node_id or ""

			-- Custom easings have more priority than easing and Defold requires vector for custom easing
			if key.easing_custom and type(key.easing_custom) == "table" then
				local easing_custom = key.easing_custom --[=[@as number[]]=]
				key.easing_custom = vmath.vector(easing_custom)
			end

			-- Replace key_type to number for faster comparison
			key.key_type = M.KEY_TYPE[key.key_type] or key.key_type
		end

		table.sort(animation.animation_keys, M.sort_keys_function)
	end

	-- For fast search
	data.animations_dict = {}
	for index = 1, #data.animations do
		local animation = data.animations[index]
		data.animations_dict[animation.animation_id] = animation
		data.animations_dict[hash(animation.animation_id)] = animation
	end

	data.group_animation_keys = M.get_group_animation_keys(data)

	do -- Process editor_only keys: update start_value and clear them
		for _, animation in pairs(data.group_animation_keys) do
			for _, node_keys in pairs(animation) do
				for _, keys in pairs(node_keys) do
					for key_index = #keys, 1, -1 do
						local key = keys[key_index]
						if key.is_editor_only then
							local next_key = keys[key_index + 1]
							if next_key then
								next_key.start_value = key.start_value
							end

							table.remove(keys, key_index)
						end
					end
				end
			end
		end

		-- Remove editor only keys
		for index = 1, #data.animations do
			local animation = data.animations[index]
			for key_index = #animation.animation_keys, 1, -1 do
				local key = animation.animation_keys[key_index]
				if key.is_editor_only then
					table.remove(animation.animation_keys, key_index)
				end
			end
		end
	end

	do -- Include all children metadata template_animation_paths recursive
		local paths = data.metadata.template_animation_paths
		if paths then
			-- For each path recursive go deep and record next path with path template/node
			for node_id, animation_or_path in pairs(paths) do
				if type(animation_or_path) == TYPE_TABLE then
					local animation = animation_or_path --[[@as panthera.animation.project_file]]

					local child_metapaths = animation.data.metadata.template_animation_paths
					if child_metapaths then
						for child_node_id, child_data in pairs(child_metapaths) do
							paths[node_id .. "/" .. child_node_id] = child_data
						end
					end
				end
			end
		end
	end
end


---Group keys in group[animation_id][node_id][property_id]
---@private
---@param animation_data panthera.animation.data
---@return table<string, table<string, panthera.animation.data.animation_key[]>>
function M.get_group_animation_keys(animation_data)
	local group_animations = {}
	for index = 1, #animation_data.animations do
		local animation = animation_data.animations[index]
		local animation_keys = animation.animation_keys
		local group_keys = {}
		for key_index = 1, #animation_keys do
			local key = animation_keys[key_index]
			local node_id = key.node_id
			local property_id = key.property_id

			group_keys[node_id] = group_keys[node_id] or {}
			group_keys[node_id][property_id] = group_keys[node_id][property_id] or {}
			table.insert(group_keys[node_id][property_id], key)
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
function M.get_key_value_at_time(key, time)
	if time < key.start_time then
		return key.start_value
	end

	if time > key.start_time + key.duration then
		return key.end_value
	end

	local easing = key.easing_custom or tweener[key.easing] or tweener.linear
	local value = tweener.ease(easing, key.start_value, key.end_value, key.duration, time - key.start_time)

	return value
end


---Get current application folder (only desktop)
---@private
---@return string|nil game_project_folder Current application folder, nil if failed
function M.get_current_game_project_folder()
	if not io.popen or html5 then
		return nil
	end

	local file = io.popen("pwd")
	if not file then
		return nil
	end

	local pwd = file:read("*l")
	file:close()

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


local path_counter = 0
---@private
function M.get_fake_animation_path()
	path_counter = path_counter + 1
	return "panthera_animation_" .. path_counter
end


-- Init hot reload animations
if IS_DEBUG then
	M.IS_HOTRELOAD_ANIMATIONS = sys.get_config_int("panthera.hotreload_animations", 0) == 1
	M.PROJECT_FOLDER = M.IS_HOTRELOAD_ANIMATIONS and M.get_current_game_project_folder()
	if not M.PROJECT_FOLDER then
		M.IS_HOTRELOAD_ANIMATIONS = false
	end
end


return M
