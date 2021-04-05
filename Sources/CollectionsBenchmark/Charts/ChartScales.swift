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

import Foundation // CGPoint, CGFloat

extension Chart {
  public struct Gridline {
    public enum Kind {
      case major
      case minor
    }
    public let kind: Kind
    public let position: CGFloat
    public let label: String?

    public init(_ kind: Kind, position: CGFloat, label: String? = nil) {
      self.kind = kind
      self.position = position
      self.label = label
    }
  }
}

public protocol ChartScale {
  // Convert the given value to chart coordinates using this scale.
  func position(for value: Double) -> CGFloat
  
  /// The range of values that can be displayed using this scale.
  var displayedRange: ClosedRange<Double> { get }
  
  /// Positions for Gridline/notches to help reading.
  var gridlines: [Chart.Gridline] { get }
}

// A scale that has no grid lines and displays no data.
extension Chart {
  public struct EmptyScale: ChartScale {
    public let displayedRange: ClosedRange<Double> = 0...1
    public let gridlines: [Gridline] = []
    public func position(for value: Double) -> CGFloat { CGFloat(2) }
  }

  public struct LogarithmicScale: ChartScale {
    let _isDecimal: Bool
    let _labeler: (Int) -> String

    let _exponentRange: ClosedRange<Int>
    public let displayedRange: ClosedRange<Double>

    // These constants are used to speed up `position(for:)`
    let _a: Double
    let _b: Double

    public init(
      displayedRange range: ClosedRange<Double>,
      isDecimal: Bool,
      labeler: @escaping (Int) -> String
    ) {
      let range = (range.lowerBound > 0
                    ? range
                    : Swift.min(1e-30, range.upperBound) ... range.upperBound)
      self._isDecimal = isDecimal
      self._labeler = labeler

      let step = isDecimal ? 10.0 : 2.0

      let smidgen = 0.001

      // Find last major grid line below range.
      let rescaledUpperBound: Double
      let min: Double
      var minExponent =  0
      if range.lowerBound < 1 {
        var s: Double = 1
        while range.lowerBound * s + smidgen < 1 {
          s *= step
          minExponent -= 1
        }
        min = 1 / s
        rescaledUpperBound = range.upperBound * s
      }
      else {
        var s: Double = 1
        while s * step <= range.lowerBound {
          s *= step
          minExponent += 1
        }
        min = s
        rescaledUpperBound = range.upperBound / s
      }

      // Find first major grid line above range.
      var maxExponent = minExponent
      var s: Double = 1
      repeat {
        s *= step
        maxExponent += 1
      } while s < rescaledUpperBound * (1 - smidgen)
      let max = min * s
      self.displayedRange = min ... max
      self._exponentRange = minExponent ... maxExponent

      self._a = log2(min)
      self._b = log2(max) - log2(min)
    }

    public func position(for value: Double) -> CGFloat {
      if value <= 0 { return 0 }
      return CGFloat((log2(value) - _a) / _b)
    }

    public var gridlines: [Gridline] {
      var gridlines: [Gridline] = []
      let step = _isDecimal ? 10.0 : 2.0
      for exponent in _exponentRange {
        let position = self.position(for: pow(step, Double(exponent)))
        let label = _labeler(exponent)
        let line = Gridline(.major, position: position, label: label)
        gridlines.append(line)
      }
      if _isDecimal {
        // Add minor gridlines at 2× intervals
        var value = 2 * displayedRange.lowerBound
        while true {
          let position = self.position(for: value)
          if position > 1.0001 { break }
          gridlines.append(Gridline(.minor, position: position))
          value *= 2
        }
      }
      return gridlines
    }
  }

  public struct LinearScale: ChartScale {
    let _isDecimal: Bool
    let _labeler: (Double) -> String
    public let displayedRange: ClosedRange<Double>
    private let _stepSize: Double

    public init(
      displayedRange range: ClosedRange<Double>,
      isDecimal: Bool,
      labeler: @escaping (Double) -> String
    ) {
      self._isDecimal = isDecimal
      self._labeler = labeler

      // Find a step size that gives us a good amount of grid lines at nice
      // even positions.
      var steps = (isDecimal ? [5.0, 2.0] : [2.0])._repeating()
      let desiredScope: Range<Double> = isDecimal ? 5.0 ..< 20.0 : 4.0 ..< 16.0

      let scope = range.upperBound - range.lowerBound
      var stepSize = 1.0
      if scope < desiredScope.lowerBound {
        while stepSize * scope < desiredScope.lowerBound {
          stepSize *= steps.next()
        }
        stepSize = 1 / stepSize
      }
      else if scope > desiredScope.upperBound {
        while scope > stepSize * desiredScope.upperBound {
          stepSize *= steps.next()
        }
      }
      let min = stepSize * floor(range.lowerBound / stepSize)
      let max = stepSize * ceil(range.upperBound / stepSize)
      self.displayedRange = min ... max
      self._stepSize = stepSize
    }

    public func position(for value: Double) -> CGFloat {
      let denom = displayedRange.upperBound - displayedRange.lowerBound
      return CGFloat((value - displayedRange.lowerBound) / denom)
    }

    public var gridlines: [Gridline] {
      var gridlines: [Gridline] = []
      let majorStep = _stepSize
      let minorStep = _stepSize / 4
      var value = self.displayedRange.lowerBound
      while true {
        let position = self.position(for: value)
        if position > 1.0001 { break }
        gridlines.append(Gridline(.major, position: position, label: _labeler(value)))
        if _isDecimal {
          var v = value + minorStep
          while v < value + majorStep {
            let p = self.position(for: v)
            if p > 1.0001 { break }
            gridlines.append(Gridline(.minor, position: p, label: _labeler(v)))
            v += minorStep
          }
        }
        value += majorStep
      }
      return gridlines
    }
  }
}
