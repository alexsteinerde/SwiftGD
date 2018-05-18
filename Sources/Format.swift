import Foundation

// TODO: Refactor encodable raster format options

/// Encodable raster formats
///
/// - bmp: https://en.wikipedia.org/wiki/bmp_file_format
///     `compression`: Whether or not apply rle compression
/// - gif: https://en.wikipedia.org/wiki/gif
/// - jpg: https://en.wikipedia.org/wiki/jpeg
///     `quality`: The quality of the jpeg encoding
/// - png: https://en.wikipedia.org/wiki/portable_network_graphics
///     `compression`: The level of PNG compression (Level: 0 -> none, 1-9 -> level, -1 -> default)
/// - tiff: https://en.wikipedia.org/wiki/TIFF
/// - wbmp: https://en.wikipedia.org/wiki/wbmp
///     `index`: The index of the foreground color. Others will not be written.
/// - webp: https://en.wikipedia.org/wiki/webp
public enum EncodableRasterFormat {
    case bmp(compression: Bool)
    case gif
    case jpg(quality: Int32, progressive: Bool?)
    case png(compression: Int32, alpha: Bool?)
    case tiff
    case wbmp(index: Int32)
    case webp
}

/// Decodable raster formats
///
/// - bmp: https://en.wikipedia.org/wiki/bmp_file_format
/// - gif: https://en.wikipedia.org/wiki/gif
/// - jpg: https://en.wikipedia.org/wiki/jpeg
/// - png: https://en.wikipedia.org/wiki/portable_network_graphics
/// - tiff: https://en.wikipedia.org/wiki/TIFF
/// - tga: https://en.wikipedia.org/wiki/Truevision_TGA
/// - wbmp: https://en.wikipedia.org/wiki/wbmp
/// - webp: https://en.wikipedia.org/wiki/webp
/// - any: Evaluates all of the above mentioned formats on decoding (sorted by the "most used on the web")
public enum DecodableRasterFormat {
    case bmp
    case gif
    case jpg
    case png
    case tiff
    case tga
    case wbmp
    case webp

    /// A list of all raster formats sorted by the "most used on the web"
    public static let any: [DecodableRasterFormat] = [.jpg, .png, .gif, .webp, .tiff, .bmp, .wbmp]
}
