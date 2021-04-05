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

public struct AnyTask {
  internal let _box: _AnyTask
  internal let _label: String

  internal init(_box: _AnyTask, label: String) {
    self._box = _box
    self._label = label
  }

  internal init<Input>(_ task: Task<Input>, label: String = "") {
    if let error = TaskID._validateLabel(label) {
      preconditionFailure(error)
    }
    _box = _ConcreteTask(task)
    _label = label
  }

  public var id: TaskID { TaskID(_uncheckedlabel: _label, title: _box.title) }

  public var base: Any { _box.base }

  public var file: StaticString { _box.file }
  public var line: UInt { _box.line }

  public var inputType: Any.Type { _box.inputType }
  public var title: String { _box.title }
  public var maxSize: Int? { _box.maxSize }

  public func prepare(input: Any) -> ((inout Timer) -> Void)? {
    _box.prepare(input: input)
  }

  public func measure(
    size: Size,
    input: Any,
    options: Benchmark.Options
  ) -> Time? {
    _box.measure(size: size, input: input, options: options)
  }

  internal func withLabel(_ label: String) -> AnyTask {
    AnyTask(_box: _box, label: label)
  }
}

extension AnyTask: Hashable {
  public static func ==(left: Self, right: Self) -> Bool {
    return left.title == right.title
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(title)
  }
}

internal class _AnyTask {
  var base: Any { fatalError("Not implemented") }
  var file: StaticString { fatalError("Not implemented") }
  var line: UInt { fatalError("Not implemented") }
  var inputType: Any.Type { fatalError("Not implemented") }
  var title: String { fatalError("Not implemented") }
  var maxSize: Int? { fatalError("Not implemented") }

  func prepare(input: Any) -> ((inout Timer) -> Void)? {
    fatalError("Not implemented")
  }

  func measure(
    size: Size,
    input: Any,
    options: Benchmark.Options
  ) -> Time? {
    fatalError("Not implemented")
  }
}

internal class _ConcreteTask<Input>: _AnyTask {
  let _task: Task<Input>

  init(_ task: Task<Input>) {
    self._task = task
  }

  override var base: Any { _task }
  override var file: StaticString { _task.file }
  override var line: UInt { _task.line }
  override var inputType: Any.Type { Input.self }
  override var title: String { _task.title }
  override var maxSize: Int? { _task.maxSize }

  override func prepare(input: Any) -> ((inout Timer) -> Void)? {
    guard let input_ = input as? Input else {
      preconditionFailure(
        "Unexpected input; expected \(Input.self), actual \(type(of: input))")
    }
    return _task.body(input_)
  }

  override func measure(
    size: Size,
    input: Any,
    options: Benchmark.Options
  ) -> Time? {
    guard let input_ = input as? Input else {
      preconditionFailure(
        "Unexpected input; expected \(Input.self), actual \(type(of: input))")
    }
    return _task.measure(size: size, input: input_, options: options)
  }
}
