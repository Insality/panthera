---@class example2.property_button: druid.widget
---@field root druid.container
---@field text_name druid.text
---@field text_button druid.text
---@field button druid.button
local M = {}


function M:init()
	self.root = self.druid:new_container("root") --[[@as druid.container]]
	self.selected = self:get_node("selected")
	gui.set_alpha(self.selected, 0)

	self.text_name = self.druid:new_text("text_name") --[[@as druid.text]]
	self.text_button = self.druid:new_text("text_button") --[[@as druid.text]]
	self.button = self.druid:new_button("button", self.on_click) --[[@as druid.button]]
end


function M:on_click()
	gui.set_alpha(self.selected, 1)
	gui.animate(self.selected, "color.w", 0, gui.EASING_INSINE, 0.16)
end


return M
