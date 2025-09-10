/**
    Renderer Render Pipelines

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.render.pipeline;
import inui.core.render.device;
import inui.core.render.texture;
import inui.core.render.shader;
import sdl.gpu;
import nulib;
import numem;

/**
    A render pipeline consisting of shaders and shared state.
*/
class RenderPipeline : NuRefCounted {
private:
@nogc:
    RenderPipelineDescriptor desc;
    vector!SDL_GPUVertexBufferDescription buffers;
    vector!SDL_GPUVertexAttribute attributes;

public:

    /**
        The vertex shader
    */
    @property Shader vertex() => desc.vertexShader;

    /**
        The fragment shader
    */
    @property Shader fragment() => desc.fragmentShader;

    /**
        Color targets
    */
    @property TextureFormat[] colorTargets() => desc.colorTargets;

    /**
        Depth-stencil target
    */
    @property TextureFormat depthStencilTarget() => desc.depthStencilTarget;

    /**
        The SDL Input state
    */
    @property SDL_GPUVertexInputState vertexInputState() => SDL_GPUVertexInputState(
        buffers.ptr,
        cast(uint)buffers.length,
        attributes.ptr,
        cast(uint)attributes.length
    );

    // Destructor
    ~this() {
        desc.vertexShader.release();
        desc.fragmentShader.release();
        nu_freea(desc.colorTargets);
        attributes.clear();
        buffers.clear();
    }

    /**
        Creates a new shader program.
    */
    this(RenderPipelineDescriptor desc) {
        this.desc.vertexShader = desc.vertexShader.retained();
        this.desc.fragmentShader = desc.fragmentShader.retained();
        this.desc.colorTargets = desc.colorTargets.nu_dup();
        this.desc.depthStencilTarget = desc.depthStencilTarget;

        foreach(i, ref VertexBufferDescriptor buffer; desc.vertexBuffers) {
            buffers ~= buffer.toSDLVertexBufferDescriptor();
            foreach(k, ref VertexAttributeDescriptor attribute; buffer.attributes) {
                attributes ~= attribute.toSDLVertexAttributeDescriptor();
                attributes[$-1].buffer_slot = cast(uint)i;
                attributes[$-1].location = cast(uint)k;
            }
        }
    }
}

/**
    Descriptor used to create a shader program.
*/
struct RenderPipelineDescriptor {

    /**
        Vertex shader for the program
    */
    Shader vertexShader;

    /**
        Fragment shader for the program
    */
    Shader fragmentShader;

    /**
        Vertex buffer layout
    */
    VertexBufferDescriptor[] vertexBuffers;

    /**
        The color render targets.
    */
    TextureFormat[] colorTargets;

    /**
        The depth-stencil render target.
    */
    TextureFormat depthStencilTarget;
}

/**
    Descriptor for vertex buffer layout
*/
struct VertexBufferDescriptor {
@nogc:

    /**
        The slot of the vertex buffer.
    */
    uint slot;

    /**
        The stride between vertex buffer elements,
        in bytes.
    */
    uint stride;

    /**
        Attributes of the vertex buffer.
    */
    VertexAttributeDescriptor[] attributes;

    /**
        Converts this descriptor to its SDL equivalent.
    */
    SDL_GPUVertexBufferDescription toSDLVertexBufferDescriptor() {
        return SDL_GPUVertexBufferDescription(
            slot,
            stride,
            SDL_GPUVertexInputRate.SDL_GPU_VERTEXINPUTRATE_VERTEX,
            0
        );
    }
}

