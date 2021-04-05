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

public struct Curve<Point> {
  public internal(set) var points: [Point]
  
  public init(_ points: [Point] = []) {
    self.points = points
  }
}

extension Curve: CustomStringConvertible {
  public var description: String {
    "Curve<\(Point.self)> with \(points.count) points"
  }
}

extension Curve: Decodable where Point: Decodable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    self.points = try container.decode([Point].self)
  }
}

extension Curve: Encodable where Point: Encodable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(points)
  }
}

extension Curve {
  public func map<T>(_ transform: (Point) -> T) -> Curve<T> {
    return Curve<T>(points.map(transform))
  }
}

extension Curve where Point == BenchmarkResults.Point {
  var sizeRange: ClosedRange<Size>? {
    guard !points.isEmpty else { return nil }
    let min = points.min(by: { $0.size < $1.size })
    let max = points.max(by: { $0.size < $1.size })
    return min!.size ... max!.size
  }
  
  var timeRange: ClosedRange<Time>? {
    guard !points.isEmpty else { return nil }
    let min = points.min(by: { $0.time < $1.time })
    let max = points.max(by: { $0.time < $1.time })
    return min!.time ... max!.time
  }
}

extension BenchmarkResults {
  /// A point in the document coordinate system, i.e., a pair of size and
  /// time values.
  public struct Point: Hashable, Codable {
    public let size: Size
    public let time: Time
    
    public init(size: Size, time: Time) {
      self.size = size
      self.time = time
    }
  }
  
  public func curve(id: TaskID, statistic: Sample.Statistic) -> Curve<Point> {
    let points: [Point] = self[id: id].compactMap { (size, sample) in
      guard let time = sample[statistic] else { return nil }
      return Point(size: size, time: time)
    }
    return Curve(points)
  }
}
