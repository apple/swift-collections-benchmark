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

import Foundation // For URL

/// Just enough graphics to render basic 2D charts.
public struct Graphics: Codable {
  public var bounds: Rectangle
  public var elements: [Element] = []

  public init(bounds: Rectangle, elements: [Element] = []) {
    self.bounds = bounds
    self.elements = elements
  }
}

extension Graphics {
  public mutating func add(_ shape: Shape) {
    elements.append(.shape(shape))
  }
  public mutating func add(_ text: Text) {
    elements.append(.text(text))
  }

  public mutating func addLine(
    from start: Point,
    to end: Point,
    stroke: Stroke? = nil
  ) {
    let path: Path = .line(from: start, to: end)
    add(Shape(path: path, stroke: stroke))
  }

  public mutating func addRect(
    _ rect: Rectangle,
    fill: Color? = nil,
    stroke: Stroke? = nil
  ) {
    let path: Path = .rect(rect)
    add(Shape(path: path, fill: fill, stroke: stroke))
  }

  public mutating func addLines(
    _ points: [Point],
    fill: Color? = nil,
    stroke: Stroke? = nil
  ) {
    let path: Path = .lines(points)
    add(Shape(path: path, fill: fill, stroke: stroke))
  }

  public mutating func addText(
    _ string: String,
    style: Text.Style,
    linkTarget: URL? = nil,
    in boundingBox: Rectangle,
    descender: Double
  ) {
    let text = Text(
      string,
      style: style,
      linkTarget: linkTarget,
      in: boundingBox,
      descender: descender)
    add(text)
  }

  public mutating func addGroup(
    clippingRect: Rectangle,
    contents: (inout Graphics) -> Void
  ) {
    var group = Graphics(bounds: clippingRect)
    contents(&group)
    elements.append(.group(clippingRect: clippingRect, group.elements))
  }
}
