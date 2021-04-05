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

import ArgumentParser
import Foundation // for setbuf

extension Benchmark {
  public func main() {
    // Turn off output buffering.
    setbuf(stdout, nil)
    setbuf(stderr, nil)

    _markAsExecuted()

    var command: ParsableCommand
    do {
      command = try _BenchmarkCLI.parseAsRoot()
    } catch {
      _BenchmarkCLI.exit(withError: error)
    }

    do {
      if let command = command as? _BenchmarkCommand {
        try command.run(benchmark: self)
      } else {
        try command.run()
      }
    } catch let e as CocoaError {
      complain("Error: \(e.localizedDescription)")
      exit(1)
    } catch let e as DecodingError {
      complain("Error: \(e.localizedDescription)")
      if let context = e._context {
        let path = context.codingPath.map { $0.stringValue }.joined(separator: "/")
        complain("\(context.debugDescription) at \(path)")
      }
      exit(1)
    } catch {
      type(of: command).exit(withError: error)
    }
  }
}

extension DecodingError {
  var _context: Context? {
    switch self {
    case .dataCorrupted(let context): return context
    case .keyNotFound(_, let context): return context
    case .typeMismatch(_, let context): return context
    case .valueNotFound(_, let context): return context
    @unknown default:
      return nil
    }
  }
}
