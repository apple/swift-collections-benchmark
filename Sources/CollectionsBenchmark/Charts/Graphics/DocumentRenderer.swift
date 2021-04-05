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

import Foundation

public protocol DocumentRenderer {
  mutating func item(title: String, graphics: Graphics?, collapsed: Bool) throws
  mutating func beginSection(title: String, collapsed: Bool) throws
  mutating func endSection() throws

  func render() throws -> Data
}
