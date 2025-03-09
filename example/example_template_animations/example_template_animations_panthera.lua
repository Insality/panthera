return {
    data = {
        animations = {
            {
                animation_id = "default",
                animation_keys = {
                    {
                        duration = 0.48,
                        easing = "outsine",
                        end_value = 135,
                        key_type = "tween",
                        node_id = "circle",
                        property_id = "position_y",
                    },
                    {
                        duration = 1,
                        easing = "linear",
                        key_type = "animation",
                        node_id = "square_animation",
                        property_id = "default",
                    },
                    {
                        duration = 0.41,
                        easing = "outsine",
                        end_value = -190,
                        key_type = "tween",
                        node_id = "circle",
                        property_id = "position_y",
                        start_time = 0.48,
                        start_value = 135,
                    },
                    {
                        duration = 0.11,
                        easing = "outsine",
                        key_type = "tween",
                        node_id = "circle",
                        property_id = "position_y",
                        start_time = 0.89,
                        start_value = -190,
                    },
                },
                duration = 1,
                formatted_duration = "1.0",
            },
        },
        metadata = {
            fps = 60,
            gizmo_steps = {
            },
            gui_path = "/example/example_template_animations/example_template_animations.gui",
            layers = {
            },
            settings = {
                font_size = 30,
            },
            template_animation_paths = {
                square_animation = require("example.example_template_animations.templates.square_animation_panthera"),
            },
        },
        nodes = {
        },
    },
    format = "json",
    type = "animation_editor",
    version = 1,
}