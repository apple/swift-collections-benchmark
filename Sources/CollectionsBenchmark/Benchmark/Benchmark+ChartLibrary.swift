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
import SystemPackage

extension Benchmark {
  /// A hierarchical collection of benchmark charts.
  public enum ChartLibrary {
    /// A group of charts. This renders its contents inside a subdirectory
    /// with the same name.
    case group(Group)
    /// A set of chart variants. The contents are generated in the current
    /// directory, tagged using secondary numbers like `04a`, '04b', '04c' etc.
    /// The associated `charts` value must consist only of `.chart`s.
    case variants(Variants)
    /// A single chart. The tasks are rendered as an image file in the
    /// directory corresponding to the chart's ancestors in the library,
    /// and numbered according to their position in their parent group.
    case chart(Chart)
  }
}

extension Benchmark.ChartLibrary {
  public struct Group: Codable {
    public var title: String
    public var directory: String?
    public var contents: [Benchmark.ChartLibrary]
  }

  public struct Variants: Codable {
    public var charts: [Chart]
  }

  public struct Chart: Codable {
    public var title: String
    public var tasks: [TaskID]
  }
}

extension Benchmark {
  internal func _loadLibrary(_ path: FilePath) throws -> ChartLibrary {
    try Benchmark.ChartLibrary.load(from: path)
  }
}

extension Benchmark.ChartLibrary: Codable {
  enum _CodingKey: String, CodingKey {
    case kind
    case title
    case directory
    case contents
    case charts
    case tasks
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: _CodingKey.self)
    let kind = try container.decode(String.self, forKey: .kind)
    switch kind {
    case "group":
      let title = try container.decode(String.self, forKey: .title)
      let directory = try container.decodeIfPresent(String.self, forKey: .directory)
      let contents = try container.decode([Self].self, forKey: .contents)
      self = .group(Group(title: title, directory: directory, contents: contents))
    case "variants":
      let charts: [Chart] =
        try container.decode([Self].self, forKey: .charts)
        .map { entry in
          guard case let .chart(chart) = entry else {
            throw DecodingError.dataCorruptedError(
              forKey: .contents,
              in: container,
              debugDescription: "'variants' entry may only contain charts")
          }
          return chart
        }
      self = .variants(Variants(charts: charts))
    case "chart":
      let title = try container.decode(String.self, forKey: .title)
      let tasks = try container.decode([TaskID].self, forKey: .tasks)
      self = .chart(Chart(title: title, tasks: tasks))
    default:
      throw DecodingError.dataCorruptedError(
        forKey: .kind,
        in: container,
        debugDescription: "Unknown kind '\(kind)'")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: _CodingKey.self)
    switch self {
    case let .group(group):
      try container.encode("group", forKey: .kind)
      try container.encode(group.title, forKey: .title)
      try container.encode(group.directory, forKey: .directory)
      try container.encode(group.contents, forKey: .contents)
    case let .variants(variants):
      try container.encode("variants", forKey: .kind)
      try container.encode(variants.charts, forKey: .charts)
    case let .chart(chart):
      try container.encode("chart", forKey: .kind)
      try container.encode(chart.title, forKey: .title)
      try container.encode(chart.tasks, forKey: .tasks)
    }
  }
}


extension Benchmark.ChartLibrary {
  public static func load(from path: FilePath) throws -> Self {
    try load(from: URL(path))
  }

  public static func load(from url: URL) throws -> Self {
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode(Self.self, from: data)
  }
}

extension Benchmark.ChartLibrary {
  public var allTasks: [TaskID] {
    var result: _SimpleOrderedSet<TaskID> = []
    _allTasks(&result)
    return result.elements
  }

  private func _allTasks(_ result: inout _SimpleOrderedSet<TaskID>) {
    switch self {
    case .group(let group):
      for item in group.contents {
        item._allTasks(&result)
      }
    case .variants(let variants):
      for chart in variants.charts {
        result.formUnion(chart.tasks)
      }
    case .chart(let chart):
      result.formUnion(chart.tasks)
    }
  }
}

extension Benchmark.ChartLibrary {
  public func allImages(format: ImageFormat = .defaultSinglefile) -> [String] {
    var result: [String] = []
    _allImages(format: format, path: _Path(), result: &result)
    return result
  }

  private func _allImages(format: ImageFormat, path: _Path, result: inout [String]) {
    switch self {
    case .group(let group):
      let path = path.appendingGroup(group.directory ?? group.title)
      var index = 0
      for entry in group.contents {
        entry._allImages(format: format, path: path.withIndex(index), result: &result)
        if entry.kind == .chart || entry.kind == .variants {
          index += 1
        }
      }
    case .variants(let variants):
      precondition(path.variant == nil)
      for (i, chart) in variants.charts.enumerated() {
        result.append(chart._filename(path: path.withVariant(i), format: format))
      }
    case .chart(let chart):
      result.append(chart._filename(path: path, format: format))
    }
  }
}