/**
    Vertex formats
*/
enum VertexFormat : SDL_GPUVertexElementFormat {
    none = SDL_GPUVertexElementFormat.SDL_GPU_VERTEXELEMENTFORMAT_INVALID,
    INT = SDL_GPUVertexElementFormat.SDL_GPU_VERTEXELEMENTFORMAT_INT,
    INT2 = SDL_GPUVertexElementFormat.SDL_GPU_VERTEXELEMENTFORMAT_INT2,
    INT3 = SDL_GPUVertexElementFormat.SDL_GPU_VERTEXELEMENTFORMAT_INT3,
    INT4 = SDL_GPUVertexElementFormat.SDL_GPU_VERTEXELEMENTFORMAT_INT4,
    UINT = SDL_GPUVertexElementFormat.SDL_GPU_VERTEXELEMENTFORMAT_UINT,
    UINT2 = SDL_GPUVertexElementFormat.SDL_GPU_VERTEXELEMENTFORMAT_UINT2,
    UINT3 = SDL_GPUVertexElementFormat.SDL_GPU_VERTEXELEMENTFORMAT_UINT3,
    UINT4 = SDL_GPUVertexElementFormat.SDL_GPU_VERTEXELEMENTFORMAT_UINT4,
    FLOAT = SDL_GPUVertexElementFormat.SDL_GPU_VERTEXELEMENTFORMAT_FLOAT,
    FLOAT2 = SDL_GPUVertexElementFormat.SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2,
    FLOAT3 = SDL_GPUVertexElementFormat.SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3,
    FLOAT4 = SDL_GPUVertexElementFormat.SDL_GPU_VERTEXELEMENTFORMAT_FLOAT4,
    BYTE2 = SDL_GPUVertexElementFormat.SDL_GPU_VERTEXELEMENTFORMAT_BYTE2,
    BYTE4 = SDL_GPUVertexElementFormat.SDL_GPU_VERTEXELEMENTFORMAT_BYTE4,
    UBYTE2 = SDL_GPUVertexElementFormat.SDL_GPU_VERTEXELEMENTFORMAT_UBYTE2,
    UBYTE4 = SDL_GPUVertexElementFormat.SDL_GPU_VERTEXELEMENTFORMAT_UBYTE4,
    BYTE2_NORM = SDL_GPUVertexElementFormat.SDL_GPU_VERTEXELEMENTFORMAT_BYTE2_NORM,
    BYTE4_NORM = SDL_GPUVertexElementFormat.SDL_GPU_VERTEXELEMENTFORMAT_BYTE4_NORM,
    UBYTE2_NORM = SDL_GPUVertexElementFormat.SDL_GPU_VERTEXELEMENTFORMAT_UBYTE2_NORM,
    UBYTE4_NORM = SDL_GPUVertexElementFormat.SDL_GPU_VERTEXELEMENTFORMAT_UBYTE4_NORM,
    SHORT2 = SDL_GPUVertexElementFormat.SDL_GPU_VERTEXELEMENTFORMAT_SHORT2,
    SHORT4 = SDL_GPUVertexElementFormat.SDL_GPU_VERTEXELEMENTFORMAT_SHORT4,
    USHORT2 = SDL_GPUVertexElementFormat.SDL_GPU_VERTEXELEMENTFORMAT_USHORT2,
    USHORT4 = SDL_GPUVertexElementFormat.SDL_GPU_VERTEXELEMENTFORMAT_USHORT4,
    SHORT2_NORM = SDL_GPUVertexElementFormat.SDL_GPU_VERTEXELEMENTFORMAT_SHORT2_NORM,
    SHORT4_NORM = SDL_GPUVertexElementFormat.SDL_GPU_VERTEXELEMENTFORMAT_SHORT4_NORM,
    USHORT2_NORM = SDL_GPUVertexElementFormat.SDL_GPU_VERTEXELEMENTFORMAT_USHORT2_NORM,
    USHORT4_NORM = SDL_GPUVertexElementFormat.SDL_GPU_VERTEXELEMENTFORMAT_USHORT4_NORM,
    HALF2 = SDL_GPUVertexElementFormat.SDL_GPU_VERTEXELEMENTFORMAT_HALF2,
    HALF4 = SDL_GPUVertexElementFormat.SDL_GPU_VERTEXELEMENTFORMAT_HALF4
}

