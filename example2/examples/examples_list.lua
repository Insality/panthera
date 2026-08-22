---The list of examples displayed in the left panel, grouped into sections.
---
---A GUI example is a GUI template placed inside the `examples` node of `/example2/example2.gui`.
---A collection example is spawned with a `collectionfactory` and a game object example with a
---`factory`, both from the `/factories` game object of `/example2/example2.collection`.
---@class example2.example
---@field name string Displayed in the examples list
---@field source string The path to the animated scene, displayed above the scene
---@field animation table The Panthera animation project file
---@field template string? GUI examples: the GUI template node id in the example2.gui scene
---@field collectionfactory string? Collection examples: the url of the collectionfactory component
---@field factory string? Game object examples: the url of the factory component
---@field object_id string? Game object examples: the object id used by the animation nodes

---@class example2.examples_section
---@field name string
---@field examples example2.example[]

---@type example2.examples_section[]
return {
	{
		name = "GUI",
		examples = {
			{
				name = "Basic Properties",
				template = "example_basic",
				animation = require("example2.examples.basic.basic_panthera"),
				source = "/example2/examples/basic/basic.gui",
			},
			{
				name = "Easings",
				template = "example_easings",
				animation = require("example2.examples.easings.easings_panthera"),
				source = "/example2/examples/easings/easings.gui",
			},
			{
				name = "Dots",
				template = "example_dots",
				animation = require("example2.examples.dots.dots_panthera"),
				source = "/example2/examples/dots/dots.gui",
			},
			{
				name = "Nested Templates",
				template = "example_nested",
				animation = require("example2.examples.nested.nested_panthera"),
				source = "/example2/examples/nested/nested.gui",
			},
			{
				name = "Triggers and Events",
				template = "example_events",
				animation = require("example2.examples.events.events_panthera"),
				source = "/example2/examples/events/events.gui",
			},
		},
	},
	{
		name = "Collections",
		examples = {
			{
				name = "Shapes",
				collectionfactory = "/scene#shapes",
				animation = require("example2.examples.shapes.shapes_panthera"),
				source = "/example2/examples/shapes/shapes.collection",
			},
			{
				name = "Hierarchy",
				collectionfactory = "/scene#hierarchy",
				animation = require("example2.examples.hierarchy.hierarchy_panthera"),
				source = "/example2/examples/hierarchy/hierarchy.collection",
			},
		},
	},
	{
		name = "Game Objects",
		examples = {
			{
				name = "Sprite",
				factory = "/scene#go_sprite",
				object_id = "hero",
				animation = require("example2.examples.go_sprite.go_sprite_panthera"),
				source = "/example2/examples/go_sprite/hero.go",
			},
			{
				name = "Label",
				factory = "/scene#go_label",
				object_id = "caption",
				animation = require("example2.examples.go_label.go_label_panthera"),
				source = "/example2/examples/go_label/caption.go",
			},
		},
	},
}
