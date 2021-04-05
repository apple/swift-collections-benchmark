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

public struct EdgeInsets: Hashable, Codable {
  public var top: CGFloat
  public var left: CGFloat
  public var bottom: CGFloat
  public var right: CGFloat
  
  public init() {
    top = 0
    left = 0
    bottom = 0
    right = 0
  }
  
  public init(
    top: CGFloat = 0,
    left: CGFloat = 0,
    bottom: CGFloat = 0,
    right: CGFloat = 0
  ) {
    self.top = top
    self.left = left
    self.bottom = bottom
    self.right = right
  }
}

extension CGRect {
  public func inset(by insets: EdgeInsets) -> CGRect {
    CGRect(
      x: self.origin.x + insets.left,
      y: self.origin.y + insets.top,
      width: self.size.width - insets.left - insets.right,
      height: self.size.height - insets.bottom - insets.top)
  }
}
