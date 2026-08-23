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
---@field group_animation_order table<string, panthera.animation.data.animation_key[][]> group_animation_order[animation_id]: key groups sorted like the timeline. Value filled at loading animation data
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


---A value key owns [start_time, ...], a clip key owns [start_time, start_time + duration):
---at the boundary instant the previous clip still holds the pose. The clip at 0 owns its start
---@param key panthera.animation.data.animation_key
---@param time number
---@return boolean
function M.is_key_started(key, time)
	if key.key_type ~= M.KEY_TYPE.ANIMATION or key.duration <= 0 then
		return key.start_time <= time
	end
	return key.start_time < time or (key.start_time == 0 and time >= 0)
end

local MAX_ANIMATION_NESTING = 16
local TIME_UNSTARTED = -1
local FROZEN_SCALE = 0
-- Where a collected value came from, breaks a tie between two values of the same root start
local SOURCE_REST_POSE = 0
local SOURCE_KEY = 1

-- A clip sample only applies properties with a started key, the rest stay on the previous clip
M.SAMPLE_DEPTH_ROOT = 1
M.SAMPLE_DEPTH_CLIP = 2
local SAMPLE_DEPTH_ROOT = M.SAMPLE_DEPTH_ROOT

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

---@type table<string, boolean> animation_path#animation_id -> true
M.LOGGED_NESTING_WARNINGS = {}

-- The list of animations that loaded directly from the table. We can't reload them on runtime, and we should not clear them on hot reload
---@type table<string, boolean> Animation fake path -> true
M.INLINE_ANIMATIONS = {}

-- The cache of inline animations by the passed table identity. It allows to reuse the same fake path
-- and already preprocessed data instead of preprocessing the shared table on every create call.
-- Weak keys, so the animation table can be collected by GC if nobody references it anymore
---@type table<table, string> Animation table -> animation fake path
M.INLINE_ANIMATION_PATHS = setmetatable({}, { __mode = "k" })

-- The list of animation data tables that are already preprocessed. Used as a guard to never
-- preprocess the same data twice, since preprocessing mutates the data in place
-- Weak keys, so the animation data can be collected by GC if nobody references it anymore
---@type table<panthera.animation.data, boolean> Animation data -> true
M.PREPROCESSED_ANIMATIONS = setmetatable({}, { __mode = "k" })

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
		local project_data = animation_or_path --[[@as panthera.animation.project_file]]

		-- Inline animations are cached by the table identity. The same table always resolves to the
		-- same fake path, so the shared data is preprocessed only once and takes only one cache slot
		local cached_path = M.INLINE_ANIMATION_PATHS[project_data]
		if cached_path and M.LOADED_ANIMATIONS[cached_path] then
			return M.LOADED_ANIMATIONS[cached_path], cached_path, nil
		end

		local animation_path = cached_path or M.get_fake_animation_path()
		local data = project_data.data
		M.preprocess_animation_keys(data)
		M.LOADED_ANIMATIONS[animation_path] = data
		M.INLINE_ANIMATIONS[animation_path] = true
		M.INLINE_ANIMATION_PATHS[project_data] = animation_path

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


---@class panthera.animation.state_value
---@field node node
---@field property_id string
---@field value any
---@field root_start number Root time of the key that set this value
---@field source number `SOURCE_REST_POSE` or `SOURCE_KEY`
---@field order number Collect order, groups are collected in timeline order

---Sample at `time`: collect, sort, apply. Last started key on the root timeline wins,
---at the same root time start values go before keys, own keys before nested and template ones
---@param animation_state panthera.animation
---@param animation_id string
---@param time number
---@param event_callback fun(event_id: string, node: node|nil, data: any, end_value: number)|nil
---@param depth number? Sample depth, `M.SAMPLE_DEPTH_ROOT` by default
function M.set_animation_state_at_time(animation_state, animation_id, time, event_callback, depth)
	local buffer = M._get_collect_buffer(animation_state)
	buffer.depth = buffer.depth + 1
	-- Nested collect (event callback) gets its own context
	local context = buffer.context
	if buffer.depth > 1 then
		context = { values = {}, pool = buffer.pool }
	end
	context.event_callback = event_callback

	local is_ok, error_message = pcall(M._collect_and_apply, animation_state, animation_id, time, context, depth or SAMPLE_DEPTH_ROOT)

	M._release_state_values(context)
	context.event_callback = nil
	buffer.depth = buffer.depth - 1

	if not is_ok then
		error(error_message)
	end
