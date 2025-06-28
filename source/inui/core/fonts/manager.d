/**
    InUI Font Manager

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.fonts.manager;
import inui.core.fonts.glyph;
import inui.core.fonts.font;
import inui.window;
import nulib.math;

import ha = hairetsu.math.linalg;

/**
    Handles fonts and inline-able symbols.
*/
final
class GlyphManager {
private:
    GlyphSource mainSource_;
    GlyphSource[] sources_;
    GlyphSource[] active_;
    float size_ = glyphMinSize;
    float shear_ = 0;
    float scale_ = 1;
    bool requiresRefresh = true;

    ptrdiff_t find(GlyphSource src) {
        foreach(i; 0..sources_.length)
            if (sources_[i] is src) return i;

        return -1;
    }

    ptrdiff_t findActive(GlyphSource src) {
        foreach(i; 0..active_.length)
            if (active_[i] is src) return i;

        return -1;
    }

    void recalculateMetrics() {
        foreach(source; active) {
            if (!source)
                continue;
            
            source.size = size_ * scale_;
            source.shear = shear_;
        }
        this.requiresRefresh = true;
    }
public:

    /**
        Minimum glyph size.
    */
    enum float glyphMinSize = 14;

    /**
        Maximum glyph size.
    */
    enum float glyphMaxSize = 255;

    /**
        Glyph sources.
    */
    @property GlyphSource[] sources() => sources_;

    /**
        Active sources.
    */
    @property GlyphSource[] active() => [mainSource_] ~ active_;

    /**
        The main font being used.
    */
    @property GlyphSource mainSource() => mainSource_;

    /**
        Current target size.

        Default: $(D 12)
        Range: $(D 12..255)
    */
    @property float size() => size_;
    @property void size(float value) {
        this.size_ = clamp(value, glyphMinSize, glyphMaxSize);
        this.recalculateMetrics();
    }

    /**
        Current target size.

        Default: $(D 12)
        Range: $(D 12..255)
    */
    @property float scale() => scale_;
    @property void scale(float value) {
        this.scale_ = value;
        this.recalculateMetrics();
    }

    /**
        Current target shear.
        
        Default: $(D 0)
        Range: $(D -1..1)
    */
    @property float shear() => shear_;
    @property void shear(float value) {
        this.shear_ = value;
        this.recalculateMetrics();
    }

    /*
        Destructor
    */
    ~this() {
        this.sources_.length = 0;
    }

    /**
        Constructs a new font manager.
    */
    this() {
        this.sources_ ~= UIFont.createFontList();

        this.set(this.sources_[0]);
    }

    /**
        Adds a glyph source to the font manager.

        Params:
            source = The source to add.
    */
    void add(GlyphSource source) {
        if (find(source) == -1)
            this.sources_ ~= source;
    }

    /**
        Gets whether the source has a given codepoint.

        Params:
            codepoint = The codepoint to query.

        Returns:
            Whether the codepoint is present within the
            glyph source.
    */
    bool hasCodepoint(uint codepoint) {
        foreach(source; active) {
            if (!source)
                continue;
            
            uint gidx = source.getGlyphIndex(codepoint);
            if (gidx != GLYPH_MISSING)
                return true;
        }
        return false;
    }

    /**
        Gets the first glyph source that supports the given
        codepoint.

        Params:
            codepoint = The codepoint to query.

        Returns:
            The first glyph source that supports the codepoint,
            $(D null) if none supports it.
    */
    GlyphSource getGlyphSourceFor(uint codepoint) {
        foreach(source; active) {
            if (!source)
                continue;
            
            uint gidx = source.getGlyphIndex(codepoint);
            if (gidx != GLYPH_MISSING)
                return source;
        }
        return null;
    }

    /**
        Sets the current active main font.

        Params:
            source = The source to deactivate.
    */
    void set(GlyphSource source) {
        this.mainSource_ = source.isRealized() ? source : source.realize();
        this.recalculateMetrics();
    }

    /**
        Activates the given glyph source.

        Params:
            source = The source to deactivate.
    */
    void activate(GlyphSource source) {
        if (findActive(source) != -1)
            return;

        this.active_ ~= source.isRealized() ? source : source.realize();
        this.recalculateMetrics();
    }

    /**
        Deactivates the given glyph source.

        Params:
            source = The source to deactivate.
    */
    void deactivate(GlyphSource source) {
        import std.algorithm.mutation : remove;
        ptrdiff_t idx = findActive(source);
        if (idx == -1)
            return;
        
        active_ = active_.remove(idx);
        this.recalculateMetrics();
    }

    /**
        Refreshes the font atlasses for the open windows.
    */
    void refreshFontAtlasses() {
        if (!requiresRefresh)
            return;

        foreach(Window window; Window.windows) {
            window.imgui.style.FontSizeBase = size_;
            window.imgui.style.FontScaleMain = scale_;
            window.imgui.refreshFontAtlas();
        }

        this.requiresRefresh = false;
    }

}
