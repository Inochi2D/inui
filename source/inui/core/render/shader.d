/**
    Renderer Shaders

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.render.shader;
import inui.core.render.device;
import inui.core.render.texture;
import sdl.gpu;
import numem;

/**
    A shader
*/
class Shader : GPUObject {
private:
@nogc:
    ShaderDescriptor desc;
    SDL_GPUShader* handle_;

public:

    /**
        The underlying SDL_GPU handle.
    */
    final @property SDL_GPUShader* handle() => handle_;

    /**
        The underlying The shader stage.
    */
    final @property ShaderStage stage() => desc.stage;

    /**
        The amount of samplers this shader requires.
    */
    final @property uint samplerCount() => desc.samplerCount;

    /**
        The amount of uniform buffers this shader requires.
    */
    final @property uint uniformCount() => desc.uniformCount;

    // Destructor
    ~this() {
        SDL_ReleaseGPUShader(gpuHandle, handle_);
    }

    /**
        Constructs a new shader

        Params:
            device =    The owning device.
            desc =      The descriptor used to create the shader.
    */
    this(RenderingDevice device, ShaderDescriptor desc) {
        super(device);
        this.desc = ShaderDescriptor(
            stage: desc.stage,
            samplerCount: desc.samplerCount,
            uniformCount: desc.uniformCount,
        );

        auto createInfo = desc.toSDLShaderCreateInfo();
        handle_ = SDL_CreateGPUShader(gpuHandle, &createInfo);
    }
}

/**
    A shader stage.
*/
enum ShaderStage : SDL_GPUShaderStage {
    vertex = SDL_GPUShaderStage.SDL_GPU_SHADERSTAGE_VERTEX,
    fragment = SDL_GPUShaderStage.SDL_GPU_SHADERSTAGE_FRAGMENT,
}

/**
    Descriptor used to create a shader.
*/
struct ShaderDescriptor {

    /**
        The stage of the shader.
    */
    ShaderStage stage;

    /**
        The shader's data.
    */
    ubyte[] data;

    /**
        The entrypoint of the shader.
    */
    string entrypoint;

    /**
        The amount of samplers the shader uses.
    */
    uint samplerCount;
    
    /**
        The amount of uniforms the shader uses.
    */
    uint uniformCount;

    /**
        Converts this descriptor to its SDL equivalent.
    */
    SDL_GPUShaderCreateInfo toSDLShaderCreateInfo() {
        return SDL_GPUShaderCreateInfo(
            code_size: data.length,
            code: data.ptr,
            entrypoint: entrypoint.ptr,
            format: SDL_SHADER_FORMAT,
            stage: stage
        );
    }
}
