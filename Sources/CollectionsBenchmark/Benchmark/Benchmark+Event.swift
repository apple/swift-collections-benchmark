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
  public enum Event: Sendable {
    /// An event sent at the start of measuring a benchmark task on a particular input size.
    case startTask(task: TaskID, size: Size)

    /// An event sent at the end of measuring a benchmark task on a particular input size.
    case stopTask(task: TaskID, size: Size, time: Time)

    /// An event sent at the start of measuring a series of tasks on a particular input size.
    case startSize(tasks: [TaskID], size: Size)

    /// An event sent at the end of measuring a series of tasks on a particular input size.
    case stopSize(tasks: [TaskID], size: Size, time: Time)

    /// An event sent at the start of a new measurement cycle.
    case startCycle(tasks: [TaskID], sizes: [Size])

    /// An event sent at the end of a measurement cycle, containing the time spent on measuring all the task/size combinations in the entire cycle.
    case stopCycle(tasks: [TaskID], sizes: [Size], time: Time)
  }
}
