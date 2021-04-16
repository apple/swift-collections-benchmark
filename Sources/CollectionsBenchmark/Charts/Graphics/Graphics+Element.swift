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

extension Graphics {
  public enum Element {
    case shape(Shape)
    case text(Text)
    case group(clippingRect: Rectangle, [Element])
  }
}

extension Graphics.Element: Codable {
  public init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    let kind = try container.decode(String.self)
    switch kind {
    case "shape":
      self = .shape(try container.decode(Shape.self))
    case "text":
      self = .text(try container.decode(Text.self))
    case "group":
      self = .group(
        clippingRect: try container.decode(Rectangle.self),
        try container.decode([Self].self))
    default:
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Unknown graphics element '\(kind)'")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    switch self {
    case let .shape(shape):
      try container.encode("shape")
      try container.encode(shape)
    case let .text(text):
      try container.encode("text")
      try container.encode(text)
    case let .group(clippingRect: clippingRect, elements):
      try container.encode("group")
      try container.encode(clippingRect)
      try container.encode(elements)
    }
  }
}
