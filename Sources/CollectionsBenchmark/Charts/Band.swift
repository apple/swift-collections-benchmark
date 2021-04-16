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

public enum BandIndex: Int, CaseIterable, Hashable, CodingKey {
  case bottom
  case center
  case top
}

/// A generic homogeneous triple with top, center and bottom parts.
///
/// Useful in representing a curve with "error bands" in a 2D chart.
public struct Band<Element> {
  public var bottom: Element
  public var center: Element
  public var top: Element

  public init(bottom: Element, center: Element, top: Element) {
    self.bottom = bottom
    self.center = center
    self.top = top
  }
  
  public init(_ value: Element) {
    self.bottom = value
    self.center = value
    self.top = value
  }
}

extension Band: Sequence {
  public func makeIterator() -> Array<Element>.Iterator {
    return [bottom, center, top].makeIterator()
  }
}

extension Band { // Collection without all the fluff
  public typealias Index = BandIndex
  
  public subscript(_ index: Index) -> Element {
    get {
      switch index {
      case .bottom: return bottom
      case .center: return center
      case .top: return top
      }
    }
    _modify {
      switch index {
      case .bottom: yield &bottom
      case .center: yield &center
      case .top:    yield &top
      }
    }
  }
}

extension Band: Decodable where Element: Decodable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: Index.self)
    self.bottom = try container.decode(Element.self, forKey: .bottom)
    self.center = try container.decode(Element.self, forKey: .center)
    self.top = try container.decode(Element.self, forKey: .top)
  }
}

extension Band: Encodable where Element: Encodable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: Index.self)
    try container.encode(bottom, forKey: .bottom)
    try container.encode(center, forKey: .center)
    try container.encode(top, forKey: .top)
  }
}

extension Band {
  public func map<T>(_ transform: (Element) -> T) -> Band<T> {
    return Band<T>(
      bottom: transform(bottom),
      center: transform(center),
      top: transform(top))
  }
}

extension Band where Element == Curve<BenchmarkResults.Measurement> {
  var sizeRange: ClosedRange<Size>? {
    _union(bottom.sizeRange, _union(center.sizeRange, top.sizeRange))
  }
  
  var timeRange: ClosedRange<Time>? {
    _union(bottom.timeRange, _union(center.timeRange, top.timeRange))
  }
}
