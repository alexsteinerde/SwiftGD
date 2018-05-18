#if os(Linux)
    import Glibc
    import Cgdlinux
#else
    import Darwin
    import Cgdmac
#endif

import Foundation

// MARK: LibGd Bridge

extension EncodableRasterFormat {

    /// Function pointer to one of libgd's built-in `Data` encoding functions
    internal var encodeData: (_ image: gdImagePtr, _ size: UnsafeMutablePointer<Int32>, _ params: Int32) -> UnsafeMutableRawPointer? {
        switch self {
        case .bmp: return gdImageBmpPtr
        case .jpg: return gdImageJpegPtr
        case .png: return gdImagePngPtrEx
        case .wbmp: return gdImageWBMPPtr
        // None-parametrizable formats (strips parameters)
        case .gif: return { image, size, _ in gdImageGifPtr(image, size) }
        case .tiff: return { image, size, _ in gdImageTiffPtr(image, size) }
        case .webp: return { image, size, _ in gdImageWebpPtr(image, size) }
        }
    }

    /// Function pointer to one of libgd's built-in FILE encoding functions
    internal var encodeFile: (_ image: gdImagePtr, _ file: UnsafeMutablePointer<FILE>, _ parameters: Int32) -> Void {
        switch self {
        case .bmp: return gdImageBmp
        case .jpg: return gdImageJpeg
        case .png: return gdImagePngEx
        // File ($1) and parameters ($2) are swapped on WBMP file import
        case .wbmp: return { gdImageWBMP($0, $2, $1) }
        // None-parametrizable formats (strips parameters)
        case .gif: return { image, file, _ in gdImageGif(image, file) }
        case .tiff: return { image, file, _ in gdImageTiff(image, file) }
        case .webp: return { image, file, _ in gdImageWebp(image, file) }
        }
    }
}

extension DecodableRasterFormat {

    /// Function pointer to one of libgd's built-in `Data` decoding functions
    internal var decodeData: (_ size: Int32, _ data: UnsafeMutableRawPointer) -> gdImagePtr? {
        switch self {
        case .bmp: return gdImageCreateFromBmpPtr
        case .gif: return gdImageCreateFromWebpPtr
        case .jpg: return gdImageCreateFromJpegPtr
        case .png: return gdImageCreateFromPngPtr
        case .tiff: return gdImageCreateFromTiffPtr
        case .tga: return gdImageCreateFromTgaPtr
        case .wbmp: return gdImageCreateFromWBMPPtr
        case .webp: return gdImageCreateFromWebpPtr
        }
    }

    /// Function pointer to one of libgd's built-in FILE decoding functions
    internal var decodeFile: (_ file: UnsafeMutablePointer<FILE>) -> gdImagePtr? {
        switch self {
        case .bmp: return gdImageCreateFromBmp
        case .gif: return gdImageCreateFromWebp
        case .jpg: return gdImageCreateFromJpeg
        case .png: return gdImageCreateFromPng
        case .tiff: return gdImageCreateFromTiff
        case .tga: return gdImageCreateFromTga
        case .wbmp: return gdImageCreateFromWBMP
        case .webp: return gdImageCreateFromWebp
        }
    }
}

// MARK: - Common Format Coding

extension EncodableRasterFormat {

    /// The parameters to apply on encoding
    internal var encodingParameters: Int32 {
        switch self {
        // Parametrizable formats
        case let .bmp(compression): return compression ? 1 : 0
        case let .jpg(quality, _): return quality
        case let .png(compression, _): return min(max(compression, -1), 9) // -1 -> default, 0 -> none, 1-9 -> level
        case let .wbmp(index): return index
        // None parametrizable formats
        case .gif, .tiff, .webp: return -1
        }
    }

    /// Whether the alpha channel of the pixels should be saved on encoding. `nil` will leave this settings "as is".
    private var alpha: Bool? {
        switch self {
        case .png(_, let alpha): return alpha
        case .bmp, .gif, .jpg, .tiff, .wbmp, .webp:
            return nil
        }
    }

    /// Sets whether an image should be interlaced encoded. `nil` will leave this settings "as is".
    private var interlaced: Bool? {
        switch self {
        case .jpg(_, let progressive): return progressive
        case .bmp, .gif, .png, .tiff, .wbmp, .webp:
            return nil
        }
    }

    /// Prepares given image for encoding
    ///
    /// - Parameter image: The image to prepare for encoding
    internal func prepare(image: gdImagePtr) {
        if let alpha = alpha { gdImageSaveAlpha(image, alpha ? 1 : 0) }
        if let interlaced = interlaced { gdImageInterlace(image, interlaced ? 1 : 0) }
    }
}

extension DecodableRasterFormat {

    /// Initializes a `DecodableRasterFormat` that matches the raster format as identified by given file/path extension.
    /// Extensions are copied from wikipedia (see links at description)
    ///
    /// - Parameter pathExtension: The file/path extension to evaluate if matching raster format exists.
    internal init?(pathExtension: String) {
        switch pathExtension {
        case "bmp", "dib":
            self = .bmp
        case "gif":
            self = .gif
        case "jpg", "jpeg", "jpe", "jif", "jfif", "jfi":
            self = .jpg
        case "png":
            self = .png
        case "tiff", "tif":
            self = .tiff
        case "tga", "icb", "vda", "vst":
            self = .tga
        case "wbmp":
            self = .wbmp
        case "webp":
            self = .webp
        default:
            return nil
        }
    }
}
