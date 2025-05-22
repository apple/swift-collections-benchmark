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

/// A watered down, inefficient `OrderedSet` implementation, used here to
/// get rid of the dependency on `swift-collections`, thus allowing that package
/// to define its own benchmarks.
struct _SimpleOrderedSet<Element: Hashable> {
  var _hashTable: Set<_Item>
  var _elements: [Element]

  init() {
    _hashTable = []
    _elements = []
  }

  init<S: Sequence>(_ elements: S) where S.Element == Element {
    _hashTable = []
    _elements = []
    for item in elements {
      self.append(item)
    }
  }
}

extension _SimpleOrderedSet: Sendable where Element: Sendable {}

extension _SimpleOrderedSet {
  struct _Item: Hashable {
    var value: Element
    var index: Int?

    init(_ value: Element, at index: Int? = nil) {
      self.value = value
      self.index = index
    }

    static func ==(left: Self, right: Self) -> Bool {
      left.value == right.value
    }

    func hash(into hasher: inout Hasher) {
      hasher.combine(value)
    }
  }
}

extension _SimpleOrderedSet._Item: Sendable where Element: Sendable {}

extension _SimpleOrderedSet {
  func _checkInvariants() {
    precondition(_elements.count == _hashTable.count)
    for i in _elements.indices {
      let si = _hashTable.firstIndex(of: _Item(_elements[i]))!
      precondition(_hashTable[si].index == i)
    }
  }
}

extension _SimpleOrderedSet: ExpressibleByArrayLiteral {
  init(arrayLiteral elements: Element...) {
    self.init(elements)
  }
}

extension _SimpleOrderedSet: RandomAccessCollection {
  typealias Index = Int
  typealias Indices = Range<Int>
  typealias SubSequence = Slice<Self>

  var startIndex: Int { _elements.startIndex }
  var endIndex: Int { _elements.endIndex }
  subscript(index: Int) -> Element { _elements[index] }

  func _customContainsEquatableElement(
    _ element: Element
  ) -> Bool? {
    _hashTable.contains(_Item(element))
  }

  func _customIndexOfEquatableElement(_ element: Element) -> Index?? {
    guard let index = _hashTable.firstIndex(of: _Item(element)) else {
      return .some(nil)
    }
    let item = _hashTable[index]
    return .some(item.index)
  }

  func _customLastIndexOfEquatableElement(_ element: Element) -> Index?? {
    _customIndexOfEquatableElement(element)
  }
}

extension _SimpleOrderedSet {
  var elements: [Element] { _elements }

  @discardableResult
  mutating func append(_ item: Element) -> (inserted: Bool, index: Int) {
    let (inserted, member) = _hashTable.insert(_Item(item, at: _elements.count))
    guard inserted else {
      return (false, member.index!)
    }
    _elements.append(item)
    return (true, _elements.count - 1)
  }

  @discardableResult
  mutating func update(with item: Element) -> Element? {
    _update(with: item).old
  }

  @discardableResult
  mutating func _update(with item: Element) -> (old: Element?, index: Index) {
    guard let setIndex = _hashTable.firstIndex(of: _Item(item)) else {
      append(item)
      return (nil, _elements.count - 1)
    }
    let old = _hashTable[setIndex]
    _elements[old.index!] = item
    return (old.value, old.index!)
  }

  @discardableResult
  mutating func _update(
    with item: Element,
    at index: Int
  ) -> Element {
    let old = _hashTable.update(with: _Item(item, at: index))
    precondition(old!.value == item)
    precondition(old!.index == index)

    let old2 = _elements[index]
    precondition(old2 == item)
    _elements[index] = item
    return old2
  }

  @discardableResult
  mutating func remove(_ item: Element) -> Element? {
    guard let old = _hashTable.remove(_Item(item)) else { return nil }
    let index = old.index!
    _elements.remove(at: index)
    for i in _elements.indices[index...] {
      _hashTable.update(with: _Item(_elements[i], at: i))
    }
    return old.value
  }

  func subtracting<S: Sequence>(_ other: S) -> Self where S.Element == Element {
    let discards = Set(other)
    var result = Self()
    for item in self {
      if discards.contains(item) { continue }
      result.append(item)
    }
    return result
  }

  mutating func formUnion<S: Sequence>(_ other: S) where S.Element == Element {
    for item in other {
      append(item)
    }
  }
}
