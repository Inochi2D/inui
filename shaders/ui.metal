#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float4x4 projectionMatrix;
};

struct VertexIn {
    float2 position  [[attribute(0)]];
    float2 texCoords [[attribute(1)]];
    uchar4 color     [[attribute(2)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoords;
    float4 color;
};

vertex VertexOut vertex_main(VertexIn in                 [[stage_in]],
                             constant Uniforms &uniforms [[buffer(0)]]) {
    VertexOut out;
    out.position = uniforms.projectionMatrix * float4(in.position, 1, 1);
    out.texCoords = in.texCoords;
    out.color = float4(in.color) / float4(255.0);
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                             texture2d<float, access::sample> textureIn [[texture(0)]],
                             sampler samplerIn [[sampler(0)]]) {

    float4 texColor = textureIn.sample(samplerIn, in.texCoords);
    return in.color * texColor;
}