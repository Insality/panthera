return function()
	describe("Panthera GO Adapter", function()
		---@type panthera
		local panthera
		local adapter_go
		local utils
		local url

		before(function()
			panthera = require("panthera.panthera")
			adapter_go = require("panthera.adapters.adapter_go")
			utils = require("test.test_utils")
			panthera.set_logger(nil)
			url = msg.url(nil, go.get_id("test"), nil)
		end)

		after(function()
			adapter_go.set_node_property(url, "position_x", 0)
			adapter_go.set_node_property(url, "position_y", 0)
			adapter_go.set_node_property(url, "scale_x", 1)
			adapter_go.set_node_property(url, "scale_y", 1)
		end)


		it("get_easing maps the panthera names onto the engine easings", function()
			assert(adapter_go.get_easing("linear") == go.EASING_LINEAR, "linear")
			assert(adapter_go.get_easing("inoutsine") == go.EASING_INOUTSINE, "inoutsine")
			assert(adapter_go.get_easing("outback") == go.EASING_OUTBACK, "outback")
		end)


		it("The adapter writes the transform properties of a game object", function()
			assert(adapter_go.is_node_valid(url) == true, "the test game object exists")

			local checks = {
				{ "position_x", 25, "position.x" },
				{ "position_y", -8, "position.y" },
				{ "scale_x", 2, "scale.x" },
				{ "scale_y", 3, "scale.y" },
				{ "rotation_z", 30, "euler.z" },
			}
			for _, check in ipairs(checks) do
				local property_id, value, defold_property = check[1], check[2], check[3]
				assert(adapter_go.set_node_property(url, property_id, value), property_id .. " is a known property")
				-- The euler round trip goes through a quaternion, so it is not exact
				assert(utils.near(go.get(url, defold_property), value, 0.01),
					property_id .. " is " .. value .. ", got " .. tostring(go.get(url, defold_property)))
			end

			adapter_go.set_node_property(url, "rotation_z", 0)
		end)


		it("The adapter tweens and cancels through the engine", function()
			adapter_go.tween_animation_key(url, "position_x", adapter_go.get_easing("linear"), 10, 500)
			adapter_go.stop_tween(url, "position_x")
			adapter_go.set_node_property(url, "position_x", 7)
			assert(utils.near(go.get(url, "position.x"), 7), "the cancelled tween leaves the set value")
		end)


		it("get_node resolves an object id and a component fragment", function()
			local get_node = adapter_go.create_get_node_function(nil, nil)
			assert(get_node("test") == go.get_id("test"), "a bare id resolves to the object")

			local component_url = get_node("test#test")
			assert(component_url.fragment == hash("test"), "the fragment is the component id")
		end)


		it("get_node prefixes the object ids with the collection name", function()
			local get_node = adapter_go.create_get_node_function(nil, { [hash("/holder/test")] = go.get_id("test") })
			assert(get_node("holder/test") == go.get_id("test"), "the object is looked up in the passed table")
		end)


		it("create_go animates the game object it resolves by id", function()
			local project = utils.project({ utils.animation("run", 1, {
				utils.tween("test", "position_x", { duration = 1, start_value = 0, end_value = 40 }) }) })

			local state = panthera.create_go(project)
			panthera.set_time(state, "run", 0.5)
			assert(utils.near(go.get(url, "position.x"), 20), "sampled halfway, got " .. tostring(go.get(url, "position.x")))
		end)
	end)
end
