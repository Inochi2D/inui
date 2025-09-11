/**
    Inui ImGui Context

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.imgui;
import inui.core.window;
import inui.core.fonts;
import inui.core.utils;
import inui.core.render;
import inui.image;
import i2d.imgui;
import nulib.math : isFinite;
import inmath;
import numem;
import nulib;
import sdl;
import sdl.misc : SDL_OpenURL;
import sdl.error : SDL_GetError;
import sdl.timer : SDL_DelayPrecise;

import std.stdio : printf;

/**
    ImGui context state.
*/
class IGContext {
private:
    //
    //      UI State
    //
    bool initialized = false;
    ImGuiContext* ctx;
    NativeWindow window;
    SDL_Cursor*[ImGuiMouseCursor.COUNT] cursors;
    SDL_Cursor* lastCursor;
    int mouseButtonsDown;
    int pendingLeaveFrame;
    float lastScale;
    vec2i lastSize;
    vec2 mouseOffset = vec2(0, 0);
    SystemTheme currTheme;
    SystemTheme lastTheme;

    void updateKeyModifiers(ImGuiIO* io, SDL_Keymod sdlKeyMods) nothrow {
        ImGuiIO_AddKeyEvent(io, ImGuiKey.ImGuiMod_Ctrl, (sdlKeyMods & SDL_Keymod.KMOD_CTRL) != 0);
        ImGuiIO_AddKeyEvent(io, ImGuiKey.ImGuiMod_Shift, (sdlKeyMods & SDL_Keymod.KMOD_SHIFT) != 0);
        ImGuiIO_AddKeyEvent(io, ImGuiKey.ImGuiMod_Alt, (sdlKeyMods & SDL_Keymod.KMOD_ALT) != 0);
        ImGuiIO_AddKeyEvent(io, ImGuiKey.ImGuiMod_Super, (sdlKeyMods & SDL_Keymod.KMOD_GUI) != 0);
    }

    void platformNewFrame(ImGuiIO* io, float deltaTime) {
        vec2i windowSize = window.ptSize;
        version(OSX) {
            recti safeArea = window.safeArea;
            io.DisplaySize = ImVec2(safeArea.width, safeArea.height);
        } else {
            io.DisplaySize = ImVec2(windowSize.x, windowSize.y);
        }
        io.DeltaTime = deltaTime;

        if (cursors[igGetMouseCursor()] !is lastCursor) {
            lastCursor = cursors[igGetMouseCursor()];
            SDL_SetCursor(lastCursor);
        }
    }

    void setImeData(ImGuiPlatformImeData* data) {
        if (!data.WantVisible && window.isTextInputActive) {
            window.stopTextInput();
        }

        if (data.WantVisible) {
            window.textArea = recti(
                cast(int)data.InputPos.x, 
                cast(int)data.InputPos.y, 
                1, 
                cast(int)data.InputLineHeight
            );
            window.startTextInput();
        }
    }

    void setupPlatform() {
        import inui.app : Application;

        ImGuiPlatformIO* platformIO = igGetPlatformIO(ctx);

        io.BackendPlatformUserData = cast(void*)this;
        io.BackendPlatformName = "Inochi2D UI Lib";
        io.BackendFlags |= ImGuiBackendFlags.HasMouseCursors;
        platformIO.Platform_SetClipboardTextFn = &__Inui_SetClipboardText;
        platformIO.Platform_GetClipboardTextFn = &__Inui_GetClipboardText;
        platformIO.Platform_SetImeDataFn = &__Inui_PlatformSetImeData;
        platformIO.Platform_OpenInShellFn = (ImGuiContext*, const char* url) {

            return SDL_OpenURL(url) == 0; 
        };

        platformIO.Platform_GetWindowDpiScale = (ImGuiViewport* vp) {
            return (cast(IGContext)vp.PlatformHandle).window.scale;
        };

        // Load mouse cursors
        this.cursors[ImGuiMouseCursor.Arrow] = SDL_CreateSystemCursor(SDL_SystemCursor.SDL_SYSTEM_CURSOR_DEFAULT);
        this.cursors[ImGuiMouseCursor.TextInput] = SDL_CreateSystemCursor(SDL_SystemCursor.SDL_SYSTEM_CURSOR_TEXT);
        this.cursors[ImGuiMouseCursor.ResizeAll] = SDL_CreateSystemCursor(SDL_SystemCursor.SDL_SYSTEM_CURSOR_MOVE);
        this.cursors[ImGuiMouseCursor.ResizeNS] = SDL_CreateSystemCursor(SDL_SystemCursor.SDL_SYSTEM_CURSOR_NS_RESIZE);
        this.cursors[ImGuiMouseCursor.ResizeEW] = SDL_CreateSystemCursor(SDL_SystemCursor.SDL_SYSTEM_CURSOR_EW_RESIZE);
        this.cursors[ImGuiMouseCursor.ResizeNESW] = SDL_CreateSystemCursor(SDL_SystemCursor.SDL_SYSTEM_CURSOR_NESW_RESIZE);
        this.cursors[ImGuiMouseCursor.ResizeNWSE] = SDL_CreateSystemCursor(SDL_SystemCursor.SDL_SYSTEM_CURSOR_NWSE_RESIZE);
        this.cursors[ImGuiMouseCursor.Hand] = SDL_CreateSystemCursor(SDL_SystemCursor.SDL_SYSTEM_CURSOR_POINTER);
        this.cursors[ImGuiMouseCursor.NotAllowed] = SDL_CreateSystemCursor(SDL_SystemCursor.SDL_SYSTEM_CURSOR_NOT_ALLOWED);
        this.cursors[ImGuiMouseCursor.Wait] = SDL_CreateSystemCursor(SDL_SystemCursor.SDL_SYSTEM_CURSOR_WAIT);
        this.cursors[ImGuiMouseCursor.Progress] = SDL_CreateSystemCursor(SDL_SystemCursor.SDL_SYSTEM_CURSOR_PROGRESS);
        
        igSetCurrentContext(ctx);
        ImGuiViewport* viewport = igGetMainViewport();
        viewport.PlatformHandle = cast(void*)this;
        viewport.PlatformHandleRaw = window.nativeHandle;
    }

    void shutdownPlatform() {
        foreach(cursor; this.cursors)
            SDL_DestroyCursor(cursor);

        io.BackendPlatformUserData = null;
        io.BackendPlatformName = null;
        io.BackendFlags = ImGuiBackendFlags.None;
    }

