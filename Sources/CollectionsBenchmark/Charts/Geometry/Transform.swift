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

/// A 2D affine transformation represented by a 3x3 matrix:
///
///     a   b   0
///     c   d   0
///     tx  ty  1
@frozen
public struct Transform {
  public var a: Double
  public var b: Double
  public var c: Double
  public var d: Double
  public var tx: Double
  public var ty: Double

  @inlinable
  public init(
    a: Double,
    b: Double,
    c: Double,
    d: Double,
    tx: Double,
    ty: Double
  ) {
    self.a = a
    self.b = b
    self.c = c
    self.d = d
    self.tx = tx
    self.ty = ty
  }
}

extension Transform: Hashable {
  public static func ==(left: Self, right: Self) -> Bool {
    left.a == right.a
      && left.b == right.b
      && left.c == right.c
      && left.d == right.d
      && left.tx == right.tx
      && left.ty == right.ty
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(a)
    hasher.combine(b)
    hasher.combine(c)
    hasher.combine(d)
    hasher.combine(tx)
    hasher.combine(ty)
  }
}

extension Transform: Codable {
  public init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    let a = try container.decode(Double.self)
    let b = try container.decode(Double.self)
    let c = try container.decode(Double.self)
    let d = try container.decode(Double.self)
    let tx = try container.decode(Double.self)
    let ty = try container.decode(Double.self)
    self.init(a: a, b: b, c: c, d: d, tx: tx, ty: ty)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    try container.encode(a)
    try container.encode(b)
    try container.encode(c)
    try container.encode(d)
    try container.encode(tx)
    try container.encode(ty)
  }
}

extension Transform {
  @inlinable
  public static var identity: Transform {
    Transform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0)
  }

  public func concatenating(_ other: Transform) -> Transform {
    Transform(
      a: self.a * other.a + self.b * other.c,
      b: self.a * other.b + self.b * other.d,
      c: self.c * other.a + self.d * other.c,
      d: self.c * other.b + self.d * other.d,
      tx: self.tx * other.a + self.ty * other.c + other.tx,
      ty: self.tx * other.b + self.ty * other.d + other.ty)
  }

  public func scaled(_ scale: Double) -> Transform {
    Transform(
      a: scale * a,
      b: scale * b,
      c: scale * c,
      d: scale * d,
      tx: tx,
      ty: ty)
  }

  public func scaled(x: Double, y: Double) -> Transform {
    Transform(
      a: x * a,
      b: x * b,
      c: y * c,
      d: y * d,
      tx: tx,
      ty: ty)
  }

  public func translated(x: Double, y: Double) -> Transform {
    Transform(
      a: a,
      b: b,
      c: c,
      d: d,
      tx: tx + x * a + y * c,
      ty: ty + x * b + y * d)
  }

  public func rotated(_ radians: Double) -> Transform {
    let cosine = _cos(radians)
    let sine = _sin(radians)
    let rotation = Transform(a: cosine, b: sine, c: -sine, d: cosine, tx: 0, ty: 0)
    return self.concatenating(rotation)
  }
}
