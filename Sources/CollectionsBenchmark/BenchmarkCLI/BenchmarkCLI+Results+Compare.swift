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
import ArgumentParser
import SystemPackage

extension _BenchmarkCLI.Results {
  struct Compare: ParsableCommand {
    internal static var configuration: CommandConfiguration {
      CommandConfiguration(
        commandName: "compare",
        abstract: "Compare the contents of two benchmark results files.")
    }

    @Argument(
      help: "Path to a benchmark results file.",
      completion: .file(),
      transform: { str in FilePath(str) })
    internal var first: FilePath

    @Argument(
      help: "Path to another benchmark results file.",
      completion: .file(),
      transform: { str in FilePath(str) })
    internal var second: FilePath

    @Option(
      help: "Output path. (default: don't generate charts)",
      completion: .file(),
      transform: { str in FilePath(str) })
    internal var output: FilePath?

    @Option(help: "Label to select from the first file. (default: unlabeled tasks)")
    internal var firstLabel = ""

    @Option(help: "Label to select from the second file. (default: unlabeled tasks)")
    internal var secondLabel = ""

    @Option(
      parsing: .upToNextOption,
      help: "Labels to use on the generated charts (default: 'before after')")
    internal var chartLabels: [String] = ["before", "after"]

    @OptionGroup
    internal var tasks: Benchmark.Options.TaskSelection

    @Option(help: "The image file format to generate.")
    var format: ImageFormat?

    @Flag(help: "Write a separate image file for each chart. (default: depends on output format)")
    var multifile: Bool = false

    @Flag(help: "Write a single document containing all charts. (default: depends on output format)")
    var singlefile: Bool = false

    @OptionGroup
    internal var chartOptions: _BenchmarkCLI.Render.Options

    @Option(help: "Don't generate charts for tasks where the difference is below this factor. (0 means no cutoff, default: 1.10")
    var chartCutoff: Double = 1.10

    @Option(help: "Don't list tasks where the difference is below this factor. (0 means no cutoff, default: 1.05")
    var listCutoff: Double = 1.05

    @Option(
      parsing: .unconditional,
      help: "Maximum number of charts to generate (default: no limit)")
    var maxCharts: Int?

    func run() throws {
      let first = try BenchmarkResults.load(from: self.first)
      let second = try BenchmarkResults.load(from: self.second)

      if chartLabels.count != 2 {
        throw Benchmark.Error("--chart-labels requires exactly two values")
      }
      if chartLabels[0] == chartLabels[1] {
        throw Benchmark.Error("--chart-labels requires two different values")
      }

      // Get list of all known tasks.
      let firstKnownTasks = first.alltaskIDs().filter { $0.label == firstLabel }
      let secondKnownTasks = second.alltaskIDs().filter { $0.label == secondLabel }
      let allKnownTasks = Set(
        firstKnownTasks.map { TaskID(title: $0.title) }
        + secondKnownTasks.map { TaskID(title: $0.title) }
      )

      let tasks = try self.tasks.resolve(
        allKnownTasks: allKnownTasks,
        ignoreLabels: true)

      let maxCharts = self.maxCharts ?? Int.max

      var missingFirst: [TaskID] = []
      var missingSecond: [TaskID] = []
      var missingData: [String] = []
      var common: [(score: Score, first: TaskResults, second: TaskResults)] = []
      for id in tasks {
        let beforeID = TaskID(label: firstLabel, title: id.title)
        let afterID = TaskID(label: secondLabel, title: id.title)
        let before = first[id: beforeID]
        guard before.sampleCount > 0 else {
          missingFirst.append(beforeID)
          continue
        }
        let after = second[id: afterID]
        guard after.sampleCount > 0 else {
          missingSecond.append(afterID)
          continue
        }
        guard let score = Score(before: before, after: after) else {
          missingData.append(beforeID.title)
          continue
        }
        common.append((score, before, after))
      }

      if !missingFirst.isEmpty {
        complain("Tasks missing from first file:")
        missingFirst.forEach { complain("  \($0)") }
      }
      if !missingSecond.isEmpty {
        complain("Tasks missing from second file:")
        missingSecond.forEach { complain("  \($0)") }
      }
      if !missingData.isEmpty {
        complain("Tasks with no overlapping measurements:")
        missingData.forEach { complain("  \($0)") }
      }

      guard !common.isEmpty else {
        throw Benchmark.Error("There is not enough data available to compare results")
      }

      let renderer = Graphics.bestAvailableRenderer
      let theme = try chartOptions.themeSpec.resolve(with: renderer)

      common.sort(by: { $0.score > $1.score })

      print("Tasks with difference scores larger than \(listCutoff):")
      print("  \(Score.header) Name")
      for item in common {
        guard item.score.score > listCutoff else { break }
        let mark = item.score.score > chartCutoff ? " (*)" : ""
        print("  \(item.score) \(item.first.taskID.title)\(mark)")
      }

      guard self.output != nil else { return }

      let (output, format, multifile) = try ImageFormat.resolve(
        stem: "diff",
        output: self.output,
        format: self.format,
        multifile: (self.multifile ? true
                        : self.singlefile ? false
                        : nil))

      // Generate charts.
      typealias Image = (title: String, score: Score, graphics: Graphics)
      var images: [Image] = []
      for (score, before, after) in common.prefix(maxCharts) {
        guard score.score > chartCutoff else { break }
        var results = BenchmarkResults()
        results.add(before.withLabel(chartLabels[0]))
        results.add(after.withLabel(chartLabels[1]))

        let chart = Chart(
          taskIDs: results.alltaskIDs(),
          in: results,
          options: try chartOptions.chartOptions())
        let graphics = chart.draw(
          bounds: chartOptions._bounds,
          theme: theme,
          renderer: renderer)
        images.append((before.taskID.title, score, graphics))
      }

      if multifile {
        guard output._isDirectory else {
          throw Benchmark.Error("Multifile output must be a directory: \(output)")
        }
        let dir = URL(output, isDirectory: true)
        for (i, (title, _, graphics)) in images.enumerated() {
          let data = try renderer.render(
            graphics,
            format: format.rawValue,
            bitmapScale: CGFloat(chartOptions.scale))
          let filename = self.filename(title: title, index: i, format: format)
          let url = dir.appendingPathComponent(filename)
          try data.write(to: url, options: .atomic)
        }
        print("\(images.count) image\(images.count == 1 ? "" : "s") generated in \(output).")
      } else {
        guard format.supportsSinglefileRendering else {
          throw Benchmark.Error("Format '\(format)' does not support multiple charts in a single file")
        }
        var doc = try renderer.documentRenderer(
          title: "Benchmark differentials",
          format: format,
          style: .flat)
        for (title, score, graphics) in images {
          try doc.item(
            title: "\(title) (score: \(score.typesetDescription))",
            graphics: graphics,
            collapsed: false)
        }
        for (score, a, _) in common.dropFirst(images.count) {
          guard score.score > listCutoff else { break }
          try doc.item(
            title: "\(a.taskID.title) (score: \(score.typesetDescription))",
            graphics: nil,
            collapsed: false)
        }
        let url = URL(output, isDirectory: false)
        try doc.render().write(to: url)
        print("\(images.count) images written to \(url.relativePath)")
      }
    }

