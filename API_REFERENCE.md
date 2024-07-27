# API Reference

## Table of Contents

- [Setup and Initialization](#setup-and-initialization)
- [Animation Functions](#animation-functions)
  - [panthera.create_gui](#pantheracreate_gui)
  - [panthera.create_go](#pantheracreate_go)
  - [panthera.create](#pantheracreate)
  - [panthera.clone_state](#pantheraclone_state)
  - [panthera.play](#pantheraplay)
  - [panthera.stop](#pantherastop)
  - [panthera.reload_animation](#pantherareload_animation)
  - [panthera.set_time](#pantheraset_time)
  - [panthera.get_time](#pantheraget_time)
  - [panthera.get_duration](#pantheraget_duration)
  - [panthera.is_playing](#pantherais_playing)
  - [panthera.get_latest_animation_id](#pantheraget_latest_animation_id)
- [Configuration Functions](#configuration-functions)
  - [panthera.set_logger](#pantheraset_logger)

## Setup and Initialization

To utilize Panthera Runtime in your Defold project for playing **Panthera 2.0** animations, start by importing the Panthera Runtime module:

```lua
local panthera = require("panthera.panthera")
```

## Animation Functions

**panthera.create_gui**
---
Load and create a GUI animation state from a JSON file or Lua table.

The Panthera uses `sys.load_resource` to load the JSON animation file. Place your animation files inside your [custom resources folder](https://defold.com/manuals/project-settings/#custom-resources) to ensure they are included in the build.

```lua
panthera.create_gui(animation_path_or_table, [template], [nodes])
```

- **Parameters:**
  - `animation_path_or_table`: The path to the animation JSON file or a table with animation data. Example: `/animations/my_gui_animation.json`.
  - `template` (optional): The GUI template id to load nodes from. Pass nil if no template is used.
  - `nodes` (optional): Table with nodes from `gui.clone_tree()` function. Pass nil if nodes are not cloned.

- **Returns:** An animation state object or `nil` if the animation cannot be loaded.

- **Usage Example:**

```lua
local PATH = "/animations/my_gui_animation.json"

-- Create over GUI on current scene
local gui_animation = panthera.create_gui(PATH)

-- Create over GUI template on current scene
local gui_animation = panthera.create_gui(PATH, "template_name")

-- Create over cloned GUI nodes
local nodes = gui.clone_tree(gui.get_node("root"))
local gui_animation = panthera.create_gui(PATH, nil, nodes)

-- Create over cloned GUI template
local nodes = gui.clone_tree(gui.get_node("template_name/root"))
local gui_animation = panthera.create_gui(PATH, "template_name", nodes)
```

```lua
-- Using Lua table with animation data
local animation_data = require("animations.my_animation_data")
local gui_animation = panthera.create_gui(animation_data)
```


**panthera.create_go**
---
Load and create a game object (GO) animation state from a JSON file or Lua table.

The Panthera uses `sys.load_resource` to load the JSON animation file. Place your animation files inside your [custom resources folder](https://defold.com/manuals/project-settings/#custom-resources) to ensure they are included in the build.

```lua
panthera.create_go(animation_path_or_table, [collection_name], [objects])
```

- **Parameters:**
  - `animation_path_or_table`: The path to the animation JSON file or a table with animation data. Example: `/animations/my_animation.json`.
  - `collection_name` (optional): The name of the collection to load objects from. Pass `nil` if no collection is used.
  - `objects` (optional): Table with object ids from collectionfactory.create() function. Pass `nil` if objects are not created.

- **Returns:** An animation state object or `nil` if the animation cannot be loaded.

- **Usage Example:**

```lua
local PATH = "/animations/my_animation.json"

-- Create over objects on current scene
local go_animation = panthera.create_go(PATH)

-- Create over collection on current scene
local go_animation = panthera.create_go(PATH, "collection_name")

-- Create over Game Object from spawned factory
-- You should create a table with mapping object to created instance.
-- Instead "/pantera" use object id from animation
local object = factory.create("#factory")
local go_animation = panthera.create_go(PATH, nil, { [hash("/panthera")]  = object })

-- Create over objects from spawned collectionfactory
local objects = collectionfactory.create("#collectionfactory")
local go_animation = panthera.create_go(PATH, nil, objects)

-- Create over objects from collectionfactory inside spawned collection
local objects = collectionfactory.create("#collectionfactory")
local go_animation = panthera.create_go(PATH, "collection_name", objects)
```

```lua
-- Using Lua table with animation data
local animation_data = require("animations.my_animation_data")
local go_animation = panthera.create_go(animation_data)
```


**panthera.create**
---
Load an animation from a JSON file or Lua table and create an animation state using a specified adapter. This is a foundational method that `create_go` and `create_gui` build upon, allowing for generic animation creation with custom adapters.

The Panthera uses `sys.load_resource` to load the JSON animation file. Place your animation files inside your [custom resources folder](https://defold.com/manuals/project-settings/#custom-resources) to ensure they are included in the build.

```lua
panthera.create(animation_path_or_table, adapter, get_node)
```

- **Parameters:**
  - `animation_path_or_table`: The path to the animation JSON file or a table with animation data. Example: `/animations/my_animation.json`.
  - `adapter`: An adapter object that specifies how Panthera Runtime interacts with Engine.
  - `get_node`: A custom function to resolve nodes by their ID. This function is used by the adapter to retrieve Defold nodes for animation.

- **Returns:** An animation state object. This object contains the loaded animation data and state necessary for playback. Returns `nil` and an error message if the animation cannot be loaded.

- **Usage Example:**

```lua
-- For GO animations
local adapter_go = require("panthera.adapters.adapter_go")
local go_animation_state = panthera.create("/animations/player_animation.json", adapter_go)

-- For GUI animations
local adapter_gui = require("panthera.adapters.adapter_gui")
local gui_animation_state = panthera.create("/animations/gui_animation.json", adapter_gui)
```

```lua
-- Using Lua table with animation data
local adapter = require("panthera.adapters.adapter_go")
local animation_data = require("animations.my_animation_data")
local go_animation_state = panthera.create(animation_data, adapter)
```

This method is essential for advanced users who need to implement custom animation logic or integrate Panthera animations with non-standard Defold components. It provides the flexibility to work directly with the underlying adapters, enabling a wide range of animation functionalities. Read about Panthera adapters in the [adapter documentation](docs/panthera_adapter.md).


**panthera.clone_state**
---
Clone an existing animation state object, enabling multiple instances of the same animation to play simultaneously or independently.

```lua
panthera.clone_state(animation_state)
```

- **Parameters:**
  - `animation_state`: The animation state object to clone.

- **Returns:** A new animation state object that is a copy of the original.

- **Usage Example:**

```lua
local go_animation_state = panthera.create_go("/animations/player_animation.json")
local cloned_state = panthera.clone_state(go_animation_state)
```


**panthera.play**
---
Play an animation with specified ID and options.

```lua
panthera.play(animation_state, animation_id, [options])
```

- **Parameters:**
  - `animation_state`: The animation state object returned by `create_go` or `create_gui`.
  - `animation_id`: A string identifier for the animation to play.
  - `options` (optional): A table of playback options, as described in the [Animation Playback Options](#animation-playback-options) section.

- **Usage Example:**

```lua
panthera.play(go_animation_state, "walk", { is_loop = true, speed = 1 })
```

### Animation Playback Options

Customize animation behavior in Panthera Runtime using a table of options passed to `panthera.play`.

**Options:**

- **`is_loop`**: Loop the animation (`true`/`false`). Triggers the callback at each loop end if set to `true`.
- **`is_skip_init`**: Start animation from its current state, skipping initial setup (`true`/`false`).
- **`is_relative`**: Apply tween values relative to the object's current state (`true`/`false`).
- **`speed`**: Playback speed multiplier (default `1`). Values >1 increase speed, <1 decrease.
- **`callback`**: Function called when the animation finishes. Receives `animation_id`.
- **`callback_event`**: Function triggered by animation events. Receives `event_id`, optional `node`, `string_value`, and `number_value`.

- **Usage Example:**

```lua
local options = {
    is_loop = true,
    speed = 1.2,
    callback = function(animation_id)
        print("Finished animation: " .. animation_id)
    end,
    callback_event = function(event_id, node, string_value, number_value)
        print("Event: " .. event_id)
    end
}

panthera.play(animation_state, "animation_id", options)
```

These options enable precise control over animation playback, enhancing interactivity and visual dynamics in your game projects.

**panthera.stop**
---
Stop a currently playing animation.

```lua
panthera.stop(animation_state)
```

- **Parameters:**
  - `animation_state`: The animation state object to stop.

- **Usage Example:**

```lua
panthera.stop(go_animation_state)
```

**panthera.reload_animation**
---
Reload animations from JSON files, useful for development and debugging. If no path is provided, all loaded animations are reloaded.

The animations loaded from Lua tables will not be reloaded.

```lua
panthera.reload_animation([animation_path])
```

- **Parameters:**
  - `animation_path` (optional): Specific animation to reload. If omitted, all loaded animations are reloaded.

- **Usage Example:**

```lua
-- Reload single animation
panthera.reload_animation("/animations/my_animation.json")

-- Reload all loaded animations
panthera.reload_animation()
```

**panthera.set_time**
---
Directly set the current playback time of an animation, useful for seeking to a specific point or synchronizing animations.

```lua
panthera.set_time(animation_state, animation_id, time)
```

- **Parameters:**
  - `animation_state`: The animation state object returned by `create_go` or `create_gui`.
  - `animation_id`: The ID of the animation to modify.
  - `time`: The target time in seconds to which the animation should be set.

- **Usage Example:**

```lua
-- Set the animation to start playing from 2 seconds in
panthera.set_time(self.go_animation, "run", 2)
```

This function stops any currently playing animation and updates the animation state to the specified time, allowing for immediate playback from that point or preparation for a triggered start.


**panthera.get_time**
---
Retrieve the current playback time of an animation, useful for tracking the animation's progress or synchronizing game events. If the animation is not playing, the function returns 0.

```lua
local time = panthera.get_time(animation_state)
```

- **Parameters:**
  - `animation_state`: The animation state object.

- **Returns:** The current playback time of the animation in seconds.

- **Usage Example:**

```lua
local time = panthera.get_time(self.go_animation)
print("Current animation time: ", time, "seconds")
```

**panthera.get_duration**
---
Retrieve the total duration of a specific animation, enabling dynamic timing decisions or UI updates based on animation length.

```lua
local duration = panthera.get_duration(animation_state, animation_id)
```

- **Parameters:**
  - `animation_state`: The animation state object.
  - `animation_id`: The ID of the animation whose duration you want to retrieve.

- **Returns:** The total duration of the animation in seconds.

- **Usage Example:**

```lua
local duration = panthera.get_duration(self.go_animation, "run")
print("Total animation duration: ", duration, "seconds")
```

Knowing the duration of an animation is particularly useful for scheduling other events or actions to occur immediately after an animation completes, ensuring smooth transitions and cohesive gameplay experiences.

**panthera.is_playing**
---
Check if an animation is currently playing.

```lua
local is_playing = panthera.is_playing(animation_state)
```

- **Parameters:**
  - `animation_state`: The animation state object.

- **Returns:** `true` if the animation is currently playing, `false` otherwise.

- **Usage Example:**

```lua
local is_playing = panthera.is_playing(self.go_animation)
if is_playing then
	print("The animation is currently playing")
end
```

This function is useful for determining whether an animation is active and can be used to trigger other game events or actions based on the animation's state.


**panthera.get_latest_animation_id**
---
Check the ID of the last animation that was started.

```lua
local animation_id = panthera.get_latest_animation_id(animation_state)
```

- **Parameters:**
  - `animation_state`: The animation state object.

- **Returns:** The ID of the last animation that was started.

- **Usage Example:**

```lua
local animation_id = panthera.get_latest_animation_id(self.go_animation)
print("Latest started animation ID: ", animation_id)
```

This function is useful for tracking the last animation that was started, allowing for dynamic behavior based on the most recent animation played.


## Configuration Functions

**panthera.set_logger**
---
Customize the logging mechanism used by **Panthera Runtime**. You can use **Defold Log** library or provide a custom logger.

```lua
panthera.set_logger(logger_instance)
```

- **Parameters:**
  - `logger_instance`: A logger object that follows the specified logging interface, including methods for `trace`, `debug`, `info`, `warn`, `error`. Pass `nil` to remove the default logger.

- **Usage Example:**

Using the [Defold Log](https://github.com/Insality/defold-log) module:
```lua
local log = require("log.log")
local panthera = require("panthera.panthera")

panthera.set_logger(log.get_logger("panthera"))
```

Creating a custom user logger:
```lua
local logger = {
    trace = function(_, message, context) end,
    debug = function(_, message, context) end,
    info = function(_, message, context) end,
    warn = function(_, message, context) end,
    error = function(_, message, context) end
}
panthera.set_logger(logger)
```

Remove the default logger:
```lua
panthera.set_logger(nil)
```
