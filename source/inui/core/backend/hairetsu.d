/**
    Hairetsu based ImGui font builder

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inui.core.backend.hairetsu;
import nulib.collections.vector;
import nulib.string;
import i2d.imgui;
import hairetsu;
import numem;
import inmath.linalg;

alias inrecti = inmath.linalg.recti;
alias inrect = inmath.linalg.rect;
alias invec2u = inmath.linalg.vec2u;
alias invec2i = inmath.linalg.vec2i;
alias invec2 = inmath.linalg.vec2;

struct GlyphInfo {
    invec2u size;
    invec2i offset;
    float advance;
}

struct FontInfo {
    uint pixelHeight;
    float ascender;
    float descender;
    float lineSpacing;
    float lineGap;
    float maxAdvanceWidth;
}

class HaFont : NuObject {
private:
@nogc:
    Font font;
    FontFace face;

public:

    /**
        Rasterization density.
    */
    float rasterDensity;

    /**
        Inverse rasterization density.
    */
    float invRasterDensity;

    /**
        Font info
    */
    FontInfo info;

    /**
        Destructor
    */
    ~this() {
        face.release();
        font.release();
    }
    
    /**
        Constructor
    */
    this(FontFile file, ref const(ImFontConfig) src) {
        
        // Fetch font
        this.font = file.fonts[src.FontNo];
        this.font.retain();
        
        // Create face.
        this.face = font.createFace();

        // File is no longer needed as we retained the specific font
        // we're after.
        file.release();

        // Finally set size of the face.
        this.rasterDensity = src.RasterizerDensity;
        this.invRasterDensity = 1.0/src.RasterizerDensity;
        this.setPixelHeight(cast(int)src.SizePixels);
    }

    /**
        Tries to create a font and checks its validity in the process.
    */
    static HaFont createFont(ref const(ImFontConfig) src) {
        
        // Load file
        FontFile file = FontFile.fromMemory(cast(ubyte[])src.FontData[0..src.FontDataSize], cast(string)src.Name.ptr.fromStringz());
        if (file) {
            return nogc_new!HaFont(file, src);
        }

        return null;
    }

    /**
        Sets size of font in pixels.
    */
    final
    void setPixelHeight(int pixelHeight) {
        face.dpi = 96*rasterDensity;
        face.px = pixelHeight;

        FontMetrics metrics = face.faceMetrics();
        info.pixelHeight = cast(uint)(pixelHeight*invRasterDensity);
        info.ascender = ceil(metrics.ascender.x)*invRasterDensity;
        info.descender = ceil(metrics.descender.x)*invRasterDensity;
        info.lineSpacing = ceil(metrics.maxExtent.y)*invRasterDensity;
        info.lineGap = ceil(metrics.lineGap.x)*invRasterDensity;
        info.maxAdvanceWidth = ceil(metrics.maxAdvance.x)*invRasterDensity;
    }

    /**
        Gets the index of a glyph.
    */
    pragma(inline, true)
    GlyphIndex getGlyphIndex(codepoint code) {
        return font.charMap.getGlyphIndex(code);
    }

    /**
        Loads a glyph from the font.
    */
    Glyph loadGlyph(codepoint code) {
        GlyphIndex glyphIdx = this.getGlyphIndex(code);
        if (glyphIdx == GLYPH_MISSING)
            return Glyph.init;
        
        // We're just getting metrics here.
        return face.getGlyph(glyphIdx, GlyphType.outline);
    }

    /**
        Renders a glyph.
    */
    HaBitmap renderGlyph(Glyph glyph, ref GlyphInfo info) {
        if (!glyph.hasData)
            return HaBitmap.init;
        
        HaBitmap bmp = glyph.rasterize();
        info.size = invec2u(bmp.width, bmp.height);
        info.offset = invec2i(2, -2);
        info.advance = glyph.metrics.advance.x;

        return bmp;
    }
}

struct IFVec2 {
    ushort x;
    ushort y;
}

