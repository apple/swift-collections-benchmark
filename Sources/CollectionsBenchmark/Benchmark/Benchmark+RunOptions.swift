//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension Benchmark {
  public func measureOneCycle(
    tasks: [AnyTask],
    sizes: [Size],
    options: Options,
    delegate: (Event) throws -> Void = { _ in }
  ) throws {
    let taskTitles = tasks.map { $0.id }

    try delegate(.startCycle(tasks: taskTitles, sizes: sizes))

    var maxSizes: [String: Size] = [:]

    let cycleStart = Tick.now
    for size in sizes {
      let sizeStart = Tick.now
      try delegate(.startSize(tasks: taskTitles, size: size))

      var inputs: [_TypeBox: Any] = [:]

      for task in tasks {
        if let max = maxSizes[task.title], max < size { continue }

        let input = inputs._cachedValue(for: _TypeBox(task.inputType)) { type in
          _inputGenerators[type]!(size.rawValue)
        }

        try delegate(.startTask(task: task.id, size: size))
        if let time = task.measure(size: size, input: input, options: options) {
          try delegate(.stopTask(task: task.id, size: size, time: time))
          // If we have exceeded the cutoff, then don't try running the task at
          // this size or larger ever again.
          //
          // Ignore the cutoff until the absolute elapsed time is larger than
          // one second. This hardwired threshold prevents us mistakenly stopping
          // measuring a task just because it ran into some large constant
          // overhead at tiny sizes.
          if
            time > Time.seconds(1), // Safety threshold
            let cutoff = options.amortizedCutoff,
            time.amortized(over: size) > cutoff
          {
            maxSizes[task.title] = size
          }
        }
      }

      let sizeDelta = Time.since(sizeStart)
      try delegate(.stopSize(tasks: taskTitles, size: size, time: sizeDelta))
    }
    let cycleDelta = Time.since(cycleStart)
    try delegate(.stopCycle(tasks: taskTitles, sizes: sizes, time: cycleDelta))
  }

  public func run(
    options: Options,
    delegate: (Event) throws -> Void
  ) throws {
    let tasks = try options.resolveTasks(from: self)
    guard let cycles = options.cycles else {
      while true {
        try measureOneCycle(
          tasks: tasks,
          sizes: options.sizes,
          options: options,
          delegate: delegate)
      }
    }
    guard cycles >= 0 else {
      throw Error("Number of cycles cannot be negative")
    }
    for _ in 0 ..< cycles {
      try measureOneCycle(
        tasks: tasks,
        sizes: options.sizes,
        options: options,
        delegate: delegate)
    }
  }
}
