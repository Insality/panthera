local event = require("event.event")

local SLIDER_WIDTH = 880

---The playback bar under the animation scene. Shows the current animation id and time
---and allows to scrub the animation back and forth with the slider.
---@class example2.timeline: druid.widget
---@field root druid.container
---@field slider druid.slider
---@field on_scrub event fun(progress: number) Triggered when the user drags the timeline slider
---@field on_play_click event fun() Triggered on the play/stop button click
local M = {}


function M:init()
	self.root = self.druid:new_container("root") --[[@as druid.container]]

	self.text_animation_id = self.druid:new_text("text_animation_id") --[[@as druid.text]]
	self.text_time = self.druid:new_text("text_time") --[[@as druid.text]]

	self.icon_play = self:get_node("icon_play")
	self.icon_pause = self:get_node("icon_pause")

	self.slider_fill = self:get_node("slider_fill")
	self.slider_fill_size = gui.get_size(self.slider_fill)

	self.slider = self.druid:new_slider("slider_pin", vmath.vector3(SLIDER_WIDTH / 2, 0, 0), self._on_slider_change) --[[@as druid.slider]]
	self.slider:set_input_node("slider")

	self.button_play = self.druid:new_button("button_play", self._on_play_click) --[[@as druid.button]]

	self.on_scrub = event.create()
	self.on_play_click = event.create()

	self:set_state(nil, 0, 0, false)
end


---@param animation_id string|nil
---@param time number Current animation time in seconds
---@param duration number Total animation duration in seconds
---@param is_playing boolean
function M:set_state(animation_id, time, duration, is_playing)
	-- The state is refreshed every frame, update the texts only when they are changed
	if self._animation_id ~= animation_id then
		self._animation_id = animation_id
		self.text_animation_id:set_text(animation_id or "No animation selected")
		self.slider:set_enabled(animation_id ~= nil)
	end

	local time_text = string.format("%.2f / %.2f", time, duration)
	if self._time_text ~= time_text then
		self._time_text = time_text
		self.text_time:set_text(time_text)
	end

	local progress = duration > 0 and (time / duration) or 0
	progress = math.min(math.max(progress, 0), 1)

	self.slider:set(progress, true)
	self.slider_fill_size.x = math.max(SLIDER_WIDTH * progress, 10)
	gui.set_size(self.slider_fill, self.slider_fill_size)

	gui.set_enabled(self.icon_play, not is_playing)
	gui.set_enabled(self.icon_pause, is_playing)
end


---@param value number In range [0..1]
function M:_on_slider_change(value)
	self.on_scrub:trigger(value)
end


function M:_on_play_click()
	self.on_play_click:trigger()
end


return M
