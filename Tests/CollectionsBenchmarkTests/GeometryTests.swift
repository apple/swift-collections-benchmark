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

import XCTest
import CollectionsBenchmark

final class GeometryTests: XCTestCase {
  func testPoint() {
    let p1 = Point(x: 1, y: 2)
    XCTAssertEqual(p1.x, 1)
    XCTAssertEqual(p1.y, 2)

    let p2 = Point(x: 2, y: 1)
    XCTAssertEqual(p2.x, 2)
    XCTAssertEqual(p2.y, 1)

    XCTAssertEqual(p1, Point(x: 1, y: 2))
    XCTAssertNotEqual(p1, p2)

    var hasher = Hasher()
    hasher.combine(1 as Double)
    hasher.combine(2 as Double)
    XCTAssertEqual(p1.hashValue, hasher.finalize())

    XCTAssertEqual(Point.zero.x, 0)
    XCTAssertEqual(Point.zero.y, 0)
  }

  func testVector() {
    let v1 = Vector(dx: 1, dy: 2)
    XCTAssertEqual(v1.dx, 1)
    XCTAssertEqual(v1.dy, 2)

    let v2 = Vector(dx: 2, dy: 1)
    XCTAssertEqual(v2.dx, 2)
    XCTAssertEqual(v2.dy, 1)

    XCTAssertEqual(v1, Vector(dx: 1, dy: 2))
    XCTAssertNotEqual(v1, v2)

    var hasher = Hasher()
    hasher.combine(1 as Double)
    hasher.combine(2 as Double)
    XCTAssertEqual(v1.hashValue, hasher.finalize())

    XCTAssertEqual(Vector.zero.dx, 0)
    XCTAssertEqual(Vector.zero.dy, 0)
  }

  func testRectangle() {
    let r1 = Rectangle(x: 1, y: 2, width: 3, height: 4)
    XCTAssertEqual(r1.origin, Point(x: 1, y: 2))
    XCTAssertEqual(r1.size, Vector(dx: 3, dy: 4))
    XCTAssertEqual(r1.minX, 1)
    XCTAssertEqual(r1.maxX, 4)
    XCTAssertEqual(r1.midX, 2.5)
    XCTAssertEqual(r1.minY, 2)
    XCTAssertEqual(r1.maxY, 6)
    XCTAssertEqual(r1.midY, 4)

    let r2 = Rectangle(origin: Point(x: 4, y: 6), size: Vector(dx: -3, dy: -4))
    XCTAssertEqual(r2.origin, Point(x: 4, y: 6))
    XCTAssertEqual(r2.size, Vector(dx: -3, dy: -4))
    XCTAssertEqual(r2.minX, 1)
    XCTAssertEqual(r2.maxX, 4)
    XCTAssertEqual(r2.midX, 2.5)
    XCTAssertEqual(r2.minY, 2)
    XCTAssertEqual(r2.maxY, 6)
    XCTAssertEqual(r2.midY, 4)

    let r3 = Rectangle(
      x: 4 as Float, y: 3 as Float, width: 2 as Float, height: 1 as Float)

    XCTAssertEqual(r1, r1)
    XCTAssertEqual(r1, r2)
    XCTAssertNotEqual(r1, r3)

    XCTAssertEqual(r2, r1)
    XCTAssertEqual(r2, r2)
    XCTAssertNotEqual(r2, r3)

    XCTAssertNotEqual(r3, r1)
    XCTAssertNotEqual(r3, r2)
    XCTAssertEqual(r3, r3)

    var hasher = Hasher()
    hasher.combine(1 as Double)
    hasher.combine(2 as Double)
    hasher.combine(3 as Double)
    hasher.combine(4 as Double)
    let hash = hasher.finalize()
    XCTAssertEqual(r1.hashValue, hash)
    XCTAssertEqual(r2.hashValue, hash)

    XCTAssertEqual(Rectangle.null.origin.x, .infinity)
    XCTAssertEqual(Rectangle.null.origin.y, .infinity)
    XCTAssertEqual(Rectangle.null.size.dx, 0)
    XCTAssertEqual(Rectangle.null.size.dy, 0)
  }

