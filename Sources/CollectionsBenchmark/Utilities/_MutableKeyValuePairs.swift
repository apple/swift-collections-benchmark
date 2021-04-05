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

/// A version of the standard `KeyValuePairs` type with an `append` function.
/// (A.k.a, what the standard `KeyValuePairs` should be.)
internal struct _MutableKeyValuePairs<Key, Value>: ExpressibleByDictionaryLiteral {
  var elements: [Element]

  init(dictionaryLiteral elements: (Key, Value)...) {
    self.elements = elements
  }
}

extension _MutableKeyValuePairs: RandomAccessCollection {
  typealias Element = (key: Key, value: Value)
  typealias Index = Int
  typealias Indices = Range<Int>
  typealias SubSequence = Slice<Self>

  var startIndex: Index { elements.startIndex }
  var endIndex: Index { elements.endIndex }
  subscript(index: Index) -> Element { elements[index] }
}

extension _MutableKeyValuePairs {
  mutating func append(_ key: Key, _ value: Value) {
    elements.append((key, value))
  }

  mutating func append<S: Sequence>(contentsOf other: S) where S.Element == Element {
    elements.append(contentsOf: other)
  }
}

func +=<Key, Value>(
  left: inout _MutableKeyValuePairs<Key, Value>,
  // Note: this is intentionally not generic over sequence -- otherwise
  // dictionary literals would default to `Dictionary`, breaking ordering
  // expectations, and potentially trapping on duplicate keys.
  right: _MutableKeyValuePairs<Key, Value>
) {
  left.append(contentsOf: right)
}
