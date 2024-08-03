local component = require("druid.component")
local panthera = require("panthera.panthera")
local druid_component_animation = require("example.example_druid_component.druid_component_animation")

---@class druid_component: druid.base_component
---@field root node
---@field text druid.text
---@field druid druid_instance
local M = component.create("druid_component")

local SCHEME = {
	ROOT = "root",
	PANTHERA = "panthera",
	TEXT = "text"
}


---@param template string
---@param nodes table<hash, node>
function M:init(template, nodes)
	self:set_template(template)
	self:set_nodes(nodes)
	self.druid = self:get_druid()

	self.root = self:get_node(SCHEME.ROOT)
	self.text = self.druid:new_text(SCHEME.TEXT)

	self.animation_state = panthera.create_gui(druid_component_animation, self:get_template(), nodes)
end


function M:run_animation()
	panthera.play(self.animation_state, "default", {
		is_loop = true
	})
end


return M
