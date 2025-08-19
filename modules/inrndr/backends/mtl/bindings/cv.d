/**
    CoreVideo

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module mtl.bindings.cv;
import coregraphics.opengl;
import corefoundation.cfallocator;
import corefoundation.cfdictionary;
import corefoundation;
import bindbc.opengl;
import metal.types;
import foundation;
import objc;

extern(C) @nogc nothrow:

/**
    Converts a 4-character ISO15924 string to its numeric equivalent.

    This essentially packs the ISO14924 string into a uint. 
*/
enum OSType ISO15924(immutable(char)[4] tag) = (
    ((cast(uint)(tag[0]) & 0xFF) << 24) | 
    ((cast(uint)(tag[1]) & 0xFF) << 16) | 
    ((cast(uint)(tag[2]) & 0xFF) << 8) |
     (cast(uint)(tag[3]) & 0xFF));

alias CVReturn = int;
enum : CVReturn {
    kCVReturnSuccess                         = 0,
    
    kCVReturnFirst                           = -6660,
    
    kCVReturnError                           = kCVReturnFirst,
    kCVReturnInvalidArgument                 = -6661,
    kCVReturnAllocationFailed                = -6662,
	kCVReturnUnsupported                     = -6663,
    
    // DisplayLink related errors
    kCVReturnInvalidDisplay                  = -6670,
    kCVReturnDisplayLinkAlreadyRunning       = -6671,
    kCVReturnDisplayLinkNotRunning           = -6672,
    kCVReturnDisplayLinkCallbacksNotSet      = -6673,
    
    // Buffer related errors
    kCVReturnInvalidPixelFormat              = -6680,
    kCVReturnInvalidSize                     = -6681,
    kCVReturnInvalidPixelBufferAttributes    = -6682,
    kCVReturnPixelBufferNotOpenGLCompatible  = -6683,
    kCVReturnPixelBufferNotMetalCompatible   = -6684,
    
    // Buffer Pool related errors
    kCVReturnWouldExceedAllocationThreshold  = -6689,
    kCVReturnPoolAllocationFailed            = -6690,
    kCVReturnInvalidPoolAttributes           = -6691,
    kCVReturnRetry                           = -6692,
	
    kCVReturnLast                            = -6699
    
}

