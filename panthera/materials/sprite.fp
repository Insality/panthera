#version 140

in mediump vec2 var_texcoord0;

out vec4 out_fragColor;

uniform mediump sampler2D texture_sampler;
uniform fs_uniforms
{
    mediump vec4 color;
};

void main()
{
    // Pre-multiply alpha since all runtime textures already are
    mediump vec4 color_pm = vec4(color.xyz * color.w, color.w);
    out_fragColor = texture(texture_sampler, var_texcoord0.xy) * color_pm;
}
