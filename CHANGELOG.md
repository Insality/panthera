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
	- Now `panthera.create_go(animation_path_or_table, [collection_name], [objects])` instead of `panthera.create_go(animation_path, [get_node)`.
	- Now `panthera.create_gui(animation_path_or_table, [template_name], [nodes])` instead of `panthera.create_gui(animation_path, [get_node])`.
	- Animation now can be created with a table with animation data directly. You can load JSON by yourself or load it from lua table.
	- Instead of `get_node` parameter, you should pass template/collection name and nodes/objects table. Nodes are created from `gui.clone_tree`, objects are created from `collectionfactory.create`.
	- To migrate to new version, you should modify your code to the new signature, or create animations with `panthera.create(animation_path_or_table, adapter, get_node)` function. Adapter can be obtained by `require("panthera.adapters.adapter_[go|gui]")`.
- Update documentation.
- Add more examples with running animations in different scenarios.
- The `animation_state` table now contains `animation_id`, instead of `animation` table data. It will be better to log/pprint the animation state.
- Rename file `panthera_system` to `panthera_internal`.
