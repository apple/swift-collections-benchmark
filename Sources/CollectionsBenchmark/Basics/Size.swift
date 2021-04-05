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

import ArgumentParser

public struct Size: RawRepresentable {
  public typealias RawValue = Int
  
  public let rawValue: RawValue
  
  public init(_ value: RawValue) {
    self.rawValue = value
  }
  
  public init(rawValue value: RawValue) {
    self.rawValue = value
  }
}

extension Size: CustomStringConvertible {
  public var description: String {
    let v = Double(rawValue)
    return
      rawValue >= 1 << 40 ? String(format: "%.3gT", v * 0x1p-40)
      : rawValue >= 1 << 30 ? String(format: "%.3gG", v * 0x1p-30)
      : rawValue >= 1 << 20 ? String(format: "%.3gM", v * 0x1p-20)
      : rawValue >= 1024 ? String(format: "%.3gk", v * 0x1p-10)
      : "\(rawValue)"
  }
}

extension Size: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: RawValue) {
    self.init(value)
  }
}

extension Size: CodingKey {
  public init?(intValue: Int) {
    self.init(intValue)
  }
  
  public init?(stringValue: String) {
    guard let size = Size(stringValue) else { return nil }
    self = size
  }
  
  public var intValue: Int? { rawValue }
  public var stringValue: String { "\(rawValue)" }
}

extension Size: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let string = try container.decode(String.self)
    guard let value = Int(string, radix: 10) else {
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Not an integer: '\(string)'")
    }
    self.rawValue = value
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode("\(rawValue)")
  }
}

extension Size {
  public init?(_ string: String) {
    var position = string.startIndex
    
    // Parse digits
    loop: while position != string.endIndex {
      switch string[position] {
      case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
        string.formIndex(after: &position)
      default:
        break loop
      }
    }
    let digits = string.prefix(upTo: position)
    guard let value = RawValue(digits, radix: 10) else { return nil }
    
    // Parse optional suffix
    let suffix = string.suffix(from: position)
    switch suffix {
    case "": self.rawValue = value
    case "k", "K": self.rawValue = value << 10
    case "m", "M": self.rawValue = value << 20
    case "g", "G": self.rawValue = value << 30
    case "t", "T": self.rawValue = value << 40
    default: return nil
    }
  }
}

extension Size: Equatable {}
extension Size: Hashable {}
extension Size: Comparable {
  public static func < (left: Self, right: Self) -> Bool {
    left.rawValue < right.rawValue
  }
}

extension Size: ExpressibleByArgument {
  public init?(argument: String) {
    self.init(argument)
  }
}

extension FixedWidthInteger {
  var _minimumBitWidth: Int {
    Self.bitWidth - self.leadingZeroBitCount
  }
}

extension Size {
  private static func _checkSignificantDigits(_ digits: Int) {
    precondition(digits >= 1 && digits <= RawValue.bitWidth)
  }
  
  public func roundedDown(significantDigits digits: Int) -> Size {
    Self._checkSignificantDigits(digits)
    let mask: RawValue = (0 &- 1) << (rawValue._minimumBitWidth - digits)
    return Size(rawValue & mask)
  }
  
  public func nextUp(significantDigits digits: Int) -> Size {
    Self._checkSignificantDigits(digits)
    
    let shift = rawValue._minimumBitWidth - digits
    let mask: RawValue = (0 &- 1) << shift
    guard shift >= 0 else {
      return Size(rawValue + 1)
    }
    return Size((rawValue + (1 << shift)) & mask)
  }
  
  public static func sizes(
    for range: ClosedRange<Size>,
    significantDigits digits: Int
  ) -> [Size] {
    _checkSignificantDigits(digits)
    var result: [Size] = []
    var value = range.lowerBound.roundedDown(significantDigits: digits)
    while value < range.lowerBound {
      value = value.nextUp(significantDigits: digits)
    }
    while value <= range.upperBound {
      result.append(value)
      value = value.nextUp(significantDigits: digits)
    }
    return result
  }
}