end


---Reset the previous animation, rewind events if time goes backwards, then sample.
---@param animation_state panthera.animation
---@param animation_id string
---@param time number
---@param event_callback fun(event_id: string, node: node|nil, data: any, end_value: number)|nil
---@param depth number? Sample depth, `M.SAMPLE_DEPTH_ROOT` by default
function M.apply_sample(animation_state, animation_id, time, event_callback, depth)
	M._reset_previous(animation_state)
	if animation_state.current_time > time then
		M.reset_animation_events(animation_state)
	end
	animation_state.current_time = time
	animation_state.animation_id = animation_id
	animation_state.animation_keys_index = 1
	M.set_animation_state_at_time(animation_state, animation_id, time, event_callback, depth)
end


---@param animation_data panthera.animation.data
---@param node_id string
---@return string|panthera.animation.project_file|nil
function M.get_template_animation_path(animation_data, node_id)
	local template_paths = animation_data.metadata and animation_data.metadata.template_animation_paths
	return template_paths and template_paths[node_id]
end


---Get cached template animation state
---@param animation_state panthera.animation
---@param node_id string
---@param template_path string|panthera.animation.project_file
---@return panthera.animation
function M.get_template_animation_state(animation_state, node_id, template_path)
	local template_states = animation_state.template_states
	if not template_states then
		template_states = {}
		animation_state.template_states = template_states
	end

	local template_state = template_states[node_id]
	if template_state then
		return template_state
	end

	local get_node = function(animation_node_id)
		return animation_state.get_node(node_id .. "/" .. animation_node_id)
	end
	template_state = M.create_animation_state(template_path, animation_state.adapter, get_node)
	template_states[node_id] = template_state
	return template_state
end


---Reset animation events
---@param animation_state panthera.animation
function M.reset_animation_events(animation_state)
	animation_state.events = nil

	local template_states = animation_state.template_states
	if template_states then
		for _, template_state in pairs(template_states) do
			M.reset_animation_events(template_state)
		end
	end
end


---@param animation_state panthera.animation
---@param animation_id string
---@param node_id string
---@param property_id string
---@param time number Pass TIME_UNSTARTED to get initial value
---@return any|nil
---@return number|nil Key start time, or nil if no key started yet
function M.get_node_value_at_time(animation_state, animation_id, node_id, property_id, time)
	local animation_data = M.get_animation_data(animation_state) --[[@as panthera.animation.data]]
	local group_keys = animation_data.group_animation_keys[animation_id]
	local group = group_keys and group_keys[node_id]
	local keys = group and group[property_id]
	if not keys or #keys == 0 then
		return nil
	end

	local initial_key = keys[1]
	local set_value
	if initial_key.key_type == M.KEY_TYPE.TRIGGER then
		set_value = initial_key.start_data
	elseif initial_key.key_type == M.KEY_TYPE.TWEEN then
		set_value = initial_key.start_value
	end

	for index = #keys, 1, -1 do
		local key = keys[index]
		if M.is_key_started(key, time) then
			if key.key_type == M.KEY_TYPE.TWEEN then
				return M.get_key_value_at_time(key, time), key.start_time
			end
			if key.key_type == M.KEY_TYPE.TRIGGER then
				return key.data, key.start_time
			end
			break
		end
	end

	return set_value, nil
end


---@param animation_state panthera.animation
---@param animation_id string
---@param node_id string
---@param property_id string
---@param time number
---@return any|nil
function M.set_node_value_at_time(animation_state, animation_id, node_id, property_id, time)
	local node = M.get_node(animation_state, node_id)
	if not node then
		return nil
	end

	local set_value = M.get_node_value_at_time(animation_state, animation_id, node_id, property_id, time)
	if set_value == nil then
		return nil
	end

	animation_state.adapter.set_node_property(node, property_id, set_value)
	return set_value
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

	local groups = animation_data.group_animation_order[animation_id]
	for index = 1, #groups do
		local first_key = groups[index][1]
		if first_key.key_type == M.KEY_TYPE.TWEEN then
			local node = M.get_node(animation_state, first_key.node_id)
			if node then
				adapter.stop_tween(node, first_key.property_id)
			end
		end
	end

	return true
