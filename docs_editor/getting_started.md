# Getting Started

Quickly dive into creating animations with **Panthera Editor 2.0** using this straightforward guide.

# Table of Contents

- [Getting Started](#getting-started)
- [Important Notes](#important-notes)
- [Interface Overview](#interface-overview)
   * [Home Screen Interface](#home-screen-interface)
   * [Animation Editor Interface](#animation-editor-interface)
   * [Atlas Editor Interface](#atlas-editor-interface)
- [Create a New Project](#create-a-new-project)
- [Create a Scene Layout](#create-a-scene-layout)
   * [Add a Box Node](#add-a-box-node)
   * [Add a Text Node](#add-a-text-node)
- [Import Image Assets](#import-image-assets)
   * [Import Images from Image Picker](#import-images-from-image-picker)
   * [Bind Defold Atlas](#bind-defold-atlas)
- [Create an Animation](#create-an-animation)
   * [Change Animation Duration](#change-animation-duration)
   * [Create a Tween Key](#create-a-tween-key)
   * [Animation Initial State](#animation-initial-state)
   * [Animation Preview](#animation-preview)
- [Export Animation Data](#export-animation-data)
   * [How to Find Animation File](#how-to-find-animation-file)
- [Import Defold GUI Layout](#import-defold-gui-layout)
- [Working with Node Properties](#working-with-node-properties)
   * [Copy and Paste Properties](#copy-and-paste-properties)
   * [Discarding Changes](#discarding-changes)
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
- [Adjust Gizmo Settings](#adjust-gizmo-settings)
   * [Scene Gizmo Settings](#scene-gizmo-settings)
   * [Timeline Gizmo Settings](#timeline-gizmo-settings)
- [Adjust Font Size](#adjust-font-size)
- [Using Hotkeys](#using-hotkeys)

# Important Notes

Here are some fast helpful tips and reminders for using Panthera Editor:

- To create animation you have to create a layout with nodes in **Layout mode** (or export GUI layout from **[Defold](https://defold.com/)** project).
- Then layout created, you can switch to **Animation mode** and start making animations.
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
- Hit `Ctrl` + `S` to save the project file.
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
List of all your projects. Here you can open, delete, or create a new project. Projects are sorted by the last modified date. After creation you can rename the project by right click -> Rename. This rename is not affecting the saved file name and can be used for better navigation.

> Project Tabs
---
All currently opened projects are displayed here. You can switch between them by clicking on the tab.


## Animation Editor Interface

![overview_interface_animation_editor](/docs_editor/media/overview_interface_animation_editor.png)

> Nodes Panel
---
Contains all the nodes in the scene. You can add new nodes here in Layout Mode.

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

## Atlas Editor Interface

![overview_interface_atlas](/docs_editor/media/overview_interface_atlas.png)

> Editor View
---
The main view where you can see the atlas. You can pan the view by holding `Ctrl` or `Alt` and dragging the view. Use the mouse wheel to zoom in and out.

> Properties Panel
---
Displays the properties of the selected node. You can view the properties here. Only `image_id` property is editable.

> Images List
---
Contains all the images in the atlas. You can add new images here.


# Create a New Project

https://github.com/Insality/panthera/assets/3294627/cf59240b-2279-4791-843f-3ea6ebcbc813

To create a new project, follow these steps:

1. Click on the "New Project" button on the home screen.
2. Choose the project type: "New Animation" or "New Atlas".
3. Select the location where you want to save the project file.
4. Click "Save".

The project will be created and opened in the Panthera Editor.


# Create a Scene Layout

https://github.com/Insality/panthera/assets/3294627/cb3115ab-e43f-44f6-abb2-c4df2d1b55b4

You can create a scene layout by adding nodes to the scene. Here's several ways to add nodes:


## Add a Box Node

1. Click on plus icon in the Nodes panel.
2. Select "Add Box Node".
3. Enter the node name.

The node will be added inside as a child of the selected node.

## Add a Text Node

1. Click on plus icon in the Nodes panel.
2. Select "Add Text Node".
3. Enter the node name.

The node will be added inside as a child of the selected node. The font can't be changed in the current version. The font size is `40` px at default scale.


# Import Image Assets

https://github.com/Insality/panthera/assets/3294627/9d956f0a-b62d-4132-bbce-cf05b818ebb9

To import image assets, follow these steps:

1. Create an Atlas project.
2. Click on plus icon in the Images panel.
3. Select "Add Images".
4. Choose the PNG files you want to import.


## Import Images from Image Picker

You can add images from the Image Picker in Animation Editor scene.

1. Select the node in the scene.
2. Click on the "Image" property in the Properties panel.
3. Select required atlas project.
4. Click on the plus icon.
5. Choose the image from the Image Picker.


## Bind Defold Atlas

https://github.com/Insality/panthera/assets/3294627/c7b7e0a8-91bf-42be-b15b-3c13041a168a

You can bind the Defold atlas to the Atlas project. All images from the Defold atlas will be imported to the Atlas project. The atlas project file should be placed inside your Defold project folder.

1. Click on plus icon in the Images panel.
2. Select "Bind Defold Atlas".
3. Choose the Defold atlas file.


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


## Create a Tween Key

To create a new animation key, follow these steps:

1. Select the node in the scene.
2. Change the node properties in the Properties panel or on Editor View.
3. Left Click on the orange property name to create a key at the current time.
4. Move the timeline slider to adjust the animation time.

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

<!-- File used in Panthera editor is the same for runtime -->

Panthera Editor used a JSON file for animation data. This file serves a dual purpose: it is used directly within the editor for creating and modifying animations, and it is also read by the runtime to display the animations. There is no separate export process; the runtime uses the same JSON file that the editor uses.

## How to Find Animation File

1. Right click on the project in the Projects tab or in the Project List.
2. Select "Show in Desktop".

The file will be opened in the file explorer window.

# Import Defold GUI Layout
<!-- animation file should be placed inside your Defold Project folder -->

https://github.com/Insality/panthera/assets/3294627/ed082b26-cfaf-4567-93ac-41d2169b2444

You can import the Defold GUI layout to the Panthera Editor. The animation file should be placed inside your Defold project folder to correct reloading in the future.

1. Open animation project.
2. Click on the plus icon in the Nodes panel.
3. Select "Bind Defold File".
4. Choose the `.gui` file from your Defold project.

The GUI layout will be imported and displayed in the Editor View. The file state is changed to linked. The GUI will be reloaded automatically when the project is opened, or manually by clicking the "Reload Binded File" button.

The layout nodes can't be modified. But you can animate them. Nodes layout data will be not stored in the animation file. Only the animation data will be stored.


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

> Note: You can use "Reset all" button in the Properties panel to reset all the properties to the initial state. If there are no changed properties., the node will be reset to the initial state.

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


## Animation Keys

The animation itself can have keys. The keys will be displayed in the Timeline panel. You can adjust the keys in the Timeline panel. To view the animation keys, select the animation in the Animations panel.

## Overlapping Keys
<!--Keys when set scale at 0 at instantly run the animation key - valid-->

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

The event keys can have a duration. The event will be triggered at the start of the key and will be stopped at the end of the key. This type of event has a start and end value and easing. The event callback will be called for each frame in the key duration.

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