struct IFRect {
    ushort x;
    ushort y;
    ushort width;
    ushort height;
}

// Source Data
struct ImFontBuildSrcDataHa {
@nogc:

    // Source Glyph
    struct ImFontBuildSrcGlyphHa {
    @nogc:
        GlyphInfo info;
        codepoint code;
        HaBitmap bitmapData;
    }

    HaFont font;
    IFRect[] rects;
    const(ImWchar)* srcRanges;
    int dstIndex;
    int glyphsHighest;
    int glyphsCount;
    ImBitVector glyphsSet;
    vector!ImFontBuildSrcGlyphHa glyphsList;
}

// Destination Data
struct ImFontBuildDstDataHa {
    int srcCount;
    int glyphsHighest;
    int glyphsCount;
    ImBitVector glyphsSet;
}

extern(C)
static bool ImFontAtlasBuildWithHairetsu(ImFontAtlas* atlas) {
    enum TEX_HEIGHT_MAX = 1024 * 32;
    igImFontAtlasBuildInit(atlas);

    // Clear atlas
    atlas.TexID = 0;
    atlas.TexWidth = 0;
    atlas.TexHeight = 0;
    atlas.TexUvScale = ImVec2(0, 0);
    atlas.TexUvWhitePixel = ImVec2(0, 0);
    ImFontAtlas_ClearTexData(atlas);
    
    vector!ImFontBuildSrcDataHa srcTmpArray;
    vector!ImFontBuildDstDataHa dstTmpArray;
    srcTmpArray.resize(atlas.ConfigData.Size);
    dstTmpArray.resize(atlas.Fonts.Size);

    // 1. Initialize font loading structure, check font data validity
    foreach(si; 0..atlas.ConfigData.Size) {
        ImFontBuildSrcDataHa* srcTmp = &srcTmpArray[si];
        ImFontConfig* src = &atlas.ConfigData[si];

        assert(src.DstFont && (!ImFont_IsLoaded(src.DstFont) || src.DstFont.ContainerAtlas == atlas));

        // Find destination font.
        srcTmp.dstIndex = -1;
        foreach(oi; 0..atlas.ConfigData.Size) {
            if (src.DstFont == atlas.Fonts[oi]) {
                srcTmp.dstIndex = oi;
                break;
            }
        }

        // Check destination index.
        assert(srcTmp.dstIndex != -1, "src.DstFont not pointing within atlas->Fonts[] array?");
        if (srcTmp.dstIndex == -1)
            return false;

        // Check and load font.
        srcTmp.font = HaFont.createFont(*src);
        if (!srcTmp.font)
            return false;

        ImFontBuildDstDataHa* dstTmp = &dstTmpArray[srcTmp.dstIndex];
        srcTmp.srcRanges = src.GlyphRanges;
        for (const(ImWchar)* srcRange = srcTmp.srcRanges; srcRange[0] && srcRange[1]; srcRange += 2) {
            assert(srcRange[0] <= srcRange[1], "Invalid range: is your glyph range array persistent? it is zero-terminated?");
            srcTmp.glyphsHighest = max(srcTmp.glyphsHighest, cast(uint)srcRange[1]);
        }
        dstTmp.srcCount++;
        dstTmp.glyphsHighest = max(dstTmp.glyphsHighest, srcTmp.glyphsHighest);
    }

    // 2. For every requested codepoint, check for their presence in the font data, and handle redundancy or overlaps between source fonts to avoid unused glyphs.
    int totalGlyphCount;
    foreach(si; 0..srcTmpArray.length) {
        ImFontBuildSrcDataHa* srcTmp = &srcTmpArray[si];
        ImFontBuildDstDataHa* dstTmp = &dstTmpArray[si];
        ImBitVector_Create(&srcTmp.glyphsSet, srcTmp.glyphsHighest+1);
        if (dstTmp.glyphsSet.Storage.empty)
            ImBitVector_Create(&dstTmp.glyphsSet, dstTmp.glyphsHighest+1);

        for (const(ImWchar)* srcRange = srcTmp.srcRanges; srcRange[0] && srcRange[1]; srcRange += 2) {
            foreach(codepoint code; srcRange[0]..srcRange[1]) {
                if (ImBitVector_TestBit(&dstTmp.glyphsSet, code))
                    continue;
                
                srcTmp.glyphsCount++;
                dstTmp.glyphsCount++;
                ImBitVector_SetBit(&srcTmp.glyphsSet, code);
                ImBitVector_SetBit(&dstTmp.glyphsSet, code);
                totalGlyphCount++;
            }
        }
    }
    
    // 3. Unpack our bit map into a flat list (we now have all the Unicode points that we know are requested _and_ available _and_ not overlapping another)
    foreach(si; 0..srcTmpArray.length) {
        ImFontBuildSrcDataHa* srcTmp = &srcTmpArray[si];
        srcTmp.glyphsList.reserve(srcTmp.glyphsCount);

        assert(typeof(srcTmp.glyphsSet.Storage.Data[0]).sizeof == uint.sizeof);
        foreach(i; 0..srcTmp.glyphsSet.Storage.Size) {
            if (uint entries32 = srcTmp.glyphsSet.Storage.Data[i]) {
                foreach(bitN; 0..32) {
                    if (entries32 & (cast(uint)1 << bitN)) {
                        ImFontBuildSrcDataHa.ImFontBuildSrcGlyphHa srcGlyph;
                        srcGlyph.code = cast(codepoint)((i << 5) + bitN);
                        srcTmp.glyphsList ~= srcGlyph;
                    }
                }
            }
        }

        ImBitVector_Clear(&srcTmp.glyphsSet);
        assert(srcTmp.glyphsList.length == srcTmp.glyphsCount);
    }
    
    foreach(di; 0..dstTmpArray.length)
        ImBitVector_Clear(&dstTmpArray[di].glyphsSet);
    dstTmpArray.clear();


    // Allocate temporary rasterization data buffers.
    // We could not find a way to retrieve accurate glyph size without rendering them.
    // (e.g. slot->metrics->width not always matching bitmap->width, especially considering the Oblique transform)
    IFRect[] rectsToPack;
    rectsToPack = rectsToPack.nu_resize(totalGlyphCount);

    // 4. Gather glyphs sizes so we can pack them in our virtual canvas.
    // 8. Render/rasterize font characters into the texture
    int totalSurface = 0;
    int rectsOutCount = 0;
    const int packPadding = atlas.TexGlyphPadding;
    foreach(si; 0..srcTmpArray.length) {

        ImFontBuildSrcDataHa* srcTmp = &srcTmpArray[si];
        if (srcTmp.glyphsCount == 0)
            continue;
    
        srcTmp.rects = rectsToPack[0..srcTmp.glyphsCount];
        rectsOutCount += srcTmp.glyphsCount;
        
        // Gather the sizes of all rectangles we will need to pack
        foreach(gi; 0..srcTmp.glyphsList.length) {
            ImFontBuildSrcDataHa.ImFontBuildSrcGlyphHa* srcGlyph = &srcTmp.glyphsList[gi];
            
            // Note: FreeType impl checks for glyph metrics being null,
            //       in this case hairetsu impl returns a base initialized
            //       Glyph, which will have no font reference.
            Glyph glyph = srcTmp.font.loadGlyph(srcGlyph.code);
            if (!glyph.font)
                continue;

            HaBitmap bitmap = srcTmp.font.renderGlyph(glyph, srcGlyph.info);
            if (bitmap.data.length == 0)
                continue;

            srcGlyph.bitmapData = bitmap;
            srcTmp.rects[gi].width = cast(ushort)(srcGlyph.info.size.x + packPadding);
            srcTmp.rects[gi].height = cast(ushort)(srcGlyph.info.size.y + packPadding);
            totalSurface += srcTmp.rects[gi].width * srcTmp.rects[gi].height;
        }
    }
    foreach(i; 0..atlas.CustomRects.Size)
        totalSurface += (atlas.CustomRects[i].Width + packPadding) * (atlas.CustomRects[i].Height + packPadding);
    
    const int surfaceSqrt = cast(int)sqrt(cast(float)totalSurface) + 1;
    atlas.TexWidth = atlas.TexDesiredWidth > 0 ?
        atlas.TexDesiredWidth : 
        ((surfaceSqrt >= 4096 * 0.7f) ? 4096 : (surfaceSqrt >= 2048 * 0.7f) ? 2048 : (surfaceSqrt >= 1024 * 0.7f) ? 1024 : 512);
    atlas.TexHeight = atlas.TexWidth;
    
    // 5. Start packing
    Skyline skyline = Skyline(cast(ushort)atlas.TexWidth, cast(ushort)atlas.TexWidth);
    foreach(si; 0..srcTmpArray.length) {

        ImFontBuildSrcDataHa* srcTmp = &srcTmpArray[si];
        if (srcTmp.glyphsCount == 0)
            continue;

        foreach(ref IFRect rect; srcTmp.rects) {
            rect = skyline.pack(IFVec2(rect.width, rect.height));
            ImFontAtlas_AddCustomRectRegular(atlas, rect.width, rect.height);
        }
    }

    // 7. Allocate texture
    uint texSizeBytes = atlas.TexWidth * atlas.TexHeight;
    atlas.TexUvScale = ImVec2(1.0 / atlas.TexWidth, 1.0 / atlas.TexHeight);
    atlas.TexPixelsAlpha8 = cast(char*)nu_malloc(texSizeBytes);
    nogc_zeroinit(cast(ubyte[])atlas.TexPixelsAlpha8[0..texSizeBytes]);

    // 8. Copy rasterized font characters back into the main texture
    // 9. Setup ImFont and glyphs for runtime
    foreach(si; 0..srcTmpArray.length) {

        ImFontBuildSrcDataHa* srcTmp = &srcTmpArray[si];
        
        // When merging fonts with MergeMode=true:
        // - We can have multiple input fonts writing into a same destination font.
        // - dst_font->Sources is != from src which is our source configuration.
        ImFontConfig* src = &atlas.ConfigData[si];
        ImFont* dstFont = src.DstFont;

        const float ascent = srcTmp.font.info.ascender;
        const float descent = srcTmp.font.info.descender;
        igImFontAtlasBuildSetupFont(atlas, dstFont, src, ascent, descent);
        if (srcTmp.glyphsCount == 0)
            continue;

        const float fontOffsetX = src.GlyphOffset.x;
        const float fontOffsetY = src.GlyphOffset.y + round(dstFont.Ascent);
        const int padding = atlas.TexGlyphPadding;
        foreach(gi; 0..srcTmp.glyphsCount) {

            ImFontBuildSrcDataHa.ImFontBuildSrcGlyphHa* srcGlyph = &srcTmp.glyphsList[gi];
            IFRect packRect = srcTmp.rects[gi];
            if (packRect.width == 0 && packRect.height == 0)
                continue;
            
            GlyphInfo info = srcGlyph.info;
            assert(info.size.x + padding <= packRect.width);
            assert(info.size.y + padding <= packRect.height);

            const int tx = packRect.x + padding;
            const int ty = packRect.y + padding;

            float invRasterDensity = srcTmp.font.invRasterDensity;

            // Register glyph
            float x0 = info.offset.x * invRasterDensity + fontOffsetX;
            float y0 = info.offset.y * invRasterDensity + fontOffsetY;
            float x1 = x0 + info.size.x * invRasterDensity;
            float y1 = y0 + info.size.y * invRasterDensity;
            float u0 = tx / cast(float)atlas.TexWidth;
            float v0 = ty / cast(float)atlas.TexHeight;
            float u1 = (tx + info.size.x) / cast(float)atlas.TexWidth;
            float v1 = (ty + info.size.y) / cast(float)atlas.TexHeight;
            float ax = info.advance * invRasterDensity;
            ImFont_AddGlyph(dstFont, src, cast(ImWchar)srcGlyph.code, x0, y0, x1, y1, u0, v0, u1, v1, ax);

            // import std.stdio : writefln;
            // ImFontGlyph* dstGlyph = &dstFont.Glyphs[dstFont.Glyphs.size()-1];

            // writefln("%x %x", dstGlyph.Codepoint, srcGlyph.code);
            // assert(dstGlyph.Codepoint == srcGlyph.code);

            size_t blitDstStride = atlas.TexWidth;
            if (atlas.TexPixelsAlpha8) {
                ubyte* blitDst = cast(ubyte*)(atlas.TexPixelsAlpha8 + (ty * blitDstStride) + tx);
                foreach(y; 0..info.size.y) {
                    ubyte[] blitSrc = cast(ubyte[])srcGlyph.bitmapData.scanline(y);
                    blitDst[0..info.size.x] = blitSrc[0..info.size.x];
                }

                srcGlyph.bitmapData.free();
            }
        }

        // Free the rects.
        srcTmp.rects = null;
    }

    rectsToPack = rectsToPack.nu_resize(0);
    srcTmpArray.clear();

    igImFontAtlasBuildFinish(atlas);
    return true;
}

