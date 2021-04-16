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

extension CGPoint {
  public init(_ point: Point) {
    self.init(x: point.x, y: point.y)
  }
}

extension Point {
  public init(_ point: CGPoint) {
    self.init(x: Double(point.x), y: Double(point.y))
  }
}

extension CGSize {
  public init(_ vector: Vector) {
    self.init(width: CGFloat(vector.dx), height: CGFloat(vector.dy))
  }
}

extension Vector {
  public init(_ size: CGSize) {
    self.init(dx: Double(size.width), dy: Double(size.height))
  }
}

extension CGRect {
  public init(_ rect: Rectangle) {
    self.init(
      x: rect.origin.x,
      y: rect.origin.y,
      width: rect.size.dx,
      height: rect.size.dy)
  }
}

extension Rectangle {
  public init(_ rect: CGRect) {
    self.init(
      x: Double(rect.origin.x),
      y: Double(rect.origin.y),
      width: Double(rect.size.width),
      height: Double(rect.size.height))
  }
}

extension CGAffineTransform {
  public init(_ t: Transform) {
    self.init(
      a: CGFloat(t.a),
      b: CGFloat(t.b),
      c: CGFloat(t.c),
      d: CGFloat(t.d),
      tx: CGFloat(t.tx),
      ty: CGFloat(t.ty))
  }
}

extension Transform {
  public init(_ t: CGAffineTransform) {
    self.init(
      a: Double(t.a),
      b: Double(t.b),
      c: Double(t.c),
      d: Double(t.d),
      tx: Double(t.tx),
      ty: Double(t.ty))
  }
}


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
    self.init(
      srgbComponents: (
        Double(comps[0]),
        Double(comps[1]),
        Double(comps[2]),
        Double(comps[3])))
  }

  public var cgColor: CGColor {
    let comps = srgbComponents
    if #available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *) {
      return CGColor(
        srgbRed: CGFloat(comps.red),
        green: CGFloat(comps.green),
        blue: CGFloat(comps.blue),
        alpha: CGFloat(comps.alpha))
    } else {
      return CGColor(
        colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
        components: [
          CGFloat(comps.red),
          CGFloat(comps.green),
          CGFloat(comps.blue),
          CGFloat(comps.alpha)])!
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
