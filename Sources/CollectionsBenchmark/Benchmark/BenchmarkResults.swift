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

import Foundation
import SystemPackage
import ArgumentParser

/// A value containing a set of benchmark results.
public struct BenchmarkResults {
  internal typealias _Results = _SimpleOrderedDictionary<TaskID, TaskResults>

  internal var _tasks: _Results = [:]

  public init() {}
}

extension BenchmarkResults: Codable {
  public enum CodingKey: String, Swift.CodingKey {
    case version
    case tasks
  }

  public init(from decoder: Decoder) throws {
    self.init()
    let container = try decoder.container(keyedBy: CodingKey.self)
    let version = try container.decode(Int.self, forKey: .version)
    guard version == 1 else {
      throw DecodingError.dataCorruptedError(
        forKey: .version, in: container,
        debugDescription: "Unsupported results version \(version)")
    }
    let results = try container.decode([TaskResults].self, forKey: .tasks)
    for result in results {
      let old = self._tasks.updateValue(result, forKey: result.taskID)
      guard old == nil else {
        throw DecodingError.dataCorruptedError(
          forKey: .tasks, in: container,
          debugDescription: "Duplicate task ID '\(result.taskID)'")
      }
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKey.self)
    try container.encode(1, forKey: .version)
    var resultsContainer = container.nestedUnkeyedContainer(forKey: .tasks)
    for item in _tasks {
      try resultsContainer.encode(item.value)
    }
  }
}

extension BenchmarkResults {
  public func contains(_ id: TaskID) -> Bool {
    _tasks[id] != nil
  }

  public func alltaskIDs() -> [TaskID] {
    _tasks.map { $0.key }
  }
}

extension BenchmarkResults {
  public var tasks: Tasks { Tasks(_tasks: _tasks) }

  public struct Tasks: RandomAccessCollection {
    public typealias Element = TaskResults
    public typealias Index = Int
    public typealias Indices = Range<Int>

    internal typealias _Base = _SimpleOrderedDictionary<TaskID, TaskResults>

    internal let _tasks: _Base

    internal init(_tasks: _Base) {
      self._tasks = _tasks
    }

    public var startIndex: Int { _tasks.startIndex.offset }
    public var endIndex: Int { _tasks.endIndex.offset }

    public subscript(position: Int) -> TaskResults {
      _tasks[_Base.Index(position)].value
    }
  }
}

extension BenchmarkResults {
  public mutating func add(_ results: TaskResults) {
    func update(_ value: inout TaskResults) {
      value.link = results.link
      value.add(results)
    }

    update(
      &self._tasks[
        results.taskID,
        default: TaskResults(id: results.taskID, link: results.link)
      ]
    )
  }

  public mutating func add(id: TaskID, size: Size, time: Time) {
    _tasks[id, default: TaskResults(id: id)].add(size: size, time: time)
  }

  public subscript(id id: TaskID, size size: Size) -> Sample {
    get {
      _tasks[id, default: TaskResults(id: id)][size]
    }
    _modify {
      yield &_tasks[id, default: TaskResults(id: id)][size]
    }
  }

  public subscript(id id: TaskID) -> TaskResults {
    get { _tasks[id] ?? TaskResults(id: id) }
    _modify {
      yield &_tasks[id, default: TaskResults(id: id)]
    }
  }
}

extension BenchmarkResults {
  public mutating func clear() {
    for id in alltaskIDs() {
      _tasks[id]!.clear()
    }
  }

  public mutating func remove(_ ids: [TaskID]) {
    for id in ids {
      _tasks[id] = nil
    }
  }

  public mutating func clear(sizes: [Size], from ids: [TaskID]) {
    for id in ids {
      guard _tasks[id] != nil else { continue }
      _tasks[id, default: TaskResults(id: id)].remove(sizes: sizes)
    }
  }
}

extension BenchmarkResults {
  /// Represents an output format for the command line interface.
  public enum OutputFormat:
    String, Codable, CustomStringConvertible,
    CaseIterable, ExpressibleByArgument
  {
    case pretty
    case compact

    public var description: String { rawValue }

    internal var _encoderFormatting: JSONEncoder.OutputFormatting {
      var result: JSONEncoder.OutputFormatting = []
      if #available(macOS 10.15, iOS 13, watchOS 6, tvOS 13.0, *) {
        result.insert(.withoutEscapingSlashes)
      }
      switch self {
      case .pretty:
        result.insert(.prettyPrinted)
        if #available(macOS 10.13, iOS 11, watchOS 4, tvOS 11.0, *) {
          result.insert(.sortedKeys)
        }
      case .compact:
        // No extras
        break
      }
      return result
    }
  }

  public func encoded(format: OutputFormat = .compact) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = format._encoderFormatting
    return try encoder.encode(self)
  }
}

extension BenchmarkResults {
  public static func load(from path: FilePath) throws -> BenchmarkResults {
    try self.load(from: URL(path))
  }

  public static func load(from url: URL) throws -> BenchmarkResults {
    let decoder = JSONDecoder()
    // Note: this fails when the path points to a special device like a
    // tty or a FIFO. This is fine as we're typically going to want to
    // replace the file later anyway.
    let data = try Data(contentsOf: url)
    return try decoder.decode(BenchmarkResults.self, from: data)
  }

  public func save(to path: FilePath, format: OutputFormat = .compact) throws {
    try save(to: URL(path), format: format)
  }

  public func save(to url: URL, format: OutputFormat = .compact) throws {
    let data = try self.encoded(format: format)
    try data.write(to: url, options: .atomic)
  }
}

