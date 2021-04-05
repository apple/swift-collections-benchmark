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

public struct HTMLDocumentRenderer: DocumentRenderer {
  internal let _style: DocumentStyle
  internal let _lang: String
  internal var _stack: [_Section] = []

  public init(title: String, style: DocumentStyle, lang: String) {
    _style = style
    _lang = lang
    _stack.append(_Section(title: title, collapsed: false))
  }

  internal enum _Item {
    case item(title: String, graphics: Graphics?, collapsed: Bool)
    case section(_Section)
  }

  internal struct _Section {
    let title: String
    let collapsed: Bool
    var contents: [_Item] = []
  }

  internal mutating func _add(_ item: _Item) {
    _stack[_stack.count - 1].contents.append(item)
  }

  public mutating func item(
    title: String,
    graphics: Graphics?,
    collapsed: Bool
  ) throws {
    _add(.item(title: title, graphics: graphics, collapsed: collapsed))
  }

  public mutating func beginSection(title: String, collapsed: Bool) throws {
    _stack.append(_Section(title: title, collapsed: collapsed))
  }

  public mutating func endSection() throws {
    precondition(_stack.count > 1, "Can't end a section that hasn't begun")
    let section = _stack.removeLast()
    _add(.section(section))
  }

  public func renderHTML() throws -> String {
    precondition(_stack.count == 1, "You must close all sections before generating data")
    let document = _stack[0]
    var xml = _XMLRenderer(docType: "html")
    xml.element(
      name: "html",
      attributes: [
        "xmlns": "http://www.w3.org/1999/xhtml",
        "lang": _lang,
      ]
    ) { xml in
      xml.element(name: "head") { xml in
        xml.emptyElement(
          name: "meta",
          attributes: [
            "http-equiv": "content-type",
            "content": "text/html; charset=utf-8",
          ])
        xml.element(name: "title", context: .text) { xml in
          xml.text(document.title)
        }
        xml.element(
          name: "style",
          attributes: ["type": "text/css"]
        ) { xml in
          xml.verbatimText("""
            body {
                font-family: -apple-system,Segoe UI,Helvetica,Arial,sans-serif,Apple Color Emoji,Segoe UI Emoji;
            }

            summary { outline-style: none; }

            details.section { margin-bottom: 6pt; }

            details.section > summary {
                font-weight: bold;
                margin-top: 6pt;
                margin-bottom: 6pt;
            }
            details.section > .details {
                margin-top: 6pt;
                margin-bottom: 12pt;
                margin-left: 2em;
            }

            details.item > summary {
                margin-top: 2pt;
                margin-bottom: 2pt;
            }
            details.item > .details {
                margin-top: 6pt;
                margin-bottom: 12pt;
                margin-left: 1em;
            }
            """)
        }
      }
      xml.element(name: "body") { xml in
        xml.element(name: "h1", context: .text) { xml in
          xml.text(document.title)
        }
        if _style == .collapsible {
          xml.element(name: "p", context: .text) { xml in
            xml.text("Click to expand individual items below.")
          }
          for item in document.contents {
            _render(item, into: &xml)
          }
        } else {
          xml.element(name: "ol") { xml in
            for item in document.contents {
              _render(item, into: &xml)
            }
          }
        }
      }
    }
    return xml.render()
  }

  internal func _render(_ item: _Item, into xml: inout _XMLRenderer) {
    switch _style {
    case .collapsible:
      switch item {
      case let .item(title: title, graphics: graphics, collapsed: collapsed):
        let attr: _XMLRenderer.Attributes = [
          "class": "item",
          "open": collapsed ? nil : ""
        ]
        xml.element(name: "details", attributes: attr) { xml in
          xml.element(name: "summary", context: .text) { xml in
            xml.text(title)
          }
          if let graphics = graphics {
            xml.element(name: "div", attributes: ["class": "details"]) { xml in
              graphics._renderSVG(into: &xml)
            }
          }
        }
      case let .section(section):
        let attr: _XMLRenderer.Attributes = [
          "class": "section",
          "open": section.collapsed ? nil : ""
        ]
        xml.element(name: "details", attributes: attr) { xml in
          xml.element(name: "summary", context: .text) { xml in
            xml.text(section.title)
          }
          xml.element(name: "div", attributes: ["class": "details"]) { xml in
            for item in section.contents {
              _render(item, into: &xml)
            }
          }
        }
      }
    case .flat:
      switch item {
      case let .item(title: title, graphics: graphics, collapsed: _):
        xml.element(name: "li") { xml in
          xml.element(name: "p", context: .text) { xml in
            xml.text(title)
          }
          if let graphics = graphics {
            graphics._renderSVG(into: &xml)
          }
        }
      case let .section(section):
        xml.element(name: "li", context: .text) { xml in
          xml.text(section.title)
        }
        xml.element(name: "ol") { xml in
          for item in section.contents {
            _render(item, into: &xml)
          }
        }
      }
    }
  }

  public func render() throws -> Data {
    try renderHTML().data(using: .utf8)!
  }
}
