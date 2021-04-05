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

extension RandomAccessCollection where Element: Comparable {
  /// Assuming `self` is a sorted collection, find an index where
  /// `element` can be inserted such that the collection remains sorted.
  /// If the element is already present in the collection, the returned index
  /// is to its first occurence.
  internal func _binarySearchStart(
    _ element: Element
  ) -> (found: Bool, index: Index) {
    var start = startIndex
    var end = endIndex
    while start < end {
      let diff = self.distance(from: start, to: end)
      let mid = self.index(start, offsetBy: diff / 2)
      if self[mid] < element {
        start = self.index(after: mid)
      } else {
        end = mid
      }
    }
    return (found: start < endIndex && self[start] == element, index: start)
  }

  /// Assuming `self` is a sorted collection, find an index where
  /// `element` can be inserted such that the collection remains sorted.
  /// If the element is already present in the collection, the returned index
  /// is to the item after its last occurence.
  internal func _binarySearchEnd(
    _ element: Element
  ) -> Index {
    var start = startIndex
    var end = endIndex
    while start < end {
      let diff = self.distance(from: start, to: end)
      let mid = self.index(start, offsetBy: diff / 2)
      if self[mid] <= element {
        start = self.index(after: mid)
      } else {
        end = mid
      }
    }
    return start
  }
}

extension RandomAccessCollection where Element: Comparable {
  /// Assuming `self` is a collection sorted by `extract`, find the first
  /// index whose element's extracted value matches `needle`.
  /// If there are no such elements, return the index of the first item
  /// whose extraction is greater than needle (or `endIndex`).
  internal func _binarySearchStart<T: Comparable>(
    _ needle: T,
    by extract: (Element) -> T
  ) -> (found: Bool, index: Index) {
    var start = startIndex
    var end = endIndex
    while start < end {
      let diff = self.distance(from: start, to: end)
      let mid = self.index(start, offsetBy: diff / 2)
      if extract(self[mid]) < needle {
        start = self.index(after: mid)
      } else {
        end = mid
      }
    }
    return (found: start < endIndex && extract(self[start]) == needle,
            index: start)
  }

  /// Assuming `self` is a collection sorted by `extract`, return the index of
  /// the first item whose extraction is greater than needle (or `endIndex`).
  internal func _binarySearchEnd<T: Comparable>(
    _ needle: T,
    by extract: (Element) -> T
  ) -> Index {
    var start = startIndex
    var end = endIndex
    while start < end {
      let diff = self.distance(from: start, to: end)
      let mid = self.index(start, offsetBy: diff / 2)
      if extract(self[mid]) <= needle {
        start = self.index(after: mid)
      } else {
        end = mid
      }
    }
    return start
  }
}
