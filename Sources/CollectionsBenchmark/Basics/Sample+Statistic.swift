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

import ArgumentParser

extension Sample {
  public enum Statistic: Sendable, Hashable {
    case maximum
    case sigma(Int)
    case mean
    case minimum
    case none
  }
  
  public subscript(_ statistic: Statistic) -> Time? {
    switch statistic {
    case .maximum: return maximum
    case .sigma(let n):
      guard let sigma = standardDeviation else { return nil }
      return .seconds(mean!.seconds + Double(n) * sigma.seconds)
    case .mean: return mean
    case .minimum: return minimum
    case .none: return nil
    }
  }
}

extension Sample.Statistic: CustomStringConvertible {
  public var description: String {
    switch self {
    case .maximum: return "max"
    case .sigma(let n): return "\(n)sigma"
    case .mean: return "mean"
    case .minimum: return "min"
    case .none: return "none"
    }
  }

  public var typesetDescription: String? {
    switch self {
    case .maximum: return "max"
    case .sigma(let n): return "mean\u{205F}+\u{205F}\(n)stddev" // U+205F is medium math space (~4/18ems)
    case .mean: return "mean"
    case .minimum: return "min"
    case .none: return nil
    }
  }
}

extension Sample.Statistic: LosslessStringConvertible {
  public init?(_ description: String) {
    switch description {
    case "maximum", "max":
      self = .maximum
    case "mean":
      self = .mean
    case "minimum", "min":
      self = .minimum
    case _ where description.hasSuffix("sigma"):
      let number = description.dropLast(5)
      guard let n = Int(number, radix: 10) else { return nil }
      self = .sigma(n)
    case _ where description.hasSuffix("𝜎"):
      let number = description.dropLast(1)
      guard let n = Int(number, radix: 10) else { return nil }
      self = .sigma(n)
    case "none":
      self = .none
    default:
      return nil
    }
  }
}

extension Sample.Statistic: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let string = try container.decode(String.self)
    guard let statistic = Self(string) else {
      throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown statistic")
    }
    self = statistic
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode("\(self)")
  }
}

extension Sample.Statistic: ExpressibleByArgument {
  public init?(argument: String) {
    self.init(argument)
  }
}

extension Sample {
  public func discardingPercentile(above percentile: Double) -> Sample {
    let ordinalRank = Int((percentile / 100 * Double(count)).rounded(.up))
    guard ordinalRank < count else { return self }
    return Sample(times[..<Swift.max(ordinalRank, 0)])
  }
}
