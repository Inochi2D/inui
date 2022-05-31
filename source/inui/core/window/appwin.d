/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.window.appwin;
import inui.core.window;
import inui.core.app;

import bindbc.sdl;
import bindbc.opengl;
import bindbc.imgui;
import bindbc.imgui.ogl;
import std.string;

private {
    __gshared bool isGLLoaded;
}

class InApplicationWindow : InWindow {
private:
    SDL_Window* window;
    ImGuiContext* ctx;
    ImGuiIO* io;
    SDL_GLContext glctx;
    bool done;

    int width_, height_;

protected:

    /**
        Early update (before UI draws)
    */
    override
    void onEarlyUpdate() {

    }

    /**
        Updates the window
    */
    override
    void onUpdate() {

    }

    /**
        Run post-window close cleanup
    */
    final void cleanup() {

        // Cleanup
        ImGuiOpenGLBackend.shutdown();
        ImGui_ImplSDL2_Shutdown();
        igDestroyContext(ctx);

        SDL_GL_DeleteContext(glctx);
        SDL_DestroyWindow(window);
    }

public:

    ~this() {
        cleanup();
    }

    this(string title, uint width, uint height) {
        this.width_ = width;
        this.height_ = height;

        // Set up OpenGL context
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GLprofile.SDL_GL_CONTEXT_PROFILE_CORE);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);

        // Set up buffers + alpha channel
        SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
        SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
        SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);
        SDL_GL_SetAttribute(SDL_GL_ALPHA_SIZE, 8);

        // Create window with GL and resizing enabled,
        // important to give the GL hint
        window = SDL_CreateWindow(
            title.toStringz, 
            SDL_WINDOWPOS_UNDEFINED, 
            SDL_WINDOWPOS_UNDEFINED, 
            width, 
            height, 
            SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE
        );

        // Create context and load GL functions
        glctx = SDL_GL_CreateContext(window);
        SDL_GL_MakeCurrent(window, glctx);
        SDL_GL_SetSwapInterval(1); // Enable VSync

        // Load OpenGL and throw any important errors.
        if (!isGLLoaded) {
            GLSupport support = loadOpenGL();
            switch(support) {
                case GLSupport.noLibrary:
                    throw new Exception("OpenGL library could not be loaded!");

                case GLSupport.noContext:
                    throw new Exception("No valid OpenGL 4.2 context was found!");

                default: break;
            }
        }

        // Setup imgui context
        ctx = igCreateContext();
        io = igGetIO();
        io.ConfigFlags |= ImGuiConfigFlags.DockingEnable;
        version(UIViewports) {
            io.ConfigFlags |= ImGuiConfigFlags.ViewportsEnable;
        }
        io.ConfigWindowsResizeFromEdges = true;
        
        // Init ImGui for SDL2 & OpenGL
        ImGui_ImplSDL2_InitForOpenGL(window, glctx);
        ImGuiOpenGLBackend.init("#version 330");
    }

    /**
        Gets whether a window should be processed
    */
    override
    bool shouldProcess() {
        return window !is null && !done && (SDL_GetWindowFlags(window) & SDL_WINDOW_MINIMIZED) == 0; 
    }

    /**
        Update all
    */
    final
    void update() {

        // Update important SDL events
        string[] files;
        SDL_Event event;
        while(SDL_PollEvent(&event)) {
            switch(event.type) {
                case SDL_QUIT:
                    close();
                    break;

                case SDL_DROPFILE:
                    files ~= cast(string)event.drop.file.fromStringz;
                    SDL_RaiseWindow(window);
                    break;
                
                default: 
                    ImGui_ImplSDL2_ProcessEvent(&event);
                    if (event.type == SDL_WINDOWEVENT) {

                        // CLOSE EVENT
                        if (
                            event.window.event == SDL_WINDOWEVENT_CLOSE && 
                            event.window.windowID == SDL_GetWindowID(window)
                        ) close();

                        // RESIZE EVENT
                        if (
                            event.window.event == SDL_WindowEventID.SDL_WINDOWEVENT_RESIZED && 
                            event.window.windowID == SDL_GetWindowID(window)
                        ) {
                            this.width_ = event.window.data1;
                            this.height_ = event.window.data2;
                            onResized(event.window.data1, event.window.data2);
                        }
                    }
                    break;
            }
        }
        
        // Start the Dear ImGui frame
        ImGuiOpenGLBackend.new_frame();
        ImGui_ImplSDL2_NewFrame();
        igNewFrame();

            // Allow dragging files in to the main window
            if (files.length > 0) {
                if (igBeginDragDropSource(ImGuiDragDropFlags.SourceExtern)) {
                    igSetDragDropPayload("_FILEDROP", &files, files.sizeof);
                    igBeginTooltip();
                        foreach(file; files) {
                            igText(file.toStringz);
                        }
                    igEndTooltip();
                    igEndDragDropSource();
                }
            }

            // update
            this.onUpdate();

        // Rendering
        igRender();

        // Reset GL State
        glViewport(0, 0, cast(int)io.DisplaySize.x, cast(int)io.DisplaySize.y);
        glClearColor(0, 0, 0, 0);
        glClear(GL_COLOR_BUFFER_BIT);

        // Run early update
        this.onEarlyUpdate();

        // Run UI Render
        ImGuiOpenGLBackend.render_draw_data(igGetDrawData());

        version(UIViewports) {
            
            // Handle viewports
            if (io.ConfigFlags & ImGuiConfigFlags.ViewportsEnable) {
                SDL_Window* currentWindow = SDL_GL_GetCurrentWindow();
                SDL_GLContext currentCtx = SDL_GL_GetCurrentContext();
                igUpdatePlatformWindows();
                igRenderPlatformWindowsDefault();
                SDL_GL_MakeCurrent(currentWindow, currentCtx);
            }
        }

        // Swap this window
        SDL_GL_SwapWindow(window);

        // Update window list
        foreach(win; inWindowListGet()) {
            win.onEarlyUpdate();
            win.onUpdate();
        }
    }

    /**
        Forces the window to be focused
    */
    override
    void focus() {
        SDL_SetWindowInputFocus(window);
    }

    /**
        Closes the Window
    */
    override
    void close() {
        done = true;
    }

    /**
        Updates the window
    */
    override
    bool isAlive() {
        return !done;
    }

    /**
        Window width
    */
    override
    int width() {
        return width_;
    }

    /**
        Window height
    */
    override
    int height() {
        return height_;
    }
}