---Download Defold annotations from here: https://github.com/astrochili/defold-annotations/releases/

---@class panthera.animation.data.node

---@class panthera.animation.data.metadata

---@class panthera.animation.data.animation
---@field duration number
---@field animation_id string
---@field initial_state string
---@field animation_keys panthera.animation.data.animation_key[]

---@class panthera.animation.data
---@field name string
---@field nodes panthera.animation.data.node[]
---@field animations panthera.animation.data.animation[]
---@field metadata panthera.animation.data.metadata
---@field group_animation_keys table<string, table<string, table<string, panthera.animation.data.animation_key[]>>> @group_animation_keys[animation_id][node_id][property_id]: keys[]. Value filled at loading animation data
---@field animations_dict table<string, panthera.animation.data.animation> @animations_dict[animation_id]: animation. Value filled at loading animation data

---@class panthera.animation.data.animation_key
---@field key_type string
---@field node_id string
---@field property_id string
---@field start_time number
---@field duration number
---@field start_value number
---@field end_value number
---@field easing string
---@field start_data string
---@field data string
---@field event_id string

---@class panthera.animation.state
---@field adapter panthera.adapter @Adapter to use for animation
---@field speed number @All animation speed multiplier
---@field current_time number @Current animation time
---@field nodes table @Animation nodes used in animation
---@field childs panthera.animation.state[]|nil @List of active child animations
---@field get_node fun(node_id: string): node @Function to get node by node_id. Default is defined in adapter
---@field animation_id string|nil @Current animation id
---@field previous_animation_id string|nil @Previous runned animation id
---@field animation_path string @Animation path to JSON file
---@field animation_keys_index number @Animation keys index
---@field timer_id hash|nil @Timer id for animation

---@class panthera.options
---@field is_loop boolean|nil @If true, the animation will loop with trigger callback each loop
---@field is_skip_init boolean|nil @If true, the animation will skip the init state and starts from current state
---@field is_relative boolean|nil @If true, all animation tween values will be relative to current state
---@field speed number|nil @Animation speed multiplier, default is 1
---@field callback (fun(animation_id: string):nil)|nil @Callback when animation is finished
---@field callback_event (fun(event_id: string, node: node|nil, string_value: string, number_value: number): nil)|nil @Callback when animation trigger event

---@class panthera.adapter
---@field get_node fun(node_id: string): node @Function to get node by node_id.
---@field get_easing fun(easing_id: string): hash @Function to get defold easing by easing_id. Default is gui.EASING
---@field tween_animation_key fun(node: node, property_id: string, easing: hash, duration: number, end_value: number): nil @Function to tween animation key.
---@field trigger_animation_key fun(node: node, property_id: string, value: any): nil @Function to trigger animation key.
---@field event_animation_key fun(node: node, key: panthera.animation.data.animation_key): nil @Function to trigger event in animation.
---@field set_node_property fun(node: node, property_id: string, value: number|string): boolean @Function to set node property. Return true if success
---@field get_node_property fun(node: node, property_id: string): number|string|boolean|nil @Function to get node property
---@field stop_tween fun(node: node, property_id: string): nil @Function to stop tween animation key

---@class panthera.logger
---@field trace fun(logger: panthera.logger, message: string, data: any|nil)
---@field debug fun(logger: panthera.logger, message: string, data: any|nil)
---@field info fun(logger: panthera.logger, message: string, data: any|nil)
---@field warn fun(logger: panthera.logger, message: string, data: any|nil)
---@field error fun(logger: panthera.logger, message: string, data: any|nil)
