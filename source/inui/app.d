/**
    Inui App Entrypoint

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.app;
import numem : nogc_delete, move;
import std.exception : enforce;
import std.string;
import sdl.init;
import sdl.events;
import sdl.timer;

public import nulib.string;
import nulib.math : abs;
import inui.core.fonts;
import inui.core.settings;
import inui.core.window;
import inui.core.imgui;
import inui.core.menu;
import inui.style;
import inui.window;
import sdl.filesystem;

/**
    Information about an application.
*/
struct AppInfo {

    /**
        Human-readable name of the app. (Required)
    */
    nstring name;

    /**
        Human-readable version number of the app. (Required)
    */
    nstring version_ = "1.0.0";

    /**
        ID of the app in reverse domain notation. (Required)
    */
    nstring id;

    /**
        Author name.
    */
    nstring author;

    /**
        Human-readable copyright string.
    */
    nstring copyright;

    /**
        The App's Web URL.
    */
    nstring url;

    /**
        The automatically generated author portion of the app id.
    */
    @property string authorId() {
        ptrdiff_t sep = getAppIdSeperator();
        return sep >= 0 ? id[0..sep] : null;
    }

    /**
        The automatically generated name portion of the app id.
    */
    @property string appId() {
        ptrdiff_t sep = getAppIdSeperator();
        return sep >= 0 ? id[sep..$] : null;
    }

    private
    ptrdiff_t getAppIdSeperator() {
        foreach_reverse(i; 0..id.length) {
            if (id[i] == '.')
                return i;
        }
        return -1;
    }
}

/**
    Root application object of the application
*/
class Application {
private:
    __gshared Application __sharedApplication;

    //
    //          SETTINGS
    //
    AppSettings settings_;
    StyleSheet stylesheet_;

    // Store init routine.
    void initStore() {
        settings_ = new AppSettings(info);
    }

    //
    //          APP INFO
    //

    AppInfo info;
    string[] startArgs;
    string exec;

    // Info application routine.
    void applyInfo() {
        assert(info.name, "Name must be specified!");
        assert(info.version_, "Version number must be specified!");
        assert(info.id, "ID must be specified!");
        assert(info.authorId && info.appId, "ID is malformed!");

        SDL_SetAppMetadataProperty(SDL_PROP_APP_METADATA_NAME_STRING, info.name.ptr);
        SDL_SetAppMetadataProperty(SDL_PROP_APP_METADATA_VERSION_STRING, info.version_.ptr);
        SDL_SetAppMetadataProperty(SDL_PROP_APP_METADATA_IDENTIFIER_STRING, info.id.ptr);
        SDL_SetAppMetadataProperty(SDL_PROP_APP_METADATA_CREATOR_STRING, info.copyright.ptr);
        SDL_SetAppMetadataProperty(SDL_PROP_APP_METADATA_URL_STRING, info.url.ptr);
        SDL_SetAppMetadataProperty(SDL_PROP_APP_METADATA_TYPE_STRING, "application");
    }

    // SDL Init routine.
    void initSDL() {
        version(OSX) {
            import inui.core.backend.osx : uiCocoaPlatformSetup;
            uiCocoaPlatformSetup();
        }

        SDL_Init(SDL_INIT_EVENTS | SDL_INIT_VIDEO);
    }

    // Init routine.
    void initialize() {
        enforce(!__sharedApplication, "There's already an existing application instance!");

        // Setup Win32 Integration
        version(Windows) {
            import inui.core.backend.win32 : uiWin32Init;
            uiWin32Init();
        }

        this.glyphManager_ = new GlyphManager();
        this.applyInfo();
        this.initSDL();
        this.initStore();
        __sharedApplication = this;

        this.glyphManager_.size = settings_.get!float("font_size", GlyphManager.glyphMinSize);
    }

    void shutdown() {
        settings_.set!float("font_size", glyphManager_.size);

        // Shutdown Win32 Integration
        version(Windows) {
            import inui.core.backend.win32 : uiWin32Shutdown;
            uiWin32Shutdown();
        }
    }

    //
    //          APP STATE
    //
    GlyphManager glyphManager_;
    Window mainWindow_;
    Menu mainMenu_;
    void delegate(ref SDL_Event ev)[] handlers;

    int startEventLoop() {
        bool first = true;
        do {

            SDL_PumpEvents();
            SDL_Event ev;
            while(SDL_PollEvent(&ev)) {
                
                // Event handlers take precedence over the application
                // handlers.
                foreach(handler; handlers)
                    handler(ev);

                // Window events have precdence over main events.
                foreach(Window window; Window.windows) {
                    window.processEvent(&ev);
                }
                
                switch(ev.type) {
                    case SDL_EventType.SDL_EVENT_QUIT:
                        mainWindow_.close();
                        break;

                    case SDL_EventType.SDL_EVENT_WINDOW_CLOSE_REQUESTED:
                        if (auto window = Window.fromID(ev.window.windowID)) {
                            nogc_delete(window);
                        }
                        break;

                    default:
                        break;
                }
            }

            foreach(Window window; Window.windows) {
                window.update();
            }
            glyphManager_.refreshFontAtlasses();

            if (first) {
                first = false;
                foreach(window; Window.windows)
                    window.refresh();
            }
        } while(mainWindow_ && !mainWindow_.isCloseRequested);
        return 0;
    } 

public:

    /**
        Global UI Scale
    */
    float uiScale = 1.0f;

    /**
        The global application instance.
    */
    static @property Application thisApp() {
        return __sharedApplication;
    }

    /**
        Path of the application executable.
    */
    @property string executable() => exec;

    /**
        The arguments which were passed to the application.
    */
    @property string[] args() => startArgs;

    /**
        The app's global stylesheet.
    */
    @property ref StyleSheet stylesheet() => stylesheet_;

    /**
        The app's global glyph manager.
    */
    @property GlyphManager glyphManager() => glyphManager_;

    /**
        The app's settings.
    */
    @property AppSettings settings() => settings_;

    /**
        The app's main window.
    */
    @property Window mainWindow() => mainWindow_;

    /**
        The app's main menu.
    */
    @property Menu mainMenu() => mainMenu_;

    /**
        Information about the app.
    */
    @property AppInfo appInfo() => info;

    /**
        Time since the start of the application.
    */
    @property double currentTime() => SDL_GetTicks()*0.001;

    /**
        Destructor
    */
    ~this() {
        this.shutdown();
        nogc_delete(info);
        __sharedApplication = null;
    }

    /**
        Creates a new application with the given application info.

        The AppInfo instance is moved out from its original variable, becoming owned
        by the Application.
    */
    this(ref AppInfo info) {
        this.info = info.move();
        this.initialize();
    }

    /**
        Runs the application.
    */
    int run(Window window, string[] args) {
        try {
            this.startArgs = args.length > 1 ? args[1..$] : null;
            this.exec = args.length > 0 ? args[0] : null;

            if (window) {
                this.mainWindow_ = window;
                this.mainWindow_.show();
                
                int ret = this.startEventLoop();
                this.shutdown();
                return ret;
            }

            this.handlers.length = 0;
        } catch(Exception ex) {
            debug throw ex;
            else {
                import inui.core.msgbox : MessageBox, MessageType;
                MessageBox.show(MessageType.error, "Uncaught Exception", ex.msg);
                return -1;
            }
        }
        return 0;
    }

    /**
        Registers an event handler with the application.
        The handler will live until the application exists.
    */
    void registerEventHandler(void delegate(ref SDL_Event ev) handler) {
        this.handlers ~= handler;
    }
}
