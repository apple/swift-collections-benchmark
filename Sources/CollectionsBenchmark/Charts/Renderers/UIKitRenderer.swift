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

#if os(iOS) || os(watchOS) || os(tvOS)
import UIKit

extension Color {
  public init?(_ color: UIColor) {
    self.init(color.cgColor)
  }

  public var uiColor: UIColor {
    UIColor(cgColor: cgColor)
  }
}

extension UIBezierPath {
  public convenience init(_ path: Path) {
    switch path {
    case let .line(from: start, to: end):
      self.init()
      move(to: CGPoint(start))
      addLine(to: CGPoint(end))
    case let .rect(rect):
      self.init(rect: CGRect(rect))
    case let .lines(points):
      self.init()
      if points.isEmpty { return }
      self.move(to: CGPoint(points[0]))
      for point in points.dropFirst() {
        self.addLine(to: CGPoint(point))
      }
    }
  }
}

internal class _UIKitFontCache {
  private let _lock = NSLock()
  private var _fonts: [Font: UIFont] = [:]
  private var _knownMissingFonts: Set<Font> = []

  internal func uiFont(for font: Font) -> UIFont {
    _lock.lock()
    defer { _lock.unlock() }
    return _fonts._cachedValue(for: font) { font in
      var traits: UIFontDescriptor.SymbolicTraits = []
      if font.isBold { traits.insert(.traitBold) }
      if font.isItalic { traits.insert(.traitItalic) }
      let descriptor = UIFontDescriptor()
        .withFamily(font.family)
        .withSymbolicTraits(traits)!
      return UIFont(descriptor: descriptor, size: CGFloat(font.size))
    }
  }

  internal func font(for font: UIFont) -> Font {
    let traits = font.fontDescriptor.symbolicTraits
    return Font(
      family: font.familyName,
      size: Double(font.pointSize),
      isBold: traits.contains(.traitBold),
      isItalic: traits.contains(.traitItalic))
  }
}

public struct UIKitRenderer: Renderer {
  private let _fontCache = _UIKitFontCache()

  public func resolve(_ font: Font) -> Font { font }

  public func measure(
    _ font: Font,
    _ text: String
  ) -> (width: Double, height: Double, descender: Double) {
    let font = _fontCache.uiFont(for: font)
    let size = (text as NSString).boundingRect(
      with: CGSize(width: 1000, height: 1000),
      options: [.usesFontLeading],
      attributes: [.font: font],
      context: nil
    ).integral.size
    return (Double(size.width), Double(size.height), -Double(font.descender))
  }

  #if !os(watchOS)
  @available(iOS 10, tvOS 10, *)
  public func renderPNG(for graphics: Graphics, scale: Double) throws -> Data {
    guard let data = renderBitmap(for: graphics, scale: scale).pngData() else {
      throw Benchmark.Error("Error generating PNG data")
    }
    return data
  }

  @available(iOS 10, tvOS 10, *)
  public func renderPDF(for graphics: Graphics) throws -> Data {
    let renderer = UIGraphicsPDFRenderer(bounds: CGRect(graphics.bounds))
    return renderer.pdfData { context in
      context.beginPage(withBounds: CGRect(graphics.bounds),
                        pageInfo: [kCGPDFContextCreator as String: _projectName])
      draw(graphics.elements)
    }
  }

  @available(iOS 10, tvOS 10, *)
  public func renderBitmap(for graphics: Graphics, scale: Double) -> UIImage {
    let srgbTraits = UITraitCollection(displayGamut: .SRGB)
    let format: UIGraphicsImageRendererFormat
    if #available(iOS 11, tvOS 11, *) {
      format = UIGraphicsImageRendererFormat(for: srgbTraits)
    } else {
      format = UIGraphicsImageRendererFormat()
    }
    format.opaque = false
    if #available(iOS 12, tvOS 12, *) {
      format.preferredRange = .standard
    }
    format.scale = CGFloat(scale)
    let renderer = UIGraphicsImageRenderer(
      bounds: CGRect(graphics.bounds),
      format: format)
    return renderer.image { _ in
      draw(graphics.elements)
    }
  }
  #endif

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
      let path = UIBezierPath(shape.path)
      if let fill = shape.fill {
        fill.uiColor.setFill()
        path.fill()
      }

      if let stroke = shape.stroke {
        path.lineWidth = CGFloat(stroke.width)
        path.lineCapStyle = .init(stroke.capStyle)
        path.lineJoinStyle = .init(stroke.joinStyle)
        if let dash = stroke.dash {
          path.setLineDash(
            dash.style.map { CGFloat($0) },
            count: dash.style.count,
            phase: CGFloat(dash.phase))
        }
        stroke.color.uiColor.setStroke()
        path.stroke()
      }
    case let .text(text):
      if let url = text.linkTarget {
        let c = UIGraphicsGetCurrentContext()!
        let tr = c.userSpaceToDeviceSpaceTransform
        UIGraphicsSetPDFContextURLForRect(
          url,
          CGRect(text.boundingBox).applying(tr))
      }
      var attributes: [NSAttributedString.Key: Any] = [:]
      attributes[.font] = _fontCache.uiFont(for: text.style.font)
      attributes[.foregroundColor] = text.style.color.uiColor
      let str = NSAttributedString(string: text.string, attributes: attributes)
      str.draw(in: CGRect(text.boundingBox))
    case let .group(clippingRect: clippingRect, elements):
      let c = UIGraphicsGetCurrentContext()!
      c.saveGState()
      c.clip(to: CGRect(clippingRect))
      draw(elements)
      c.restoreGState()
    }
  }

  public var supportedImageFormats: [ImageFormat] {
    var result = DefaultRenderer().supportedImageFormats
    #if !os(watchOS)
    if #available(iOS 10.0, tvOS 10, *) {
      result += [.png, .pdf]
    }
    #endif
    return result
  }

  public var defaultImageFormat: ImageFormat { .png }

  public func render(
    _ graphics: Graphics,
    format: String,
    bitmapScale: Double
  ) throws -> Data {
    let format = format.lowercased()
    #if !os(watchOS)
    if #available(iOS 10.0, tvOS 10, *), format == "png" {
      return try renderPNG(for: graphics, scale: bitmapScale)
    }
    if #available(iOS 10.0, tvOS 10, *), format == "pdf" {
      return try renderPDF(for: graphics)
    }
    #endif
    return try DefaultRenderer().render(graphics, format: format, bitmapScale: bitmapScale)
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
#endif // os(iOS) || os(watchOS) || os(tvOS)
