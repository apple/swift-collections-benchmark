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

#if !USE_FOUNDATION_DATE && (os(macOS) || os(iOS) || os(watchOS) || os(tvOS))
import Foundation // For the side effect of reexporting Darwin/Glibc

public struct Tick {
  internal let _value: timespec

  internal init(_value: timespec) {
    self._value = _value
  }

  public static var now: Tick {
    guard #available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *) else {
      fatalError("Please enable USE_FOUNDATION_DATE")
    }
    var now = timespec()
    let r = clock_gettime(CLOCK_MONOTONIC_RAW, &now)
    precondition(r == 0, "clock_gettime failure")
    return Tick(_value: now)
  }
  
  public static var resolution: Time {
    guard #available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *) else {
      fatalError("Please enable USE_FOUNDATION_DATE")
    }
    var res = timespec()
    let r = clock_getres(CLOCK_MONOTONIC_RAW, &res)
    precondition(r == 0, "clock_getres failure")
    return Tick(_value: res).elapsedTime(since: Tick(_value: timespec(tv_sec: 0, tv_nsec: 0)))
  }

  public func elapsedTime(since start: Tick) -> Time {
    let s = Double(_value.tv_sec - start._value.tv_sec)
    let ns = Double(_value.tv_nsec - start._value.tv_nsec)
    return Time(s + ns / 1e9)
  }
}

#else

import Foundation

public struct Tick {
  internal let _value: Date

  internal init(_value: Date) {
    self._value = _value
  }

  public static var now: Tick {
    Tick(_value: Date())
  }

  public func elapsedTime(since start: Tick) -> Time {
    Time(Double(_value.timeIntervalSince(start._value)))
  }
  
  public static var resolution: Time {
    .nanosecond
  }
}
#endif
