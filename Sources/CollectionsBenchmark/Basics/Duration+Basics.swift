//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension Duration {
  // Backported from Swift 6.2
  internal init(_attoseconds: Int128) {
    self.init(_high: _attoseconds._high, low: _attoseconds._low)
  }

  // Backported from Swift 6.2
  internal var _attoseconds: Int128 {
    Int128(_low: _low, _high: _high)
  }

  // Backported from a utopistic future
  internal var _seconds: Double {
    Double(_attoseconds) / 1e18
  }
}