  func testTransform() throws {
    let t1 = Transform(a: 1, b: 2, c: 3, d: 4, tx: 5, ty: 6)
    XCTAssertEqual(t1.a, 1)
    XCTAssertEqual(t1.b, 2)
    XCTAssertEqual(t1.c, 3)
    XCTAssertEqual(t1.d, 4)
    XCTAssertEqual(t1.tx, 5)
    XCTAssertEqual(t1.ty, 6)

    let t2 = Transform(a: -1, b: -2, c: -3, d: -4, tx: -5, ty: -6)
    XCTAssertEqual(t2.a, -1)
    XCTAssertEqual(t2.b, -2)
    XCTAssertEqual(t2.c, -3)
    XCTAssertEqual(t2.d, -4)
    XCTAssertEqual(t2.tx, -5)
    XCTAssertEqual(t2.ty, -6)

    XCTAssertEqual(t1, t1)
    XCTAssertNotEqual(t1, t2)
    XCTAssertEqual(t2, t2)

    var hasher = Hasher()
    hasher.combine(1 as Double)
    hasher.combine(2 as Double)
    hasher.combine(3 as Double)
    hasher.combine(4 as Double)
    hasher.combine(5 as Double)
    hasher.combine(6 as Double)
    let hash = hasher.finalize()
    XCTAssertEqual(t1.hashValue, hash)
  }

  func testPoint_Codable() throws {
    let p = Point(x: 1, y: 2)
    let encoder = JSONEncoder()
    let data = try encoder.encode(p)
    let decoder = JSONDecoder()
    let q = try decoder.decode(Point.self, from: data)
    XCTAssertEqual(q, p)
  }

  func testVector_Codable() throws {
    let v = Vector(dx: 1, dy: 2)
    let encoder = JSONEncoder()
    let data = try encoder.encode(v)
    let decoder = JSONDecoder()
    let w = try decoder.decode(Vector.self, from: data)
    XCTAssertEqual(w, v)
  }

  func testRectangle_Codable() throws {
    let r1 = Rectangle(x: 1, y: 2, width: 3, height: 4)
    let encoder = JSONEncoder()
    let data = try encoder.encode(r1)
    let decoder = JSONDecoder()
    let r2 = try decoder.decode(Rectangle.self, from: data)
    XCTAssertEqual(r1, r2)
  }

  func testTransform_Codable() throws {
    let t1 = Transform(a: 1, b: 2, c: 3, d: 4, tx: 5, ty: 6)
    let encoder = JSONEncoder()
    let data = try encoder.encode(t1)
    let decoder = JSONDecoder()
    let t2 = try decoder.decode(Transform.self, from: data)
    XCTAssertEqual(t1, t2)
  }

  func testRectangle_isNull() throws {
    XCTAssertTrue(Rectangle.null.isNull)
    XCTAssertFalse(Rectangle(x: 1, y: 2, width: 3, height: 4).isNull)
    XCTAssertTrue(Rectangle(x: .infinity, y: 2, width: 3, height: 4).isNull)
    XCTAssertFalse(Rectangle(x: -.infinity, y: 2, width: 3, height: 4).isNull)
    XCTAssertTrue(Rectangle(x: 1, y: .infinity, width: 3, height: 4).isNull)
    XCTAssertFalse(Rectangle(x: 1, y: -.infinity, width: 3, height: 4).isNull)
    XCTAssertFalse(Rectangle(x: 1, y: 2, width: .infinity, height: 4).isNull)
    XCTAssertFalse(Rectangle(x: 1, y: 2, width: -.infinity, height: 4).isNull)
    XCTAssertFalse(Rectangle(x: 1, y: 2, width: 3, height: .infinity).isNull)
    XCTAssertFalse(Rectangle(x: 1, y: 2, width: 3, height: -.infinity).isNull)
  }

