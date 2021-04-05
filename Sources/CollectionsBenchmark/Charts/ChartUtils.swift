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

internal func _min<C: Comparable>(_ a: C?, _ b: C?) -> C? {
  switch (a, b) {
  case let (a?, b?): return Swift.min(a, b)
  case let (a?, nil): return a
  case let (nil, b?): return b
  case (nil, nil): return nil
  }
}

internal func _max<C: Comparable>(_ a: C?, _ b: C?) -> C? {
  switch (a, b) {
  case let (a?, b?): return Swift.max(a, b)
  case let (a?, nil): return a
  case let (nil, b?): return b
  case (nil, nil): return nil
  }
}

internal func _union<Bounds>(
  _ left: ClosedRange<Bounds>?,
  _ right: ClosedRange<Bounds>?
) -> ClosedRange<Bounds>? {
  switch (left, right) {
  case let (nil, right):
    return right
  case let (left?, nil):
    return left
  case let (left?, right?):
    let upper = Swift.max(left.upperBound, right.upperBound)
    let lower = Swift.min(left.lowerBound, right.lowerBound)
    return .init(uncheckedBounds: (lower, upper))
  }
}

internal struct _RepeatingIterator<C: Collection> {
  typealias Element = C.Element
  
  let base: C
  var index: C.Index
  
  init(_ base: C) {
    self.base = base
    self.index = base.startIndex
    
    precondition(!base.isEmpty)
  }
  
  mutating func next() -> C.Element {
    defer { base.formIndex(after: &index) }
    if index == base.endIndex { index = base.startIndex }
    return base[index]
  }
}

extension Collection {
  internal func _repeating() -> _RepeatingIterator<Self> {
    return _RepeatingIterator(self)
  }
}

@inline(__always)
private func _cache<Key, Value>(
  _ key: Key,
  _ value: inout Value?,
  _ body: (Key) throws -> Value
) rethrows -> Value {
  if let value = value { return value }
  let v = try body(key)
  value = v
  return v
}

extension Dictionary {
  internal mutating func _cachedValue(
    for key: Key,
    _ body: (Key) throws -> Value
  ) rethrows -> Value {
    try _cache(key, &self[key], body)
  }
}
