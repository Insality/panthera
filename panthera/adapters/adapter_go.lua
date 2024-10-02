local PROPERTY_TO_TWEEN_PROPERTY = {
	["position_x"] = "position.x",
	["position_y"] = "position.y",
	["position_z"] = "position.z",
	["rotation_x"] = "euler.x",
	["rotation_y"] = "euler.y",
	["rotation_z"] = "euler.z",
	["scale_x"] = "scale.x",
	["scale_y"] = "scale.y",
	["scale_z"] = "scale.z",
	["size_x"] = "size.x",
	["size_y"] = "size.y",
	["size_z"] = "size.z",
	["color_r"] = "color.x",
	["color_g"] = "color.y",
	["color_b"] = "color.z",
	["color_a"] = "color.w",
	["slice9_left"] = "slice.x",
	["slice9_top"] = "slice.y",
	["slice9_right"] = "slice.z",
	["slice9_bottom"] = "slice.w"
}

local PROPERTY_TO_TRIGGER_PROPERTY = {
	["text"] = "text",
	["texture"] = "texture",
	["enabled"] = "enabled",
}

local EASING_TO_DEFOLD_EASING = {
	["inback"] = go.EASING_INBACK,
	["inbounce"] = go.EASING_INBOUNCE,
	["incirc"] = go.EASING_INCIRC,
	["incubic"] = go.EASING_INCUBIC,
	["inelastic"] = go.EASING_INELASTIC,
	["inexpo"] = go.EASING_INEXPO,
	["inoutback"] = go.EASING_INOUTBACK,
	["inoutbounce"] = go.EASING_INOUTBOUNCE,
	["inoutcirc"] = go.EASING_INOUTCIRC,
	["inoutcubic"] = go.EASING_INOUTCUBIC,
	["inoutelastic"] = go.EASING_INOUTELASTIC,
	["inoutexpo"] = go.EASING_INOUTEXPO,
	["inoutquad"] = go.EASING_INOUTQUAD,
	["inoutquart"] = go.EASING_INOUTQUART,
	["inoutquint"] = go.EASING_INOUTQUINT,
	["inoutsine"] = go.EASING_INOUTSINE,
	["inquad"] = go.EASING_INQUAD,
	["inquart"] = go.EASING_INQUART,
	["inquint"] = go.EASING_INQUINT,
	["insine"] = go.EASING_INSINE,
	["linear"] = go.EASING_LINEAR,
	["outback"] = go.EASING_OUTBACK,
	["outbounce"] = go.EASING_OUTBOUNCE,
	["outcirc"] = go.EASING_OUTCIRC,
	["outcubic"] = go.EASING_OUTCUBIC,
	["outelastic"] = go.EASING_OUTELASTIC,
	["outexpo"] = go.EASING_OUTEXPO,
	["outinback"] = go.EASING_OUTINBACK,
	["outinbounce"] = go.EASING_OUTINBOUNCE,
	["outincirc"] = go.EASING_OUTINCIRC,
	["outincubic"] = go.EASING_OUTINCUBIC,
	["outinelastic"] = go.EASING_OUTINELASTIC,
	["outinexpo"] = go.EASING_OUTINEXPO,
	["outinquad"] = go.EASING_OUTINQUAD,
	["outinquart"] = go.EASING_OUTINQUART,
	["outinquint"] = go.EASING_OUTINQUINT,
	["outinsine"] = go.EASING_OUTINSINE,
	["outquad"] = go.EASING_OUTQUAD,
	["outquart"] = go.EASING_OUTQUART,
	["outquint"] = go.EASING_OUTQUINT,
	["outsine"] = go.EASING_OUTSINE,
}


local MSG_ENABLE_VALUE = {
	["true"] = hash("enable"),
	["false"] = hash("disable"),
}


---@param inputstr string
---@param sep string
local function split(inputstr, sep)
	sep = sep or "%s"
	local t = {}
	local i = 1
	for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end


