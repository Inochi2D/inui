/**
    Inui Render Pass

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module gl.pass;
import gl.context;
import gl.texture;
import gl.buffer;
import gl.shader;
import inmath;
import numem;

public import inrndr.pass;

class GLCommandBuffer : CommandBuffer {
private:
@nogc:

public:

    this(RenderPassDescriptor desc) {
        super(desc);
    }

    override
    void setViewport(rect value) { }

    override
    void setScissor(rect value) { }

    override
    void setTexture(Texture texture, uint slot) { }

    override
    void setUniformBuffer(Buffer buffer, uint slot) { }

    override
    void drawTriangles(Buffer vertices, uint vertexCount, uint vertexOffset = 0) { }

    override
    void drawTriangles(Buffer vertices, Buffer indices, uint indexElemSize, uint indexCount, uint indexOffset = 0, uint vertexOffset = 0) { }
}