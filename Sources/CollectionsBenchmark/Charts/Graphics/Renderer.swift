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
import ArgumentParser
import SystemPackage

/// A bare-bones font layout system.
public protocol Renderer {
  /// Resolve the given font specification to a supported font.
  func resolve(_ font: Font) -> Font

  /// Measures `text` using `font`.
  ///
  /// `text` must not contain more than one line.
  func measure(
    _ font: Font,
    _ text: String
  ) -> (size: CGSize, descender: CGFloat)

  var supportedImageFormats: [ImageFormat] { get }
  var defaultImageFormat: ImageFormat { get }

  func render(
    _ graphics: Graphics,
    format: String,
    bitmapScale: CGFloat
  ) throws -> Data

  func documentRenderer(
    title: String,
    format: ImageFormat,
    style: DocumentStyle
  ) throws -> DocumentRenderer
}

public enum DocumentStyle {
  case collapsible
  case flat
}

extension Renderer {
  public func resolve(_ style: Text.Style) -> Text.Style {
    var r = style
    r.font = resolve(r.font)
    return r
  }
}
