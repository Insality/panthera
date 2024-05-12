-- In Defold 1.2.180+ gui.set and gui.get functions were added. Rotation was changed to Euler
local IS_DEFOLD_180 = (gui.set and gui.get)

local PROPERTY_TO_DEFOLD_TWEEN_PROPERTY = {
	["position_x"] = "position.x",
	["position_y"] = "position.y",
	["position_z"] = "position.z",
	["rotation_x"] = IS_DEFOLD_180 and "euler.x" or "rotation.x",
	["rotation_y"] = IS_DEFOLD_180 and "euler.y" or "rotation.y",
	["rotation_z"] = IS_DEFOLD_180 and "euler.z" or "rotation.z",
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
	["outline_r"] = "outline.x",
	["outline_g"] = "outline.y",
	["outline_b"] = "outline.z",
	["outline_a"] = "outline.w",
	["shadow_r"] = "shadow.x",
	["shadow_g"] = "shadow.y",
	["shadow_b"] = "shadow.z",
	["shadow_a"] = "shadow.w",
	["slice9_left"] = "slice9.x",
	["slice9_top"] = "slice9.y",
	["slice9_right"] = "slice9.z",
	["slice9_bottom"] = "slice9.w",
	["inner_radius"] = "inner_radius",
	["fill_angle"] = "fill_angle",
	["text_tracking"] = "tracking",
	["text_leading"] = "leading",
}

local PROPERTY_TO_DEFOLD_TRIGGER_PROPERTY = {
	["text"] = "text",
	["texture"] = "texture",
	["enabled"] = "enabled",
	["visible"] = "visible",
	["inherit_alpha"] = "inherit_alpha",
	["pivot"] = "pivot",
	["blend_mode"] = "blend_mode",
	["size_mode"] = "size_mode",
	["clipping_mode"] = "clipping_mode",
	["clipping_visible"] = "clipping_visible",
	["clipping_inverted"] = "clipping_inverted",
	["line_break"] = "line_break",
	["outer_bounds"] = "outer_bounds",
	["perimeter_verticies"] = "perimeter_verticies",
}

local EASING_TO_DEFOLD_EASING = {
	["inback"] = gui.EASING_INBACK,
	["inbounce"] = gui.EASING_INBOUNCE,
	["incirc"] = gui.EASING_INCIRC,
	["incubic"] = gui.EASING_INCUBIC,
	["inelastic"] = gui.EASING_INELASTIC,
	["inexpo"] = gui.EASING_INEXPO,
	["inoutback"] = gui.EASING_INOUTBACK,
	["inoutbounce"] = gui.EASING_INOUTBOUNCE,
	["inoutcirc"] = gui.EASING_INOUTCIRC,
	["inoutcubic"] = gui.EASING_INOUTCUBIC,
	["inoutelastic"] = gui.EASING_INOUTELASTIC,
	["inoutexpo"] = gui.EASING_INOUTEXPO,
	["inoutquad"] = gui.EASING_INOUTQUAD,
	["inoutquart"] = gui.EASING_INOUTQUART,
	["inoutquint"] = gui.EASING_INOUTQUINT,
	["inoutsine"] = gui.EASING_INOUTSINE,
	["inquad"] = gui.EASING_INQUAD,
	["inquart"] = gui.EASING_INQUART,
	["inquint"] = gui.EASING_INQUINT,
	["insine"] = gui.EASING_INSINE,
	["linear"] = gui.EASING_LINEAR,
	["outback"] = gui.EASING_OUTBACK,
	["outbounce"] = gui.EASING_OUTBOUNCE,
	["outcirc"] = gui.EASING_OUTCIRC,
	["outcubic"] = gui.EASING_OUTCUBIC,
	["outelastic"] = gui.EASING_OUTELASTIC,
	["outexpo"] = gui.EASING_OUTEXPO,
	["outinback"] = gui.EASING_OUTINBACK,
	["outinbounce"] = gui.EASING_OUTINBOUNCE,
	["outincirc"] = gui.EASING_OUTINCIRC,
	["outincubic"] = gui.EASING_OUTINCUBIC,
	["outinelastic"] = gui.EASING_OUTINELASTIC,
	["outinexpo"] = gui.EASING_OUTINEXPO,
	["outinquad"] = gui.EASING_OUTINQUAD,
	["outinquart"] = gui.EASING_OUTINQUART,
	["outinquint"] = gui.EASING_OUTINQUINT,
	["outinsine"] = gui.EASING_OUTINSINE,
	["outquad"] = gui.EASING_OUTQUAD,
	["outquart"] = gui.EASING_OUTQUART,
	["outquint"] = gui.EASING_OUTQUINT,
	["outsine"] = gui.EASING_OUTSINE,
}

