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
public struct Point {
  public var x: Double
  public var y: Double

  @inlinable
  public init(x: Double, y: Double) {
    self.x = x
    self.y = y
  }

  @inlinable
  public static var zero: Point { Point(x: 0, y: 0) }
}

extension Point: Hashable {
  @inlinable
  public static func ==(left: Self, right: Self) -> Bool {
    left.x == right.x && left.y == right.y
  }

  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher.combine(x)
    hasher.combine(y)
  }
}

extension Point: Codable {
  public init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    let x = try container.decode(Double.self)
    let y = try container.decode(Double.self)
    self.init(x: x, y: y)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    try container.encode(x)
    try container.encode(y)
  }
}

extension Point {
  @inlinable
  public func applying(_ t: Transform) -> Point {
    Point(
      x: t.a * x + t.c * y + t.tx,
      y: t.b * x + t.d * y + t.ty)
  }
}
