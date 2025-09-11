/**
    Staging Buffer Manager

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.render.staging;
import inui.core.render.device;
import inui.core.render.buffer;
import inui.core.render.texture;
import sdl.gpu;
import numem;
import nulib;

/**
    A staging buffer which a device records requests to.

    These requests are then uploaded to the GPU when the buffer
    is refreshed.
*/
class StagingBuffer : GPUObject {
private:
@nogc:
    Buffer texTxrBuffer_;
    Buffer bufTxrBuffer_;
    weak_vector!TxrRequest requests_;

public:

    // Destructor
    ~this() {
        nogc_delete(texTxrBuffer_);
        nogc_delete(bufTxrBuffer_);
    }

    /**
        Constructs a new staging buffer.

        Params:
            device = The owning device.
    */
    this(RenderingDevice device) {
        super(device);

        this.texTxrBuffer_ = nogc_new!Buffer(
            device, 
            BufferDescriptor(
                BufferType.staging, 
                SDL_CalculateGPUTextureFormatSize(TextureFormat.rgba32f, 4096, 4096, 1)
            )
        );
        this.bufTxrBuffer_ = nogc_new!Buffer(
            device,
            BufferDescriptor(
                BufferType.staging,
                12_582_912 
            )
        );
    }

    /**
        Enqueues a staging request for the given texture.

        Params:
            texture =   The texture.
            data =      The data to upload to the texture.
            mipLevel =  The mipmap level to upload the data to.
    */
    void enqueue(Texture2D texture, void[] data, uint mipLevel) {
        requests_ ~= TxrRequest(
            target: texture, 
            mipLevel: mipLevel, 
            data: data
        );
    }

    /**
        Enqueues a staging request for the given buffer.

        Params:
            buffer =    The buffer.
            data =      The data to upload to the buffer.
            offset =    The offset to upload the data at.
    */
    void enqueue(Buffer buffer, void[] data, uint offset) {
        if (buffer.type == BufferType.staging) {
            buffer.set(data);
            return;
        }

        requests_ ~= TxrRequest(
            target: buffer, 
            offset: offset, 
            data: data
        );
    }

    /**
        Flushes the buffer, submitting all requests.
    */
    void flush() {
        if (requests_.length == 0)
            return;

        import nulib.math : min, max;

        SDL_GPUCommandBuffer* cmdbuf = SDL_AcquireGPUCommandBuffer(gpuHandle);
        SDL_GPUCopyPass* pass = SDL_BeginGPUCopyPass(cmdbuf);

        foreach(TxrRequest request; requests_) {
            if (!request.target || request.data.length == 0)
                continue;

            // Texture2D
            if (auto texture = cast(Texture2D)request.target) {
                if (texture.handle is null)
                    continue;

                texTxrBuffer_.set(request.data);
                auto sourceInfo = SDL_GPUTextureTransferInfo(
                    cast(SDL_GPUTransferBuffer*)texTxrBuffer_.handle,
                    0,
                    texture.width,
                    texture.width*texture.height
                );
                auto targetInfo = SDL_GPUTextureRegion(
                    texture.handle,
                    request.mipLevel,
                    0,
                    0,
                    0,
                    0,
                    texture.width,
                    texture.height,
                    1
                );

                SDL_UploadToGPUTexture(pass, &sourceInfo, &targetInfo, false);
            }
            
            // Buffer
            if (auto buffer = cast(Buffer)request.target) {
                if (buffer.handle is null)
                    continue;

                bufTxrBuffer_.set(request.data);

                size_t copyPasses = max(1, request.data.length/bufTxrBuffer_.size);
                foreach(i; 0..copyPasses) {
                    size_t start = (bufTxrBuffer_.size * i);
                    size_t length = min(bufTxrBuffer_.size, request.data.length-start);

                    auto sourceInfo = SDL_GPUTransferBufferLocation(
                        cast(SDL_GPUTransferBuffer*)bufTxrBuffer_.handle,
                        cast(uint)start
                    );
                    auto targetInfo = SDL_GPUBufferRegion(
                        cast(SDL_GPUBuffer*)buffer.handle,
                        cast(uint)start+request.offset,
                        cast(uint)length
                    );
                    SDL_UploadToGPUBuffer(pass, &sourceInfo, &targetInfo, false);
                }
            }
        }

        SDL_EndGPUCopyPass(pass);
        SDL_SubmitGPUCommandBuffer(cmdbuf);
        requests_.clear();
    }
}

private
struct TxrRequest {
    GPUObject target;
    uint offset;
    uint mipLevel;
    void[] data;
}