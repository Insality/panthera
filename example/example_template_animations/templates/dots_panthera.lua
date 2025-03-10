return {
    data = {
        animations = {
            {
                animation_id = "default",
                animation_keys = {
                },
                duration = 1,
            },
            {
                animation_id = "flip",
                animation_keys = {
                    {
                        duration = 0.23,
                        easing = "outsine",
                        end_value = 45,
                        key_type = "tween",
                        node_id = "dot1",
                        property_id = "position_y",
                    },
                    {
                        duration = 1,
                        easing = "outcubic",
                        end_value = -70,
                        key_type = "tween",
                        node_id = "dot",
                        property_id = "position_x",
                    },
                    {
                        duration = 1,
                        easing = "outcubic",
                        key_type = "tween",
                        node_id = "dot2",
                        property_id = "position_x",
                        start_value = 70,
                    },
                    {
                        duration = 1,
                        easing = "outsine",
                        end_value = 70,
                        key_type = "tween",
                        node_id = "dot1",
                        property_id = "position_x",
                        start_value = -70,
                    },
                    {
                        duration = 0.77,
                        easing = "insine",
                        key_type = "tween",
                        node_id = "dot1",
                        property_id = "position_y",
                        start_time = 0.23,
                        start_value = 45,
                    },
                },
                duration = 1,
            },
        },
        metadata = {
            fps = 60,
            gizmo_steps = {
            },
            gui_path = "/example/example_template_animations/templates/dots.gui",
            layers = {
            },
            settings = {
                font_size = 30,
            },
            template_animation_paths = {
            },
        },
        nodes = {
        },
    },
    format = "json",
    type = "animation_editor",
    version = 1,
}