//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import CoreGraphics

extension Color {
  @available(macOS 10.11, *)
  public init?(_ color: CGColor) {
    guard
      let space = CGColorSpace(name: CGColorSpace.sRGB),
      let color = color.converted(to: space, intent: .saturation, options: nil),
      let comps = color.components,
      comps.count == 4
    else {
      return nil
    }
    self.init(srgbComponents: (comps[0], comps[1], comps[2], comps[3]))
  }

  public var cgColor: CGColor {
    let comps = srgbComponents
    if #available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *) {
      return CGColor(
        srgbRed: comps.red,
        green: comps.green,
        blue: comps.blue,
        alpha: comps.alpha)
    } else {
      return CGColor(
        colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
        components: [comps.red, comps.green, comps.blue, comps.alpha])!
    }
  }
}

extension CGLineCap {
  public init(_ style: Stroke.CapStyle) {
    switch style {
    case .butt: self = .butt
    case .round: self = .round
    case .square: self = .square
    }
  }
}

extension CGLineJoin {
  public init(_ style: Stroke.JoinStyle) {
    switch style {
    case .bevel: self = .bevel
    case .miter: self = .miter
    case .round: self = .round
    }
  }
}

#endif // os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
