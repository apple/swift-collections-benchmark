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

public struct Sample: Equatable {
  // Sorted array of measured durations.
  internal var _times: _SimpleSortedBag<Time> = []

  public init() {}
  public init(_ time: Time) { _times = [time] }

  public init<S: Sequence>(
    _ times: S
  ) where S.Element == Time {
    self._times = _SimpleSortedBag(times)
  }

  public var times: [Time] { _times._elements }
  public var count: Int { _times.count }
  public var minimum: Time? { _times.min() }
  public var maximum: Time? { _times.max() }
  public var sum: Time { Time(_times.reduce(0.0, { $0 + $1.seconds })) }
  public var sumSquared: Double { _times.reduce(0.0, { $0 + $1.seconds * $1.seconds })}
  
  public var mean: Time? {
    guard _times.count > 0 else { return nil }
    return Time(sum.seconds / Double(_times.count))
  }
  
  public var standardDeviation: Time? {
    guard _times.count >= 2 else { return nil }
    let c = Double(_times.count)
    let sum = self.sum.seconds
    let s2: Double = (c * self.sumSquared - sum * sum) / (c * (c - 1))
    return Time(s2.magnitude.squareRoot())
  }
  
  public mutating func add(_ time: Time) {
    _times.insert(time)
  }

  public mutating func add(_ sample: Sample) {
    _times.insert(contentsOf: sample.times)
  }
}

extension Sample: CustomStringConvertible {
  public var description: String {
    switch count {
    case 0:
      return "[0 samples]"
    case 1:
      return "[1 sample at \(_times[0])]"
    default:
      let average = self.mean!
      let pct = String(format: "%.3f", standardDeviation!.seconds / average.seconds)
      return "[\(count) samples with μ: \(average) σ: \(pct)%]"
    }
  }
}

extension Sample: Codable {
  public init(from decoder: Decoder) throws {
    self._times = _SimpleSortedBag(try Array(from: decoder))
  }
  
  public func encode(to encoder: Encoder) throws {
    try self.times.encode(to: encoder)
  }
}
