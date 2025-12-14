### Understanding Panthera Adapters

In Panthera Runtime for Defold, an adapter is a crucial component that bridges Panthera animations with Defold's game objects or GUI nodes. It translates animation data into actions that Defold understands, like moving a sprite or changing the transparency of a GUI element.

#### What Does an Adapter Do?

An adapter takes care of several key tasks:

- **Property Animation**: Applies animations to properties of nodes, such as position, rotation, or scale, using Defold's animation system.
- **Event Handling**: Triggers custom actions defined in Panthera animations, like playing a sound or changing a scene.
- **Easing Functions**: Maps Panthera easing functions to Defold's easing types for smooth transitions.

#### Example Adapter

Here’s a simple adapter example for Defold GUI:

```lua
local M = {
    get_easing = function(easing_name)
        -- Returns a Defold easing type. This example always returns LINEAR easing.
        -- You might want to map Panthera easing names to Defold's easing constants.
        return gui.EASING_LINEAR
    end,
    set_node_property = function(node, property_id, value)
        -- Sets a property of a node to a specified value.
        gui.set(node, property_id, value)
    end,
    tween_animation_key = function(node, property_id, easing, duration, end_value)
        -- Applies a tween to a node property based on Panthera animation key data.
        gui.animate(node, property_id, end_value, easing, duration)
    end,
    stop_tween = function(node, property_id)
        -- Stops any ongoing tween on a node property.
        gui.cancel_animation(node, property_id)
    end,
    trigger_animation_key = function(node, property_id, value)
        -- Intended for triggering non-tween animation keys, such as sound or event triggers.
        -- This example logs a message, but you should implement specific logic as needed.
        print("Triggering animation key for non-tween values. Node: ", node_id, " Property: ", property_id, " Value: ", value)
    end,
}
```

#### Using the Adapter

To use your custom adapter with Panthera Runtime, simply pass it when creating animations:

```lua
local my_custom_adapter = require("path.to.my_custom_adapter")
local animation = panthera.create("/path/to/animation.json", my_custom_adapter, function(node_id)
	return gui.get_node(node_id)
end)
```

This flexibility allows Panthera Runtime to work seamlessly with any part of Defold, ensuring that you can bring any animation from Panthera 2.0 into your game with precision and ease.
