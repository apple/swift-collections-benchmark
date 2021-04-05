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

/// A watered down, inefficient `SortedDictionary` implementation, used here to
/// as a stand-in for a proper implementation in `swift-collections`.
///
/// This uses a flat array as storage, so it gets ludicrously slow after
/// a couple thousand elements.
struct _SimpleSortedDictionary<Key: Comparable, Value> {
  var _elements: [_Item]

  init() {
    _elements = []
  }
}

extension _SimpleSortedDictionary {
  struct _Item: Comparable {
    var key: Key
    var value: Value

    init(_ key: Key, _ value: Value) {
      self.key = key
      self.value = value
    }

    var element: Element { (key, value) }

    static func ==(left: Self, right: Self) -> Bool {
      left.key == right.key
    }
    static func <(left: Self, right: Self) -> Bool {
      left.key < right.key
    }
  }
}

extension _SimpleSortedDictionary {
  init<S: Sequence>(
    uniqueKeysWithValues elements: S
  ) where S.Element == Element {
    _elements = elements.map { _Item($0.key, $0.value) }
    _elements.sort()
    var last: Key? = nil
    for item in _elements {
      guard item.key != last else {
        preconditionFailure("Duplicate key '\(item.key)")
      }
      last = item.key
    }
  }

  init<S: Sequence>(
    _ keysAndValues: S,
    uniquingKeysWith combine: (Value, Value) throws -> Value
  ) rethrows where S.Element == (Key, Value) {
    self._elements = []

    var elements = keysAndValues.map { _Item($0.0, $0.1) }
    guard !elements.isEmpty else { return }
    elements.sort()
    elements.reverse()

    var next = elements.removeLast()
    while let item = elements.popLast() {
      if item.key == next.key {
        next.value = try combine(next.value, item.value)
      } else {
        _elements.append(next)
        next = item
      }
    }
    _elements.append(next)
  }
}

extension _SimpleSortedDictionary: ExpressibleByDictionaryLiteral {
  init(dictionaryLiteral elements: (Key, Value)...) {
    self.init(uniqueKeysWithValues: elements)
  }
}

extension _SimpleSortedDictionary {
  func _checkInvariants() {
    var last: Key? = nil
    for item in _elements {
      precondition(last == nil || last! < item.key)
      last = item.key
    }
  }
}

extension _SimpleSortedDictionary {
  subscript(key: Key) -> Value? {
    get {
      let (found, index) = _elements._binarySearchStart(key, by: { $0.key })
      return (found ? _elements[index].value : nil)
    }
    _modify {
      let (found, index) = _elements._binarySearchStart(key, by: { $0.key })
      var value: Value?
      if found {
        _elements.swapAt(index, _elements.count - 1)
        value = _elements.removeLast().value
      }
      defer {
        switch (found, value) {
        case (true, let value?):
          // Update
          _elements.append(_Item(key, value))
          _elements.swapAt(index, _elements.count - 1)
        case (false, let value?):
          // Insert
          _elements.insert(_Item(key, value), at: index)
        case (true, nil):
          // Remove
          if index < _elements.count {
            let item = _elements.remove(at: index)
            _elements.append(item)
          }
        case (false, nil):
          // Noop
          break
        }
      }
      yield &value
    }
  }

  subscript(
    key: Key,
    default defaultValue: @autoclosure () -> Value
  ) -> Value {
    get {
      self[key] ?? defaultValue()
    }
    _modify {
      let (found, index) = _elements._binarySearchStart(key, by: { $0.key })
      if !found {
        _elements.insert(_Item(key, defaultValue()), at: index)
      }
      yield &_elements[index].value
    }
  }

  mutating func updateValue(
    _ value: Value,
    forKey key: Key
  ) -> Value? {
    let (found, index) = _elements._binarySearchStart(key, by: { $0.key })
    if found {
      let old = _elements[index].value
      _elements[index].value = value
      return old
    }
    _elements.insert(_Item(key, value), at: index)
    return nil
  }
}

extension _SimpleSortedDictionary: RandomAccessCollection {
  typealias Element = (key: Key, value: Value)

  struct Index: Comparable {
    var offset: Int

    init(_ offset: Int) { self.offset = offset }

    static func == (left: Self, right: Self) -> Bool {
      left.offset == right.offset
    }

    static func < (left: Self, right: Self) -> Bool {
      left.offset < right.offset
    }
  }

  var startIndex: Index { Index(_elements.startIndex) }
  var endIndex: Index { Index(_elements.endIndex) }

  func index(after i: Index) -> Index {
    Index(i.offset + 1)
  }

  func index(before i: Index) -> Index {
    Index(i.offset - 1)
  }

  func index(_ i: Index, offsetBy distance: Int) -> Index {
    Index(i.offset + distance)
  }

  func distance(from start: Index, to end: Index) -> Int {
    end.offset - start.offset
  }

  subscript(position: Index) -> Element {
    let item = _elements[position.offset]
    return (item.key, item.value)
  }
}

extension _SimpleSortedDictionary {
  mutating func removeAll(
    where shouldBeRemoved: (Element) throws -> Bool
  ) rethrows {
    try _elements.removeAll { item in
      try shouldBeRemoved(item.element)
    }
  }
}
