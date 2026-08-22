local helper = require("druid.helper")
local panthera = require("panthera.panthera")

local animation = require("example2.examples.character.character_panthera")

---An example scene with its own logic. The example browser creates this widget over the template
---of the example, so a scene can react to input and add its own properties to the panel.
---
---The character is animated by three animation states over the same nodes: the browser plays the
---animations of the first one, while the two here are not played but scrubbed with
---`panthera.set_time` from the mouse position, blending the poses together.
---@class example2.character: druid.widget
---@field animation_horizontal panthera.animation
---@field animation_vertical panthera.animation
local M = {}


function M:init()
	self.root = self:get_node("root")
	self.root_size = gui.get_size(self.root)

	self.animation_horizontal = panthera.create_gui(animation, self:get_template(), self:get_nodes())
	self.animation_vertical = panthera.create_gui(animation, self:get_template(), self:get_nodes())

	self:set_blend(0.5, 0.5)

	self.druid:new_text("text_hint", "Move the mouse over the character")
end


---@param horizontal number In range [0..1]
---@param vertical number In range [0..1]
function M:set_blend(horizontal, vertical)
	-- Both animations are one second long, so the progress is the animation time
	panthera.set_time(self.animation_horizontal, "horizontal", horizontal)
	panthera.set_time(self.animation_vertical, "vertical", vertical)
end


---@private
---@param action_id hash
---@param action action
function M:on_input(action_id, action)
	-- The mouse movement comes with no action id
	if action_id ~= nil or not gui.pick_node(self.root, action.x, action.y) then
		return false
	end

	local root_screen_position = gui.get_screen_position(self.root)
	local koef_x, koef_y = helper.get_screen_aspect_koef()

	local dx = (action.screen_x - root_screen_position.x) * koef_x
	local dy = (action.screen_y - root_screen_position.y) * koef_y

	self:set_blend(
		(dx + self.root_size.x / 2) / self.root_size.x,
		(dy + self.root_size.y / 2) / self.root_size.y)

	return false
end


---Called by the example browser after it filled the panel with the playback settings
---@param properties_panel example2.properties_panel
function M:properties_control(properties_panel)
	local horizontal = properties_panel:add_slider("Turn", 0.5, function(value)
		panthera.set_time(self.animation_horizontal, "horizontal", value)
	end)
	local vertical = properties_panel:add_slider("Look", 0.5, function(value)
		panthera.set_time(self.animation_vertical, "vertical", value)
	end)

	self.sliders = { horizontal, vertical }
end


---@private
function M:update()
	if not self.sliders then
		return
	end

	-- Keep the sliders in sync while the mouse drives the animations
	self.sliders[1]:set_value(panthera.get_time(self.animation_horizontal), true)
	self.sliders[2]:set_value(panthera.get_time(self.animation_vertical), true)
end


return M
