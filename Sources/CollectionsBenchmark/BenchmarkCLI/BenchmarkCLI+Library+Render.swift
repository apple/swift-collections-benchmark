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

extension _BenchmarkCLI.Library {
  internal struct Render: _BenchmarkCommand {
    static var configuration: CommandConfiguration {
      CommandConfiguration(
        commandName: "render",
        abstract: "Render a predefined set of benchmarks.")
    }

    @Option(
      help: "Path to a library configuration file in JSON format. (default: built-in library)",
      completion: .file(extensions: ["json"]),
      transform: { str in FilePath(str) })
    var library: FilePath?

    @Argument(
      help: "A path to a benchmark results document.",
      completion: .file(),
      transform: { str in FilePath(str) })
    var input: FilePath

    @Option(
      help: "Output path.",
      completion: .file(),
      transform: { str in FilePath(str) })
    var output: FilePath?

    @Option(help: "The image file format to generate. (default: based on the output path)")
    var format: ImageFormat?

    @Flag(help: "Write a separate image file for each chart. (default: depends on output format)")
    var multifile: Bool = false

    @Flag(help: "Write a single document containing all charts. (default: depends on output format)")
    var singlefile: Bool = false

    @OptionGroup
    var options: _BenchmarkCLI.Render.Options

    func run(benchmark: Benchmark) throws {
      let results = try BenchmarkResults.load(from: input)
      let library = try benchmark._loadLibrary(self.library)
      let renderer = Graphics.bestAvailableRenderer
      let theme = try options.themeSpec.resolve(with: renderer)

      let (output, format, multifile) = try ImageFormat.resolve(
        stem: "results",
        output: self.output,
        format: self.format,
        multifile: (self.multifile ? true
                        : self.singlefile ? false
                        : nil))

      func draw(_ chart: Benchmark.ChartLibrary.Chart) throws -> Graphics {
        var taskSelection = Benchmark.Options.TaskSelection.empty
        taskSelection.tasks = chart.tasks

        let tasks = try taskSelection.resolve(
          allKnownTasks: results.alltaskIDs(),
          ignoreLabels: false)

        let chart = Chart(taskIDs: tasks,
                          in: results,
                          options: try options.chartOptions())
        let graphics = chart.draw(
          bounds: options._bounds,
          theme: theme,
          renderer: renderer)

        return graphics
      }

      if multifile {
        guard output._isDirectory else {
          throw Benchmark.Error("Multifile output must be a directory: \(output)")
        }
        let output = URL(output, isDirectory: true)

        print("Generating images:")
        var count = 0
        try library.apply { event in
          switch event {
          case .startGroup, .endGroup, .startVariants, .endVariants:
            break
          case let .chart(directory: dir, number: number, chart: chart):
            let graphics = try draw(chart)
            var url = output
            if !dir.isEmpty {
              url.appendPathComponent(dir, isDirectory: true)
            }

            try FileManager.default.createDirectory(
              at: url,
              withIntermediateDirectories: true)

            let filename = "\(number) \(chart.title).\(format)"
              .replacingOccurrences(of: "/", with: "-")
            url.appendPathComponent(filename)
            print("  \(url.relativePath)")

            let data = try renderer.render(
              graphics,
              format: format.rawValue,
              bitmapScale: CGFloat(options.scale))
            try data.write(to: url)
            count += 1
          }
        }
        print("Done. \(count) images saved.")

        let markdown = try library.markdown(format: format)
        let mdfile = output.appendingPathComponent("Results.md")
        try markdown.write(to: mdfile, atomically: true, encoding: .utf8)
        print("Overview written to \(mdfile.relativePath).")
      } else {
        guard format.supportsSinglefileRendering else {
          throw Benchmark.Error("Format '\(format)' does not support multiple charts in a single file")
        }

        var count = 0
        var depth = 0
        var doc = try renderer.documentRenderer(
          title: "Benchmark results",
          format: format,
          style: .collapsible)
        try library.apply { event in
          switch event {
          case .startGroup(let group):
            depth += 1
            try doc.beginSection(title: group.title, collapsed: depth > 2)
          case .endGroup(_):
            try doc.endSection()
            depth -= 1
          case .startVariants, .endVariants:
            break
          case let .chart(directory: _, number: number, chart: chart):
            let graphics = try draw(chart)
            try doc.item(
              title: "\(number) \(chart.title)",
              graphics: graphics,
              collapsed: true)
            count += 1
          }
        }
        let url = URL(output, isDirectory: false)
        try doc.render().write(to: url)
        print("\(count) images written to \(url.relativePath).")
      }
    }
  }
}