    //
    //      GL State
    //
    nstring g_RenderName;
    CommandQueue g_Queue;
    CommandBuffer g_Cmds;
    RenderCommandEncoder g_RenderPass;
    Buffer g_IdxBuffer;
    Buffer g_VtxBuffer;
    Buffer g_Uniforms;
    Sampler g_Sampler;
    RenderPipeline g_Pipeline;

    void createDeviceObjects() {
        g_Queue = window.renderer.createQueue();
        g_Uniforms = window.renderer.createBuffer(
            BufferDescriptor(
                BufferType.uniform, 
                mat4.sizeof
            )
        );
        g_Sampler = window.renderer.createSampler(
            SamplerDescriptor(
                TextureFilter.linear,
                TextureFilter.linear,
                TextureWrap.clampToEdge,
                TextureWrap.clampToEdge,
                1      
            )
        );

        g_VtxBuffer = window.renderer.createBuffer(BufferDescriptor(
            BufferType.vertex,
            ushort.max * ImDrawVert.sizeof
        ));

        g_IdxBuffer = window.renderer.createBuffer(BufferDescriptor(
            BufferType.index,
            ushort.max * ImDrawIdx.sizeof
        ));

        version(OSX) {
            Shader vertexShader = window.renderer.createShader(
                ShaderDescriptor(
                    ShaderStage.vertex, 
                    cast(ubyte[])import("shaders/ui.metal"), 
                    "vertex_main", 
                    1, 
                    1
                )
            );
            Shader fragmentShader = window.renderer.createShader(
                ShaderDescriptor(
                    ShaderStage.fragment, 
                    cast(ubyte[])import("shaders/ui.metal"), 
                    "fragment_main", 
                    1, 
                    1
                )
            );
        } else {
            Shader vertexShader = window.renderer.createShader(
                ShaderDescriptor(
                    ShaderStage.vertex, 
                    cast(ubyte[])import("shaders/ui.vert.spv"), 
                    "main",
                    0,
                    1
                )
            );
            Shader fragmentShader = window.renderer.createShader(
                ShaderDescriptor(
                    ShaderStage.fragment, 
                    cast(ubyte[])import("shaders/ui.frag.spv"), 
                    "main", 
                    1, 
                    0
                )
            );
        }

        g_Pipeline = nogc_new!RenderPipeline(RenderPipelineDescriptor(
            vertexShader,
            fragmentShader,
            [
                VertexBufferDescriptor(0, ImDrawVert.sizeof, [
                    VertexAttributeDescriptor(0, VertexFormat.FLOAT2),
                    VertexAttributeDescriptor(8, VertexFormat.FLOAT2),
                    VertexAttributeDescriptor(16, VertexFormat.UBYTE4_NORM),
                ])
            ],
            [window.renderer.swapchain.textureFormat],
            TextureFormat.none
        ));
    }

    void destroyDeviceObjects() {
        g_Pipeline.release();
        g_Sampler.release();
        g_Uniforms.release();
        g_VtxBuffer.release();
        g_IdxBuffer.release();
    }

    void setupRenderState(ImDrawData* drawData, rect fbArea) {

        // Setup viewport, orthographic projection matrix
        // Our visible imgui space lies from draw_data.DisplayPos (top left) to draw_data.DisplayPos+data_data.DisplaySize (bottom right). DisplayPos is (0,0) for single viewport apps.
        g_Uniforms.set([mat4.orthographic01(
            drawData.DisplayPos.x,
            drawData.DisplayPos.x + drawData.DisplaySize.x,
            drawData.DisplayPos.y + drawData.DisplaySize.y,
            drawData.DisplayPos.y,
            0, 1
        ).transposed()]);
        g_RenderPass.viewport = fbArea;
    }

