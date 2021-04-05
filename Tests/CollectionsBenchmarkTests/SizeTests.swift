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

final class SizeFormatterTests: XCTestCase {
  func testDisplayString() {
    XCTAssertEqual(Size(0).description, "0")
    XCTAssertEqual(Size(1).description, "1")
    XCTAssertEqual(Size(1 << 5).description, "32")
    XCTAssertEqual(Size(3 << 10).description, "3k")
    XCTAssertEqual(Size(3840).description, "3.75k")
    XCTAssertEqual(Size(5 << 20).description, "5M")
    XCTAssertEqual(Size(5767168).description, "5.5M")
    XCTAssertEqual(Size(7 << 30).description, "7G")
    XCTAssertEqual(Size(9 << 40).description, "9T")
    // Only three significant digits
    XCTAssertEqual(Size(1_000_000).description, "977k")
    XCTAssertEqual(Size(10_000_000).description, "9.54M")
  }

  func testValueForString() {
    XCTAssertEqual(Size("")?.rawValue, nil)
    XCTAssertEqual(Size("0")?.rawValue, 0)
    XCTAssertEqual(Size("1")?.rawValue, 1)
    XCTAssertEqual(Size("-1")?.rawValue, nil)
    XCTAssertEqual(Size("10.5")?.rawValue, nil)
    XCTAssertEqual(Size("10")?.rawValue, 10)
    XCTAssertEqual(Size("10 ")?.rawValue, nil)
    XCTAssertEqual(Size(" 10")?.rawValue, nil)
    XCTAssertEqual(Size("1023")?.rawValue, 1023)
    XCTAssertEqual(Size("1024")?.rawValue, 1024)
    XCTAssertEqual(Size("1k")?.rawValue, 1024)
    XCTAssertEqual(Size("1 k")?.rawValue, nil)
    XCTAssertEqual(Size("4K")?.rawValue, 4096)
    XCTAssertEqual(Size("1m")?.rawValue, 1 << 20)
    XCTAssertEqual(Size("50M")?.rawValue, 50 << 20)
    XCTAssertEqual(Size("20g")?.rawValue, 20 << 30)
    XCTAssertEqual(Size("512G")?.rawValue, 512 << 30)
    XCTAssertEqual(Size("1t")?.rawValue, 1 << 40)
    XCTAssertEqual(Size("128T")?.rawValue, 128 << 40)
  }

