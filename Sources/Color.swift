import Foundation

// TODO: "Unify" color, or make it more protocol based
// TODO: Support none alpha color

/// A struct that stores color data and opacity (alpha).
public struct Color {

    /// The red component
    public var red: Double

    /// The green component
    public var green: Double

    /// The blue component
    public var blue: Double

    /// The alpha component
    public var alpha: Double

    /// Initializes a new color instance from given component values.
    ///
    /// - Parameters:
    ///   - red: The red component of the new color (clipped between 0...1)
    ///   - green: The green component of the new color (clipped between 0...1)
    ///   - blue: The blue component of the new color (clipped between 0...1)
    ///   - alpha: The alpha component of the new color (clipped between 0...1)
    public init(red: Double, green: Double, blue: Double, alpha: Double) {
        self.red = max(0.0, min(1.0, red))
        self.green = max(0.0, min(1.0, green))
        self.blue =  max(0.0, min(1.0, blue))
        self.alpha =  max(0.0, min(1.0, alpha))
    }
}

// MARK: Description

extension Color: CustomStringConvertible, CustomDebugStringConvertible {

    /// A textual representation of this instance.
    public var description: String {
        return debugDescription
    }

    /// A textual representation of this instance, suitable for debugging.
    public var debugDescription: String {
        return "<red: \(red), green: \(green), blue: \(blue), alpha: \(alpha)>"
    }
}

// MARK: Equatable & Hashable

extension Color: Hashable {

    /// The hash value (the hex value of the color)
    public var hashValue: Int {
        return hex
    }

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    /// - Returns: `true` if both values are equal, `false` otherwise
    public static func == (lhs: Color, rhs: Color) -> Bool {
        return lhs.red == rhs.red
            && lhs.green == rhs.green
            && lhs.blue == rhs.blue
            && lhs.alpha == rhs.alpha
    }
}

// MARK: Constants

extension Color {

    /// Returns opaque red
    public static let red = Color(red: 1, green: 0, blue: 0, alpha: 1)

    /// Returns opaque green
    public static let green = Color(red: 0, green: 1, blue: 0, alpha: 1)

    /// Returns opaque blue
    public static let blue = Color(red: 0, green: 0, blue: 1, alpha: 1)

    /// Returns opaque black
    public static let black = Color(red: 0, green: 0, blue: 0, alpha: 1)

    /// Returns opaque white
    public static let white = Color(red: 1, green: 1, blue: 1, alpha: 1)

    /// Returns transparent black
    public static let transparent = Color(red: 0, green: 0, blue: 0, alpha: 0)
}

// MARK: LibGD

extension Color {

    /*
     gd uses an inverted (0=opaque, 1=transparent) 7-bit alpha channel (2^7=128), as opposed to the 8-bit r/g/b channels.
     This is taken into account in conversions from/to the normalized color that is represented by `this`.
     See: `gdAlpha` and `init(libgd:)`
     Reference: https://github.com/libgd/libgd/issues/132
    */

    /// The red component in libgd space
    internal var gdRed: Int32 {
        return Int32(red * 255)
    }

    /// The green component in libgd space
    internal var gdGreen: Int32 {
        return Int32(green * 255)
    }

    /// The blue component in libgd space
    internal var gdBlue: Int32 {
        return Int32(blue * 255)
    }

    /// The alpha component in libgd space
    internal var gdAlpha: Int32 {
        return 127 - Int32(alpha * 127)
    }

    /// Initializes a new color instance from given libgd color representation.
    ///
    /// This initializes (re-)inverts the alpha channel of the libgd color (which uses inverted
    /// alpha channels by design) and normalizes it around 0.0 (transparent) and 1.0 (opaque).
    ///
    /// - Parameter libgd: The libgd color to create a normalized color from.
    internal init(libgd color: Int32) {
        self.init(
            red: Double((color >> 16) & 0xff) / 255,
            green: Double((color >> 8) & 0xff) / 255,
            blue: Double((color >> 0) & 0xff) / 255,
            alpha: 1 - (Double((color >> 24) & 0xff) / 127)
        )
    }
}

// MARK: Hexadecimal

extension Color {

    /// Returns the color as hex value (RGBA)
    public var hex: Int {
        var hex = Int(red * 255) << 24
        hex += Int(green * 255) << 16
        hex += Int(blue * 255) << 8
        hex += Int(alpha * 255) << 0
        return hex
    }