    void render(ImDrawData* drawData) {
        
        // Avoid rendering when minimized, scale coordinates for retina displays (screen coordinates != framebuffer coordinates)
        float fbWidth = drawData.DisplaySize.x;
        float fbHeight = drawData.DisplaySize.y;
        if (fbWidth <= 0 || fbHeight <= 0)
            return;

        vec2i windowSize = window.ptSize;
        rect fbArea = rect(windowSize.x-fbWidth, windowSize.y-fbHeight, fbWidth, fbHeight);

        // Will project scissor/clipping rectangles into framebuffer space
        ImVec2 clip_off = ImVec2(
            drawData.DisplayPos.x+fbArea.x,
            drawData.DisplayPos.y+fbArea.y
        ); // (0,0) unless using multi-viewports

        ImVec2 clip_scale = ImVec2(
            drawData.FramebufferScale.x,
            drawData.FramebufferScale.y
        ); // (1,1) unless using retina display which are often (2,2)

        // Fill buffers.
        if (g_VtxBuffer.size < drawData.TotalVtxCount * ImDrawVert.sizeof)
            g_VtxBuffer.resize(cast(uint)(drawData.TotalVtxCount * ImDrawVert.sizeof));
        if (g_IdxBuffer.size < drawData.TotalIdxCount * ImDrawIdx.sizeof)
            g_IdxBuffer.resize(cast(uint)(drawData.TotalIdxCount * ImDrawIdx.sizeof));
        
        uint vtxI = 0;
        uint idxI = 0;
        foreach(n; 0..drawData.CmdListsCount) {
            const ImDrawList* cmd_list = drawData.CmdLists[n];
            g_VtxBuffer.set(cast(void[])cmd_list.VtxBuffer.Data[0..cmd_list.VtxBuffer.Size], vtxI);
            g_IdxBuffer.set(cast(void[])cmd_list.IdxBuffer.Data[0..cmd_list.IdxBuffer.Size], idxI);
            vtxI += (cmd_list.VtxBuffer.Size * ImDrawVert.sizeof);
            idxI += (cmd_list.IdxBuffer.Size * ImDrawIdx.sizeof);
        }

        if (drawData.Textures !is null) {
            foreach(ImTextureData* texture; drawData.Textures.Data[0..drawData.Textures.size()]) {
                if (texture.Status != ImTextureStatus.OK)
                    this.updateTexture(texture);
            }
        }

        window.renderer.flush();

        g_Cmds = g_Queue.newCommandBuffer();
        if (auto swapchainTexture = g_Cmds.acquireSwapchainTexture()) {

            // Setup desired state
            g_RenderPass = g_Cmds.beginRenderPass(RenderPassDescriptor([
                    ColorAttachmentDescriptor(swapchainTexture, LoadAction.clear, StoreAction.store, vec4(0, 0, 0, 0))
                ]
            ));

            g_RenderPass.setRenderPipeline(g_Pipeline);
            g_RenderPass.cullMode = CullMode.none;
            g_RenderPass.srcColorFactor = BlendFactor.srcAlpha;
            g_RenderPass.srcAlphaFactor = BlendFactor.srcAlpha;
            g_RenderPass.dstColorFactor = BlendFactor.oneMinusSrcAlpha;
            g_RenderPass.dstAlphaFactor = BlendFactor.oneMinusSrcAlpha;
            this.setupRenderState(drawData, fbArea);

            // Render command lists
            vtxI = 0;
            idxI = 0;
            for (int n = 0; n < drawData.CmdListsCount; n++) {
                const ImDrawList* cmd_list = drawData.CmdLists[n];

                for (int cmd_i = 0; cmd_i < cmd_list.CmdBuffer.Size; cmd_i++) {
                    const(ImDrawCmd)* pcmd = &cmd_list.CmdBuffer.Data[cmd_i];
                    if (pcmd.UserCallback != null) {
                        // User callback, registered via ImDrawList::AddCallback()
                        // (ImDrawCallback_ResetRenderState is a special callback value used by the user to request the renderer to reset render state.)
                        if (pcmd.UserCallback == cast(ImDrawCallback)(-1))
                            this.setupRenderState(drawData, fbArea);
                        else
                            pcmd.UserCallback(cmd_list, pcmd);
                    } else {
                        // Project scissor/clipping rectangles into framebuffer space
                        ImVec4 clipRect;
                        clipRect.x = (pcmd.ClipRect.x + clip_off.x) * clip_scale.x;
                        clipRect.y = (pcmd.ClipRect.y + clip_off.y) * clip_scale.y;
                        clipRect.z = (pcmd.ClipRect.z + clip_off.x) * clip_scale.x;
                        clipRect.w = (pcmd.ClipRect.w + clip_off.y) * clip_scale.y;

                        if (clipRect.x < fbWidth && clipRect.y < fbHeight && clipRect.z >= 0.0f && clipRect.w >= 0.0f) {
                            // Apply scissor/clipping rectangle
                            g_RenderPass.scissor = recti(
                                cast(int)clipRect.x, 
                                cast(int)clipRect.y, 
                                cast(int)(clipRect.z - clipRect.x), 
                                cast(int)(clipRect.w - clipRect.y)
                            );

                            // Will not validate in Metal.
                            if (pcmd.ElemCount == 0)
                                continue;

                            Texture2D texture = cast(Texture2D)cast(void*)ImTextureRef_GetTexID(cast(ImTextureRef*)&pcmd.TexRef);

                            // Bind texture, Draw
                            g_RenderPass.setFragmentTexture(0, texture, g_Sampler);
                            g_RenderPass.setVertexBuffer(0, g_Uniforms);
                            g_RenderPass.setVertexBuffer(0, g_VtxBuffer, vtxI);
                            g_RenderPass.setIndexBuffer(g_IdxBuffer, ImDrawIdx.sizeof == 2 ? IndexType.uint16 : IndexType.uint32, idxI);
                            g_RenderPass.drawIndexed(pcmd.ElemCount, pcmd.IdxOffset, pcmd.VtxOffset);
                        }
                    }
                }
                            
                vtxI += (cmd_list.VtxBuffer.Size * ImDrawVert.sizeof);
                idxI += (cmd_list.IdxBuffer.Size * ImDrawIdx.sizeof);
            }

            g_RenderPass.end();
            g_Queue.submit(g_Cmds);
            g_Queue.awaitCompletion();
        } else {
            g_Cmds.cancel();
        }
        
        SDL_DelayPrecise(100_000);
    }

    void updateTexture(ImTextureData* texture) {
        if (texture.Status == ImTextureStatus.WantCreate) {
            void[] pixels = (cast(void*)ImTextureData_GetPixels(texture))[0..ImTextureData_GetSizeInBytes(texture)];
            Texture2D toUpdate = window.renderer.createTexture(
                TextureDescriptor(TextureFormat.rgba8Unorm, texture.Width, texture.Height, 1)
            );

            toUpdate.upload(pixels, 0);
            ImTextureData_SetTexID(texture, cast(ImTextureID)cast(void*)toUpdate);
            ImTextureData_SetStatus(texture, ImTextureStatus.OK);
        } else if (texture.Status == ImTextureStatus.WantUpdates) {
            void[] pixels = (cast(void*)ImTextureData_GetPixels(texture))[0..ImTextureData_GetSizeInBytes(texture)];
            Texture2D toUpdate = cast(Texture2D)(cast(void*)ImTextureData_GetTexID(texture));

            toUpdate.upload(pixels, 0);
            ImTextureData_SetStatus(texture, ImTextureStatus.OK);
        } else if (texture.Status == ImTextureStatus.WantDestroy && texture.UnusedFrames > 0) {
            Texture2D toUpdate = cast(Texture2D)(cast(void*)ImTextureData_GetTexID(texture));
            toUpdate.release();

            ImTextureData_SetTexID(texture, 0);
            ImTextureData_SetStatus(texture, ImTextureStatus.Destroyed);
        }
    }

    void setupRendering() {
        import std.format : format;

        // We can honor the ImDrawCmd::VtxOffset field, allowing for large meshes.
        g_RenderName = "InRender";
        io.BackendFlags |= cast(int) ImGuiBackendFlags.RendererHasVtxOffset;
        io.BackendFlags |= cast(int) ImGuiBackendFlags.RendererHasTextures;
        io.BackendRendererName = g_RenderName.ptr;
        this.createDeviceObjects();
    }

    void shutdownRendering() {
        this.destroyDeviceObjects();
    }

