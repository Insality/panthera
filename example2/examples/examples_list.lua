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
---@field factories { factory: string, object_id: string }[]? Several objects, one factory each
---@field scene_objects string[]? The objects that are already in the bootstrap collection
---@field collection_name string? The name of the collection the animated objects live in
---@field widget table? A Druid widget module created over the template, for the examples whose
---scene needs its own logic. See `/example2/examples/character/character.lua`

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
				name = "Template Animations",
				template = "example_nested",
				animation = require("example2.examples.nested.nested_panthera"),
				source = "/example2/examples/nested/nested.gui",
			},
			{
				name = "Nested Animations",
				template = "example_nested_animations",
				animation = require("example2.examples.nested_animations.nested_animations_panthera"),
				source = "/example2/examples/nested_animations/nested_animations.gui",
			},
			{
				name = "Nested and Template",
				template = "example_combined",
				animation = require("example2.examples.combined.combined_panthera"),
				source = "/example2/examples/combined/combined.gui",
			},
			{
				name = "Deep Templates",
				template = "example_deep_templates",
				animation = require("example2.examples.deep_templates.deep_templates_panthera"),
				source = "/example2/examples/deep_templates/deep_templates.gui",
			},
			{
				name = "Triggers and Events",
				template = "example_events",
				animation = require("example2.examples.events.events_panthera"),
				source = "/example2/examples/events/events.gui",
			},
			{
				name = "Text Properties",
				template = "example_text_properties",
				animation = require("example2.examples.text_properties.text_properties_panthera"),
				source = "/example2/examples/text_properties/text_properties.gui",
			},
			{
				name = "Pie and Slice9",
				template = "example_pie_slice9",
				animation = require("example2.examples.pie_slice9.pie_slice9_panthera"),
				source = "/example2/examples/pie_slice9/pie_slice9.gui",
			},
			{
				name = "Screen Transitions",
				template = "example_transitions",
				animation = require("example2.examples.transitions.transitions_panthera"),
				source = "/example2/examples/transitions/transitions.gui",
			},
			{
				name = "Character Blend",
				template = "example_character",
				widget = require("example2.examples.character.character"),
				animation = require("example2.examples.character.character_panthera"),
				source = "/example2/examples/character/character.gui",
			},
			{
				name = "Clipping",
				template = "example_clipping",
				animation = require("example2.examples.clipping.clipping_panthera"),
				source = "/example2/examples/clipping/clipping.gui",
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
			{
				-- The objects are already in the bootstrap collection: `create_go(animation)`
				name = "Scene Objects",
				scene_objects = { "/scene_dot_1", "/scene_dot_2", "/scene_dot_3", "/scene_dot_4", "/scene_dot_5" },
				animation = require("example2.examples.scene_objects.scene_objects_panthera"),
				source = "/example2/examples/scene_objects/dot.go",
			},
			{
				-- A collection instance of the bootstrap collection: `create_go(animation, "orbit")`
				name = "Scene Collection",
				scene_objects = { "/orbit/planet", "/orbit/moon" },
				collection_name = "orbit",
				animation = require("example2.examples.orbit.orbit_panthera"),
				source = "/example2/examples/orbit/orbit.collection",
			},
			{
				-- A spawned collection that holds a nested one: `create_go(animation, "inner", objects)`
				name = "Nested Collection",
				collectionfactory = "/scene#nested_collection",
				collection_name = "inner",
				animation = require("example2.examples.nested_collection.nested_collection_panthera"),
				source = "/example2/examples/nested_collection/wrapper.collection",
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
			{
				-- One object with a sprite, a second sprite and a label, animated component by component
				name = "Components",
				factory = "/scene#go_avatar",
				object_id = "avatar",
				animation = require("example2.examples.components.components_panthera"),
				source = "/example2/examples/components/avatar.go",
			},
			{
				-- Two objects spawned by two factories into one animation
				name = "Two Objects",
				factories = {
					{ factory = "/scene#go_ball", object_id = "ball" },
					{ factory = "/scene#go_paddle", object_id = "paddle" },
				},
				animation = require("example2.examples.two_objects.two_objects_panthera"),
				source = "/example2/examples/two_objects/ball.go",
			},
		},
	},
}
