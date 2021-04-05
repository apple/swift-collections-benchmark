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

/// A simple document model with periodic autosaving.
internal struct _Document {

  internal enum Mode: String, Codable, CustomStringConvertible, ExpressibleByArgument {
    case append = "append"
    case replace = "replace"
    case replaceAll = "replace-all"

    var description: String { rawValue }
  }

  let url: URL
  let format: BenchmarkResults.OutputFormat
  let mode: Mode
  var _lastSave: Tick
  var _results: BenchmarkResults
  var _isDirty: Bool

  /// Prevent losing data by saving the output file every handful of seconds.
  let _savePeriod = Time(10) // FIXME Maybe replace this with a command line option

  init(
    url: URL,
    format: BenchmarkResults.OutputFormat,
    mode: Mode,
    lastSave: Tick,
    results: BenchmarkResults
  ) {
    self.url = url
    self.format = format
    self.mode = mode
    self._lastSave = lastSave
    self._results = results
    self._isDirty = false
  }

  init(creating path: FilePath, format: BenchmarkResults.OutputFormat, mode: Mode) throws {
    let url = URL(path, isDirectory: false)
    let results = BenchmarkResults()
    try results.save(to: url, format: format)
    self.init(url: url, format: format, mode: mode, lastSave: .now, results: results)
  }

  init(
    opening path: FilePath,
    format: BenchmarkResults.OutputFormat,
    mode: Mode
  ) throws {
    if !path._exists {
      try self.init(creating: path, format: format, mode: mode)
    }
    let url = URL(path, isDirectory: false)
    do {
      let results = try BenchmarkResults.load(from: url)
      self.init(url: url, format: format, mode: mode,
                lastSave: .now, results: results)
      return
    } catch {
      guard mode == .replaceAll else { throw error }
      // Allow the original file to be corrupt if we're going to replace it
      // anyway.
      self.init(url: url, format: format, mode: mode,
                lastSave: .now, results: BenchmarkResults())
      _isDirty = true
    }
  }

  var results: BenchmarkResults {
    get { _results }
    _modify {
      _isDirty = true
      yield &_results
    }
  }

  mutating func saveIfNeeded() throws {
    guard _isDirty else { return }
    let now = Tick.now
    guard now.elapsedTime(since: _lastSave) > _savePeriod else { return }
    try save()
  }

  mutating func save() throws {
    try _results.save(to: url, format: format)
    _lastSave = .now
    _isDirty = false
  }

  mutating func run(benchmark: Benchmark, options: Benchmark.Options) throws {
    let tasks = try options.resolveTasks(from: benchmark)
    let sizes = try options.resolveSizes()
    print("""
      Running \(tasks.count) tasks \
      on \(sizes.count) sizes \
      from \(sizes.first!) \
      to \(sizes.last!):
      """)
    for task in tasks.prefix(20) {
      print("  \(task.id)")
    }
    if tasks.count > 20 {
      print("  (\(tasks.count - 20) more)")
    }

    print("Output file: \(url.absoluteURL.path)")
    switch mode {
    case .append:
      print("Appending to existing data (if any) for these tasks/sizes.")
    case .replace:
      print("Discarding existing data (if any) for these tasks/sizes.")
      results.clear(sizes: sizes, from: options.tasks)
    case .replaceAll:
      print("Discarding all existing data.")
      results.clear()
    }

    // Register links to tasks if needed.
    if let sourceURL = options.sourceURL.flatMap({ URL(string: $0) }) {
      for id in options.tasks {
        let task = benchmark.task(named: id.title)!
        _results.add(TaskResults(id: id, link: task._sourceLink(base: sourceURL)))
      }
    }

    print()
    #if DEBUG
    complain("WARNING: Running benchmarks in debug configuration.")
    print()
    #endif

    print("Collecting data:")
    let start = Tick.now
    var needDot = false
    try benchmark.run(options: options) { event in
      switch event {
      case .startCycle:
        print("  ", terminator: "")
      case let .stopCycle(tasks: _, sizes: _, time: time):
        needDot = false
        print(" -- \(time)")
        try save()
      case let .startSize(tasks: _, size: size):
        if size.rawValue & (size.rawValue - 1) == 0 { // Power of two
          if needDot { print(".", terminator: "")}
          print("\(size)", terminator: "")
          needDot = true
        } else {
          print(".", terminator: "")
          needDot = false
        }
      case .stopSize:
        break // Do nothing
      case .startTask:
        break // Do nothing
      case let .stopTask(task: task, size: size, time: time):
        results.add(id: task, size: size, time: time)
        try saveIfNeeded()
      }
    }
    // FIXME: Report memory usage stats, user/sys/wallclock time
    print("Finished in \(Tick.now.elapsedTime(since: start))")
  }

  mutating func merge(results: BenchmarkResults, mode: Mode) {
    switch mode {
    case .append:
      for r in results.tasks {
        self.results.add(r)
      }
    case .replace:
      for r in results.tasks {
        self.results[id: r.taskID] = r
      }
    case .replaceAll:
      self.results = results
    }
  }
}