    //
    //      FONTS
    //
    ImFontLoader sharedFontLoader;
    void setupFonts() {
        sharedFontLoader.Name = "Hairetsu";
        sharedFontLoader.LoaderInit = (ImFontAtlas* atlas) {
            atlas.FontLoaderName = "Hairetsu";
            atlas.TexGlyphPadding = 2;
            return true;
        };
        sharedFontLoader.FontSrcContainsGlyph = (ImFontAtlas* atlas, ImFontConfig* src, ImWchar code) {
            return IGContext.glyphManager.hasCodepoint(code);
        };
        sharedFontLoader.FontBakedInit = (ImFontAtlas* atlas, ImFontConfig* src, ImFontBaked* baked, void* lddata) {
            return true;
        };
        sharedFontLoader.FontBakedLoadGlyph = (ImFontAtlas* atlas, ImFontConfig* src, ImFontBaked* baked, void* lddata, ImWchar code, ImFontGlyph* dst) {
            GlyphSource gsrc = IGContext.glyphManager.getGlyphSourceFor(code);
            if (!gsrc)
                return false;

            if (auto msrc = IGContext.glyphManager.mainSource) {
                size_t lowestLength = min(src.Name.length, msrc.name.length);
                src.Name[0..$] = '\0';
                src.Name[0..lowestLength] = msrc.name[0..lowestLength];
            }

            uint glyphIdx = gsrc.getGlyphIndex(code);
            Bitmap bitmap = gsrc.rasterize(glyphIdx);
            SourceMetrics smetrics = gsrc.metrics;
            Metrics metrics = gsrc.getMetricsFor(glyphIdx);
            if (!src.MergeMode) {
                baked.Ascent = ceil(smetrics.ascender.x);
                baked.Descent = ceil(smetrics.descender.x);
            }
            
            // Basic data.
            dst.Codepoint = code;
            dst.AdvanceX = metrics.advance.x;
            if (bitmap.data.length == 0)
                return true;

            import hairetsu.raster.coverage : HaCoverageMask;
            enum int padding = HaCoverageMask.MASK_PADDING;
            
            // Copy bitmap data.
            bitmap.crop(padding, padding, bitmap.width-padding, bitmap.height-padding);
            if (bitmap.width == 0 || bitmap.height == 0) {
                bitmap.free();
                return false;
            }

            // Pack glyph.
            ImFontAtlasRectId packId = igImFontAtlasPackAddRect(atlas, bitmap.width, bitmap.height);
            if (packId == -1)
                return false;
            
            ImTextureRect* packRect = igImFontAtlasPackGetRect(atlas, packId);
            rect renderRect = gsrc.getRenderRectFor(
                glyphIdx, 
                baked.Size
            );
            
            // Generate and add glyph.
            dst.X0 = renderRect.left;
            dst.Y0 = renderRect.top;
            dst.X1 = renderRect.left + bitmap.width;
            dst.Y1 = renderRect.top + bitmap.height;
            dst.Visible = true;
            dst.Colored = false;
            dst.PackId = packId;
            igImFontAtlasBakedSetFontGlyphBitmap(
                atlas,
                baked,
                src,
                dst,
                packRect,
                cast(char*)bitmap.data.ptr,
                ImTextureFormat.Alpha8,
                bitmap.width
            );
            bitmap.free();
            return true;
        };

        io.Fonts.FontLoader = &sharedFontLoader;
        igGetStyle().FontSizeBase = 14;
    }

    static @property GlyphManager glyphManager() {
        import inui.app : Application;
        return Application.thisApp.glyphManager;
    }

    //
    //      General Implementation
    //
    void create() {
        import inui.app : Application;

        this.lastSize = window.ptSize;
        this.lastScale = window.scale;
        this.ctx = igCreateContext();
        igSetCurrentContext(ctx);

        io.ConfigFlags |= ImGuiConfigFlags.DockingEnable;
        io.ConfigWindowsResizeFromEdges = true;
        io.ConfigWindowsMoveFromTitleBarOnly = true;
        io.ConfigInputTextCursorBlink = true;
        version(OSX) io.ConfigMacOSXBehaviors = true;

        this.setupPlatform();
        this.setupRendering();
        this.setupFonts();
        this.updateSystemColors();

        // TODO: This breaks ?
        // io.IniFilename = null;
        // string ini = Application.thisApp.settings.get!string("imgui", null);
        // if (ini)
        //     igLoadIniSettingsFromMemory(ini.ptr, ini.length);
    }

    void shutdown() {
        this.shutdownRendering();
        this.shutdownPlatform();
        igDestroyContext(ctx);
    }

    void updateSystemColors() {
        currTheme = window.systemTheme;
        if (lastTheme != currTheme) {
            lastTheme = currTheme;
            this.applySystemColorScheme();
        }
    }

