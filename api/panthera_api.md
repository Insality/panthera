# panthera API

> at /panthera/panthera.lua

## Functions

- [set_logger](#set_logger)
- [create_go](#create_go)
- [create_gui](#create_gui)
- [create](#create)
- [clone_state](#clone_state)
- [play](#play)
- [play_tweener](#play_tweener)
- [play_detached](#play_detached)
- [set_time](#set_time)
- [get_time](#get_time)
- [stop](#stop)
- [get_duration](#get_duration)
- [is_playing](#is_playing)
- [get_latest_animation_id](#get_latest_animation_id)
- [get_animations](#get_animations)
- [reload_animation](#reload_animation)

## Fields

- [SPEED](#SPEED)
- [OPTIONS_LOOP](#OPTIONS_LOOP)
- [OPTIONS_SKIP_INIT](#OPTIONS_SKIP_INIT)
- [OPTIONS_SKIP_INIT_LOOP](#OPTIONS_SKIP_INIT_LOOP)



### set_logger

---
```lua
panthera.set_logger([logger_instance])
```

Customize the logging mechanism used by Panthera Runtime. You can use Defold Log library or provide a custom logger.

- **Parameters:**
	- `[logger_instance]` *((table|panthera.logger)?)*: A logger object that follows the specified logging interface. Pass nil to use empty logger

### create_go

---
```lua
panthera.create_go(animation_or_path, [collection_name], [objects])
```

Load and create a game object animation state from a Lua table or JSON file.

- **Parameters:**
	- `animation_or_path` *(string|table)*: Lua table with animation data or path to JSON animation file in custom resources
	- `[collection_name]` *(string?)*: Collection name to load nodes from. Pass nil if no collection is used
	- `[objects]` *(table<string|hash, string|hash>?)*: Table with game objects from collectionfactory. Pass nil if no objects are used

- **Returns:**
	- `animation` *(panthera.animation)*: Animation state or nil if animation can't be loaded

### create_gui

---
```lua
panthera.create_gui(animation_or_path, [template], [nodes])
```

Load and create a GUI animation state from a Lua table or JSON file.

- **Parameters:**
	- `animation_or_path` *(string|table)*: Lua table with animation data or path to JSON animation file in custom resources
	- `[template]` *(string?)*: The GUI template ID to load nodes from. Pass nil if no template is used
	- `[nodes]` *(table<string|hash, node>?)*: Table with nodes from gui.clone_tree() function. Pass nil if no nodes are used

- **Returns:**
	- `animation` *(panthera.animation)*: Animation state or nil if animation can't be loaded

### create

---
```lua
panthera.create(animation_or_path, adapter, get_node)
```

Load an animation from a Lua table or JSON file and create an animation state using a specified adapter.

- **Parameters:**
	- `animation_or_path` *(string|table)*: Lua table with animation data or path to JSON animation file in custom resources
	- `adapter` *(panthera.adapter)*: An adapter object that specifies how Panthera Runtime interacts with Engine
	- `get_node` *(fun(node_id: string):node)*: Function to get node by node_id. A custom function to resolve nodes by their ID

- **Returns:**
	- `animation` *(panthera.animation)*: Animation state or nil if animation can't be loaded

### clone_state

---
```lua
panthera.clone_state(animation_state)
```

Clone an existing animation state object, enabling multiple instances of the same animation to play simultaneously or independently.

- **Parameters:**
	- `animation_state` *(panthera.animation)*: The animation state object to clone

- **Returns:**
	- `animation` *(panthera.animation)*: New animation state object that is a copy of the original

### play

---
```lua
panthera.play(animation_state, animation_id, [options])
```

Play an animation with specified ID and options.

- **Parameters:**
	- `animation_state` *(panthera.animation)*: The animation state object returned by `create_go` or `create_gui`
	- `animation_id` *(string)*: The ID of the animation to play
	- `[options]` *((panthera.options)?)*: Options for the animation playback

- **Returns:**
	- `` *(nil)*:

### play_tweener

---
```lua
panthera.play_tweener(animation_state, animation_id, [options])
```

Play animation with easing support using tweener. Allows for non-linear animation playback with custom easing functions.

- **Parameters:**
	- `animation_state` *(panthera.animation)*: The animation state object
	- `animation_id` *(string)*: The ID of the animation to play
	- `[options]` *((panthera.options_tweener)?)*: Options including easing function, speed, and callbacks

- **Returns:**
	- `` *(nil)*:

### play_detached

---
```lua
panthera.play_detached(animation_state, animation_id, [options])
```

Play animation as a child of the current animation state, allowing multiple animations to run independently and simultaneously.
This creates a detached animation that runs in parallel with the main animation state without affecting it.
The child animation will be automatically cleaned up when it completes.

- **Parameters:**
	- `animation_state` *(panthera.animation)*: The parent animation state object
	- `animation_id` *(string)*: The ID of the animation to play as a detached child
	- `[options]` *((panthera.options)?)*: Options for the detached animation playback

### set_time

---
```lua
panthera.set_time(animation_state, animation_id, time, [event_callback])
```

Set the current time of an animation. This function stops any currently playing animation.

- **Parameters:**
	- `animation_state` *(panthera.animation)*: The animation state object returned by `create_go` or `create_gui`.
	- `animation_id` *(string)*: The ID of the animation to modify.
	- `time` *(number)*: The target time in seconds to which the animation should be set.
	- `[event_callback]` *(fun(event_id: string, node: node|nil, string_value: string, number_value: number)|nil)*:

- **Returns:**
	- `result` *(boolean)*: True if animation state was set successfully, false if animation can't be set

### get_time

---
```lua
panthera.get_time(animation_state)
```

Retrieve the current playback time in seconds of an animation. If the animation is not playing, the function returns 0.

- **Parameters:**
	- `animation_state` *(panthera.animation)*: The animation state object

- **Returns:**
	- `Current` *(number)*: animation time in seconds

### stop

---
```lua
panthera.stop(animation_state)
```

Stop a currently playing animation. The animation will be stopped at current time.

- **Parameters:**
	- `animation_state` *(panthera.animation)*: The animation state object to stop

- **Returns:**
	- `True` *(boolean)*: if animation was stopped, false if animation is not playing

### get_duration

---
```lua
panthera.get_duration(animation_state, animation_id)
```

Retrieve the total duration of a specific animation.

- **Parameters:**
	- `animation_state` *(panthera.animation)*: The animation state object
	- `animation_id` *(string)*: The ID of the animation whose duration you want to retrieve

- **Returns:**
	- `The` *(number)*: total duration of the animation in seconds

### is_playing

---
```lua
panthera.is_playing(animation_state)
```

Check if an animation is currently playing.

- **Parameters:**
	- `animation_state` *(panthera.animation)*: The animation state object

- **Returns:**
	- `True` *(boolean)*: if the animation is currently playing, false otherwise

### get_latest_animation_id

---
```lua
panthera.get_latest_animation_id(animation_state)
```

Get the ID of the last animation that was started.

- **Parameters:**
	- `animation_state` *(panthera.animation)*: The animation state object

- **Returns:**
	- `Animation` *(string?)*: ID or nil if no animation was started

### get_animations

---
```lua
panthera.get_animations(animation_state)
```

Return a list of animation IDs from the created animation state.

- **Parameters:**
	- `animation_state` *(panthera.animation)*: The animation state object

- **Returns:**
	- `Array` *(string[])*: of animation IDs available in the animation state

### reload_animation

---
```lua
panthera.reload_animation([animation_path])
```

Reload animations from JSON files, useful for development and debugging.
The animations loaded from Lua tables will not be reloaded.
Animation will be reloaded only at desktop.

- **Parameters:**
	- `[animation_path]` *(string?)*: Specific animation to reload. If omitted, all loaded animations are reloaded


## Fields
<a name="SPEED"></a>
- **SPEED** (_number_): Default speed of all animations

<a name="OPTIONS_LOOP"></a>
- **OPTIONS_LOOP** (_table_):  Set of predefined options

<a name="OPTIONS_SKIP_INIT"></a>
- **OPTIONS_SKIP_INIT** (_table_)

<a name="OPTIONS_SKIP_INIT_LOOP"></a>
- **OPTIONS_SKIP_INIT_LOOP** (_table_)

