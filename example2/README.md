# Panthera Runtime Example

An interactive browser of Panthera animations, built with [Druid](https://github.com/Insality/druid).
It is the bootstrap collection of this project, so just run the project to open it.

## Layout

- **Left** — the list of examples. Each example is a GUI template with a Panthera animation over it.
- **Center** — the animated scene and the timeline. Drag the timeline slider to scrub the animation
  back and forth, the play button pauses and resumes the playback.
- **Right** — the animations of the selected example and the playback settings.

## Controls

| Input | Action |
| --- | --- |
| `Space` | Pause / resume the current animation |
| `Up` / `Down` | Select the previous / next animation |
| Click on an animation | Play it from the beginning, even if it is already selected |

The `Loop` and `Speed` settings are applied to the running animation without restarting it, while
changing the `Easing` replays the animation: the easing switches Panthera between the timer based
playback and the tweener based one.

## Examples

| Example | What it shows |
| --- | --- |
| Basic Properties | Position, rotation, scale, color, alpha and size tweens |
| Easings | The same tween played with the `in`, `out`, `inout` and `outin` variants of each easing |
| Dots | A small animation set over a three node template |
| Nested Templates | Animation keys that run the animations of the nested GUI templates |
| Triggers and Events | Trigger keys that set node properties and event keys reported to the game code |

## Adding an example

1. Create a GUI scene with the nodes to animate in `/example2/examples/<name>/`.
2. Animate it in the [Panthera 2 editor](https://github.com/Insality/panthera) and save the
   animation next to the scene as `<name>_panthera.lua`.
3. Add the scene as a template inside the `examples` node of `/example2/example2.gui`.
4. Register it in [examples/examples_list.lua](examples/examples_list.lua).

The animations list, the timeline and the playback settings are filled from the animation data,
so nothing else has to be written for a new example.
