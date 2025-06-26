/**
    InUI Font

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.fonts.font;
import inui.core.fonts.glyph;
import inmath.linalg;
import nulib.math;
import numem;

import ha = hairetsu;

/**
    A font which can be used in a UI.
*/
class UIFont : GlyphSource {
private:
    ha.FontFaceInfo unrealized;
    ha.FontFile file;
    ha.Font font;
    ha.FontFace face;

    float thickness_ = 1;
    float shear_ = 0;

public:

    /**
        Name of the glyph source.
    */
    override @property string name() {
        if (!font)
            return unrealized.name;
        
        return font.name;
    }

    /**
        Whether the glyph source is realized (ready for use)
    */
    override @property bool isRealized() => face !is null;

    /**
        Current size of the glyph source in
    */
    override @property float size() => face.px;
    override @property void size(float value) { face.px = value; }

    /**
        Synthetic thickness to apply.

        Default: $(D 1)
        Range: $(D 0..4)
    */
    override @property float thickness() => this.thickness_;
    override @property void thickness(float value) { this.thickness_ = clamp(value, 0, 4); }

    /**
        Synthetic shear to apply.

        Default: $(D 0)
        Range: $(D -1..1)
    */
    override @property float shear() => this.shear_;
    override @property void shear(float value) { this.shear_ = clamp(value, -1, 1); }

    /**
        The metrics of the font.
    */
    override @property SourceMetrics metrics() => face ? face.faceMetrics : super.metrics; 

    /**
        Creates a fontlist from the system fonts.
    */
    static UIFont[] createFontList() {
        import std.uni : toLower;
        import std.stdio : writeln;
        UIFont[] result;
        auto fontlist = ha.FontCollection.createFromSystem();
        foreach(ha.FontFamily family; fontlist.families) {
            foreach(ha.FontFaceInfo info; family.faces) {
                if (info.outlines != ha.GlyphType.trueType)
                    continue;
                
                if (info.variable)
                    continue;

                string ext = info.path[$-4..$-1].toLower();
                if (ext != "ttf")
                    continue;
                
                result ~= new UIFont(info);
            }
        }
        return result;
    }

    /*
        Destructor
    */
    ~this() {
        if (face) this.face = face.released(); 
        if (font) this.font = font.released(); 
        if (file) this.file = file.released();
        this.unrealized = null;
    }

    /**
        Constructs a new font from a file path.
    */
    this(string path, uint index = 0) {
        this.file = ha.FontFile.fromFile(path);
        this.font = file.fonts[index];
        this.face = font.createFace();
    }

    /**
        Constructs a new font from a binary stream.
    */
    this(ubyte[] data, uint index = 0) {
        this.file = ha.FontFile.fromMemory(data);
        this.font = file.fonts[index];
        this.face = font.createFace();
    }

    /**
        Constructs a unrealized UI font from a font instance.
    */
    this(ha.Font font) {
        this.font = font;
        this.face = font.createFace();
    }

    /**
        Constructs a unrealized UI font from a face info.
    */
    this(ha.FontFaceInfo info) {
        this.unrealized = info;
    }

    /**
        Gets whether the source has a given codepoint.

        Params:
            codepoint = The codepoint to query.

        Returns:
            Whether the codepoint is present within the
            glyph source.
    */
    override
    bool hasCodepoint(uint codepoint) {
        return font ? font.charMap.getGlyphIndex(codepoint) != GLYPH_MISSING : false;
    }

    /**
        Gets whether the source has a given codepoint.

        Params:
            codepoint = The codepoint to get the glyph index for.
        
        Returns:
            The index of the glyph of matching the given codepoint,
            returns $(D GLYPH_MISSING) if glyph isn't found.
    */
    override
    uint getGlyphIndex(uint codepoint) {
        return font ? font.charMap.getGlyphIndex(codepoint) : GLYPH_MISSING;
    }

    /**
        Gets the metrics for the given glyph index.

        Params:
            glyphIndex = Index of the glpyh to get metrics for.

        Returns:
            The metrics for the given glyph.
    */
    override
    Metrics getMetricsFor(uint glyphIndex) {
        if (!face)
            return Metrics.init;
        
        return face.getMetricsFor(glyphIndex);
    }

    /**
        Gets the rendering rectangle for a given glyph index.

        Params:
            glyphIndex = Index of the glpyh to get render rect for.
            baselineHeight = Height of the baseline.

        Returns:
            The render rectangle for the given glyph.
    */
    override
    rect getRenderRectFor(uint glyphIndex, float baselineHeight) {
        Metrics metrics = this.getMetricsFor(glyphIndex);
        return rect(
            metrics.bounds.xMin - 1.0, 
            baselineHeight - metrics.bounds.yMax - 1.0,
            metrics.bounds.width, 
            metrics.bounds.height
        );
    }

    /**
        Rasterizes the glyph.

        Returns:
            A new rasterized bitmap.
    */
    override
    Bitmap rasterize(uint glyphIndex) {
        if (!face)
            return Bitmap.init;
        
        ha.Glyph glyph = face.getGlyph(glyphIndex, ha.GlyphType.outline);
        glyph.metrics.thickness = thickness_;
        glyph.metrics.shear = shear_;
        if (glyph.hasData)
            return glyph.rasterize();
        
        return Bitmap.init;
    }

    /**
        Realizes the glyph source.
    */
    override
    GlyphSource realize() {
        if (!unrealized.isRealizable)
            return null;
        
        return new UIFont(unrealized.realize());
    }
}
