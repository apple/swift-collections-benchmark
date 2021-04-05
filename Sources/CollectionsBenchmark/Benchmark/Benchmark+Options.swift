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

import SystemPackage
import ArgumentParser

extension Benchmark {
  public struct Options: Codable {
    /// Benchmark tasks to run. (default: all benchmarks, unlabeled)
    public var tasks: [TaskID] = []

    /// Input sizes to measure. Overrides min-size and max-size.
    public var sizes: [Size] = []

    /// The number of times to run each task/size measurement.
    /// The reported result is the minimum elapsed time across all iterations.
    /// (Depending on how slow/fast the task is, this count may get overridden
    /// by `minimumDuration` and/or `maximumDuration`.)
    public var cycles: Int?

    /// Repeat each particular task/size measurement until at least this amount of time has passed.
    /// (When this is positive, tasks may get run for more than `iterations` times.)
    public var iterations: Int = 3

    /// Repeat each task for at least this number of seconds.
    public var minimumDuration = Time(0.01)

    /// Stop repeating a particular task/size measurement after this amount of time has passed.
    /// (When this is a finite positive value, tasks may get run for less than `iterations` times.)
    public var maximumDuration: Time?

    /// Stop running a particular task if its per-element processing time goes
    /// beyond this value. (The task won't be run for any sizes higher than the
    /// first that reaches this value.)
    public var amortizedCutoff: Time?

    /// The URL for the root of the source tree.
    ///
    /// If this is non-nil, then the source location of each task will be saved
    /// into generated benchmark results, using GitHub-style URLs with the line
    /// number stored in the URL fragment. For example, if `sourceURL` is
    /// `https://example.org/`, then a task at line 42 of
    /// `Sources/foo/bar/benchmark.swift` will generate the following URL:
    ///
    ///  `https://example.org/Sources/foo/bar/benchmark.swift#L42`
    ///
    /// Typically, you'll want the URL to address the specific commit you're
    /// benchmarking.
    public var sourceURL: String?

    public init() {}

    public init(
      options: GeneralOptions,
      tasks: [TaskID],
      sizes: [Size]
    ) throws {
      self.init()
      self.tasks = tasks
      self.sizes = sizes
      self.cycles = options.cycles
      self.iterations = options.iterations
      self.minimumDuration = options.minimumDuration
      self.maximumDuration = options.maximumDuration
      self.amortizedCutoff = options.disableCutoff ? nil : options.amortizedCutoff
      if let sourceURL = options.sourceURL {
        self.sourceURL = sourceURL
      }
    }
  }
}

extension Benchmark.Options {
  public func resolveTasks(
    from benchmark: Benchmark
  ) throws -> [AnyTask] {
    if tasks.isEmpty {
      throw Benchmark.Error("No tasks selected")
    }
    var result: _SimpleOrderedSet<AnyTask> = []
    for id in tasks {
      guard let task = benchmark.task(named: id.title) else {
        throw Benchmark.Error("Unknown task: '\(id.title)'")
      }
      result.append(task.withLabel(id.label))
    }
    return result.elements
  }

  public func resolveSizes() throws -> [Size] {
    let sizes = self.sizes.sorted()
    var last: Size = 0
    for size in sizes {
      guard size > last else {
        throw Benchmark.Error("Invalid size list: duplicate entry '\(size)'")
      }
      last = size
    }
    guard !sizes.isEmpty else {
      throw Benchmark.Error("No sizes selected")
    }
    return sizes
  }
}

extension Benchmark.Options {
  public struct TaskSelection: ParsableArguments {
    @Option(parsing: .upToNextOption,
            help: "List of benchmark tasks to operate on. (default: all tasks)")
    public var tasks: [TaskID] = []

    @Option(
      help: "A file containing additional task names.",
      completion: .file(),
      transform: { str in FilePath(str) })
    public var tasksFile: FilePath? = nil

    @Option(
      name: [.long, .customShort("f")],
      parsing: .singleValue,
      help: "Only select tasks that match this regular expression.")
    public var filter: [String] = []

    @Option(
      name: [.long, .customShort("x")],
      parsing: .singleValue,
      help: "Exclude tasks that match this regular expression.")
    public var exclude: [String] = []

    public init() {
    }

    public static var empty: Self {
      var value = Self()
      value.tasks = []
      value.tasksFile = nil
      value.filter = []
      value.exclude = []
      return value
    }
  }

  public struct SizeSelection: ParsableArguments {
    @Option(help: "Minimum size (default: 1)")
    public var minSize = Size(1)

    @Option(help: "Maximum size (default: 1M)")
    public var maxSize = Size(1 << 20)

    @Option(help: "Number of subdivisions between powers of two on the size axis. (1 ... 10)")
    public var smoothness: Int = 3

    @Option(parsing: .upToNextOption, help: "Specific sizes to use. Overrides min-size and max-size.")
    public var sizes: [Size] = []

    public init() {}
  }

  public struct GeneralOptions: ParsableArguments {
    @Option(help: "Number of times to repeat benchmark tasks (default: no limit)")
    public var cycles: Int?

    @Option(help: "Number of times to run each task/size measurement")
    public var iterations: Int = 3

    @Option(name: .customLong("min-duration"),
            help: "Repeat each task for at least this number of seconds")
    public var minimumDuration = Time(0.01)

    @Option(name: .customLong("max-duration"),
            help: "Stop repeating tasks if this amount of time has elapsed (default: no limit)")
    public var maximumDuration: Time?

    @Option(help: "Stop running a particular task if its per-element processing time goes beyond this value (default: 10µs)")
    public var amortizedCutoff: Time = Time("10µs")!

    @Option(help: "Disable amortized cutoff")
    public var disableCutoff = false

    @Option(help: "The base URL to project sources. This is used to set links to the source of each task in the generated results. (default: none)")
    var sourceURL: String?

    public init() {}
  }
}


extension Benchmark.Options.SizeSelection {
  public func resolveSizes() throws -> [Size] {
    if !sizes.isEmpty {
      let sizes = self.sizes.sorted()
      var last: Size = 0
      for size in sizes {
        guard size > last else {
          throw Benchmark.Error("Invalid size list: duplicate entry '\(size)'")
        }
        last = size
      }
      return sizes
    }

    guard minSize <= maxSize else {
      throw Benchmark.Error("minimum size must not exceed maximum size")
    }
    guard smoothness >= 1, smoothness <= 6 else {
      throw Benchmark.Error("smoothness must be between 1 and 6")

    }
    return Size.sizes(for: minSize ... maxSize, significantDigits: smoothness)
  }
}
