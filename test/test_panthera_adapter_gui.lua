return function()
	describe("Panthera Adapters", function()
		---@type panthera
		local panthera
		local adapter_gui
		local utils

		before(function()
			panthera = require("panthera.panthera")
			adapter_gui = require("panthera.adapters.adapter_gui")
			utils = require("test.test_utils")
			panthera.set_logger(nil)
		end)


		---A gui animation moving one property of `node_id` to `end_value`
		local function property_project(node_id, property_id, end_value, key_type)
			local key = key_type == "trigger"
				and utils.trigger(node_id, property_id, { data = end_value })
				or utils.tween(node_id, property_id, { duration = 1, start_value = 0, end_value = end_value })
			return utils.project({ utils.animation("run", 1, { key }) })
		end


		it("The gui adapter writes every numeric property of a box node", function()
			utils.in_gui(function()
				local node = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(10, 10, 0))
				local checks = {
					{ "position_x", 12, function() return gui.get_position(node).x end },
					{ "position_y", 13, function() return gui.get_position(node).y end },
					{ "position_z", 14, function() return gui.get_position(node).z end },
					{ "rotation_z", 45, function() return gui.get(node, "euler.z") end },
					{ "scale_x", 2, function() return gui.get_scale(node).x end },
					{ "scale_y", 3, function() return gui.get_scale(node).y end },
					{ "size_x", 20, function() return gui.get_size(node).x end },
					{ "size_y", 30, function() return gui.get_size(node).y end },
					{ "color_r", 0.5, function() return gui.get_color(node).x end },
					{ "color_a", 0.25, function() return gui.get_color(node).w end },
					{ "slice9_left", 4, function() return gui.get_slice9(node).x end },
				}

				for _, check in ipairs(checks) do
					local property_id, value, getter = check[1], check[2], check[3]
					local is_ok = adapter_gui.set_node_property(node, property_id, value)
					assert(is_ok, property_id .. " is a known property")
					assert(utils.near(getter(), value), property_id .. " is " .. value .. ", got " .. tostring(getter()))
				end

				gui.delete_node(node)
			end)
		end)


		it("The gui adapter writes the trigger properties", function()
			utils.in_gui(function()
				local box = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(10, 10, 0))
				adapter_gui.set_node_property(box, "visible", false)
				assert(gui.get_visible(box) == false, "visible is written")

				adapter_gui.set_node_property(box, "enabled", false)
				assert(gui.is_enabled(box) == false, "enabled is written")

				local text_node = gui.new_text_node(vmath.vector3(0, 0, 0), "before")
				gui.set_font(text_node, "text_bold")
				adapter_gui.set_node_property(text_node, "text", "after")
				assert(gui.get_text(text_node) == "after", "text is written, got " .. gui.get_text(text_node))

				gui.delete_node(box)
				gui.delete_node(text_node)
			end)
		end)


		it("The gui adapter tweens and cancels through the engine", function()
			utils.in_gui(function()
				local node = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(10, 10, 0))

				adapter_gui.tween_animation_key(node, "position_x", adapter_gui.get_easing("linear"), 10, 500)
				adapter_gui.stop_tween(node, "position_x")
				adapter_gui.set_node_property(node, "position_x", 7)
				assert(utils.near(gui.get_position(node).x, 7), "the cancelled tween leaves the set value")

				gui.delete_node(node)
			end)
		end)


		it("get_easing maps the panthera names onto the gui easings", function()
			utils.in_gui(function()
				assert(adapter_gui.get_easing("linear") == gui.EASING_LINEAR, "gui linear")
				assert(adapter_gui.get_easing("outback") == gui.EASING_OUTBACK, "gui outback")
			end)
		end)


		it("create_gui animates the nodes it resolves by id", function()
			utils.in_gui(function()
				local node = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(10, 10, 0))
				local nodes = { box = node }

				local state = panthera.create_gui(property_project("box", "position_x", 100), nil, nodes)
				panthera.set_time(state, "run", 0.5)
				assert(utils.near(gui.get_position(node).x, 50), "sampled halfway, got " .. gui.get_position(node).x)

				gui.delete_node(node)
			end)
		end)


		it("create_gui prefixes the node ids with the template name", function()
			utils.in_gui(function()
				local node = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(10, 10, 0))
				local nodes = { ["card/box"] = node }

				local state = panthera.create_gui(property_project("box", "position_y", 60), "card", nodes)
				panthera.set_time(state, "run", 1)
				assert(utils.near(gui.get_position(node).y, 60), "the template node is resolved, got " .. gui.get_position(node).y)

				gui.delete_node(node)
			end)
		end)
	end)
end
