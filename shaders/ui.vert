#version 450

layout(location = 0) in vec2 Position;
layout(location = 1) in vec2 UV;
layout(location = 2) in vec4 Color;

layout(location = 0) out vec2 Frag_UV;
layout(location = 1) out vec4 Frag_Color;

layout(set = 1, binding = 0) uniform Proj {
    mat4 ProjMtx;
};

void main() {
    Frag_UV = UV;
    Frag_Color = Color;
    gl_Position = ProjMtx * vec4(Position.xy,0,1);
}