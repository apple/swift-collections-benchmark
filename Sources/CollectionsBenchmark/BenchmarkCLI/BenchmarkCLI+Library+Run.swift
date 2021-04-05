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
import SystemPackage

extension _BenchmarkCLI.Library {
  internal struct Run: _BenchmarkCommand {
    static var configuration: CommandConfiguration {
      CommandConfiguration(
        commandName: "run",
        abstract: "Run a predefined set of benchmarks.")
    }

    @Option(
      help: "Path to a library configuration file in JSON format. (default: built-in library)",
      completion: .file(extensions: ["json"]),
      transform: { str in FilePath(str) })
    internal var library: FilePath?

    @Argument(
      help: "Output filename.",
      completion: .file(),
      transform: { str in FilePath(str) })
    internal var output: FilePath

    @Option(help: "Label to apply to all task names. (default: no label)")
    internal var label: String = ""

    @OptionGroup
    internal var options: Benchmark.Options.GeneralOptions

    @OptionGroup
    internal var sizes: Benchmark.Options.SizeSelection

    @Option(name: .customLong("format"), help: "Output format (pretty|compact, default: compact)")
    internal var outputFormat: BenchmarkResults.OutputFormat = .compact

    @Option(help: "What to do with existing measurements (append|replace|replace-all, default: append)")
    internal var mode: _Document.Mode = .append

    internal func run(benchmark: Benchmark) throws {
      let library = try benchmark._loadLibrary(self.library)

      var taskSelection = Benchmark.Options.TaskSelection.empty
      taskSelection.tasks = library.allTasks.map { TaskID(title: $0.title) }

      let options = try Benchmark.Options(
        options: self.options,
        tasks: try taskSelection.resolve(
          allKnownTasks: benchmark.tasks.lazy.map { $0.id },
          ignoreLabels: true,
          labelOverride: label),
        sizes: try sizes.resolveSizes())

      var document = try _Document(
        opening: output,
        format: outputFormat,
        mode: mode)
      try document.run(benchmark: benchmark, options: options)
      try document.saveIfNeeded()
    }
  }
}
