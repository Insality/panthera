return function()
	describe("Panthera Runtime", function()
		---@type panthera
		local panthera
		local panthera_internal
		local test_engine
		local transitions
		local slot_machine

		local FRAME = 1 / 60

		local STRIPES = {}
		for index = 0, 12 do
			STRIPES[#STRIPES + 1] = "stripe_" .. index .. "/shape"
		end

		before(function()
			panthera = require("panthera.panthera")
			panthera_internal = require("panthera.panthera_internal")
			test_engine = require("test.test_engine")
			transitions = require("example.examples.transitions.transitions_panthera")
			slot_machine = require("example.examples.slot_machine.slot_machine_panthera")

			panthera.set_logger(nil)
			test_engine.mock()
		end)

		after(function()
			test_engine.unmock()
		end)

		---@return panthera.animation, table<string, table>
		local function create_scene(animation_or_path)
			local nodes = {}
			local get_node = function(node_id)
				nodes[node_id] = nodes[node_id] or { id = node_id, position_x = 0, scale_y = 1 }
				return nodes[node_id]
			end
			return panthera.create(animation_or_path, test_engine.create_adapter(), get_node), nodes
		end

		local function play_frames(count)
			for _ = 1, count do
				test_engine.step(FRAME)
			end
		end

		local function near(a, b, epsilon)
			return math.abs(a - b) <= (epsilon or 0.001)
		end

		---Stripe values as a comparable string
		local function stripe_pose(nodes, property_id)
			local pose = {}
			for _, node_id in ipairs(STRIPES) do
				pose[#pose + 1] = string.format("%.4f", nodes[node_id][property_id])
			end
			return table.concat(pose, " ")
		end

		---Two clips driving box.position_x from the same start time
		local function tie_animation(first_id, second_id)
			local function clip(id, value)
				return { animation_id = id, duration = 1, animation_keys = {
					{ key_type = "tween", node_id = "box", property_id = "position_x", easing = "linear",
					  start_time = 0, duration = 1, start_value = value, end_value = value } } }
			end
			return { type = "animation_editor", format = "json", version = 1, data = {
				nodes = {},
				metadata = { fps = 60, template_animation_paths = {}, gui_path = "tie", settings = {}, gizmo_steps = {} },
				animations = { clip(first_id, 100), clip(second_id, 200), {
					animation_id = "root", duration = 1, animation_keys = {
						{ key_type = "animation", property_id = first_id, start_time = 0, duration = 1, easing = "linear" },
						{ key_type = "animation", property_id = second_id, start_time = 0, duration = 1, easing = "linear" },
					} } },
			} }
		end


		it("A clip key hands over at the boundary, a value key owns its start", function()
			local clip = { key_type = panthera_internal.KEY_TYPE.ANIMATION, start_time = 0.9, duration = 0.9 }
			assert(panthera_internal.is_key_started(clip, 0.89) == false, "a clip is not started before its start time")
			assert(panthera_internal.is_key_started(clip, 0.9) == false, "the previous clip owns the boundary instant")
			assert(panthera_internal.is_key_started(clip, 0.901) == true, "a clip is started right after the boundary")

			local first_clip = { key_type = panthera_internal.KEY_TYPE.ANIMATION, start_time = 0, duration = 0.9 }
			assert(panthera_internal.is_key_started(first_clip, 0) == true, "the clip at zero owns its start instant")

			local tween = { key_type = panthera_internal.KEY_TYPE.TWEEN, start_time = 0.9, duration = 0.9 }
			assert(panthera_internal.is_key_started(tween, 0.89) == false, "a value key is not started before its start")
			assert(panthera_internal.is_key_started(tween, 0.9) == true, "a value key owns its start instant")
		end)


		it("The next clip keeps the nodes the finished one released", function()
			-- appear1 over [0, 0.9), disappear1 over [0.9, 1.8), stripe_6 starts at the boundary itself
			local state, nodes = create_scene(transitions)
			panthera.play(state, "together1")

			play_frames(56) -- 0.9333, just past the boundary
			local at_boundary = stripe_pose(nodes, "position_x")

			play_frames(22) -- 1.3, disappear1 is 0.4 in, so every stripe key has started
			assert(stripe_pose(nodes, "position_x") ~= at_boundary, "the stripes move on past the boundary")
			for _, node_id in ipairs(STRIPES) do
				assert(not near(nodes[node_id].position_x, 0),
					node_id .. " is pinned at the appear1 end pose, got " .. nodes[node_id].position_x)
			end

			play_frames(44) -- 2.0, the whole animation is over
			for _, node_id in ipairs(STRIPES) do
				assert(near(math.abs(nodes[node_id].position_x), 1900, 1),
					node_id .. " ends at +/-1900, got " .. nodes[node_id].position_x)
			end
			assert(panthera.is_playing(state) == false, "the animation is over")
			assert(test_engine.tween_count() == 0, "no tween is left running")
		end)


		it("The result does not depend on the order of the timers of a frame", function()
			local function pose_after(animation_id, property_id, is_reverse)
				test_engine.reset()
				test_engine.is_reverse_timers = is_reverse
				local state, nodes = create_scene(transitions)
				panthera.play(state, animation_id)
				play_frames(78) -- 1.3
				return stripe_pose(nodes, property_id)
			end

			assert(pose_after("together1", "position_x", false) == pose_after("together1", "position_x", true),
				"together1 is the same in both timer orders")
			assert(pose_after("together2", "scale_y", false) == pose_after("together2", "scale_y", true),
				"together2 is the same in both timer orders")
		end)


		it("The scale_y clips of together2 hand over without a reset", function()
			local state, nodes = create_scene(transitions)
			panthera.play(state, "together2")
			for _, node_id in ipairs(STRIPES) do
				assert(near(nodes[node_id].scale_y, 0), node_id .. " starts squashed, got " .. nodes[node_id].scale_y)
			end

			play_frames(56)
			for _, node_id in ipairs(STRIPES) do
				-- `inback` overshoots above 1 right after the boundary
				assert(nodes[node_id].scale_y > 0.99, node_id .. " is grown at the boundary, got " .. nodes[node_id].scale_y)
			end

			play_frames(120)
			for _, node_id in ipairs(STRIPES) do
				assert(near(nodes[node_id].scale_y, 0), node_id .. " ends squashed, got " .. nodes[node_id].scale_y)
			end
		end)


		it("Playback and sampling agree on a property the running clip does not own", function()
			-- At 3.333 the win clip just started and holds no reel_l key, the spin pose has to survive
			local played, played_nodes = create_scene(slot_machine)
			panthera.play(played, "review")
			play_frames(200)

			local sampled, sampled_nodes = create_scene(slot_machine)
			panthera.set_time(sampled, "review", 200 * FRAME)

			assert(near(played_nodes.reel_l.scale_x, sampled_nodes.reel_l.scale_x, 0.02),
				string.format("reel_l.scale_x: played %.3f, sampled %.3f", played_nodes.reel_l.scale_x, sampled_nodes.reel_l.scale_x))
			assert(played_nodes.reel_l.scale_x > 1.01, "the spin pose survives into the win clip")
		end)


		it("set_time gives the boundary instant to the ending clip", function()
			local state, nodes = create_scene(transitions)

			panthera.set_time(state, "together1", 0.9)
			for _, node_id in ipairs(STRIPES) do
				assert(near(nodes[node_id].position_x, 0),
					node_id .. " is at the appear1 end at 0.9, got " .. nodes[node_id].position_x)
			end

			panthera.set_time(state, "together1", 1.8)
			for _, node_id in ipairs(STRIPES) do
				assert(near(math.abs(nodes[node_id].position_x), 1900),
					node_id .. " is at the disappear1 end at 1.8, got " .. nodes[node_id].position_x)
			end
		end)


		it("One timer drives the whole tree", function()
			local state = create_scene(transitions)
			panthera.play(state, "together1")
			assert(test_engine.timer_count() == 1, "a single timer while a clip runs, got " .. test_engine.timer_count())

			play_frames(56)
			assert(test_engine.timer_count() == 1, "still a single timer across the boundary, got " .. test_engine.timer_count())

			panthera.stop(state)
			assert(test_engine.timer_count() == 0, "stop cancels the timer, got " .. test_engine.timer_count())
		end)


		it("A loop restarts the clips instead of piling them up", function()
			local state, nodes = create_scene(transitions)
			panthera.play(state, "together1", { is_loop = true })

			play_frames(56)
			assert(#state.clips == 1, "one clip runs after the boundary, got " .. #state.clips)

			play_frames(120) -- past the loop point, appear1 runs again
			assert(#state.clips == 1, "still one clip after the loop, got " .. #state.clips)
			assert(test_engine.timer_count() == 1, "the loop keeps a single timer, got " .. test_engine.timer_count())

			play_frames(600) -- ten more seconds of looping
			assert(#state.clips == 1, "the clip list does not grow while looping, got " .. #state.clips)
			local is_animating = false
			for _, node_id in ipairs(STRIPES) do
				is_animating = is_animating or not near(nodes[node_id].position_x, 0)
			end
			assert(is_animating, "the loop is still animating after ten seconds")

			panthera.stop(state)
			assert(test_engine.tween_count() == 0, "stop cancels the tweens of the clips")
		end)


		it("Two groups starting at the same time resolve the same way in both paths", function()
			for _, pair in ipairs({ { "a", "b" }, { "b", "a" }, { "fade_in", "fade_out" }, { "zzz", "aaa" } }) do
				local sampled, sampled_nodes = create_scene(tie_animation(pair[1], pair[2]))
				panthera.set_time(sampled, "root", 0.5)

				local played, played_nodes = create_scene(tie_animation(pair[1], pair[2]))
				panthera.play(played, "root")
				play_frames(30)

				-- The group of the alphabetically later property is collected last and wins
				local expected = pair[1] < pair[2] and 200 or 100
				assert(sampled_nodes.box.position_x == expected,
					string.format("set_time %s/%s: expected %d, got %s", pair[1], pair[2], expected, sampled_nodes.box.position_x))
				assert(played_nodes.box.position_x == expected,
					string.format("play %s/%s: expected %d, got %s", pair[1], pair[2], expected, played_nodes.box.position_x))
			end
		end)


		it("A rest pose of a deeper clip outranks an earlier running key", function()
			-- The root key at 0.3 runs, the inner clip two levels down has not started. The inner
			-- rest pose sits at the offset of its parent clip, 0.5, so it is the later one and wins
			local function tween(value, start_time, duration)
				return { key_type = "tween", node_id = "box", property_id = "position_x", easing = "linear",
					start_time = start_time, duration = duration, start_value = value, end_value = value }
			end
			local data = { type = "animation_editor", format = "json", version = 1, data = {
				nodes = {},
				metadata = { fps = 60, template_animation_paths = {}, gui_path = "rest", settings = {}, gizmo_steps = {} },
				animations = {
					{ animation_id = "inner", duration = 1, animation_keys = { tween(777, 0, 1) } },
					{ animation_id = "mid", duration = 2, animation_keys = {
						{ key_type = "animation", property_id = "inner", start_time = 1.5, duration = 1, easing = "linear" } } },
					{ animation_id = "root", duration = 3, animation_keys = { tween(111, 0.3, 1),
						{ key_type = "animation", property_id = "mid", start_time = 0.5, duration = 2, easing = "linear" } } },
				},
			} }

			local state, nodes = create_scene(data)
			panthera.set_time(state, "root", 0.6)
			assert(nodes.box.position_x == 777, "the inner rest pose wins, got " .. tostring(nodes.box.position_x))
		end)


		it("A group of only editor keys is left out of the traversal order", function()
			local data = { type = "animation_editor", format = "json", version = 1, data = {
				nodes = {},
				metadata = { fps = 60, template_animation_paths = {}, gui_path = "editor_only", settings = {}, gizmo_steps = {} },
				animations = { { animation_id = "root", duration = 1, animation_keys = {
					{ key_type = "tween", node_id = "ghost", property_id = "position_x", easing = "linear",
					  start_time = 0, duration = 1, start_value = 5, end_value = 5, is_editor_only = true },
					{ key_type = "tween", node_id = "box", property_id = "position_x", easing = "linear",
					  start_time = 0, duration = 1, start_value = 0, end_value = 50 },
				} } },
			} }

			local state, nodes = create_scene(data)
			panthera.set_time(state, "root", 0.5)
			assert(near(nodes.box.position_x, 25), "box is sampled, got " .. tostring(nodes.box.position_x))
			assert(nodes.ghost == nil, "the editor only node is never touched")

			-- Walking the order in play and stop must not trip over the emptied group
			panthera.play(state, "root")
			play_frames(40)
			panthera.stop(state)
		end)
	end)
end
