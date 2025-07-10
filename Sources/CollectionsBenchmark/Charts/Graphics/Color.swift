//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A color in sRGB color space, with an alpha channel and 8-bit components.
public struct Color: Sendable, Hashable {
  public var red: UInt8
  public var green: UInt8
  public var blue: UInt8
  public var alpha: UInt8

  public init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8 = 255) {
    self.red = red
    self.green = green
    self.blue = blue
    self.alpha = alpha
  }

  public typealias RGBComponents =
    (red: Double, green: Double, blue: Double, alpha: Double)

  public init(srgbComponents srgb: RGBComponents) {
    self.red = UInt8((255 * min(max(srgb.red, 0), 1)).rounded())
    self.green = UInt8((255 * min(max(srgb.green, 0), 1)).rounded())
    self.blue = UInt8((255 * min(max(srgb.blue, 0), 1)).rounded())
    self.alpha = UInt8((255 * min(max(srgb.alpha, 0), 1)).rounded())
  }

  public var srgbComponents: RGBComponents {
    (Double(red) / 255,
     Double(green) / 255,
     Double(blue) / 255,
     Double(alpha) / 255)
  }
}

extension Color {
  static var white: Color { Color(red: 255, green: 255, blue: 255) }
  static var black: Color { Color(red: 0, green: 0, blue: 0) }
  static var clear: Color { Color(red: 0, green: 0, blue: 0, alpha: 0) }
}

extension Color {
  public func withAlphaFactor(_ value: Double) -> Color {
    var comps = srgbComponents
    comps.alpha *= value
    return Self(srgbComponents: comps)
  }
}

extension Color {
  public init(
    hue: Double,
    saturation: Double,
    brightness: Double,
    alpha: Double
  ) {
    let hue = hue - hue.rounded(.down)
    let segment = (6 * hue).rounded(.down)
    let fraction = 6 * hue - segment
    let p = brightness * (1 - saturation)
    let q = brightness * (1 - saturation * fraction)
    let t = brightness * (1 - saturation * (1 - fraction))
    let srgb: RGBComponents
    switch Int(segment) % 6 {
    case 0: srgb = (red: brightness, green: t, blue: p, alpha: alpha)
    case 1: srgb = (red: q, green: brightness, blue: p, alpha: alpha)
    case 2: srgb = (red: p, green: brightness, blue: t, alpha: alpha)
    case 3: srgb = (red: p, green: q, blue: brightness, alpha: alpha)
    case 4: srgb = (red: t, green: p, blue: brightness, alpha: alpha)
    case 5: srgb = (red: brightness, green: p, blue: q, alpha: alpha)
    default: fatalError()
    }
    self.init(srgbComponents: srgb)
  }
}

extension Color: CustomStringConvertible {
  internal static func _hexstring(for value: UInt8) -> String {
    var hex = String(value, radix: 16, uppercase: true)
    if hex.count == 1 { hex = "0" + hex }
    assert(hex.count == 2)
    return hex
  }

  public var description: String {
    var result = "#"
    result += Self._hexstring(for: red)
    result += Self._hexstring(for: green)
    result += Self._hexstring(for: blue)
    result += Self._hexstring(for: alpha)
    return result
  }
}

extension Color: LosslessStringConvertible {
  public init?(_ string: String) {
    guard string.first == "#" else { return nil }
    guard string.count <= 9 else { return nil }
    guard let value = UInt32(string.dropFirst(), radix: 16) else { return nil }
    switch string.count {
    case 4: // #rgb
      self.red   = UInt8((value & 0xF00) >> 4)
      self.green = UInt8(value & 0x0F0)
      self.blue  = UInt8((value & 0x00F) << 4)
      self.alpha = 255
    case 5: // #rgba
      self.red   = UInt8((value & 0xF000) >> 8)
      self.green = UInt8((value & 0x0F00) >> 4)
      self.blue  = UInt8(value & 0x00F0)
      self.alpha = UInt8((value & 0x000F) << 4)
    case 7: // #rrggbb
      self.red   = UInt8((value & 0xFF0000) >> 16)
      self.green = UInt8((value & 0x00FF00) >> 8)
      self.blue  = UInt8((value & 0x0000FF))
      self.alpha = 255
    case 9: // #rrggbbaa
      self.red   = UInt8((value & 0xFF000000) >> 24)
      self.green = UInt8((value & 0x00FF0000) >> 16)
      self.blue  = UInt8((value & 0x0000FF00) >> 8)
      self.alpha = UInt8((value & 0x000000FF))
    default:
      return nil
    }
  }
}

extension Color: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.init(value)!
  }
}

extension Color: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let string = try container.decode(String.self)
    guard let color = Color(string) else {
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Invalid color value '\(string)'")
    }
    self = color
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(description)
  }
}

extension Color {
  // Colors that work well on a light background.
  enum LightPalette {
    public static var red: Color { "#FF3B30FF" }
    public static var blue: Color { "#007AFFFF" }
    public static var green: Color { "#28CD41FF" }
    public static var yellow: Color { "#FFCC00FF" }
    public static var indigo: Color { "#5856D6FF" }
    public static var orange: Color { "#FF9500FF" }
    public static var brown: Color { "#A2845EFF" }
    public static var purple: Color { "#AF52DEFF" }
    public static var gray: Color { "#8E8E93FF" }
    public static var teal: Color { "#55BEF0FF" }
    public static var pink: Color { "#FF2D55FF" }
  }

  // Colors that work well on a dark background.
  enum DarkPalette {
    public static var red: Color { "#FF453AFF" }
    public static var blue: Color { "#0A84FFFF" }
    public static var green: Color { "#32D74BFF" }
    public static var yellow: Color { "#FFD60AFF" }
    public static var indigo: Color { "#5E5CE6FF" }
    public static var orange: Color { "#FF9F0AFF" }
    public static var brown: Color { "#AC8E68FF" }
    public static var purple: Color { "#BF5AF2FF" }
    public static var gray: Color { "#98989DFF" }
    public static var teal: Color { "#5AC8F5FF" }
    public static var pink: Color { "#FF375FFF" }
  }
}
