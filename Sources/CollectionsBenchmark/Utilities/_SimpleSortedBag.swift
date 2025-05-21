//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A watered down, inefficient `SortedBag` implementation, used here to
/// as a stand-in for a proper implementation in `swift-collections`.
///
/// This uses a flat array as storage, so it gets ludicrously slow after
/// a couple thousand elements.
struct _SimpleSortedBag<Element: Comparable> {
  var _elements: [Element]

  init() {
    _elements = []
  }

  init<S: Sequence>(
    _ elements: S
  ) where S.Element == Element {
    _elements = Array(elements)
    _elements.sort()
  }
}

extension _SimpleSortedBag: Sendable where Element: Sendable {}

extension _SimpleSortedBag: ExpressibleByArrayLiteral {
  init(arrayLiteral elements: Element...) {
    self.init(elements)
  }
}

extension _SimpleSortedBag: RandomAccessCollection {
  typealias Index = Int
  typealias Indices = Range<Int>

  var startIndex: Index { _elements.startIndex }
  var endIndex: Index { _elements.endIndex }

  subscript(position: Index) -> Element {
    _elements[position]
  }

  func _customContainsEquatableElement(
    _ element: Element
  ) -> Bool? {
    _elements._binarySearchStart(element).found
  }

  func _customIndexOfEquatableElement(_ element: Element) -> Index?? {
    let (found, index) = _elements._binarySearchStart(element)
    return (found ? .some(index) : .some(nil))
  }

  func _customLastIndexOfEquatableElement(_ element: Element) -> Index?? {
    let index = _elements._binarySearchEnd(element)
    let found = index > 0 && _elements[index - 1] == element
    return (found ? .some(index - 1) : .some(nil))
  }
}

extension _SimpleSortedBag: Equatable {
  static func ==(left: Self, right: Self) -> Bool {
    left._elements == right._elements
  }
}

extension _SimpleSortedBag {
  @discardableResult
  mutating func insert(_ item: Element) -> Index {
    let index = _elements._binarySearchEnd(item)
    _elements.insert(item, at: index)
    return index
  }

  mutating func insert<S: Sequence>(
    contentsOf items: S
  ) where S.Element == Element {
    _elements.append(contentsOf: items)
    _elements.sort()
  }
}
