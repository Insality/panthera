--[[
  Generated with github.com/astrochili/defold-annotations
  Defold 1.8.1

  Known classes and aliases used in the Defold API
--]]

---@diagnostic disable: lowercase-global
---@diagnostic disable: missing-return
---@diagnostic disable: duplicate-doc-param
---@diagnostic disable: duplicate-set-field

---@class matrix4
---@field c0 vector4
---@field c1 vector4
---@field c2 vector4
---@field c3 vector4
---@field m00 number
---@field m01 number
---@field m02 number
---@field m03 number
---@field m10 number
---@field m11 number
---@field m12 number
---@field m13 number
---@field m20 number
---@field m21 number
---@field m22 number
---@field m23 number
---@field m30 number
---@field m31 number
---@field m32 number
---@field m33 number

---@class on_input.action
---@field dx number|nil The change in x value of a pointer device, if present.
---@field dy number|nil The change in y value of a pointer device, if present.
---@field gamepad integer|nil The change in screen space y value of a pointer device, if present.
---@field pressed boolean|nil If the input was pressed this frame. This is not present for mouse movement.
---@field released boolean|nil If the input was released this frame. This is not present for mouse movement.
---@field repeated boolean|nil If the input was repeated this frame. This is similar to how a key on a keyboard is repeated when you hold it down. This is not present for mouse movement.
---@field screen_dx number|nil The change in screen space x value of a pointer device, if present.
---@field screen_dy number|nil The index of the gamepad device that provided the input.
---@field screen_x number|nil The screen space x value of a pointer device, if present.
---@field screen_y number|nil The screen space y value of a pointer device, if present.
---@field touch [on_input.touch]|nil List of touch input, one element per finger, if present.
---@field value number|nil The amount of input given by the user. This is usually 1 for buttons and 0-1 for analogue inputs. This is not present for mouse movement.
---@field x number|nil The x value of a pointer device, if present.
---@field y number|nil The y value of a pointer device, if present.

---@class on_input.touch
---@field acc_x number|nil Accelerometer x value (if present).
---@field acc_y number|nil Accelerometer y value (if present).
---@field acc_z number|nil Accelerometer z value (if present).
---@field dx number The change in x value.
---@field dy number The change in y value.
---@field id number A number identifying the touch input during its duration.
---@field pressed boolean True if the finger was pressed this frame.
---@field released boolean True if the finger was released this frame.
---@field tap_count integer Number of taps, one for single, two for double-tap, etc
---@field x number The x touch location.
---@field y number The y touch location.

---@class physics.raycast_response
---@field fraction number The fraction of the hit measured along the ray, where 0 is the start of the ray and 1 is the end
---@field group hash The collision group of the hit collision object as a hashed name
---@field id hash The instance id of the hit collision object
---@field normal vector3 The normal of the surface of the collision object where it was hit
---@field position vector3 The world position of the hit
---@field request_id number The id supplied when the ray cast was requested

---@class resource.animation
---@field flip_horizontal boolean|nil Optional flip the animation horizontally, the default value is false
---@field flip_vertical boolean|nil Optional flip the animation vertically, the default value is false
---@field fps integer|nil Optional fps of the animation, the default value is 30
---@field frame_end integer Index to the last geometry of the animation (non-inclusive). Indices are lua based and must be in the range of 1 .. in atlas.
---@field frame_start integer Index to the first geometry of the animation. Indices are lua based and must be in the range of 1 .. in atlas.
---@field height integer The height of the animation
---@field id string The id of the animation, used in e.g sprite.play_animation
---@field playback constant|nil Optional playback mode of the animation, the default value is go.PLAYBACK_ONCE_FORWARD
---@field width integer The width of the animation

---@class resource.atlas
---@field animations resource.animation[] A list of the animations in the atlas
---@field geometries resource.geometry[] A list of the geometries that should map to the texture data
---@field texture string|hash The path to the texture resource, e.g "/main/my_texture.texturec"

---@class resource.geometry
---@field id string The name of the geometry. Used when matching animations between multiple atlases
---@field indices number[] A list of the indices of the geometry in the form { i0, i1, i2, ..., in }. Each tripe in the list represents a triangle.
---@field uvs number[] A list of the uv coordinates in texture space of the geometry in the form of { u0, v0, u1, v1, ..., un, vn }
---@field vertices number[] A list of the vertices in texture space of the geometry in the form { px0, py0, px1, py1, ..., pxn, pyn }

---@class socket.dns
socket.dns = {}

---@class url
---@field fragment hash
---@field path hash
---@field socket hash

---@class vector3
---@field x number
---@field y number
---@field z number
---@operator add(vector3): vector3
---@operator mul(number): vector3
---@operator sub(vector3): vector3
---@operator unm: vector3

---@class vector4
---@field w number
---@field x number
---@field y number
---@field z number
---@operator add(vector4): vector4
---@operator mul(number): vector4
---@operator sub(vector4): vector4
---@operator unm: vector4

---@alias array table
---@alias b2Body userdata
---@alias b2BodyType number
---@alias b2World userdata
---@alias bool boolean
---@alias buffer_data userdata
---@alias buffer_stream userdata
---@alias constant userdata
---@alias constant_buffer userdata
---@alias float number
---@alias hash userdata
---@alias node userdata
---@alias quaternion vector4
---@alias render_predicate userdata
---@alias render_target userdata
---@alias resource_data userdata
---@alias resource_handle number|userdata
---@alias socket_client userdata
---@alias socket_master userdata
---@alias socket_unconnected userdata