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
  public var top: Double
  public var left: Double
  public var bottom: Double
  public var right: Double

  public init(
    top: Double = 0,
    left: Double = 0,
    bottom: Double = 0,
    right: Double = 0
  ) {
    self.top = top
    self.left = left
    self.bottom = bottom
    self.right = right
  }

  public init(
    minX: Double = 0,
    minY: Double = 0,
    maxX: Double = 0,
    maxY: Double = 0
  ) {
    self.init(top: minY, left: minX, bottom: maxY, right: maxX)
  }

  public var minX: Double { left }
  public var minY: Double { top }
  public var maxX: Double { right }
  public var maxY: Double { bottom }

  public var dx: Double { minX + maxX }
  public var dy: Double { minY + maxY }
}
