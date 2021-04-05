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

func _expectEqual<
  S1: Sequence,
  S2: Sequence,
  A: Equatable,
  B: Equatable
>(
  _ actual: S1,
  _ expected: S2,
  file: StaticString = #file,
  line: UInt = #line
) where
  S1.Element == (key: A, value: B),
  S2.Element == (A, B)
{
  var it1 = actual.makeIterator()
  var it2 = actual.makeIterator()
  var i = 0
  while true {
    switch (it1.next(), it2.next()) {
    case let (v1?, v2?):
      XCTAssertEqual(
        v1.0, v2.0,
        "Discrepancy at offset \(i)", file: file, line: line)
      XCTAssertEqual(
        v1.1, v2.1,
        "Discrepancy at offset \(i)", file: file, line: line)
      if v1 != v2 { return }
    case (nil, nil):
      return
    case (nil, _?):
      XCTFail("First sequence is shorter than the second",
              file: file, line: line)
      return
    case (_?, nil):
      XCTFail("Second sequence is shorter than the first",
              file: file, line: line)
      return
    }
    i += 1
  }
}

final class SimpleOrderedDictionaryTests: XCTestCase {
  func testInit() {
    let empty = _SimpleOrderedDictionary<Int, Int>()
    XCTAssertTrue(empty.isEmpty)

    do {
      let reference = (0 ..< 10).map { ($0, 2 * $0) }
      let d = _SimpleOrderedDictionary<Int, Int>(uniqueKeysWithValues: reference)
      d._checkInvariants()
      _expectEqual(d, reference)
    }

    let literal: _SimpleOrderedDictionary = [
      1: 2,
      2: 4,
      3: 6
    ]
    _expectEqual(literal, [(1, 2), (2, 4), (3, 6)])
  }

  func testLookups() {
    let d = _SimpleOrderedDictionary(
      uniqueKeysWithValues: (0 ..< 100).map { ($0, 2 * $0) }
    )
    for i in 0 ..< 100 {
      XCTAssertEqual(d[i], 2 * i)
      XCTAssertEqual(d[i, default: -1], 2 * i)
    }
    for i in 100 ..< 200 {
      XCTAssertNil(d[i])
      XCTAssertEqual(d[i, default: -1], -1)
    }
  }

  func testSubscript_Mutations() {
    var d: _SimpleOrderedDictionary<Int, Int> = [:]
    for i in 0 ..< 10 {
      d[i] = 1
    }
    for i in 0 ..< 20 {
      func update(_ value: inout Int?) {
        if let v = value { value = v + 1 }
        else { value = 1 }
      }
      update(&d[i])
    }
    for i in 0 ..< 30 {
      d[i, default: 0] += 1
    }
    for i in 0 ..< 30 {
      XCTAssertEqual(d[i], 3 - (i / 10))
    }

    for i in 0 ..< 30 {
      d[i] = nil
    }
    XCTAssertTrue(d.isEmpty)
  }

  func testDefaultedSubscript_Mutations() {
    var d: _SimpleOrderedDictionary<Int, Int> = [:]
    for i in 0 ..< 10 {
      d[i] = 1
    }
    for i in 0 ..< 20 {
      d[i, default: 0] += 1
    }
    _expectEqual(d, (0 ..< 20).map { ($0, 2 - $0 / 10) })
  }

  func testUpdateValueForKey() {
    var d = _SimpleOrderedDictionary(
      uniqueKeysWithValues: (0 ..< 10).map { ($0, 1) })
    for i in 0 ..< 10 {
      XCTAssertEqual(d.updateValue(2, forKey: i), 1)
    }
    for i in 10 ..< 20 {
      XCTAssertNil(d.updateValue(2, forKey: i))
    }
  }

  func testIndex() {
    let d = _SimpleOrderedDictionary(
      uniqueKeysWithValues: (0 ..< 10).map { ($0, 1) })

    XCTAssertEqual(d.startIndex.offset, 0)
    XCTAssertEqual(d.endIndex.offset, 10)
    XCTAssertTrue(d.startIndex < d.endIndex)
    XCTAssertEqual(d.distance(from: d.startIndex, to: d.endIndex), 10)
    XCTAssertEqual(d.index(d.startIndex, offsetBy: 10), d.endIndex)
    var index = d.startIndex
    var i = 0
    while i < 10 {
      XCTAssertEqual(index.offset, i)
      index = d.index(after: index)
      i += 1
    }
    XCTAssertEqual(index, d.endIndex)

    i = 10
    while i > 0 {
      XCTAssertEqual(index.offset, i)
      index = d.index(before: index)
      i -= 1
    }
    XCTAssertEqual(index, d.startIndex)
  }

  func testRemoveAllWhere() {
    var d = _SimpleOrderedDictionary(
      uniqueKeysWithValues: (0 ..< 10).map { ($0, 1) })
    d.removeAll { $0.key.isMultiple(of: 2) }
    _expectEqual(d, [(1, 1), (3, 1), (5, 1), (7, 1), (9, 1)])
  }
}