    /// Returns the color as hex string, e.g "ffee33dd" (RGBA)
    public var hexString: String {
        return String(hex, radix: 16)
    }

    /// Initializes a new `Color` instance of given hexadecimal color string.
    ///
    /// Given string will be stripped from a single leading "#", if applicable.
    /// Resulting string must met any of the following criteria:
    ///
    /// - Is a string with 8-characters and therefore a fully fledged hexadecimal
    ///   color representation **including** an alpha component. Given value will remain
    ///   untouched before conversion. Example: `ffeebbaa`
    /// - Is a string with 6-characters and therefore a fully fledged hexadecimal color
    ///   representation **excluding** an alpha component. Given RGB color components will
    ///   remain untouched and an alpha component of `0xff` (opaque) will be extended before
    ///   conversion. Example: `ffeebb` -> `ffeebbff`
    /// - Is a string with 4-characters and therefore a shortened hexadecimal color
    ///   representation **including** an alpha component. Each single character will be
    ///   doubled before conversion. Example: `feba` -> `ffeebbaa`
    /// - Is a string with 3-characters and therefore a shortened hexadecimal color
    ///   representation **excluding** an alpha component. Given RGB color character will
    ///   be doubled and an alpha of component of `0xff` (opaque) will be extended before
    ///   conversion. Example: `feb` -> `ffeebbff`
    ///
    /// - Parameters:
    ///   - string: The hexadecimal color string.
    ///   - leadingAlpha: Indicate whether given string should be treated as ARGB (`true`) or RGBA (`false`)
    /// - Throws: `.invalidColor` if given string does not match any of the above mentioned criteria or is not a valid hex color.
    public init(hex string: String, leadingAlpha: Bool = false) throws {
        let string = try Color.sanitize(hex: string, leadingAlpha: leadingAlpha)
        let code = try Int(string, radix: 16).or(throw: .invalidColor(reason: "0x\(string) is not a valid hex color code"))
        self.init(hex: code, leadingAlpha: leadingAlpha)
    }

    /// Initializes a new `Color` instance of given hexadecimal color values.
    ///
    /// - Parameters:
    ///   - color: The hexadecimal color value, incl. red, green, blue and alpha
    ///   - space: The color space of given `color`
    ///   - leadingAlpha: Indicates whether given code should be treated as ARGB (`true`) or RGBA (`false`)
    public init(hex color: Int, leadingAlpha: Bool = false) {

        let first = Double((color >> 24) & 0xff) / 255
        let second = Double((color >> 16) & 0xff) / 255
        let third = Double((color >>  8) & 0xff) / 255
        let fourth = Double((color >>  0) & 0xff) / 255

        if leadingAlpha {
            self.init(red: second, green: third, blue: fourth, alpha: first) // ARGB
        } else {
            self.init(red: first, green: second, blue: third, alpha: fourth) // RGBA
        }
    }

    // MARK: Private helper

    /// Sanitizes given hexadecimal color string (strips # and forms proper length).
    ///
    /// - Parameters:
    ///   - string: The hexadecimal color string to sanitize
    ///   - leadingAlpha: Indicate whether given and returning string should be treated as ARGB (`true`) or RGBA (`false`)
    /// - Returns: The sanitized hexadecimal color string
    /// - Throws: `.invalidColor` if given string is not of proper length
    private static func sanitize(hex string: String, leadingAlpha: Bool) throws -> String {

        // Drop whitespaces and newline characters as well as a leading "#" if applicable
        var string = string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "", options: .anchored)

        // Evaluate if short code w/wo alpha (e.g. `feb` or `feb4`). Double up the characters if so.
        if string.count == 3 || string.count == 4 {
            string = string.map({ "\($0)\($0)" }).joined()
        }

        // Evaluate if fully fledged code w/wo alpha (e.g. `ffaabb` or `ffaabb44`), otherwise throw error
        switch string.count {
        case 6: // Hex color code without alpha (e.g. ffeeaa)
            let alpha = String(0xff, radix: 16) // 0xff (opaque)
            return leadingAlpha ? alpha + string : string + alpha
        case 8: // Fully fledged hex color including alpha (e.g. eebbaa44)
            return string
        default:
            throw Error.invalidColor(reason: "0x\(string) has invalid hex color string length")
        }
    }
}
