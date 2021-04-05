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

import Foundation // CGRect, URL

public struct Text: Codable {
  public struct Style: Hashable, Codable {
    public var font: Font
    public var color: Color
  }

  public var string: String
  public var style: Style
  public var boundingBox: CGRect
  public var descender: CGFloat
  public var linkTarget: URL?

  public init(
    _ string: String,
    style: Style,
    linkTarget: URL? = nil,
    in boundingBox: CGRect,
    descender: CGFloat
  ) {
    self.string = string
    self.style = style
    self.boundingBox = boundingBox
    self.descender = descender
    self.linkTarget = linkTarget
  }
}

