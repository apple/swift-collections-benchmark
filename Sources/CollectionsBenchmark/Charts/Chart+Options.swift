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

import Foundation // for pow

extension Chart {
  public struct Options: Codable {
    public var amortizedTime = true
    public var logarithmicTime = true
    public var logarithmicSize = true

    public var statistics = Band<Sample.Statistic>(
      bottom: .minimum,
      center: .mean,
      top: .sigma(2))

    public var minSize: Size? = nil
    public var maxSize: Size? = nil

    public var minTime: Time? = nil
    public var maxTime: Time? = nil

    public var percentile: Double = 100

    public var amortizedCaptionText
      = "Average per-element processing time over input size"
    public var regularCaptionText
      = "Overall processing time over input size"

    public init() {}
  }
}

extension Chart.Options {
  var captionText: String {
    let base = amortizedTime ? amortizedCaptionText : regularCaptionText
    let bands = statistics.compactMap { $0.typesetDescription }.joined(separator: ", ")
    return "\(base) (bands: \(bands))"
  }

  func sizeScale(for range: ClosedRange<Size>?) -> ChartScale {
    sizeScale(min: range?.lowerBound, max: range?.upperBound)
  }

  func sizeScale(min: Size?, max: Size?) -> ChartScale {
    guard let min = min, let max = max else { return Chart.EmptyScale() }
    let range = Double(min.rawValue) ... Double(max.rawValue)
    if self.logarithmicSize {
      let labeler: (Int) -> String = { value in "\(Size(1 << value))" }
      return Chart.LogarithmicScale(
        displayedRange: range, isDecimal: false, labeler: labeler)
    }
    let labeler: (Double) -> String = { value in "\(Size(Int(value)))" }
    return Chart.LinearScale(
      displayedRange: range, isDecimal: false, labeler: labeler)
  }

  func timeScale(for range: ClosedRange<Time>?) -> ChartScale {
    timeScale(min: range?.lowerBound, max: range?.upperBound)
  }

  func timeScale(min: Time?, max: Time?) -> ChartScale {
    guard let min = min, let max = max else { return Chart.EmptyScale() }
    let range = min.seconds ... max.seconds
    if self.logarithmicTime {
      let labeler: (Int) -> String = { value in
        Time(pow(10, Double(value))).typesetDescription
      }
      return Chart.LogarithmicScale(
        displayedRange: range, isDecimal: true, labeler: labeler)
    }
    let labeler: (Double) -> String = { value in "\(Time(value))" }
    return Chart.LinearScale(
      displayedRange: range, isDecimal: true, labeler: labeler)
  }
}