  func testRoundedDown() {
    XCTAssertEqual(Size(0).roundedDown(significantDigits: 1), 0)
    XCTAssertEqual(Size(1).roundedDown(significantDigits: 1), 1)
    XCTAssertEqual(Size(2).roundedDown(significantDigits: 1), 2)
    XCTAssertEqual(Size(3).roundedDown(significantDigits: 1), 2)
    XCTAssertEqual(Size(4).roundedDown(significantDigits: 1), 4)
    XCTAssertEqual(Size(5).roundedDown(significantDigits: 1), 4)
    XCTAssertEqual(Size(6).roundedDown(significantDigits: 1), 4)
    XCTAssertEqual(Size(7).roundedDown(significantDigits: 1), 4)
    XCTAssertEqual(Size(8).roundedDown(significantDigits: 1), 8)
    XCTAssertEqual(Size(9).roundedDown(significantDigits: 1), 8)
    XCTAssertEqual(Size(10).roundedDown(significantDigits: 1), 8)
    XCTAssertEqual(Size(11).roundedDown(significantDigits: 1), 8)
    XCTAssertEqual(Size(12).roundedDown(significantDigits: 1), 8)
    XCTAssertEqual(Size(13).roundedDown(significantDigits: 1), 8)
    XCTAssertEqual(Size(14).roundedDown(significantDigits: 1), 8)
    XCTAssertEqual(Size(15).roundedDown(significantDigits: 1), 8)
    XCTAssertEqual(Size(16).roundedDown(significantDigits: 1), 16)

    XCTAssertEqual(Size(0).roundedDown(significantDigits: 2), 0)
    XCTAssertEqual(Size(1).roundedDown(significantDigits: 2), 1)
    XCTAssertEqual(Size(2).roundedDown(significantDigits: 2), 2)
    XCTAssertEqual(Size(3).roundedDown(significantDigits: 2), 3)
    XCTAssertEqual(Size(4).roundedDown(significantDigits: 2), 4)
    XCTAssertEqual(Size(5).roundedDown(significantDigits: 2), 4)
    XCTAssertEqual(Size(6).roundedDown(significantDigits: 2), 6)
    XCTAssertEqual(Size(7).roundedDown(significantDigits: 2), 6)
    XCTAssertEqual(Size(8).roundedDown(significantDigits: 2), 8)
    XCTAssertEqual(Size(9).roundedDown(significantDigits: 2), 8)
    XCTAssertEqual(Size(10).roundedDown(significantDigits: 2), 8)
    XCTAssertEqual(Size(11).roundedDown(significantDigits: 2), 8)
    XCTAssertEqual(Size(12).roundedDown(significantDigits: 2), 12)
    XCTAssertEqual(Size(13).roundedDown(significantDigits: 2), 12)
    XCTAssertEqual(Size(14).roundedDown(significantDigits: 2), 12)
    XCTAssertEqual(Size(15).roundedDown(significantDigits: 2), 12)
    XCTAssertEqual(Size(16).roundedDown(significantDigits: 2), 16)

    XCTAssertEqual(Size(0xFFFF).roundedDown(significantDigits: 1), 0x8000)
    XCTAssertEqual(Size(0xFFFF).roundedDown(significantDigits: 2), 0xC000)
    XCTAssertEqual(Size(0xFFFF).roundedDown(significantDigits: 3), 0xE000)
    XCTAssertEqual(Size(0xFFFF).roundedDown(significantDigits: 4), 0xF000)
    XCTAssertEqual(Size(0xFFFF).roundedDown(significantDigits: 5), 0xF800)
    XCTAssertEqual(Size(0xFFFF).roundedDown(significantDigits: 6), 0xFC00)
    XCTAssertEqual(Size(0xFFFF).roundedDown(significantDigits: 7), 0xFE00)
    XCTAssertEqual(Size(0xFFFF).roundedDown(significantDigits: 8), 0xFF00)
    XCTAssertEqual(Size(0xFFFF).roundedDown(significantDigits: 9), 0xFF80)
    XCTAssertEqual(Size(0xFFFF).roundedDown(significantDigits: 10), 0xFFC0)
    XCTAssertEqual(Size(0xFFFF).roundedDown(significantDigits: 11), 0xFFE0)
    XCTAssertEqual(Size(0xFFFF).roundedDown(significantDigits: 12), 0xFFF0)
    XCTAssertEqual(Size(0xFFFF).roundedDown(significantDigits: 13), 0xFFF8)
    XCTAssertEqual(Size(0xFFFF).roundedDown(significantDigits: 14), 0xFFFC)
    XCTAssertEqual(Size(0xFFFF).roundedDown(significantDigits: 15), 0xFFFE)
    XCTAssertEqual(Size(0xFFFF).roundedDown(significantDigits: 16), 0xFFFF)
    XCTAssertEqual(Size(0xFFFF).roundedDown(significantDigits: 17), 0xFFFF)
    XCTAssertEqual(Size(0xFFFF).roundedDown(significantDigits: 18), 0xFFFF)
    XCTAssertEqual(Size(0xFFFF).roundedDown(significantDigits: 19), 0xFFFF)
    XCTAssertEqual(Size(0xFFFF).roundedDown(significantDigits: 20), 0xFFFF)
    XCTAssertEqual(Size(0xFFFF).roundedDown(significantDigits: 64), 0xFFFF)
  }

