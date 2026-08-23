return function()
	describe("Panthera Playback", function()
		---@type panthera
		local panthera
		local test_engine
		local utils
		local project

		before(function()
			panthera = require("panthera.panthera")
			test_engine = require("test.test_engine")
			utils = require("test.test_utils")
			panthera.set_logger(nil)
			panthera.SPEED = 1
			test_engine.mock()

			project = utils.project({
				utils.animation("move", 1, {
					utils.tween("box", "position_x", { duration = 1, start_value = 0, end_value = 100 }) }),
				utils.animation("back", 1, {
					utils.tween("box", "position_x", { duration = 1, start_value = 100, end_value = 0 }) }),
				utils.animation("blink", 0.1, {
					utils.tween("box", "scale_x", { duration = 0.1, start_value = 0, end_value = 1 }) }),
			})
		end)

		after(function()
			panthera.SPEED = 1
			test_engine.unmock()
		end)


		it("Playing reports its time and its state", function()
			local state = utils.create_scene(project)
			assert(panthera.is_playing(state) == false, "not playing before play")
			assert(panthera.get_duration(state, "move") == 1, "duration is read from the data")

			panthera.play(state, "move")
			assert(panthera.is_playing(state) == true, "playing after play")
			utils.play_frames(30)
			assert(utils.near(panthera.get_time(state), 0.5, 0.02), "time advances, got " .. panthera.get_time(state))
			assert(panthera.get_latest_animation_id(state) == "move", "the current animation is reported")

			panthera.stop(state)
			assert(panthera.is_playing(state) == false, "not playing after stop")
			assert(panthera.get_latest_animation_id(state) == "move", "the last animation is still reported")
		end)


		it("The finish callback fires once with the animation id", function()
			local state = utils.create_scene(project)
			local finished = {}
			panthera.play(state, "move", { callback = function(animation_id) finished[#finished + 1] = animation_id end })

			utils.play_frames(50)
			assert(#finished == 0, "not finished yet, got " .. #finished)
			utils.play_frames(20)
			assert(#finished == 1, "finished once, got " .. #finished)
			assert(finished[1] == "move", "the animation id is passed")
		end)


		it("A loop keeps running and compensates the time overflow", function()
			local state = utils.create_scene(project)
			local loops = 0
			panthera.play(state, "blink", { is_loop = true, callback = function() loops = loops + 1 end })

			utils.play_frames(60) -- one second of a 0.1s animation
			assert(loops >= 9 and loops <= 11, "about ten loops in a second, got " .. loops)
			assert(panthera.is_playing(state) == true, "still playing")
			panthera.stop(state)
		end)


		it("options.speed scales the playback", function()
			local state, nodes = utils.create_scene(project)
			panthera.play(state, "move", { speed = 2 })

			utils.play_frames(15) -- 0.25 real seconds, 0.5 of the animation
			assert(utils.near(nodes.box.position_x, 50, 3), "twice as far, got " .. tostring(nodes.box.position_x))
			utils.play_frames(20)
			assert(panthera.is_playing(state) == false, "over in half the time")
		end)


		it("The state speed and panthera.SPEED both scale the playback", function()
			local state, nodes = utils.create_scene(project)
			state.speed = 2
			panthera.play(state, "move")
			utils.play_frames(15)
			assert(utils.near(nodes.box.position_x, 50, 3), "the state speed applies, got " .. tostring(nodes.box.position_x))
			panthera.stop(state)

			panthera.SPEED = 2
			local global_state, global_nodes = utils.create_scene(project)
			panthera.play(global_state, "move")
			utils.play_frames(15)
			assert(utils.near(global_nodes.box.position_x, 50, 3), "the global speed applies, got " .. tostring(global_nodes.box.position_x))
			panthera.stop(global_state)
		end)


		it("is_skip_init leaves the nodes where they are", function()
			local state, nodes = utils.create_scene(project)
			nodes.box = { id = "box", position_x = 777 }

			panthera.play(state, "move", { is_skip_init = true })
			assert(nodes.box.position_x == 777, "the initial pose is not applied, got " .. tostring(nodes.box.position_x))

			local reset_state, reset_nodes = utils.create_scene(project)
			reset_nodes.box = { id = "box", position_x = 777 }
			panthera.play(reset_state, "move")
			assert(reset_nodes.box.position_x == 0, "without the flag the start value is applied, got " .. tostring(reset_nodes.box.position_x))
		end)


		it("Playing another animation resets the previous one", function()
			local state, nodes = utils.create_scene(project)
			panthera.play(state, "move")
			utils.play_frames(70)
			assert(utils.near(nodes.box.position_x, 100), "move is over at 100")

			panthera.play(state, "blink")
			assert(utils.near(nodes.box.position_x, 0), "move was reset to its start value, got " .. tostring(nodes.box.position_x))
			panthera.stop(state)
		end)


		it("Stopping mid animation leaves the nodes where they were", function()
			local state, nodes = utils.create_scene(project)
			panthera.play(state, "move")
			utils.play_frames(30)
			local at_stop = nodes.box.position_x

			panthera.stop(state)
			utils.play_frames(30)
			assert(nodes.box.position_x == at_stop, "the value is frozen at the stop, got " .. tostring(nodes.box.position_x))
			assert(test_engine.tween_count() == 0, "the tween is cancelled")
		end)


		it("An easing option routes the playback through the tweener", function()
			local state, nodes = utils.create_scene(project)
			local finished = 0
			panthera.play(state, "move", { easing = "inquad", callback = function() finished = finished + 1 end })

			utils.play_frames(30)
			-- The tweener eases the timeline itself, so the animation is behind the linear one
			assert(nodes.box.position_x < 40, "the timeline is eased, got " .. tostring(nodes.box.position_x))
			utils.play_frames(40)
			assert(utils.near(nodes.box.position_x, 100, 1), "reaches the end, got " .. tostring(nodes.box.position_x))
			assert(finished == 1, "the callback fires once, got " .. finished)
		end)


		it("play_tweener honours from and to", function()
			local state, nodes = utils.create_scene(project)
			panthera.play_tweener(state, "move", { from = 1, to = 0 })

			utils.play_frames(2)
			assert(nodes.box.position_x > 90, "starts from the end of the timeline, got " .. tostring(nodes.box.position_x))
			utils.play_frames(70)
			assert(utils.near(nodes.box.position_x, 0, 1), "plays back to the start, got " .. tostring(nodes.box.position_x))
		end)


		it("A detached animation runs beside the main one", function()
			local state, nodes = utils.create_scene(project)
			local finished = 0

			panthera.play(state, "move")
			panthera.play_detached(state, "blink", { callback = function() finished = finished + 1 end })

			utils.play_frames(12) -- blink is 0.1s, it is over
			assert(finished == 1, "the detached callback fired, got " .. finished)
			assert(utils.near(nodes.box.scale_x, 1), "the detached animation ran, got " .. tostring(nodes.box.scale_x))
			assert(panthera.is_playing(state) == true, "the main animation is untouched")
			assert(nodes.box.position_x > 0, "the main animation kept running")

			panthera.stop(state)
		end)


		it("Stopping the parent stops its detached children", function()
			local state, nodes = utils.create_scene(project)
			panthera.play(state, "move")
			panthera.play_detached(state, "move")
			assert(#state.childs == 1, "the detached child is tracked, got " .. #state.childs)

			utils.play_frames(10)
			panthera.stop(state)
			local at_stop = nodes.box.position_x
			utils.play_frames(30)
			assert(nodes.box.position_x == at_stop, "nothing keeps animating after the stop")
			assert(test_engine.timer_count() == 0, "every timer is cancelled, got " .. test_engine.timer_count())
		end)


		it("Stop of a nil state is reported and does not throw", function()
			assert(panthera.stop(nil) == false, "stop reports the failure")
		end)


		it("Playing an unknown animation id is reported", function()
			local state = utils.create_scene(project)
			local logged = 0
			panthera.set_logger({
				trace = function() end, debug = function() end, info = function() end,
				warn = function() logged = logged + 1 end,
				error = function() logged = logged + 1 end,
			})

			panthera.play(state, "no_such_animation")
			assert(logged == 1, "the error is logged, got " .. logged)
			assert(panthera.is_playing(state) == false, "nothing is playing")

			assert(panthera.set_time(state, "no_such_animation", 0.5) == false, "set_time reports the failure")
			panthera.set_logger(nil)
		end)
	end)
end
