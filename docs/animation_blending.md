### Animation Blending

Panthera Runtime for Defold supports animation blending, enabling multiple animations to run simultaneously on the same entity. This feature is akin to using multiple tracks in traditional animation software, where each track can control different sets of properties or parts of the model independently.


#### How It Works

To achieve animation blending, you need to create separate animation states for each animation you wish to blend. These states act as individual tracks, allowing each animation to run concurrently without interfering with each other, provided they animate different properties or nodes.

**Key Consideration**: Ensure that the node properties animated by these concurrent states do not overlap. Overlapping animations on the same property within the same node will result in conflicts, with one animation overriding the other.


#### Implementation Steps

1. **Create Multiple Animation States**: For each animation you want to blend, create a separate animation state using either `panthera.create_go` or `panthera.create_gui`, depending on whether you are animating a game object or a GUI node.

2. **Play Animations Simultaneously**: Start each animation using `panthera.play`, specifying the individual animation state and desired playback options. As long as these animations target different properties or nodes, they will blend seamlessly.


#### Example

```lua
local panthera = require("panthera.panthera")

function init(self)
    -- Create two separate animation states for blending
    self.character_animation = panthera.create_go("/animations/character.json")
    self.character_details_animation = panthera.clone_state(self.character_animation)

    -- Start both animations to run at the same time
    panthera.play(self.character_animation, "walk", { is_loop = true })
    panthera.play(self.character_details_animation, "eyes", { is_loop = true })
end
```

In this example, the character can walk and wave simultaneously because the `walk` and `arm_wave` animations affect different parts of the character or different properties. This method provides a powerful tool for creating complex, layered animations that enhance the visual fidelity and dynamism of your game.


#### Tips for Effective Animation Blending

- **Plan Your Animations**: Ensure animations meant to be blended do not compete for the same properties. Design your animations with blending in mind.
- **Use Blending for Complexity**: Combine simple animations to create complex behaviors. This not only saves time but also keeps your animation workflow organized.
- **Test Blending**: Experiment with different combinations of animations to find blends that work best for your game's aesthetics and gameplay needs.

Animation blending is a versatile technique that, when used correctly, can significantly elevate the player's visual experience in your Defold games.
