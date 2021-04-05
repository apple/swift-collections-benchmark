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

// A ridiculously simple XML renderer.

extension String {
  internal func _xmlEscaped() -> String {
    var r = ""
    for c in self {
      switch c {
      case "\"": r += "&quot;"
      case "'": r += "&apos;"
      case "<": r += "&lt;"
      case ">": r += "&gt;"
      case "&": r += "&amp;"
      default: r.append(c)
      }
    }
    return r
  }
}

struct _XMLRenderer {
  typealias Attributes = _MutableKeyValuePairs<String, String?>

  private var _text = "" //<?xml version=\"1.0\"?>\n"
  private var _stack: [_Element] = []

  private var _indent: String { String(repeating: "  ", count: _stack.count) }

  private var _context: _Context {
    guard let element = _stack.last else { return .regular }
    return element.context
  }

  private var _idCounters: [String: Int] = [:]

  init(docType: String?) {
    if let docType = docType {
      _text += "<!DOCTYPE \(docType)>\n"
    }
  }

  private func _attributeString(_ attributes: Attributes) -> String {
    var attr = ""
    for (key, value) in attributes {
      guard let value = value else { continue }
      attr += #" \#(key)="\#(value._xmlEscaped())""#
    }
    return attr
  }

  private mutating func _writeTag(
    kind: _TagKind,
    context: _Context = .regular,
    name: String,
    attributes: Attributes = [:]
  ) {
    let s = (kind == .close ? "/" : "")
    let e = (kind == .empty ? "/" : "")
    let tag = "<\(s)\(name)\(_attributeString(attributes))\(e)>"

    switch (kind, _context, context) {
    case (.open, .regular, _),
         (.empty, .regular, _),
         (.close, _, .regular):
      if !_text.hasSuffix("\n") { _text += "\n" }
      _text += _indent
    default:
      break
    }

    _text += tag

    switch (kind, _context, context) {
    case (.open, _, .regular),
         (.empty, .regular, _),
         (.close, .regular, _):
      _text += "\n"
    default:
      break
    }
  }

  internal mutating func emptyElement(
    name: String,
    attributes: Attributes = [:]
  ) {
    _writeTag(kind: .empty, name: name, attributes: attributes)
  }

  internal mutating func startTag(
    name: String,
    context: _Context = .regular,
    attributes: Attributes = [:]
  ) {
    _writeTag(kind: .open, context: context, name: name, attributes: attributes)
    _stack.append(_Element(name: name, context: context))
  }

  internal mutating func endTag(name: String) {
    guard let element = _stack.popLast() else {
      preconditionFailure("There are no open elements")
    }
    precondition(
      element.name == name,
      "Mismatching element name in close tag; expected '\(element.name)', actual '\(name)'")
    _writeTag(kind: .close, context: element.context, name: name)
  }

  internal mutating func element(
    name: String,
    context: _Context = .regular,
    attributes: Attributes = [:],
    body: (inout _XMLRenderer) -> Void
  ) {
    startTag(name: name, context: context, attributes: attributes)
    body(&self)
    endTag(name: name)
  }

  internal mutating func _text(_ text: String) {
    let lines = text.split(
      omittingEmptySubsequences: false,
      whereSeparator: { $0.isNewline })
    for (i, line) in lines.enumerated() {
      if _context == .regular || i > 0 {
        if !_text.hasSuffix("\n") { _text += "\n" }
        _text += _indent
      }
      _text += line
    }
  }

  internal mutating func text(_ text: String) {
    _text(text._xmlEscaped())
  }

  internal mutating func verbatimText(_ text: String) {
    _text(text)
  }

  internal mutating func nextID(for label: String) -> String {
    func mutate<T, R>(
      _ value: inout T,
      _ body: (inout T) throws -> R
    ) rethrows -> R {
      try body(&value)
    }
    return mutate(&_idCounters[label, default: 0]) { value in
      defer { value += 1}
      return "\(label)\(label.isEmpty ? "" : "-")\(value)"
    }
  }

  internal mutating func render() -> String {
    precondition(_stack.isEmpty, "Can't render text with open elements")
    if !_text.hasSuffix("\n") { _text += "\n" }
    return _text
  }
}

extension _XMLRenderer {
  internal enum _Context {
    case regular
    case text
  }

  private enum _TagKind {
    case open
    case close
    case empty
  }

  private struct _Element {
    var name: String
    var context: _Context
  }
}
