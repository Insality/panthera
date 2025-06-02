---Download Defold annotations from here: https://github.com/astrochili/defold-annotations/releases/

---@class panthera.animation.data.node

---@class panthera.animation.data.metadata
---@field gui_path string
---@field fps number
---@field settings table
---@field gizmo_steps table
---@field template_animation_paths table<string, string> template_animation_paths[node_id]: path. Value filled at loading animation data

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
---@field group_animation_keys table<string, table<string, table<string, panthera.animation.data.animation_key[]>>> group_animation_keys[animation_id][node_id][property_id]: keys[]. Value filled at loading animation data
---@field animations_dict table<string, panthera.animation.data.animation> animations_dict[animation_id]: animation. Value filled at loading animation data

---@class panthera.animation.project_file
---@field data panthera.animation.data Animation data
---@field format string Animation format
---@field version string Animation version
---@field type string Animation type. Example: "animation_editor", "atlas"

---@class panthera.animation.data.animation_key
---@field key_type number
---@field node_id string
---@field property_id string
---@field start_time number
---@field duration number
---@field start_value number
---@field end_value number
---@field easing string
---@field easing_custom number[]|nil
---@field start_data string
---@field data string
---@field event_id string
---@field is_editor_only boolean

---@class panthera.options_tweener
---@field speed number|nil Animation speed multiplier, default is 1
---@field is_loop boolean|nil If true, the animation will loop with trigger callback each loop
---@field easing string|constant|nil Easing function for play animation with. Works currently only on play_tweener
---@field callback (fun(animation_id: string):nil)|nil Callback when animation is finished
---@field callback_event (fun(event_id: string, node: node|nil, string_value: string, number_value: number): nil)|nil Callback when animation trigger event
---@field is_reverse boolean|nil If true, the animation will play in reverse
---@field from number|nil Start value for tween animation
---@field to number|nil End value for tween animation
