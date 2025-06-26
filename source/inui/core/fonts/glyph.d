/**
    InUI Font Manager

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.fonts.glyph;
import ha = hairetsu;
import inmath.linalg;

alias Bitmap = ha.HaBitmap;
alias Metrics = ha.GlyphMetrics;
alias SourceMetrics = ha.FontMetrics;
alias GLYPH_MISSING = ha.GLYPH_MISSING;

/**
    A glyph source.
*/
abstract
class GlyphSource {

    /**
        Name of the glyph source.
    */
    abstract @property string name();

    /**
        Whether the glyph source is realized (ready for use)
    */
    abstract @property bool isRealized();

    /**
        Current size of the glyph source.
    */
    abstract @property float size();
    abstract @property void size(float value);

    /**
        Synthetic thickness to apply. (default: 1)
    */
    abstract @property float thickness();
    abstract @property void thickness(float value);

    /**
        Synthetic shear to apply. (default: 0)
    */
    abstract @property float shear();
    abstract @property void shear(float value);

    /**
        General metrics of the source.
    */
    @property SourceMetrics metrics() => SourceMetrics(
        ha.vec2(0, 0),
        ha.vec2(0, 0),
        ha.vec2(0, 0),
        ha.vec2(0, 0),
        ha.vec2(0, 0)
    );

    /**
        Gets whether the source has a given codepoint.

        Params:
            codepoint = The codepoint to query.

        Returns:
            Whether the codepoint is present within the
            glyph source.
    */
    abstract bool hasCodepoint(uint codepoint);

    /**
        Gets whether the source has a given codepoint.

        Params:
            codepoint = The codepoint to get the glyph index for.
        
        Returns:
            The index of the glyph of matching the given codepoint,
            returns $(D GLYPH_MISSING) if glyph isn't found.
    */
    abstract uint getGlyphIndex(uint codepoint);

    /**
        Gets the metrics for the given glyph index.

        Params:
            glyphIndex = Index of the glpyh to get metrics for.

        Returns:
            The metrics for the given glyph.
    */
    abstract Metrics getMetricsFor(uint glyphIndex);

    /**
        Gets the rendering rectangle for a given glyph index.

        Params:
            glyphIndex = Index of the glpyh to get render rect for.
            baselineHeight = Height of the baseline.

        Returns:
            The render rectangle for the given glyph.
    */
    abstract rect getRenderRectFor(uint glyphIndex, float baselineHeight);

    /**
        Rasterizes the glyph.

        Params:
            glyphIndex = Index of the glpyh to rasterize.

        Returns:
            A new rasterized bitmap.
    */
    abstract Bitmap rasterize(uint glyphIndex);

    /**
        Realizes the glyph source.

        Returns:
            The realized glyph source.
    */
    abstract GlyphSource realize();
}
