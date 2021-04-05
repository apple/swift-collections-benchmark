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
import SystemPackage
import ArgumentParser

extension Benchmark.Options.TaskSelection {
  internal func resolve<C: Collection>(
    allKnownTasks: C,
    ignoreLabels: Bool,
    labelOverride: String? = nil,
    ignoreUnknowns: Bool = false
  ) throws -> [TaskID]
  where C.Element == TaskID
  {
    var tasks = self.tasks

    // Read additional task names.
    if let path = tasksFile {
      tasks += try path._utf8Lines().lazy.map { try TaskID(from: $0) }
    }

    // Check for unknown tasks.
    if !ignoreUnknowns {
      let unknownTasks =
        _SimpleOrderedSet(tasks.map { ignoreLabels ? $0.title : $0.description })
        .subtracting(allKnownTasks.lazy.map { ignoreLabels ? $0.title : $0.description })
      guard unknownTasks.isEmpty else {
        if unknownTasks.count == 1 {
          throw Benchmark.Error("Unknown task '\(unknownTasks[0])'")
        }
        throw Benchmark.Error(
          "\(unknownTasks.count) unknown tasks:\n"
            + (unknownTasks
                .map { $0.description }
                .joined(separator: "\n")))
      }
    }

    // Fall back to all tasks if none given.
    if tasks.isEmpty {
      tasks = Array(allKnownTasks)
    }

    // Apply label override.
    if let labelOverride = labelOverride {
      if let error = TaskID._validateLabel(labelOverride) {
        throw Benchmark.Error(error)
      }
      for i in tasks.indices {
        tasks[i].label = labelOverride
      }
    }

    // Filter out duplicates.
    tasks = _SimpleOrderedSet(tasks).elements

    let filters = try self.filter.map { pattern in
      try NSRegularExpression(
        pattern: pattern,
        options: [.anchorsMatchLines, .useUnicodeWordBoundaries])
    }
    let exclusions = try self.exclude.map { pattern in
      try NSRegularExpression(
        pattern: pattern,
        options: [.anchorsMatchLines, .useUnicodeWordBoundaries])
    }
    if !filters.isEmpty || !exclusions.isEmpty {
      tasks = tasks.filter { task in
        let task = ignoreLabels ? task.title : task.description
        let range = NSRange(location: 0, length: task.utf16.count)
        for regex in filters {
          let m = regex.rangeOfFirstMatch(in: task, options: [], range: range)
          if m.location == NSNotFound { return false }
        }
        for regex in exclusions {
          let m = regex.rangeOfFirstMatch(in: task, options: [], range: range)
          if m.location != NSNotFound { return false }
        }
        return true
      }
    }
    guard !tasks.isEmpty else {
      throw Benchmark.Error("No tasks selected")
    }
    return tasks
  }
}
