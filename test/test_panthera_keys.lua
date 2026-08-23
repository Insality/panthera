return function()
	describe("Panthera Keys", function()
		---@type panthera
		local panthera
		local test_engine
		local utils

		before(function()
			panthera = require("panthera.panthera")
			test_engine = require("test.test_engine")
			utils = require("test.test_utils")
			panthera.set_logger(nil)
			test_engine.mock()
		end)

		after(function()
			test_engine.unmock()
		end)


		it("A tween key eases from its start value to its end value", function()
			local project = utils.project({ utils.animation("run", 1, {
				utils.tween("box", "position_x", { duration = 1, start_value = 100, end_value = 200 }) }) })
			local state, nodes = utils.create_scene(project)

			panthera.set_time(state, "run", 0)
			assert(utils.near(nodes.box.position_x, 100), "start value, got " .. tostring(nodes.box.position_x))
			panthera.set_time(state, "run", 0.5)
			assert(utils.near(nodes.box.position_x, 150), "halfway, got " .. tostring(nodes.box.position_x))
			panthera.set_time(state, "run", 1)
			assert(utils.near(nodes.box.position_x, 200), "end value, got " .. tostring(nodes.box.position_x))
		end)


		it("A tween key value is clamped outside of its own range", function()
			local project = utils.project({ utils.animation("run", 2, {
				utils.tween("box", "position_x", { start_time = 0.5, duration = 1, start_value = 10, end_value = 20 }) }) })
			local state, nodes = utils.create_scene(project)

			panthera.set_time(state, "run", 0.2)
			assert(utils.near(nodes.box.position_x, 10), "before the key it holds the start value")
			panthera.set_time(state, "run", 2)
			assert(utils.near(nodes.box.position_x, 20), "after the key it holds the end value")
		end)


		it("A key of zero duration cuts to its end value", function()
			local project = utils.project({ utils.animation("run", 1, {
				utils.tween("box", "position_x", { start_time = 0.5, duration = 0, start_value = 1, end_value = 9 }) }) })
			local state, nodes = utils.create_scene(project)

			panthera.set_time(state, "run", 0.4)
			assert(utils.near(nodes.box.position_x, 1), "start value before the cut")
			panthera.set_time(state, "run", 0.5)
			assert(utils.near(nodes.box.position_x, 9), "end value at the cut instant")
		end)


		it("A trigger key sets its data, and its start data before it", function()
			local project = utils.project({ utils.animation("run", 1, {
				utils.trigger("label", "text", { start_time = 0.5, data = "after", start_data = "before" }) }) })
			local state, nodes = utils.create_scene(project)

			panthera.set_time(state, "run", 0)
			assert(nodes.label.text == "before", "start data, got " .. tostring(nodes.label.text))
			panthera.set_time(state, "run", 0.5)
			assert(nodes.label.text == "after", "data at the trigger, got " .. tostring(nodes.label.text))
		end)


		it("A trigger key fires during playback", function()
			local project = utils.project({ utils.animation("run", 1, {
				utils.trigger("label", "text", { start_time = 0.5, data = "fired", start_data = "idle" }) }) })
			local state, nodes = utils.create_scene(project)

			panthera.play(state, "run")
			assert(nodes.label.text == "idle", "the start data is applied on play")
			utils.play_frames(20) -- 0.33
			assert(nodes.label.text == "idle", "not fired yet")
			utils.play_frames(12) -- 0.53
			assert(nodes.label.text == "fired", "fired, got " .. tostring(nodes.label.text))
		end)


		it("An event key of zero duration calls back once with its data", function()
			local project = utils.project({ utils.animation("run", 1, {
				utils.event("boom", { start_time = 0.5, data = "payload", end_value = 42 }) }) })
			local state = utils.create_scene(project)

			local calls = {}
			panthera.play(state, "run", { callback_event = function(event_id, node, data, value)
				calls[#calls + 1] = { event_id = event_id, data = data, value = value }
			end })

			utils.play_frames(20)
			assert(#calls == 0, "not fired before its time, got " .. #calls)
			utils.play_frames(40)
			assert(#calls == 1, "fired exactly once, got " .. #calls)
			assert(calls[1].event_id == "boom", "event id")
			assert(calls[1].data == "payload", "event data")
			assert(calls[1].value == 42, "event end value")
		end)


		it("An event key with a duration streams its eased value", function()
			local project = utils.project({ utils.animation("run", 1, {
				utils.event("stream", { duration = 0.5, start_value = 0, end_value = 100 }) }) })
			local state = utils.create_scene(project)

			local values = {}
			panthera.play(state, "run", { callback_event = function(_, _, _, value)
				values[#values + 1] = value
			end })

			utils.play_frames(40)
			assert(#values > 1, "the value is streamed over the key duration, got " .. #values)
			assert(utils.near(values[1], 0, 5), "starts near the start value, got " .. tostring(values[1]))
			assert(utils.near(values[#values], 100, 5), "ends at the end value, got " .. tostring(values[#values]))
		end)


		it("An event fires once per loop and rewinds when the time goes back", function()
			local project = utils.project({ utils.animation("run", 1, { utils.event("tick", { start_time = 0.5 }) }) })
			local state = utils.create_scene(project)

			local count = 0
			local on_event = function() count = count + 1 end

			panthera.set_time(state, "run", 0.6, on_event)
			assert(count == 1, "fired on the first sample, got " .. count)
			panthera.set_time(state, "run", 0.7, on_event)
			assert(count == 1, "not fired again while the time moves forward, got " .. count)
			panthera.set_time(state, "run", 0.1, on_event)
			panthera.set_time(state, "run", 0.6, on_event)
			assert(count == 2, "fired again after the time went back, got " .. count)
		end)


		it("A custom easing curve drives the sampled value", function()
			-- The curve peaks in the middle, so the value overshoots the end value there
			local project = utils.project({ utils.animation("run", 1, {
				utils.tween("box", "position_x", { duration = 1, start_value = 0, end_value = 100,
					easing_custom = { 0, 1, 2, 1, 0 } }) }) })
			local state, nodes = utils.create_scene(project)

			panthera.set_time(state, "run", 0)
			assert(utils.near(nodes.box.position_x, 0), "starts at 0, got " .. tostring(nodes.box.position_x))
			panthera.set_time(state, "run", 0.5)
			assert(utils.near(nodes.box.position_x, 200), "peaks at 200, got " .. tostring(nodes.box.position_x))
			panthera.set_time(state, "run", 1)
			assert(utils.near(nodes.box.position_x, 0), "returns to 0, got " .. tostring(nodes.box.position_x))
		end)


		it("A named easing is resolved for both sampling and playback", function()
			local project = utils.project({ utils.animation("run", 1, {
				utils.tween("box", "position_x", { duration = 1, start_value = 0, end_value = 100, easing = "inquad" }) }) })

			local sampled, sampled_nodes = utils.create_scene(project)
			panthera.set_time(sampled, "run", 0.5)
			assert(utils.near(sampled_nodes.box.position_x, 25), "inquad at the half is 25, got " .. tostring(sampled_nodes.box.position_x))

			local played, played_nodes = utils.create_scene(project)
			panthera.play(played, "run")
			utils.play_frames(30)
			assert(utils.near(played_nodes.box.position_x, 25, 3), "playback agrees, got " .. tostring(played_nodes.box.position_x))
		end)


		it("An editor only key hands its start value to the next key", function()
			local project = utils.project({ utils.animation("run", 1, {
				utils.tween("box", "position_x", { duration = 0, start_value = 55, end_value = 55, is_editor_only = true }),
				utils.tween("box", "position_x", { start_time = 0.5, duration = 0.5, start_value = 0, end_value = 99 }),
			}) })
			local state, nodes = utils.create_scene(project)

			panthera.set_time(state, "run", 0.5)
			assert(utils.near(nodes.box.position_x, 55), "the next key took the editor start value, got " .. tostring(nodes.box.position_x))
		end)
	end)
end
