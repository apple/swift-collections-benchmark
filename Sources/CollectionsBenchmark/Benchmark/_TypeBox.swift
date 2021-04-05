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

internal struct _TypeBox: Hashable {
  let type: Any.Type

  init(_ type: Any.Type) {
    self.type = type
  }

  static func ==(left: Self, right: Self) -> Bool {
    left.type == right.type
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(type))
  }
}
