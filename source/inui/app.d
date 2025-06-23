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
import inui.core.settings;
import inui.core.window;
import inui.core.imgui;
import inui.window;
import inui.menu;

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

    // Store init routine.
    void initStore() {
        settings_ = new AppSettings(info.id);
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
        SDL_SetAppMetadataProperty(SDL_PROP_APP_METADATA_NAME_STRING, info.name.ptr);
        SDL_SetAppMetadataProperty(SDL_PROP_APP_METADATA_VERSION_STRING, info.version_.ptr);
        SDL_SetAppMetadataProperty(SDL_PROP_APP_METADATA_IDENTIFIER_STRING, info.id.ptr);
        SDL_SetAppMetadataProperty(SDL_PROP_APP_METADATA_CREATOR_STRING, info.copyright.ptr);
        SDL_SetAppMetadataProperty(SDL_PROP_APP_METADATA_URL_STRING, info.url.ptr);
        SDL_SetAppMetadataProperty(SDL_PROP_APP_METADATA_TYPE_STRING, "application");
    }

    // SDL Init routine.
    void initSDL() {
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

        this.applyInfo();
        this.initSDL();
        this.initStore();
        __sharedApplication = this;
    }

    void shutdown() {

        // Shutdown Win32 Integration
        version(Windows) {
            import inui.core.backend.win32 : uiWin32Shutdown;
            uiWin32Shutdown();
        }
    }

    //
    //          APP STATE
    //
    Window mainWindow_;
    Menu mainMenu_;
    void delegate(ref SDL_Event ev)[] handlers;

    int startEventLoop() {
        while(mainWindow_ && !mainWindow_.isCloseRequested) {

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
        }
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
    @property string executable() { return exec; }

    /**
        The arguments which were passed to the application.
    */
    @property string[] args() { return startArgs; }

    /**
        The app's settings.
    */
    @property AppSettings settings() { return settings_; }

    /**
        The app's main window.
    */
    @property Window mainWindow() { return mainWindow_; }

    /**
        The app's main menu.
    */
    @property Menu mainMenu() { return mainMenu_; }

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
                return ret;
            }

            this.handlers.length = 0;
            return 0;
        } catch(Exception ex) {
            import inui.core.msgbox : MessageBox, MessageType;
            MessageBox.show(MessageType.error, "Uncaught Exception", ex.msg);
            return -1;
        }
    }

    /**
        Registers an event handler with the application.
        The handler will live until the application exists.
    */
    void registerEventHandler(void delegate(ref SDL_Event ev) handler) {
        this.handlers ~= handler;
    }
}