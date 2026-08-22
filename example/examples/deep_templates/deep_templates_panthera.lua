return {
    data = {
        animations = {
            {
                animation_id = "wake_both",
                animation_keys = {
                    {
                        duration = 1,
                        easing = "linear",
                        key_type = "animation",
                        node_id = "panel_top",
                        property_id = "wake",
                    },
                    {
                        duration = 1,
                        easing = "linear",
                        key_type = "animation",
                        node_id = "panel_bottom",
                        property_id = "wake",
                        start_time = 0.25,
                    },
                },
                duration = 1.25,
            },
            {
                animation_id = "flip_both",
                animation_keys = {
                    {
                        duration = 1,
                        easing = "linear",
                        key_type = "animation",
                        node_id = "panel_top",
                        property_id = "flip",
                    },
                    {
                        duration = 1,
                        easing = "linear",
                        key_type = "animation",
                        node_id = "panel_bottom",
                        property_id = "flip",
                        start_time = 0.2,
                    },
                },
                duration = 1.2,
            },
            {
                animation_id = "mixed",
                animation_keys = {
                    {
                        duration = 1,
                        easing = "linear",
                        key_type = "animation",
                        node_id = "panel_top",
                        property_id = "wake",
                    },
                    {
                        duration = 1,
                        easing = "linear",
                        key_type = "animation",
                        node_id = "panel_bottom",
                        property_id = "flip",
                        start_time = 0.3,
                    },
                    {
                        duration = 0.3,
                        easing = "outsine",
                        end_value = 0.2,
                        key_type = "tween",
                        node_id = "text_hint",
                        property_id = "color_a",
                        start_value = 1,
                    },
                    {
                        duration = 0.3,
                        easing = "insine",
                        end_value = 1,
                        key_type = "tween",
                        node_id = "text_hint",
                        property_id = "color_a",
                        start_time = 1,
                        start_value = 0.2,
                    },
                },
                duration = 1.3,
            },
        },
        metadata = {
            fps = 60,
            gizmo_steps = {
                time = 0.1,
            },
            gui_path = "example/examples/deep_templates/deep_templates.gui",
            layers = {
            },
            settings = {
                font_size = 30,
            },
            template_animation_paths = {
                panel_top = require("example.examples.deep_templates.panel_panthera"),
                panel_bottom = require("example.examples.deep_templates.panel_panthera"),
            },
        },
        nodes = {
        },
    },
    format = "json",
    type = "animation_editor",
    version = 1,
}
