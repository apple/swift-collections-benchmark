//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import Foundation

public struct Font: Sendable, Hashable, Codable, CustomStringConvertible {
  public var family: String
  public var size: Double
  public var isBold = false
  public var isItalic = false

  public var description: String {
    "'\(family)' at size \(size)"
  }
}