    void applySystemColorScheme() {
        if (currTheme == SystemTheme.dark)    
            igStyleColorsDark(&ctx.Style);
        else
            igStyleColorsLight(&ctx.Style);

        ctx.Style.FramePadding = ImVec2(6, 4);
        ctx.Style.FrameRounding = 6;
        ctx.Style.GrabRounding = 6;
        ctx.Style.FrameBorderSize = 1;
        ctx.Style.TabBarBorderSize = 0;
        ctx.Style.Colors[ImGuiCol.DockingEmptyBg] = ImVec4(0, 0, 0, 0);
        ctx.Style.Colors[ImGuiCol.BorderShadow] = ctx.Style.Colors[ImGuiCol.Border];
        ctx.Style.Colors[ImGuiCol.WindowBg].w = 0.50;
        ctx.Style.Colors[ImGuiCol.TitleBg].w = 0.25;
        ctx.Style.Colors[ImGuiCol.TitleBgCollapsed].w = 0.25;
        ctx.Style.Colors[ImGuiCol.TitleBgActive].w = 0.25;
        ctx.Style.Colors[ImGuiCol.BorderShadow].w = 0.15;
        ctx.Style.Colors[ImGuiCol.Border].w = 0;

        // Apply system color scheme.
        if (window.getColor(ColorStyle.none).isFinite) {
            ImVec4 background = window.getColor(ColorStyle.background).toImGui!ImVec4;
            ImVec4 backgroundHovered = window.getColor(ColorStyle.backgroundHovered).toImGui!ImVec4;
            ImVec4 none = window.getColor(ColorStyle.none).toImGui!ImVec4;
            ImVec4 hovered = window.getColor(ColorStyle.hovered).toImGui!ImVec4;
            ImVec4 pressed = window.getColor(ColorStyle.pressed).toImGui!ImVec4;
            ImVec4 selected = window.getColor(ColorStyle.selected).toImGui!ImVec4;
            ImVec4 tab = window.getColor(ColorStyle.tab).toImGui!ImVec4;
            ImVec4 tabActive = window.getColor(ColorStyle.tabActive).toImGui!ImVec4;
            ImVec4 titlebar = window.getColor(ColorStyle.titlebar).toImGui!ImVec4;
            ImVec4 titlebarActive = window.getColor(ColorStyle.titlebarActive).toImGui!ImVec4;
            ImVec4 link = window.getColor(ColorStyle.link).toImGui!ImVec4;
            ImVec4 text = window.getColor(ColorStyle.text).toImGui!ImVec4;
            ImVec4 textDisabled = window.getColor(ColorStyle.textDisabled).toImGui!ImVec4;
            ImVec4 textSelected = window.getColor(ColorStyle.textSelected).toImGui!ImVec4;

            ctx.Style.Colors[ImGuiCol.Button] = none;
            ctx.Style.Colors[ImGuiCol.ButtonHovered] = hovered;
            ctx.Style.Colors[ImGuiCol.ButtonActive] = pressed;
            ctx.Style.Colors[ImGuiCol.CheckMark] = selected;
            ctx.Style.Colors[ImGuiCol.FrameBg] = background;
            ctx.Style.Colors[ImGuiCol.FrameBgHovered] = backgroundHovered;
            ctx.Style.Colors[ImGuiCol.FrameBgActive] = background;
            ctx.Style.Colors[ImGuiCol.Text] = text;
            ctx.Style.Colors[ImGuiCol.TextDisabled] = textDisabled;
            ctx.Style.Colors[ImGuiCol.TextLink] = link;
            ctx.Style.Colors[ImGuiCol.TextSelectedBg] = textSelected;
            ctx.Style.Colors[ImGuiCol.DragDropTarget] = pressed;
            ctx.Style.Colors[ImGuiCol.NavCursor] = pressed;
            ctx.Style.Colors[ImGuiCol.Header] = background;
            ctx.Style.Colors[ImGuiCol.HeaderHovered] = backgroundHovered;
            ctx.Style.Colors[ImGuiCol.HeaderActive] = backgroundHovered;
            ctx.Style.Colors[ImGuiCol.Separator] = background;
            ctx.Style.Colors[ImGuiCol.SeparatorHovered] = backgroundHovered;
            ctx.Style.Colors[ImGuiCol.SeparatorActive] = backgroundHovered;
            ctx.Style.Colors[ImGuiCol.ResizeGrip] = background;
            ctx.Style.Colors[ImGuiCol.ResizeGripHovered] = backgroundHovered;
            ctx.Style.Colors[ImGuiCol.ResizeGripActive] = backgroundHovered;
            ctx.Style.Colors[ImGuiCol.SliderGrab] = none;
            ctx.Style.Colors[ImGuiCol.SliderGrabActive] = pressed;
            ctx.Style.Colors[ImGuiCol.DockingPreview] = none;
            ctx.Style.Colors[ImGuiCol.Tab] = tab;
            ctx.Style.Colors[ImGuiCol.TabSelected] = tabActive;
            ctx.Style.Colors[ImGuiCol.TabSelectedOverline] = tabActive;
            ctx.Style.Colors[ImGuiCol.TabDimmed] = tab;
            ctx.Style.Colors[ImGuiCol.TabDimmedSelected] = tabActive;
            ctx.Style.Colors[ImGuiCol.TabDimmedSelectedOverline] = tabActive;
            ctx.Style.Colors[ImGuiCol.TabHovered] = tabActive;
            ctx.Style.Colors[ImGuiCol.TitleBg] = titlebar;
            ctx.Style.Colors[ImGuiCol.TitleBgCollapsed] = titlebar;
            ctx.Style.Colors[ImGuiCol.TitleBgActive] = titlebarActive;
        }
    }

public:

    /**
        ImGui IO Handler for this context.
    */
    @property ImGuiIO* io() { return igGetIO(ctx); }

    /**
        Style object
    */
    @property ImGuiStyle* style() { return &ctx.Style; }

    /**
        Destructor
    */
    ~this() {
        this.shutdown();
    }

    /**
        Constructs a new ImGui Context
    */
    this(NativeWindow window) {
        // Load config
        this.window = window;
        this.create();
        this.rescale();
    }

    /**
        Re-scales the window and context.
    */
    void rescale() {       
        ImGuiStyle* style = igGetStyle();
        float scale = window.scale;
        float relScale = scale / lastScale;
        if (relScale == 1)
            return;

        // Rescale windows and fonts.
        igScaleWindowsInViewport(cast(ImGuiViewportP*)igGetMainViewport(), relScale);
        IGContext.glyphManager.scale = scale;
        window.ptSize = vec2i(
            cast(int)(lastSize.x * relScale), 
            cast(int)(lastSize.y * relScale)
        );

        this.lastScale = scale;
        this.lastSize = window.ptSize;
    }