enum CVPixelFormatType : OSType {
    k1Monochrome                         = 0x00000001,          /* 1 bit indexed */
    k2Indexed                            = 0x00000002,          /* 2 bit indexed */
    k4Indexed                            = 0x00000004,          /* 4 bit indexed */
    k8Indexed                            = 0x00000008,          /* 8 bit indexed */
    k1IndexedGray_WhiteIsZero            = 0x00000021,          /* 1 bit indexed gray, white is zero */
    k2IndexedGray_WhiteIsZero            = 0x00000022,          /* 2 bit indexed gray, white is zero */
    k4IndexedGray_WhiteIsZero            = 0x00000024,          /* 4 bit indexed gray, white is zero */
    k8IndexedGray_WhiteIsZero            = 0x00000028,          /* 8 bit indexed gray, white is zero */
    k16BE555                             = 0x00000010,          /* 16 bit BE RGB 555 */
    k16LE555                             = ISO15924!"L555",     /* 16 bit LE RGB 555 */
    k16LE5551                            = ISO15924!"5551",     /* 16 bit LE RGB 5551 */
    k16BE565                             = ISO15924!"B565",     /* 16 bit BE RGB 565 */
    k16LE565                             = ISO15924!"L565",     /* 16 bit LE RGB 565 */
    k24RGB                               = 0x00000018,          /* 24 bit RGB */
    k24BGR                               = ISO15924!"24BG",     /* 24 bit BGR */
    k32ARGB                              = 0x00000020,          /* 32 bit ARGB */
    k32BGRA                              = ISO15924!"BGRA",     /* 32 bit BGRA */
    k32ABGR                              = ISO15924!"ABGR",     /* 32 bit ABGR */
    k32RGBA                              = ISO15924!"RGBA",     /* 32 bit RGBA */
    k64ARGB                              = ISO15924!"b64a",     /* 64 bit ARGB, 16-bit big-endian samples */
    k64RGBALE                            = ISO15924!"l64r",     /* 64 bit RGBA, 16-bit little-endian full-range (0-65535) samples */
    k48RGB                               = ISO15924!"b48r",     /* 48 bit RGB, 16-bit big-endian samples */
    k32AlphaGray                         = ISO15924!"b32a",     /* 32 bit AlphaGray, 16-bit big-endian samples, black is zero */
    k16Gray                              = ISO15924!"b16g",     /* 16 bit Grayscale, 16-bit big-endian samples, black is zero */
    k30RGB                               = ISO15924!"R10k",     /* 30 bit RGB, 10-bit big-endian samples, 2 unused padding bits (at least significant end). */
    k30RGB_r210                          = ISO15924!"r210",     /* 30 bit RGB, 10-bit big-endian samples, 2 unused padding bits (at most significant end), video-range (64-940). */
    k422YpCbCr8                          = ISO15924!"2vuy",     /* Component Y'CbCr 8-bit 4:2:2, ordered Cb Y'0 Cr Y'1 */
    k4444YpCbCrA8                        = ISO15924!"v408",     /* Component Y'CbCrA 8-bit 4:4:4:4, ordered Cb Y' Cr A */
    k4444YpCbCrA8R                       = ISO15924!"r408",     /* Component Y'CbCrA 8-bit 4:4:4:4, rendering format. full range alpha, zero biased YUV, ordered A Y' Cb Cr */
    k4444AYpCbCr8                        = ISO15924!"y408",     /* Component Y'CbCrA 8-bit 4:4:4:4, ordered A Y' Cb Cr, full range alpha, video range Y'CbCr. */
    k4444AYpCbCr16                       = ISO15924!"y416",     /* Component Y'CbCrA 16-bit 4:4:4:4, ordered A Y' Cb Cr, full range alpha, video range Y'CbCr, 16-bit little-endian samples. */
    k4444AYpCbCrFloat                    = ISO15924!"r4fl",     /* Component AY'CbCr single precision floating-point 4:4:4:4 */
    k444YpCbCr8                          = ISO15924!"v308",     /* Component Y'CbCr 8-bit 4:4:4, ordered Cr Y' Cb, video range Y'CbCr */
    k422YpCbCr16                         = ISO15924!"v216",     /* Component Y'CbCr 10,12,14,16-bit 4:2:2 */
    k422YpCbCr10                         = ISO15924!"v210",     /* Component Y'CbCr 10-bit 4:2:2 */
    k444YpCbCr10                         = ISO15924!"v410",     /* Component Y'CbCr 10-bit 4:4:4 */
    k420YpCbCr8Planar                    = ISO15924!"y420",     /* Planar Component Y'CbCr 8-bit 4:2:0.  baseAddr points to a big-endian CVPlanarPixelBufferInfo_YCbCrPlanar struct */
    k420YpCbCr8PlanarFullRange           = ISO15924!"f420",     /* Planar Component Y'CbCr 8-bit 4:2:0, full range.  baseAddr points to a big-endian CVPlanarPixelBufferInfo_YCbCrPlanar struct */
    k422YpCbCr_4A_8BiPlanar              = ISO15924!"a2vy",     /* First plane: Video-range Component Y'CbCr 8-bit 4:2:2, ordered Cb Y'0 Cr Y'1; second plane: alpha 8-bit 0-255 */
    k420YpCbCr8BiPlanarVideoRange        = ISO15924!"420v",     /* Bi-Planar Component Y'CbCr 8-bit 4:2:0, video-range (luma=[16,235] chroma=[16,240]).  baseAddr points to a big-endian CVPlanarPixelBufferInfo_YCbCrBiPlanar struct */
    k420YpCbCr8BiPlanarFullRange         = ISO15924!"420f",     /* Bi-Planar Component Y'CbCr 8-bit 4:2:0, full-range (luma=[0,255] chroma=[1,255]).  baseAddr points to a big-endian CVPlanarPixelBufferInfo_YCbCrBiPlanar struct */ 
    k422YpCbCr8BiPlanarVideoRange        = ISO15924!"422v",     /* Bi-Planar Component Y'CbCr 8-bit 4:2:2, video-range (luma=[16,235] chroma=[16,240]).  baseAddr points to a big-endian CVPlanarPixelBufferInfo_YCbCrBiPlanar struct */
    k422YpCbCr8BiPlanarFullRange         = ISO15924!"422f",     /* Bi-Planar Component Y'CbCr 8-bit 4:2:2, full-range (luma=[0,255] chroma=[1,255]).  baseAddr points to a big-endian CVPlanarPixelBufferInfo_YCbCrBiPlanar struct */
    k444YpCbCr8BiPlanarVideoRange        = ISO15924!"444v",     /* Bi-Planar Component Y'CbCr 8-bit 4:4:4, video-range (luma=[16,235] chroma=[16,240]).  baseAddr points to a big-endian CVPlanarPixelBufferInfo_YCbCrBiPlanar struct */
    k444YpCbCr8BiPlanarFullRange         = ISO15924!"444f",     /* Bi-Planar Component Y'CbCr 8-bit 4:4:4, full-range (luma=[0,255] chroma=[1,255]).  baseAddr points to a big-endian CVPlanarPixelBufferInfo_YCbCrBiPlanar struct */
    k422YpCbCr8_yuvs                     = ISO15924!"yuvs",     /* Component Y'CbCr 8-bit 4:2:2, ordered Y'0 Cb Y'1 Cr */
    k422YpCbCr8FullRange                 = ISO15924!"yuvf",     /* Component Y'CbCr 8-bit 4:2:2, full range, ordered Y'0 Cb Y'1 Cr */
    kOneComponent8                       = ISO15924!"L008",     /* 8 bit one component, black is zero */
    kTwoComponent8                       = ISO15924!"2C08",     /* 8 bit two component, black is zero */
    k30RGBLEPackedWideGamut              = ISO15924!"w30r",     /* little-endian RGB101010, 2 MSB are ignored, wide-gamut (384-895) */
    kARGB2101010LEPacked                 = ISO15924!"l10r",     /* little-endian ARGB2101010 full-range ARGB */
    k40ARGBLEWideGamut                   = ISO15924!"w40a",     /* little-endian ARGB10101010, each 10 bits in the MSBs of 16bits, wide-gamut (384-895, including alpha) */
    k40ARGBLEWideGamutPremultiplied      = ISO15924!"w40m",     /* little-endian ARGB10101010, each 10 bits in the MSBs of 16bits, wide-gamut (384-895, including alpha). Alpha premultiplied */
    kOneComponent10                      = ISO15924!"L010",     /* 10 bit little-endian one component, stored as 10 MSBs of 16 bits, black is zero */
    kOneComponent12                      = ISO15924!"L012",     /* 12 bit little-endian one component, stored as 12 MSBs of 16 bits, black is zero */
    kOneComponent16                      = ISO15924!"L016",     /* 16 bit little-endian one component, black is zero */
    kTwoComponent16                      = ISO15924!"2C16",     /* 16 bit little-endian two component, black is zero */
    kOneComponent16Half                  = ISO15924!"L00h",     /* 16 bit one component IEEE half-precision float, 16-bit little-endian samples */
    kOneComponent32Float                 = ISO15924!"L00f",     /* 32 bit one component IEEE float, 32-bit little-endian samples */
    kTwoComponent16Half                  = ISO15924!"2C0h",     /* 16 bit two component IEEE half-precision float, 16-bit little-endian samples */
    kTwoComponent32Float                 = ISO15924!"2C0f",     /* 32 bit two component IEEE float, 32-bit little-endian samples */
    k64RGBAHalf                          = ISO15924!"RGhA",     /* 64 bit RGBA IEEE half-precision float, 16-bit little-endian samples */
    k128RGBAFloat                        = ISO15924!"RGfA",     /* 128 bit RGBA IEEE float, 32-bit little-endian samples */
    k14Bayer_GRBG                        = ISO15924!"grb4",     /* Bayer 14-bit Little-Endian, packed in 16-bits, ordered G R G R... alternating with B G B G... */
    k14Bayer_RGGB                        = ISO15924!"rgg4",     /* Bayer 14-bit Little-Endian, packed in 16-bits, ordered R G R G... alternating with G B G B... */
    k14Bayer_BGGR                        = ISO15924!"bgg4",     /* Bayer 14-bit Little-Endian, packed in 16-bits, ordered B G B G... alternating with G R G R... */
    k14Bayer_GBRG                        = ISO15924!"gbr4",     /* Bayer 14-bit Little-Endian, packed in 16-bits, ordered G B G B... alternating with R G R G... */
    kDisparityFloat16	                 = ISO15924!"hdis",     /* IEEE754-2008 binary16 (half float), describing the normalized shift when comparing two images. Units are 1/meters: ( pixelShift / (pixelFocalLength * baselineInMeters) ) */
    kDisparityFloat32	                 = ISO15924!"fdis",     /* IEEE754-2008 binary32 float, describing the normalized shift when comparing two images. Units are 1/meters: ( pixelShift / (pixelFocalLength * baselineInMeters) ) */
    kDepthFloat16	                     = ISO15924!"hdep",     /* IEEE754-2008 binary16 (half float), describing the depth (distance to an object) in meters */
    kDepthFloat32	                     = ISO15924!"fdep",     /* IEEE754-2008 binary32 float, describing the depth (distance to an object) in meters */
    k420YpCbCr10BiPlanarVideoRange       = ISO15924!"x420",     /* 2 plane YCbCr10 4:2:0, each 10 bits in the MSBs of 16bits, video-range (luma=[64,940] chroma=[64,960]) */
    k422YpCbCr10BiPlanarVideoRange       = ISO15924!"x422",     /* 2 plane YCbCr10 4:2:2, each 10 bits in the MSBs of 16bits, video-range (luma=[64,940] chroma=[64,960]) */
    k444YpCbCr10BiPlanarVideoRange       = ISO15924!"x444",     /* 2 plane YCbCr10 4:4:4, each 10 bits in the MSBs of 16bits, video-range (luma=[64,940] chroma=[64,960]) */
    k420YpCbCr10BiPlanarFullRange        = ISO15924!"xf20",     /* 2 plane YCbCr10 4:2:0, each 10 bits in the MSBs of 16bits, full-range (Y range 0-1023) */
    k422YpCbCr10BiPlanarFullRange        = ISO15924!"xf22",     /* 2 plane YCbCr10 4:2:2, each 10 bits in the MSBs of 16bits, full-range (Y range 0-1023) */
    k444YpCbCr10BiPlanarFullRange        = ISO15924!"xf44",     /* 2 plane YCbCr10 4:4:4, each 10 bits in the MSBs of 16bits, full-range (Y range 0-1023) */
    k420YpCbCr8VideoRange_8A_TriPlanar   = ISO15924!"v0a8",     /* first and second planes as per 420YpCbCr8BiPlanarVideoRange (420v), alpha 8 bits in third plane full-range.  No CVPlanarPixelBufferInfo struct. */
    k16VersatileBayer                    = ISO15924!"bp16",     /* Single plane Bayer 16-bit little-endian sensor element ("sensel") samples from full-size decoding of ProRes RAW images; Bayer pattern (sensel ordering) and other raw conversion information is described via buffer attachments */
    k64RGBA_DownscaledProResRAW          = ISO15924!"bp64",     /* Single plane 64-bit RGBA (16-bit little-endian samples) from downscaled decoding of ProRes RAW images; components--which may not be co-sited with one another--are sensel values and require raw conversion, information for which is described via buffer attachments */
    k422YpCbCr16BiPlanarVideoRange       = ISO15924!"sv22",     /* 2 plane YCbCr16 4:2:2, video-range (luma=[4096,60160] chroma=[4096,61440]) */
    k444YpCbCr16BiPlanarVideoRange       = ISO15924!"sv44",     /* 2 plane YCbCr16 4:4:4, video-range (luma=[4096,60160] chroma=[4096,61440]) */
    k444YpCbCr16VideoRange_16A_TriPlanar = ISO15924!"s4as",     /* 3 plane video-range YCbCr16 4:4:4 with 16-bit full-range alpha (luma=[4096,60160] chroma=[4096,61440] alpha=[0,65535]).  No CVPlanarPixelBufferInfo struct. */
}

