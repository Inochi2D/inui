/**
    InUI Font Manager

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.fonts.manager;
import inui.core.fonts.glyph;
import inui.core.fonts.font;
import ha = hairetsu.math.linalg;

/**
    Handles fonts and inline-able symbols.
*/
final
class GlyphManager {
private:
    GlyphSource[] sources_;
    GlyphSource[] active_;
    float size_ = 14;

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
        foreach(active; active_) {
            active.size = size_;
        }
    }

public:

    /**
        Glyph sources.
    */
    @property GlyphSource[] sources() => sources_;

    /**
        Active sources.
    */
    @property GlyphSource[] active() => active_;

    /**
        Current size of the glyph source in
    */
    @property float size() => size_;
    @property void size(float value) {
        this.size_ = value;
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
        foreach(active; active_) {
            uint gidx = active.getGlyphIndex(codepoint);
            if (gidx != GLYPH_MISSING)
                return true;
        }
        return false;
    }

    /**
        Gets the metrics for the given glyph index.

        Params:
            codepoint = The codepoint to query.

        Returns:
            The metrics for the given glyph.
    */
    Metrics getMetricsFor(uint codepoint) {
        foreach(active; active_) {
            uint gidx = active.getGlyphIndex(codepoint);
            if (gidx != GLYPH_MISSING)
                return active.getMetricsFor(gidx);
        }
        return Metrics.init;
    }

    /**
        Gets the source metrics for the given codepoint.

        Params:
            codepoint = The codepoint to query.

        Returns:
            The metrics for the first source that provides
            the given codepoint.
    */
    SourceMetrics getSourceMetricsFor(uint codepoint) {
        foreach(active; active_) {
            uint gidx = active.getGlyphIndex(codepoint);
            if (gidx != GLYPH_MISSING)
                return active.metrics;
        }

        // Some metrics is better than no metrics.
        return 
            active_.length > 0 ? 
            active_[0].metrics : 
            SourceMetrics.init;
    }

    /**
        Rasterizes the glyph.

        Params:
            codepoint = The codepoint to query.

        Returns:
            A new rasterized bitmap.
    */
    Bitmap rasterize(uint codepoint) {
        foreach(active; active_) {
            uint gidx = active.getGlyphIndex(codepoint);
            if (gidx != GLYPH_MISSING)
                return active.rasterize(gidx);
        }
        return Bitmap.init;
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
}
