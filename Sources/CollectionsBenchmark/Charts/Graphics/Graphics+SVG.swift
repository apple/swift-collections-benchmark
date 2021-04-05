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

extension Color {
  func _svgString() -> String {
    var r = "#"
    r += Self._hexstring(for: red)
    r += Self._hexstring(for: green)
    r += Self._hexstring(for: blue)
    return r
  }
}

extension BinaryFloatingPoint {
  /// A short string representation of `self`, with reduced precision.
  ///
  /// Using this in SVG files reduces file size by ~50% without noticeably
  /// affecting results.
  fileprivate var s: String { String(format: "%.5g", Double(self)) }
}

extension Path {
  func _svgString() -> String {
    switch self {
    case let .line(from: start, to: end):
      return "M \(start.x.s) \(start.y.s) L \(end.x.s) \(end.y.s)"
    case let .rect(rect):
      return """
         M \(rect.minX.s) \(rect.minY.s) \
         L \(rect.minX.s) \(rect.maxY.s) \
         L \(rect.maxX.s) \(rect.maxY.s) \
         L \(rect.maxX.s) \(rect.minY.s) \
         z
         """
    case let .lines(points):
      var r = ""
      for i in points.indices {
        r += i == 0 ? "M" : "L"
        r += " \(points[i].x.s) \(points[i].y.s)"
      }
      return r
    }
  }
}

extension Graphics {
  public func svgString() -> String {
    var xml = _XMLRenderer(
      docType: #"svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd""#)
    _renderSVG(into: &xml)
    return xml.render()
  }

  internal func _renderSVG(into xml: inout _XMLRenderer) {
    xml.element(
      name: "svg", context: .regular,
      attributes: [
        "width": "\(bounds.width)px",
        "height": "\(bounds.height)px",
        "viewBox":
          "\(bounds.minX) \(bounds.minY) \(bounds.width) \(bounds.height)",
        "xmlns": "http://www.w3.org/2000/svg",
        "xmlns:xlink": "http://www.w3.org/1999/xlink",
        "version": "1.1",
      ]) { xml in
      Self._renderSVG(elements, into: &xml)
    }
  }

  func htmlString() -> String {
    var xml = _XMLRenderer(docType: "html")
    xml.element(name: "html") { xml in
      xml.element(name: "head") { xml in
        xml.emptyElement(
          name: "meta",
          attributes: [
            "http-equiv": "content-type",
            "content": "text/html; charset=utf-8",
          ])
        xml.element(name: "title", context: .text) { xml in
          xml.text("Benchmark results")
        }
      }
      xml.element(name: "body") { xml in
        _renderSVG(into: &xml)
      }
    }
    return xml.render()
  }

  internal static func _renderSVG(
    _ elements: [Element],
    into xml: inout _XMLRenderer
  ) {
    for element in elements {
      switch element {
      case let .shape(shape):
        var attrs: _XMLRenderer.Attributes = [
          "d": shape.path._svgString(),
        ]
        if let fill = shape.fill {
          attrs += [
            "fill": fill._svgString(),
            "fill-opacity": "\(fill.srgbComponents.alpha)",
          ]
        } else {
          attrs += ["fill":  "none"]
        }
        if let stroke = shape.stroke {
          attrs += [
            "stroke-width": "\(stroke.width.s)",
            "stroke": stroke.color._svgString(),
            "stroke-opacity": "\(stroke.color.srgbComponents.alpha.s)",
            "stroke-linecap": "\(stroke.capStyle)",
            "stroke-linejoin": "\(stroke.joinStyle)",
          ]
          if let dash = stroke.dash {
            attrs += [
              "stroke-dasharray": dash.style.map {"\($0.s)"}.joined(separator: " "),
              "stroke-dashoffset": "\(dash.phase.s)",
            ]
          }
        } else {
          attrs += ["stroke": "none"]
        }
        xml.emptyElement(name: "path", attributes: attrs)
      case let .text(text):
        func renderText(into xml: inout _XMLRenderer) {
          xml.element(
            name: "text",
            context: .text,
            attributes: [
              "x": "\(text.boundingBox.minX.s)",
              "y": "\((text.boundingBox.maxY - text.descender).s)",
              "font-family": text.style.font.family,
              "font-size": "\(text.style.font.size.s)",
              "font-weight": text.style.font.isBold ? "bold" : "normal",
              "font-style": text.style.font.isItalic ? "italic" : "normal",
              "fill": text.style.color._svgString(),
              "fill-opacity": "\(text.style.color.srgbComponents.alpha.s)"
            ]) { xml in
            xml.text(text.string)
          }
        }
        if let target = text.linkTarget {
          xml.element(
            name: "a",
            context: .text,
            attributes: [
              "xlink:href": target.relativeString,
            ]
          ) { xml in
            renderText(into: &xml)
          }
        } else {
          renderText(into: &xml)
        }
      case let .group(clippingRect: clippingRect, elements):
        let id = xml.nextID(for: "clip")
        xml.element(
          name: "clipPath",
          attributes: ["id": "\(id)"]
        ) { xml in
          xml.emptyElement(
            name: "path",
            attributes: [
              "d": Path.rect(clippingRect)._svgString()
            ])
        }
        xml.element(
          name: "g",
          attributes: ["clip-path": "url(#\(id))"]
        ) { xml in
          Self._renderSVG(elements, into: &xml)
        }
      }
    }
  }
}
