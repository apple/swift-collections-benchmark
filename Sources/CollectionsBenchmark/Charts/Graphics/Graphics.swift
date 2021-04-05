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

/// Just enough graphics to render basic 2D charts.
public struct Graphics: Codable {
  public var bounds: CGRect
  public var elements: [Element] = []

  public init(bounds: CGRect, elements: [Element] = []) {
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
    from start: CGPoint,
    to end: CGPoint,
    stroke: Stroke? = nil
  ) {
    let path: Path = .line(from: start, to: end)
    add(Shape(path: path, stroke: stroke))
  }

  public mutating func addRect(
    _ rect: CGRect,
    fill: Color? = nil,
    stroke: Stroke? = nil
  ) {
    let path: Path = .rect(rect)
    add(Shape(path: path, fill: fill, stroke: stroke))
  }

  public mutating func addLines(
    _ points: [CGPoint],
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
    in boundingBox: CGRect,
    descender: CGFloat
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
    clippingRect: CGRect,
    contents: (inout Graphics) -> Void
  ) {
    var group = Graphics(bounds: clippingRect)
    contents(&group)
    elements.append(.group(clippingRect: clippingRect, group.elements))
  }
}
