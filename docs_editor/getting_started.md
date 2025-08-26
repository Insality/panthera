# Getting Started

Welcome to Panthera 2.0 Editor — a cross‑platform animation editor tightly integrated with [Defold](https://defold.com/). This guide walks you from installation to your first animation playing in‑game, then deepens into daily‑use workflows.

## Table of Contents

- [Requirements](#requirements)
- [Install](#install)
- [Quick start (10 minutes)](#quick-start-10-minutes)
- [Create a project from a Defold file](#create-a-project-from-a-defold-file)
- [Create your first animation](#create-your-first-animation)
  - [Change animation duration](#change-animation-duration)
  - [Create a tween key](#create-a-tween-key)
  - [Set an initial state](#set-an-initial-state)
  - [Preview speed and zoom](#preview-speed-and-zoom)
- [Use the animation in Defold (Runtime)](#use-the-animation-in-defold-runtime)
- [Working with node properties](#working-with-node-properties)
- [Working with timeline keys](#working-with-timeline-keys)
- [Events](#events)
- [Nested and Template animations](#nested-and-template-animations)
- [Interface overview](#interface-overview)
- [Tips and troubleshooting](#tips-and-troubleshooting)
- [Adjust gizmo settings](#adjust-gizmo-settings)
- [Adjust font size](#adjust-font-size)
- [Hotkeys](#using-hotkeys)

---

## Requirements

- Defold Editor installed
- Panthera 2.0 Editor (Windows/macOS/Linux)
- Optional: project uses [Defold Tweener](https://github.com/Insality/defold-tweener) and [Panthera Runtime](https://github.com/Insality/panthera) for in‑game playback

## Install

1. Download Panthera 2.0 Editor from the [Releases](https://github.com/Insality/panthera/releases) page.
2. Unzip and run the application for your OS.
3. Open your Defold project. Keep Panthera Editor running to use the Defold context‑menu actions.

> Tip: You can use Panthera standalone, but pairing it with the Defold Editor gives you one‑click open/create for animations.

## Quick start (10 minutes)

1. In Defold, right‑click a `.gui` or `.collection` → `[Panthera] Create Panthera Animation`.
2. Panthera opens, imports the layout, and creates a `*_panthera.lua` animation file next to your Defold file.
3. Switch to Animation mode → click “+” in Animations → name it `appear` → set Duration.
4. Select a node → change a property (e.g. `position.y`) → click the orange property name to create a key.
5. Move the time slider → change the property again → click the orange name to create the second key.
6. Press Space to preview. Save often (Ctrl/Cmd+S).
7. In Defold, play it using the Runtime:

```lua
-- GUI example
local panthera = require("panthera.panthera")
local animation = require("gui.my_gui_panthera")

function init(self)
    self.animation = panthera.create_gui(animation)
    panthera.play(self.animation, "appear", { is_loop = false })
end
```

```lua
-- Collection / GO example
local panthera = require("panthera.panthera")
local animation = require("entities.my_entity_panthera")

function init(self)
    self.animation = panthera.create_go(animation)
    panthera.play(self.animation, "appear", { is_loop = true })
end
```

> See the full [API Reference](https://github.com/Insality/panthera/blob/main/API_REFERENCE.md) for `panthera.create_gui`, `panthera.create_go`, and `panthera.play` options.

---

## Create a project from a Defold file

Right‑click a `.gui` or `.collection` in the Defold Editor → `[Panthera] Open Panthera Animation`.

https://github.com/Insality/panthera/assets/3294627/ed082b26-cfaf-4567-93ac-41d2169b2444

The layout is imported read‑only into the Editor View. The file state becomes “linked”. Reload from the project screen or via the “Reload Binded File” button.

https://github.com/user-attachments/assets/b39445d1-ebe8-4f02-ac54-418e952d9b84

To open an existing Lua/JSON Panthera animation from Defold, right‑click the animation file → `[Panthera] Edit Panthera Animation`.

https://github.com/user-attachments/assets/5e649807-f030-4c81-8264-a0e54191da2a

### Manual project creation

1. In Panthera Editor click “+” in the Projects tab → New Animation → choose a file
2. In Layout mode click “+” in Nodes panel → Bind Defold File → choose a `.gui`/`.collection`

## Create your first animation

https://github.com/Insality/panthera/assets/3294627/b31f4ba0-4989-485d-a05b-6a0888689fae

1. Switch to Animation mode
2. “+” in Animations → name it
3. Set duration in Properties
4. Select node → modify a property → click its orange name to create a key at the current time
5. Move the playhead and repeat to create the next key
6. Press Space to preview

# Interface Overview

Here is a quick overview of the Panthera Editor interface:

## Home Screen Interface

![overview_interface_home](/docs_editor/media/overview_interface_home.png)

> Welcome Page
---
Contains the information, latest news and quick access buttons to leave feedback and report issues

> Project list
---
List of all your projects. Here you can open, delete, or create a new project. Projects are sorted by the last modified date. After creation you can rename the project by `right click -> Rename`. This rename is not affecting the saved file name and can be used for better navigation.

The same for deleting projects: the source file will be not deleted, only the project info inside the editor will be deleted.

To create first animation project, click on the "Plus" button and select "New Animation".

> Project Tabs
---
All currently opened projects are displayed here. You can switch between them by clicking on the tab.

> Animation Information
---
Contains the information about the selected animation. It contains a list of all the animations in the project and all affected nodes.


## Animation Editor Interface

![overview_interface_animation_editor](/docs_editor/media/overview_interface_animation_editor.png)

> Nodes Panel
---
Contains all the nodes in the scene. Contains all the nodes from the imported layout.

> Editor View
---
The main view where you can see the scene and animations. You can pan the view by holding `Ctrl` or `Alt` and dragging the view. Use the mouse wheel to zoom in and out. Select nodes by clicking on them. Use `Shift + Click` to add or remove nodes from the selection.

> Properties Panel
---
Displays the properties of the selected node. You can change the properties here.

![overview_interface_timeline](/docs_editor/media/overview_interface_timeline.png)

> Animations Panel
---
Appears only in Animation mode. Contains all the animations in the scene. You can add new animations here.

> Timeline Panel
---
Appears only in Animation mode. Contains the all the keys of the selected animation or nodes. You can adjust the keys here. The speed and zoom sliders used to preview the animation only and will be not exported.

> Timeline Properties Panel
---
Appears only in Animation mode. Contains the properties of the selected key. You can change the properties here.

## Interface adjustments

You can change the UI scale by pressing `Ctrl` + `Shift` + `-` to scale down and `Ctrl` + `Shift` + `+` to scale up.

https://github.com/user-attachments/assets/f6f94120-56c1-4abb-a5fc-acdedbe6127c

You can adjust the width of the Node panel and Timeline panel by dragging the splitter between them.

https://github.com/user-attachments/assets/ef0e9d38-eb39-4001-83de-5bdbaf9cc47d

# Create an Animation Project from Defold File

To open project to edit, right click on the `.gui` or `.collection` file in the Defold Editor and select `[Panthera] Open Panthera Animation`. The Panthera 2.0 Editor should be started before using the scripts. It will create a new lua animation file nearby with a `_panthera` postfix. If file already exists, it will be opened instead.

https://github.com/Insality/panthera/assets/3294627/ed082b26-cfaf-4567-93ac-41d2169b2444

The layout will be imported and displayed in the Editor View. The file state is changed to linked. The file will be reloaded automatically when the project is opened, or manually by clicking the "Reload Binded File" button.

The layout nodes can't be modified. But you can animate them. Nodes layout data will be not stored in the animation file. Only the animation data will be stored.

https://github.com/user-attachments/assets/b39445d1-ebe8-4f02-ac54-418e952d9b84

To open Panthera animation (both in json or lua formars) from Defold Editor, press right click on the Panthera animation file and select `[Panthera] Edit Panthera Animation`. The Panthera Editor will be opened with the selected animation project.

https://github.com/user-attachments/assets/5e649807-f030-4c81-8264-a0e54191da2a

# Manual Create Animation Project

You can open the project manually from Panthera Editor:

1. Click on plus icon in the Projects tab.
2. Select "New Animation".
3. Select the project file.
4. In project, in layout mode, click on plus icon in the Nodes panel.
5. Select "Bind Defold File".
6. Choose the `.gui` or `.collection` file to import.


# Create an Animation

https://github.com/Insality/panthera/assets/3294627/b31f4ba0-4989-485d-a05b-6a0888689fae

To create an animation, follow these steps:

1. Click on the "Animation" button in Editor Panel to switch to Animation mode.
2. Click on the plus icon in the Animations panel.
3. Enter the animation name.
4. Set the animation duration in Properties panel.

The animation will be created and displayed in the Animations panel. Press `Space` button to play the animation. But now it's empty. Let's add some keys.


### Change animation duration

To change the animation duration, follow these steps:

1. Select the animation in the Animations panel.
2. Change the duration in the Properties panel.

If animation time is decreasing and some timeline keys should be affected, the all timeline keys will be resized to fit the new animation duration.


### Create a tween key

To create a new animation key, follow these steps:

1. Select the node in the scene.
2. Change the node properties in the Properties panel or on Editor View.
3. Left Click on the orange property name to create a key at the current time.
4. Move the timeline key slider to adjust the animation time.

All created keys will be displayed and selected in the Timeline panel.

> Node: You can commit all the changes in the Properties panel by pressing `Shift` + `Enter`.


### Set an initial state

https://github.com/Insality/panthera/assets/3294627/d9654d70-d82a-4b47-9e6a-b3b6c903333b

The animation's initial state by default is the layout state. However, you can choose a different animation to set as the initial state via the Properties panel. In this case, the chosen animation's end state will be used as the initial state.

1. Select the animation in the Animations panel.
2. Choose the initial state animation in the Properties panel.

To reset the initial state, set the initial state animation to `Initial Layout`.

### Preview speed and zoom

You can adjust the animation preview speed and zoom in the Timeline panel. These settings are only for preview and will not be exported.


## Use the animation in Defold (Runtime)

https://github.com/Insality/panthera/assets/3294627/867e4116-2015-4de8-ad3b-b464bbdca50a

Panthera stores animation data as Lua or JSON. The same file is used by the editor and the runtime — there is no separate export step.

### Where is my animation file?

1. Right click on the project in the Projects tab or in the Project List.
2. Select "Show in Desktop".

The file will be opened in the file explorer window.


Place animation files inside your Defold project so the editor can auto‑reload them (paths are relative to `game.project`).

1. Open animation project.
2. Click on the plus icon in the Nodes panel.
3. Select "Bind Defold File".
4. Choose the `.gui` file from your Defold project.


## Working with node properties

https://github.com/Insality/panthera/assets/3294627/2e4483c1-004c-4736-a70a-a29e8ae5f4df

### Copy and paste properties

To copy and paste node properties, follow these steps:

1. Select the node in the scene.
2. Right click on the property name in the Properties panel.
3. Select "Copy". The copy buffer is stored per property name.
4. Select another node.
5. Right click on the same property name in the Properties panel.
6. Select "Paste".


### Discard changes

To discard changes in the Properties panel, follow these steps:

1. Select the node in the scene.
2. Right click on the property name in the Properties panel.
3. Select "Discard Changes".

> Note: You can use "Reset all" button in the Properties panel to reset all the properties to the initial state. If there are no changed properties, the node will be reset to the initial state.

### Set empty/default value

To set the empty or default value for the property, follow these steps:

1. Right click on the property name in the Properties panel.
2. Select "Set Default".

## Working with timeline keys

https://github.com/Insality/panthera/assets/3294627/6f026870-1a44-49f5-8612-c54bb79590f2

### Select and modify keys

You can select and modify keys in the Timeline panel.

1. Select the keys in the Timeline panel.
2. Drag the square at the middle of the selection to move the keys.
3. Drag the corner of the selection to scale the keys.
4. Press Delete button to remove the keys.

### Copy and paste keys

You can copy and paste animation keys across nodes and projects.

1. Select the keys in the Timeline panel.
2. Press `Ctrl` + `C` to copy the keys.
3. Select another node or animation.
4. Press `Ctrl` + `V` to paste the keys.

The timeline keys will be paste at the current time. The keys will be pasted with the same time offset as they were copied.

### Create an instant key

To create an instant timeline key (with zero duration), follow these steps:

1. Select the node in the scene.
2. Change the node properties in the Properties panel.
3. `Ctrl` + `Left Click` on the orange property name in the Properties panel.

> Note: the `ctrl` will also works with "Commit All" button in the Properties panel.

> Note: You also can set manually a duration to 0 of new created keys to make them instant.

## Animation Keys

The animation itself can have keys. The keys will be displayed in the Timeline panel. You can adjust the keys in the Timeline panel. To view the animation keys, select the animation in the Animations panel.

## Overlapping Keys

The overlapping keys is valid. The previous key will be applied until the next key. The keys with zero duration will be applied instantly.

## Events

https://github.com/Insality/panthera/assets/3294627/2e1bbf3a-7882-400e-bf03-125845df003d

Events is a type of key that can be used to trigger custom actions in the Panthera Runtime. The events can be added to the timeline keys for specific nodes or animations.

### Event keys

To add an event key, follow these steps:

1. Select the node or animation in the scene.
2. Press "Add Event" button in the Properties panel.
3. Adjust the event properties in the Timeline Properties panel.

### Event keys with duration

The event keys can have a duration. The event will be triggered at the start of the key and will be stopped at the end of the key. This type of event has a start and end value and easing. The event callback will be called for each frame in update loop for the key duration.

1. Create a new event key.
2. Set the duration greated than 0 in the Timeline Properties panel.


## Nested and Template animations

https://github.com/Insality/panthera/assets/3294627/7b31c66e-ed65-4df9-b4e0-3f43f55cba5f

### Add a nested animation

You can add a nested animation to the scene. Nested animations can be created in the animation timeline.

1. Select the animation in the Animations panel.
2. Select the animation in dropdown menu "Play Animation"
3. Adjust the animation key in the Timeline properties panel.

### Cyclic references

In the current version, the cyclic references are not protected. The cyclic references can cause the infinite loop in the animation playback. Be careful with it.

### Template animations

The nested GUI template or Collections can have their own animations. If the `*_panthera.lua` file is placed in the same folder as the template or collection, it will be used as a template animation. If it's not created, you can double click on the template or collection to create it. To add animation from template, you should do next steps:

1. Select the template or collection in the scene.
2. In field `Play Animation` select the template animation.
3. Adjust the animation key in the Timeline properties panel.

> Note: Sometimes after creation of new template animation the template will be not visible in the scene. You can reopen the project to update the scene.

## Workflow example

Here is a 4 minutes of making simple appear/disappear animations in Panthera Editor.

https://github.com/user-attachments/assets/18615ed3-3b09-47c3-a677-411ffa7d6600


## Adjust gizmo settings

https://github.com/Insality/panthera/assets/3294627/53b1de58-84eb-4a20-800f-c4bcf13cc78b

**Gizmo** - is a manipulator that allows you to move, rotate, and scale the nodes or timeline keys in the scene. You can adjust the gizmo settings in the Editor View.

### Scene gizmo settings

To adjust the scene gizmo settings, follow these steps:

1. Right Click on yellow square of the gizmo in the Editor View.
2. Adjust values: position step, rotation step, scale step and size step

These gizmo steps will be stored in the project file and used for all nodes in the scene.

### Timeline gizmo settings

To adjust the timeline gizmo settings, follow these steps:

1. Right Click on the "Play" button in the Timeline panel.
2. Adjust the Time Step value.

Time step is the minimal step point in timeline controls. The time step will be stored in the project file and used for all keys in the timeline.


## Adjust font size

![change_font_size](/docs_editor/media/change_font_size.png)

By default, Panthera uses a font with 40 font size. If you want to change the font size, you can click the `settings` button at bottom right corner of the editor and set your font size. This settings is stored in the project file and should be set for each project.

After changing the font size, you should restart the project to apply the changes.


## Using Hotkeys

Read the [Hotkeys](hotkeys.md) guide to learn the most useful shortcuts.

---

## Interface overview

Here is a quick overview of the Panthera Editor interface:

### Home Screen Interface

![overview_interface_home](/docs_editor/media/overview_interface_home.png)

> Welcome Page — news and quick access links
>
> Project list — open, delete, or create new projects (sorted by last modified)
>
> Project Tabs — switch between open projects
>
> Animation Information — animations list and affected nodes

### Animation Editor Interface

![overview_interface_animation_editor](/docs_editor/media/overview_interface_animation_editor.png)

![overview_interface_timeline](/docs_editor/media/overview_interface_timeline.png)

> Nodes Panel — all nodes from the imported layout
>
> Editor View — pan with Ctrl/Alt + drag; zoom with wheel; Shift+Click to multi‑select
>
> Properties Panel — edit selected node properties
>
> Animations Panel — appears in Animation mode
>
> Timeline & Timeline Properties — keys editing and key properties

---

## Tips and troubleshooting

- Create animations from the Defold Editor for best workflow
- Orange property names = changed but not applied. Click to commit
- Use Commit/Reset all changes buttons in the Properties panel when needed
- Keep files under version control and save often (Ctrl/Cmd+S)
- Toggle Editor Gizmo with `W`
- See the [FAQ](../docs/faq.md) for common issues


