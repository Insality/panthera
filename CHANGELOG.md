# Changelog

## Version v1

Initial resease!


## Version v2

- Add `panthera.clone_state` function to clone animation states.
- Various fixes for correct animation playback.
- Add `speed` modifier for animation states to adjust all animations played by this state.
	- After creating an animation state, you can set the speed of all animations played by this state by setting the `speed` property.
	- Example: `animation_state.speed = 1.5`
- Update documentation.
- Update GO and GUI adapters:
	- GO now supports `color` and `slice9` properties.
	- The default sprite color property is `tint`. To use panthera color property, use `/panthera/materials/sprite.material` or any other with `color` property.
	- GUI: fix slice9 property.
	- GUI: fix for pie vertices and piebounds properties.


## Version v3

- **BREAKING CHANGES**: Change `panthera.create_go` and `panthera.create_gui` functions signature.
	- Now `panthera.create_go(animation_or_path, [collection_name], [objects])` instead of `panthera.create_go(animation_path, [get_node)`.
	- Now `panthera.create_gui(animation_or_path, [template_name], [nodes])` instead of `panthera.create_gui(animation_path, [get_node])`.
	- Animation now can be created with a table with animation data directly. You can load JSON by yourself or load it from lua table.
	- Instead of `get_node` parameter, you should pass template/collection name and nodes/objects table. Nodes are created from `gui.clone_tree`, objects are created from `collectionfactory.create`.
	- To migrate to new version, you should modify your code to the new signature, or create animations with `panthera.create(animation_or_path, adapter, get_node)` function. Adapter can be obtained by `require("panthera.adapters.adapter_[go|gui]")`.
- Add more examples with playing animations in different scenarios.
- Update documentation.
- The `animation_state` table now contains `animation_id`, instead of `animation` table data. It will be better to log or `pprint` the animation state.
- Rename file `panthera_system` to `panthera_internal`.
- Add support for `is_editor_only` timeline key property
- Add support for `easing_custom` timeline key property


## Version v4

- Add Defold Editor scripts to create and edit Panthera animations directly from the Defold Editor
	- Panthera Editor should be started before using the scripts.
- Add time overflow handling for more precise animation playback.


## Version v5
- Add shadow and outline for text labels support
- Now you can use the hashed `animation_id` to play animations. Useful if you want to specify the animation from the script properties (via `go.property`).
- The more precies animation timing with take care of time overflow.
- The `panthera.set_time` now trigger the events in case of forward time change. If animation is played in reverse, events will be not triggered.
- Add `panthera.play_tweener` and `panthera.play_detached` functions to play animations.
	- This is kind of experimental, currently figure out how is it convenient to use.
	- The `play_detached` function plays a animation as a child, able to easily create new "tracks" for animations. Other way is to clone state and play it.
	- The `play_tweener` function plays a animation with a tweener easing. Now you able to adjust the "easing" of the animation and able to play it in reverse. Later should be able to specify the start and end time of the animation.
- Additional checks for deleted nodes in the animation playback (currently only for game objects)
- Add global Panthera speed modifier (panthera.SPEED)
	- Now you can adjust speed with three modifiers
		- global (`panthera.SPEED`)
		- state (`animation_state.speed`)
		- instance animation (`animation.speed`)
- Refactor the animation playback system, should be more performant
- Fix for `is_editor_only` key field
- Various fixes


## Version v6
- Fix [#23](https://github.com/Insality/panthera/issues/23) Sprite image change animation does not work in nested collection
- Fix [#20](https://github.com/Insality/panthera/issues/20) panthera.stop() does not work correctly with animations with multiple tween keys

## Version v7
- Migrate API to Defold 1.13.0
	- Fix `gui.cancel_animation` call for Defold 1.13.0 compatibility

## Version v8
- Use timer `dt` instead of manual `socket.gettime()` delta for animation updates
- Apply the final animation state when an animation reaches its end before stop/callback
- Fix [#35](https://github.com/Insality/panthera/pull/35) GO `objects` map lookup from a nested collection context
	- When `objects` is passed to `panthera.create_go`, keys are resolved as absolute prototype paths (`hash("/" .. id)`), matching `collectionfactory.create()` / documented `{ [hash("/panthera")] = id }` maps

## Version v9
- Fix memory leak and repeated preprocessing for inline (Lua table) animations
	- The same animation table now always resolves to the same animation path and is preprocessed only once, instead of allocating a new cache entry on every `panthera.create_go` / `create_gui` / `create` call
	- Nested template animations passed as tables are cached the same way
- Fix collecting of nested `template_animation_paths`, they were inserted into the table while it was iterated over

## Version v10
- Fix the animation state when several animations are changing the same node property
	- The state is collected first and applied in the order of the keys which set the values, so the last started key always wins, no matter if it comes from the animation itself, a nested or a template animation
- Fix the initial state animation of a nested animation, it is applied at the moment this animation is started
- Fix the properties animated by a nested or a template animation which is not started yet
	- They are reset to their start values instead of keeping the values of the previously played animation. Works for `panthera.play`, `panthera.set_time` and the animations played with easing
- Fix the template animation time, it is scaled to the length of the animation key
- Fix the animation keys skipped by the time overflow, the final state of the animation is applied instead
- Fix the reset of two template nodes bound to the same template animation, only one of them was reset
- Fix the events of the template animations, they were triggered on every animation state update
- Fix the events of the nested animations, they were not passed to the `callback_event` while the animation is playing
- Fix the child animation states leak for the animation keys which are already over
- Fix nested template animations desync on HTML5
	- Playback ticks every frame instead of `1/60` timers, and nested/template animations start on the same frame as the parent
