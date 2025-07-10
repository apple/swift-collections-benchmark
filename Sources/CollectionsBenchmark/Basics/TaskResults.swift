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

import Foundation // URL

/// A series of samples taken at for various sizes for a particular
/// benchmark task.
public struct TaskResults: Sendable {
  public typealias Element = (size: Size, sample: Sample)

  internal typealias _Results = _SimpleSortedDictionary<Size, Sample>

  public internal(set) var taskID: TaskID
  public internal(set) var link: URL?

  internal var _samples: _SimpleSortedDictionary<Size, Sample>

  public init(id: TaskID, link: URL? = nil) {
    self.taskID = id
    self.link = link
    self._samples = [:]
  }
}

extension TaskResults {
  public var samples: Samples { Samples(_samples: _samples) }

  public struct Samples: RandomAccessCollection {
    public typealias Element = TaskResults.Element
    public typealias Index = Int
    public typealias Indices = Range<Int>

    internal typealias _Results = _SimpleSortedDictionary<Size, Sample>

    let _samples: _Results

    init(_samples: _Results) {
      self._samples = _samples
    }

    public var startIndex: Index { _samples.startIndex.offset }
    public var endIndex: Index { _samples.endIndex.offset }

    public subscript(position: Int) -> Element {
      let item = _samples[_Results.Index(position)]
      return (item.key, item.value)
    }
  }
}

extension TaskResults: Sequence {
  public struct Iterator: IteratorProtocol {
    internal let _samples: _Results
    internal var _index: _Results.Index
    init(_ results: TaskResults) {
      self._samples = results._samples
      self._index = results._samples.startIndex
    }
    public mutating func next() -> Element? {
      guard _index < _samples.endIndex else { return nil }
      defer { _index.offset += 1 }
      let item = _samples[_index]
      return (item.key, item.value)
    }
  }
  public var underestimatedCount: Int { _samples.count }
  public func makeIterator() -> Iterator { Iterator(self) }
}

extension TaskResults: Codable {
  public enum CodingKey: String, Swift.CodingKey {
    case title
    case label
    case link
    case results
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKey.self)
    let title = try container.decode(String.self, forKey: .title)
    let label = try container.decodeIfPresent(String.self, forKey: .label)
    let link = try container.decodeIfPresent(URL.self, forKey: .link)
    let resultsContainer = try container.nestedContainer(keyedBy: Size.self, forKey: .results)
    var results: Array<(key: Size, value: Sample)> = []
    for size in resultsContainer.allKeys {
      let sample = try resultsContainer.decode(Sample.self, forKey: size)
      results.append((size, sample))
    }
    results.sort(by: { $0.key < $1.key })
    var last: Size? = nil
    for (size, _) in results {
      guard size != last else {
        throw DecodingError.dataCorruptedError(
          forKey: size, in: resultsContainer,
          debugDescription: "Duplicate size \(size)")
      }
      last = size
    }
    self.taskID = TaskID(label: label ?? "", title: title)
    self.link = link
    self._samples = _SimpleSortedDictionary(uniqueKeysWithValues: results)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKey.self)
    try container.encode(taskID.title, forKey: .title)
    if !taskID.label.isEmpty {
      try container.encode(taskID.label, forKey: .label)
    }
    try container.encodeIfPresent(link, forKey: .link)
    var resultContainer = container.nestedContainer(keyedBy: Size.self, forKey: .results)
    for (size, sample) in _samples {
      try resultContainer.encode(sample, forKey: size)
    }
  }
}

extension TaskResults {
  public subscript(_ size: Size) -> Sample {
    get {
      _samples[size, default: Sample()]
    }
    _modify {
      yield &_samples[size, default: Sample()]
    }
  }

  public mutating func add(_ results: TaskResults) {
    if self._samples.isEmpty {
      self._samples = results._samples
      return
    }
    for (size, sample) in results._samples {
      self._samples[size, default: Sample()].add(sample)
    }
  }
  
  public mutating func add(size: Size, time: Time) {
    _samples[size, default: Sample()].add(time)
  }

  public mutating func remove(sizes: [Size]) {
    let sizes = Set(sizes)
    _samples.removeAll { sizes.contains($0.key) }
  }

  public mutating func clear() {
    _samples = [:]
  }
}

extension TaskResults {
  public var sampleCount: Int {
    _samples.reduce(into: 0, { $0 += $1.value.count })
  }
}
extension TaskResults {
  func curve(
    for statistic: Sample.Statistic,
    percentile: Double,
    amortizedTime: Bool
  ) -> Curve<Measurement> {
    var curve = Curve<Measurement>()
    for (size, sample) in _samples {
      let sample = sample.discardingPercentile(above: percentile)
      guard let time = sample[statistic] ?? sample[.mean] else { continue }

      let t = amortizedTime ? time.amortized(over: size) : time
      curve.points.append(Measurement(size: size, time: t))
    }
    return curve
  }
}

extension TaskResults {
  func withLabel(_ label: String) -> TaskResults {
    var copy = self
    copy.taskID.label = label
    return copy
  }
}
