module mtl.pass;
import mtl.context;
import mtl.texture;
import mtl.buffer;
import mtl.shader;
import foundation;

import inmath;

public import inrndr.pass;
public import metal.renderpass;
public import metal.argument;
public import metal.commandbuffer;
public import metal.commandencoder;
public import metal.rendercommandencoder;
public import metal.renderpipeline;
public import metal.vertexdescriptor;

class MetalCommandBuffer : CommandBuffer {
private:
@nogc:
    MTLCommandBuffer buffer;
    MTLRenderCommandEncoder encoder;

    void create(MTLCommandQueue queue, RenderPassDescriptor desc) {
        NSError err;

        MTLRenderPipelineDescriptor pipeline = MTLRenderPipelineDescriptor.alloc.init;
        MTLRenderPassDescriptor pass = MTLRenderPassDescriptor.create();

        pipeline.vertexFunction = (cast(MetalShader)desc.shader).vertex;
        pipeline.fragmentFunction = (cast(MetalShader)desc.shader).fragment;
        pipeline.vertexDescriptor = desc.vertexInput.toMTLDescriptor();

        foreach(i, target; desc.targets) {
            MTLRenderPassColorAttachmentDescriptor passColorDesc = pass.colorAttachments.get(cast(uint)i);
            MTLRenderPipelineColorAttachmentDescriptor pipelineColorDesc = pipeline.colorAttachments.get(cast(uint)i);

            passColorDesc.texture = cast(MTLTexture)(cast(MetalTexture)target.target).texture;
            passColorDesc.level = 0;
            passColorDesc.slice = 0;
            passColorDesc.storeAction = MTLStoreAction.Store;
            passColorDesc.loadAction = target.clear ? MTLLoadAction.Clear : MTLLoadAction.Load;
            passColorDesc.clearColor = MTLClearColor(target.clearColor.r, target.clearColor.g, target.clearColor.b, target.clearColor.a);

            pipelineColorDesc.pixelFormat = target.target.format.toMTLPixelFormat();
            pipelineColorDesc.blendingEnabled = target.blending;
            pipelineColorDesc.sourceRGBBlendFactor = target.srcBlendFactor.toMTLBlendFactor();
            pipelineColorDesc.sourceAlphaBlendFactor = target.srcBlendFactor.toMTLBlendFactor();
            pipelineColorDesc.destinationRGBBlendFactor = target.dstBlendFactor.toMTLBlendFactor();
            pipelineColorDesc.destinationAlphaBlendFactor = target.dstBlendFactor.toMTLBlendFactor();
        }

        buffer = queue.commandBuffer();
        encoder = buffer.renderCommandEncoder(pass);

        auto pipelineState = buffer.device.newRenderPipelineState(pipeline, err);
        encoder.setRenderPipelineState(pipelineState);
        
        pipelineState.autorelease();
        pipeline.autorelease();
    }

public:

    ~this() { }

    /**
        Constructor
    */
    this(MTLCommandQueue queue, RenderPassDescriptor desc) {
        this.create(queue, desc);
        super(desc);
    }

    override
    void setViewport(rect value) {
        encoder.setViewport(MTLViewport(
            value.x,
            value.y,
            value.width,
            value.height,
            0.0, 1.0
        ));
    }

    override
    void setScissor(rect value) {
        encoder.setScissorRect(MTLScissorRect(
            cast(uint)value.x,
            cast(uint)value.y,
            cast(uint)value.width,
            cast(uint)value.height,
        ));
    }

    override
    void setUniformBuffer(Buffer buffer, uint slot) {
        encoder.setVertexBuffer((cast(MetalBuffer)buffer).buffer, 0, slot+1);
        encoder.setFragmentBuffer((cast(MetalBuffer)buffer).buffer, 0, slot);
    }

    override
    void setTexture(Texture texture, uint slot) {
        encoder.setFragmentTexture((cast(MetalTexture)texture).texture, slot);
    }

    override
    void drawTriangles(Buffer vertices, uint vertexCount, uint vertexOffset = 0) {
        encoder.setVertexBuffer((cast(MetalBuffer)vertices).buffer, vertexOffset, 0);
        encoder.draw(MTLPrimitiveType.Triangle, 0, vertexCount);
    }

    override
    void drawTriangles(Buffer vertices, Buffer indices, uint indexElemSize, uint indexCount, uint indexOffset = 0, uint vertexOffset = 0) {
        encoder.setVertexBuffer((cast(MetalBuffer)vertices).buffer, vertexOffset, 0);
        encoder.drawIndexed(
            MTLPrimitiveType.Triangle, 
            indexCount, 
            indexElemSize == 2 ? MTLIndexType.UInt16 : MTLIndexType.UInt32, 
            (cast(MetalBuffer)indices).buffer, 
            indexOffset
        );
    }

    MTLCommandBuffer finalize() {
        encoder.endEncoding();
        return buffer;
    }
}

MTLBlendFactor toMTLBlendFactor(BlendMode blendMode) @nogc {
    final switch(blendMode) {
        case BlendMode.zero: return MTLBlendFactor.Zero;
        case BlendMode.one: return MTLBlendFactor.One;
        case BlendMode.srcColor: return MTLBlendFactor.SourceColor;
        case BlendMode.oneMinusSrcColor: return MTLBlendFactor.OneMinusSourceColor;
        case BlendMode.srcAlpha: return MTLBlendFactor.SourceAlpha;
        case BlendMode.oneMinusSrcAlpha: return MTLBlendFactor.OneMinusSourceAlpha;
        case BlendMode.dstColor: return MTLBlendFactor.DestinationColor;
        case BlendMode.oneMinusDstColor: return MTLBlendFactor.OneMinusDestinationColor;
        case BlendMode.dstAlpha: return MTLBlendFactor.DestinationAlpha;
        case BlendMode.oneMinusDstAlpha: return MTLBlendFactor.OneMinusDestinationAlpha;
    }
}

MTLVertexFormat toMTLVertexFormat(VertexFormat format) @nogc {
    final switch(format) {
        case VertexFormat.float1: return MTLVertexFormat.Float;
        case VertexFormat.float2: return MTLVertexFormat.Float2;
        case VertexFormat.float3: return MTLVertexFormat.Float3;
        case VertexFormat.float4: return MTLVertexFormat.Float4;
        case VertexFormat.ubyte1: return MTLVertexFormat.UChar;
        case VertexFormat.ubyte2: return MTLVertexFormat.UChar2;
        case VertexFormat.ubyte3: return MTLVertexFormat.UChar3;
        case VertexFormat.ubyte4: return MTLVertexFormat.UChar4;
    }
}

MTLVertexDescriptor toMTLDescriptor(VertexDescriptor desc) @nogc {
    MTLVertexDescriptor result = MTLVertexDescriptor.create();
    auto layout = result.layouts.get(0);

    foreach(i, attrib; desc.attributes) {
        MTLVertexAttributeDescriptor adesc = result.attributes.get(i);

        adesc.offset = attrib.offset;
        adesc.format = attrib.format.toMTLVertexFormat();
    }

    layout.stepRate = desc.rate;
    layout.stepFunction = MTLVertexStepFunction.PerVertex;
    layout.stride = desc.stride;
    return result;
}
