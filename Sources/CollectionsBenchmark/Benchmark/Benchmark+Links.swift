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

extension Benchmark {
  func _links(for taskNames: [String], base: URL) -> [String: URL] {
    var result: [String: URL] = [:]
    for name in taskNames {
      guard let task = _tasks[name] else { continue }
      result[name] = task._sourceLink(base: base)
    }
    return result
  }
}

private func packageBuildRoot(for path: String) -> String? {
  var root = URL(fileURLWithPath: path)
  while !root.appendingPathComponent("Package.swift")._filePath._exists {
    root.deleteLastPathComponent()
    if root.path.isEmpty { return nil }
  }
  return root.path
}

extension AnyTask {
  func _sourceLink(base: URL) -> URL? {
    var file = Substring(self.file.description)
    guard let prefix = packageBuildRoot(for: file.base) else { return nil }
    guard file.starts(with: prefix) else { return nil }
    file = file.dropFirst(prefix.count)
    guard file.starts(with: "/") else { return nil }
    file = file.dropFirst()
    let url = base.appendingPathComponent(String(file))
    // FIXME: URL doesn't let us set the fragment.
    return URL(string: "\(url.relativeString)#L\(line)")
  }
}
