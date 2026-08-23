-- Frame control for the Panthera tests. `timer` is mocked so a frame is one deterministic
-- unit of work, and the adapter animates plain tables instead of gui nodes.

local mock = require("deftest.mock.mock")
local time_mock = require("deftest.mock.time")

local M = {}

local timers = {}
local tweens = {}
local timer_counter = 0
local next_order = 0

---Defold makes no promise about the order of the timers of one frame.
---Set to true to run them from the newest to the oldest
M.is_reverse_timers = false


---Drop every timer and tween, without touching the mock itself
function M.reset()
	timers = {}
	tweens = {}
	timer_counter = 0
	next_order = 0
	M.is_reverse_timers = false
end


function M.mock()
	M.reset()

	-- Tweener measures its progress with `socket.gettime`, so the clock steps with the frame
	time_mock.mock()
	time_mock.set(0)

	mock.mock(timer)

	timer.delay.replace(function(_, is_repeating, callback)
		timer_counter = timer_counter + 1
		next_order = next_order + 1
		timers[timer_counter] = { callback = callback, is_repeating = is_repeating, order = next_order }
		return timer_counter
	end)

	timer.cancel.replace(function(timer_id)
		timers[timer_id] = nil
	end)

	timer.trigger.replace(function(timer_id)
		local handle = timers[timer_id]
		if handle then
			handle.callback(nil, timer_id, 0)
		end
	end)
end


function M.unmock()
	time_mock.unmock()
	mock.unmock(timer)
	timers = {}
	tweens = {}
end


local function tween_id(node, property_id)
	return tostring(node) .. "#" .. property_id
end


---One tween per node and property, started from the current value, like `gui.animate`
---@return panthera.adapter
function M.create_adapter()
	local tweener = require("tweener.tweener")

	return {
		get_easing = function(easing_id) return easing_id end,
		is_node_valid = function(node) return node ~= nil end,
		event_animation_key = function() end,
		set_node_property = function(node, property_id, value)
			node[property_id] = value
			return true
		end,
		trigger_animation_key = function(node, property_id, value)
			node[property_id] = value
		end,
		stop_tween = function(node, property_id)
			tweens[tween_id(node, property_id)] = nil
		end,
		tween_animation_key = function(node, property_id, easing, duration, end_value)
			if duration <= 0 then
				node[property_id] = end_value
				tweens[tween_id(node, property_id)] = nil
				return
			end

			tweens[tween_id(node, property_id)] = {
				node = node,
				property_id = property_id,
				from = node[property_id] or 0,
				to = end_value,
				easing = tweener[easing] or tweener.linear,
				duration = duration,
				elapsed = 0,
			}
		end,
	}
end


---Run one frame: the timers first, then the running tweens
function M.step(dt)
	local tweener = require("tweener.tweener")
	time_mock.elapse(dt)

	local ordered = {}
	for timer_id, handle in pairs(timers) do
		ordered[#ordered + 1] = { timer_id = timer_id, handle = handle }
	end
	if M.is_reverse_timers then
		table.sort(ordered, function(a, b) return a.handle.order > b.handle.order end)
	else
		table.sort(ordered, function(a, b) return a.handle.order < b.handle.order end)
	end

	for index = 1, #ordered do
		local entry = ordered[index]
		-- An earlier callback of this frame could have cancelled it
		if timers[entry.timer_id] then
			entry.handle.callback(nil, entry.timer_id, dt)
			if not entry.handle.is_repeating then
				timers[entry.timer_id] = nil
			end
		end
	end

	for id, tween in pairs(tweens) do
		tween.elapsed = math.min(tween.elapsed + dt, tween.duration)
		tween.node[tween.property_id] = tweener.ease(tween.easing, tween.from, tween.to, tween.duration, tween.elapsed)
		if tween.elapsed >= tween.duration then
			tweens[id] = nil
		end
	end
end


local function count(container)
	local total = 0
	for _ in pairs(container) do
		total = total + 1
	end
	return total
end


function M.tween_count() return count(tweens) end
function M.timer_count() return count(timers) end


return M
