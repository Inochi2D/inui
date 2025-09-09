/**
    Renderer Render Encoder

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.render.renderencoder;
import inui.core.render.cmdbuffer;
import inui.core.render.pipeline;
import inui.core.render.gpucache;
import inui.core.render.device;
import inui.core.render.texture;
import inui.core.render.buffer;
import nulib;
import numem;
import sdl.gpu;
import sdl.pixels;
import sdl.rect;
import std.stdio;

/**
    Encodes rendering commands.
*/
class RenderCommandEncoder : CommandEncoder {
private:
@nogc:
    SDL_GPURenderPass* handle_;
    SDL_GPUGraphicsPipeline* pipeline;
    rect viewport_;
    recti scissor_;
    PipelineState state;

protected:
    this(CommandBuffer parent, RenderPassDescriptor desc) {
        super(parent);

        auto colorTargets = desc.colorAttachments.toSDLColorTargets();
        auto depthStencilTarget = desc.depthStencilAttachment.toSDLDepthStencilTargetInfo();
        this.handle_ = SDL_BeginGPURenderPass(parent.handle, colorTargets.ptr, colorTargets.length, &depthStencilTarget);
        nu_freea(colorTargets);
    }

public:

    /**
        The scissor rectangle.
    */
    @property recti scissor() => scissor_;
    @property void scissor(recti value) {
        this.scissor_ = value;
        SDL_SetGPUScissor(handle_, cast(SDL_Rect*)&scissor_);
    }

    /**
        The viewport rectangle.
    */
    @property rect viewport() => viewport_;
    @property void viewport(rect value) {
        SDL_GPUViewport vp = {
            x = value.x,
            y = value.y,
            w = value.width,
            h = value.height,
            min_depth = 0,
            max_depth = 1
        };
        SDL_SetGPUViewport(handle_, &vp);
        this.viewport_ = value;
    }

    /**
        Sets the currently active render pipeline.

        Params:
            pipeline = The pipeline to set.
    */
    void setRenderPipeline(RenderPipeline pipeline) {
        state.renderPipeline = pipeline;
        SDL_BindGPUGraphicsPipeline(
            handle_,        
            parent.device.pipelineCache.get(state)
        );
    }

    /**
        Sets a index buffer for subsequent draw calls.

        Params:
            buffer =    The buffer to bind.
            indexType = The type of elements stored in the index buffer.
    */
    void setIndexBuffer(Buffer buffer, IndexType indexType) {
        if (buffer.type != BufferType.index)
            return;

        SDL_GPUBufferBinding binding = {
            buffer = buffer.handle,
            offset = 0
        };
        SDL_BindGPUIndexBuffer(handle_, &binding, indexType);
    }

    /**
        Sets a vertex buffer for subsequent draw calls.

        Params:
            slot =      The slot to bind the buffer
            buffer =    The buffer to bind.
    */
    void setVertexBuffer(uint slot, Buffer buffer) {
        switch(buffer.type) {
            case BufferType.uniform:
                auto hndl = buffer.handle;
                SDL_BindGPUVertexStorageBuffers(handle_, slot, &hndl, 1);
                return;
            
            case BufferType.vertex:
                SDL_GPUBufferBinding binding = {
                    buffer = buffer.handle,
                    offset = 0
                };
                SDL_BindGPUVertexBuffers(handle_, slot, &binding, 1);
                return;
            
            default:
                break;
        }
    }

    /**
        Sets a fragment storage buffer for subsequent draw calls.

        Params:
            slot =      The slot to bind the buffer
            buffer =    The buffer to bind.
    */
    void setFragmentBuffer(uint slot, Buffer buffer) {
        if (buffer.type != BufferType.uniform)
            return;
        
        SDL_GPUBufferBinding binding = {
            buffer = buffer.handle,
            offset = 0
        };
        SDL_BindGPUFragmentStorageBuffers(handle_, slot, &binding, 1);
    }

    /**
        Submits a draw command to the GPU.

        Params:
            vertexCount =   The amount of vertices to draw.
            vertexOffset =  Offset into the vertex buffer to draw from.
    */
    void draw(uint vertexCount, uint vertexOffset) {
        SDL_DrawGPUPrimitives(handle_, vertexCount, 1, vertexOffset, 0); 
    }

    /**
        Submits an indexed draw command to the GPU.

        Params:
            indexCount =    The amount of indices to draw.
            startIndex =    The index to start from.
            baseVertex =    The base offset into the vertex buffer to draw from.
    */
    void drawIndexed(uint indexCount, uint startIndex, uint baseVertex) {
        SDL_DrawGPUIndexedPrimitives(handle_, indexCount, 1, startIndex, baseVertex, 0);
    }

