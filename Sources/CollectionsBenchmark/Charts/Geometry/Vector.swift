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
public struct Vector {
  public var dx: Double
  public var dy: Double

  @inlinable
  public init(dx: Double, dy: Double) {
    self.dx = dx
    self.dy = dy
  }

  @inlinable
  public static var zero: Vector { Vector(dx: 0, dy: 0) }
}

extension Vector: Hashable {
  @inlinable
  public static func ==(left: Self, right: Self) -> Bool {
    left.dx == right.dx && left.dy == right.dy
  }

  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher.combine(dx)
    hasher.combine(dy)
  }
}

extension Vector: Codable {
  public init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    let dx = try container.decode(Double.self)
    let dy = try container.decode(Double.self)
    self.init(dx: dx, dy: dy)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    try container.encode(dx)
    try container.encode(dy)
  }
}

extension Vector {
  @inlinable
  public func applying(_ t: Transform) -> Vector {
    Vector(
      dx: t.a * dx + t.c * dy,
      dy: t.b * dx + t.d * dy)
  }
}
