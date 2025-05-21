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

public struct Tick: Sendable {
  typealias Clock = SuspendingClock

  internal let _value: SuspendingClock.Instant

  internal init(_value: SuspendingClock.Instant) {
    self._value = _value
  }

  public static var now: Tick {
    Tick(_value: SuspendingClock.now)
  }
  
  public static var resolution: Time {
    Time(Clock().minimumResolution)
  }

  public func elapsedTime(since start: Tick) -> Time {
    Time(start._value.duration(to: self._value))
  }
}