local PIVOT_TO_DEFOLD_PIVOT = {
	["pivot_center"] = gui.PIVOT_CENTER,
	["pivot_n"] = gui.PIVOT_N,
	["pivot_ne"] = gui.PIVOT_NE,
	["pivot_e"] = gui.PIVOT_E,
	["pivot_se"] = gui.PIVOT_SE,
	["pivot_s"] = gui.PIVOT_S,
	["pivot_sw"] = gui.PIVOT_SW,
	["pivot_w"] = gui.PIVOT_W,
	["pivot_nw"] = gui.PIVOT_NW,
}

local BLEND_MODE_TO_DEFOLD_BLEND_MODE = {
	["alpha"] = gui.BLEND_ALPHA,
	["add"] = gui.BLEND_ADD,
	["multiply"] = gui.BLEND_MULT,
	["screen"] = 4, -- No screen blend mode in Defold gui* bindings, pick from source
}

local OUTER_BOUNDS_TO_DEFOLD_OUTER_BOUNDS = {
	["ellipse"] = gui.PIEBOUNDS_ELLIPSE,
	["rectangle"] = gui.PIEBOUNDS_RECTANGLE
}

local BOOLEAN_VALUE = {
	["true"] = true,
	["false"] = false,
}

local SIZE_MODE_TO_DEFOLD_SIZE_MODE = {
	["auto"] = gui.SIZE_MODE_AUTO,
	["manual"] = gui.SIZE_MODE_MANUAL,
}

local CLIPPING_MODE_TO_DEFOLD_CLIPPING_MODE = {
	["none"] = gui.CLIPPING_MODE_NONE,
	["stencil"] = gui.CLIPPING_MODE_STENCIL,
}

-- Used only in Defold 1.2.179-, no need to update with Euler
local TWEEN_DEFOLD_SET_GET = {
	["scale_x"] = { "scale", "x", gui.get_scale, gui.set_scale },
	["scale_y"] = { "scale", "y", gui.get_scale, gui.set_scale },
	["scale_z"] = { "scale", "z", gui.get_scale, gui.set_scale },
	["position_x"] = { "position", "x", gui.get_position, gui.set_position },
	["position_y"] = { "position", "y", gui.get_position, gui.set_position },
	["position_z"] = { "position", "z", gui.get_position, gui.set_position },
	["rotation_x"] = { "rotation", "x", gui.get_rotation, gui.set_rotation },
	["rotation_y"] = { "rotation", "y", gui.get_rotation, gui.set_rotation },
	["rotation_z"] = { "rotation", "z", gui.get_rotation, gui.set_rotation },
	["color_r"] = { "color", "x", gui.get_color, gui.set_color },
	["color_g"] = { "color", "y", gui.get_color, gui.set_color },
	["color_b"] = { "color", "z", gui.get_color, gui.set_color },
	["color_a"] = { "color", "w", gui.get_color, gui.set_color },
	["outline_r"] = { "outline", "x", gui.get_outline, gui.set_outline },
	["outline_g"] = { "outline", "y", gui.get_outline, gui.set_outline },
	["outline_b"] = { "outline", "z", gui.get_outline, gui.set_outline },
	["outline_a"] = { "outline", "w", gui.get_outline, gui.set_outline },
	["shadow_r"] = { "shadow", "x", gui.get_shadow, gui.set_shadow },
	["shadow_g"] = { "shadow", "y", gui.get_shadow, gui.set_shadow },
	["shadow_b"] = { "shadow", "z", gui.get_shadow, gui.set_shadow },
	["shadow_a"] = { "shadow", "w", gui.get_shadow, gui.set_shadow },
	["size_x"] = { "size", "x", gui.get_size, gui.set_size },
	["size_y"] = { "size", "y", gui.get_size, gui.set_size },
	["size_z"] = { "size", "z", gui.get_size, gui.set_size },
	["slice9_left"] = { "slice9", "x", gui.get_slice9, gui.set_slice9 },
	["slice9_top"] = { "slice9", "y", gui.get_slice9, gui.set_slice9 },
	["slice9_right"] = { "slice9", "z", gui.get_slice9, gui.set_slice9 },
	["slice9_bottom"] = { "slice9", "w", gui.get_slice9, gui.set_slice9 },
	["inner_radius"] = { "inner_radius", nil, gui.get_inner_radius, gui.set_inner_radius },
	["fill_angle"] = { "fill_angle", nil, gui.get_fill_angle, gui.set_fill_angle },
	["text_tracking"] = { "tracking", nil, gui.get_tracking, gui.set_tracking },
	["text_leading"] = { "leading", nil, gui.get_leading, gui.set_leading },
}

