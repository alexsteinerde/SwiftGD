#if os(Linux)
	import Glibc
	import Cgdlinux
#else
	import Darwin
	import Cgdmac
#endif

import Foundation

// MARK: Incorporate "success" return values (GD_TRUE (1) on success, GD_FALSE (0) on failure)

/// Allows a more "swifty" handling of gdimage pointer instances within the module
internal typealias GDImage = gdImagePtr

// In case you were wondering: it's a class rather than a struct because we need
// deinit to free the internal GD pointer, and that's only available to classes.
public final class Image {

    /// The underlying image to manage and process
	private var internalImage: gdImagePtr

    /// Initializes a new image handling/representing given `gdImagePtr`
    ///
    /// - Parameter gdImage: The underlying image of the `Image` instance to be created.
    private init(gdImage: gdImagePtr) {
        internalImage = gdImage
    }

    /// Destroys the internal image resource
    deinit {
        gdImageDestroy(internalImage)
    }
}

// MARK: Properties & Subscripts

extension Image {

    /// The size of the image in pixel
    public var size: Size {
        return Size(width: internalImage.pointee.sx, height: internalImage.pointee.sy)
    }

    /// Returns or sets the color of given `pixel` coordinate (`Point`).
    ///
    /// - Parameter pixel: The pixel to read or write given color
    public subscript(pixel: Point) -> Color {
        get { return self[pixel.x, pixel.y] }
        set { self[pixel.x, pixel.y] = newValue }
    }

    /// Returns or sets the color of given `pixel` coordinate.
    ///
    /// - Parameter pixel: The pixel to read or write given color
    public subscript(x: Int32, y: Int32) -> Color {
        get {
            return Color(libgd: gdImageGetTrueColorPixel(internalImage, x, y))
        }
        set {
            let color = gdImageColorAllocateAlpha(internalImage, newValue.gdRed, newValue.gdGreen, newValue.gdBlue, newValue.gdAlpha)
            gdImageSetPixel(internalImage, x, y, color)
            gdImageColorDeallocate(internalImage, color)
        }
    }
}

// MARK: Plain True Color Image

extension Image {

    /// Initializes a new true color image of given size
    ///
    /// - Parameters:
    ///   - width: The width of the image
    ///   - height: The height of the image
    public convenience init(width: Int32, height: Int32) throws {
        try self.init(size: Size(width: width, height: height))
    }

    /// Initializes a new true color image of given size
    ///
    /// - Parameters:
    ///   - size: The size of the image
    public convenience init(size: Size) throws {
        guard let image = gdImageCreateTrueColor(size.width, size.height) else {
            throw Error.invalidImage(reason: "True color image of size \(size.width)x\(size.height) could not be created")
        }
        self.init(gdImage: image)
    }
}

// MARK: Generic Image Coding

extension Image {

    /// Initializes a new `Image` instance using given `decoder` to decode given `Decodable` image representation.
    ///
    /// - Parameters:
    ///    - decodable: The `Decodable` that represents an image.
    ///    - decoder: The `Decoder` that can decode given `Decodable` image representation.
    /// - Returns: An `Image` instance of the image represented by `Decodable`.
    /// - Throws: `Error` if the image representation of `Decodable` could not be decoded.
    internal convenience init<T: Decoder>(decode decodable: T.Decodable, using decoder: T) throws {
        self.init(gdImage: try decoder.decode(decodable: decodable))
    }

    /// Exports the image as `Encodable` using given `encoder` for image encoding
    ///
    /// - Parameter encoder: The `Encoder` to use for encoding the image (`self`) as `Encodable`.
    /// - Returns: The `Encodable` that represents the image (`self`)
    /// - Throws: `Error` if the encoding of `self` using given `encoder` failed.
    internal func encode<T: Encoder>(using encoder: T) throws -> T.Encodable {
        return try encoder.encode(image: internalImage)
    }
}

// MARK: - Drawing

extension Image {

    public func fill(from point: Point, color: Color) {
        let color = gdImageColorAllocateAlpha(internalImage, color.gdRed, color.gdGreen, color.gdBlue, color.gdAlpha)
        gdImageFill(internalImage, point.x, point.y, color)
        gdImageColorDeallocate(internalImage, color)
    }

    public func drawLine(from point1: Point, to point2: Point, color: Color) {
        let color = gdImageColorAllocateAlpha(internalImage, color.gdRed, color.gdGreen, color.gdBlue, color.gdAlpha)
        gdImageLine(internalImage, point1.x, point1.y, point2.x, point2.y, color)
        gdImageColorDeallocate(internalImage, color)
    }

    public func strokeEllipse(center: Point, size: Size, color: Color) {
        let color = gdImageColorAllocateAlpha(internalImage, color.gdRed, color.gdGreen, color.gdBlue, color.gdAlpha)
        gdImageEllipse(internalImage, center.x, center.y, size.width, size.height, color)
        gdImageColorDeallocate(internalImage, color)
    }

