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

extension _BenchmarkCLI {

  internal struct Run: _BenchmarkCommand {
    static var configuration: CommandConfiguration {
      CommandConfiguration(
        commandName: "run",
        abstract: "Run a particular set of benchmarks.")
    }

    @Argument(
      help: "Output filename.",
      completion: .file(),
      transform: { str in FilePath(str) })
    internal var output: FilePath

    @OptionGroup
    internal var tasks: Benchmark.Options.TaskSelection

    @OptionGroup
    internal var sizes: Benchmark.Options.SizeSelection

    @Option(help: "Label to apply to all task names. (default: no label)")
    public var label: String = ""

    @Flag(
      name: [.long, .customShort("n")],
      help: "Print list of tasks selected to run and exit.")
    public var dryRun = false

    @OptionGroup
    internal var options: Benchmark.Options.GeneralOptions

    @Option(name: .customLong("format"), help: "Output format (pretty|compact, default: compact)")
    internal var outputFormat: BenchmarkResults.OutputFormat = .compact

    @Option(help: "What to do with existing measurements (append|replace|replace-all, default: append)")
    internal var mode: _Document.Mode = .append

    internal func run(benchmark: Benchmark) throws {
      if benchmark.tasks.isEmpty {
        throw Benchmark.Error("This benchmark instance has no tasks defined")
      }

      let options = try Benchmark.Options(
        options: self.options,
        tasks: try tasks.resolve(
          allKnownTasks: benchmark.tasks.lazy.map { $0.id },
          ignoreLabels: true,
          labelOverride: self.label),
        sizes: try sizes.resolveSizes())

      if self.dryRun {
        let tasks = try options.resolveTasks(from: benchmark)
        tasks.forEach { print($0.id) }
        return
      }

      var document = try _Document(
        opening: output,
        format: outputFormat,
        mode: mode)
      try document.run(benchmark: benchmark, options: options)
    }
  }
}
