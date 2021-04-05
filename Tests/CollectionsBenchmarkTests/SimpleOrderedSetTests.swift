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

final class SimpleOrderedSetTests: XCTestCase {
  func testInit() {
    let empty = _SimpleOrderedSet<Int>()
    XCTAssertTrue(empty.isEmpty)

    let range = _SimpleOrderedSet<Int>(0 ..< 100)
    XCTAssertTrue(range.elementsEqual(0 ..< 100))

    let dupes = _SimpleOrderedSet<Int>([
      3, 3, 3, 3, 3, 3, 1, 2, 2, 0, 0, 0, 0, 1, 2, 3, 0, 0,
    ])
    XCTAssertTrue(dupes.elementsEqual([3, 1, 2, 0]))

    let literal: _SimpleOrderedSet = [
      42, 42, 23, 0, -7, 23, -7, 0, 0, 42, 42, 42, 13
    ]
    XCTAssertTrue(literal.elementsEqual([42, 23, 0, -7, 13]))
  }

  func testLookups() {
    let set = _SimpleOrderedSet(0 ..< 100)
    for i in 0 ..< 100 {
      XCTAssertTrue(set.contains(i))
      XCTAssertEqual(set.firstIndex(of: i), i)
      XCTAssertEqual(set.lastIndex(of: i), i)
    }
    for i in 100 ..< 200 {
      XCTAssertFalse(set.contains(i))
      XCTAssertNil(set.firstIndex(of: i))
      XCTAssertNil(set.lastIndex(of: i))
    }
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
