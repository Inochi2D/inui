/**
    Renderer Swapchain

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.render.swapchain;
import inui.core.render.cmdbuffer;
import inui.core.render.texture;
import inui.core.render.device;
import inui.core.render.eh;
import sdl.video;
import sdl.gpu;
import nulib;
import numem;

/**
    Presentation modes for swapchain.
*/
enum PresentMode : SDL_GPUPresentMode {
    immediate = SDL_GPUPresentMode.SDL_GPU_PRESENTMODE_IMMEDIATE,
    mailbox = SDL_GPUPresentMode.SDL_GPU_PRESENTMODE_MAILBOX,
    vsync = SDL_GPUPresentMode.SDL_GPU_PRESENTMODE_VSYNC,
}

/**
    GPU Swapchain.
*/
class Swapchain : GPUObject {
private:
@nogc:
    SDL_GPUSwapchainComposition compositionFlags = SDL_GPUSwapchainComposition.SDL_GPU_SWAPCHAINCOMPOSITION_SDR;
    PresentMode presentMode = PresentMode.mailbox;
    SDL_Window* handle_;

public:

    /**
        The handle of the swapchain.
    */
    final @property SDL_Window* handle() => handle_;

    /**
        The texture format of swapchain textures.
    */
    final @property TextureFormat textureFormat() => cast(TextureFormat)SDL_GetGPUSwapchainTextureFormat(gpuHandle, handle_);

    /**
        The presentation mode for the swapchain.
    */
    final @property PresentMode presentationMode() => presentMode;
    final @property Swapchain presentationMode(PresentMode value) {
        presentMode = value;
        return this;
    }

    /**
        Whether the swapchain uses HDR.
    */
    final @property bool isHDR() => 
        compositionFlags >= SDL_GPUSwapchainComposition.SDL_GPU_SWAPCHAINCOMPOSITION_HDR_EXTENDED_LINEAR;
    final @property Swapchain isHDR(bool value) {
        compositionFlags = value ? 
            (isLinear ? SDL_GPUSwapchainComposition.SDL_GPU_SWAPCHAINCOMPOSITION_HDR_EXTENDED_LINEAR : SDL_GPUSwapchainComposition.SDL_GPU_SWAPCHAINCOMPOSITION_HDR10_ST2084) :
            (isLinear ? SDL_GPUSwapchainComposition.SDL_GPU_SWAPCHAINCOMPOSITION_SDR_LINEAR : SDL_GPUSwapchainComposition.SDL_GPU_SWAPCHAINCOMPOSITION_SDR);
        SDL_SetGPUSwapchainParameters(gpuHandle, handle_, compositionFlags, presentMode);
        return this;
    }

    /**
        Whether the swapchain does sRGB to linear conversion.
    */
    final @property bool isLinear() => 
        compositionFlags == SDL_GPUSwapchainComposition.SDL_GPU_SWAPCHAINCOMPOSITION_SDR_LINEAR || 
        compositionFlags == SDL_GPUSwapchainComposition.SDL_GPU_SWAPCHAINCOMPOSITION_HDR_EXTENDED_LINEAR;
    final @property Swapchain isLinear(bool value) {
        compositionFlags = compositionFlags < SDL_GPUSwapchainComposition.SDL_GPU_SWAPCHAINCOMPOSITION_HDR_EXTENDED_LINEAR ? 
            (value ? SDL_GPUSwapchainComposition.SDL_GPU_SWAPCHAINCOMPOSITION_SDR_LINEAR : SDL_GPUSwapchainComposition.SDL_GPU_SWAPCHAINCOMPOSITION_SDR) :
            (value ? SDL_GPUSwapchainComposition.SDL_GPU_SWAPCHAINCOMPOSITION_HDR_EXTENDED_LINEAR : SDL_GPUSwapchainComposition.SDL_GPU_SWAPCHAINCOMPOSITION_HDR10_ST2084);
        SDL_SetGPUSwapchainParameters(gpuHandle, handle_, compositionFlags, presentMode);
        return this;
    }

    /**
        Whether the HDR is supported by the swapchain's window.
    */
    final @property bool supportsHDR() =>
            SDL_WindowSupportsGPUSwapchainComposition(gpuHandle, handle_, SDL_GPUSwapchainComposition.SDL_GPU_SWAPCHAINCOMPOSITION_HDR_EXTENDED_LINEAR) ||
            SDL_WindowSupportsGPUSwapchainComposition(gpuHandle, handle_, SDL_GPUSwapchainComposition.SDL_GPU_SWAPCHAINCOMPOSITION_HDR10_ST2084);

    // Destructor
    ~this() {
        SDL_ReleaseWindowFromGPUDevice(gpuHandle, handle_);
    }

    /**
        Constructs a new swapchain for the given device and
        window.
    */
    this(RenderingDevice device, SDL_Window* window) {
        super(device);
        this.handle_ = window;

        enforceSDL(SDL_ClaimWindowForGPUDevice(gpuHandle, handle_));
    }

    /**
        Applies the current settings of the swapchain.
    */
    void applySettings() {
        SDL_SetGPUSwapchainParameters(gpuHandle, handle_, compositionFlags, presentMode);
    }

    /**
        Claims a texture for the given command buffer.

        Params:
            buffer = The command buffer to claim the texture for.
        
        Returns:
            The next texture of the swapchain.
    */
    Texture2D claimNext(CommandBuffer buffer) {
        SDL_GPUTexture* tex;
        uint width;
        uint height;
        bool succeeded = SDL_WaitAndAcquireGPUSwapchainTexture(buffer.handle, handle_, &tex, &width, &height);
        return succeeded && tex ? 
            nogc_new!Texture2D(device, tex, device.swapchain.textureFormat, width, height) :
            null;
    }
}