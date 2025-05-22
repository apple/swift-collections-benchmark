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

import Foundation // for atexit
import Synchronization

let _hasDoneSetup: Atomic<Bool> = .init(false)
let _hasExecuted: Atomic<Bool> = .init(false)

private func _exitHandler() {
  if !_hasExecuted.load(ordering: .acquiring) {
    fatalError("Did you forget to call Benchmark.start()?")
  }
}

internal func _setUpExecutionCheck() {
  let (exchanged, _) = _hasDoneSetup.compareExchange(
    expected: false, desired: true, ordering: .acquiringAndReleasing)
  if exchanged {
    // Check that Benchmark.start() was executed before exiting the process.
    // FIXME: Calling convention mismatch
    atexit(_exitHandler)
  }
}

internal func _markAsExecuted() {
  guard _hasDoneSetup.load(ordering: .acquiring) else {
    fatalError("Internal error: _markAsExecuted called before _setUpExecutionCheck")
  }
  _hasExecuted.store(true, ordering: .releasing)
}
