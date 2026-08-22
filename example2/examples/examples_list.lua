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