    /**
        Processes input events for the context.
    */
    bool processEvent(const(SDL_Event)* event) {
        switch (event.type) {
            case SDL_EventType.SDL_EVENT_WINDOW_DISPLAY_CHANGED:
                if (event.window.windowID != window.id)
                    return false;
                
                this.rescale();
                return true;
            
            case SDL_EventType.SDL_EVENT_SYSTEM_THEME_CHANGED:
                this.updateSystemColors();
                return true;
            
            case SDL_EventType.SDL_EVENT_WINDOW_RESIZED:
                if (event.window.windowID != window.id)
                    return false;
                
                recti safeArea = window.safeArea;
                lastSize = vec2i(event.window.data1, event.window.data2);
                mouseOffset = vec2(event.window.data1 - safeArea.width, event.window.data2 - safeArea.height);
                return true;

            case SDL_EventType.SDL_EVENT_MOUSE_MOTION:
                if (event.motion.windowID != window.id)
                    return false;
                
                ImVec2 mousePos = { cast(float) event.motion.x - mouseOffset.x, cast(float) event.motion.y - mouseOffset.y };
                ImGuiIO_AddMouseSourceEvent(io,
                    event.motion.which == SDL_TOUCH_MOUSEID ?
                        ImGuiMouseSource.TouchScreen : ImGuiMouseSource.Mouse
                );
                ImGuiIO_AddMousePosEvent(io, mousePos.x, mousePos.y);
                return true;

            case SDL_EventType.SDL_EVENT_MOUSE_WHEEL:
                if (event.motion.windowID != window.id)
                    return false;

                ImVec2 wheel = {cast(float)-event.wheel.x, cast(float) event.wheel.y};
                ImGuiIO_AddMouseSourceEvent(io,
                    event.wheel.which == SDL_TOUCH_MOUSEID ?
                        ImGuiMouseSource.TouchScreen : ImGuiMouseSource.Mouse
                );

                // Calibrated for the magic trackpad.
                version(OSX) ImGuiIO_AddMouseWheelEvent(io, wheel.x*0.05, wheel.y*0.05);
                else ImGuiIO_AddMouseWheelEvent(io, wheel.x, wheel.y);
                return true;

            case SDL_EventType.SDL_EVENT_MOUSE_BUTTON_DOWN:
            case SDL_EventType.SDL_EVENT_MOUSE_BUTTON_UP:
                if (event.motion.windowID != window.id)
                    return false;
                
                int mouseButton = -1;
                if (event.button.button == SDL_MouseButtonFlags.BUTTON_LEFT) {
                    mouseButton = 0;
                }
                if (event.button.button == SDL_MouseButtonFlags.BUTTON_RIGHT) {
                    mouseButton = 1;
                }
                if (event.button.button == SDL_MouseButtonFlags.BUTTON_MIDDLE) {
                    mouseButton = 2;
                }
                if (event.button.button == SDL_MouseButtonFlags.BUTTON_X1) {
                    mouseButton = 3;
                }
                if (event.button.button == SDL_MouseButtonFlags.BUTTON_X2) {
                    mouseButton = 4;
                }
                if (mouseButton == -1)
                    break;

                ImGuiIO_AddMouseSourceEvent(io,
                    event.button.which == SDL_TOUCH_MOUSEID ?
                    ImGuiMouseSource.TouchScreen : 
                    ImGuiMouseSource.Mouse
                );
                ImGuiIO_AddMouseButtonEvent(io,
                    mouseButton,
                    (event.type == SDL_EventType.SDL_EVENT_MOUSE_BUTTON_DOWN)
                );

                this.mouseButtonsDown = 
                    (event.type == SDL_EventType.SDL_EVENT_MOUSE_BUTTON_DOWN) ?
                    (mouseButtonsDown | (1 << mouseButton)) : 
                    (mouseButtonsDown & ~(1 << mouseButton)
                );
                return true;

            case SDL_EventType.SDL_EVENT_TEXT_INPUT:
                if (event.motion.windowID != window.id)
                    return false;
                
                ImGuiIO_AddInputCharactersUTF8(io, event.text.text);
                return true;

            case SDL_EventType.SDL_EVENT_KEY_DOWN:
            case SDL_EventType.SDL_EVENT_KEY_UP:
                if (event.motion.windowID != window.id)
                    return false;

                ImGuiKey key = event.key.key.toImGuiKey();
                if (!key)
                    key = event.key.scancode.toImGuiKey();

                this.updateKeyModifiers(io, cast(SDL_Keymod) event.key.mod);
                ImGuiIO_AddKeyEvent(io, key, (event.type == SDL_EventType.SDL_EVENT_KEY_DOWN));
                ImGuiIO_SetKeyEventNativeData(io, key, event.key.key, event.key.scancode, event.key.scancode);
                return true;

            case SDL_EventType.SDL_EVENT_WINDOW_MOUSE_ENTER:
                if (event.motion.windowID != window.id)
                    return false;
                
                this.pendingLeaveFrame = 0;
                return true;

            case SDL_EventType.SDL_EVENT_WINDOW_MOUSE_LEAVE:
                if (event.motion.windowID != window.id)
                    return false;
                
                this.pendingLeaveFrame = igGetFrameCount() + 1;
                return true;

            case SDL_EventType.SDL_EVENT_WINDOW_FOCUS_GAINED:
            case SDL_EventType.SDL_EVENT_WINDOW_FOCUS_LOST:
                if (event.motion.windowID != window.id)
                    return false;

                ImGuiIO_AddFocusEvent(io, event.type == SDL_EventType.SDL_EVENT_WINDOW_FOCUS_GAINED);
                return true;
            
            default:
                return false;
        }
        return false;
    }

    /**
        Starts rendering a new frame.
    */
    void beginFrame(float deltaTime) {
        this.updateSystemColors();
        this.platformNewFrame(io, deltaTime);
        igNewFrame();
    }

    /**
        Ends the frame and renders it.
    */
    void endFrame() {
        igRender();
        this.render(igGetDrawData());

        // if (io.WantSaveIniSettings) {
        //     import inui.app : Application;

        //     size_t settingsSize;
        //     nstring settings = igSaveIniSettingsToMemory(&settingsSize);
        //     Application.thisApp.settings.set!string("imgui", settings[]);
        //     io.WantSaveIniSettings = false;
        // }
        initialized = true;
    }

    /**
        Makes this ImGui Context current.
    */
    void makeCurrent() {
        igSetCurrentContext(ctx);
    }

    /**
        Refrehshes the font altas for this imgui context.
    */
    void refreshFontAtlas() {
        if (!initialized)
            return;
        
        if (auto fonts = io.Fonts)
            igImFontAtlasBuildClear(fonts);
    }
}


//
//      IMPLEMENTATION DETAILS.
//

private:

extern(C)
IGContext __Inui_GetBackendData(ImGuiContext* ctx) {
    if (!ctx) return null;
    return cast(IGContext)igGetIO(ctx).BackendPlatformUserData;
}

// Gets the text in the clipboard for the window for the given context.
extern(C)
const(char)* __Inui_GetClipboardText(ImGuiContext* ctx) {
    import sdl.clipboard : SDL_GetClipboardText;
    return SDL_GetClipboardText();
}

// Sets the text in the clipboard for the window for the given context.
extern(C)
void __Inui_SetClipboardText(ImGuiContext* ctx, const(char)* text) {
    import sdl.clipboard : SDL_SetClipboardText;
    SDL_SetClipboardText(text);
}

// Sets the IME Data for the window for the given context.
extern(C)
void __Inui_PlatformSetImeData(ImGuiContext* ctx, ImGuiViewport* viewport, ImGuiPlatformImeData* data) {
    if (auto handle = __Inui_GetBackendData(ctx)) {
        handle.setImeData(data);
    }
}

