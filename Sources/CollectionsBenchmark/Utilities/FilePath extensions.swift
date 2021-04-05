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

extension URL {
  internal init(_ path: FilePath, isDirectory: Bool? = nil) {
    if let isDirectory = isDirectory {
      self.init(fileURLWithPath: path.description, isDirectory: isDirectory)
    } else {
      self.init(fileURLWithPath: path.description)
    }
  }

  internal var _filePath: FilePath {
    precondition(self.isFileURL)
    return FilePath(self.path)
  }
}

extension FilePath {
  internal var _exists: Bool {
    FileManager.default.fileExists(atPath: self.description)
  }

  internal var _isDirectory: Bool {
    var isDirectory: ObjCBool = false
    return
      FileManager.default.fileExists(atPath: self.description, isDirectory: &isDirectory)
      && isDirectory.boolValue
  }

  /// Synchronously read the contents of the file at this path.
  ///
  /// Unlike `Data(contentsOf:)`, this supports reading from special files
  /// like terminal devices or FIFOs.
  internal func _bytes() throws -> Data {
    let fd = try FileDescriptor.open(self, .readOnly)
    var data = Data()
    var bytesRead = 0
    try fd.closeAfter {
      while true {
        if bytesRead == data.count {
          data.count += 1024
        }
        let c: Int = try data.withUnsafeMutableBytes { buffer in
          let target = UnsafeMutableRawBufferPointer(rebasing: buffer[bytesRead...])
          precondition(target.count > 0)
          let c = try fd.read(into: target)
          bytesRead += c
          return c
        }
        if c == 0 { break }
      }
    }
    data.count = bytesRead
    return data
  }

  /// Synchronously read the contents of the file at this path into a string,
  /// interpreting its bytes as UTF-8 data.
  ///
  /// Unlike `String(contentsOf:)`, this supports reading from special files
  /// like terminal devices or FIFOs.
  internal func _utf8Characters() throws -> String {
    let data = try _bytes()
    return data.withUnsafeBytes { buffer in
      String(decoding: buffer, as: UTF8.self)
    }
  }

  internal func _utf8Lines() throws -> [String] {
    let string = try _utf8Characters()
    return string.split(whereSeparator: { $0.isNewline }).map { String($0) }
  }
}
