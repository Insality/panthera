varying mediump vec2 var_texcoord0;
varying mediump vec4 var_color0;

uniform lowp sampler2D texture_sampler;

void main()
{
    // Pre-multiply alpha since all runtime textures already are
    lowp vec4 color_pm = vec4(var_color0.xyz * var_color0.w, var_color0.w);
    gl_FragColor = texture2D(texture_sampler, var_texcoord0.xy) * color_pm;
}
