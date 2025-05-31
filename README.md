![](media/runtime_logo.png)

[![Github-sponsors](https://img.shields.io/badge/sponsor-30363D?style=for-the-badge&logo=GitHub-Sponsors&logoColor=#EA4AAA)](https://github.com/sponsors/insality) [![Ko-Fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/insality) [![BuyMeACoffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/insality)

[![](https://img.shields.io/badge/Release-download-blue?style=for-the-badge)](https://github.com/Insality/panthera/tags)

# Panthera Runtime

**Panthera Runtime** - a [Defold](https://defold.com/) library designed to integrate animations created with [**Panthera 2.0 Editor**](/docs_editor/README.md), a versatile animation software, into Defold projects. This runtime library simplifies the process of importing and playing back Panthera animations, enhancing the visual quality and interactivity of Defold games and applications.

## Features

- **Seamless Animation Integration**: Import and use Panthera 2.0 animations directly in Defold.
- **Full Animation Support**: Supports all animation features provided by Panthera 2.0, including events, animation blending, nested animations and more.
- **Flexible Usage**: Compatible with both Game Objects and GUI nodes in Defold, allowing for versatile application across different game elements.
- **Animation Cursor**: Provides a way to control animation manually, allowing for precise control over playback and synchronization with game events.
- **Hot Reloading**: Reload animations on the fly during development, enabling rapid iteration and testing of animation assets.

## Panthera 2.0 Editor

Read the [**Panthera 2.0 Editor**](/docs_editor/README.md) guide to learn about the Panthera 2.0 Editor, an innovative tool developed using the Defold engine, designed to simplify and enhance the creation of animations for Defold projects.

## Setup

### [Dependency](https://defold.com/manuals/libraries/#setting-up-library-dependencies)

Open your `game.project` file and add the following lines to the dependencies field under the project section:


**[Defold Tweener](https://github.com/Insality/defold-tweener)**

```
https://github.com/Insality/defold-tweener/archive/refs/tags/3.zip
```

**[Panthera Runtime](https://github.com/Insality/panthera)**

```
https://github.com/Insality/panthera/archive/refs/tags/runtime.4.zip
```

After that, select `Project ▸ Fetch Libraries` to update [library dependencies]((https://defold.com/manuals/libraries/#setting-up-library-dependencies)). This happens automatically whenever you open a project so you will only need to do this if the dependencies change without re-opening the project.

### Library Size

> **Note:** The library size is calculated based on the build report per platform

| Platform         | Library Size |
| ---------------- | ------------ |
| HTML5            | **12.42 KB** |
| Desktop / Mobile | **21.35 KB** |


## API Reference

### Quick API Reference

```lua
panthera.create_gui(animation_path_or_data, [template], [nodes])
panthera.create_go(animation_path_or_data, [collection_name], [objects])
panthera.create(animation_path_or_data, adapter, get_node)
panthera.clone_state(animation_state)
panthera.play(animation_state, animation_id, [options])
panthera.stop(animation_state)
panthera.set_time(animation_state, animation_id, time)
panthera.get_time(animation_state)
panthera.get_duration(animation_state, animation_id)
panthera.is_playing(animation_state)
panthera.get_latest_animation_id(animation_state)
panthera.set_logger([logger_instance])
panthera.reload_animation([animation_path])
```


### API Reference

Read the [API Reference](API_REFERENCE.md) file to see the full API documentation for the module.


### Usage Examples

Integrate Panthera animations into Defold with these concise examples:

#### Example 1: Start animation in GO

Load and play a animation file using the GO adapter.

```lua
local panthera = require("panthera.panthera")
local animation = require("path.to.panthera_animation")

function init(self)
    self.animation = panthera.create_go(animation)
    panthera.play(self.animation, "run", { is_loop = true })
end
```
This example applies a looping run animation to a game object when the game starts.

#### Example 2: Start animation in GUI

Load and play a animation file using the GUI adapter.

```lua
local panthera = require("panthera.panthera")
local animation = require("path.to.panthera_animation")

function init(self)
    self.animation = panthera.create_gui(animation)
    panthera.play(self.animation, "fade_in")
end
```
This example applies a fade-in animation to a GUI node when the game starts


#### Example 3: Check if animation is playing

Check if an animation is currently playing and retrieve the current animation ID.

```lua
local panthera = require("panthera.panthera")

function init(self)
    -- You can use JSON instead of Lua tables, but it should be accessible with sys.load_resource()
    self.animation = panthera.create_gui("/animations/animation.json")
    local is_playing = panthera.is_playing(self.animation)
    local animation_id = panthera.get_latest_animation_id(self.animation)

    if is_playing then
        print("The animation is currently playing: ", animation_id)
    else
        print("The animation is not playing")
    end
end
```

### GO Animation Restrictions

When integrating Panthera 2.0 animations with Defold game objects (GOs), it's essential to know which properties you can animate:

By default, sprite components uses the `tint` property and label components use the `color` property. Panthera try to use `color` property. To enable `color` property you should set the material of sprite component to `/panthera/materials/sprite.material` or use any other material with `color` attribute.

- **Position**: Move objects.
- **Rotation**: Rotate objects.
- **Scale**: Scale objects.
- **Color**: Update color of sprite or Text component.
- **Slice9**: Update slice9 properties of sprite component.
- **Size**: Update size of sprite component.
- **Text**: Update text content of label component.
- **Texture**: Switch textures of sprite component.
- **Enabled**: Toggle object enabled/disabled.


### Animation Blending

Read the [Animation Blending](docs/animation_blending.md) guide to learn how to blend multiple animations simultaneously on the same entity, creating complex, layered animations that enhance the visual fidelity and dynamism of your game.


### Customizing Your Adapter

While **Panthera** Runtime provides a default adapter for game objects and GUI, you might need to customize your adapter based on your project's needs. Read the [Customizing Your Adapter](docs/panthera_adapter.md) guide to learn how to map easing types, handle custom events, and use your custom adapter with Panthera Runtime.


## License

Panthera Runtime is licensed under the MIT License - see the [LICENSE](/LICENSE) file for details.


## Issues and Suggestions

For any issues, questions, or suggestions, please [create an issue](https://github.com/Insality/panthera/issues).


## Changelog

Read the [CHANGELOG](/CHANGELOG.md) to learn about the latest updates and features in Panthera Runtime.


## 👏 Contributors

<a href="https://github.com/Insality/panthera/graphs/contributors">
  <img src="https://contributors-img.web.app/image?repo=insality/panthera"/>
</a>


## ❤️ Support the Project ❤️

Your support motivates me to keep creating and maintaining projects for **Defold**. Consider supporting if you find my projects helpful and valuable.

[![Github-sponsors](https://img.shields.io/badge/sponsor-30363D?style=for-the-badge&logo=GitHub-Sponsors&logoColor=#EA4AAA)](https://github.com/sponsors/insality) [![Ko-Fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/insality) [![BuyMeACoffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/insality)
