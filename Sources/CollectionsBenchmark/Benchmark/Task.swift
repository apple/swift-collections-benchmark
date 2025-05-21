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

public struct Task<Input> {
  public let title: String
  public let maxSize: Int?
  public let file: StaticString
  public let line: UInt
  public let body: (Input) -> Benchmark.TaskBody?

  public init(
    _ title: String,
    on input: Input.Type = Input.self,
    maxSize: Int? = nil,
    file: StaticString = #filePath,
    line: UInt = #line,
    body: @escaping (Input) -> Benchmark.TaskBody?
  ) {
    if let error = TaskID._validateTitle(title) {
      preconditionFailure("'\(title)': \(error)", file: (file), line: line)
    }
    self.title = title
    self.maxSize = maxSize
    self.file = file
    self.line = line
    self.body = body
  }
}

extension Task: CustomStringConvertible {
  public var description: String {
    title
  }
}

extension Task {
  public func measure(
    size: Size,
    input: Input,
    options: Benchmark.Options
  ) -> Time? {
    if let maxSize = self.maxSize, size.rawValue > maxSize {
      _debug("Ignoring '\(title)' at size \(size)")
      return nil
    }
    guard let instance = self.body(input) else {
      _debug("Ignoring '\(title)' at size \(size)")
      return nil
    }

    let minDuration = options.minimumDuration
    let maxDuration = options.maximumDuration ?? .eternity
    let wallClockStart = Tick.now

    // Measure the task once to get a rough estimate for its length and to
    // determine if it can be measured through bulk iteration.
    //
    // For short tasks, the first measurement can wildly overestimate the
    // actual length because it runs with cold caches. This is fine, as
    // we run short tasks multiple times, and we adjust iteration counts as
    // we go.

    let (firstTime, hasNestedMeasurement) = Timer._measureFirst(instance)
    
    if hasNestedMeasurement {
      // We can't do iterating measurements. Loop over individual
      // measurements until we satisfy requirements.
      //
      // Note: Getting the current time in every iteration adds some
      // overhead that slows such tests down a little bit (by 10ns or so
      // for an empty task).
      var minTime = firstTime
      var iteration = 1
      repeat {
        let wallClockDuration =
          Time.since(wallClockStart)
        if wallClockDuration > maxDuration { break }
        if iteration > options.iterations, wallClockDuration > minTime { break }
        let time = Timer._nestedMeasure(instance)
        minTime = min(minTime, time)
        iteration += 1
      } while true

      _debug("nested, iterations: \(iteration), result: \(minTime)")
      return minTime
    }

    // We need to measure the entire duration of the task. This allows us
    // to run the task multiple times before stopping to look at the time,
    // which can lead to more precise measurements.

    // Don't run the task more than `batchSize` number of times before
    // stopping to collect statistics. Batching iterations like this reduces
    // the chance that outlier runs will corrupt the results.
    // (Inconvenient context switches can add delays that can sometimes
    // take orders of magnitude longer than the task itself.)
    let batchSize = 100

    var minTime = firstTime
    var iteration = 1
    while true {
      let wallClockDuration = Time.since(wallClockStart)
      if wallClockDuration > maxDuration {
        // We ran out of time. Stop measuring.
        break
      }

      var batch: Int
      if wallClockDuration < minDuration {
        let averageDuration = wallClockDuration.seconds / Double(iteration)
        let remainingDuration = minDuration.seconds - wallClockDuration.seconds
        let remainingIterationEstimate =
          Int((remainingDuration / averageDuration).rounded(.up))
        batch = max(1, min(batchSize, remainingIterationEstimate))
      } else if iteration < options.iterations {
        batch = max(1, min(batchSize, options.iterations - iteration))
      } else {
        // We've done enough measurements. Stop measuring.
        break
      }

      let time = Timer._iteratingMeasure(iterations: batch, instance)
      minTime = min(minTime, time)
      iteration += batch
    }

    _debug("direct, iterations: \(iteration), result: \(minTime)")
    return minTime
  }
}
