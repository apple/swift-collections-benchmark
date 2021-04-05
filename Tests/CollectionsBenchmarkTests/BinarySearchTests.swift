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

final class BinarySearchTests: XCTestCase {
  func testBinarySearch() {
    for count in [0, 1, 2, 100] {
      for dupes in 0 ..< 10 {
        for offset in 0 ..< count {
          var items: [Int] = []
          items.append(contentsOf: 0 ..< offset)
          items.append(contentsOf: Array(repeating: offset, count: dupes))
          items.append(contentsOf: offset + 1 ..< count)

          let (found, start) = items._binarySearchStart(offset)
          let end = items._binarySearchEnd(offset)

          XCTAssertEqual(found, dupes > 0)
          XCTAssertEqual(start, offset)
          XCTAssertEqual(end, offset + dupes)
        }
      }
    }
  }

  func testBinarySearch_Extract() {
    for count in [0, 1, 2, 100] {
      for dupes in 0 ..< 10 {
        for offset in 0 ..< count {
          var items: [Int] = []
          items.append(contentsOf: 0 ..< offset)
          items.append(contentsOf: Array(repeating: offset, count: dupes))
          items.append(contentsOf: offset + 1 ..< count)

          let (found, start) = items._binarySearchStart(UInt64(offset), by: { UInt64($0) })
          let end = items._binarySearchEnd(UInt64(offset), by: { UInt64($0) })

          XCTAssertEqual(found, dupes > 0)
          XCTAssertEqual(start, offset)
          XCTAssertEqual(end, offset + dupes)
        }
      }
    }
  }
}
