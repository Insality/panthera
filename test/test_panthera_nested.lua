return function()
	describe("Panthera Nested", function()
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

		---An animation moving `box.position_x` from 0 to `to` over one second
		local function move_to(animation_id, to)
			return utils.animation(animation_id, 1, {
				utils.tween("box", "position_x", { duration = 1, start_value = 0, end_value = to }) })
		end


		it("A nested clip plays the inner animation on the same nodes", function()
			local project = utils.project({
				move_to("inner", 100),
				utils.animation("root", 1, { utils.clip("inner", { duration = 1 }) }),
			})
			local state, nodes = utils.create_scene(project)

			panthera.set_time(state, "root", 0.5)
			assert(utils.near(nodes.box.position_x, 50), "sampled halfway, got " .. tostring(nodes.box.position_x))

			local played, played_nodes = utils.create_scene(project)
			panthera.play(played, "root")
			utils.play_frames(30)
			assert(utils.near(played_nodes.box.position_x, 50, 3), "played halfway, got " .. tostring(played_nodes.box.position_x))
		end)


		it("A clip key stretches the inner animation over its own duration", function()
			-- One second of animation squeezed into half a second of the key
			local project = utils.project({
				move_to("inner", 100),
				utils.animation("root", 1, { utils.clip("inner", { duration = 0.5 }) }),
			})
			local state, nodes = utils.create_scene(project)

			panthera.set_time(state, "root", 0.25)
			assert(utils.near(nodes.box.position_x, 50), "half of the key is all of the inner, got " .. tostring(nodes.box.position_x))
			panthera.set_time(state, "root", 0.5)
			assert(utils.near(nodes.box.position_x, 100), "the inner is over at the key end, got " .. tostring(nodes.box.position_x))
		end)


		it("A template clip resolves its nodes under the template node", function()
			local template = utils.project({ move_to("inner", 70) })
			local project = utils.project({
				utils.animation("root", 1, { utils.clip("inner", { node_id = "holder", duration = 1 }) }),
			}, { holder = template })
			local state, nodes = utils.create_scene(project)

			panthera.set_time(state, "root", 0.5)
			assert(nodes["holder/box"] ~= nil, "the node is resolved under the template node")
			assert(utils.near(nodes["holder/box"].position_x, 35), "sampled halfway, got " .. tostring(nodes["holder/box"].position_x))
			assert(nodes.box == nil, "the bare node is never touched")
		end)


		it("A template clip plays back the same way it samples", function()
			local template = utils.project({ move_to("inner", 70) })
			local project = utils.project({
				utils.animation("root", 1, { utils.clip("inner", { node_id = "holder", duration = 1 }) }),
			}, { holder = template })
			local state, nodes = utils.create_scene(project)

			panthera.play(state, "root")
			utils.play_frames(30)
			assert(utils.near(nodes["holder/box"].position_x, 35, 3), "played halfway, got " .. tostring(nodes["holder/box"].position_x))
		end)


		it("Template paths of a template are collected with their prefix", function()
			local deep = utils.project({ move_to("inner", 40) })
			local middle = utils.project({
				utils.animation("mid", 1, { utils.clip("inner", { node_id = "leaf", duration = 1 }) }),
			}, { leaf = deep })
			local project = utils.project({
				utils.animation("root", 1, { utils.clip("mid", { node_id = "branch", duration = 1 }) }),
			}, { branch = middle })

			local state, nodes = utils.create_scene(project)
			panthera.set_time(state, "root", 0.5)
			assert(nodes["branch/leaf/box"] ~= nil, "the deep node is resolved through both prefixes")
			assert(utils.near(nodes["branch/leaf/box"].position_x, 20), "sampled halfway, got " .. tostring(nodes["branch/leaf/box"].position_x))
		end)


		it("A clip key that is already over holds the final pose", function()
			local project = utils.project({
				move_to("inner", 100),
				utils.animation("root", 1, { utils.clip("inner", { duration = 0 }) }),
			})
			local state, nodes = utils.create_scene(project)

			panthera.play(state, "root")
			utils.play_frames(2)
			assert(utils.near(nodes.box.position_x, 100), "the inner sits at its end, got " .. tostring(nodes.box.position_x))
		end)


		it("initial_state poses the other animation at its end", function()
			local project = utils.project({
				utils.animation("opened", 1, {
					utils.tween("box", "position_x", { duration = 1, start_value = 0, end_value = 500 }) }),
				utils.animation("blink", 1, {
					utils.tween("box", "scale_x", { duration = 1, start_value = 1, end_value = 2 }) }, "opened"),
			})
			local state, nodes = utils.create_scene(project)

			panthera.set_time(state, "blink", 0)
			assert(utils.near(nodes.box.position_x, 500), "opened is held at its end, got " .. tostring(nodes.box.position_x))
			assert(utils.near(nodes.box.scale_x, 1), "blink starts from its own start value, got " .. tostring(nodes.box.scale_x))

			panthera.set_time(state, "blink", 1)
			assert(utils.near(nodes.box.position_x, 500), "opened stays frozen while blink runs")
			assert(utils.near(nodes.box.scale_x, 2), "blink reaches its end, got " .. tostring(nodes.box.scale_x))
		end)


		it("A self referencing animation stops at the nesting limit instead of hanging", function()
			local project = utils.project({
				utils.animation("loop_me", 1, {
					utils.tween("box", "position_x", { duration = 1, start_value = 0, end_value = 10 }),
					utils.clip("loop_me", { duration = 1 }),
				}),
			})
			local state, nodes = utils.create_scene(project)

			panthera.set_time(state, "loop_me", 0.5)
			assert(nodes.box.position_x ~= nil, "the sample terminates and still poses the node")
		end)


		it("A clip key pointing at a missing animation is skipped", function()
			local project = utils.project({
				utils.animation("root", 1, {
					utils.tween("box", "position_x", { duration = 1, start_value = 0, end_value = 10 }),
					utils.clip("no_such_animation", { duration = 1 }),
				}),
			})
			local state, nodes = utils.create_scene(project)

			panthera.play(state, "root")
			utils.play_frames(30)
			assert(utils.near(nodes.box.position_x, 5, 1), "the rest of the timeline still runs, got " .. tostring(nodes.box.position_x))
		end)


		it("A template clip without a registered path is skipped", function()
			local project = utils.project({
				move_to("inner", 100),
				utils.animation("root", 1, {
					utils.tween("box", "position_x", { duration = 1, start_value = 0, end_value = 10 }),
					utils.clip("inner", { node_id = "missing_template", duration = 1 }),
				}),
			})
			local state, nodes = utils.create_scene(project)

			panthera.play(state, "root")
			utils.play_frames(30)
			assert(utils.near(nodes.box.position_x, 5, 1), "the rest of the timeline still runs, got " .. tostring(nodes.box.position_x))
		end)
	end)
end