  func testNextUp() {
    XCTAssertEqual(Size(0x01).nextUp(significantDigits: 1), 0x02)
    XCTAssertEqual(Size(0x02).nextUp(significantDigits: 1), 0x04)
    XCTAssertEqual(Size(0x04).nextUp(significantDigits: 1), 0x08)
    XCTAssertEqual(Size(0x08).nextUp(significantDigits: 1), 0x10)
    XCTAssertEqual(Size(0x10).nextUp(significantDigits: 1), 0x20)
    XCTAssertEqual(Size(0x20).nextUp(significantDigits: 1), 0x40)
    XCTAssertEqual(Size(0x40).nextUp(significantDigits: 1), 0x80)
    XCTAssertEqual(Size(0x80).nextUp(significantDigits: 1), 0x0100)

    XCTAssertEqual(Size(0x01).nextUp(significantDigits: 2), 0x02)
    XCTAssertEqual(Size(0x02).nextUp(significantDigits: 2), 0x03)
    XCTAssertEqual(Size(0x03).nextUp(significantDigits: 2), 0x04)
    XCTAssertEqual(Size(0x04).nextUp(significantDigits: 2), 0x06)
    XCTAssertEqual(Size(0x06).nextUp(significantDigits: 2), 0x08)
    XCTAssertEqual(Size(0x08).nextUp(significantDigits: 2), 0x0C)
    XCTAssertEqual(Size(0x0C).nextUp(significantDigits: 2), 0x10)
    XCTAssertEqual(Size(0x10).nextUp(significantDigits: 2), 0x18)
    XCTAssertEqual(Size(0x18).nextUp(significantDigits: 2), 0x20)
    XCTAssertEqual(Size(0x20).nextUp(significantDigits: 2), 0x30)
    XCTAssertEqual(Size(0x30).nextUp(significantDigits: 2), 0x40)
    XCTAssertEqual(Size(0x40).nextUp(significantDigits: 2), 0x60)
    XCTAssertEqual(Size(0x60).nextUp(significantDigits: 2), 0x80)
    XCTAssertEqual(Size(0x80).nextUp(significantDigits: 2), 0xC0)
    XCTAssertEqual(Size(0xC0).nextUp(significantDigits: 2), 0x0100)

    XCTAssertEqual(Size(0x01).nextUp(significantDigits: 3), 0x02)
    XCTAssertEqual(Size(0x02).nextUp(significantDigits: 3), 0x03)
    XCTAssertEqual(Size(0x03).nextUp(significantDigits: 3), 0x04)
    XCTAssertEqual(Size(0x04).nextUp(significantDigits: 3), 0x05)
    XCTAssertEqual(Size(0x05).nextUp(significantDigits: 3), 0x06)
    XCTAssertEqual(Size(0x06).nextUp(significantDigits: 3), 0x07)
    XCTAssertEqual(Size(0x07).nextUp(significantDigits: 3), 0x08)
    XCTAssertEqual(Size(0x08).nextUp(significantDigits: 3), 0x0A)
    XCTAssertEqual(Size(0x09).nextUp(significantDigits: 3), 0x0A)
    XCTAssertEqual(Size(0x0A).nextUp(significantDigits: 3), 0x0C)
    XCTAssertEqual(Size(0x0B).nextUp(significantDigits: 3), 0x0C)
    XCTAssertEqual(Size(0x0C).nextUp(significantDigits: 3), 0x0E)
    XCTAssertEqual(Size(0x0D).nextUp(significantDigits: 3), 0x0E)
    XCTAssertEqual(Size(0x0E).nextUp(significantDigits: 3), 0x10)
    XCTAssertEqual(Size(0x0F).nextUp(significantDigits: 3), 0x10)
    XCTAssertEqual(Size(0x10).nextUp(significantDigits: 3), 0x14)
    XCTAssertEqual(Size(0x11).nextUp(significantDigits: 3), 0x14)
    XCTAssertEqual(Size(0x12).nextUp(significantDigits: 3), 0x14)
    XCTAssertEqual(Size(0x13).nextUp(significantDigits: 3), 0x14)
    XCTAssertEqual(Size(0x14).nextUp(significantDigits: 3), 0x18)
    XCTAssertEqual(Size(0x18).nextUp(significantDigits: 3), 0x1C)
    XCTAssertEqual(Size(0x1C).nextUp(significantDigits: 3), 0x20)
    XCTAssertEqual(Size(0x20).nextUp(significantDigits: 3), 0x28)
    XCTAssertEqual(Size(0x28).nextUp(significantDigits: 3), 0x30)
    XCTAssertEqual(Size(0x30).nextUp(significantDigits: 3), 0x38)
    XCTAssertEqual(Size(0x38).nextUp(significantDigits: 3), 0x40)
    XCTAssertEqual(Size(0x40).nextUp(significantDigits: 3), 0x50)
    XCTAssertEqual(Size(0x50).nextUp(significantDigits: 3), 0x60)
    XCTAssertEqual(Size(0x60).nextUp(significantDigits: 3), 0x70)
    XCTAssertEqual(Size(0x70).nextUp(significantDigits: 3), 0x80)
    XCTAssertEqual(Size(0x80).nextUp(significantDigits: 3), 0xA0)
    XCTAssertEqual(Size(0xA0).nextUp(significantDigits: 3), 0xC0)
    XCTAssertEqual(Size(0xC0).nextUp(significantDigits: 3), 0xE0)
    XCTAssertEqual(Size(0xE0).nextUp(significantDigits: 3), 0x0100)
  }

  func testSizesForRange() {
    XCTAssertEqual(Size.sizes(for: Size(1) ... Size(16), significantDigits: 1),
                   [1, 2, 4, 8, 16])
    XCTAssertEqual(Size.sizes(for: Size(1) ... Size(16), significantDigits: 2),
                   [1, 2, 3, 4, 6, 8, 12, 16])
    XCTAssertEqual(Size.sizes(for: Size(1) ... Size(16), significantDigits: 3),
                   [1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 16])
    XCTAssertEqual(Size.sizes(for: Size(1) ... Size(16), significantDigits: 4),
                   [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16])

    XCTAssertEqual(Size.sizes(for: Size(100) ... Size(200), significantDigits: 1),
                   [128])
    XCTAssertEqual(Size.sizes(for: Size(100) ... Size(200), significantDigits: 2),
                   [128, 192])
    XCTAssertEqual(Size.sizes(for: Size(100) ... Size(200), significantDigits: 3),
                   [112, 128, 160, 192])
    XCTAssertEqual(Size.sizes(for: Size(100) ... Size(200), significantDigits: 4),
                   [104, 112, 120, 128, 144, 160, 176, 192])
  }
}
