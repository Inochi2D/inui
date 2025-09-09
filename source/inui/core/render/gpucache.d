/**
    Renderer GPU Pipeline Caching

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.render.gpucache;
import inui.core.render.renderencoder;
import inui.core.render.pipeline;
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
    map!(RenderPipeline, vector!CachedPipeline) pipelines;

    void createPipelineFor(ref CachedPipeline pipeline) {
        SDL_GPUGraphicsPipelineCreateInfo createInfo = pipeline.state.toPipelineCreateInfo();

        // Setup color target state.
        auto targetDescriptions = nu_malloc!SDL_GPUColorTargetDescription(createInfo.target_info.num_color_targets);
        auto blendState = pipeline.toBlendState();
        foreach(i, ref SDL_GPUColorTargetDescription colorTarget; targetDescriptions) {
            colorTarget.format = pipeline.state.renderPipeline.colorTargets[i];
            colorTarget.blend_state = blendState;
        }

        createInfo.target_info.color_target_descriptions = targetDescriptions.ptr;
        pipeline.pipeline = SDL_CreateGPUGraphicsPipeline(
            gpuHandle,
            &createInfo
        );
        nu_freea(targetDescriptions);
    }

public:

    // Destructor
    ~this() {
        foreach(vector!CachedPipeline cache; pipelines.byValue) {
            foreach(ref CachedPipeline pipeline; cache[]) {
                SDL_ReleaseGPUGraphicsPipeline(gpuHandle, pipeline.pipeline);
            }
            cache.clear();
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
            if (pipeline.state == pipeline)
                return pipeline.pipeline;
        }

        CachedPipeline newPipeline;
        newPipeline.state = state;
        this.createPipelineFor(newPipeline);
        pipelines[state.renderPipeline] ~= newPipeline;
        return newPipeline.pipeline;
    }
}

/**
    Combined pipeline state
*/
struct PipelineState {
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
            num_color_targets: renderPipeline.colorTargets.length,
            depth_stencil_format: renderPipeline.depthStencilTarget,
            has_depth_stencil_target: renderPipeline.depthStencilTarget != TextureFormat.none
        );
    }

    private
    SDL_GPUGraphicsPipelineCreateInfo toPipelineCreateInfo() {
        return SDL_GPUGraphicsPipelineCreateInfo(
            vertex_shader: pipeline.renderPipeline.vertex.handle,
            fragment_shader: pipeline.renderPipeline.fragment.handle,
            vertex_input_state: pipeline.renderPipeline.vertexInputState,
            primitive_type: pipeline.topology,
            rasterizer_state: this.toRasterState(),
            target_info: this.toGraphicsPipelineTargetInfo(),
            multisample_state: SDL_GPUMultisampleState(1, 0, false, 0, 0, 0),
        );
    }

    bool opEquals(const PipelineState other) const {
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