    /**
        Stops recording commands into the pass, returning
        control to the parent command buffer.

        Notes:
            This encoder will become invalid after this call,
            any attempts to record to it after ending it will
            result in undefined behaviour.
    */
    override
    void end() {
        SDL_EndGPURenderPass(handle_);
        super.end();
    }
}

/**
    Mesh topology modes
*/
enum Topology : SDL_GPUPrimitiveType {
    triangles = SDL_GPUPrimitiveType.SDL_GPU_PRIMITIVETYPE_TRIANGLELIST,
    triangleStrip = SDL_GPUPrimitiveType.SDL_GPU_PRIMITIVETYPE_TRIANGLESTRIP,
    lines = SDL_GPUPrimitiveType.SDL_GPU_PRIMITIVETYPE_LINELIST,
    lineStrip = SDL_GPUPrimitiveType.SDL_GPU_PRIMITIVETYPE_LINESTRIP,
    points = SDL_GPUPrimitiveType.SDL_GPU_PRIMITIVETYPE_POINTLIST,
}

/**
    Index type for index buffers.
*/
enum IndexType : SDL_GPUIndexElementSize {
    uint16 = SDL_GPUIndexElementSize.SDL_GPU_INDEXELEMENTSIZE_16BIT,
    uint32 = SDL_GPUIndexElementSize.SDL_GPU_INDEXELEMENTSIZE_32BIT
}

/**
    Load actions for attachments.
*/
enum LoadAction : SDL_GPULoadOp {
    load = SDL_GPULoadOp.SDL_GPU_LOADOP_LOAD,
    clear = SDL_GPULoadOp.SDL_GPU_LOADOP_CLEAR,
    dontCare = SDL_GPULoadOp.SDL_GPU_LOADOP_DONT_CARE
}

/**
    Store actions for attachments.
*/
enum StoreAction : SDL_GPUStoreOp {
    store = SDL_GPUStoreOp.SDL_GPU_STOREOP_STORE,
    dontCare = SDL_GPUStoreOp.SDL_GPU_STOREOP_DONT_CARE
}

/**
    Describes a render pass.
*/
struct RenderPassDescriptor {

    /**
        Color attachments.
    */
    ColorAttachmentDescriptor[] colorAttachments;
    
    /**
        Depth-stencil attachment.
    */
    DepthStencilAttachmentDescriptor depthStencilAttachment;

    /**
        Converts the color attachemnt descriptors to their
        SDL equivalent.
    */
    SDL_GPUColorTargetInfo[] toSDLColorTargets() {
        SDL_GPUColorTargetInfo[] tmp = nu_malloca!SDL_GPUColorTargetInfo(desc.colorAttachments.length);
        foreach(i; 0..tmp.length) {
            tmp[i] = desc.colorAttachments[i].toSDLColorTargetInfo();
        }
        return tmp;
    }
}

/**
    Describes a single color attachment in a render pass.
*/
struct ColorAttachmentDescriptor {
    
    /**
        The texture attached at this bind location.
    */
    Texture2D texture;

    /**
        Load action for the attachment.
    */
    LoadAction loadAction;

    /**
        Store action for the attachment.
    */
    StoreAction storeAction;

    /**
        Clear color for the attachment.
    */
    vec4 clearColor;

    /**
        Converts this attachemnt descriptor to its
        SDL equivalent.
    */
    SDL_GPUColorTargetInfo toSDLColorTargetInfo() {
        return SDL_GPUColorTargetInfo(
            texture.handle,
            0,
            0,
            *cast(SDL_FColor*)clearColor.ptr,
            loadAction,
            storeAction,
            null,
            0,
            0,
            true,
            false,
            0,
            0
        );
    }
}

/**
    Describes a depth-stencil attachment in a render pass.
*/
struct DepthStencilAttachmentDescriptor {
    
    /**
        The texture attached at this bind location.
    */
    Texture2D texture;

    /**
        Load action for the attachment.
    */
    LoadAction depthLoadAction;

    /**
        Store action for the attachment.
    */
    StoreAction depthStoreAction;

    /**
        Load action for the attachment.
    */
    LoadAction stencilLoadAction;

    /**
        Store action for the attachment.
    */
    StoreAction stencilStoreAction;

    /**
        Clear value for the depth buffer.
    */
    float clearDepth;

    /**
        Clear value for the stencil buffer.
    */
    ubyte clearStencil;

    /**
        Converts this attachemnt descriptor to its
        SDL equivalent.
    */
    SDL_GPUDepthStencilTargetInfo toSDLDepthStencilTargetInfo() {
        return SDL_GPUDepthStencilTargetInfo(
            texture.handle,
            clearDepth,
            depthLoadAction,
            depthStoreAction,
            stencilLoadAction,
            stencilStoreAction,
            true,
            clearStencil,
            0,
            0
        );
    }
}