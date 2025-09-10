/**
    Renderer GPU Pipeline Caching

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.render.gpucache;
import inui.core.render.renderencoder;
import inui.core.render.pipeline;
import inui.core.render.texture;
import inui.core.render.device;
import inui.core.render.shader;
import sdl.gpu;
import nulib;
import numem;

/**
    Caches GPU pipelines.
*/
class GPUPipelineCache : GPUObject {
private:
@nogc:
    map!(RenderPipeline, CachedPipeline[]) pipelines;

    void createPipelineFor(ref CachedPipeline pipeline) {
        SDL_GPUGraphicsPipelineCreateInfo createInfo = pipeline.state.toPipelineCreateInfo();

        // Setup color target state.
        vector!SDL_GPUColorTargetDescription colorTargets;
        auto blendState = pipeline.state.toBlendState();
        foreach(i; 0..pipeline.state.renderPipeline.colorTargets.length) {
            if (pipeline.state.renderPipeline.colorTargets[i] == TextureFormat.none)
                continue;

            colorTargets ~= SDL_GPUColorTargetDescription(
                pipeline.state.renderPipeline.colorTargets[i],
                blendState
            );
        }

        createInfo.target_info.color_target_descriptions = colorTargets.ptr;
        createInfo.target_info.num_color_targets = cast(uint)colorTargets.length;
        pipeline.pipeline = SDL_CreateGPUGraphicsPipeline(
            gpuHandle,
            &createInfo
        );
        colorTargets.clear();
    }

public:

    // Destructor
    ~this() {
        foreach(CachedPipeline[] cache; pipelines.byValue) {
            foreach(ref CachedPipeline pipeline; cache) {
                SDL_ReleaseGPUGraphicsPipeline(gpuHandle, pipeline.pipeline);
            }
            nu_freea(cache);
        }
        pipelines.clearContents();
    }

    // Constructor
    this(RenderingDevice device) {
        super(device);
    }

    /**
        Gets a pipeline object from the cache.
    */
    SDL_GPUGraphicsPipeline* get(PipelineState state) {
        if (state.renderPipeline !in pipelines) {
            pipelines[state.renderPipeline] = (vector!CachedPipeline).init;
        }

        foreach(pipeline; pipelines[state.renderPipeline]) {
            if (pipeline.state == state)
                return pipeline.pipeline;
        }

        CachedPipeline newPipeline;
        newPipeline.state = state;
        this.createPipelineFor(newPipeline);

        auto plist = pipelines[state.renderPipeline];
        plist = plist.nu_resize(plist.length+1);
        plist[$-1] = newPipeline;
        pipelines[state.renderPipeline] = plist;
        return newPipeline.pipeline;
    }
}

/**
    Combined pipeline state
*/
struct PipelineState {
@nogc:
    RenderPipeline renderPipeline;
    bool enableBlend = true;
    BlendOp colorBlendOp = BlendOp.add;
    BlendOp alphaBlendOp = BlendOp.add;
    BlendFactor srcColorFactor = BlendFactor.one;
    BlendFactor srcAlphaFactor = BlendFactor.one;
    BlendFactor dstColorFactor = BlendFactor.oneMinusSrcAlpha;
    BlendFactor dstAlphaFactor = BlendFactor.oneMinusSrcAlpha;
    FrontFace frontFace = FrontFace.ccw;
    CullMode cullMode = CullMode.back;
    Topology topology = Topology.triangles;

    private
    SDL_GPURasterizerState toRasterState() {
        return SDL_GPURasterizerState(
            SDL_GPUFillMode.SDL_GPU_FILLMODE_FILL,
            cullMode,
            frontFace,
            0,
            0,
            0,
            false,
            false,
            0,
            0
        );
    }

    private
    SDL_GPUColorTargetBlendState toBlendState() {
        return SDL_GPUColorTargetBlendState(
            srcColorFactor,
            dstColorFactor,
            colorBlendOp,
            srcAlphaFactor,
            dstAlphaFactor,
            alphaBlendOp,
            cast(SDL_GPUColorComponentFlags)0,
            enableBlend,
            false,
            0,
        );
    }

    private
    SDL_GPUGraphicsPipelineTargetInfo toGraphicsPipelineTargetInfo() {
        return SDL_GPUGraphicsPipelineTargetInfo(
            color_target_descriptions: null,
            num_color_targets: cast(uint)renderPipeline.colorTargets.length,
            depth_stencil_format: renderPipeline.depthStencilTarget,
            has_depth_stencil_target: renderPipeline.depthStencilTarget != TextureFormat.none
        );
    }

    private
    SDL_GPUGraphicsPipelineCreateInfo toPipelineCreateInfo() {
        return SDL_GPUGraphicsPipelineCreateInfo(
            vertex_shader: renderPipeline.vertex.handle,
            fragment_shader: renderPipeline.fragment.handle,
            vertex_input_state: renderPipeline.vertexInputState,
            primitive_type: topology,
            rasterizer_state: this.toRasterState(),
            multisample_state: SDL_GPUMultisampleState(SDL_GPUSampleCount.SDL_GPU_SAMPLECOUNT_1, 0, false, 0, 0, 0),
            depth_stencil_state: SDL_GPUDepthStencilState(enable_depth_test: false, enable_depth_write: false, enable_stencil_test: false),
            target_info: this.toGraphicsPipelineTargetInfo(),
        );
    }

    bool opEquals(ref PipelineState other) {
        return
            this.renderPipeline is other.renderPipeline &&
            this.enableBlend is other.enableBlend &&
            this.colorBlendOp == other.colorBlendOp &&
            this.alphaBlendOp == other.alphaBlendOp &&
            this.srcColorFactor == other.srcColorFactor &&
            this.srcAlphaFactor == other.srcAlphaFactor &&
            this.dstColorFactor == other.dstColorFactor &&
            this.frontFace == other.frontFace &&
            this.cullMode == other.cullMode &&
            this.topology == other.topology;
    }
}

private
struct CachedPipeline {
    PipelineState state;
    SDL_GPUGraphicsPipeline* pipeline;
}
