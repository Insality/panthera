---The list of examples displayed in the left panel. Each example is a GUI template placed
---inside the `examples` node of `/example2/example2.gui` and a Panthera animation over it.
---@class example2.example
---@field name string Displayed in the examples list
---@field template string The GUI template node id in the example2.gui scene
---@field animation table The Panthera animation project file
---@field gui_path string The path to the animated GUI scene, displayed in the scene header

---@type example2.example[]
return {
	{
		name = "Basic Properties",
		template = "example_basic",
		animation = require("example2.examples.basic.basic_panthera"),
		gui_path = "/example2/examples/basic/basic.gui",
	},
	{
		name = "Easings",
		template = "example_easings",
		animation = require("example2.examples.easings.easings_panthera"),
		gui_path = "/example2/examples/easings/easings.gui",
	},
	{
		name = "Dots",
		template = "example_dots",
		animation = require("example2.examples.dots.dots_panthera"),
		gui_path = "/example2/examples/dots/dots.gui",
	},
	{
		name = "Nested Templates",
		template = "example_nested",
		animation = require("example2.examples.nested.nested_panthera"),
		gui_path = "/example2/examples/nested/nested.gui",
	},
	{
		name = "Triggers and Events",
		template = "example_events",
		animation = require("example2.examples.events.events_panthera"),
		gui_path = "/example2/examples/events/events.gui",
	},
}
