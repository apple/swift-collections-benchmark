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

public struct Timer {
  internal var _expectNested: Bool? = nil
  public var elapsedTime: Time? = nil {
    didSet {
      precondition(_expectNested != false,
                   "Inconsistent timer use: Unexpected call to Timer.elapsedTime setter")
    }
  }
  
  public init() {}
  
  internal init(_expectNested: Bool?) {
    self._expectNested = _expectNested
  }
  
  internal static func _measureFirst(
    _ body: (inout Timer) -> Void
  ) -> (elapsedTime: Time, hasNestedMeasurement: Bool) {
    var timer = Timer(_expectNested: nil)
    let start = Tick.now
    body(&timer)
    let end = Tick.now
    let elapsed = timer.elapsedTime ?? end.elapsedTime(since: start)
    return (elapsedTime: elapsed._orIfZero(Tick.resolution),
            hasNestedMeasurement: timer.elapsedTime != nil)
  }

  internal static func _nestedMeasure(_ body: (inout Timer) -> Void) -> Time {
    var timer = Timer(_expectNested: true)
    body(&timer)
    guard let elapsed = timer.elapsedTime else {
      fatalError("Inconsistent timer use: Expected call to Timer.measure")
    }
    return elapsed._orIfZero(Tick.resolution)
  }
  
  internal static func _iteratingMeasure(
    iterations: Int,
    _ body: (inout Timer) -> Void
  ) -> Time {
    precondition(iterations > 0)
    var timer = Timer(_expectNested: false)
    let start = Tick.now
    for _ in 0 ..< iterations {
      body(&timer)
    }
    let end = Tick.now
    let elapsed = end.elapsedTime(since: start)._orIfZero(Tick.resolution)
    return Time(elapsed.seconds / Double(iterations))
  }
  
  @inline(never)
  public mutating func measure(_ body: () -> Void) {
    precondition(_expectNested != false,
                 "Inconsistent timer use: Unexpected call to Timer.measure")
    let start = Tick.now
    body()
    let end = Tick.now
    elapsedTime = end.elapsedTime(since: start)
    _expectNested = false
  }
}

