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

/// A point in the document coordinate system, i.e., a pair of size and
/// time values.
public struct Measurement: Sendable, Hashable, Codable {
  public let size: Size
  public let time: Time

  public init(size: Size, time: Time) {
    self.size = size
    self.time = time
  }
}
