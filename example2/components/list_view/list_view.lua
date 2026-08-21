local event = require("event.event")
local list_view_item = require("example2.components.list_view.list_view_item")

local ITEM_HEIGHT = 50

---A scrollable list of selectable items. Used twice in the example: for the examples list
---on the left side and for the animations list of the selected example on the right side.
---@class example2.list_view: druid.widget
---@field root druid.container
---@field scroll druid.scroll
---@field grid druid.grid
---@field items example2.list_view.item[]
---@field on_select event fun(data: any, index: number)
local M = {}

---@class example2.list_view.item
---@field widget example2.list_view_item
---@field data any


---@param text_scale number? The scale of the item text, default is taken from the item template
function M:init(text_scale)
	self.text_scale = text_scale

	self.root = self.druid:new_container("root") --[[@as druid.container]]
	self.root:add_container("text_header")

	self.text_header = self.druid:new_text("text_header") --[[@as druid.text]]

	self.prefab = self:get_node("list_view_item/root")
	gui.set_enabled(self.prefab, false)

	self.scroll = self.druid:new_scroll("scroll_view", "scroll_content") --[[@as druid.scroll]]
	self.scroll.on_scroll:subscribe(self.on_scroll)
	self.grid = self.druid:new_grid("scroll_content", self.prefab, 1) --[[@as druid.grid]]
	self.scroll:bind_grid(self.grid)

	-- The item template has its own width, stretch the items over the whole list width instead
	self.item_width = self.root:get_size().x
	self.grid:set_item_size(self.item_width, ITEM_HEIGHT)

	self.slider = self.druid:new_slider("scroll_bar_pin", vmath.vector3(-8, 48 - 850, 0), self.on_slider_change) --[[@as druid.slider]]
	self.slider:set_input_node("scroll_bar_view")

	self.root:add_container("scroll_view", nil, function(_, size)
		self.scroll:set_view_size(size)
		self.scroll:set_size(self.grid:get_size())
		self.slider:set_end_pos(vmath.vector3(-8, 48 - size.y, 0))
	end)

	self.items = {}
	self.selected_index = nil

	self.on_select = event.create()
end


---@param header string
function M:set_header(header)
	self.text_header:set_text(header)
end


function M:clear()
	for index = 1, #self.items do
		self.druid:remove(self.items[index].widget)
	end
	self.items = {}
	self.selected_index = nil

	local nodes = self.grid.nodes
	for index = 1, #nodes do
		gui.delete_node(nodes[index])
	end
	self.grid:clear()

	self.scroll:set_size(self.grid:get_size())
	self.scroll:scroll_to_percent(vmath.vector3(0), true)
	self:_refresh_scroll_bar()
end


---@param text string The text to display in the list item
---@param data any The value passed to the `on_select` event
---@return number index The index of the added item
function M:add_item(text, data)
	local nodes = gui.clone_tree(self.prefab)
	local widget = self.druid:new_widget(list_view_item, "list_view_item", nodes) --[[@as example2.list_view_item]]
	gui.set_enabled(widget.root.node, true)
	widget:set_width(self.item_width)
	widget:set_text(text)

	if self.text_scale then
		widget.text:set_scale(vmath.vector3(self.text_scale, self.text_scale, 1))
	end

	local index = #self.items + 1
	widget.on_click:subscribe(function()
		self:select(index)
	end)

	self.grid:add(widget.root.node)
	self.items[index] = {
		widget = widget,
		data = data,
	}

	self:_refresh_scroll_bar()

	return index
end


---Select the item by index. Selecting the already selected item triggers the event again,
---so the animations can be replayed by the second click.
---@param index number
---@param is_silent boolean? If true, the `on_select` event is not triggered
function M:select(index, is_silent)
	local item = self.items[index]
	if not item then
		return
	end

	if self.selected_index and self.selected_index ~= index then
		self.items[self.selected_index].widget:set_selected(false)
	end

	self.selected_index = index
	item.widget:set_selected(true)

	-- Only scroll when the item is outside of the view, the list should stay in place otherwise
	if self.scroll.drag.can_y then
		self.scroll:scroll_to_make_node_visible(item.widget.root.node, true)
	end

	if not is_silent then
		self.on_select:trigger(item.data, index)
	end
end


---Select the next item in the list, wrapping around to the first one
---@param shift number The number of items to move, negative to move up
function M:select_shifted(shift)
	if #self.items == 0 then
		return
	end

	local index = ((self.selected_index or 1) + shift - 1) % #self.items + 1
	self:select(index)
end


---@param value number In range [0..1]
function M:on_slider_change(value)
	self.scroll:scroll_to_percent(vmath.vector3(0, 1 - value, 0), true)
end


function M:on_scroll()
	self.slider:set(1 - self.scroll:get_percent().y, true)
end


function M:_refresh_scroll_bar()
	local is_scroll_available = self.scroll.drag.can_y
	gui.set_enabled(self.slider.node, is_scroll_available)
	if is_scroll_available then
		self.slider:set(1 - self.scroll:get_percent().y, true)
	end
end


return M
