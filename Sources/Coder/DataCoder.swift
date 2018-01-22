#if os(Linux)
    import Glibc
    import Cgdlinux
#else
    import Darwin
    import Cgdmac
#endif

import Foundation

// MARK: - Decoding

extension DecodableRasterFormat {

    /// Function pointer to one of libgd's built-in `Data` decoding functions
    fileprivate var decode: (_ size: Int32, _ data: UnsafeMutableRawPointer) -> gdImagePtr? {
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
}

/// Defines a coder to be used on supported `DecodableRasterFormat` `Data` decoding
private struct DataDecoder: Decoder {

    /// The raster format of the image represented by data passed to this decoder
    fileprivate let format: DecodableRasterFormat

    /// Creates a `gdImagePtr` from given `Data`.
    ///
    /// - Parameter decodable: The image data representation necessary to decode an image instance
    /// - Returns: The `gdImagePtr` of the instantiated image
    /// - Throws: `Error` if decoding failed
    fileprivate func decode(decodable: Data) throws -> gdImagePtr {
        guard decodable.count < Int32.max else { // Bytes must not exceed int32 as limit by `gdImageCreate..Ptr()`
            throw Error.invalidImage(reason: "Given image data exceeds maximum allowed bytes (must be in int32 range)")
        }
        let dataPointer = decodable.withUnsafeBytes({ UnsafeMutableRawPointer(mutating: $0) })
        guard let imagePtr = format.decode(Int32(decodable.count), dataPointer) else {
            throw Error.invalidFormat
        }
        return imagePtr
    }
}

/// Defines a coder to be used on multiple possible supported `DecodableRasterFormat` `Data` decodings
private struct CollectionDataDecoder: Decoder {

    /// The raster formats of the images represented by data passed to this decoder
    fileprivate let formats: [DecodableRasterFormat]

    /// Creates a `gdImagePtr` from given `Data`.
    ///
    /// - Parameter decodable: The image data representation necessary to decode an image instance
    /// - Returns: The `gdImagePtr` of the instantiated image
    /// - Throws: `Error` if decoding failed
    func decode(decodable: Data) throws -> gdImagePtr {
        for format in formats {
            if let result = try? DataDecoder(format: format).decode(decodable: decodable) {
                return result
            }
        }
        throw Error.invalidImage(reason: "No matching decoder for given image found")
    }
}

// MARK: - Encoding

extension EncodableRasterFormat {

    /// Function pointer to one of libgd's built-in `Data` encoding functions
    fileprivate var encode: (_ image: gdImagePtr, _ size: UnsafeMutablePointer<Int32>, _ parameters: Int32) -> UnsafeMutableRawPointer? {
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
}

/// Defines a coder to be used on supported `EncodableRasterFormat` `Data` encoding
private struct DataEncoder: Encoder {

    /// The raster format of the to be created/encoded data represention of images passed to this encoder
    fileprivate let format: EncodableRasterFormat

    /// Creates a `Data` instance from given `gdImagePtr`.
    ///
    /// - Parameter image: The `gdImagePtr` to encode
    /// - Returns: The image data representation of given `image`.
    /// - Throws: `Error` if encoding failed
    func encode(image: gdImagePtr) throws -> Data {
        var size: Int32 = 0
        format.prepare(image: image)
        guard let bytesPtr = format.encode(image, &size, format.encodingParameters) else {
            throw Error.invalidFormat
        }
        return Data(bytes: bytesPtr, count: Int(size))
    }
}

// MARK: - Image Extension

extension Image {

    /// Initializes a new `Image` instance from given image data in specified raster format.
    ///
    /// - Parameters:
    ///   - data: The image data
    ///   - format: The raster format of the image data (e.g. png, webp, ...)
    /// - Throws: `Error` if image `data` in raster `format` could not be decoded
    public convenience init(data: Data, as format: DecodableRasterFormat) throws {
        try self.init(decode: data, using: DataDecoder(format: format))
    }

    /// Initializes a new `Image` instance from given image data in specified raster format.
    /// If formats are omitted, all supported raster formats will be evaluated.
    ///
    /// - Parameters:
    ///   - data: The image data
    ///   - formats: List of possible raster formats of the image data. Defaults to `.any`
    /// - Throws:  `Error` if image `data` is not of any of the given raster `formats`
    public convenience init(data: Data, as oneOf: [DecodableRasterFormat] = DecodableRasterFormat.any) throws {
        try self.init(decode: data, using: CollectionDataDecoder(formats: oneOf))

    }

    /// Exports the image as `Data` object in specified raster format.
    ///
    /// - Parameter format: The raster format of the returning image data. Defaults to `.png` with alpha channel and default compression.
    /// - Returns: The image data
    /// - Throws: `Error` if the export of `self` in specified raster format failed.
    public func export(as format: EncodableRasterFormat = .default) throws -> Data {
        return try encode(using: DataEncoder(format: format))
    }
}
