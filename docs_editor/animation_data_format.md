# Animation File Format

```proto
smessage data {
	string name = 1;
	repeated node nodes = 2;
	repeated animation animations = 3;
	animation_metadata metadata = 4;
}

message runtime_data {
	repeated node nodes = 1;
	repeated node selected_nodes = 2;
	string select_mode = 3;
	string editor_mode = 4;
	repeated animation selected_animations = 5;
	repeated animation_key selected_animation_keys = 6;
	repeated node hidden_nodes = 7;
	map<string, transform> runtime_world_transforms = 8;
	timeline_runtime timeline_runtime = 9;
}

message timeline_runtime {
	double current_animation_time = 1;
	bool is_playing = 2;
	bool is_loop_playing = 3;
	bool is_reverse_playing = 4;
	double play_speed = 5;
}

message transform {
	double position_x = 1;
	double position_y = 2;
	double position_z = 3;

	double rotation_x = 4;
	double rotation_y = 5;
	double rotation_z = 6;

	double scale_x = 7;
	double scale_y = 8;
	double scale_z = 9;

	double size_x = 10;
	double size_y = 11;
	double size_z = 12;

	double pivot_x = 13;
	double pivot_y = 14;
	double pivot_z = 15;
	string pivot = 16;

	string parent = 17;
}

message node {
	string node_id = 1;
	string parent = 2; // Parent node id
	string node_type = 3; // One of "box", "text", "pie", "template", "spine", "particlefx",

	bool enabled = 4;
	bool visible = 5;
	string layer = 6;
	bool inherit_alpha = 7;
	uint32 node_index = 8;

	// General
	double position_x = 9;
	double position_y = 10;
	double position_z = 11;

	double rotation_x = 12;
	double rotation_y = 13;
	double rotation_z = 14;

	double scale_x = 15;
	double scale_y = 16;
	double scale_z = 17;

	double size_x = 18;
	double size_y = 19;
	double size_z = 20;

	double slice9_top = 21;
	double slice9_bottom = 22;
	double slice9_left = 23;
	double slice9_right = 24;

	double color_r = 25;
	double color_g = 26;
	double color_b = 27;
	double color_a = 28;

	// Text Nodes
	string text = 29;
	string font = 30;
	double font_size = 31;
	bool line_break = 32;
	double text_leading = 33;
	double text_tracking = 34;

	double shadow_r = 35;
	double shadow_g = 36;
	double shadow_b = 37;
	double shadow_a = 38;

	double outline_r = 39;
	double outline_g = 40;
	double outline_b = 41;
	double outline_a = 42;

	// Images
	string texture = 43; // Format is {texture_name}/{image_name}. Example "game/character"
	string pivot = 44; // One of "pivot_center", "pivot_n", "pivot_ne", "pivot_e", "pivot_se", "pivot_s", "pivot_sw", "pivot_w", "pivot_nw"
	string blend_mode = 45; // One of "alpha", "add", "multiply", "screen"
	string size_mode = 46; // One of "auto", "manual"

	// Clipping
	string clipping_mode = 47; // One of "none", "stencil"
	bool clipping_visible = 48;
	bool clipping_inverted = 49;

	// Pie node
	string outer_bounds = 50;
	double inner_radius = 51;
	double perimeter_vertices = 52;
	double fill_angle = 53;

	// Template node
	string template = 54;
}

message animation {
	string animation_id = 1;
	double duration = 2; // In seconds
	string initial_state = 3; // The animation id to copy the initial state from
	repeated animation_key animation_keys = 4;
}

message animation_key {
	uint32 id = 1;
	string node_id = 2;
	string property_id = 3; // Property id to animate, example: "position_x", "rotation_z", "size_x", "color_r", "text"
	string key_type = 4; // One of "tween", "trigger", "event" or "animation"
	double start_value = 5;
	double end_value = 6;
	double start_time = 7;
	double duration = 8;
	string easing = 9; // One of "linear", "inbounce", "inoutquad", "outcirc", "outinquint", etc
	string start_data = 10;
	string data = 11;
	string event_id = 12;
}

message animation_metadata {
	string gui_path = 1;
	gizmo_steps gizmo_steps = 2;
	uint32 fps = 3;
}

message gizmo_steps {
	double position = 1;
	double scale = 2;
	double rotation = 3;
	double size = 4;
	double time = 5;
}
```