ImGuiKey toImGuiKey(SDL_Keycode keycode) @nogc nothrow {
    switch (keycode) {
        case SDL_Keycode.SDLK_TAB:
            return ImGuiKey.Tab;
        case SDL_Keycode.SDLK_LEFT:
            return ImGuiKey.LeftArrow;
        case SDL_Keycode.SDLK_RIGHT:
            return ImGuiKey.RightArrow;
        case SDL_Keycode.SDLK_UP:
            return ImGuiKey.UpArrow;
        case SDL_Keycode.SDLK_DOWN:
            return ImGuiKey.DownArrow;
        case SDL_Keycode.SDLK_PAGEUP:
            return ImGuiKey.PageUp;
        case SDL_Keycode.SDLK_PAGEDOWN:
            return ImGuiKey.PageDown;
        case SDL_Keycode.SDLK_HOME:
            return ImGuiKey.Home;
        case SDL_Keycode.SDLK_END:
            return ImGuiKey.End;
        case SDL_Keycode.SDLK_INSERT:
            return ImGuiKey.Insert;
        case SDL_Keycode.SDLK_DELETE:
            return ImGuiKey.Delete;
        case SDL_Keycode.SDLK_BACKSPACE:
            return ImGuiKey.Backspace;
        case SDL_Keycode.SDLK_SPACE:
            return ImGuiKey.Space;
        case SDL_Keycode.SDLK_RETURN:
            return ImGuiKey.Enter;
        case SDL_Keycode.SDLK_ESCAPE:
            return ImGuiKey.Escape;
            //case SDL_Keycode.SDLK_APOSTROPHE: return ImGuiKey.Apostrophe;
        case SDL_Keycode.SDLK_COMMA:
            return ImGuiKey.Comma;
            //case SDL_Keycode.SDLK_MINUS: return ImGuiKey.Minus;
        case SDL_Keycode.SDLK_PERIOD:
            return ImGuiKey.Period;
            //case SDL_Keycode.SDLK_SLASH: return ImGuiKey.Slash;
        case SDL_Keycode.SDLK_SEMICOLON:
            return ImGuiKey.Semicolon;
            //case SDL_Keycode.SDLK_EQUALS: return ImGuiKey.Equal;
            //case SDL_Keycode.SDLK_LEFTBRACKET: return ImGuiKey.LeftBracket;
            //case SDL_Keycode.SDLK_BACKSLASH: return ImGuiKey.Backslash;
            //case SDL_Keycode.SDLK_RIGHTBRACKET: return ImGuiKey.RightBracket;
            //case SDL_Keycode.SDLK_GRAVE: return ImGuiKey.GraveAccent;
        case SDL_Keycode.SDLK_CAPSLOCK:
            return ImGuiKey.CapsLock;
        case SDL_Keycode.SDLK_SCROLLLOCK:
            return ImGuiKey.ScrollLock;
        case SDL_Keycode.SDLK_NUMLOCKCLEAR:
            return ImGuiKey.NumLock;
        case SDL_Keycode.SDLK_PRINTSCREEN:
            return ImGuiKey.PrintScreen;
        case SDL_Keycode.SDLK_PAUSE:
            return ImGuiKey.Pause;
        case SDL_Keycode.SDLK_LCTRL:
            return ImGuiKey.LeftCtrl;
        case SDL_Keycode.SDLK_LSHIFT:
            return ImGuiKey.LeftShift;
        case SDL_Keycode.SDLK_LALT:
            return ImGuiKey.LeftAlt;
        case SDL_Keycode.SDLK_LGUI:
            return ImGuiKey.LeftSuper;
        case SDL_Keycode.SDLK_RCTRL:
            return ImGuiKey.RightCtrl;
        case SDL_Keycode.SDLK_RSHIFT:
            return ImGuiKey.RightShift;
        case SDL_Keycode.SDLK_RALT:
            return ImGuiKey.RightAlt;
        case SDL_Keycode.SDLK_RGUI:
            return ImGuiKey.RightSuper;
        case SDL_Keycode.SDLK_APPLICATION:
            return ImGuiKey.Menu;
        case SDL_Keycode.SDLK_0:
            return ImGuiKey.n0;
        case SDL_Keycode.SDLK_1:
            return ImGuiKey.n1;
        case SDL_Keycode.SDLK_2:
            return ImGuiKey.n2;
        case SDL_Keycode.SDLK_3:
            return ImGuiKey.n3;
        case SDL_Keycode.SDLK_4:
            return ImGuiKey.n4;
        case SDL_Keycode.SDLK_5:
            return ImGuiKey.n5;
        case SDL_Keycode.SDLK_6:
            return ImGuiKey.n6;
        case SDL_Keycode.SDLK_7:
            return ImGuiKey.n7;
        case SDL_Keycode.SDLK_8:
            return ImGuiKey.n8;
        case SDL_Keycode.SDLK_9:
            return ImGuiKey.n9;
        case SDL_Keycode.SDLK_A:
            return ImGuiKey.A;
        case SDL_Keycode.SDLK_B:
            return ImGuiKey.B;
        case SDL_Keycode.SDLK_C:
            return ImGuiKey.C;
        case SDL_Keycode.SDLK_D:
            return ImGuiKey.D;
        case SDL_Keycode.SDLK_E:
            return ImGuiKey.E;
        case SDL_Keycode.SDLK_F:
            return ImGuiKey.F;
        case SDL_Keycode.SDLK_G:
            return ImGuiKey.G;
        case SDL_Keycode.SDLK_H:
            return ImGuiKey.H;
        case SDL_Keycode.SDLK_I:
            return ImGuiKey.I;
        case SDL_Keycode.SDLK_J:
            return ImGuiKey.J;
        case SDL_Keycode.SDLK_K:
            return ImGuiKey.K;
        case SDL_Keycode.SDLK_L:
            return ImGuiKey.L;
        case SDL_Keycode.SDLK_M:
            return ImGuiKey.M;
        case SDL_Keycode.SDLK_N:
            return ImGuiKey.N;
        case SDL_Keycode.SDLK_O:
            return ImGuiKey.O;
        case SDL_Keycode.SDLK_P:
            return ImGuiKey.P;
        case SDL_Keycode.SDLK_Q:
            return ImGuiKey.Q;
        case SDL_Keycode.SDLK_R:
            return ImGuiKey.R;
        case SDL_Keycode.SDLK_S:
            return ImGuiKey.S;
        case SDL_Keycode.SDLK_T:
            return ImGuiKey.T;
        case SDL_Keycode.SDLK_U:
            return ImGuiKey.U;
        case SDL_Keycode.SDLK_V:
            return ImGuiKey.V;
        case SDL_Keycode.SDLK_W:
            return ImGuiKey.W;
        case SDL_Keycode.SDLK_X:
            return ImGuiKey.X;
        case SDL_Keycode.SDLK_Y:
            return ImGuiKey.Y;
        case SDL_Keycode.SDLK_Z:
            return ImGuiKey.Z;
        case SDL_Keycode.SDLK_F1:
            return ImGuiKey.F1;
        case SDL_Keycode.SDLK_F2:
            return ImGuiKey.F2;
        case SDL_Keycode.SDLK_F3:
            return ImGuiKey.F3;
        case SDL_Keycode.SDLK_F4:
            return ImGuiKey.F4;
        case SDL_Keycode.SDLK_F5:
            return ImGuiKey.F5;
        case SDL_Keycode.SDLK_F6:
            return ImGuiKey.F6;
        case SDL_Keycode.SDLK_F7:
            return ImGuiKey.F7;
        case SDL_Keycode.SDLK_F8:
            return ImGuiKey.F8;
        case SDL_Keycode.SDLK_F9:
            return ImGuiKey.F9;
        case SDL_Keycode.SDLK_F10:
            return ImGuiKey.F10;
        case SDL_Keycode.SDLK_F11:
            return ImGuiKey.F11;
        case SDL_Keycode.SDLK_F12:
            return ImGuiKey.F12;
        case SDL_Keycode.SDLK_F13:
            return ImGuiKey.F13;
        case SDL_Keycode.SDLK_F14:
            return ImGuiKey.F14;
        case SDL_Keycode.SDLK_F15:
            return ImGuiKey.F15;
        case SDL_Keycode.SDLK_F16:
            return ImGuiKey.F16;
        case SDL_Keycode.SDLK_F17:
            return ImGuiKey.F17;
        case SDL_Keycode.SDLK_F18:
            return ImGuiKey.F18;
        case SDL_Keycode.SDLK_F19:
            return ImGuiKey.F19;
        case SDL_Keycode.SDLK_F20:
            return ImGuiKey.F20;
        case SDL_Keycode.SDLK_F21:
            return ImGuiKey.F21;
        case SDL_Keycode.SDLK_F22:
            return ImGuiKey.F22;
        case SDL_Keycode.SDLK_F23:
            return ImGuiKey.F23;
        case SDL_Keycode.SDLK_F24:
            return ImGuiKey.F24;
        case SDL_Keycode.SDLK_AC_BACK:
            return ImGuiKey.AppBack;
        case SDL_Keycode.SDLK_AC_FORWARD:
            return ImGuiKey.AppForward;
        default:
            return ImGuiKey.None;
    }
}

