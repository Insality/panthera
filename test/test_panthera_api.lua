return function()
	describe("Panthera API", function()
		---@type panthera
		local panthera
		local panthera_internal
		local test_engine
		local utils
		local project

		local ANIMATION_PATH = "/test/test_animation.json"
		local NOT_ANIMATION_PATH = "/test/test_not_animation.json"

		before(function()
			panthera = require("panthera.panthera")
			panthera_internal = require("panthera.panthera_internal")
			test_engine = require("test.test_engine")
			utils = require("test.test_utils")
			panthera.set_logger(nil)
			test_engine.mock()

			project = utils.project({
				utils.animation("move", 1, {
					utils.tween("box", "position_x", { duration = 1, start_value = 0, end_value = 100 }) }),
				utils.animation("blink", 0.5, {
					utils.tween("box", "scale_x", { duration = 0.5, start_value = 0, end_value = 1 }) }),
			})
		end)

		after(function()
			test_engine.unmock()
		end)

		---@return fun(node_id: string): table
		local function node_source(nodes)
			return function(node_id)
				nodes[node_id] = nodes[node_id] or { id = node_id }
				return nodes[node_id]
			end
		end


		it("get_animations lists every animation of the data", function()
			local state = utils.create_scene(project)
			local ids = panthera.get_animations(state)
			table.sort(ids)
			assert(#ids == 2, "two animations, got " .. #ids)
			assert(ids[1] == "blink" and ids[2] == "move", "the ids are listed")
		end)


		it("A cloned state animates the same nodes independently", function()
			local nodes = {}
			local state = panthera.create(project, test_engine.create_adapter(), node_source(nodes))
			local clone = panthera.clone_state(state)

			assert(clone ~= state, "the clone is a new state")
			assert(clone.animation_path == state.animation_path, "both share the loaded data")

			panthera.play(clone, "move")
			utils.play_frames(30)
			assert(nodes.box.position_x > 0, "the clone drives the same nodes")
			assert(panthera.is_playing(state) == false, "the source state is untouched")
			panthera.stop(clone)
		end)


		it("The same animation table is loaded and preprocessed once", function()
			local first = utils.create_scene(project)
			local second = utils.create_scene(project)
			assert(first.animation_path == second.animation_path, "the table identity resolves to one path")
		end)


		it("An animation is loaded from a json resource", function()
			local nodes = {}
			local state = panthera.create(ANIMATION_PATH, test_engine.create_adapter(), node_source(nodes))

			assert(panthera.get_duration(state, "from_file") == 1, "the duration is read from the file")
			panthera.set_time(state, "from_file", 0.5)
			assert(utils.near(nodes.box.position_x, 150), "the keys are sampled, got " .. tostring(nodes.box.position_x))
		end)


		it("A json file that is not an animation is rejected", function()
			local data, path, reason = panthera_internal.load(NOT_ANIMATION_PATH, false)
			assert(data == nil, "no data is returned")
			assert(path == nil, "no path is returned")
			assert(reason == "The JSON file is not an animation editor file", "the reason explains it, got " .. tostring(reason))
		end)


		it("A missing resource is reported instead of loading", function()
			local data, _, reason = panthera_internal.load("/test/no_such_file.json", false)
			assert(data == nil, "no data is returned")
			assert(reason ~= nil, "a reason is returned")
		end)


		it("reload_animation refreshes a file animation and leaves inline ones alone", function()
			local nodes = {}
			panthera.create(ANIMATION_PATH, test_engine.create_adapter(), node_source(nodes))
			local inline_state = utils.create_scene(project)
			local inline_path = inline_state.animation_path

			panthera.reload_animation(ANIMATION_PATH)
			assert(panthera_internal.LOADED_ANIMATIONS[ANIMATION_PATH] ~= nil, "the file animation is loaded again")

			panthera.reload_animation()
			assert(panthera_internal.LOADED_ANIMATIONS[inline_path] ~= nil, "the inline animation survives a full reload")
		end)


		it("A node that cannot be resolved is reported once and skipped", function()
			local warnings = 0
			panthera.set_logger({
				trace = function() end, debug = function() end, info = function() end,
				warn = function() warnings = warnings + 1 end,
				error = function() end,
			})

			local state = panthera.create(project, test_engine.create_adapter(), function() return nil end)
			panthera.set_time(state, "move", 0.5)
			assert(warnings > 0, "the missing node is reported")

			panthera.set_logger(nil)
		end)


		it("A get_node that throws does not break the sample", function()
			local state = panthera.create(project, test_engine.create_adapter(), function()
				error("no node here")
			end)

			assert(panthera.set_time(state, "move", 0.5) == true, "the sample still succeeds")
		end)


		it("A node that becomes invalid is dropped from the animation", function()
			local box = { id = "box" }
			local is_valid = true
			local adapter = test_engine.create_adapter()
			adapter.is_node_valid = function() return is_valid end

			local state = panthera.create(project, adapter, function() return box end)
			panthera.set_time(state, "move", 0.5)
			assert(utils.near(box.position_x, 50), "the node is animated while valid")

			is_valid = false
			panthera.set_time(state, "move", 1)
			assert(utils.near(box.position_x, 50), "the invalid node is left alone, got " .. tostring(box.position_x))

			is_valid = true
			panthera.set_time(state, "move", 1)
			assert(utils.near(box.position_x, 50), "the node stays dropped once marked invalid")
		end)


		it("set_time accepts times outside of the animation range", function()
			local state, nodes = utils.create_scene(project)

			panthera.set_time(state, "move", -1)
			assert(utils.near(nodes.box.position_x, 0), "before the start it holds the start value, got " .. tostring(nodes.box.position_x))
			panthera.set_time(state, "move", 100)
			assert(utils.near(nodes.box.position_x, 100), "past the end it holds the end value, got " .. tostring(nodes.box.position_x))
		end)


		it("set_time stops a running animation", function()
			local state = utils.create_scene(project)
			panthera.play(state, "move")
			assert(panthera.is_playing(state) == true, "playing")

			panthera.set_time(state, "move", 0.5)
			assert(panthera.is_playing(state) == false, "set_time takes over the state")
			assert(utils.near(panthera.get_time(state), 0.5), "the time is the one that was set")
		end)


		it("An event callback may sample another animation from inside the sample", function()
			local other, other_nodes = utils.create_scene(project)
			local with_event = utils.project({ utils.animation("run", 1, {
				utils.tween("box", "position_x", { duration = 1, start_value = 0, end_value = 10 }),
				utils.event("nested", { start_time = 0.5 }),
			}) })

			local state, nodes = utils.create_scene(with_event)
			local is_nested_done = false
			panthera.set_time(state, "run", 0.6, function()
				panthera.set_time(other, "move", 1)
				is_nested_done = true
			end)

			assert(is_nested_done, "the callback ran")
			assert(utils.near(other_nodes.box.position_x, 100), "the nested sample applied, got " .. tostring(other_nodes.box.position_x))
			assert(utils.near(nodes.box.position_x, 6), "the outer sample is not disturbed, got " .. tostring(nodes.box.position_x))
		end)


		it("A template state is reused across samples and rewinds its events", function()
			local template = utils.project({ utils.animation("inner", 1, {
				utils.tween("box", "position_x", { duration = 1, start_value = 0, end_value = 80 }),
				utils.event("inner_tick", { start_time = 0.5 }),
			}) })
			local outer = utils.project({
				utils.animation("root", 1, { utils.clip("inner", { node_id = "holder", duration = 1 }) }),
			}, { holder = template })

			local state, nodes = utils.create_scene(outer)
			local ticks = 0
			local on_event = function() ticks = ticks + 1 end

			panthera.set_time(state, "root", 0.6, on_event)
			local template_state = state.template_states and state.template_states.holder
			assert(template_state ~= nil, "the template state is cached")
			assert(ticks == 1, "the template event fired, got " .. ticks)

			panthera.set_time(state, "root", 0.7, on_event)
			assert(state.template_states.holder == template_state, "the cached template state is reused")
			assert(ticks == 1, "the event does not fire twice going forward, got " .. ticks)

			panthera.set_time(state, "root", 0.1, on_event)
			panthera.set_time(state, "root", 0.6, on_event)
			assert(ticks == 2, "the template events rewound with the time, got " .. ticks)
			assert(utils.near(nodes["holder/box"].position_x, 48), "the template is still sampled")
		end)


		it("Creating a state from a missing path throws", function()
			local is_ok = pcall(panthera.create, "/test/nope.json", test_engine.create_adapter(), node_source({}))
			assert(is_ok == false, "the create call fails loudly")
		end)


		it("Playing without a state is reported", function()
			local errors = 0
			panthera.set_logger({
				trace = function() end, debug = function() end, info = function() end,
				warn = function() end, error = function() errors = errors + 1 end,
			})

			panthera.play_tweener(nil, "move")
			assert(errors == 1, "play_tweener reports the missing state, got " .. errors)
			panthera.set_logger(nil)
		end)


		it("Restarting a tweener playback cancels the previous one", function()
			local state, nodes = utils.create_scene(project)
			panthera.play_tweener(state, "move", {})
			utils.play_frames(20)

			panthera.play_tweener(state, "move", {})
			assert(test_engine.timer_count() == 1, "only one tweener timer is left, got " .. test_engine.timer_count())
			utils.play_frames(70)
			assert(utils.near(nodes.box.position_x, 100, 1), "the restarted playback finishes")
		end)


		it("An adapter error during a sample is raised, not swallowed", function()
			local adapter = test_engine.create_adapter()
			adapter.set_node_property = function() error("adapter is broken") end

			local state = panthera.create(project, adapter, node_source({}))
			local is_ok = pcall(panthera.set_time, state, "move", 0.5)
			assert(is_ok == false, "the error reaches the caller")
		end)


		it("The predefined option tables are usable as they are", function()
			local state = utils.create_scene(project)
			panthera.play(state, "blink", panthera.OPTIONS_LOOP)
			utils.play_frames(60)
			assert(panthera.is_playing(state) == true, "the loop option keeps it running")
			panthera.stop(state)
		end)
	end)
end
