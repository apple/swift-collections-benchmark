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

extension Graphics {
  public static var bestAvailableRenderer: Renderer {
    #if os(macOS)
    return CocoaRenderer()
    #elseif os(iOS) || os(watchOS) || os(tvOS)
    return UIKitRenderer()
    #else
    return DefaultRenderer()
    #endif
  }
}

// A fallback renderer when we don't have an actual graphics system, only
// supporting SVG and JSON output.
//
// This substitutes every font with *Courier New* and measures strings using
// hardwired metrics, assuming there is a one-to-one mapping between characters
// and glyphs.
public struct DefaultRenderer: Renderer {
  public func resolve(_ font: Font) -> Font {
    var substitute = font
    substitute.family = "Courier New"
    return substitute
  }

  public func measure(
    _ font: Font,
    _ text: String
  ) -> (size: CGSize, descender: CGFloat) {
    let unitAdvancement = CGSize(width: 0.60009765625, height: 1.1328125)
    let unitDescender: CGFloat = 0.30029296875

    let width = CGFloat(text.count) * font.size * unitAdvancement.width
    let height = font.size * unitAdvancement.height
    let descender = unitDescender * font.size

    return (
      size: CGSize(
        width: width.rounded(.up),
        height: height.rounded(.up)),
      descender: descender)
  }

  public var supportedImageFormats: [ImageFormat] { [.json, .svg, .html] }
  public var defaultImageFormat: ImageFormat { .svg }

  public func render(
    _ graphics: Graphics,
    format: String,
    bitmapScale: CGFloat
  ) throws -> Data {
    switch format.lowercased() {
    case "json":
      let encoder = JSONEncoder()
      return try encoder.encode(graphics)
    case "svg":
      let text = graphics.svgString()
      return text.data(using: .utf8)!
    case "html":
      let text = graphics.htmlString()
      return text.data(using: .utf8)!
    default:
      throw Benchmark.Error(
        "Can't generate output for unknown file format '\(format)'")
    }
  }

  public func documentRenderer(
    title: String,
    format: ImageFormat,
    style: DocumentStyle
  ) throws -> DocumentRenderer {
    switch format {
    case .html:
      return HTMLDocumentRenderer(title: title, style: style, lang: "en")
    default:
      throw Benchmark.Error(
        "Can't generate output for unknown file format '\(format)'")
    }
  }
}
