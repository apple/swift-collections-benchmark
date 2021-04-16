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

@frozen
public struct Rectangle {
  public var origin: Point
  public var size: Vector

  @inlinable
  public init(origin: Point, size: Vector) {
    self.origin = origin
    self.size = size
  }

  @inlinable
  public init(x: Double, y: Double, width: Double, height: Double) {
    self.origin = Point(x: x, y: y)
    self.size = Vector(dx: width, dy: height)
  }

  @inlinable
  public init<N: BinaryInteger>(x: N, y: N, width: N, height: N) {
    self.init(
      x: Double(x),
      y: Double(y),
      width: Double(width),
      height: Double(height))
  }

  @inlinable
  public init<N: BinaryFloatingPoint>(x: N, y: N, width: N, height: N) {
    self.init(
      x: Double(x),
      y: Double(y),
      width: Double(width),
      height: Double(height))
  }

  public static var null: Rectangle {
    Rectangle(x: .infinity, y: .infinity, width: 0, height: 0)
  }

  public var minX: Double { origin.x + min(0, size.dx) }
  public var maxX: Double { origin.x + max(0, size.dx) }
  public var midX: Double { 0.5 * (minX + maxX) }

  public var minY: Double { origin.y + min(0, size.dy) }
  public var maxY: Double { origin.y + max(0, size.dy) }
  public var midY: Double { 0.5 * (minY + maxY) }

  @inlinable public var width: Double { abs(size.dx) }
  @inlinable public var height: Double { abs(size.dy) }
}

extension Rectangle: Hashable {
  public static func ==(left: Self, right: Self) -> Bool {
    let r1 = left.standardized
    let r2 = right.standardized
    return r1.origin == r2.origin && r1.size == r2.size
  }

  public func hash(into hasher: inout Hasher) {
    let r = self.standardized
    hasher.combine(r.origin)
    hasher.combine(r.size)
  }
}

extension Rectangle: Codable {
  public init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    let origin = try container.decode(Point.self)
    let size = try container.decode(Vector.self)
    self.init(origin: origin, size: size)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    try container.encode(origin)
    try container.encode(size)
  }
}

extension Rectangle {
  public var isNull: Bool {
    (origin.x.isInfinite && origin.x.sign == .plus)
      || (origin.y.isInfinite && origin.y.sign == .plus)
  }

  public func intersects(_ other: Rectangle) -> Bool {
    let r1 = self.standardized
    let r2 = other.standardized
    guard !r1.isNull && !r2.isNull else { return false }

    let minX1 = r1.origin.x
    let minX2 = r2.origin.x
    if minX1 < minX2, r1.origin.x + r1.size.dx <= minX2 { return false }
    if minX1 > minX2, r2.origin.x + r2.size.dx <= minX1 { return false }

    let minY1 = r1.origin.y
    let minY2 = r2.origin.y
    if minY1 < minY2, r1.origin.y + r1.size.dy <= minY2 { return false }
    if minY1 > minY2, r2.origin.y + r2.size.dy <= minY1 { return false }
    return true
  }
}

extension Rectangle {
  public func inset(by insets: EdgeInsets) -> Rectangle {
    let r = Rectangle(
      x: self.minX + insets.minX,
      y: self.minY + insets.minY,
      width: self.width - insets.dx,
      height: self.height - insets.dy)
    guard r.size.dx >= 0 && r.size.dy >= 0 else { return .null }
    return r
  }

  public func inset(dx: Double, dy: Double) -> Rectangle {
    inset(by: EdgeInsets(minX: dx, minY: dy, maxX: dx, maxY: dy))
  }

  public var standardized: Rectangle {
    Rectangle(x: minX, y: minY, width: width, height: height)
  }

  public var integral: Rectangle {
    Rectangle(
      x: minX.rounded(.down),
      y: minY.rounded(.down),
      width: width.rounded(.up),
      height: height.rounded(.up))
  }

  public enum Edge {
    case minX
    case maxX
    case minY
    case maxY
  }

  public func divided(
    atDistance distance: Double,
    from edge: Edge
  ) -> (slice: Rectangle, remainder: Rectangle) {
    let r = self.standardized
    guard !r.isNull else { return (.null, .null) }
    let split: Double
    switch edge {
    case .minX:
      split = min(max(distance, 0), r.size.dx)
    case .maxX:
      split = r.size.dx - min(max(distance, 0), r.size.dx)
    case .minY:
      split = min(max(distance, 0), r.size.dy)
    case .maxY:
      split = r.size.dy - min(max(distance, 0), r.size.dy)
    }

    switch edge {
    case .minX, .maxX:
      let r1 = Rectangle(x: r.origin.x, y: r.origin.y,
                         width: split, height: r.size.dy)
      let r2 = Rectangle(x: r.origin.x + split, y: r.origin.y,
                         width: r.size.dx - split, height: r.size.dy)
      return (edge == .minX ? (r1, r2) : (r2, r1))
    case .minY, .maxY:
      let r1 = Rectangle(x: r.origin.x, y: r.origin.y,
                         width: r.size.dx, height: split)
      let r2 = Rectangle(x: r.origin.x, y: r.origin.y + split,
                         width: r.size.dx, height: r.size.dy - split)
      return (edge == .minY ? (r1, r2) : (r2, r1))
    }
  }
}

