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

import Foundation // For CGPoint, CGRect

public enum Path {
  /// A line segment between two points.
  case line(from: CGPoint, to: CGPoint)
  /// A rectangle.
  case rect(CGRect)
  /// A series of connected line segments.
  case lines([CGPoint])
}

extension Path: Codable {
  public init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    let kind = try container.decode(String.self)
    switch kind {
    case "line":
      self = .line(
        from: try container.decode(CGPoint.self),
        to: try container.decode(CGPoint.self))
    case "rect":
      self = .rect(try container.decode(CGRect.self))
    case "lines":
      self = .lines(try container.decode([CGPoint].self))
    default:
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Unknown path kind '\(kind)'")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    switch self {
    case let .line(from: start, to: end):
      try container.encode("line")
      try container.encode(start)
      try container.encode(end)
    case let .rect(rect):
      try container.encode("rect")
      try container.encode(rect)
    case let .lines(points):
      try container.encode("lines")
      try container.encode(points)
    }
  }
}
