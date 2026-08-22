local event = require("event.event")

---@class example.property_slider: druid.widget
---@field on_reset event Triggered by a click on the name of the property
---@field root druid.container
---@field text_name druid.text
---@field text_value druid.text
---@field slider druid.slider
local M = {}


function M:init()
	self.root = self.druid:new_container("root") --[[@as druid.container]]
	self.selected = self:get_node("selected")
	gui.set_alpha(self.selected, 0)
	self._value = 0

	self.text_name = self.druid:new_text("text_name") --[[@as druid.text]]
	self.text_value = self.druid:new_text("text_value") --[[@as druid.text]]
	self.slider = self.druid:new_slider("slider_pin", vmath.vector3(68, 0, 0), self._on_slider_change_by_user) --[[@as druid.slider]]
	self.slider:set_input_node("slider")

	self:set_text_function(function(value)
		return math.floor(value * 100) .. "%"
	end)

	self.on_reset = event.create()
	self.druid:new_button("text_name", function()
		self.on_reset:trigger()
	end)
end


---@param callback fun(value: number): string
function M:set_text_function(callback)
	self._text_function = callback
	self.text_value:set_text(self._text_function(self._value))
end


---@param value number
---@param is_instant boolean?
function M:set_value(value, is_instant)
	if self._value == value then
		return
	end

	self._value = value
	self.slider:set(value, true)
	self.text_value:set_text(self._text_function(value))

	if not is_instant then
		gui.set_alpha(self.selected, 1)
		gui.animate(self.selected, "color.w", 0, gui.EASING_INSINE, 0.16)
	end
end


---@return number
function M:get_value()
	return self._value
end


function M:_on_slider_change_by_user(value)
	self._value = value
	self.text_value:set_text(self._text_function(value))

	gui.set_alpha(self.selected, 1)
	gui.animate(self.selected, "color.w", 0, gui.EASING_INSINE, 0.16)
end


return M
