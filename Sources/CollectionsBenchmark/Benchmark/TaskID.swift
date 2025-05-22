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

public struct TaskID: Sendable, Hashable {
  public var label: String {
    didSet {
      if let error = Self._validateLabel(label) {
        preconditionFailure("'\(label)': \(error)")
      }
    }
  }
  public var title: String {
    didSet {
      if let error = Self._validateTitle(title) {
        preconditionFailure("'\(title)': \(error)")
      }
    }
  }

  public init(_uncheckedlabel label: String, title: String) {
    self.label = label
    self.title = title
  }

  public init(label: String = "", title: String) {
    if let error = Self._validateTitle(title) {
      preconditionFailure("'\(title)': \(error)")
    }
    if let error = Self._validateLabel(label) {
      preconditionFailure("'\(label)': \(error)")
    }
    self.label = label
    self.title = title
  }
}

extension TaskID {
  internal static func _validateLabel(_ label: String) -> String? {
    guard !label.contains("[") else {
      return "Benchmark label must not contain '[' characters"
    }
    guard !label.contains("]") else {
      return "Benchmark label must not contain '[' characters"
    }
    guard !label.contains(where: { $0.isNewline }) else {
      return "Benchmark label must not contain multiple lines"
    }
    return nil
  }

  internal static func _validateTitle(_ title: String) -> String? {
    guard !title.isEmpty else {
      return "Benchmark task title must not be empty"
    }
    guard title.first!.isLetter else {
      return "Benchmark task title must begin with a letter"
    }
    guard !title.contains(where: { $0.isNewline }) else {
      return "Benchmark task title must not contain multiple lines"
    }
    return nil
  }
}


extension TaskID: CustomStringConvertible {
  public var description: String {
    if label.isEmpty { return title }
    return "[\(label)]\(title)"
  }
}

extension TaskID {
  public var typesetDescription: String {
    guard !label.isEmpty else { return title }
    return "\(label)∶ \(title)"
  }

  public init<S: StringProtocol>(from name: S) throws {
    if name.starts(with: "["), let i = name.firstIndex(of: "]") {
      self.label = String(name.dropFirst().prefix(upTo: i))
      self.title = String(name.suffix(from: name.index(after: i)))
    } else {
      self.label = ""
      self.title = String(name)
    }
    if let error = Self._validateLabel(label) {
      throw Benchmark.Error("Invalid task name '\(name)': \(error)")
    }
    if let error = Self._validateTitle(title) {
      throw Benchmark.Error("Invalid task name '\(name)': \(error)")
    }
  }
}

extension TaskID: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let value = try container.decode(String.self)
    do {
      let id = try Self(from: value)
      self = id
    } catch {
      let context = DecodingError.Context(
        codingPath: decoder.codingPath,
        debugDescription: error.localizedDescription)
      throw DecodingError.dataCorrupted(context)
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(description)
  }
}

extension TaskID: LosslessStringConvertible {
  public init?<S: StringProtocol>(_ description: S) {
    if description.starts(with: "["), let i = description.firstIndex(of: "]") {
      let label = String(description.dropFirst().prefix(upTo: i))
      let title = String(description.suffix(from: description.index(after: i)))
      guard Self._validateLabel(label) == nil else { return nil }
      guard Self._validateTitle(title) == nil else { return nil }
      self.label = label
      self.title = title
    } else {
      let title = String(description)
      guard Self._validateTitle(title) == nil else { return nil }
      self.label = ""
      self.title = title
    }
  }
}

extension TaskID: Comparable {
  public static func < (left: Self, right: Self) -> Bool {
    switch (left.label as NSString).localizedStandardCompare(right.label) {
    case .orderedAscending: return true
    case .orderedDescending: return false
    case .orderedSame:
      return (left.title as NSString).localizedStandardCompare(right.title) == .orderedAscending
    }
  }
}

extension TaskID: ExpressibleByArgument {
  public init?(argument: String) {
    self.init(argument)
  }
}
