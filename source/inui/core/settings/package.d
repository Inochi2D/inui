module inui.core.settings;
import inui.core.msgbox;
import inui.app;
import sdl.filesystem;
import std.json;
import std.file;
import std.path;

enum APP_LOAD_ERROR_STRING = "Oops! Your settings.json file is corrupted. Inochi Creator will load the default settings.
The corrupted settings file has been moved to '%s'.

If you see this message repeatedly, please report it on the issue tracker.
Error Message: %s";

/**
    Application settings manager.
*/
class AppSettings {
private:
    SettingsStore store;
    nstring configDir_;
    nstring basePath_;
    nstring imguiIniPath_;
    nstring prefJsonPath_;
    nstring[] localePaths_;

public:
    
    /*
        Destructor
    */
    ~this() {
        store.sync();
    }

    /**
        Constructs the settings manager.
    */
    this(ref AppInfo appInfo) {
        nstring authorId = appInfo.authorId;
        nstring appId = appInfo.appId;

        const(char)* cPath = SDL_GetPrefPath(authorId.ptr, appId.ptr);
        const(char)* bPath = SDL_GetBasePath();
        if (cPath) configDir_ = cPath[0..nu_strlen(cPath)];
        if (bPath) basePath_ = bPath[0..nu_strlen(bPath)];

        store = __inc_get_settings_store(appInfo.id[]);

        imguiIniPath_ = buildPath(configDirectory, "imgui.ini");
        prefJsonPath_ = buildPath(configDirectory, "settings.json");
        localePaths_ = [
            nstring(buildPath(configDirectory, "locale")), 
            nstring(buildPath(basePath, "locale")),
            nstring(buildNormalizedPath(basePath, "../SharedSupport/locale"))
        ];
    }

    /**
        The path where app configuration is stored.
    */
    @property string configDirectory() => configDir_[];

    /**
        The path the app was launched from.
    */
    @property string basePath() => basePath_[];
    
    /**
        The paths which locales are read from.
    */
    @property nstring[] localePaths() => localePaths_;

    /**
        The path of the settings file.
    */
    @property string settingsFile() { return prefJsonPath_[]; }
    
    /**
        The path of the imgui config file.
    */
    @property string imguiConfigFile() { return imguiIniPath_[]; }

    /**
        Saves the app settings.
    */
    void save() {
        store.sync();
    }

    /**
        Sets a setting.
    */
    void set(T)(string name, T value) {
        store.set!T(name, value);
    }

    /**
        Unsets a setting.
    */
    bool unset(string name) {
        return store.unset(name);
    }

    /**
        Gets a setting.
    */
    T get(T)(string name, T defaultValue = T.init) {
        return store.get!T(name, defaultValue);
    }

    /**
        Gets whether the settings store has a setting with the given name.
    */
    bool has(string name) {
        return store.has(name);
    }
}

private
extern(C)
SettingsStore __inc_get_settings_store(string storeId);

/**
    A settings store, implemented by a store backend.
*/
abstract
class SettingsStore {
private:
    string storeId_;

    /**
        Encodes values recursively.
    */
    JSONValue encode(T)(T value) {
        import std.traits : isArray, isAssociativeArray;

        static if (isArray!T) {
            JSONValue[] data;
            foreach(i; 0..value.length) {
                data ~= this.encode(value[i]);
            }
            return JSONValue(data);
        } else static if (isAssociativeArray!T) {
            JSONValue[string] data;
            foreach(key, value; value) {
                data[key.toString()] = this.encode(value[key]);
            }
            return JSONValue(data);
        } else {
            return JSONValue(value);
        }
    }

    /**
        Encodes values recursively.
    */
    T decode(T)(JSONValue from, T defaultValue) {
        import std.traits : isArray, isAssociativeArray, KeyType, ValueType;
        import std.range : ElementType;
        import std.exception : enforce;
        import std.conv : to;
        T retval;

        static if (is(T : string) || is(T : wstring) || is (T : dstring)) {
            return from.str().to!T;
        } else static if (isArray!T) {
            if (!from.array)
                return defaultValue;

            alias ET = ElementType!T;
            
            retval.length = from.array.length;
            foreach(i, ref JSONValue element; retval) {
                retval = this.decode!ET(element, ET.init);
            }
        } else static if (isAssociativeArray!T) {
            if (!from.object)
                return defaultValue;
            
            alias KT = KeyType!T;
            alias VT = ValueType!T;
            foreach(key, value; from.object) {
                try {
                    retval[key.to!KT] = this.decode!VT(value, VT.init);
                } catch(Exception ex) {
                    // Ignore.
                }
            }
        } else static if (is(T : JSONValue)) {
            return from;
        } else {
            return from.get!T();
        }

        return retval;
    }

protected:
    abstract long getIntImpl(string name, long defaultValue);
    abstract ulong getUIntImpl(string name, ulong defaultValue);
    abstract double getDoubleImpl(string name, double defaultValue);
    abstract string getStringImpl(string name, string defaultValue);
    abstract JSONValue getJSONImpl(string name, JSONValue defaultValue);

    abstract void setIntImpl(string name, long value);
    abstract void setUIntImpl(string name, ulong value);
    abstract void setDoubleImpl(string name, double value);
    abstract void setStringImpl(string name, string value);
    abstract void setJSONImpl(string name, JSONValue value);

public:

    /**
        Constructor
    */
    this(string storeId) {
        this.storeId_ = storeId;
    }

    /**
        ID of the data store in reverse domain notation.
    */
    final
    @property string storeId() => storeId_;

    /**
        Synchronises the settings store with the on-disk
        store.
    */
    abstract void sync();

    /**
        Un-sets a value.
    */
    abstract bool unset(string name);

    /**
        Gets whether the store has a given value.
    */
    abstract bool has(string name);

    /**
        Gets a value from the settings store.
    */
    void set(T)(string name, T value) {
        static if (is(T == string)) {
            this.setStringImpl(name, value);
        } else static if (__traits(isIntegral, T)) {
            static if (__traits(isUnsigned, T))
                this.setUIntImpl(name, cast(ulong)value);
            else
                this.setIntImpl(name, cast(long)value);
        } else static if (__traits(isFloating, T)) {
            this.setDoubleImpl(name, cast(double)value);
        } else static if (is(T == JSONValue)) {
            this.setJSONImpl(name, encode!T(value));
        } else static assert(false, T.stringof~" not supported.");
    }

    /**
        Gets a value from the settings store.
    */
    T get(T)(string name, T defaultValue = T.init) {
        static if (is(T == string)) {
            return this.getStringImpl(name, defaultValue);
        } else static if (__traits(isIntegral, T)) {
            static if (__traits(isUnsigned, T))
                return cast(T)this.getUIntImpl(name, cast(ulong)defaultValue);
            else
                return cast(T)this.getIntImpl(name, cast(long)defaultValue);
        } else static if (__traits(isFloating, T)) {
            return cast(T)this.getDoubleImpl(name, cast(double)defaultValue);
        } else static if (is(T == JSONValue)) {
            return this.getJSONImpl(name, defaultValue);
        } else static assert(false, T.stringof~" not supported.");
    }
}