extension Benchmark.ChartLibrary.Chart {
  internal func _filename(
    path: Benchmark.ChartLibrary._Path,
    format: ImageFormat
  ) -> String {
    let dir = path.groups.joined(separator: "/")
    return "\(dir)/\(path.chartID) \(title).\(format)"
  }
}

extension Benchmark.ChartLibrary {
  public enum Kind: Equatable {
    case group
    case variants
    case chart
  }

  public var kind: Kind {
    switch self {
    case .group: return .group
    case .variants: return .variants
    case .chart: return .chart
    }
  }
}

extension Benchmark.ChartLibrary {
  internal struct _Path {
    var groups: [String]
    var index: Int
    var variant: Int?

    init(_ groups: [String] = [], _ index: Int = 0, _ variant: Int? = nil) {
      self.groups = groups
      self.index = index
      self.variant = variant
    }

    var directory: String {
      groups.joined(separator: "/")
    }

    var chartID: String {
      let i = index < 9 ? "0\(index + 1)" : "\(index + 1)"
      if let variant = self.variant {
        guard variant < 26 else {
          return "\(i)-\(variant + 1)"
        }
        let a: UnicodeScalar = "a"
        let v = String(UnicodeScalar(a.value + UInt32(variant))!)
        return "\(i)\(v)"
      }
      return i
    }

    func appendingGroup(_ name: String) -> _Path {
      var path = self
      path.groups.append(name)
      path.index = 0
      path.variant = nil
      return path
    }

    func withIndex(_ index: Int) -> _Path {
      var path = self
      path.index = index
      path.variant = nil
      return path
    }

    func withVariant(_ variant: Int) -> _Path {
      var path = self
      path.variant = variant
      return path
    }
  }
}

extension Benchmark.ChartLibrary {
  typealias TaskSelection = Benchmark.Options.TaskSelection
  typealias Render = _BenchmarkCLI.Render

  public enum VisitEvent {
    case startGroup(Group)
    case endGroup(Group)
    case startVariants(Variants)
    case endVariants(Variants)
    case chart(directory: String, number: String, chart: Chart)
  }

  public func apply(
    visitor: (VisitEvent) throws -> Void
  ) throws {
    try _apply(path: _Path(), visitor: visitor)
  }

  internal func _apply(
    path: _Path,
    visitor: (VisitEvent) throws -> Void
  ) throws {
    switch self {
    case .group(let group):
      var index = 0
      let path = path.appendingGroup(group.directory ?? group.title)
      try visitor(.startGroup(group))
      for child in group.contents {
        try child._apply(path: path.withIndex(index), visitor: visitor)
        if child.kind == .chart || child.kind == .variants {
          index += 1
        }
      }
      try visitor(.endGroup(group))
    case .variants(let variants):
      precondition(path.variant == nil)
      for (i, chart) in variants.charts.enumerated() {
        let p = path.withVariant(i)
        try visitor(.chart(directory: p.directory, number: p.chartID, chart: chart))
      }
    case .chart(let chart):
      try visitor(.chart(directory: path.directory, number: path.chartID, chart: chart))
    }
  }
}

extension Benchmark.ChartLibrary {
  func markdown(format: ImageFormat) throws -> String {
    var prefix = ""
    var result = """
      # Benchmark results
      
      Click to expand individual items below.

      """
    try apply { event in
      switch event {
      case .startGroup(let group):
        result += """
              \(prefix)<details open>
              \(prefix)  <summary><strong>\(group.title._xmlEscaped())</strong></summary>
              \(prefix)  <ul>\n
              """
        prefix += "  "
      case .endGroup(_):
        prefix = String(prefix.dropLast(2))
        result += """
              \(prefix)  </ul>
              \(prefix)</details>\n
              """
      case .startVariants, .endVariants:
        break
      case let .chart(directory: directory, number: number, chart: chart):
        let path = directory.isEmpty ? "" : directory + "/"
        let filename = "\(path)\(number) \(chart.title).\(format.rawValue)"
        let url = URL(fileURLWithPath: filename)
        result += """
          \(prefix)<details>
          \(prefix)  <summary>\(number): \(chart.title._xmlEscaped())</summary>
          \(prefix)  <img src=\"\(url.relativePath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)\">
          \(prefix)</details>\n
          """
      }
    }
    return result
  }
}
