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

import Foundation

public struct Stroke: Hashable, Codable {
  public enum CapStyle: String, Hashable, Codable {
    case butt
    case round
    case square
  }
  public enum JoinStyle: String, Hashable, Codable {
    case miter
    case round
    case bevel
  }
  public struct Dash: Hashable, Codable {
    public var style: [Double]
    public var phase: Double = 0
  }

  public var width: Double
  public var color: Color
  public var dash: Dash?
  public var capStyle: CapStyle
  public var joinStyle: JoinStyle

  public init(
    width: Double,
    color: Color,
    dash: Dash? = nil,
    capStyle: CapStyle = .round,
    joinStyle: JoinStyle = .round
  ) {
    self.width = width
    self.color = color
    self.dash = dash
    self.capStyle = capStyle
    self.joinStyle = joinStyle
  }
}
