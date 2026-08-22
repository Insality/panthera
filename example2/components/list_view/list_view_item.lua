local COLOR_SECTION = vmath.vector4(0.72, 0.45, 0.32, 1)
local COLOR_SECONDARY = vmath.vector4(0.6, 0.502, 0.902, 1)

---@class example2.list_view_item: druid.widget
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

	gui.set_enabled(self.icon, false)
	gui.set_enabled(self.selected, false)

	self.button = self.druid:new_button("root") --[[@as druid.button]]
	self.button:set_style(nil)

	self.hover = self.druid:new_hover("root") --[[@as druid.hover]]
	self.hover.on_mouse_hover:subscribe(self.on_hover)

	self.on_click = self.button.on_click
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
	for _, node in ipairs({ self.root.node, self.highlight }) do
		local size = gui.get_size(node)
		size.x = width
		gui.set_size(node, size)
	end
end


---@param text string
function M:set_text(text)
	self.text:set_text(text)
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


---@param is_hover boolean
function M:on_hover(is_hover)
	if is_hover then
		gui.animate(self.highlight, "color.w", 1, gui.EASING_OUTQUAD, 0.2)
	else
		gui.animate(self.highlight, "color.w", 0, gui.EASING_OUTQUAD, 0.1)
	end
end


return M