---@param collection_name string|nil
---@param objects table<string|hash, string|hash>|nil
---@return function(node_id: string): hash|url
local function create_get_node_function(collection_name, objects)
	return function(node_id)
		if collection_name then
			node_id = collection_name .. "/" .. node_id
		end

		-- Acquire component id
		local split_index = string.find(node_id, "#")
		if split_index then
			local object_id = string.sub(node_id, 1, split_index - 1)
			local fragment_id = string.sub(node_id, split_index + 1)

			local object_path = hash("/" .. object_id)
			if objects then
				object_path = objects[object_path] --[[@as hash]]
			end

			local object_url = msg.url(object_path)
			object_url.fragment = hash(fragment_id)

			return object_url
		end

		local object_path = hash("/" .. node_id)
		if objects then
			object_path = objects[object_path] --[[@as hash]]
		end
		return object_path
	end
end


---@param node node
---@param property_id string
---@param value any
local function trigger_animation_key(node, property_id, value)
	local defold_property_id = PROPERTY_TO_TRIGGER_PROPERTY[property_id]

	if defold_property_id == "text" then
		label.set_text(node, value)
	end
	if defold_property_id == "texture" then
		local texture_name = value
		if texture_name ~= "" then
			local splitted = split(value, "/")
			sprite.play_flipbook(node, splitted[#splitted])
		end
	end
	if defold_property_id == "enabled" then
		local msg_id = MSG_ENABLE_VALUE[value]
		msg.post(node, msg_id)
	end
end


---@param node node
---@param property_id string
---@return number|string|boolean|nil
local function get_trigger_property_id(node, property_id)
	local defold_property_id = PROPERTY_TO_TRIGGER_PROPERTY[property_id]

	if defold_property_id == "text" then
		return label.get_text(node)
	end
	if defold_property_id == "texture" then
		local texture_name = go.get(node, "animation")
		local splitted = split(texture_name, "/")
		return splitted[#splitted]
	end
	if defold_property_id == "enabled" then
		return gui.is_enabled(node)
	end

	return nil
end


---@param node node
---@param property_id string
local function stop_tween(node, property_id)
	property_id = PROPERTY_TO_TWEEN_PROPERTY[property_id]
	go.cancel_animations(node, property_id)
end


---@param node node
---@param property_id string
---@param value number
---@return boolean @true if success
local function set_node_property(node, property_id, value)
	local defold_property_id = PROPERTY_TO_TRIGGER_PROPERTY[property_id]

	if defold_property_id then
		value = value or ""
		trigger_animation_key(node, defold_property_id, value)
		return true
	end

	stop_tween(node, property_id)
	defold_property_id = PROPERTY_TO_TWEEN_PROPERTY[property_id]
	if not defold_property_id then
		print("Unknown property_id: " .. property_id, debug.traceback())
		return false
	end

	go.set(node, defold_property_id, value)

	return true
end


---@param node node
---@param property_id string
---@return number|string|boolean|nil
local function get_node_property(node, property_id)
	local defold_trigger_property_id = PROPERTY_TO_TRIGGER_PROPERTY[property_id]
	if defold_trigger_property_id then
		return get_trigger_property_id(node, defold_trigger_property_id)
	end

	local defold_number_property_id = PROPERTY_TO_TWEEN_PROPERTY[property_id]
	if not defold_number_property_id then
		print("Unknown property_id: " .. property_id, debug.traceback())
		return nil
	end

	return go.get(node, defold_number_property_id)
end


---Return defold easing id
---@param easing string
---@return userdata
local function get_easing(easing)
	return EASING_TO_DEFOLD_EASING[easing] or go.EASING_LINEAR
end


---@param node node
---@param property_id string
---@param easing userdata|number[]
---@param duration number
---@param end_value number
local function tween_animation_key(node, property_id, easing, duration, end_value)
	if duration == 0 then
		set_node_property(node, property_id, end_value)
	else
		property_id = PROPERTY_TO_TWEEN_PROPERTY[property_id]
		go.animate(node, property_id, go.PLAYBACK_ONCE_FORWARD, end_value, easing, duration)
	end
end


local M = {
	get_easing = get_easing,
	set_node_property = set_node_property,
	get_node_property = get_node_property,
	tween_animation_key = tween_animation_key,
	stop_tween = stop_tween,
	trigger_animation_key = trigger_animation_key,
	create_get_node_function = create_get_node_function,
}


return M
