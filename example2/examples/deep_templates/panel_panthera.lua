return {
    data = {
        animations = {
            {
                animation_id = "wake",
                animation_keys = {
                    {
                        duration = 1,
                        easing = "linear",
                        key_type = "animation",
                        node_id = "dots",
                        property_id = "bounce",
                    },
                    {
                        duration = 0.25,
                        easing = "incubic",
                        end_value = 40,
                        key_type = "tween",
                        node_id = "bar",
                        property_id = "size_x",
                        start_value = 340,
                    },
                    {
                        duration = 0.75,
                        easing = "outcubic",
                        end_value = 340,
                        key_type = "tween",
                        node_id = "bar",
                        property_id = "size_x",
                        start_time = 0.25,
                        start_value = 40,
                    },
                },
                duration = 1,
            },
            {
                animation_id = "flip",
                animation_keys = {
                    {
                        duration = 1,
                        easing = "linear",
                        key_type = "animation",
                        node_id = "dots",
                        property_id = "flip",
                    },
                    {
                        duration = 0.5,
                        easing = "outsine",
                        end_value = 4,
                        key_type = "tween",
                        node_id = "root",
                        property_id = "rotation_z",
                    },
                    {
                        duration = 0.5,
                        easing = "outelastic",
                        key_type = "tween",
                        node_id = "root",
                        property_id = "rotation_z",
                        start_time = 0.5,
                        start_value = 4,
                    },
                },
                duration = 1,
            },
        },
        metadata = {
            fps = 60,
            gizmo_steps = {
                time = 0.1,
            },
            gui_path = "example2/examples/deep_templates/panel.gui",
            layers = {
            },
            settings = {
                font_size = 30,
            },
            template_animation_paths = {
                dots = require("example2.examples.dots.dots_panthera"),
            },
        },
        nodes = {
        },
    },
    format = "json",
    type = "animation_editor",
    version = 1,
}