/**
    Descriptor for vertex buffer layout
*/
struct VertexAttributeDescriptor {
@nogc:
    uint offset;
    VertexFormat format;

    /**
        Converts this descriptor to its SDL equivalent.
    */
    SDL_GPUVertexAttribute toSDLVertexAttributeDescriptor() {
        return SDL_GPUVertexAttribute(
            0,
            0,
            format,
            offset
        );
    }
}

/**
    Blending operators
*/
enum BlendOp : SDL_GPUBlendOp {
    
    /**
        (source * source_factor) + (destination * destination_factor) 
    */
    add = SDL_GPUBlendOp.SDL_GPU_BLENDOP_ADD,
        
    /**
        (source * source_factor) - (destination * destination_factor) 
    */
    subtract = SDL_GPUBlendOp.SDL_GPU_BLENDOP_SUBTRACT,
        
    /**
        (destination * destination_factor) - (source * source_factor) 
    */
    reverseSubtract = SDL_GPUBlendOp.SDL_GPU_BLENDOP_REVERSE_SUBTRACT,
        
    /**
        min(source, destination) 
    */
    min = SDL_GPUBlendOp.SDL_GPU_BLENDOP_MIN,
        
    /**
        max(source, destination) 
    */
    max = SDL_GPUBlendOp.SDL_GPU_BLENDOP_MAX,
}

/**
    Blending factor
*/
enum BlendFactor : SDL_GPUBlendFactor {
    
    /**
        0 
    */
    zero = SDL_GPUBlendFactor.SDL_GPU_BLENDFACTOR_ZERO,
        
    /**
        1 
    */
    one = SDL_GPUBlendFactor.SDL_GPU_BLENDFACTOR_ONE,
        
    /**
        source color 
    */
    srcColor = SDL_GPUBlendFactor.SDL_GPU_BLENDFACTOR_SRC_COLOR,
        
    /**
        1 - source color 
    */
    oneMinusSrcColor = SDL_GPUBlendFactor.SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_COLOR,
        
    /**
        destination color 
    */
    dstColor = SDL_GPUBlendFactor.SDL_GPU_BLENDFACTOR_DST_COLOR,
        
    /**
        1 - destination color 
    */
    oneMinusDstColor = SDL_GPUBlendFactor.SDL_GPU_BLENDFACTOR_ONE_MINUS_DST_COLOR,
        
    /**
        source alpha 
    */
    srcAlpha = SDL_GPUBlendFactor.SDL_GPU_BLENDFACTOR_SRC_ALPHA,
        
    /**
        1 - source alpha 
    */
    oneMinusSrcAlpha = SDL_GPUBlendFactor.SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
        
    /**
        destination alpha 
    */
    dstAlpha = SDL_GPUBlendFactor.SDL_GPU_BLENDFACTOR_DST_ALPHA,
        
    /**
        1 - destination alpha 
    */
    oneMinusDstAlpha = SDL_GPUBlendFactor.SDL_GPU_BLENDFACTOR_ONE_MINUS_DST_ALPHA
}

/**
    Culling modes.
*/
enum CullMode : SDL_GPUCullMode {
    none = SDL_GPUCullMode.SDL_GPU_CULLMODE_NONE,
    back = SDL_GPUCullMode.SDL_GPU_CULLMODE_BACK,
    font = SDL_GPUCullMode.SDL_GPU_CULLMODE_FRONT
}

/**
    Culling modes.
*/
enum FrontFace : SDL_GPUFrontFace {

    /**
        Front face has clockwise winding
    */
    clockwise = SDL_GPUFrontFace.SDL_GPU_FRONTFACE_CLOCKWISE,

    /**
        Front face has counter-clockwise winding
    */
    ccw = SDL_GPUFrontFace.SDL_GPU_FRONTFACE_COUNTER_CLOCKWISE
}