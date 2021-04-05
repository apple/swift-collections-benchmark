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

import Foundation // CGRect
import ArgumentParser

extension _BenchmarkCLI.Render {
  internal struct Options: ParsableCommand {
    @Option(help: "Minimum size (default: minimum size in results)")
    var minSize: Size?

    @Option(help: "Maximum size (default: maximum size in results)")
    var maxSize: Size?

    @Option(help: "Minimum time (default: minimum time in results)")
    var minTime: Time?

    @Option(help: "Maximum time (default: maximum time in results)")
    var maxTime: Time?

    @Option(name: .long,
            help: "Render amortized time by dividing elapsed time by its corresponding input size (default: on)")
    var amortized = true

    @Flag(name: .long, help: "Use a linear scale on the size axis (default: logarithmic)")
    var linearSize = false

    @Flag(name: .long, help: "Use a linear scale on the time axis (default: logarithmic)")
    var linearTime = false

    @Option(help: "Bottom band (minimum|mean|sigma1|sigma2|maximum|none, default: minimum)")
    var bottomStatistic: Sample.Statistic = .minimum

    @Option(help: "Center band (minimum|mean|sigma1|sigma2|maximum|none, default: mean)")
    var centerStatistic: Sample.Statistic = .mean

    @Option(help: "Top band (minimum|mean|sigma1|sigma2|maximum|none, default: sigma2)")
    var topStatistic: Sample.Statistic = .sigma(2)

    var statistics: Band<Sample.Statistic> {
      Band<Sample.Statistic>(
        bottom: bottomStatistic,
        center: centerStatistic,
        top: topStatistic)
    }

    @Option(help: "Discard data above this percentile (default: 100, i.e., keep all data)")
    var percentile: Double = 100

    @Option(help: "Width of generated image, in points")
    var width: Int = 1280

    @Option(help: "Height of generated image, in points")
    var height: Int = 480

    @Option(help: "Number of pixels in a point")
    var scale: Double = 2

    @OptionGroup
    var themeSpec: Theme.Spec

    func chartOptions() throws -> Chart.Options {
      var options = Chart.Options()
      options.amortizedTime = self.amortized
      options.logarithmicTime = !self.linearTime
      options.logarithmicSize = !self.linearSize

      options.statistics = self.statistics
      options.percentile = percentile

      options.minSize = self.minSize
      options.maxSize = self.maxSize

      options.minTime = self.minTime
      options.maxTime = self.maxTime

      return options
    }

    var _bounds: CGRect {
      CGRect(x: 0, y: 0, width: width, height: height)
    }
  }
}
