/**
    Inui Render Pass

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inrndr.pass;
import inrndr.texture;
import inrndr.buffer;
import inrndr.shader;
import inmath;
import numem;
import sdl;

/**
    An object which records rendering commands for
    a render pass.
*/
abstract
class CommandBuffer : NuRefCounted {
private:
@nogc:
    RenderPassDescriptor desc_;

public:

    /**
        The render pass that was used to create the buffer.
    */
    final @property RenderPassDescriptor descriptor() => desc_;

    /**
        Base constructor used by a backend to create a command buffer.
    */
    this(RenderPassDescriptor desc) {
        this.desc_ = desc;
    }

    /**
        Sets the viewport for the render pass.
    */
    abstract void setViewport(rect value);

    /**
        Sets the scissor rectangle for the render pass.
    */
    abstract void setScissor(rect value);

    /**
        Sets the given texture to be active in the given
        texture slot.

        Params:
            texture =   The texture to activate on the given slot.
            slot =      The slot to activate it on
    */
    abstract void setTexture(Texture texture, uint slot);

    /**
        Sets the given buffer to be active in the given
        uniform buffer slot.

        Params:
            buffer =    The buffer to activate on the given slot.
            slot =      The slot to activate it on
    */
    abstract void setUniformBuffer(Buffer buffer, uint slot);

    /**
        Draws a vertex buffer.

        Params:
            vertices =      The vertex buffer.
            vertexCount =   The amount of vertices from the buffer to draw.
            vertexOffset =  The offset into the vertex buffer to start at.
    */
    abstract void drawTriangles(Buffer vertices, uint vertexCount, uint vertexOffset = 0);

    /**
        Draws vertex and element buffers.

        Params:
            vertices =      The vertex buffer.
            indices =       The index buffer.
            indexElemSize = The size of index elements in bytes.
            indexCount =    The amount of indices from the index buffer to draw.
            indexOffset =   The offset into the index buffer to start at.
            vertexOffset =  The offset into the vertex buffer to start at.
    */
    abstract void drawTriangles(Buffer vertices, Buffer indices, uint indexElemSize, uint indexCount, uint indexOffset = 0, uint vertexOffset = 0);
}

/**
    Descriptor used to create render passes.
*/
struct RenderPassDescriptor {

    /**
        Target textures
    */
    RenderTargetDescriptor[] targets;

    /**
        The vertex layout for the input vertex buffer.
    */
    VertexDescriptor vertexInput;

    /**
        The active shader for the render pass.
    */
    Shader shader;
}

/**
    Descriptor of a render target
*/
struct RenderTargetDescriptor {

    /**
        Texture target
    */
    Texture target;

    /**
        Whether to clear the render target.
    */
    bool clear = false;

    /**
        The clear color of the render target.
    */
    vec4 clearColor = vec4(0, 0, 0, 0);

    /**
        Whether blending is enabled.
    */
    bool blending = true;

    /**
        Blending source mode.
    */
    BlendMode srcBlendFactor = BlendMode.srcAlpha;

    /**
        Blending destination mode.
    */
    BlendMode dstBlendFactor = BlendMode.oneMinusSrcAlpha;
}

/**
    Format identifier for a vertex element.
*/
enum VertexFormat : uint {
    float1,
    float2,
    float3,
    float4,
    ubyte1,
    ubyte2,
    ubyte3,
    ubyte4,
}

struct VertexDescriptor {
    VertexAttributeDescriptor[] attributes;
    uint rate;
    uint stride;
}

struct VertexAttributeDescriptor {
    uint offset;
    VertexFormat format;
}