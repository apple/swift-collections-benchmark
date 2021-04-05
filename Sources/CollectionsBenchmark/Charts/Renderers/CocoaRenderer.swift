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

#if os(macOS)
import Quartz
import AppKit

extension Color {
  @available(macOS 10.11, *)
  public init?(_ color: NSColor) {
    self.init(color.cgColor)
  }

  public var nsColor: NSColor {
    NSColor(cgColor: cgColor)!
  }
}

extension NSBezierPath.LineCapStyle {
  public init(_ style: Stroke.CapStyle) {
    switch style {
    case .butt: self = .butt
    case .round: self = .round
    case .square: self = .square
    }
  }
}

extension NSBezierPath.LineJoinStyle {
  public init(_ style: Stroke.JoinStyle) {
    switch style {
    case .bevel: self = .bevel
    case .miter: self = .miter
    case .round: self = .round
    }
  }
}

extension NSBezierPath {
  public convenience init(_ path: Path) {
    switch path {
    case let .line(from: start, to: end):
      self.init()
      move(to: start)
      line(to: end)
    case let .rect(rect):
      self.init(rect: rect)
    case let .lines(points):
      self.init()
      if points.isEmpty { return }
      self.move(to: points[0])
      for point in points.dropFirst() {
        self.line(to: point)
      }
    }
  }
}

extension NSImage {
  internal func _pngData(scale: CGFloat = 4) throws -> Data {
    let cgimage = self.cgImage(
      forProposedRect: nil,
      context: nil,
      hints: [.ctm: NSAffineTransform(transform: .init(scale: scale))])!
    let rep = NSBitmapImageRep(cgImage: cgimage)
    rep.size = self.size
    guard let data = rep.representation(using: .png, properties: [:]) else {
      throw Benchmark.Error("Error generating PNG data")
    }
    return data
  }
}

internal class _CocoaFontCache {
  private let _lock = NSLock()
  private var _fonts: [Font: NSFont] = [:]
  private var _knownMissingFonts: Set<Font> = []

  internal func font(for font: NSFont) -> Font {
    let traits = font.fontDescriptor.symbolicTraits
    return Font(
      family: font.familyName ?? font.fontName,
      size: font.pointSize,
      isBold: traits.contains(.bold),
      isItalic: traits.contains(.italic))
  }

  internal func nsFont(for font: Font) -> NSFont {
    _lock.lock()
    defer { _lock.unlock() }
    return _fonts._cachedValue(for: font) { font in
      var traits: NSFontDescriptor.SymbolicTraits = []
      if font.isBold { traits.insert(.bold) }
      if font.isItalic { traits.insert(.italic) }
      let descriptor = NSFontDescriptor()
        .withFamily(font.family)
        .withSymbolicTraits(traits)
      if let nsfont = NSFont(descriptor: descriptor, size: font.size) {
        return nsfont
      }
      if _knownMissingFonts.insert(font).inserted {
        complain("warning: Missing font '\(font)' substituted with default")
      }
      return NSFont.systemFont(ofSize: font.size)
    }
  }
}

public class CocoaRenderer: Renderer {
  private let _fontCache = _CocoaFontCache()

  public func resolve(_ font: Font) -> Font { font }

  public func measure(
    _ font: Font,
    _ text: String
  ) -> (size: CGSize, descender: CGFloat) {
    let font = _fontCache.nsFont(for: font)
    let size = (text as NSString).boundingRect(
      with: CGSize(width: 1000, height: 1000),
      options: [.usesFontLeading],
      attributes: [.font: font]).integral.size
    return (size, -font.descender)
  }

  public func renderPNG(for graphics: Graphics, scale: CGFloat) throws -> Data {
    try renderImage(for: graphics)._pngData(scale: scale)
  }

  public func renderPDF(for graphics: Graphics) throws -> Data {
    let pdfInfo: [CFString: Any] = [
      kCGPDFContextCreator: _projectName,
    ]
    let data = NSMutableData()
    var bounds = graphics.bounds
    let c = CGContext(
      consumer: CGDataConsumer(data: data as CFMutableData)!,
      mediaBox: &bounds,
      pdfInfo as CFDictionary)!

    c.beginPDFPage(nil)

    // Flip the context.
    c.scaleBy(x: 1, y: -1)
    c.translateBy(x: 0, y: -bounds.height)

    NSGraphicsContext.current = NSGraphicsContext(cgContext: c, flipped: true)

    self.draw(graphics)

    c.endPDFPage()
    c.closePDF()
    return data as Data
  }

  public func renderImage(for graphics: Graphics) -> NSImage {
    let b = graphics.bounds
    return NSImage(size: b.integral.size, flipped: true) { rect in
      let t = AffineTransform(translationByX: -b.minX, byY: -b.minY)
      NSAffineTransform(transform: t).concat()
      self.draw(graphics)
      return true
    }
  }

  /// Render the given graphics in the current graphics context,
  /// which must be flipped.
  public func draw(_ graphics: Graphics) {
    draw(graphics.elements)
  }

  /// Render the given graphic elements in the current graphics context,
  /// which must be flipped.
  public func draw(_ elements: [Graphics.Element]) {
    for element in elements {
      self.draw(element)
    }
  }

  /// Render the given graphic element in the current graphics context,
  /// which must be flipped.
  public func draw(_ element: Graphics.Element) {
    switch element {
    case let .shape(shape):
      let path = NSBezierPath(shape.path)
      if let fill = shape.fill {
        fill.nsColor.setFill()
        path.fill()
      }
      if let stroke = shape.stroke {
        path.lineWidth = stroke.width
        path.lineCapStyle = .init(stroke.capStyle)
        path.lineJoinStyle = .init(stroke.joinStyle)
        if let dash = stroke.dash {
          path.setLineDash(
            dash.style, count: dash.style.count, phase: dash.phase)
        }
        stroke.color.nsColor.setStroke()
        path.stroke()
      }
    case let .text(text):
      if let url = text.linkTarget {
        let c = NSGraphicsContext.current!.cgContext
        let tr = c.userSpaceToDeviceSpaceTransform
        c.setURL(url as CFURL, for: text.boundingBox.applying(tr))
      }
      var attributes: [NSAttributedString.Key: Any] = [:]
      attributes[.font] = _fontCache.nsFont(for: text.style.font)
      attributes[.foregroundColor] = text.style.color.nsColor
      //attributes[.link] = text.linkTarget
      let str = NSAttributedString(string: text.string, attributes: attributes)
      str.draw(in: text.boundingBox)

    case let .group(clippingRect: clippingRect, elements):
      NSGraphicsContext.saveGraphicsState()
      clippingRect.clip()
      draw(elements)
      NSGraphicsContext.restoreGraphicsState()
    }
  }

  public var supportedImageFormats: [ImageFormat] {
    [.png, .pdf] + DefaultRenderer().supportedImageFormats
  }

  public var defaultImageFormat: ImageFormat { .png }

  public func render(
    _ graphics: Graphics,
    format: String,
    bitmapScale: CGFloat
  ) throws -> Data {
    switch format.lowercased() {
    case "png":
      return try renderPNG(for: graphics, scale: bitmapScale)
    case "pdf":
      return try renderPDF(for: graphics)
    default:
      return try DefaultRenderer().render(graphics, format: format, bitmapScale: bitmapScale)
    }
  }

  public func documentRenderer(
    title: String,
    format: ImageFormat,
    style: DocumentStyle
  ) throws -> DocumentRenderer {
    switch format {
    default:
      return try DefaultRenderer().documentRenderer(title: title, format: format, style: style)
    }
  }
}
#endif // os(macOS)
