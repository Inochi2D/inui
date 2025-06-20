module inui.core.imgui;
import i2d.imgui;
import inui.core.window;
import inui.core.backend.imgui;
import inui.core.backend.gl;
import inui.core.backend.hairetsu;
import sdl;

/**
    ImGui context state.
*/
class IGContext {
private:
    ImGuiContext* ctx;

public:

    /**
        Destructor
    */
    ~this() {
        incGLBackendShutdown();
        ImGui_ImplShutdown();
        igDestroyContext(ctx);
    }

    /**
        Constructs a new ImGui Context
    */
    this() {

        // Load config
        this.ctx = igCreateContext();
        igSetCurrentContext(ctx);

        auto io = igGetIO();
        igLoadIniSettingsFromDisk(io.IniFilename);

        io.ConfigFlags |= ImGuiConfigFlags.DockingEnable;
        io.ConfigWindowsResizeFromEdges = true;
        version(OSX) io.ConfigMacOSXBehaviors = true;

        // ImFontAtlas* atlas = io.Fonts;
        // atlas.FontBuilderIO = GetBuilderForHairetsu();
        incGLBackendInit();
        incGLBackendPlatformInterfaceInit();
    }

    void processEvent(const(SDL_Event)* event) {
        ImGui_ImplProcessEvent(event);
    }

    void beginFrame(NativeWindow window, float deltaTime) {
        incGLBackendNewFrame();
        ImGui_ImplNewFrame(window, deltaTime);
        igNewFrame();

        incGLBackendBeginRender(window);
    }

    void endFrame(NativeWindow window) {
        igRender();

        ImGui_ImplViewportUpdate(window);
        incGLBackendRenderDrawData(igGetDrawData());
    }
}