/**
    A skyline packing structure.
*/
struct Skyline {
    ushort width;
    ushort height;
    vector!IFVec2 skyline;

    this(ushort width, ushort height) {
        this.width = width;
        this.height = height;
        this.skyline = [IFVec2(0, 0)];
    }

    /**
        Packs a rectangle into the skyline.

        Params:
            size = The size of the rectangle to pack
        
        Returns:
            A new reactangle with the bounds.
    */
    IFRect pack(IFVec2 size) {
        if (size.x == 0 || size.y == 0)
            return IFRect.init;
        
        ushort iBest = ushort.max;
        ushort jBest = ushort.max;
        IFVec2 best = IFVec2(ushort.max, ushort.max);
        foreach(i; 0..skyline.length) {
            IFVec2 pos = skyline[i];

            // Right boundary reached.
            if (size.x > width - pos.x)
                break;
            
            // Can't best the best.
            if (pos.y >= best.y)
                continue;

            uint xMax = pos.x + width;

            ushort j;
            for(j = cast(ushort)(i+1); j < skyline.length; ++j) {
                
                // Won't reach next points.
                if (xMax <= skyline[j].x)
                    break;

                // Raise Y to not intersect.
                if (pos.y < skyline[j].y)
                    pos.y = skyline[j].y;
            }

            // Can't best the best.
            if (pos.y >= best.y)
                continue;
            
            // Top boundary reached.
            if (size.y > height - pos.y)
                continue;

            iBest = cast(ushort)i;
            jBest = j;
            best = pos;
        }

        if (iBest == ushort.max)
            return IFRect.init;
        
        // Bugcheck
        assert(iBest < jBest);
        assert(jBest > 0);

        // Calculate the relevant points.
        IFVec2 newTL = IFVec2(best.x, cast(ushort)(best.y + size.y));
        IFVec2 newBR = IFVec2(cast(ushort)(best.x + size.x), skyline[jBest-1].y);
        bool brPoint = (jBest < skyline.length ? newBR.x < skyline[jBest].x : newBR.x < width);

        // Calculate, then remove and insert indices.
        skyline.removeAt(iBest, jBest-iBest);
        skyline.insert(newTL, iBest);
        if (brPoint)
            skyline.insert(newBR, iBest+1);

        return IFRect(best.x, best.y, size.x, size.y);
    }
}

const(ImFontBuilderIO)* GetBuilderForHairetsu() {
    __gshared ImFontBuilderIO io;
    io.FontBuilder_Build = &ImFontAtlasBuildWithHairetsu;
    return &io;
}