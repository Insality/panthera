# Getting Started

Quickly dive into creating animations with **Panthera Editor 2.0** using this straightforward guide.

# Table of Contents


- [Getting Started](#getting-started)
- [Important Notes](#important-notes)
- [Interface Overview](#interface-overview)
   * [Home Screen Interface](#home-screen-interface)
   * [Animation Editor Interface](#animation-editor-interface)
   * [Interface adjustments](#interface-adjustments)
- [Create an Animation Project from Defold File](#create-an-animation-project-from-defold-file)
- [Manual Create Animation Project](#manual-create-animation-project)
- [Create an Animation](#create-an-animation)
   * [Change Animation Duration](#change-animation-duration)
   * [Create a Tween Key](#create-a-tween-key)
   * [Animation Initial State](#animation-initial-state)
   * [Animation Preview](#animation-preview)
- [Export Animation Data](#export-animation-data)
   * [How to Find Animation File](#how-to-find-animation-file)
- [Working with Node Properties](#working-with-node-properties)
   * [Copy and Paste Properties](#copy-and-paste-properties)
   * [Discarding Changes](#discarding-changes)
   * [Set Empty or Default Value](#set-empty-or-default-value)
- [Working with Timeline Keys](#working-with-timeline-keys)
   * [Select and Modify Keys](#select-and-modify-keys)
   * [Copy and Paste Keys](#copy-and-paste-keys)
   * [Create Instant Timeline key](#create-instant-timeline-key)
   * [Animation Keys](#animation-keys)
   * [Overlapping Keys](#overlapping-keys)
- [Working with Events](#working-with-events)
   * [Event Keys](#event-keys)
   * [Event Keys with Duration](#event-keys-with-duration)
- [Working with Nested Animations](#working-with-nested-animations)
   * [Add Nested Animation](#add-nested-animation)
   * [Cyclic References](#cyclic-references)
   * [Template Animations](#template-animations)
- [Workflow Example](#workflow-example)
- [Adjust Gizmo Settings](#adjust-gizmo-settings)
   * [Scene Gizmo Settings](#scene-gizmo-settings)
   * [Timeline Gizmo Settings](#timeline-gizmo-settings)
- [Adjust Font Size](#adjust-font-size)
- [Using Hotkeys](#using-hotkeys)

# Important Notes

Here are some fast helpful tips and reminders for using Panthera Editor:

- Usually you should create animation over your existing GUI or Collection layout directly from the Defold Editor.
- To create animation right click on the `.gui` or `.collection` file in the Defold Editor and select `[Panthera] Create Panthera Animation`.
- Switch to **Animation mode** and start creating animations.
- Pan the editor view by holding `Ctrl` or `Alt` and dragging the view.
- Property names in 🔸 orange indicate unapplied changes. ![changed_property](/docs_editor/media/icon_changed_property.png)
- Click on **🔸 Orange Property Name** to apply changes.
- Unapplied changes will not be animated in the preview until they are saved or discarded.
- Right Click on the **Property Name** to show the context menu (contains Discard Changes).
- Two buttons in the Properties panel: ![icon_commit](/docs_editor/media/icon_commit_all.png) **"Commit All Changes"** and ![icon_reset](/docs_editor/media/icon_reset_all.png) **"Reset All Changes"**.
- Node names in 🔸 orange indicate nodes with unapplied changes.
- Node names in **bold** indicate nodes with timeline keys.
- Animation names in **bold** indicate animations with timeline keys.
- Animations can contains timeline keys _(select the animation in the Animations panel to view them)_.
- Select timeline keys to edit them.
- Use the 🔸 **Gizmo** to move and stretch selected timeline keys.
- Move keys by dragging the 🔸 square at the middle of the selection.
- Animation timeline keys can start other animations (don't cycle them! ;) ).
- Keep your animation files under version control to avoid losing your work.
- Hit `Ctrl` + `S` to save the project file. Do it often and use Version Control to avoid losing your work.
- Toggle Editor Gizmo visible state with `W` key.

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


## Change Animation Duration

To change the animation duration, follow these steps:

1. Select the animation in the Animations panel.
2. Change the duration in the Properties panel.

If animation time is decreasing and some timeline keys should be affected, the all timeline keys will be resized to fit the new animation duration.


## Create a Tween Key

To create a new animation key, follow these steps:

1. Select the node in the scene.
2. Change the node properties in the Properties panel or on Editor View.
3. Left Click on the orange property name to create a key at the current time.
4. Move the timeline key slider to adjust the animation time.

All created keys will be displayed and selected in the Timeline panel.

> Node: You can commit all the changes in the Properties panel by pressing `Shift` + `Enter`.


## Animation Initial State

https://github.com/Insality/panthera/assets/3294627/d9654d70-d82a-4b47-9e6a-b3b6c903333b

The animation's initial state by default is the layout state. However, you can choose a different animation to set as the initial state via the Properties panel. In this case, the chosen animation's end state will be used as the initial state.

1. Select the animation in the Animations panel.
2. Choose the initial state animation in the Properties panel.

To reset the initial state, set the initial state animation to `Initial Layout`.

## Animation Preview

You can adjust the animation preview speed and zoom in the Timeline panel. These settings are only for preview and will not be exported.


# Export Animation Data

https://github.com/Insality/panthera/assets/3294627/867e4116-2015-4de8-ad3b-b464bbdca50a

Panthera Editor used a Lua or JSON file for animation data. This file serves a dual purpose: it is used directly within the editor for creating and modifying animations, and it is also read by the runtime to display the animations. There is no separate export process; the runtime uses the same file that the editor uses.

## How to Find Animation File

1. Right click on the project in the Projects tab or in the Project List.
2. Select "Show in Desktop".

The file will be opened in the file explorer window.


You can import the Defold GUI/Collection/GO layout to the Panthera Editor. The animation file should be placed inside your Defold project folder to correct reloading in the future (it uses relative path's from `game.project` file).

1. Open animation project.
2. Click on the plus icon in the Nodes panel.
3. Select "Bind Defold File".
4. Choose the `.gui` file from your Defold project.


# Working with Node Properties

https://github.com/Insality/panthera/assets/3294627/2e4483c1-004c-4736-a70a-a29e8ae5f4df

## Copy and Paste Properties

To copy and paste node properties, follow these steps:

1. Select the node in the scene.
2. Right click on the property name in the Properties panel.
3. Select "Copy". The copy buffer is stored per property name.
4. Select another node.
5. Right click on the same property name in the Properties panel.
6. Select "Paste".


## Discarding Changes

To discard changes in the Properties panel, follow these steps:

1. Select the node in the scene.
2. Right click on the property name in the Properties panel.
3. Select "Discard Changes".

> Note: You can use "Reset all" button in the Properties panel to reset all the properties to the initial state. If there are no changed properties, the node will be reset to the initial state.

## Set Empty or Default Value

To set the empty or default value for the property, follow these steps:

1. Right click on the property name in the Properties panel.
2. Select "Set Default".

# Working with Timeline Keys

https://github.com/Insality/panthera/assets/3294627/6f026870-1a44-49f5-8612-c54bb79590f2

## Select and Modify Keys

You can select and modify keys in the Timeline panel.

1. Select the keys in the Timeline panel.
2. Drag the square at the middle of the selection to move the keys.
3. Drag the corner of the selection to scale the keys.
4. Press Delete button to remove the keys.

## Copy and Paste Keys

You can copy and paste animation keys across nodes and projects.

1. Select the keys in the Timeline panel.
2. Press `Ctrl` + `C` to copy the keys.
3. Select another node or animation.
4. Press `Ctrl` + `V` to paste the keys.

The timeline keys will be paste at the current time. The keys will be pasted with the same time offset as they were copied.

## Create Instant Timeline key

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

# Working with Events

https://github.com/Insality/panthera/assets/3294627/2e1bbf3a-7882-400e-bf03-125845df003d

Events is a type of key that can be used to trigger custom actions in the Panthera Runtime. The events can be added to the timeline keys for specific nodes or animations.

## Event Keys

To add an event key, follow these steps:

1. Select the node or animation in the scene.
2. Press "Add Event" button in the Properties panel.
3. Adjust the event properties in the Timeline Properties panel.

## Event Keys with Duration

The event keys can have a duration. The event will be triggered at the start of the key and will be stopped at the end of the key. This type of event has a start and end value and easing. The event callback will be called for each frame in update loop for the key duration.

1. Create a new event key.
2. Set the duration greated than 0 in the Timeline Properties panel.


# Working with Nested Animations

https://github.com/Insality/panthera/assets/3294627/7b31c66e-ed65-4df9-b4e0-3f43f55cba5f

## Add Nested Animation

You can add a nested animation to the scene. Nested animations can be created in the animation timeline.

1. Select the animation in the Animations panel.
2. Select the animation in dropdown menu "Play Animation"
3. Adjust the animation key in the Timeline properties panel.

## Cyclic References

In the current version, the cyclic references are not protected. The cyclic references can cause the infinite loop in the animation playback. Be careful with it.

## Template Animations

The nested GUI template or Collections can have their own animations. If the `*_panthera.lua` file is placed in the same folder as the template or collection, it will be used as a template animation. If it's not created, you can double click on the template or collection to create it. To add animation from template, you should do next steps:

1. Select the template or collection in the scene.
2. In field `Play Animation` select the template animation.
3. Adjust the animation key in the Timeline properties panel.

> Note: Sometimes after creation of new template animation the template will be not visible in the scene. You can reopen the project to update the scene.

# Workflow Example

Here is a 4 minutes of making simple appear/disappear animations in Panthera Editor.

https://github.com/user-attachments/assets/18615ed3-3b09-47c3-a677-411ffa7d6600


# Adjust Gizmo Settings

https://github.com/Insality/panthera/assets/3294627/53b1de58-84eb-4a20-800f-c4bcf13cc78b

**Gizmo** - is a manipulator that allows you to move, rotate, and scale the nodes or timeline keys in the scene. You can adjust the gizmo settings in the Editor View.

## Scene Gizmo Settings

To adjust the scene gizmo settings, follow these steps:

1. Right Click on yellow square of the gizmo in the Editor View.
2. Adjust values: position step, rotation step, scale step and size step

These gizmo steps will be stored in the project file and used for all nodes in the scene.

## Timeline Gizmo Settings

To adjust the timeline gizmo settings, follow these steps:

1. Right Click on the "Play" button in the Timeline panel.
2. Adjust the Time Step value.

Time step is the minimal step point in timeline controls. The time step will be stored in the project file and used for all keys in the timeline.


# Adjust Font Size

![change_font_size](/docs_editor/media/change_font_size.png)

By default, Panthera uses a font with 40 font size. If you want to change the font size, you can click the `settings` button at bottom right corner of the editor and set your font size. This settings is stored in the project file and should be set for each project.

After changing the font size, you should restart the project to apply the changes.


# Using Hotkeys

Read the [Hotkeys](hotkeys.md) guide to learn about the helpful shortcuts available in the Panthera Editor.

