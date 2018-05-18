import Foundation

// MARK: - Point

/// A structure that contains a point in a two-dimensional coordinate system.
public struct Point {

    /// The x-coordinate of the point.
    public var x: Int32

    /// The y-coordinate of the point.
    public var y: Int32

    /// The point at the origin (0,0).
    public static let zero = Point(x: 0, y: 0)

    /// Initializes a new point at given coordinates.
    ///
    /// - Parameters:
    ///   - x: The x-coordinate of the point.
    ///   - y: The y-coordinate of the point.
    public init(x: Int32, y: Int32) {
        self.x = x
        self.y = y
    }
}

extension Point: Equatable {

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (lhs: Point, rhs: Point) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
}

// MARK: - Size

/// A structure that represents a two-dimensional size.
public struct Size {

    /// The width value of the size.
    public var width: Int32

    /// The height value of the size.
    public var height: Int32

    /// Size whose width and height are both zero.
    public static let zero = Size(width: 0, height: 0)

    /// Initializes a new size of given dimensions.
    ///
    /// - Parameters:
    ///   - width: The width value of the size.
    ///   - height: The height value of the size.
    public init(width: Int32, height: Int32) {
        self.width = width
        self.height = height
    }
}

extension Size: Comparable {

    /// Returns a Boolean value indicating whether the value of the first
    /// argument is less than that of the second argument.
    ///
    /// This function is the only requirement of the `Comparable` protocol. The
    /// remainder of the relational operator functions are implemented by the
    /// standard library for any type that conforms to `Comparable`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func < (lhs: Size, rhs: Size) -> Bool {
        return lhs.width * lhs.height < rhs.width * rhs.height
    }

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (lhs: Size, rhs: Size) -> Bool {
        return lhs.width == rhs.width && lhs.height == rhs.height
    }
}

// MARK: - Rectangle

/// A structure that represents a rectangle.
public struct Rectangle {

    /// The origin of the rectangle.
    public var origin: Point

    /// The size of the rectangle.
    public var size: Size

    /// The center point of the rectangle.
    public var center: Point {
        return Point(
            x: origin.x + (size.width >> 1),
            y: origin.x + (size.height >> 1)
        )
    }

    /// Initializes a new rectangle at given point of given size.
    ///
    /// - Parameters:
    ///   - origin: The origin of the rectangle.
    ///   - size: The size of the rectangle.
    public init(origin: Point, size: Size) {
        self.origin = origin
        self.size = size
    }
}

extension Rectangle {

    /// Rectangle at the origin whose width and height are both zero.
    public static let zero = Rectangle(origin: .zero, size: .zero)

    /// Creates a rectangle at specified point and given size.
    ///
    /// - Parameters:
    ///   - x: The x-coordinate of the point
    ///   - y: The y-coordinate of the point
    ///   - width: The width value of the size
    ///   - height: The height value of the size
    public init(x: Int32, y: Int32, width: Int32, height: Int32) {
        self.init(origin: Point(x: x, y: y), size: Size(width: width, height: height))
    }
}

extension Rectangle: Equatable {

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (lhs: Rectangle, rhs: Rectangle) -> Bool {
        return lhs.origin == rhs.origin && lhs.size == rhs.size
    }
}
