![](media/runtime_logo.png)

[![Github-sponsors](https://img.shields.io/badge/sponsor-30363D?style=for-the-badge&logo=GitHub-Sponsors&logoColor=#EA4AAA)](https://github.com/sponsors/insality) [![Ko-Fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/insality) [![BuyMeACoffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/insality)

[![](https://img.shields.io/badge/Release-download-blue?style=for-the-badge)](https://github.com/Insality/panthera/tags)

# Panthera Runtime

**Panthera Runtime** - a [Defold](https://defold.com/) library designed to integrate animations created with [**Panthera 2.0 Editor**](/docs_editor/README.md), seamlessly integrate **Panthera 2.0** animations into your Defold projects. This runtime can play animation for Game Objects and GUI nodes with a also a animation cursor support.

## Features

- **Seamless Integration**: Import and use **Panthera 2.0** directly in Defold with one click.
- **Full Animation Support**: Supports all animation features provided by **Panthera 2.0**, including events, nested animations, all available properties and more.
- **Flexible Usage**: Compatible with both Game Objects and GUI nodes in Defold, allowing for flexible usage across different game elements.
- **Animation Cursor**: Provides a way to control animation manually, allowing for precise control over playback and synchronization with game events.

## Panthera 2.0 Editor

Read the [**Panthera 2.0 Editor**](/docs_editor/README.md) guide to learn about the **Panthera 2.0 Editor**. This is the animation editor that you can use to create animations for your Defold projects, created with [Defold engine](https://defold.com/) and [Druid UI framework](https://github.com/Insality/druid)!

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

Read the [API Reference](api/panthera_api.md) file to see the full API documentation for the module.

```lua
-- Create animation states
panthera.create_gui(animation_path_or_data, [template], [nodes])
panthera.create_go(animation_path_or_data, [collection_name], [objects])
panthera.create(animation_path_or_data, adapter, get_node)
panthera.clone_state(animation_state)

-- Animation control
panthera.play(animation_state, animation_id, [options])
panthera.stop(animation_state)
panthera.set_time(animation_state, animation_id, time)
panthera.get_time(animation_state)
panthera.get_duration(animation_state, animation_id)
panthera.is_playing(animation_state)
panthera.get_latest_animation_id(animation_state)

-- Utils
panthera.set_logger([logger_instance])
panthera.reload_animation([animation_path])
```


### Documentation

- [API Reference](api/panthera_api.md)
- [Animation Blending](docs/animation_blending.md)
- [Customizing Your Adapter](docs/panthera_adapter.md)


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
