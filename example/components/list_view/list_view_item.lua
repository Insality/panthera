local COLOR_SECTION = vmath.vector4(0.72, 0.45, 0.32, 1)
local COLOR_PRIMARY = vmath.vector4(0.894, 0.506, 0.333, 1)
local COLOR_SECONDARY = vmath.vector4(0.6, 0.502, 0.902, 1)
local QUEUE_MARGIN = 16
local QUEUE_GAP = 10

---@class example.list_view_item: druid.widget
---@field root druid.container
---@field text druid.text
---@field button druid.button
---@field on_click event
local M = {}


function M:init()
	self.root = self.druid:new_container("root") --[[@as druid.container]]
	self.text = self.druid:new_text("text") --[[@as druid.text]]
	self.icon = self:get_node("icon")
	self.selected = self:get_node("panel_selected")
	self.highlight = self:get_node("panel_highlight")

	self.color_not_selected = gui.get_color(self.text.node)
	self.color_selected = gui.get_outline(self.text.node)
	self.color_selected.w = 1
	self.color_bar = gui.get_color(self.selected)
	self.text_position = gui.get_position(self.text.node)
	self.item_width = gui.get_size(self.root.node).x
	self.queue_primary = ""
	self.queue_secondary = ""

	gui.set_enabled(self.icon, false)
	gui.set_enabled(self.selected, false)

	self.node_queue = self:_create_queue_node(COLOR_PRIMARY)
	self.node_queue_secondary = self:_create_queue_node(COLOR_SECONDARY)

	self.button = self.druid:new_button("root") --[[@as druid.button]]
	self.button:set_style(nil)

	self.hover = self.druid:new_hover("root") --[[@as druid.hover]]
	self.hover.on_mouse_hover:subscribe(self.on_hover)

	self.on_click = self.button.on_click
end


---@param color vector4
---@return node
function M:_create_queue_node(color)
	local node = gui.clone(self.text.node)
	gui.set_parent(node, self.root.node)
	gui.set_pivot(node, gui.PIVOT_E)
	gui.set_size_mode(node, gui.SIZE_MODE_AUTO)
	local scale = gui.get_scale(node)
	scale.x = scale.x * 0.9
	scale.y = scale.y * 0.9
	gui.set_scale(node, scale)
	gui.set_color(node, color)
	gui.set_text(node, "")
	gui.set_enabled(node, false)
	return node
end


---Turn the item into a non interactive section header
function M:set_section()
	self.druid:remove(self.button)
	self.druid:remove(self.hover)
	gui.set_color(self.text.node, COLOR_SECTION)
	gui.set_enabled(self.selected, false)
	gui.set_enabled(self.highlight, false)
end


---Shift the item text to the right to show it as a child of a section
---@param offset number
function M:set_indent(offset)
	self.text_position.x = self.text_position.x + offset
	gui.set_position(self.text.node, self.text_position)
end


---@param width number
function M:set_width(width)
	self.item_width = width
	for _, node in ipairs({ self.root.node, self.highlight }) do
		local size = gui.get_size(node)
		size.x = width
		gui.set_size(node, size)
	end
	self:_layout_queue()
end


---@param text string
function M:set_text(text)
	self.text:set_text(text)
end


---Scale the name and the playlist numbers together, then used by a list with a smaller text
---@param multiplier number
function M:multiply_text_scale(multiplier)
	if multiplier == 1 then
		return
	end

	self.text:set_scale(gui.get_scale(self.text.node) * multiplier)
	gui.set_scale(self.node_queue, gui.get_scale(self.node_queue) * multiplier)
	gui.set_scale(self.node_queue_secondary, gui.get_scale(self.node_queue_secondary) * multiplier)
	self:_layout_queue()
end


---@param is_selected boolean
---@param is_secondary boolean? True to mark the item as the second animation track
function M:set_selected(is_selected, is_secondary)
	gui.set_enabled(self.selected, is_selected)
	gui.set_color(self.selected, is_secondary and COLOR_SECONDARY or self.color_bar)

	local color = self.color_not_selected
	if is_selected then
		color = is_secondary and COLOR_SECONDARY or self.color_selected
	end
	gui.set_color(self.text.node, color)
end


---Show the playlist positions of this animation on the primary and the second track
---@param primary_text string|nil
---@param secondary_text string|nil
function M:set_queue(primary_text, secondary_text)
	self.queue_primary = primary_text or ""
	self.queue_secondary = secondary_text or ""
	self:_layout_queue()
end


---@param node node
---@return number width
function M:_queue_text_width(node)
	return gui.get_size(node).x * gui.get_scale(node).x
end


function M:_layout_queue()
	local has_primary = self.queue_primary ~= ""
	local has_secondary = self.queue_secondary ~= ""

	gui.set_enabled(self.node_queue, has_primary)
	gui.set_enabled(self.node_queue_secondary, has_secondary)

	local x = self.item_width - QUEUE_MARGIN
	if has_secondary then
		gui.set_text(self.node_queue_secondary, self.queue_secondary)
		gui.set_position(self.node_queue_secondary, vmath.vector3(x, 0, 0))
		x = x - self:_queue_text_width(self.node_queue_secondary) - QUEUE_GAP
	end
	if has_primary then
		gui.set_text(self.node_queue, self.queue_primary)
		gui.set_position(self.node_queue, vmath.vector3(x, 0, 0))
		x = x - self:_queue_text_width(self.node_queue) - QUEUE_GAP
	end

	-- Keep the name from running into the playlist numbers
	local text_size = gui.get_size(self.text.node)
	text_size.x = math.max(x - self.text_position.x, 40)
	gui.set_size(self.text.node, text_size)
end


---@param is_hover boolean
function M:on_hover(is_hover)
	if is_hover then
		gui.animate(self.highlight, "color.w", 1, gui.EASING_OUTQUAD, 0.2)
	else
		gui.animate(self.highlight, "color.w", 0, gui.EASING_OUTQUAD, 0.1)
	end
end


return M