extern const __gshared NSString kCVPixelBufferOpenGLCompatibilityKey;
extern const __gshared NSString kCVPixelBufferMetalCompatibilityKey;


alias CVOpenGLTextureCacheRef = CFTypeRef;
extern CVReturn CVOpenGLTextureCacheCreate(CVOpenGLTextureCacheRef);
extern void CVOpenGLTextureCacheRelease(CVOpenGLTextureCacheRef);
extern CVReturn CVOpenGLTextureCacheCreate(CFAllocatorRef, NSDictionary!(NSString, NSObject), CGLContextObj, CGLPixelFormatObj, CFDictionaryRef, ref CVOpenGLTextureCacheRef);
extern CVReturn CVOpenGLTextureCacheCreateTextureFromImage(CFAllocatorRef, CVOpenGLTextureCacheRef, CVPixelBufferRef, CFDictionaryRef, ref CVOpenGLTextureRef);
extern void CVOpenGLTextureCacheFlush(CVOpenGLTextureCacheRef, ulong);

alias CVOpenGLTextureRef = CFTypeRef;
extern CVOpenGLTextureRef CVOpenGLTextureRetain(CVOpenGLTextureRef);
extern void CVOpenGLTextureRelease(CVOpenGLTextureRef);
extern GLenum CVOpenGLTextureGetTarget(CVOpenGLTextureRef);
extern GLenum CVOpenGLTextureGetName(CVOpenGLTextureRef);
extern bool CVOpenGLTextureIsFlipped(CVOpenGLTextureRef);

alias CVPixelBufferRef = CFTypeRef;
extern CVPixelBufferRef CVPixelBufferRetain(CVPixelBufferRef);
extern void CVPixelBufferRelease(CVPixelBufferRef);
extern CVReturn CVPixelBufferCreate(CFAllocatorRef, size_t, size_t, OSType, CFDictionaryRef, ref CVPixelBufferRef);