end


---Reset all animated values in animation id to initial state
---@param animation_state panthera.animation
---@param animation_id string
---@param visited table<panthera.animation, table<string, boolean>>|nil
function M.reset_animation_state(animation_state, animation_id, visited)
	local animation_data = M.get_animation_data(animation_state) --[[@as panthera.animation.data]]
	if not animation_data then
		return
	end

	local groups = animation_data.group_animation_order[animation_id]
	if not groups then
		return
	end

	-- Per animation_state, so two template nodes both reset
	visited = visited or {}
	local visited_animations = visited[animation_state]
	if not visited_animations then
		visited_animations = {}
		visited[animation_state] = visited_animations
	end
	if visited_animations[animation_id] then
		return
	end
	visited_animations[animation_id] = true

	for index = 1, #groups do
		local first_key = groups[index][1]
		if first_key.key_type == M.KEY_TYPE.ANIMATION then
			local child_state = M._child_sample_state(animation_state, animation_data, first_key.node_id)
			if child_state then
				M.reset_animation_state(child_state, first_key.property_id, visited)
			end
		else
			M.set_node_value_at_time(animation_state, animation_id, first_key.node_id, first_key.property_id, TIME_UNSTARTED)
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
	if node == false then
		return nil
	end

	if node == nil then
		local is_ok, result = pcall(animation_state.get_node, node_id)
		if not is_ok then
			M._log_node(animation_state, node_id, "Can't get node")
			return nil
		end
		node = result
		animation_state.nodes[node_id] = node
	end

	if not node then
		M._log_node(animation_state, node_id, "Can't find node")
		return nil
	end

	if not animation_state.adapter.is_node_valid(node) then
		animation_state.nodes[node_id] = false
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

	if key.key_type == M.KEY_TYPE.EVENT then
		M.event_animation_key(node, key, key_duration, options.callback_event)
		return true
	end
	if not node then
		return false
	end
	if key.key_type == M.KEY_TYPE.TWEEN then
		-- Engine easing, sampling uses `M._get_key_easing`
		local easing = key.easing_custom or adapter.get_easing(key.easing)
		adapter.tween_animation_key(node, key.property_id, easing, key_duration, key.start_value + (key.end_value - key.start_value))
		return true
	end
	if key.key_type == M.KEY_TYPE.TRIGGER then
		adapter.trigger_animation_key(node, key.property_id, key.data)
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
		return
	end

	local easing = M._get_key_easing(key)
	-- TODO: need to keep tween reference to cancel it
	tweener.tween(easing, key.start_value, key.end_value, duration, function(value)
		callback_event(key.event_id, node, key.data, value)
	end)
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
	if not file then
		return nil, "Failed to load file: " .. path
	end

	local file_data = file:read("*all")
	file:close()
	if not file_data then
		return nil, "Failed to load file: " .. path
	end

	local is_ok, result = pcall(json.decode, file_data)
	if not is_ok then
		return nil, "Failed to parse json: " .. path
	end
	local parsed_data = result
	if parsed_data and type(parsed_data) == TYPE_TABLE then
		return parsed_data, nil
	end

	return nil, "Failed to load file: " .. path
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
		return nil, error or ("Failed to load animation: " .. path)
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
	-- Preprocessing mutates the data in place, so it should be done only once per animation data
	if M.PREPROCESSED_ANIMATIONS[data] then
		return
	end
	M.PREPROCESSED_ANIMATIONS[data] = true

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

	-- After the editor only keys are gone, so that an emptied group is left out
	data.group_animation_order = M.get_group_animation_order(data)

	do -- Include all children metadata template_animation_paths recursive
		local paths = data.metadata.template_animation_paths
		if paths then
			-- Collect nested paths in a separate table. Inserting into the table we iterate over
			-- is undefined behavior in Lua, so collected paths are merged after the traversal
			local nested_paths = {}
			M.collect_nested_template_paths("", paths, nested_paths)

			for node_id, animation_or_path in pairs(nested_paths) do
				paths[node_id] = animation_or_path
			end
		end
	end
end


