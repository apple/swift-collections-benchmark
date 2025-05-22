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

extension Benchmark {
  public struct Error: Sendable, Swift.Error, CustomStringConvertible {
    public let description: String

    public init(_ description: String) {
      self.description = description
    }

    public var localizedDescription: String { description }
  }
}
