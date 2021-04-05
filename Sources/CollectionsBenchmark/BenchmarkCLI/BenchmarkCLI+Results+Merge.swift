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
  struct Merge: ParsableCommand {
    internal static var configuration: CommandConfiguration {
      CommandConfiguration(
        commandName: "merge",
        abstract: "Merge two or more benchmark results files")
    }

    @Option(
      parsing: .upToNextOption,
      help: "One or more input files from which to collect data.",
      completion: .file(),
      transform: { str in FilePath(str) })
    internal var input: [FilePath]

    @Option(
      help: "The output file into which data is to be merged.",
      completion: .file(),
      transform: { str in FilePath(str) })
    internal var output: FilePath

    @Option(name: .customLong("format"), help: "Output format (pretty|compact, default: compact)")
    internal var outputFormat: BenchmarkResults.OutputFormat = .compact

    @Option(help: "What to do with existing measurements (append|replace|replace-all, default: append)")
    internal var mode: _Document.Mode = .append

    internal func run() throws {
      var document = try _Document(opening: output, format: outputFormat, mode: mode)
      for input in self.input {
        let results = try BenchmarkResults.load(from: input)
        document.merge(results: results, mode: mode)
      }
      try document.save()
    }
  }
}


