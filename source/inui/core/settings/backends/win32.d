/**
    Windows registry settings store.

    Copyright:
        Copyright © 2025, Kitsunebi Games
        Copyright © 2025, Inochi2D Project
    
    License:   $(LINK2 https://opensource.org/license/bsd-2-clause, BSD 2-clause)
    Authors:   Luna Nielsen
*/
module inui.core.settings.backends.win32;
import inui.core.settings;
import std.exception;
import std.format;
import std.json;
import std.array : split;

version(Windows):

import core.sys.windows.winreg;
import core.sys.windows.windef;
import core.sys.windows.winbase : ExpandEnvironmentStringsW;
import std.regex;
import nulib.conv;
import nulib.math;

/**
    Creates a new settings store.
*/
export
extern(C)
SettingsStore __inc_get_settings_store(string storeId) {
    return new Win32SettingsStore(storeId);
}

class Win32SettingsStore : SettingsStore {
private:
    RegistryKey storeKey;

protected:

    override
    long getIntImpl(string name, long defaultValue = 0) {
        return storeKey.getValue!long(name, defaultValue);
    }
    
    override
    ulong getUIntImpl(string name, ulong defaultValue = 0) {
        return storeKey.getValue!ulong(name, defaultValue);
    }
    
    override
    double getDoubleImpl(string name, double defaultValue = 0) {
        return storeKey.getValue!double(name, defaultValue);
    }
    
    override
    string getStringImpl(string name, string defaultValue = null) {
        return storeKey.getValue!string(name, defaultValue);
    }
    
    override
    JSONValue getJSONImpl(string name, JSONValue defaultValue) {
        return storeKey.getValue!JSONValue(name, defaultValue);
    }

    
    override
    void setIntImpl(string name, long value)  {
        storeKey.setValue!long(name, value);
    }
    
    override
    void setUIntImpl(string name, ulong value)  {
        storeKey.setValue!ulong(name, value);
    }
    
    override
    void setDoubleImpl(string name, double value)  {
        storeKey.setValue!double(name, value);
    }
    
    override
    void setStringImpl(string name, string value)  {
        storeKey.setValue!string(name, value);
    }
    
    override
    void setJSONImpl(string name, JSONValue value)  {
        storeKey.setValue!JSONValue(name, value);
    }


public:

    /**
        Constructor
    */
    this(string storeId) {
        super(storeId);
        this.storeKey = new RegistryKey(HKEY_CURRENT_USER, "SOFTWARE\\"~storeId);
    }

    /**
        Synchronises the settings store with the on-disk
        store.
    */
    override
    void sync() {
        storeKey.flush();
    }

    /**
        Un-sets a value.
    */
    override
    bool unset(string name) {
        if (storeKey.hasKey(name))
            return storeKey.deleteKey(name);
        else if (storeKey.hasValue(name))
            return storeKey.deleteValue(name);
        else
            return false;
    }

    /**
        Gets whether the store has a given value.
    */
    override
    bool has(string name) {
        return storeKey.hasValue(name) | storeKey.hasKey(name);
    }
}

/**
    Wrapper around a windows registry key.
*/
class RegistryKey {
private:
    HKEY[] keys;
    const(wchar)[] subkeyPath;

    ptrdiff_t getValueSize(const(wchar)[] wkey, ref DWORD type) {
        DWORD size = 0;
        if (RegGetValueW(key, null, wkey.ptr, RRF_RT_ANY, &type, null, &size) == ERROR_SUCCESS)
            return size;
        
        return -1;
    }

    string expandEnvString(const(wchar)* str) {
        uint size = ExpandEnvironmentStringsW(str, null, 0);

        if (size > 0) {
            wstring buffer = new wstring(size);
            ExpandEnvironmentStringsW(str, cast(wchar*)buffer.ptr, cast(uint)buffer.length);
            return buffer.ptr.fromWin32Str();
        }

        return "";
    }

    void tryOpenKeyPath(HKEY rootKey, string sk) {
        keys = [rootKey];

        HKEY _key;
        string[] subkeys = sk.split("\\");
        foreach(subkey; subkeys) {
            const(wchar)[] wsubkey = subkey.toWin32Str();

            DWORD lpdwd;
            HRESULT hr = RegCreateKeyExW(
                keys[$-1], 
                wsubkey.ptr, 
                0, 
                null, 
                REG_OPTION_NON_VOLATILE, 
                KEY_READ | KEY_WRITE,
                null,
                &_key,
                &lpdwd
            );
            enforce(hr == ERROR_SUCCESS, "Opening subkey '%s' failed with code %s".format(subkey, hr));
            keys ~= _key;
        }
    }

public:

