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

final class UtilitiesTests: XCTestCase {
  func testSanitizedPathComponent() {
    func check(
      _ input: String,
      _ output: String,
      windows: String? = nil,
      file: StaticString = #file,
      line: UInt = #line
    ) {
      #if os(Windows)
      XCTAssertEqual(
        input._sanitizedPathComponent(),
        windows ?? output,
        file: file, line: line)
      #else
      XCTAssertEqual(
        input._sanitizedPathComponent(),
        output,
        file: file, line: line)
      #endif
    }
    check("", "")
    check("Hello", "Hello")
    check("Hello/goodbye", "Hello_goodbye")
    check("Hello\u{0}goodbye", "Hello_goodbye")
    check("Hello//goodbye", "Hello_goodbye")
    check("Hello///////goodbye", "Hello_goodbye")
    check("Hello/\u{0}/\u{0}/\u{0}/\u{0}goodbye", "Hello_goodbye")
    check("/\u{0}/\u{0}/\u{0}/\u{0}", "_")

    check(".", ".")
    check("..", "..")
    check("CON", "CON")
    check("LPT7", "LPT7")
    check(
      "Some\\systems:have<trouble>with\"reasonable*filenames|like?this",
      "Some\\systems:have<trouble>with\"reasonable*filenames|like?this",
      windows: "Some_systems_have_trouble_with_reasonable_filenames_like_this")
    check("Hi/:/*/bye", "Hi_:_*_bye", windows: "Hi_bye")
  }
}
