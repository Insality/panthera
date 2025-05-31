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
- [async_play](#async_play)
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

Customize the logging mechanism used by **Panthera Runtime**. You can use **Defold Log** library or provide a custom logger.

- **Parameters:**
	- `[logger_instance]` *(table|panthera.logger|nil)*:

### create_go

---
```lua
panthera.create_go(animation_path_or_data, [collection_name], [objects])
```

Load animation from JSON file or direct data and create it with Panthera GO adapter

- **Parameters:**
	- `animation_path_or_data` *(string|table)*: Path to JSON animation file in custom resources or table with animation data
	- `[collection_name]` *(string|nil)*: Collection name to load nodes from. Pass nil if no collection is used
	- `[objects]` *(table<string|hash, string|hash>|nil)*: Table with game objects from collectionfactory. Pass nil if no objects are used

- **Returns:**
	- `Animation` *(panthera.animation)*: data or nil if animation can't be loaded, error message

### create_gui

---
```lua
panthera.create_gui(animation_path_or_data, [template], [nodes])
```

Load animation from JSON file or direct data and create it with Panthera GUI adapter

- **Parameters:**
	- `animation_path_or_data` *(string|table)*: Path to JSON animation file in custom resources or table with animation data
	- `[template]` *(string|nil)*: The GUI template id to load nodes from. Pass nil if no template is used
	- `[nodes]` *(table<string|hash, node>|nil)*: Table with nodes from gui.clone_tree() function. Pass nil if no nodes are used

- **Returns:**
	- `Animation` *(panthera.animation)*: data or nil if animation can't be loaded, error message

### create

---
```lua
panthera.create(animation_path_or_data, adapter, get_node)
```

Load animation from JSON file

- **Parameters:**
	- `animation_path_or_data` *(string|table)*: Path to JSON animation file in custom resources or table with animation data
	- `adapter` *(panthera.adapter)*:
	- `get_node` *(fun(node_id: string):node)*: Function to get node by node_id. Default is defined in adapter

- **Returns:**
	- `Animation` *(panthera.animation)*: data or nil if animation can't be loaded, error message

### clone_state

---
```lua
panthera.clone_state(animation_state)
```

Create identical copy of animation state to run it in parallel

- **Parameters:**
	- `animation_state` *(panthera.animation)*:

- **Returns:**
	- `New` *(panthera.animation)*: animation state or nil if animation can't be cloned

### play

---
```lua
panthera.play(animation_state, animation_id, [options])
```

- **Parameters:**
	- `animation_state` *(panthera.animation)*:
	- `animation_id` *(string)*:
	- `[options]` *(panthera.options|nil)*:

- **Returns:**
	- `` *(nil)*:

### play_tweener

---
```lua
panthera.play_tweener(animation_state, animation_id, [options])
```

 TODO: make it inside play somehow

- **Parameters:**
	- `animation_state` *(panthera.animation)*:
	- `animation_id` *(string)*:
	- `[options]` *(panthera.options_tweener|nil)*:

- **Returns:**
	- `` *(nil)*:

### play_detached

---
```lua
panthera.play_detached(animation_state, animation_id, [options])
```

 TODO: make it inside play somehow
Play animation as a child of the current animation state

- **Parameters:**
	- `animation_state` *(panthera.animation)*:
	- `animation_id` *(string)*:
	- `[options]` *(any)*:

### async_play

---
```lua
panthera.async_play(animation_state, animation_id, [options])
```

Play animation asynchronously

- **Parameters:**
	- `animation_state` *(panthera.animation)*:
	- `animation_id` *(string)*:
	- `[options]` *((panthera.options)?)*:

### set_time

---
```lua
panthera.set_time(animation_state, animation_id, time, [event_callback])
```

Set animation state at specific time. This will stop animation if it's playing

- **Parameters:**
	- `animation_state` *(panthera.animation)*:
	- `animation_id` *(string)*:
	- `time` *(number)*:
	- `[event_callback]` *(fun(event_id: string, node: node|nil, string_value: string, number_value: number)|nil)*:

- **Returns:**
	- `result` *(boolean)*: Animation state or nil if animation can't be set

### get_time

---
```lua
panthera.get_time(animation_state)
```

Retrieve the current playback time in seconds of an animation. If the animation is not playing, the function returns 0.

- **Parameters:**
	- `animation_state` *(panthera.animation)*:

- **Returns:**
	- `Current` *(number)*: animation time in seconds

### stop

---
```lua
panthera.stop(animation_state)
```

Stop playing animation. The animation will be stopped at current time.

- **Parameters:**
	- `animation_state` *(panthera.animation)*:

- **Returns:**
	- `True` *(boolean)*: if animation was stopped, false if animation is not playing

### get_duration

---
```lua
panthera.get_duration(animation_state, animation_id)
```

Retrieve the total duration of a specific animation.

- **Parameters:**
	- `animation_state` *(panthera.animation)*:
	- `animation_id` *(string)*:

- **Returns:**
	- `` *(number)*:

### is_playing

---
```lua
panthera.is_playing(animation_state)
```

Check if an animation is currently playing.

- **Parameters:**
	- `animation_state` *(panthera.animation)*:

- **Returns:**
	- `` *(boolean)*:

### get_latest_animation_id

---
```lua
panthera.get_latest_animation_id(animation_state)
```

Get the ID of the last animation that was started.

- **Parameters:**
	- `animation_state` *(panthera.animation)*: Animation state

- **Returns:**
	- `Animation` *(string|nil)*: id or nil if animation is not playing

### get_animations

---
```lua
panthera.get_animations(animation_state)
```

 Return a list of animation ids from the created animation state

- **Parameters:**
	- `animation_state` *(panthera.animation)*:

- **Returns:**
	- `` *(string[])*:

### reload_animation

---
```lua
panthera.reload_animation([animation_path])
```

Desktop Only. Reload animation from JSON file. All current animation will be updated on the next play() function
or after the next set_time() function
Animation will be reloaded only at desktop. Only if we have a Panthera file
inside resources with the user folder directory path

- **Parameters:**
	- `[animation_path]` *(string|nil)*: If nil - reload all loaded animations


## Fields
<a name="SPEED"></a>
- **SPEED** (_number_): Default speed of all animations

<a name="OPTIONS_LOOP"></a>
- **OPTIONS_LOOP** (_table_)

<a name="OPTIONS_SKIP_INIT"></a>
- **OPTIONS_SKIP_INIT** (_table_)

<a name="OPTIONS_SKIP_INIT_LOOP"></a>
- **OPTIONS_SKIP_INIT_LOOP** (_table_)

