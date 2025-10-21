#version 450

layout(location = 0) in vec2 Frag_UV;
layout(location = 1) in vec4 Frag_Color;

layout(location = 0) out vec4 Out_Color;
layout(set = 1, binding = 0) uniform texture2D inTexture;
layout(set = 2, binding = 0) uniform sampler inSampler;

void main() {
    Out_Color = Frag_Color * texture(sampler2D(inTexture, inSampler), Frag_UV.st);
}