    /**
        The open key
    */
    @property HKEY key() { return keys[$-1]; }

    /**
        Destructor
    */
    ~this() {
        foreach(k; keys) {
            RegCloseKey(k);
        }
        keys.length = 0;
    }

    /**
        Constructor
    */
    this(HKEY rootKey, string subkey) {
        this.tryOpenKeyPath(rootKey, subkey);
    }

    /**
        Gets whether the key has a given value.
    */
    bool hasValue(string vkey) {
        auto wkey = vkey.toWin32Str();
        return RegGetValueW(key, null, wkey.ptr, RRF_RT_ANY, null, null, null) == ERROR_SUCCESS;
    }

    /**
        Gets whether the key has a given value.
    */
    bool hasKey(string vkey) {
        auto wkey = vkey.toWin32Str();
        HKEY k;
        if (RegOpenKeyExW(key, wkey.ptr, 0, KEY_READ, &k) == ERROR_SUCCESS) {
            RegCloseKey(k);
            return true;
        }
        return false;
    }

    /**
        Gets the requested value.
    */
    T getValue(T)(string vkey, T defaultValue = T.init) {
        auto wkey = vkey.toWin32Str();

        static if (is(T == JSONValue)) {

            // Handle arrays.
            if (!hasKey(vkey)) {
                if (hasValue(vkey)) 
                    return parseJSON(this.getValue!string(vkey, ""));
                
                return defaultValue;
            }

            wchar[] nameBuffer;
            void[] dataBuffer;
            DWORD ktype;
            uint tmpNameSz;
            uint tmpDataSz;
            uint idx;
            
            JSONValue json = JSONValue.emptyObject;
            
            // Iterate sub-sub keys.
            RegistryKey subkey = new RegistryKey(key, vkey);
            nameBuffer = new wchar[255];
            while(RegEnumKeyExW(subkey.key, idx, nameBuffer.ptr, &tmpNameSz, null, null, null, null) != ERROR_NO_MORE_ITEMS) {
                string sskName = nameBuffer[0..tmpNameSz-1].text;
                json[sskName] = subkey.getValue!JSONValue(sskName);

                tmpNameSz = 255;
                idx++;
            }

            DWORD maxValNameLen;
            DWORD maxValDataLen;
            RegQueryInfoKeyW(subkey.key, null, null, null, null, null, null, null, &maxValNameLen, &maxValDataLen, null, null);

            dataBuffer = new void[maxValDataLen+1];
            nameBuffer = new wchar[maxValNameLen+1];

            // Iterate values
            idx = 0;
            tmpDataSz = cast(uint)dataBuffer.length;
            tmpNameSz = cast(uint)(wchar.sizeof*nameBuffer.length);
            while(RegEnumValueW(subkey.key, idx, nameBuffer.ptr, &tmpNameSz, null, &ktype, cast(ubyte*)dataBuffer.ptr, &tmpDataSz) != ERROR_NO_MORE_ITEMS) {

                string skvName = nameBuffer.ptr.fromWin32Str();
                switch(ktype) {
                    case REG_BINARY:
                        json[skvName] = JSONValue(cast(ubyte[])dataBuffer);
                        break;
                    
                    case REG_DWORD:
                        json[skvName] = *(cast(uint*)dataBuffer.ptr);
                        break;
                    
                    case REG_QWORD:
                        json[skvName] = *(cast(ulong*)dataBuffer.ptr);
                        break;
                    
                    case REG_EXPAND_SZ:
                        json[skvName] = expandEnvString(cast(wchar*)dataBuffer.ptr);
                        break;
                    
                    case REG_MULTI_SZ:
                        wstring[] strings = (cast(wstring)dataBuffer[0..tmpDataSz]).split("\0");
                        json[skvName] = JSONValue.emptyArray;
                        foreach(i, str; strings[0..$-1]) {
                            json[skvName][i] = strings[i].ptr.fromWin32Str();
                        }
                        break;
                    
                    case REG_SZ:
                        json[skvName] = (cast(wchar*)dataBuffer.ptr).fromWin32Str();
                        break;
                    
                    default:
                        break;
                }
                

                tmpDataSz = cast(uint)dataBuffer.length;
                tmpNameSz = cast(uint)(wchar.sizeof*nameBuffer.length);
                idx++;
            }

            return json;
        } else {

            // Try getting the value.
            DWORD type;
            ptrdiff_t valueSize = this.getValueSize(wkey, type);
            if (valueSize == -1)
                return defaultValue;

            // Get value.
            DWORD valueStoreSize = cast(DWORD)valueSize;
            void[] valueStore = new void[min(8, valueSize)];
            if (RegGetValueW(key, null, wkey.ptr, RRF_RT_ANY, null, cast(void*)valueStore.ptr, &valueStoreSize) != ERROR_SUCCESS)
                return defaultValue;

            static if (is(T : string)) {
                if (!(type & (REG_SZ | REG_MULTI_SZ | REG_EXPAND_SZ)))
                    return defaultValue;

                if (type == REG_EXPAND_SZ)
                    return expandEnvString(cast(wchar*)valueStore.ptr);

                return (cast(wchar*)valueStore.ptr).fromWin32Str();
            } else static if (__traits(isIntegral, T)) {
                if (!(type & (REG_DWORD | REG_QWORD)))
                    return defaultValue;

                // Reinterpret cast if needed.
                static if (__traits(isUnsigned, T)) 
                    return cast(T)(*cast(ulong*)valueStore.ptr);
                else 
                    return cast(T)(*cast(long*)valueStore.ptr);
            } else static if (__traits(isFloating, T)) {
                if (!(type & (REG_DWORD | REG_QWORD)))
                    return defaultValue;
                
                // Reinterpret int to float.
                return cast(T)(*cast(double*)valueStore.ptr);
            }
        }
    }