    func filename(title: String, index: Int, format: ImageFormat) -> String {
      let i = index < 9 ? "0\(index + 1)" : "\(index + 1)"
      return "\(i) \(title).\(format.rawValue)"
    }
  }
}

extension Array where Element == Double {
  fileprivate func _scaledAverage(count: Int) -> Double {
    precondition(count >= self.count)
    if isEmpty { return 1 }
    let sum = sorted().reduce(into: 0, { $0 += $1 })
    let extras = Double(count - self.count)
    return (sum + extras) / Double(count)
  }
}

extension String {
  fileprivate func _rightPadded(_ count: Int) -> String {
    if self.count >= count { return self }
    return self + String(repeating: " ", count: count - self.count)
  }
}

extension _BenchmarkCLI.Results.Compare {
  struct Score: CustomStringConvertible, Comparable {
    var score: Double = 0

    var overall: Double = 0
    var improvements: Double = 0
    var regressions: Double = 0

    var overallCount: Int = 0
    var improvementCount: Int = 0
    var regressionCount: Int = 0

    init?(before: TaskResults, after: TaskResults) {
      var improvementFactors: [Double] = []
      var regressionFactors: [Double] = []
      for (size, before) in before {
        let after = after[size]
        guard let amin = before.minimum, let bmin = after.minimum else { continue }
        guard amin.seconds > 0, bmin.seconds > 0 else { continue }
        if amin < bmin {
          regressionFactors.append(amin.seconds / bmin.seconds)
        } else {
          improvementFactors.append(amin.seconds / bmin.seconds)
        }
      }
      guard !improvementFactors.isEmpty || !regressionFactors.isEmpty else { return nil }
      overallCount = improvementFactors.count + regressionFactors.count
      improvementCount = improvementFactors.count
      regressionCount = regressionFactors.count

      overall = regressionFactors.sorted().reduce(into: 0, { $0 += $1 })
      overall += improvementFactors.sorted().reduce(into: 0, { $0 += $1 })
      overall /= Double(overallCount)

      #if false // average of absolutes
      score =
        (improvementFactors + regressionFactors.map { 1 / $0 })
        ._scaledAverage(count: overallCount)
      #else
      score = overall < 1 ? 1 / overall : overall
      #endif

      improvements = improvementFactors._scaledAverage(count: overallCount)
      regressions = regressionFactors._scaledAverage(count: overallCount)
    }

    static func ==(left: Self, right: Self) -> Bool {
      left.score == right.score
    }

    static func <(left: Self, right: Self) -> Bool {
      left.score < right.score
    }

    static var header: String {
      return "Score   Sum     Improvements Regressions "
    }
    var description: String {
      //     "1.597   1.597   1.597(#33)   1.02(#2)    "
      let scr = String(format: "%-#5.4g", self.score)._rightPadded(5).prefix(5)
      let sum = String(format: "%-#5.4g", self.overall)._rightPadded(5).prefix(5)
      let pos = String(format: "%-#5.4g(#%d)", self.improvements, self.improvementCount)._rightPadded(12)
      let neg = String(format: "%-#5.4g(#%d)", self.regressions, self.regressionCount)._rightPadded(12)
      return "\(scr)   \(sum)   \(pos) \(neg)"
    }

    var typesetDescription: String {
      //     "1.597 (positive: 1.597 at 33 sizes, negative: 1.02 at 2 sizes)"
      let scr = String(format: "%-.4g", self.score)
      let sum = String(format: "%-.4g", self.overall)
      let pos = String(format: "%-.4g", self.improvements)
      let neg = String(format: "%-.4g", self.regressions)

      let improvements = "\(pos)(#\(self.improvementCount))"
      let regressions = "\(neg)(#\(self.regressionCount))"
      return "\(scr), overall: \(sum), improvements: \(improvements), regressions: \(regressions)"
    }
  }
}