---Go deep in the child animations and record their template paths with the "template/node" prefix
---@private
---@param prefix string Node path prefix of the current animation, empty for the root one
---@param source_paths table<string, string|panthera.animation.project_file> Paths of the current animation
---@param nested_paths table<string, string|panthera.animation.project_file> Collected paths of the child animations
function M.collect_nested_template_paths(prefix, source_paths, nested_paths)
	for node_id, animation_or_path in pairs(source_paths) do
		if type(animation_or_path) == TYPE_TABLE then
			local animation = animation_or_path --[[@as panthera.animation.project_file]]

			local child_paths = animation.data.metadata.template_animation_paths
			if child_paths then
				local child_prefix = prefix .. node_id .. "/"
				for child_node_id, child_animation in pairs(child_paths) do
					nested_paths[child_prefix .. child_node_id] = child_animation
				end

				M.collect_nested_template_paths(child_prefix, child_paths, nested_paths)
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


---Order the key groups of every animation the same way the timeline is ordered, so that a sample
---resolves two groups starting at the same time exactly like the playback does.
---Holds the key arrays themselves, `keys[1]` carries the node and the property of a group
---@private
---@param animation_data panthera.animation.data
---@return table<string, panthera.animation.data.animation_key[][]>
function M.get_group_animation_order(animation_data)
	local group_order = {}
	for animation_id, group_keys in pairs(animation_data.group_animation_keys) do
		local groups = {}
		for _, node_keys in pairs(group_keys) do
			for _, keys in pairs(node_keys) do
				if keys[1] then
					groups[#groups + 1] = keys
				end
			end
		end

		table.sort(groups, M.sort_groups_function)
		group_order[animation_id] = groups
	end

	return group_order
end


---@private
---@param a panthera.animation.data.animation_key[]
---@param b panthera.animation.data.animation_key[]
function M.sort_groups_function(a, b)
	return M.sort_keys_function(a[1], b[1])
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

	local easing = M._get_key_easing(key)
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


---@param animation_state panthera.animation
---@return panthera.collect_buffer
function M._get_collect_buffer(animation_state)
	local buffer = animation_state.collect_buffer
	if not buffer then
		local pool = {}
		buffer = {
			depth = 0,
			pool = pool,
			context = { values = {}, pool = pool },
		}
		animation_state.collect_buffer = buffer
	end
	return buffer
end


---@param context panthera.collect_context
function M._release_state_values(context)
	local values = context.values
	local pool = context.pool
	local pool_index = #pool
	for index = #values, 1, -1 do
		local state_value = values[index]
		state_value.node = nil
		state_value.value = nil
		values[index] = nil
		pool_index = pool_index + 1
		pool[pool_index] = state_value
	end
end


---Sampling curve. Playback uses `adapter.get_easing`, a custom easing has to exist in both
---@param key panthera.animation.data.animation_key
---@return any
function M._get_key_easing(key)
	return key.easing_custom or tweener[key.easing] or tweener.linear
end


---@param animation_state panthera.animation
function M._reset_previous(animation_state)
	local previous_animation_id = animation_state.previous_animation_id
	if not previous_animation_id then
		return
	end
	M.reset_animation_state(animation_state, previous_animation_id)
	animation_state.previous_animation_id = nil
end


---@param animation_state panthera.animation
---@param node_id string
---@param message string
function M._log_node(animation_state, node_id, message)
	local animation_data = M.get_animation_data(animation_state)
	M.logger:warn(message, {
		binded_to = animation_data.metadata and animation_data.metadata.gui_path,
		animation_path = animation_state.animation_path,
		node_id = node_id,
	})
end


---@param keys panthera.animation.data.animation_key[]
---@param time number
---@return panthera.animation.data.animation_key|nil
function M._last_key_at(keys, time)
	local animation_key
	for index = 1, #keys do
		local key = keys[index]
		if not M.is_key_started(key, time) then
			break
		end
		animation_key = key
	end
	return animation_key
end


---Fit the inner animation into the key duration
---@param key panthera.animation.data.animation_key
---@param time number
---@param inner_duration number
---@return number local_time
---@return number time_scale
function M._inner_sample(key, time, inner_duration)
	if key.duration <= 0 or inner_duration <= 0 then
		return inner_duration, FROZEN_SCALE
	end
	local key_progress = math.min(time - key.start_time, key.duration)
	local local_time = tweener.ease(M._get_key_easing(key), 0, inner_duration, key.duration, key_progress)
	return local_time, key.duration / inner_duration
end


---@param animation_state panthera.animation
---@param animation_data panthera.animation.data
---@param node_id string
---@return panthera.animation|nil
function M._child_sample_state(animation_state, animation_data, node_id)
	if node_id == "" then
		return animation_state
	end
	local template_path = M.get_template_animation_path(animation_data, node_id)
	if not template_path then
		return nil
	end
	return M.get_template_animation_state(animation_state, node_id, template_path)
end


---@param context panthera.collect_context
---@param node node
---@param property_id string
---@param value any
---@param root_start number
---@param source number
function M._add_state_value(context, node, property_id, value, root_start, source)
	local values = context.values
	local pool = context.pool
	local pool_index = #pool
	local state_value = pool[pool_index]
	local index = #values + 1
	if state_value then
		pool[pool_index] = nil
		state_value.node = node
		state_value.property_id = property_id
		state_value.value = value
		state_value.root_start = root_start
		state_value.source = source
		state_value.order = index
	else
		state_value = {
			node = node,
			property_id = property_id,
			value = value,
			root_start = root_start,
			source = source,
			order = index,
		}
	end
	values[index] = state_value
end


---Values are applied in this order, so the last one of a node property wins:
---the later root start, then a started key over a rest pose, then the timeline order of the group
---@param a panthera.animation.state_value
---@param b panthera.animation.state_value
function M._sort_state_values(a, b)
	if a.root_start ~= b.root_start then
		return a.root_start < b.root_start
	end
	if a.source ~= b.source then
		return a.source < b.source
	end
	return a.order < b.order
end


---@param animation_state panthera.animation
---@param keys panthera.animation.data.animation_key[]
---@param time number
---@param context panthera.collect_context
function M._collect_animation_events(animation_state, keys, time, context)
	for index = 1, #keys do
		local key = keys[index]
		if not M.is_key_started(key, time) then
			break
		end

		-- Mark before callback, it can collect again
		local events = animation_state.events or {}
		animation_state.events = events
		if not events[key] then
			events[key] = key
			M.event_animation_key(nil, key, key.duration, context.event_callback)
		end
	end
end


---@param animation_state panthera.animation
---@param animation_id string
---@param node_id string
---@param property_id string
---@param keys panthera.animation.data.animation_key[]
---@param time number
---@param context panthera.collect_context
---@param time_offset number
---@param time_scale number
---@param depth number
function M._collect_own(animation_state, animation_id, node_id, property_id, keys, time, context, time_offset, time_scale, depth)
	local first_key = keys[1]
	if not first_key then
		return
	end

	local key_type = first_key.key_type
	if key_type == M.KEY_TYPE.EVENT then
		M._collect_animation_events(animation_state, keys, time, context)
		return
	end
	if key_type == M.KEY_TYPE.ANIMATION or node_id == "" then
		return
	end

	local node = M.get_node(animation_state, node_id)
	if not node then
		return
	end

	local value, key_start_time = M.get_node_value_at_time(animation_state, animation_id, node_id, property_id, time)
	if value == nil then
		return
	end

	local is_owned = key_start_time ~= nil
	local is_clip_start_pose = time < 0
	local is_root = depth == SAMPLE_DEPTH_ROOT

	-- A running clip claims only what it owns, the rest stays on the previous clip
	if not is_owned and not is_clip_start_pose and not is_root then
		return
	end

	if is_owned then
		M._add_state_value(context, node, property_id, value, time_offset + key_start_time * time_scale, SOURCE_KEY)
	else
		M._add_state_value(context, node, property_id, value, time_offset, SOURCE_REST_POSE)
	end
end


---@param animation_state panthera.animation
---@param animation_data panthera.animation.data
---@param node_id string
---@param property_id string
---@param keys panthera.animation.data.animation_key[]
---@param time number
---@param context panthera.collect_context
---@param time_offset number
---@param time_scale number
---@param depth number
function M._collect_child(animation_state, animation_data, node_id, property_id, keys, time, context, time_offset, time_scale, depth)
	local first_key = keys[1]
	if not first_key or first_key.key_type ~= M.KEY_TYPE.ANIMATION then
		return
	end

	local child_state = M._child_sample_state(animation_state, animation_data, node_id)
	if not child_state then
		return
	end

	M._collect_animation_key_state(child_state, property_id, keys, time, context, time_offset, time_scale, depth)
end


---@param animation_state panthera.animation
---@param animation panthera.animation.data.animation
---@param animation_data panthera.animation.data
---@param time number
---@param context panthera.collect_context
---@param time_offset number
---@param depth number
function M._collect_initial_state(animation_state, animation, animation_data, time, context, time_offset, depth)
	if not animation.initial_state or time < 0 then
		return
	end
	local initial_animation = M.get_animation_by_animation_id(animation_data, animation.initial_state)
	if not initial_animation or initial_animation.animation_id == animation.animation_id then
		return
	end
	M._collect_animation_state(animation_state, initial_animation.animation_id, initial_animation.duration, context, time_offset, FROZEN_SCALE, depth + 1)
end


---@param animation_state panthera.animation
---@param animation_id string
function M._warn_deep_nesting(animation_state, animation_id)
	local warning_id = animation_state.animation_path .. "#" .. animation_id
	if M.LOGGED_NESTING_WARNINGS[warning_id] then
		return
	end
	M.LOGGED_NESTING_WARNINGS[warning_id] = true
	M.logger:warn("Too deep animation nesting, the animation is probably recursive", {
		animation_path = animation_state.animation_path,
		animation_id = animation_id,
	})
end


---@param animation_state panthera.animation
---@param animation_id string
---@param time number
---@param context panthera.collect_context
---@param time_offset number Start of this animation on the root timeline
---@param time_scale number Root seconds per one second of this animation
---@param depth number
function M._collect_animation_state(animation_state, animation_id, time, context, time_offset, time_scale, depth)
	local animation_data = M.get_animation_data(animation_state)
	local animation = animation_data and M.get_animation_by_animation_id(animation_data, animation_id)
	if not animation then
		return
	end

	local groups = animation_data.group_animation_order[animation_id]
	if not groups then
		return
	end

	if depth > MAX_ANIMATION_NESTING then
		M._warn_deep_nesting(animation_state, animation_id)
		return
	end

	M._collect_initial_state(animation_state, animation, animation_data, time, context, time_offset, depth)

	-- Own keys first, then nested/template: later collected wins at the same root time
	for index = 1, #groups do
		local keys = groups[index]
		M._collect_own(animation_state, animation_id, keys[1].node_id, keys[1].property_id, keys, time, context, time_offset, time_scale, depth)
	end
	for index = 1, #groups do
		local keys = groups[index]
		M._collect_child(animation_state, animation_data, keys[1].node_id, keys[1].property_id, keys, time, context, time_offset, time_scale, depth)
	end
end


---@param animation_state panthera.animation
---@param inner_animation_id string
---@param keys panthera.animation.data.animation_key[]
---@param time number
---@param context panthera.collect_context
---@param time_offset number
---@param time_scale number
---@param depth number
function M._collect_animation_key_state(animation_state, inner_animation_id, keys, time, context, time_offset, time_scale, depth)
	local animation_key = M._last_key_at(keys, time)
	if not animation_key then
		M._collect_animation_state(animation_state, inner_animation_id, TIME_UNSTARTED, context,
			time_offset, FROZEN_SCALE, depth + 1)
		return
	end

	local animation_data = M.get_animation_data(animation_state)
	local animation_to_play = animation_data and M.get_animation_by_animation_id(animation_data, inner_animation_id)
	local inner_duration = animation_to_play and animation_to_play.duration or 0
	local local_time, inner_scale = M._inner_sample(animation_key, time, inner_duration)

	M._collect_animation_state(animation_state, inner_animation_id, local_time, context,
		time_offset + animation_key.start_time * time_scale, time_scale * inner_scale, depth + 1)
end


---@param animation_state panthera.animation
---@param animation_id string
---@param time number
---@param context panthera.collect_context
---@param depth number
function M._collect_and_apply(animation_state, animation_id, time, context, depth)
	M._collect_animation_state(animation_state, animation_id, time, context, 0, 1, depth)

	local values = context.values
	table.sort(values, M._sort_state_values)

	local adapter = animation_state.adapter
	for index = 1, #values do
		local state_value = values[index]
		adapter.set_node_property(state_value.node, state_value.property_id, state_value.value)
	end
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
