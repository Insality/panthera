-- Builders for synthetic animation data and the scene helpers shared by the test files

local test_engine = require("test.test_engine")

local M = {}

M.FRAME = 1 / 60


---@param node_id string
---@param property_id string
---@param params table? start_time, duration, start_value, end_value, easing, easing_custom, is_editor_only
---@return panthera.animation.data.animation_key
function M.tween(node_id, property_id, params)
	params = params or {}
	return {
		key_type = "tween",
		node_id = node_id,
		property_id = property_id,
		easing = params.easing or "linear",
		easing_custom = params.easing_custom,
		start_time = params.start_time or 0,
		duration = params.duration or 0,
		start_value = params.start_value or 0,
		end_value = params.end_value or 0,
		is_editor_only = params.is_editor_only,
	}
end


---@param node_id string
---@param property_id string
---@param params table? data, start_data, start_time
---@return panthera.animation.data.animation_key
function M.trigger(node_id, property_id, params)
	params = params or {}
	return {
		key_type = "trigger",
		node_id = node_id,
		property_id = property_id,
		easing = "linear",
		start_time = params.start_time or 0,
		duration = 0,
		data = params.data,
		start_data = params.start_data,
	}
end


---@param event_id string
---@param params table? data, start_time, duration, start_value, end_value
---@return panthera.animation.data.animation_key
function M.event(event_id, params)
	params = params or {}
	return {
		key_type = "event",
		node_id = "",
		property_id = "event",
		event_id = event_id,
		easing = params.easing or "linear",
		start_time = params.start_time or 0,
		duration = params.duration or 0,
		start_value = params.start_value or 0,
		end_value = params.end_value or 0,
		data = params.data,
	}
end


---A nested clip when `params.node_id` is omitted, a template clip when it names a template node
---@param animation_id string
---@param params table? node_id, start_time, duration, easing
---@return panthera.animation.data.animation_key
function M.clip(animation_id, params)
	params = params or {}
	return {
		key_type = "animation",
		node_id = params.node_id or "",
		property_id = animation_id,
		easing = params.easing or "linear",
		start_time = params.start_time or 0,
		duration = params.duration or 1,
	}
end


---@param animation_id string
---@param duration number
---@param keys panthera.animation.data.animation_key[]
---@param initial_state string?
---@return panthera.animation.data.animation
function M.animation(animation_id, duration, keys, initial_state)
	return {
		animation_id = animation_id,
		duration = duration,
		animation_keys = keys,
		initial_state = initial_state,
	}
end


---@param animations panthera.animation.data.animation[]
---@param template_paths table<string, string|table>?
---@return panthera.animation.project_file
function M.project(animations, template_paths)
	return {
		type = "animation_editor",
		format = "json",
		version = 1,
		data = {
			nodes = {},
			animations = animations,
			metadata = {
				fps = 60,
				gui_path = "test",
				settings = {},
				gizmo_steps = {},
				template_animation_paths = template_paths or {},
			},
		},
	}
end


---Nodes are plain tables created on demand, so any node id resolves
---@param animation_or_path string|table
---@return panthera.animation, table<string, table>
function M.create_scene(animation_or_path)
	local panthera = require("panthera.panthera")
	local nodes = {}
	local get_node = function(node_id)
		nodes[node_id] = nodes[node_id] or { id = node_id }
		return nodes[node_id]
	end
	return panthera.create(animation_or_path, test_engine.create_adapter(), get_node), nodes
end


function M.play_frames(count)
	for _ = 1, count do
		test_engine.step(M.FRAME)
	end
end


---Run `callback` in the gui script context of the collection bridge
---@generic T
---@param callback fun(): T
---@return T
function M.in_gui(callback)
	local events = require("event.events")
	return events.trigger("panthera_test.in_gui", callback)
end


function M.near(a, b, epsilon)
	return type(a) == "number" and math.abs(a - b) <= (epsilon or 0.001)
end


return M
