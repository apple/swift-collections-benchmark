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

private func _exitHandler() {
  if !_ExecutionContext.shared._hasExecuted {
    fatalError("Did you forget to call Benchmark.start()?")
  }
}

internal class _ExecutionContext {
  var _hasExecuted = false
  
  private init() {
    // Check that Benchmark.start() was executed before exiting the process.
    atexit(_exitHandler)
  }
  
  static let shared: _ExecutionContext = { _ExecutionContext() }()
}