    /**
        Sets the requested value.
    */
    void setValue(T)(string vkey, T value) {
        auto wkey = vkey.toWin32Str();

        static if (is(T : string)) {
            auto wval = value.toWin32Str();
            assert(RegSetValueExW(key, wkey.ptr, 0, REG_SZ, cast(const(BYTE)*)wval, cast(DWORD)(value.length*wchar.sizeof)) == ERROR_SUCCESS);
        } else static if (__traits(isIntegral, T)) {
            static if (__traits(isUnsigned, T)) {
                ulong ulValue = value;
                assert(RegSetValueExW(key, wkey.ptr, 0, REG_QWORD, cast(const(BYTE)*)&ulValue, cast(DWORD)ulong.sizeof) == ERROR_SUCCESS);
            } else {
                long lValue = value;
                assert(RegSetValueExW(key, wkey.ptr, 0, REG_QWORD, cast(const(BYTE)*)&lValue, cast(DWORD)long.sizeof) == ERROR_SUCCESS);
            }
        } else static if (__traits(isFloating, T)) {
            double dValue = cast(double)value;
            assert(RegSetValueExW(key, wkey.ptr, 0, REG_QWORD, cast(const(BYTE)*)&dValue, cast(DWORD)double.sizeof) == ERROR_SUCCESS);
        } else static if (is(T : JSONValue)) {
            final switch(value.type) {
                case JSONType.object:
                    RegistryKey subkey = new RegistryKey(key, vkey);
                    foreach(string svk, JSONValue sv; value) {
                        subkey.setValue!JSONValue(svk, sv);
                    }
                    break;

                case JSONType.string:
                    this.setValue!string(vkey, value.str);
                    break;

                case JSONType.integer:
                    this.setValue!long(vkey, value.integer);
                    break;

                case JSONType.uinteger:
                    this.setValue!ulong(vkey, value.uinteger);
                    break;

                case JSONType.float_:
                    this.setValue!double(vkey, value.floating);
                    break;

                case JSONType.true_:
                    this.setValue!bool(vkey, true);
                    break;

                case JSONType.false_:
                    this.setValue!bool(vkey, false);
                    break;

                case JSONType.array:
                    this.setValue!string(vkey, value.toString());
                    break;

                case JSONType.null_:
                    if (hasKey(vkey))
                        this.deleteKey(vkey);
                    else if (hasValue(vkey))
                        this.deleteValue(vkey);
                    break;
            }
        } else static assert(0, "Unsupported type "~T.stringof);
    }

    /**
        Deletes the requested value.
    */
    bool deleteKey(string vkey) {
        auto wkey = vkey.toWin32Str();
        return RegDeleteKeyW(key, wkey.ptr) == ERROR_SUCCESS;
    }

    /**
        Deletes the requested value.
    */
    bool deleteValue(string vkey) {
        auto wkey = vkey.toWin32Str();
        return RegDeleteValueW(key, wkey.ptr) == ERROR_SUCCESS;
    }

    /**
        Flushes the key.
    */
    void flush() {
        RegFlushKey(key);
    }

}


//
//          HELPERS
//

private
string fromWin32Str(const(wchar)* str) {
    import std.conv : text;
    return str.text;
}

private
const(wchar)[] toWin32Str(string str) {
    import core.internal.utf : toUTF16;

    auto value = (str~"\0").toUTF16();
    return value;
}