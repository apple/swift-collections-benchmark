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

extension String {
  /// Sanitize a string replacing common characters that aren't supported
  /// in filesystem path components on the current system.
  ///
  /// Note that this does not guarantee that the returned string will be a
  /// valid filename -- for example, it does not filter out control characters
  /// other than NUL, and it does not check for reserved filenames such as
  /// `.`, `..` (or `CON` on Windows). This is fine -- all this needs to do
  /// is to map reasonable chart titles to plausible filenames that resemble
  /// them. There is also no expectation that this would prevent collisions
  /// -- the caller is supposed to guarantee that the filenames will get
  /// distinguished by e.g. numbering them.
  ///
  /// (An example for a reasonable chart title that includes several characters
  /// not supported in filenames is `std::deque<int> append/removeFirst`.
  /// `:`, `<`, and `>` are invalid on Windows, while `/` is invalid on all
  /// currently supported platforms.)
  internal func _sanitizedPathComponent() -> String {
    // FIXME: Should we use a highest common denominator allow list instead?
    // (I don't think we need to go that far, but it may be nice to use the same
    // rules everywhere.)
    #if os(Windows)
    let blockList: Set<UnicodeScalar> = [
      "/", "\u{0}", "\\", ":", "<", ">", "\"", "|", "?", "*",
    ]
    #else
    let blockList: Set<UnicodeScalar> = [
      "/", "\u{0}",
    ]
    #endif
    // Replace runs of bad characters with a single underscore.
    var lastReplaced = false
    let scalars = self.unicodeScalars.compactMap { c -> UnicodeScalar? in
      let bad = blockList.contains(c)
      defer { lastReplaced = bad }
      return bad
        ? (lastReplaced ? nil : "_")
        : c
    }
    return String(String.UnicodeScalarView(scalars))
  }
}
