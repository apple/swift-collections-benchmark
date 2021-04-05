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

extension _BenchmarkCLI {
  internal struct Render: ParsableCommand {
    static var configuration = CommandConfiguration(
      commandName: "render",
      abstract: "Generate charts from benchmark results.")
    
    @Argument(help: "Path to a benchmark results document.")
    var input: String
    
    @Argument(help: "Path to image file to generate.")
    var output: String

    @OptionGroup
    var tasks: Benchmark.Options.TaskSelection

    @Flag(name: .long, help: "Print list of tasks selected to run and exit.")
    public var dryRun = false

    @OptionGroup
    var options: Options

    func run() throws {
      let input = URL(fileURLWithPath: self.input)
      let output = URL(fileURLWithPath: self.output)

      let results = try BenchmarkResults.load(from: input)

      let tasks = try self.tasks.resolve(
        allKnownTasks: results.alltaskIDs(),
        ignoreLabels: false)

      if self.dryRun {
        tasks.forEach { print($0) }
        return
      }

      let renderer = Graphics.bestAvailableRenderer
      let theme = try options.themeSpec.resolve(with: renderer)

      let chart = Chart(taskIDs: tasks,
                        in: results,
                        options: try options.chartOptions())
      let graphics = chart.draw(
        bounds: CGRect(x: 0, y: 0, width: options.width, height: options.height),
        theme: theme,
        renderer: renderer)
      let data = try renderer.render(
        graphics,
        format: output.pathExtension,
        bitmapScale: CGFloat(options.scale))
      try data.write(to: output, options: .atomic)
    }
  }
}
