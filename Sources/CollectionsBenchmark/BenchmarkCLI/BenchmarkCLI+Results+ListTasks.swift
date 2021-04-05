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
import ArgumentParser
import SystemPackage

extension _BenchmarkCLI.Results {
  struct ListTasks: ParsableCommand {
    internal static var configuration: CommandConfiguration {
      CommandConfiguration(
        commandName: "list-tasks",
        abstract: "List the contents of a benchmark results file.")
    }

    @Argument(
      help: "Path to a benchmark results file.",
      completion: .file(),
      transform: { str in FilePath(str) })
    internal var input: FilePath

    @Flag(help: "Ignore tasks with no data.")
    var excludeEmpty = false

    @Flag(help: "Also print the source URL for each task (if known).")
    var urls = false

    @Flag(help: "Also print the size range for each task (if any).")
    var sizes = false

    func run() throws {
      let url = URL(input, isDirectory: false)

      let results = try BenchmarkResults.load(from: url)
      for result in results.tasks {
        if excludeEmpty, result.sampleCount == 0 { continue }
        if sizes {
          if
            let min = result.samples.first?.size,
            let max = result.samples.last?.size
          {
            print("\(min) ..< \(max) - \(result.taskID)")
          } else {
            print("(No sizes) - \(result.taskID)")
          }
        } else {
          print(result.taskID)
        }
        if urls, let link = result.link {
          print("  \(link)")
        }
      }
    }
  }
}