    public func strokeEllipse(rectangle: Rectangle, color: Color) {
        strokeEllipse(center: rectangle.center, size: rectangle.size, color: color)
    }

    public func fillEllipse(center: Point, size: Size, color: Color) {
        let color = gdImageColorAllocateAlpha(internalImage, color.gdRed, color.gdGreen, color.gdBlue, color.gdAlpha)
        gdImageFilledEllipse(internalImage, center.x, center.y, size.width, size.height, color)
        gdImageColorDeallocate(internalImage, color)
    }

    public func fillEllipse(rectangle: Rectangle, color: Color) {
        fillEllipse(center: rectangle.center, size: rectangle.size, color: color)
    }

    public func strokeRectangle(topLeft: Point, bottomRight: Point, color: Color) {
        let color = gdImageColorAllocateAlpha(internalImage, color.gdRed, color.gdGreen, color.gdBlue, color.gdAlpha)
        gdImageRectangle(internalImage, topLeft.x, topLeft.y, bottomRight.x, bottomRight.y, color)
        gdImageColorDeallocate(internalImage, color)
    }

    public func strokeRectangle(_ rectangle: Rectangle, color: Color) {
        let bottomRight = Point(x: rectangle.origin.x + size.width, y: rectangle.origin.y + size.width)
        strokeRectangle(topLeft: rectangle.origin, bottomRight: bottomRight, color: color)
    }

    public func fillRectangle(topLeft: Point, bottomRight: Point, color: Color) {
        let color = gdImageColorAllocateAlpha(internalImage, color.gdRed, color.gdGreen, color.gdBlue, color.gdAlpha)
        gdImageFilledRectangle(internalImage, topLeft.x, topLeft.y, bottomRight.x, bottomRight.y, color)
        gdImageColorDeallocate(internalImage, color)
    }

    public func fillRectangle(_ rectangle: Rectangle, color: Color) {
        let bottomRight = Point(x: rectangle.origin.x + size.width, y: rectangle.origin.y + size.width)
        fillRectangle(topLeft: rectangle.origin, bottomRight: bottomRight, color: color)
    }
}

// MARK: - Resizing

extension Image {

    public func applyInterpolation(enabled: Bool, currentSize: Size, newSize: Size) {
        if !enabled {
            gdImageSetInterpolationMethod(internalImage, GD_NEAREST_NEIGHBOUR)
        } else if currentSize > newSize {
            gdImageSetInterpolationMethod(internalImage, GD_SINC)
        } else if currentSize < newSize {
            gdImageSetInterpolationMethod(internalImage, GD_MITCHELL)
        } else {
            gdImageSetInterpolationMethod(internalImage, GD_NEAREST_NEIGHBOUR)
        }
    }

    public func resizeTo(size newSize: Size, applySmoothing: Bool = true) throws {
        applyInterpolation(enabled: applySmoothing, currentSize: size, newSize: newSize)
        guard let output = gdImageScale(internalImage, UInt32(newSize.width), UInt32(newSize.height)) else {
            throw Error.resizingFailed(reason: "Could not resize image")
        }
        gdImageDestroy(internalImage)
        internalImage = output
    }

    public func resizeTo(width: Int32, height: Int32, applySmoothing: Bool = true) throws {
        try resizeTo(size: Size(width: width, height: height), applySmoothing: applySmoothing)
    }

    public func resizeTo(width: Int32, applySmoothing: Bool = true) throws {
        let currentSize = size
        let heightAdjustment = Double(width) / Double(currentSize.width)
        try resizeTo(width: width, height: Int32(Double(currentSize.height) * Double(heightAdjustment)), applySmoothing: applySmoothing)
    }

    public func resizeTo(height: Int32, applySmoothing: Bool = true) throws {
        let currentSize = size
        let widthAdjustment = Double(height) / Double(currentSize.height)
        try resizeTo(width: Int32(Double(currentSize.width) * Double(widthAdjustment)), height: height, applySmoothing: applySmoothing)
    }

    public func resizedTo(size newSize: Size, applySmoothing: Bool = true) throws -> Image {
        applyInterpolation(enabled: applySmoothing, currentSize: size, newSize: newSize)
        guard let output = gdImageScale(internalImage, UInt32(newSize.width), UInt32(newSize.height)) else {
            throw Error.resizingFailed(reason: "Could not resize image")
        }
        return Image(gdImage: output)
    }

    public func resizedTo(width: Int32, height: Int32, applySmoothing: Bool = true) throws -> Image {
        return try resizedTo(size: Size(width: width, height: height), applySmoothing: applySmoothing)
    }

	public func resizedTo(width: Int32, applySmoothing: Bool = true) throws -> Image {
		let heightAdjustment = Double(width) / Double(size.width)
        let height = Int32(Double(size.height) * Double(heightAdjustment))
        return try resizedTo(width: width, height: height, applySmoothing: applySmoothing)
	}