ImGuiKey toImGuiKey(SDL_Scancode scancode) @nogc nothrow {
    // Keypad doesn't have individual key values in SDL3
    switch (scancode) {
        case SDL_Scancode.SDL_SCANCODE_KP_0:
            return ImGuiKey.Keypad0;
        case SDL_Scancode.SDL_SCANCODE_KP_1:
            return ImGuiKey.Keypad1;
        case SDL_Scancode.SDL_SCANCODE_KP_2:
            return ImGuiKey.Keypad2;
        case SDL_Scancode.SDL_SCANCODE_KP_3:
            return ImGuiKey.Keypad3;
        case SDL_Scancode.SDL_SCANCODE_KP_4:
            return ImGuiKey.Keypad4;
        case SDL_Scancode.SDL_SCANCODE_KP_5:
            return ImGuiKey.Keypad5;
        case SDL_Scancode.SDL_SCANCODE_KP_6:
            return ImGuiKey.Keypad6;
        case SDL_Scancode.SDL_SCANCODE_KP_7:
            return ImGuiKey.Keypad7;
        case SDL_Scancode.SDL_SCANCODE_KP_8:
            return ImGuiKey.Keypad8;
        case SDL_Scancode.SDL_SCANCODE_KP_9:
            return ImGuiKey.Keypad9;
        case SDL_Scancode.SDL_SCANCODE_KP_PERIOD:
            return ImGuiKey.KeypadDecimal;
        case SDL_Scancode.SDL_SCANCODE_KP_DIVIDE:
            return ImGuiKey.KeypadDivide;
        case SDL_Scancode.SDL_SCANCODE_KP_MULTIPLY:
            return ImGuiKey.KeypadMultiply;
        case SDL_Scancode.SDL_SCANCODE_KP_MINUS:
            return ImGuiKey.KeypadSubtract;
        case SDL_Scancode.SDL_SCANCODE_KP_PLUS:
            return ImGuiKey.KeypadAdd;
        case SDL_Scancode.SDL_SCANCODE_KP_ENTER:
            return ImGuiKey.KeypadEnter;
        case SDL_Scancode.SDL_SCANCODE_KP_EQUALS:
            return ImGuiKey.KeypadEqual;
        case SDL_Scancode.SDL_SCANCODE_GRAVE:
            return ImGuiKey.GraveAccent;
        case SDL_Scancode.SDL_SCANCODE_MINUS:
            return ImGuiKey.Minus;
        case SDL_Scancode.SDL_SCANCODE_EQUALS:
            return ImGuiKey.Equal;
        case SDL_Scancode.SDL_SCANCODE_LEFTBRACKET:
            return ImGuiKey.LeftBracket;
        case SDL_Scancode.SDL_SCANCODE_RIGHTBRACKET:
            return ImGuiKey.RightBracket;
        case SDL_Scancode.SDL_SCANCODE_BACKSLASH:
            return ImGuiKey.Backslash;
        case SDL_Scancode.SDL_SCANCODE_SEMICOLON:
            return ImGuiKey.Semicolon;
        case SDL_Scancode.SDL_SCANCODE_APOSTROPHE:
            return ImGuiKey.Apostrophe;
        case SDL_Scancode.SDL_SCANCODE_COMMA:
            return ImGuiKey.Comma;
        case SDL_Scancode.SDL_SCANCODE_PERIOD:
            return ImGuiKey.Period;
        case SDL_Scancode.SDL_SCANCODE_SLASH:
            return ImGuiKey.Slash;
        default:
            return ImGuiKey.None;
    }
}