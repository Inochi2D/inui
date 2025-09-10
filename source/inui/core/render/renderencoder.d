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
import inmath;
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
    bool needsStateRefresh = false;

    void refreshState() {
        if (needsStateRefresh) {
            SDL_BindGPUGraphicsPipeline(
                handle_,        
                parent.device.pipelineCache.get(state)
            );
            this.needsStateRefresh = false;
        }
    }

public:
    this(CommandBuffer parent, RenderPassDescriptor desc) {
        super(parent);

        auto colorTargets = desc.toSDLColorTargets();
        auto depthStencilTarget = desc.depthStencilAttachment.toSDLDepthStencilTargetInfo();

        this.handle_ = SDL_BeginGPURenderPass(parent.handle, colorTargets.ptr, cast(uint)colorTargets.length, depthStencilTarget.texture ? &depthStencilTarget : null);
        nu_freea(colorTargets);
    }

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
            x: value.x,
            y: value.y,
            w: value.width,
            h: value.height,
            min_depth: 0,
            max_depth: 1
        };
        SDL_SetGPUViewport(handle_, &vp);
        this.viewport_ = value;
    }

    /**
        The currently active culling mode.
    */
    @property CullMode cullMode() => state.cullMode;
    @property void cullMode(CullMode value) {
        state.cullMode = value;
        this.needsStateRefresh = true;
    }

    /**
        The currently active rendering topology.
    */
    @property Topology topology() => state.topology;
    @property void topology(Topology value) {
        state.topology = value;
        this.needsStateRefresh = true;
    }

    /**
        The currently active source color blending factor.
    */
    @property BlendFactor srcColorFactor() => state.srcColorFactor;
    @property void srcColorFactor(BlendFactor value) {
        state.srcColorFactor = value;
        this.needsStateRefresh = true;
    }

    /**
        The currently active source alpha blending factor.
    */
    @property BlendFactor srcAlphaFactor() => state.srcAlphaFactor;
    @property void srcAlphaFactor(BlendFactor value) {
        state.srcAlphaFactor = value;
        this.needsStateRefresh = true;
    }

    /**
        The currently active destination color blending factor.
    */
    @property BlendFactor dstColorFactor() => state.dstColorFactor;
    @property void dstColorFactor(BlendFactor value) {
        state.dstColorFactor = value;
        this.needsStateRefresh = true;
    }

    /**
        The currently active destination alpha blending factor.
    */
    @property BlendFactor dstAlphaFactor() => state.dstAlphaFactor;
    @property void dstAlphaFactor(BlendFactor value) {
        state.dstAlphaFactor = value;
        this.needsStateRefresh = true;
    }

    /**
        Sets the currently active render pipeline.

        Params:
            pipeline = The pipeline to set.
    */
    void setRenderPipeline(RenderPipeline pipeline) {
        state.renderPipeline = pipeline;
        this.needsStateRefresh = true;
    }

    /**
        Sets a index buffer for subsequent draw calls.

        Params:
            buffer =    The buffer to bind.
            indexType = The type of elements stored in the index buffer.
            offset =    Offset into the index buffer to read from.
    */
    void setIndexBuffer(Buffer buffer, IndexType indexType, uint offset = 0) {
        if (buffer.type != BufferType.index)
            return;

        SDL_GPUBufferBinding binding = {
            buffer: cast(SDL_GPUBuffer*)buffer.handle,
            offset: offset
        };
        SDL_BindGPUIndexBuffer(handle_, &binding, indexType);
    }

    /**
        Sets a texture to use for sampling in the fragment shader
        of the pipeline.
    */
    void setFragmentTexture(uint slot, Texture2D texture, Sampler sampler) {
        if (!state.renderPipeline)
            return;
        
        auto bindInfo = SDL_GPUTextureSamplerBinding(
            texture: texture.handle,
            sampler: sampler.handle
        );
        SDL_BindGPUFragmentSamplers(handle_, slot, &bindInfo, 1);
    }

    /**
        Sets a vertex buffer for subsequent draw calls.

        Params:
            slot =      The slot to bind the buffer
            buffer =    The buffer to bind.
            offset =    The offset into the buffer to bind.
        
        Note:
            Offset does nothing for uniform buffers, the entire
            buffer will always be pushed.
    */
    void setVertexBuffer(uint slot, Buffer buffer, uint offset = 0) {
        switch(buffer.type) {
            case BufferType.uniform:
                SDL_PushGPUVertexUniformData(parent.handle, slot, buffer.handle, buffer.size);
                return;
            
            case BufferType.vertex:
                SDL_GPUBufferBinding binding = {
                    buffer: cast(SDL_GPUBuffer*)buffer.handle,
                    offset: offset
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
        switch(buffer.type) {
            case BufferType.uniform:
                SDL_PushGPUFragmentUniformData(parent.handle, slot, buffer.handle, buffer.size);
                return;
            
            default:
                break;
        }
    }

    /**
        Submits a draw command to the GPU.

        Params:
            vertexCount =   The amount of vertices to draw.
            vertexOffset =  Offset into the vertex buffer to draw from.
    */
    void draw(uint vertexCount, uint vertexOffset) {
        if (!state.renderPipeline)
            return;
        
        this.refreshState();
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
        if (!state.renderPipeline)
            return;
        
        this.refreshState();
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
@nogc:

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
        weak_vector!SDL_GPUColorTargetInfo tmp;
        foreach(i; 0..colorAttachments.length) {
            if (colorAttachments[i].texture)
                tmp ~= colorAttachments[i].toSDLColorTargetInfo();
        }
        return tmp.take();
    }
}

/**
    Describes a single color attachment in a render pass.
*/
struct ColorAttachmentDescriptor {
@nogc:

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
            texture ? texture.handle : null,
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
@nogc:

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
            texture ? texture.handle : null,
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