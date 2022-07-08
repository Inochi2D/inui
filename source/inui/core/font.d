module inui.core.font;
import inui.core.settings;
import bindbc.imgui;

private {
    ImFontAtlas* atlas;
    
    void _inAddFontData(string name, ref ubyte[] data, float size = 14, const ImWchar* ranges = null, ImVec2 offset = ImVec2(0f, 0f)) {
        auto cfg = ImFontConfig_ImFontConfig();
        cfg.FontBuilderFlags = 1 << 9;
        cfg.FontDataOwnedByAtlas = false;
        cfg.MergeMode = atlas.Fonts.empty() ? false : true;
        cfg.GlyphOffset = offset;
        cfg.OversampleH = 3;
        cfg.OversampleV = 2;

        char[40] nameDat;
        nameDat[0..name.length] = name[0..name.length];
        cfg.Name = nameDat;
        ImFontAtlas_AddFontFromMemoryTTF(atlas, cast(void*)data.ptr, cast(int)data.length, size, cfg, ranges);
    }

    ubyte[] NOTO = cast(ubyte[])import("NotoSansCJK-Regular.ttc");
    ubyte[] ICONS = cast(ubyte[])import("MaterialIcons.ttf");
}

/**
    Initializes fonts
*/
void inInitFonts() {
    //_inInitFontList();
    atlas = igGetIO().Fonts;
        _inAddFontData("APP\0", NOTO, 26, (cast(ImWchar[])[
            0x0020, 0x00FF, // Basic Latin + Latin Supplement
            0x2000, 0x206F, // General Punctuation
            0x3000, 0x30FF, // CJK Symbols and Punctuations, Hiragana, Katakana
            0x31F0, 0x31FF, // Katakana Phonetic Extensions
            0xFF00, 0xFFEF, // Half-width characters
            0xFFFD, 0xFFFD, // Invalid
            0x4e00, 0x9FAF, // CJK Ideograms
            0]).ptr,
            ImVec2(0, -6)
        );
        _inAddFontData(
            "Icons", 
            ICONS, 
            32, 
            [
                cast(ImWchar)0xE000, 
                cast(ImWchar)0xF23B
            ].ptr, 
            ImVec2(0, -2)
        );
    ImFontAtlas_Build(atlas);
    inSetUIScale(inGetUIScale());
}

/**
    Sets the UI scale for fonts
*/
void inSetUIScale(float scale) {
    inSettingsSet("UIScale", scale);
    igGetIO().FontGlobalScale = inGetUIScaleFont();
}

/**
    Get the UI scale in terms of font size
*/
float inGetUIScaleFont() {
    return inGetUIScale()/2;
}

/**
    Returns the UI Scale
*/
float inGetUIScale() {
    return inSettingsGet!float("UIScale", 1.0);
}

/**
    Gets the UI scale in text form
*/
string inGetUIScaleText() {
    import std.format : format;
    return "%s%%".format(cast(int)(inGetUIScale()*100));
}

/**
    Begins a section where text is double size
*/
void inFontsBeginLarge() {
    igGetIO().FontGlobalScale = inGetUIScaleFont()*2;
}

/**
    Ends a section where text is double size
*/
void inFontsEndLarge() {
    igGetIO().FontGlobalScale = inGetUIScaleFont();
}

/**
    A font entry in the fonts list
*/
struct FontEntry {
    /**
        Family name of the font
    */
    string name;
    
    /**
        Main language of the font
    */
    string lang;

    /**
        The file of the font
    */
    string file;
}