local TRIGGER_DEFOLD_SET_GET = {
	["text"] = { "text", "text", gui.get_text, gui.set_text },
	["texture"] = { "texture", "texture", gui.get_texture, gui.set_texture },
	["enabled"] = { "enabled", "enabled", gui.is_enabled, gui.set_enabled },
	["visible"] = { "visible", "visible", gui.get_visible, gui.set_visible },
	["inherit_alpha"] = { "inherit_alpha", "inherit_alpha", gui.get_inherit_alpha, gui.set_inherit_alpha },
	["pivot"] = { "pivot", "pivot", gui.get_pivot, gui.set_pivot },
	["blend_mode"] = { "blend_mode", "blend_mode", gui.get_blend_mode, gui.set_blend_mode },
	["size_mode"] = { "size_mode", "size_mode", gui.get_size_mode, gui.set_size_mode },
	["clipping_mode"] = { "clipping_mode", "clipping_mode", gui.get_clipping_mode, gui.set_clipping_mode },
	["clipping_visible"] = { "clipping_visible", "clipping_visible", gui.get_clipping_visible, gui.set_clipping_visible },
	["clipping_inverted"] = { "clipping_inverted", "clipping_inverted", gui.get_clipping_inverted, gui.set_clipping_inverted },
	["outer_bounds"] = { "outer_bounds", "outer_bounds", gui.get_outer_bounds, gui.set_outer_bounds },
	["perimeter_verticies"] = { "perimeter_verticies", "perimeter_verticies", gui.get_perimeter_vertices, gui.set_perimeter_vertices },
	["line_break"] = { "line_break", "line_break", gui.get_line_break, gui.set_line_break }
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


local DEFOLD_TRIGGER_SETTER = {
	["text"] = function(node, value)
		gui.set_text(node, value)
	end,
	["texture"] = function(node, texture_name)
		if texture_name ~= "" then
			local splitted = split(texture_name, "/")
			gui.play_flipbook(node, splitted[#splitted])
		end
	end,
	["enabled"] = function(node, value)
		gui.set_enabled(node, BOOLEAN_VALUE[value])
	end,
	["visible"] = function(node, value)
		gui.set_visible(node, BOOLEAN_VALUE[value])
	end,
	["inherit_alpha"] = function(node, value)
		gui.set_inherit_alpha(node, BOOLEAN_VALUE[value])
	end,
	["pivot"] = function(node, value)
		gui.set_pivot(node, PIVOT_TO_DEFOLD_PIVOT[value])
	end,
	["blend_mode"] = function(node, value)
		gui.set_blend_mode(node, BLEND_MODE_TO_DEFOLD_BLEND_MODE[value])
	end,
	["size_mode"] = function(node, value)
		gui.set_size_mode(node, SIZE_MODE_TO_DEFOLD_SIZE_MODE[value])
	end,
	["clipping_mode"] = function(node, value)
		gui.set_clipping_mode(node, CLIPPING_MODE_TO_DEFOLD_CLIPPING_MODE[value])
	end,
	["clipping_visible"] = function(node, value)
		gui.set_clipping_visible(node, BOOLEAN_VALUE[value])
	end,
	["clipping_inverted"] = function(node, value)
		gui.set_clipping_inverted(node, BOOLEAN_VALUE[value])
	end,
	["line_break"] = function(node, value)
		gui.set_line_break(node, BOOLEAN_VALUE[value])
	end,
	["outer_bounds"] = function(node, value)
		local outer_bounds = OUTER_BOUNDS_TO_DEFOLD_OUTER_BOUNDS[value]
		gui.set_outer_bounds(node, outer_bounds)
	end,
	["perimeter_verticies"] = function(node, value)
		gui.set_perimeter_vertices(node, value)
	end,
}


---@param node node
---@param property_id string
---@param value any
local function trigger_animation_key(node, property_id, value)
	local defold_property_id = PROPERTY_TO_DEFOLD_TRIGGER_PROPERTY[property_id]

	local trigger_setter = DEFOLD_TRIGGER_SETTER[defold_property_id]
	if trigger_setter then
		trigger_setter(node, value)
	else
		print("Unknown property_id: " .. property_id, debug.traceback())
	end
end


---@param node node
---@param property_id string
local function stop_tween(node, property_id)
	local defold_property_id = PROPERTY_TO_DEFOLD_TWEEN_PROPERTY[property_id]
	gui.cancel_animation(node, defold_property_id)
end


---@param node node
---@param property_id string
---@param value number
---@return boolean @true if success
local function set_node_property(node, property_id, value)
	-- Handle Trigger properties
	local trigger_info = TRIGGER_DEFOLD_SET_GET[property_id]
	if trigger_info then
		trigger_animation_key(node, property_id, value or "")
		return true
	end

	stop_tween(node, property_id)

	-- Handle Tween properties
	if IS_DEFOLD_180 then
		-- Handle Defold 1.2.180+ properties
		local defold_number_property_id = PROPERTY_TO_DEFOLD_TWEEN_PROPERTY[property_id]
		gui.set(node, defold_number_property_id, value)
	else
		-- Handle Defold 1.2.179- properties
		local tween_info = TWEEN_DEFOLD_SET_GET[property_id]
		if not tween_info then
			print("Unknown property_id: " .. property_id, debug.traceback())
			return false
		end

		local field, getter, setter = tween_info[2], tween_info[3], tween_info[4]
		if field then
			-- Set vector field
			local vector_value = getter(node)
			vector_value[field] = value or 0
			setter(node, vector_value)
		else
			-- Set single value
			setter(node, value)
		end
	end

	return true
end


---@param node node
---@param property_id string
---@return number|string|boolean|nil
local function get_node_property(node, property_id)
	-- Handle Trigger properties
	local trigger_info = TRIGGER_DEFOLD_SET_GET[property_id]
	if trigger_info then
		return trigger_info[3](node)
	end

	-- Handle Tween properties
	if IS_DEFOLD_180 then
		-- Handle Defold 1.2.180+ properties
		local defold_number_property_id = PROPERTY_TO_DEFOLD_TWEEN_PROPERTY[property_id]
		return gui.get(node, defold_number_property_id)
	else
		-- Handle Defold 1.2.179- properties
		local tween_info = TWEEN_DEFOLD_SET_GET[property_id]
		if not tween_info then
			print("Unknown property_id: " .. property_id, debug.traceback())
			return false
		end

		local field, getter = tween_info[2], tween_info[3]
		if field then
			-- Get vector field
			local vector_value = getter(node)
			return vector_value[field]
		else
			-- Get single value
			return getter(node)
		end
	end
end


---Return defold easing id
---@param easing string
---@return userdata
local function get_easing(easing)
	return EASING_TO_DEFOLD_EASING[easing] or gui.EASING_LINEAR
end


---@param node node
---@param property_id string
---@param easing userdata
---@param duration number
---@param end_value number
local function tween_animation_key(node, property_id, easing, duration, end_value)
	if duration == 0 then
		set_node_property(node, property_id, end_value)
	else
		property_id = PROPERTY_TO_DEFOLD_TWEEN_PROPERTY[property_id]
		gui.animate(node, property_id, end_value, easing, duration)
	end
end


local M = {
	get_node = gui.get_node,
	get_easing = get_easing,
	stop_tween = stop_tween,
	set_node_property = set_node_property,
	get_node_property = get_node_property,
	tween_animation_key = tween_animation_key,
	trigger_animation_key = trigger_animation_key,
}


return M
