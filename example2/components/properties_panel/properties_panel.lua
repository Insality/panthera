local property_checkbox = require("example2.components.properties_panel.properties.property_checkbox")
local property_slider = require("example2.components.properties_panel.properties.property_slider")
local property_button = require("example2.components.properties_panel.properties.property_button")

---A scrollable list of the playback settings. Properties are added by the example page
---and cleared when another example is selected.
---@class example2.properties_panel: druid.widget
---@field root druid.container
---@field scroll druid.scroll
---@field grid druid.grid
local M = {}


function M:init()
	self.root = self.druid:new_container("root") --[[@as druid.container]]
	self.root:add_container("text_header")
	self.root:add_container("separator")

	self.properties = {}

	self.text_header = self.druid:new_text("text_header") --[[@as druid.text]]
	self.text_no_properties = self.druid:new_text("text_no_properties") --[[@as druid.text]]

	self.scroll = self.druid:new_scroll("scroll_view", "scroll_content") --[[@as druid.scroll]]
	self.grid = self.druid:new_grid("scroll_content", "item_size", 1) --[[@as druid.grid]]
	self.scroll:bind_grid(self.grid)
	self.scroll.on_scroll:subscribe(self.on_scroll)
	self.grid.on_change_items:subscribe(self.on_grid_change_items)

	self.slider = self.druid:new_slider("scroll_bar_pin", vmath.vector3(-8, 48 - 290, 0), self.on_slider_change) --[[@as druid.slider]]
	self.slider:set_input_node("scroll_bar_view")

	self.property_checkbox_prefab = self:get_node("property_checkbox/root")
	gui.set_enabled(self.property_checkbox_prefab, false)

	self.property_slider_prefab = self:get_node("property_slider/root")
	gui.set_enabled(self.property_slider_prefab, false)

	self.property_button_prefab = self:get_node("property_button/root")
	gui.set_enabled(self.property_button_prefab, false)
end


---@param header string
function M:set_header(header)
	self.text_header:set_text(header)
end


function M:clear()
	for index = 1, #self.properties do
		self.druid:remove(self.properties[index])
	end
	self.properties = {}

	local nodes = self.grid.nodes
	for index = 1, #nodes do
		gui.delete_node(nodes[index])
	end
	self.grid:clear()

	gui.set_enabled(self.text_no_properties.node, true)
end


---@param text string
---@param initial_value boolean
---@param on_change_callback fun(value: boolean)
---@return example2.property_checkbox
function M:add_checkbox(text, initial_value, on_change_callback)
	local instance = self.druid:new_widget(property_checkbox, "property_checkbox", self.property_checkbox_prefab) --[[@as example2.property_checkbox]]
	instance.text_name:set_text(text)
	instance:set_value(initial_value, true)
	instance.button.on_click:subscribe(function()
		on_change_callback(instance:get_value())
	end)

	self:_add_property(instance)

	return instance
end


---@param text string
---@param initial_value number
---@param on_change_callback fun(value: number)
---@return example2.property_slider
function M:add_slider(text, initial_value, on_change_callback)
	local instance = self.druid:new_widget(property_slider, "property_slider", self.property_slider_prefab) --[[@as example2.property_slider]]
	instance.text_name:set_text(text)
	instance:set_value(initial_value, true)
	instance.slider.on_change_value:subscribe(function(_, value)
		on_change_callback(value)
	end)

	self:_add_property(instance)

	return instance
end


---@param text string
---@param button_text string
---@param on_click_callback fun()
---@return example2.property_button
function M:add_button(text, button_text, on_click_callback)
	local instance = self.druid:new_widget(property_button, "property_button", self.property_button_prefab) --[[@as example2.property_button]]
	instance.text_name:set_text(text)
	instance.text_button:set_text(button_text)
	instance.button.on_click:subscribe(on_click_callback)

	self:_add_property(instance)

	return instance
end


---@param instance example2.property_checkbox|example2.property_slider|example2.property_button
function M:_add_property(instance)
	gui.set_enabled(instance.root.node, true)
	self.grid:add(instance.root.node)
	table.insert(self.properties, instance)
	gui.set_enabled(self.text_no_properties.node, false)
end


---@param value number In range [0..1]
function M:on_slider_change(value)
	self.scroll:scroll_to_percent(vmath.vector3(0, 1 - value, 0), true)
end


function M:on_scroll()
	self.slider:set(1 - self.scroll:get_percent().y, true)
end


function M:on_grid_change_items()
	local is_scroll_available = self.scroll.drag.can_y
	gui.set_enabled(self.slider.node, is_scroll_available)
	if is_scroll_available then
		self.slider:set(1 - self.scroll:get_percent().y, true)
	end
end


return M
