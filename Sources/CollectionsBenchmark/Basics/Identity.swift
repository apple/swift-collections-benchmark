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

/// Do nothing and immediately return `value`, unchanged.
///
/// If you are benchmarking a calculation repeatedly in a loop with the
/// same inputs, some optimizations may move parts of the calculation outside
/// of the loop, and this could affect the accuracy of the benchmark.
/// To defeat these optimizations, pass such constant input values to this
/// function; the compiler won't be able to tell that the function doesn't
/// actually do anything, so the optimizations won't trigger.
@inline(never)
public func identity<T>(_ value: T) -> T {
  value
}
