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
  struct Delete: ParsableCommand {
    internal static var configuration: CommandConfiguration {
      CommandConfiguration(
        commandName: "delete",
        abstract: "Remove data from a benchmark results file")
    }

    @Argument(
      help: "The file from which to remove data.",
      completion: .file(),
      transform: { str in FilePath(str) })
    internal var file: FilePath

    @Option(name: .customLong("format"), help: "Output format (pretty|compact, default: compact)")
    internal var outputFormat: BenchmarkResults.OutputFormat = .compact

    @Option(help: "Label to apply to all task names. (default: no label)")
    public var label: String?

    @Flag(
      name: [.long, .customShort("n")],
      help: "Print list of tasks selected to remove and exit.")
    public var dryRun = false

    @OptionGroup
    internal var tasks: Benchmark.Options.TaskSelection

    @OptionGroup
    internal var sizes: Benchmark.Options.SizeSelection

    @Flag(
      name: [.long, .customShort("a")],
      help: "Remove all sizes (overrides other size options).")
    public var allSizes = false

    internal func run() throws {
      var data = try BenchmarkResults.load(from: file)

      let tasks = try self.tasks.resolve(
        allKnownTasks: data.alltaskIDs(),
        ignoreLabels: false,
        labelOverride: label,
        ignoreUnknowns: true)
      let sizes = try self.sizes.resolveSizes()

      guard allSizes || !sizes.isEmpty else {
        throw Benchmark.Error("No sizes selected")
      }

      let sizeStr = allSizes
        ? "all sizes"
        : "\(sizes.count) sizes from \(sizes.first!) to \(sizes.last!)"

      print("""
        \(dryRun ? "[DRY RUN] " : "")\
        Deleting data for \(tasks.count) tasks on \(sizeStr):
        """)
      for task in tasks {
        print("  \(task)")
      }
      if !dryRun {
        if allSizes {
          data.remove(tasks)
        } else {
          data.clear(sizes: sizes, from: tasks)
        }
        try data.save(to: file)
      }
    }
  }
}


