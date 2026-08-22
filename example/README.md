# Panthera Runtime Example

An interactive browser of Panthera animations, built with [Druid](https://github.com/Insality/druid).
It is the bootstrap collection of this project, so just run the project to open it.

## Layout

- **Left** — the examples, grouped into the `GUI`, `Collections` and `Game Objects` sections.
- **Center** — the animated scene and the timeline. The corners show the source of the scene and
  the Lua memory in use. Drag the timeline slider to scrub the animation back and forth, the play
  button pauses and resumes the playback.
- **Right** — the animations of the selected example and the playback settings.

## Controls

| Input | Action |
| --- | --- |
| `Space` | Pause / resume the playback |
| `Up` / `Down` | Select the previous / next animation |
| Click on an animation | Play it as the only track, from the beginning even if it is already selected |
| `Shift` + click on an animation | Play it as the second track next to the selected one |

## Play All

The `Play All` button in the header of the examples list runs every animation one after another,
starting from the selected animation of the selected example and going to the end of the list. It
plays at the speed set in the panel and turns the loop off, since a looped animation never ends.
Pressing the button again or clicking anything in the lists takes the control back.

## Two tracks

An example can play two animations at once. Shift click an animation to put it on the second track:
it gets its own color and its own timeline under the first one. The tracks animate the same example
over two animation states, so they run independently and can be at different times. A plain click
drops the second track and goes back to a single animation.

The playback settings apply to both tracks. The easing is split in two properties: `Ease Mode`
picks `in` / `out` / `inout` / `outin` and `Ease Type` picks the family, and the two are composed
into the easing Panthera plays with. A click on the **name** of a property resets it to its default:
`out` for the mode, `linear` for the type and `x1.00` for the speed.

`Loop` and `Speed` are applied to the next animation cycle without restarting it, while changing the
easing replays the animations: it switches Panthera between the timer based playback and the tweener
based one. Selecting an animation resets the ease type back to `linear`.

## Examples

| Section | Example | What it shows |
| --- | --- | --- |
| GUI | Basic Properties | Position, rotation, scale, color, alpha and size tweens |
| GUI | Easings | The same tween played with the `in`, `out`, `inout` and `outin` variants of each easing |
| GUI | Dots | A small animation set over a three node template |
| GUI | Template Animations | Animation keys that run the animations of a nested GUI template, from its own file |
| GUI | Nested Animations | Animation keys without a node id, running other animations of the same file |
| GUI | Nested and Template | Both kinds of animation keys side by side in one animation |
| GUI | Deep Templates | A template inside a template: the scene drives a panel that drives its own dots |
| GUI | Triggers and Events | Trigger keys that set node properties and event keys reported to the game code |
| GUI | Text Properties | Tracking, leading, outline and shadow of a text node, and text triggers |
| GUI | Pie and Slice9 | The fill angle and the inner radius of a pie node, and the slice9 of a box |
| GUI | Clipping | An animated stencil mask over a static content |
| GUI | Screen Transitions | Two fullscreen wipes, each split into an `appear` and a `disappear` half that `together` chains |
| GUI | Character Blend | Three animation states over the same nodes, two of them blended from the mouse position. Character assets by [Kenney](https://kenney.nl/) |
| Collections | Shapes | A collection of sprites animated by their object and component properties |
| Collections | Hierarchy | Child objects following the animated parent through its local transform |
| Collections | Scene Objects | Objects that are already in the bootstrap collection, with no factory at all |
| Collections | Scene Collection | A collection instance of the bootstrap collection, addressed by its name |
| Collections | Nested Collection | A spawned collection that holds a nested one, addressed by the name of the inner |
| Game Objects | Sprite | A single game object: transform, tint, alpha and flipbook triggers |
| Game Objects | Label | A label component: text triggers, color, outline and a pop in animation |
| Game Objects | Components | One object with two sprites and a label, animated component by component |
| Game Objects | Two Objects | Two objects from two factories, mapped into one animation |

## How the examples are hosted

A GUI example is a GUI template inside the `examples` node of [example.gui](example.gui) and is
animated with `panthera.create_gui`.

The world is rendered by an orthographic camera looking at the origin, and every spawned example is
parented to the `scene_root` object that sits there, so the animations play around the center of the
screen in their own local space.

A collection or a game object example is animated with `panthera.create_go`, and the examples cover
every way it can be called: over the objects of the bootstrap collection, over a collection instance
of it addressed by name, over the objects of a spawned collection, over a spawned collection that
holds a nested one, and over objects spawned one by one from a factory. The `scene` game object owns
the factories, and [scene/scene.script](scene/scene.script) picks the variant from the fields of the
example. The GUI is drawn on
top of the world, so the center panel does not draw a background of its own — it only clips the GUI
examples, and the world behind it is painted by the render clear color.

Panthera animates game objects with the `go.*` functions, which are not available in a GUI script.
[scene/scene.script](scene/scene.script) owns the spawned objects and every Panthera call over them;
the GUI script drives it through Defold Event, which switches the script context and returns the
result, so the calls read like plain function calls.

## Scenes with their own logic

An example can point at a Druid widget module with the `widget` field. The browser creates it over
the template of the example, so the scene can handle input, create animation states of its own and
append properties to the panel through an optional `properties_control(properties_panel)` method.
[examples/character/character.lua](examples/character/character.lua) is the one example that uses
it: it scrubs two animation states with `panthera.set_time` from the mouse position.

## Adding an example

1. Create the scene to animate in `/example/examples/<name>/`: a GUI scene, a collection or a
   game object.
2. Animate it in the [Panthera 2 editor](https://github.com/Insality/panthera) and save the
   animation next to the scene as `<name>_panthera.lua`.
3. Make it reachable: add a GUI scene as a template inside the `examples` node of
   [example.gui](example.gui), or add a factory for it to the `scene` game object of
   [example.collection](example.collection).
4. Register it in [examples/examples_list.lua](examples/examples_list.lua).

The animations list, the timeline and the playback settings are filled from the animation data,
so nothing else has to be written for a new example.

An animation key drives another animation instead of a property. Without a node id it plays
another animation of the same file, with one it plays an animation of the template animation bound
to that node, and both can be used together in a single animation.

Author every animation so that each property starts from the state of the scene. Panthera resets
a node to the start value of the first key of the property when another animation is played over
it, so an animation that starts from an offset leaves the node parked at that offset once you
switch away from it.
