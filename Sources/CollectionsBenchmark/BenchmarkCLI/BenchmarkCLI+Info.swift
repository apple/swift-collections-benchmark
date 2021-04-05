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

extension _BenchmarkCLI {
  internal struct Info: _BenchmarkCommand {
    internal static var configuration: CommandConfiguration {
      CommandConfiguration(
        commandName: "info",
        abstract: "Print information about the capabilities of this executable.")
    }

    @Flag(help: "List known tasks and exit")
    var tasks = false

    @Flag(help: "List known themes and exit")
    var themes = false

    @Flag(help: "List known image formats and exit")
    var imageFormats = false

    internal func run(benchmark: Benchmark) throws {
      if themes {
        Theme.knownThemes.keys.sorted().forEach { print($0) }
        return
      }
      if imageFormats {
        Graphics
          .bestAvailableRenderer
          .supportedImageFormats
          .forEach { print($0.rawValue) }
        return
      }
      if tasks {
        for title in benchmark.allTaskNames() {
          print(title)
        }
        return
      }
      throw Benchmark.Error("Please specify a command: --tasks|--themes|--image-formats")
    }
  }
}