  func testRectangle_intersects() throws {
    let r0 = Rectangle.null
    let r1 = Rectangle(x: 0, y: 0, width: 1, height: 2)
    let r2 = Rectangle(x: 1, y: 0, width: 1, height: 2)
    let r3 = Rectangle(x: 0, y: 2, width: 1, height: 2)
    let r4 = Rectangle(x: 0, y: 0, width: 2, height: 4)

    XCTAssertFalse(r1.intersects(r0))
    XCTAssertTrue(r1.intersects(r1))
    XCTAssertFalse(r1.intersects(r2))
    XCTAssertFalse(r1.intersects(r3))
    XCTAssertTrue(r1.intersects(r4))

    XCTAssertFalse(r2.intersects(r0))
    XCTAssertFalse(r2.intersects(r1))
    XCTAssertTrue(r2.intersects(r2))
    XCTAssertFalse(r2.intersects(r3))
    XCTAssertTrue(r2.intersects(r4))

    XCTAssertFalse(r3.intersects(r0))
    XCTAssertFalse(r3.intersects(r1))
    XCTAssertFalse(r3.intersects(r2))
    XCTAssertTrue(r3.intersects(r3))
    XCTAssertTrue(r3.intersects(r4))

    XCTAssertFalse(r4.intersects(r0))
    XCTAssertTrue(r4.intersects(r1))
    XCTAssertTrue(r4.intersects(r2))
    XCTAssertTrue(r4.intersects(r3))
    XCTAssertTrue(r4.intersects(r4))
  }

  func testRectangle_inset() throws {
    let r = Rectangle(x: 1, y: 2, width: 3, height: 4)

    XCTAssertEqual(
      r.inset(by: EdgeInsets(top: 0.125, left: 0.25, bottom: 0.375, right: 0.5)),
      Rectangle(x: 1.25, y: 2.125, width: 2.25, height: 3.5))

    XCTAssertEqual(
      r.inset(by: EdgeInsets(top: 4, left: 3, bottom: 0, right: 0)),
      Rectangle(x: 4, y: 6, width: 0, height: 0))

    XCTAssertEqual(
      r.inset(by: EdgeInsets(top: 0, left: 3.25, bottom: 4, right: 0)),
      .null)

    XCTAssertEqual(
      r.inset(by: EdgeInsets(top: 0, left: 3, bottom: 4.25, right: 0)),
      .null)

    XCTAssertEqual(
      r.inset(dx: 0.5, dy: 0.5),
      Rectangle(x: 1.5, y: 2.5, width: 2, height: 3))
  }

  func testRectangle_standardized() throws {
    XCTAssertEqual(
      Rectangle(x: 1, y: 2, width: 3, height: 4).standardized,
      Rectangle(x: 1, y: 2, width: 3, height: 4))
    XCTAssertEqual(
      Rectangle(x: 1, y: 2, width: -3, height: 4).standardized,
      Rectangle(x: -2, y: 2, width: 3, height: 4))
    XCTAssertEqual(
      Rectangle(x: 1, y: 2, width: 3, height: -4).standardized,
      Rectangle(x: 1, y: -2, width: 3, height: 4))
    XCTAssertEqual(
      Rectangle(x: 1, y: 2, width: -3, height: -4).standardized,
      Rectangle(x: -2, y: -2, width: 3, height: 4))
  }

  func testRectangle_integral() throws {
    XCTAssertEqual(
      Rectangle(x: 1, y: 2, width: 3, height: 4).integral,
      Rectangle(x: 1, y: 2, width: 3, height: 4))
    XCTAssertEqual(
      Rectangle(x: 1.5, y: 2.5, width: 3.5, height: 4.5).integral,
      Rectangle(x: 1, y: 2, width: 4, height: 5))
    XCTAssertEqual(
      Rectangle(x: -1.5, y: -2.5, width: 3.5, height: 4.5).integral,
      Rectangle(x: -2, y: -3, width: 4, height: 5))
    XCTAssertEqual(
      Rectangle(x: 1, y: 2, width: -3.5, height: -4.5).integral,
      Rectangle(x: -3, y: -3, width: 4, height: 5))
  }

