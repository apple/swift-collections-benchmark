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
@testable import CollectionsBenchmark

final class SimpleSortedBagTests: XCTestCase {
  func testInit() {
    let empty = _SimpleSortedBag<Int>()
    XCTAssertTrue(empty.isEmpty)

    let range = _SimpleSortedBag<Int>(0 ..< 100)
    XCTAssertTrue(range.elementsEqual(0 ..< 100))

    do {
      let reference = [
        3, 3, 3, 3, 3, 3, 1, 2, 2, 0, 0, 0, 0, 1, 2, 3, 0, 0,
      ]
      let dupes = _SimpleSortedBag<Int>(reference)
      XCTAssertTrue(dupes.elementsEqual(reference.sorted()))
    }

    do {
      let literal: _SimpleSortedBag = [
        42, 42, 23, 0, -7, 23, -7, 0, 0, 42, 13
      ]
      let reference = [
        -7, -7, 0, 0, 0, 13, 23, 23, 42, 42, 42
      ]
      XCTAssertTrue(literal.elementsEqual(reference))
    }
  }

  func testLookups() {
    let set = _SimpleSortedBag(Array(0 ..< 100) + Array(0 ..< 100))
    for i in 0 ..< 100 {
      XCTAssertTrue(set.contains(i))
      XCTAssertEqual(set.firstIndex(of: i), 2 * i)
      XCTAssertEqual(set.lastIndex(of: i), 2 * i + 1)
    }
    for i in 100 ..< 200 {
      XCTAssertFalse(set.contains(i))
      XCTAssertNil(set.firstIndex(of: i))
      XCTAssertNil(set.lastIndex(of: i))
    }
  }

  func testInsert_One() {
    var bag: _SimpleSortedBag<Int> = []
    for i in 0 ..< 5 {
      for _ in 0 ..< i {
        let index = bag.insert(i)
        XCTAssertEqual(index, bag.count - 1)
      }
    }
    XCTAssertTrue(
      bag.elementsEqual([1, 2, 2, 3, 3, 3, 4, 4, 4, 4]))
  }

  func testEquatable() {
    let a: _SimpleSortedBag<Int> = []
    let b: _SimpleSortedBag<Int> = [0, 1]
    let c: _SimpleSortedBag<Int> = [0, 0, 1]
    let d: _SimpleSortedBag<Int> = [0, 0, 1, 1]

    XCTAssertEqual(a, a)
    XCTAssertNotEqual(a, b)
    XCTAssertNotEqual(a, c)
    XCTAssertNotEqual(a, d)

    XCTAssertNotEqual(b, a)
    XCTAssertEqual(b, b)
    XCTAssertNotEqual(b, c)
    XCTAssertNotEqual(b, d)

    XCTAssertNotEqual(c, a)
    XCTAssertNotEqual(c, b)
    XCTAssertEqual(c, c)
    XCTAssertNotEqual(c, d)

    XCTAssertNotEqual(d, a)
    XCTAssertNotEqual(d, b)
    XCTAssertNotEqual(d, c)
    XCTAssertEqual(d, d)
  }

  func testInsert_Many() {
    var bag: _SimpleSortedBag<Int> = []
    bag.insert(contentsOf: 0 ..< 5)
    bag.insert(contentsOf: 0 ..< 5)
    bag.insert(contentsOf: 0 ..< 5)
    XCTAssertTrue(
      bag.elementsEqual(
        [0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4]))
  }

  func testUpdate() {
    var set = _SimpleOrderedSet(0 ..< 100)
    for i in 0 ..< 100 {
      XCTAssertEqual(set.update(with: i), i)
      XCTAssertNil(set.update(with: 100 + i))
      set._checkInvariants()
    }
  }

  func testUpdateAtIndex() {
    var set = _SimpleOrderedSet(0 ..< 100)
    for i in 0 ..< 100 {
      XCTAssertEqual(set._update(with: i, at: i), i)
      set._checkInvariants()
    }
  }

  func testRemove() {
    var set = _SimpleOrderedSet(0 ..< 100)
    for i in 0 ..< 100 {
      XCTAssertEqual(set.remove(i), i)
      XCTAssertNil(set.remove(i))
      set._checkInvariants()
    }
  }

  func testSubtracting() {
    let set = _SimpleOrderedSet(0 ..< 100)
    for i in 0 ..< 90 {
      let range = i ..< i + 10
      var reference = Array(0 ..< 100)
      reference.removeSubrange(range)
      XCTAssertTrue(set.subtracting(range).elementsEqual(reference))
    }
  }

  func testFormUnion() {
    for i in 0 ..< 10 {
      let range = i ..< i + 10
      var set = _SimpleOrderedSet(0 ..< 10)
      set.formUnion(range)
      XCTAssertTrue(set.elementsEqual(0 ..< i + 10))
    }
  }
}
