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

public struct Benchmark {
  public typealias TaskBody = (inout Timer) -> Void

  public let title: String
  internal var _tasks: _SimpleOrderedDictionary<String, AnyTask> = [:]
  internal var _inputGenerators: [_TypeBox: (Int) -> Any] = [:]
  private let _executionContext = _ExecutionContext.shared

  public var chartLibrary: ChartLibrary? = nil

  public init(title: String = "") {
    self.title = title
    registerInputGenerator(for: Int.self) { size in
      size
    }
    registerInputGenerator(for: [Int].self) { size in
      (0 ..< size).shuffled()
    }
    registerInputGenerator(for: ([Int], [Int]).self) { size in
      ((0 ..< size).shuffled(), (0 ..< size).shuffled())
    }
    registerInputGenerator(for: Insertions.self) { size in
      Insertions(count: size)
    }
  }

  /// A generator for a random array of nonnegative integers where the *i*th
  /// value is always less than or equal to *i*.
  ///
  /// This is useful for benchmarking random insertions.
  public struct Insertions {
    public let values: [Int]

    public init(count: Int) {
      var rng = SystemRandomNumberGenerator()
      self.init(count: count, using: &rng)
    }

    public init<R: RandomNumberGenerator>(
      count: Int,
      using generator: inout R
    ) {
      precondition(count > 0)
      self.values = (0 ..< count).map { i in
        Int.random(in: 0 ..< i + 1, using: &generator)
      }
    }
  }

  internal func _markAsExecuted() {
    _executionContext._hasExecuted = true
  }

  public func allTaskNames() -> [String] {
    _tasks.map { $0.key }
  }

  public func task(named name: String) -> AnyTask? {
    _tasks[name]
  }

  internal func _task(named name: String) throws -> AnyTask {
    guard let task = _tasks[name] else {
      throw Error("Task not found: '\(name)'")
    }
    return task
  }

  public mutating func registerInputGenerator<Input>(
    for type: Input.Type = Input.self,
    _ generator: @escaping (Int) -> Input
  ) {
    _inputGenerators[_TypeBox(Input.self)] = { size in generator(size) }
  }

  public mutating func add(_ task: AnyTask) {
    precondition(_inputGenerators[_TypeBox(task.inputType)] != nil,
                 "Unregistered input type '\(task.inputType)'")

    precondition(_tasks[task.title] == nil,
                 "Duplicate task title: '\(task.title)'")
    _tasks[task.title] = task
  }
}

extension Benchmark {
  public mutating func add<Input>(_ task: Task<Input>) {
    add(AnyTask(task))
  }

  public mutating func add<Input>(
    title: String,
    input: Input.Type,
    maxSize: Int? = nil,
    file: StaticString = #filePath,
    line: UInt = #line,
    body: @escaping (Input) -> Benchmark.TaskBody?
  ) {
    add(Task<Input>(title, maxSize: maxSize, file: file, line: line, body: body))
  }

  public mutating func addSimple<Input>(
    title: String,
    input: Input.Type,
    maxSize: Int? = nil,
    file: StaticString = #filePath,
    line: UInt = #line,
    body: @escaping (Input) -> Void
  ) {
    let task = Task<Input>(title, maxSize: maxSize, file: file, line: line) { input in
      return { timer in body(input) }
    }
    add(task)
  }
}

extension Benchmark {
  public var tasks: Tasks { Tasks(_tasks: _tasks) }

  public struct Tasks: RandomAccessCollection {
    public typealias Element = AnyTask
    public typealias Index = Int
    public typealias Indices = Range<Int>

    internal typealias _Base = _SimpleOrderedDictionary<String, AnyTask>

    internal let _tasks: _Base

    internal init(_tasks: _Base) {
      self._tasks = _tasks
    }

    public var startIndex: Index { _tasks.startIndex.offset }
    public var endIndex: Index { _tasks.endIndex.offset }

    public subscript(position: Index) -> Element {
      _tasks[_Base.Index(position)].value
    }
  }
}