  func testRectangle_divided() throws {
    XCTAssertEqual(Rectangle.null.divided(atDistance: 1, from: .minX).slice, .null)
    XCTAssertEqual(Rectangle.null.divided(atDistance: 1, from: .minX).remainder, .null)

    XCTAssertEqual(Rectangle.null.divided(atDistance: 1, from: .maxX).slice, .null)
    XCTAssertEqual(Rectangle.null.divided(atDistance: 1, from: .maxX).remainder, .null)

    XCTAssertEqual(Rectangle.null.divided(atDistance: 1, from: .minY).slice, .null)
    XCTAssertEqual(Rectangle.null.divided(atDistance: 1, from: .minY).remainder, .null)

    XCTAssertEqual(Rectangle.null.divided(atDistance: 1, from: .maxY).slice, .null)
    XCTAssertEqual(Rectangle.null.divided(atDistance: 1, from: .maxY).remainder, .null)

    let r = Rectangle(x: 1, y: 2, width: 3, height: 4)

    // minX
    XCTAssertEqual(
      r.divided(atDistance: 0.5, from: .minX).slice,
      Rectangle(x: 1, y: 2, width: 0.5, height: 4))
    XCTAssertEqual(
      r.divided(atDistance: 0.5, from: .minX).remainder,
      Rectangle(x: 1.5, y: 2, width: 2.5, height: 4))

    XCTAssertEqual(
      r.divided(atDistance: -0.5, from: .minX).slice,
      Rectangle(x: 1, y: 2, width: 0, height: 4))
    XCTAssertEqual(
      r.divided(atDistance: -0.5, from: .minX).remainder,
      Rectangle(x: 1, y: 2, width: 3, height: 4))

    // maxX
    XCTAssertEqual(
      r.divided(atDistance: 0.5, from: .maxX).slice,
      Rectangle(x: 3.5, y: 2, width: 0.5, height: 4))
    XCTAssertEqual(
      r.divided(atDistance: 0.5, from: .maxX).remainder,
      Rectangle(x: 1, y: 2, width: 2.5, height: 4))

    XCTAssertEqual(
      r.divided(atDistance: -0.5, from: .maxX).slice,
      Rectangle(x: 4, y: 2, width: 0, height: 4))
    XCTAssertEqual(
      r.divided(atDistance: -0.5, from: .maxX).remainder,
      Rectangle(x: 1, y: 2, width: 3, height: 4))

    // minY
    XCTAssertEqual(
      r.divided(atDistance: 0.5, from: .minY).slice,
      Rectangle(x: 1, y: 2, width: 3, height: 0.5))
    XCTAssertEqual(
      r.divided(atDistance: 0.5, from: .minY).remainder,
      Rectangle(x: 1, y: 2.5, width: 3, height: 3.5))

    XCTAssertEqual(
      r.divided(atDistance: -0.5, from: .minY).slice,
      Rectangle(x: 1, y: 2, width: 3, height: 0))
    XCTAssertEqual(
      r.divided(atDistance: -0.5, from: .minY).remainder,
      Rectangle(x: 1, y: 2, width: 3, height: 4))

    // maxY
    XCTAssertEqual(
      r.divided(atDistance: 0.5, from: .maxY).slice,
      Rectangle(x: 1, y: 5.5, width: 3, height: 0.5))
    XCTAssertEqual(
      r.divided(atDistance: 0.5, from: .maxY).remainder,
      Rectangle(x: 1, y: 2, width: 3, height: 3.5))

    XCTAssertEqual(
      r.divided(atDistance: -0.5, from: .maxY).slice,
      Rectangle(x: 1, y: 6, width: 3, height: 0))
    XCTAssertEqual(
      r.divided(atDistance: -0.5, from: .maxY).remainder,
      Rectangle(x: 1, y: 2, width: 3, height: 4))
  }

