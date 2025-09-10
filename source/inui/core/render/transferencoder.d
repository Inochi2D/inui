/**
    Renderer Transfer Encoder

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.render.transferencoder;
import inui.core.render.cmdbuffer;
import inui.core.render.device;
import inui.core.render.texture;
import inui.core.render.buffer;
import nulib;
import numem;
import sdl.gpu;

/**
    Encodes transfer commands
*/
class TransferCommandEncoder : CommandEncoder {
private:
@nogc:
    SDL_GPUCopyPass* handle_;

public:
    this(CommandBuffer parent, SDL_GPUCopyPass* pass) {
        super(parent);
        this.handle_ = pass;
    }

    /**
        Copies texture data from a staging buffer to a texture.

        Params:
            target =        The target texture to copy data to.
            source =        The source buffer to copy texture data from.
            offset =        Offset into the buffer to start reading
            pixelsPerRow =  The amount of pixels that make up one row (width) of the texture.
            mipLevel =      The mipmap level to upload to.
        
        Notes:
            The $(D source) buffer must be of the $(D staging) type.
    */
    void copyBufferToTexture(Texture2D target, Buffer source, uint offset, uint pixelsPerRow, uint mipLevel = 0) {
        if (source.type != BufferType.staging)
            return;

        auto sourceInfo = SDL_GPUTextureTransferInfo(
            cast(SDL_GPUTransferBuffer*)source.handle,
            offset,
            pixelsPerRow,
            pixelsPerRow*target.height
        );
        auto targetInfo = SDL_GPUTextureRegion(
            target.handle,
            mipLevel,
            0,
            0,
            0,
            0,
            target.width,
            target.height,
            1
        );
        SDL_UploadToGPUTexture(handle_, &sourceInfo, &targetInfo, true);
    }

    /**
        Copies bytes from a staging buffer to a GPU buffer.

        Params:
            target =        The target buffer to copy data to.
            source =        The source buffer to copy texture data from.
            srcOffset =     Offset into the source to read from.
            dstOffset =     Offset into the target to write to.
            length =        Length of data to copy, in bytes.
        
        Notes:
            The $(D target) must be a non-staging buffer.
    */
    void copyBufferToBuffer(Buffer target, Buffer source, uint srcOffset, uint dstOffset, uint length) {
        if (target.type == BufferType.staging)
            return;
        
        if (source.type == BufferType.staging) {
            auto sourceInfo = SDL_GPUTransferBufferLocation(
                cast(SDL_GPUTransferBuffer*)source.handle,
                srcOffset
            );
            auto targetInfo = SDL_GPUBufferRegion(
                cast(SDL_GPUBuffer*)target.handle,
                dstOffset,
                length
            );
            SDL_UploadToGPUBuffer(handle_, &sourceInfo, &targetInfo, true);
            return;
        }

        auto sourceInfo = SDL_GPUBufferLocation(
            cast(SDL_GPUBuffer*)source.handle,
            srcOffset
        );
        auto targetInfo = SDL_GPUBufferLocation(
            cast(SDL_GPUBuffer*)target.handle,
            dstOffset
        );
        SDL_CopyGPUBufferToBuffer(handle_, &sourceInfo, &targetInfo, length, true);
        return;
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
        SDL_EndGPUCopyPass(handle_);
        super.end();
    }
}