	public func resizedTo(height: Int32, applySmoothing: Bool = true) throws -> Image {
		let widthAdjustment = Double(height) / Double(size.height)
        return try resizedTo(width: Int32(Double(size.width) * Double(widthAdjustment)), height: height, applySmoothing: applySmoothing)
	}
}

// MARK: - Cropping

extension Image {

    // MARK: In-Place

    /// <#Description#>
    ///
    /// - Parameter frame: <#frame description#>
    /// - Throws: <#throws value description#>
    public func crop(using frame: Rectangle) throws {
        var rect = gdRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: frame.size.height)
        guard let image = gdImageCrop(internalImage, &rect) else {
            throw Error.croppingFailed(reason: "Could not crop image")
        }
        gdImageDestroy(internalImage)
        internalImage = image
    }

    // MARK: Cropped Copies

    /// <#Description#>
    ///
    /// - Parameter frame: <#frame description#>
    /// - Returns: <#return value description#>
    /// - Throws: <#throws value description#>
    public func cropped(using frame: Rectangle) throws -> Image {
        var rect = gdRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: frame.size.height)
        guard let image = gdImageCrop(internalImage, &rect) else {
            throw Error.croppingFailed(reason: "Could not crop image")
        }
        return Image(gdImage: image)
    }
}

// MARK: - Manipulating

extension Image {

    /// Describes the axis around which the image should be flipped
    ///
    /// - horizontal: Flips the image horizontally
    /// - vertical: Flips the image vertically
    /// - both: Flips the image around both axis, horizontally & vertically
    public enum FlipMode {
        case horizontal
        case vertical
        case both
    }

    @discardableResult
    public func write(to url: URL, quality: Int = 100, allowOverwrite: Bool = false) -> Bool {
        let fileType = url.pathExtension.lowercased()
        guard fileType == "png" || fileType == "jpeg" || fileType == "jpg" else { return false }
        
        let fm = FileManager()
        
        if !allowOverwrite {
            // refuse to overwrite existing files
            guard fm.fileExists(atPath: url.path) == false else { return false }
        }
        
        // open our output file, then defer it to close
        let outputFile = fopen(url.path, "wb")
        defer { fclose(outputFile) }
        
        // write the correct output format based on the path extension
        switch fileType {
        case "png":
            gdImageSaveAlpha(internalImage, 1)
            gdImagePng(internalImage, outputFile)
        case "jpg", "jpeg":
            gdImageJpeg(internalImage, outputFile, Int32(quality))
        default:
            return false
        }
        
        // return true or false based on whether the output file now exists
        return fm.fileExists(atPath: url.path)
    }
    
	public func flip(_ mode: FlipMode) {
		switch mode {
		case .horizontal:
			gdImageFlipHorizontal(internalImage)
		case .vertical:
			gdImageFlipVertical(internalImage)
		case .both:
			gdImageFlipBoth(internalImage)
		}
	}

    public func colorize(using color: Color) {
        gdImageColor(internalImage, color.gdRed, color.gdGreen, color.gdBlue, color.gdAlpha)
    }

    public func desaturate() {
        gdImageGrayScale(internalImage)
    }

	public func pixelate(blockSize: Int32) {
		gdImagePixelate(internalImage, blockSize, GD_PIXELATE_AVERAGE.rawValue)
	}

    public func blur(radius: Int32) throws {
        guard let result = gdImageCopyGaussianBlurred(internalImage, radius, -1) else {
            throw Error.manipulationFailed(reason: "Could not blur image")
        }
        gdImageDestroy(internalImage)
        internalImage = result
    }

    public func blurred(radius: Int32) throws -> Image {
        guard let result = gdImageCopyGaussianBlurred(internalImage, radius, -1) else {
            throw Error.manipulationFailed(reason: "Could not blur image")
        }
        return Image(gdImage: result)
    }
}

// MARK: - Cloning & Copying

extension Image {

    /// Merges `other` image into this using given `rect` as content area for the new image.
    ///
    /// - Parameters:
    ///   - other: The `other` image to merge into this image.
    ///   - rect: The area within this image to draw the `other` image into.
    /// - Throws: An error if merge failed.
    public func merge(with other: Image, in rect: Rectangle) throws {
        gdImageCopy(internalImage, other.internalImage, rect.origin.x, rect.origin.y, 0, 0, rect.size.width, rect.size.height)
    }

    /// Merges `other` image into this starting at `point`.
    ///
    /// - Parameters:
    ///   - other: The `other` image to merge into this image.
    ///   - point: The starting `Point` at which to start merging.
    /// - Throws: An error if merge failed.
    public func merge(with other: Image, at point: Point) throws {
        try merge(with: other, in: Rectangle(origin: point, size: other.size))
    }
}