  func testTransform_identity() {
    XCTAssertEqual(Transform.identity, Transform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0))
    XCTAssertEqual(Transform.identity.concatenating(.identity), .identity)
    XCTAssertEqual(Point(x: 1, y: 2).applying(.identity), Point(x: 1, y: 2))
    XCTAssertEqual(Vector(dx: 1, dy: 2).applying(.identity), Vector(dx: 1, dy: 2))
  }

  func testTransform_concatenating() {
    let a = Transform(a: 1, b: 2, c: 3, d: 4, tx: 5, ty: 6)
    let b = Transform(a: 0.5, b: 1.0, c: 1.5, d: 2, tx: 2.5, ty: 3)
    let c = Transform(a: 6, b: 5, c: 4, d: 3, tx: 2, ty: 1)

    XCTAssertEqual(
      a.concatenating(b),
      Transform(a: 3.5, b: 5, c: 7.5, d: 11, tx: 14, ty: 20))
    XCTAssertEqual(
      b.concatenating(a),
      Transform(a: 3.5, b: 5, c: 7.5, d: 11, tx: 16.5, ty: 23))

    XCTAssertEqual(
      a.concatenating(c),
      Transform(a: 14, b: 11, c: 34, d: 27, tx: 56, ty: 44))
    XCTAssertEqual(
      c.concatenating(a),
      Transform(a: 21, b: 32, c: 13, d: 20, tx: 10, ty: 14))

    XCTAssertEqual(
      b.concatenating(c),
      Transform(a: 7, b: 5.5, c: 17, d: 13.5, tx: 29, ty: 22.5))
    XCTAssertEqual(
      c.concatenating(b),
      Transform(a: 10.5, b: 16, c: 6.5, d: 10, tx: 5, ty: 7))
  }

  func testTransform_scaled() {
    let scale = Transform.identity.scaled(x: 2, y: 0.5)
    XCTAssertEqual(scale, Transform(a: 2, b: 0, c: 0, d: 0.5, tx: 0, ty: 0))
    XCTAssertEqual(scale.scaled(2), Transform(a: 4, b: 0, c: 0, d: 1, tx: 0, ty: 0))
    XCTAssertEqual(Point(x: 1, y: 2).applying(scale), Point(x: 2, y: 1))
    XCTAssertEqual(Vector(dx: 1, dy: 2).applying(scale), Vector(dx: 2, dy: 1))
  }

  func testTransform_translated() {
    let translation = Transform.identity.translated(x: 3, y: 4)
    XCTAssertEqual(translation, Transform(a: 1, b: 0, c: 0, d: 1, tx: 3, ty: 4))
    XCTAssertEqual(translation.translated(x: 1, y: 2),
                   Transform(a: 1, b: 0, c: 0, d: 1, tx: 4, ty: 6))
    XCTAssertEqual(Point(x: 1, y: 2).applying(translation), Point(x: 4, y: 6))
    XCTAssertEqual(Vector(dx: 1, dy: 2).applying(translation), Vector(dx: 1, dy: 2))
  }

  func testTransform_rotated() {
    let rotation = Transform.identity.rotated(Double.pi / 2)
    XCTAssertEqual(rotation.a, 0, accuracy: 0.001)
    XCTAssertEqual(rotation.b, 1, accuracy: 0.001)
    XCTAssertEqual(rotation.c, -1, accuracy: 0.001)
    XCTAssertEqual(rotation.d, 0, accuracy: 0.001)
    XCTAssertEqual(rotation.tx, 0, accuracy: 0.001)
    XCTAssertEqual(rotation.ty, 0, accuracy: 0.001)

    let r4 = rotation.rotated(.pi / 2).rotated(.pi / 2).rotated(.pi / 2)
    XCTAssertEqual(r4.a, 1, accuracy: 0.001)
    XCTAssertEqual(r4.b, 0, accuracy: 0.001)
    XCTAssertEqual(r4.c, 0, accuracy: 0.001)
    XCTAssertEqual(r4.d, 1, accuracy: 0.001)
    XCTAssertEqual(r4.tx, 0, accuracy: 0.001)
    XCTAssertEqual(r4.ty, 0, accuracy: 0.001)

    let p = Point(x: 1, y: 2).applying(rotation)
    XCTAssertEqual(p.x, -2, accuracy: 0.001)
    XCTAssertEqual(p.y, 1, accuracy: 0.001)

    let v = Vector(dx: 1, dy: 2).applying(rotation)
    XCTAssertEqual(v.dx, -2, accuracy: 0.001)
    XCTAssertEqual(v.dy, 1, accuracy: 0.001)
  }
}
