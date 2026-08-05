return {
    data = {
        animations = {
            {
                animation_id = "default",
                animation_keys = {
                    {
                        duration = 1,
                        easing = "outsine",
                        end_value = 1.6,
                        key_type = "tween",
                        node_id = "panthera#sprite",
                        property_id = "scale_x",
                        start_value = 1,
                    },
                    {
                        duration = 1,
                        easing = "outsine",
                        end_value = 1.6,
                        key_type = "tween",
                        node_id = "panthera#sprite",
                        property_id = "scale_y",
                        start_value = 1,
                    },
                    {
                        duration = 1,
                        easing = "outsine",
                        end_value = 1,
                        key_type = "tween",
                        node_id = "panthera#sprite",
                        property_id = "scale_x",
                        start_time = 1,
                        start_value = 1.6,
                    },
                    {
                        duration = 1,
                        easing = "outsine",
                        end_value = 1,
                        key_type = "tween",
                        node_id = "panthera#sprite",
                        property_id = "scale_y",
                        start_time = 1,
                        start_value = 1.6,
                    },
                },
                duration = 2,
            },
        },
        metadata = {
            fps = 60,
            gizmo_steps = {
            },
            layers = {
            },
            settings = {
                font_size = 40,
            },
            template_animation_paths = {
            },
        },
        nodes = {
            {
                node_id = "panthera",
                node_index = 1,
                node_type = "box",
            },
            {
                node_id = "panthera#sprite",
                node_index = 2,
                node_type = "box",
                parent = "panthera",
            },
        },
    },
    format = "json",
    type = "animation_editor",
    version = 1,
}
