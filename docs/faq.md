
## The file '/tweener/tweener.lua' could not be found.

The **[Defold Tweener](https://github.com/Insality/defold-tweener)** library is missing. Add it to your project by following the instructions in the repository's README.

## Animation name highlighted in red

This issue can occur when the animation file is re-exported from Defold, and some nodes are no longer present in the project. To resolve this, you can either remove the timeline keys associated with the missing nodes or change the node_id to match the current node in the project.

This timeline key is error keys and should be removed or fixed.

## How to delete nodes

To delete a node, select it in the layout mode and press the delete icon in properties panel or `Ctrl (Cmd) + Backspace` keys on your keyboard.

## How to delete timeline keys

To delete a timeline key, select it in the timeline and press the delete icon in the timeline panel properties or `Delete` key on your keyboard.

## My node stops animating when I make changes

Probably the reason in changed properties in Animation Mode.

The Properties panel orange property names indicate that the property value is changed. It can't be animated with existing timeline keys. To continue you should commit (press left mouse button on the property name) or reset (press right mouse button on the property name -> select discard) the property value.

## How to setup initial property value in animation

To setup initial property value in animation you should create a timeline key with the property value you need at the start of the animation. The timeline key will have zero time and will be the first key in the timeline. Next timeline key also can be started from zero time.

## I drag the timeline slider and nothing happens

Sounds like a bug. You can press save on the project and reload the project. If the issue persists, please create an issue on the GitHub repository with the detailed description of the problem.

# Hotkeys is not working

Probably a some of modifiers keys are pressed in the system. Try to press `Ctrl`, `Alt`, `Shift` and `Cmd` keys on your keyboard to ensure it released by the system.

<!-- TODO: questions about size mode -->
<!-- TODO: hover hints are important -->
<!-- TODO: hotkey issue is important -->
