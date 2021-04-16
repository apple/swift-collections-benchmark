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

@inline(__always)
internal func _sin(_ radians: Double) -> Double {
  sin(radians)
}

@inline(__always)
internal func _cos(_ radians: Double) -> Double {
  cos(radians)
}

@inline(__always)
internal func _log2(_ value: Double) -> Double {
  log2(value)
}

@inline(__always)
internal func _pow(_ base: Double, _ exponent: Double) -> Double {
  pow(base, exponent)
}
