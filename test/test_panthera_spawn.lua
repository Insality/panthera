return function()
	describe("Panthera Spawned Objects", function()
		---@type panthera
		local panthera
		local adapter_go
		local mock
		local utils
		local spawned

		before(function()
			panthera = require("panthera.panthera")
			adapter_go = require("panthera.adapters.adapter_go")
			mock = require("deftest.mock.mock")
			utils = require("test.test_utils")
			panthera.set_logger(nil)
			spawned = {}
		end)

		after(function()
			for _, id in ipairs(spawned) do
				go.delete(id, true)
			end
		end)

		---@param id hash
		local function track(id)
			spawned[#spawned + 1] = id
			return id
		end

		---One animation moving `node_id.property_id` to `end_value` over a second
		local function move(node_id, property_id, end_value)
			return utils.project({ utils.animation("run", 1, {
				utils.tween(node_id, property_id, { duration = 1, start_value = 0, end_value = end_value }) }) })
		end


		it("A game object spawned by a factory is animated through the objects map", function()
			local id = track(factory.create("#object_factory"))
			local objects = { [hash("/spawned")] = id }

			local state = panthera.create_go(move("spawned", "position_x", 120), nil, objects)
			panthera.set_time(state, "run", 0.5)

			local url = msg.url(nil, id, nil)
			assert(utils.near(go.get(url, "position.x"), 60), "the spawned object moved, got " .. tostring(go.get(url, "position.x")))
		end)


		it("A collection spawned by a collection factory is animated by its object ids", function()
			local objects = collectionfactory.create("#nested_factory")
			track(objects[hash("/parent")])

			local project = utils.project({ utils.animation("run", 1, {
				utils.tween("parent", "position_x", { duration = 1, start_value = 0, end_value = 100 }),
				utils.tween("child", "position_y", { duration = 1, start_value = 0, end_value = 50 }),
			}) })

			local state = panthera.create_go(project, nil, objects)
			panthera.set_time(state, "run", 1)

			assert(utils.near(go.get(msg.url(nil, objects[hash("/parent")], nil), "position.x"), 100), "the parent moved")
			assert(utils.near(go.get(msg.url(nil, objects[hash("/child")], nil), "position.y"), 50), "the nested child moved")
		end)


		it("A child of a spawned collection is addressed on its own", function()
			local objects = collectionfactory.create("#nested_factory")
			track(objects[hash("/parent")])

			local state = panthera.create_go(move("child", "position_x", 100), nil, objects)
			panthera.set_time(state, "run", 1)

			local child_url = msg.url(nil, objects[hash("/child")], nil)
			local parent_url = msg.url(nil, objects[hash("/parent")], nil)
			assert(utils.near(go.get(child_url, "position.x"), 100), "the child moved, got " .. tostring(go.get(child_url, "position.x")))
			assert(utils.near(go.get(parent_url, "position.x"), 0), "the parent is untouched, got " .. tostring(go.get(parent_url, "position.x")))
		end)


		it("The collection name prefixes the object ids of the map", function()
			local id = track(factory.create("#object_factory"))
			local objects = { [hash("/level/hero")] = id }

			local state = panthera.create_go(move("hero", "position_y", 80), "level", objects)
			panthera.set_time(state, "run", 1)

			assert(utils.near(go.get(msg.url(nil, id, nil), "position.y"), 80), "the prefixed id resolved")
		end)


		it("A sprite component is reached through the node id fragment", function()
			local id = track(factory.create("#object_factory"))
			local objects = { [hash("/hero")] = id }

			local project = utils.project({ utils.animation("run", 1, {
				utils.tween("hero#sprite", "size_x", { duration = 1, start_value = 32, end_value = 64 }),
				utils.tween("hero#sprite", "scale_y", { duration = 1, start_value = 1, end_value = 2 }),
			}) })

			local state = panthera.create_go(project, nil, objects)
			panthera.set_time(state, "run", 1)

			local sprite_url = msg.url(nil, id, "sprite")
			assert(utils.near(go.get(sprite_url, "size.x"), 64), "the sprite size is animated, got " .. tostring(go.get(sprite_url, "size.x")))
			assert(utils.near(go.get(sprite_url, "scale.y"), 2), "the sprite scale is animated, got " .. tostring(go.get(sprite_url, "scale.y")))
		end)


		it("A label component is reached and coloured through the node id fragment", function()
			local id = go.get_id("test")
			local objects = { [hash("/hero")] = id }

			local project = utils.project({ utils.animation("run", 1, {
				utils.tween("hero#label", "color_a", { duration = 1, start_value = 1, end_value = 0 }),
				utils.tween("hero#label", "outline_a", { duration = 1, start_value = 1, end_value = 0 }),
				utils.tween("hero#label", "shadow_r", { duration = 1, start_value = 0, end_value = 1 }),
				utils.trigger("hero#label", "text", { start_time = 0.5, data = "done", start_data = "start" }),
			}) })

			local state = panthera.create_go(project, nil, objects)
			local label_url = msg.url(nil, id, "label")

			-- A label commits its text on the next frame, so the call itself is what is checked
			local written = {}
			mock.mock(label)
			label.set_text.replace(function(url, text) written[#written + 1] = { url = url, text = text } end)

			panthera.set_time(state, "run", 0)
			panthera.set_time(state, "run", 1)
			mock.unmock(label)

			assert(utils.near(go.get(label_url, "color.w"), 0), "the label faded out, got " .. tostring(go.get(label_url, "color.w")))
			assert(utils.near(go.get(label_url, "outline.w"), 0), "the outline faded out")
			assert(utils.near(go.get(label_url, "shadow.x"), 1), "the shadow colour is animated")

			assert(#written == 2, "the text was written on both samples, got " .. #written)
			assert(written[1].text == "start", "the start data first, got " .. tostring(written[1].text))
			assert(written[2].text == "done", "the key data after the trigger, got " .. tostring(written[2].text))
			assert(written[2].url.fragment == hash("label"), "the write goes to the label component")
		end)


		it("A texture trigger plays the flipbook of a sprite", function()
			local id = go.get_id("test")
			local objects = { [hash("/hero")] = id }

			local project = utils.project({ utils.animation("run", 1, {
				utils.trigger("hero#sprite", "texture", { start_time = 0.5, data = "/example/icon_check", start_data = "/example/pixel" }) }) })

			local state = panthera.create_go(project, nil, objects)

			-- A sprite swaps its flipbook on the next frame, so the call itself is what is checked
			local played = {}
			mock.mock(sprite)
			sprite.play_flipbook.replace(function(url, animation) played[#played + 1] = { url = url, animation = animation } end)

			panthera.set_time(state, "run", 0)
			panthera.set_time(state, "run", 1)
			mock.unmock(sprite)

			assert(#played == 2, "the flipbook was played on both samples, got " .. #played)
			-- The adapter takes the last segment of the panthera texture path
			assert(played[1].animation == "pixel", "the start flipbook, got " .. tostring(played[1].animation))
			assert(played[2].animation == "icon_check", "the key flipbook, got " .. tostring(played[2].animation))
			assert(played[2].url.fragment == hash("sprite"), "the call goes to the sprite component")
		end)


		it("The reachable properties of an object, a sprite and a label are the documented ones", function()
			local id = track(factory.create("#object_factory"))
			local object_url = msg.url(nil, id, nil)
			local sprite_url = msg.url(nil, id, "sprite")
			local label_url = msg.url(nil, id, "label")

			local function reaches(url, property_id)
				return pcall(adapter_go.set_node_property, url, property_id, 1)
			end

			for _, property_id in ipairs({ "position_x", "position_y", "position_z", "rotation_z", "scale_x", "scale_y" }) do
				assert(reaches(object_url, property_id), "a game object reaches " .. property_id)
			end
			for _, property_id in ipairs({ "size_x", "size_y", "scale_x", "slice9_left",
				"color_r", "color_g", "color_b", "color_a" }) do
				assert(reaches(sprite_url, property_id), "a sprite reaches " .. property_id)
			end
			for _, property_id in ipairs({ "size_x", "scale_x", "color_r", "color_a", "outline_a", "shadow_a" }) do
				assert(reaches(label_url, property_id), "a label reaches " .. property_id)
			end
		end)


		it("An enabled trigger posts the enable and disable messages", function()
			local id = go.get_id("test")
			local objects = { [hash("/hero")] = id }

			local project = utils.project({ utils.animation("run", 1, {
				utils.trigger("hero#sprite", "enabled", { start_time = 0.5, data = "false", start_data = "true" }) }) })

			local state = panthera.create_go(project, nil, objects)
			local posted = {}
			mock.mock(msg)
			msg.post.replace(function(url, message_id) posted[#posted + 1] = message_id end)

			panthera.set_time(state, "run", 0)
			panthera.set_time(state, "run", 1)
			mock.unmock(msg)

			assert(#posted == 2, "both samples posted, got " .. #posted)
			assert(posted[1] == hash("enable"), "the start data enables")
			assert(posted[2] == hash("disable"), "the key data disables")
		end)


		it("A sprite is faded through color_a", function()
			local id = go.get_id("test")
			local objects = { [hash("/hero")] = id }

			local project = utils.project({ utils.animation("run", 1, {
				utils.tween("hero#sprite", "color_a", { duration = 1, start_value = 1, end_value = 0 }) }) })

			local state = panthera.create_go(project, nil, objects)
			panthera.set_time(state, "run", 1)

			local sprite_url = msg.url(nil, id, "sprite")
			assert(utils.near(go.get(sprite_url, "color.w"), 0), "the sprite faded out, got " .. tostring(go.get(sprite_url, "color.w")))

			panthera.set_time(state, "run", 0)
		end)
	end)
end
