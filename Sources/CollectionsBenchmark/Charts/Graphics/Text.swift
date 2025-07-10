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

public struct Text: Sendable, Codable {
  public struct Style: Sendable, Hashable, Codable {
    public var font: Font
    public var color: Color
  }

  public var string: String
  public var style: Style
  public var boundingBox: Rectangle
  public var descender: Double
  public var linkTarget: URL?

  public init(
    _ string: String,
    style: Style,
    linkTarget: URL? = nil,
    in boundingBox: Rectangle,
    descender: Double
  ) {
    self.string = string
    self.style = style
    self.boundingBox = boundingBox
    self.descender = descender
    self.linkTarget = linkTarget
  }
}

