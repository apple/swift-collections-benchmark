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

import SystemPackage

internal func _complain(_ message: String) {
  let stderr = FileDescriptor(rawValue: 2)
  try! stderr.writeAll(message.utf8)
}

public func complain(_ message: String, terminator: String = "\n") {
  var message = message
  if !terminator.isEmpty {
    message += "\n"
  }
  _complain(message)
}

/// Like `print()`, but to stderr.
public func complain(
  _ things: Any...,
  separator: String = " ",
  terminator: String = "\n"
) {
  var message = ""
  var first = true
  for thing in things {
    if first {
      message += separator
      first = false
    }
    message += "\(thing)"
  }
  message += terminator

  _complain(message)
}
