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

/// A watered down, inefficient `OrderedDictionary` implementation, used here to
/// get rid of the dependency on `swift-collections`, thus allowing that package
/// to define its own benchmarks.
struct _SimpleOrderedDictionary<Key: Hashable, Value> {
  var _elements: _SimpleOrderedSet<_Item>

  init() {
    self._elements = []
  }

  init<S: Sequence>(
    uniqueKeysWithValues elements: S
  ) where S.Element == (Key, Value) {
    self._elements = []
    for item in elements {
      let inserted = _elements.append(_Item(item.0, item.1)).inserted
      precondition(inserted, "Duplicate key '\(item.0)'")
    }
  }
}

extension _SimpleOrderedDictionary: Sendable
where Key: Sendable, Value: Sendable {}

extension _SimpleOrderedDictionary {
  struct _Item: Hashable {
    var key: Key
    var value: Value?

    init(_ key: Key, _ value: Value? = nil) {
      self.key = key
      self.value = value
    }

    static func ==(left: Self, right: Self) -> Bool {
      left.key == right.key
    }

    func hash(into hasher: inout Hasher) {
      hasher.combine(key)
    }
  }
}

extension _SimpleOrderedDictionary._Item: Sendable
where Key: Sendable, Value: Sendable {}

extension _SimpleOrderedDictionary {
  func _checkInvariants() {
    for item in _elements {
      precondition(item.value != nil)
    }
  }
}

extension _SimpleOrderedDictionary: ExpressibleByDictionaryLiteral {
  init(dictionaryLiteral elements: (Key, Value)...) {
    self.init(uniqueKeysWithValues: elements)
  }
}

extension _SimpleOrderedDictionary {
  mutating func _beginUpdate(_ key: Key) -> (value: Value?, index: Int) {
    let (item, index) = _elements._update(with: _Item(key))
    if let item = item {
      return (item.value!, index)
    }
    return (nil, index)
  }

  mutating func _commitUpdate(
    _ key: Key,
    _ item: (value: Value?, index: Int)
  ) {
    if let value = item.value {
      // Update, insert
      _elements._update(with: _Item(key, value), at: item.index)
    } else {
      // Noop, removal
      _elements.remove(_Item(key))
    }
  }

  subscript(key: Key) -> Value? {
    get {
      guard let index = _elements.firstIndex(of: _Item(key)) else { return nil }
      return _elements[index].value!
    }
    _modify {
      var item = _beginUpdate(key)
      defer {
        _commitUpdate(key, item)
      }
      yield &item.value
    }
  }

  subscript(key: Key, default defaultValue: @autoclosure () -> Value) -> Value {
    get {
      self[key] ?? defaultValue()
    }
    _modify {
      var value: Value
      let index: Int

      do {
        let item: _Item?
        (item, index) = _elements._update(with: _Item(key))
        value = item?.value ?? defaultValue()
      }

      defer {
        _elements._update(with: _Item(key, value), at: index)
      }

      yield &value
    }
  }

  mutating func updateValue(_ value: Value, forKey key: Key) -> Value? {
    guard let old = _elements.update(with: _Item(key, value)) else {
      return nil
    }
    return old.value!
  }
}

extension _SimpleOrderedDictionary: RandomAccessCollection {
  typealias Element = (key: Key, value: Value)

  struct Index: Hashable, Comparable {
    var offset: Int

    init(_ offset: Int) { self.offset = offset }

    static func < (left: Self, right: Self) -> Bool {
      left.offset < right.offset
    }
  }

  var startIndex: Index { Index(_elements.startIndex) }
  var endIndex: Index { Index(_elements.endIndex) }

  func index(before i: Index) -> Index {
    Index(i.offset - 1)
  }

  func index(after i: Index) -> Index {
    Index(i.offset + 1)
  }

  func index(_ i: Index, offsetBy distance: Int) -> Index {
    Index(i.offset + distance)
  }

  func distance(from start: Index, to end: Index) -> Int {
    end.offset - start.offset
  }

  subscript(position: Index) -> Element {
    let item = _elements[position.offset]
    return (item.key, item.value!)
  }
}

extension _SimpleOrderedDictionary {
  mutating func removeAll(
    where shouldBeRemoved: (Element) throws -> Bool
  ) rethrows {
    var result = Self()
    for item in self {
      if try shouldBeRemoved(item) { continue }
      result[item.key] = item.value
    }
    self = result
  }
}
