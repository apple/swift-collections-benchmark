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

import Foundation
import ArgumentParser

public struct Time: Sendable {
  public let duration: Duration

  public init(_ duration: Duration) {
    self.duration = duration
  }
}

extension Time {
  public static let second = Time(.seconds(1))
  public static let millisecond = Time(.milliseconds(1))
  public static let microsecond = Time(.microseconds(1))
  public static let nanosecond = Time(.nanoseconds(1))
  public static let picosecond = Time(.init(_attoseconds: 1_000_000))
  public static let femtosecond = Time(.init(_attoseconds: 1_000))
  public static let attosecond = Time(.init(_attoseconds: 1))
  public static let zero = Time(.zero)
}

extension Time {
  public static func since(_ start: Tick) -> Time {
    Tick.now.elapsedTime(since: start)
  }

  public static var eternity: Time { Time(Duration(_high: .max, low: .max)) }

  public static func seconds(_ seconds: Double) -> Time {
    Time(.seconds(seconds))
  }

  public var seconds: Double {
    duration._seconds
  }
}

extension Time: RawRepresentable {
  public var rawValue: TimeInterval { seconds }

  public init(rawValue: TimeInterval) {
    self.duration = .seconds(rawValue)
  }
}

extension Time: Equatable {
  public static func == (left: Self, right: Self) -> Bool {
    return left.duration == right.duration
  }
}

extension Time: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(duration)
  }
}

extension Time: Comparable {
  public static func < (left: Self, right: Self) -> Bool {
    return left.duration < right.duration
  }
}

extension Time: CustomStringConvertible {
  public var description: String {
    if self.duration == .zero { return "0" }
    if self < .attosecond { return String(format: "%.3gas", seconds) }
    if self < .picosecond { return String(format: "%.3gfs", seconds * 1e15) }
    if self < .nanosecond  { return String(format: "%.3gps", seconds * 1e12) }
    if self < .microsecond { return String(format: "%.3gns", seconds * 1e9) }
    if self < .millisecond { return String(format: "%.3gµs", seconds * 1e6) }
    if self < .second      { return String(format: "%.3gms", seconds * 1e3) }
    if self.duration < .seconds(1000) { return String(format: "%.3gs", seconds) }
    return String(format: "%gs", seconds.rounded())
  }
  
  public var typesetDescription: String {
    let spc = "\u{200A}"
    if self.seconds == 0 { return "0\(spc)s" }
    if self < .femtosecond { return String(format: "%.3g\(spc)as", seconds * 1e18) }
    if self < .picosecond { return String(format: "%.3g\(spc)fs", seconds * 1e15) }
    if self < .nanosecond  { return String(format: "%.3g\(spc)ps", seconds * 1e12) }
    if self < .microsecond { return String(format: "%.3g\(spc)ns", seconds * 1e9) }
    if self < .millisecond { return String(format: "%.3g\(spc)µs", seconds * 1e6) }
    if self < .second      { return String(format: "%.3g\(spc)ms", seconds * 1e3) }
    if self.seconds < 1000 { return String(format: "%.3g\(spc)s", seconds) }
    return String(format: "%g\(spc)s", seconds.rounded())
  }
}

extension Time: Codable {
  public init(from decoder: Decoder) throws {
    do {
      self.duration = try Duration(from: decoder)
    } catch DecodingError.typeMismatch {
      self.duration = .seconds(try TimeInterval(from: decoder))
    }
  }
  
  public func encode(to encoder: Encoder) throws {
    do {
      try self.duration.encode(to: encoder)
    } catch EncodingError.invalidValue {
      try self.seconds.encode(to: encoder)
    }
  }
}

extension Time: ExpressibleByArgument {
  public init?(argument: String) {
    self.init(argument)
  }
}

extension Time {
  private static let _scaleFromSuffix: [String: Time] = [
    "": .second,
    "s": .second,
    "ms": .millisecond,
    "µs": .microsecond,
    "us": .microsecond,
    "ns": .nanosecond,
    "ps": .picosecond,
    "fs": .femtosecond,
    "as": .attosecond,
  ]
  
  private static let _floatingPointCharacterSet = CharacterSet(charactersIn: "+-0123456789.e")
  
  public init?(_ description: String) {
    var description = description.trimmingCharacters(in: .whitespacesAndNewlines)
    description = description.lowercased()
    if let i = description.rangeOfCharacter(from: Time._floatingPointCharacterSet.inverted) {
      let number = description.prefix(upTo: i.lowerBound)
      let suffix = description.suffix(from: i.lowerBound)
      guard let value = Double(number) else { return nil }
      guard let scale = Time._scaleFromSuffix[String(suffix)] else { return nil }
      self = .seconds(value * scale.seconds)
    }
    else {
      guard let value = Double(description) else { return nil }
      self = .seconds(value)
    }
  }
}

extension Time {
  public func amortized(over size: Size) -> Time {
    Time(duration / size.rawValue)
  }
}

extension Time {
  internal func _orIfZero(_ time: Time) -> Time {
    self > .zero ? self : time
  }
}
