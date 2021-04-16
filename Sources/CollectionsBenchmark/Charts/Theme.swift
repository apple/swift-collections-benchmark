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

public struct Theme: Codable {
  public enum LegendPosition: String, Codable {
    case hidden
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
  }

  public var background: Color = .white
  public var border = Stroke(width: 0.5, color: .black)
  public var margins = EdgeInsets(top: 9, left: 9, bottom: 9, right: 9)

  public var majorGridline = Stroke(
    width: 0.75,
    color: .black,
    capStyle: .butt)
  public var minorGridline = Stroke(
    width: 0.5,
    color: .black,
    dash: Stroke.Dash(style: [6, 3]),
    capStyle: .butt)

  public var axisLabels = Text.Style(
    font: Font(family: "Helvetica", size: 10),
    color: .black)
  public var axisLeading: Double = 3

  public var curves: [CurveTheme] = []
  public var curveFallback: CurveTheme
    = CurveTheme(color: .black, width: 4)

  public var hairlines = Stroke(width: 0.5, color: .black)
  public var bandDimmingFactor: Double = 0.3

  public var xPadding: Double = 6
  public var yPadding: Double = 3

  public var legendPosition: LegendPosition = .topLeft
  public var legendLabels =
    Text.Style(font: Font(family: "Menlo", size: 12), color: .black)
  public var legendCornerOffset = Point(x: 24, y: 24)
  public var legendPadding = EdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
  public var legendLineSampleWidth: Double = 24
  public var legendLineLeading: Double = 3
  public var legendSeparation: Double = 9

  public init() {}
}

extension Theme {
  public struct CurveTheme: Hashable, Codable {
    public var color: Color
    public var lineWidth: Double

    public init(color: Color, width: Double) {
      self.color = color
      self.lineWidth = width
    }

    public var stroke: Stroke {
      Stroke(width: lineWidth, color: color)
    }
  }
}

extension Theme {
  internal func _themeForCurve(index: Int, of count: Int) -> CurveTheme {
    precondition(index >= 0 && index < count)
    if count <= curves.count {
      return curves[index]
    }
    var theme = curveFallback
    // When we have to draw too many curves, just spread them out equally
    // over the rainbow. The result typically won't be very useful.
    theme.color = Color(
      hue: Double(index) / Double(count),
      saturation: 1,
      brightness: 1,
      alpha: 1)
    return theme
  }

  internal func _colorForBand(index: Int, of count: Int) -> Color {
    _themeForCurve(index: index, of: count)
      .color
      .withAlphaFactor(bandDimmingFactor)
  }

  internal func _legendFrame(for size: Vector, in bounds: Rectangle) -> Rectangle {
    let origin: Point
    switch legendPosition {
    case .hidden:
      return Rectangle.null
    case .topLeft:
      origin = Point(
        x: bounds.minX + legendCornerOffset.x,
        y: bounds.minY + legendCornerOffset.y)
    case .topRight:
      origin = Point(
        x: bounds.maxX - legendCornerOffset.x - size.dx,
        y: bounds.minY + legendCornerOffset.y)
    case .bottomLeft:
      origin = Point(
        x: bounds.minX + legendCornerOffset.x,
        y: bounds.maxY - legendCornerOffset.y - size.dy)
    case .bottomRight:
      origin = Point(
        x: bounds.maxX - legendCornerOffset.x - size.dx,
        y: bounds.maxY - legendCornerOffset.y - size.dy)
    }
    return Rectangle(origin: origin, size: size)
  }
}

extension Theme {
  public static var knownThemes: Dictionary<String, Theme> = [
    "light": Theme.light,
    "dark": Theme.dark,
  ]

  public static var light: Theme {
    var theme = Theme()
    theme.background = .white
    theme.border.color = .black
    theme.majorGridline.color = "#0000007F"
    theme.minorGridline.color = "#00000042"
    theme.axisLabels.color = .black
    theme.curves = [
      CurveTheme(
        color: Color.LightPalette.red,
        width: 4),
      CurveTheme(
        color: Color.LightPalette.blue,
        width: 4),
      CurveTheme(
        color: Color.LightPalette.green,
        width: 4),
      CurveTheme(
        color: Color.LightPalette.yellow,
        width: 4),
      CurveTheme(
        color: Color.LightPalette.indigo,
        width: 4),
      CurveTheme(
        color: Color.LightPalette.orange,
        width: 4),
      CurveTheme(
        color: Color.LightPalette.brown,
        width: 4),
      CurveTheme(
        color: Color.LightPalette.purple,
        width: 4),
      CurveTheme(
        color: Color.LightPalette.gray,
        width: 4),
      CurveTheme(
        color: Color.LightPalette.teal,
        width: 4),
      CurveTheme(
        color: Color.LightPalette.pink,
        width: 4),
    ]
    theme.hairlines.color = "#0000004D"
    theme.legendLabels.color = .black
    return theme
  }

  public static var dark: Theme {
    var theme = Theme()
    theme.background = "#1E1E1EFF"
    theme.border.color = .white
    theme.majorGridline.color = "#FFFFFF8C"
    theme.minorGridline.color = "#00000042"
    theme.axisLabels.color = "#FFFFFF3F"
    theme.curves = [
      CurveTheme(
        color: Color.DarkPalette.red,
        width: 4),
      CurveTheme(
        color: Color.DarkPalette.blue,
        width: 4),
      CurveTheme(
        color: Color.DarkPalette.green,
        width: 4),
      CurveTheme(
        color: Color.DarkPalette.yellow,
        width: 4),
      CurveTheme(
        color: Color.DarkPalette.indigo,
        width: 4),
      CurveTheme(
        color: Color.DarkPalette.orange,
        width: 4),
      CurveTheme(
        color: Color.DarkPalette.brown,
        width: 4),
      CurveTheme(
        color: Color.DarkPalette.purple,
        width: 4),
      CurveTheme(
        color: Color.DarkPalette.gray,
        width: 4),
      CurveTheme(
        color: Color.DarkPalette.teal,
        width: 4),
      CurveTheme(
        color: Color.DarkPalette.pink,
        width: 4),
    ]
    theme.hairlines.color = "#FFFFFF4D"
    theme.legendLabels.color = .white
    return theme
  }
}

extension Theme {
  public static func load(from path: FilePath) throws -> Theme {
    try self.load(from: URL(path))
  }

  public static func load(from url: URL) throws -> Theme {
    let decoder = JSONDecoder()
    // FIXME: this fails when the path points to a special device like a
    // tty or a FIFO.
    let data = try Data(contentsOf: url)
    return try decoder.decode(Theme.self, from: data)
  }

  public func save(to path: FilePath) throws {
    try save(to: URL(path))
  }

  public func save(to url: URL) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = BenchmarkResults.OutputFormat.pretty._encoderFormatting
    let data = try encoder.encode(self)
    try data.write(to: url, options: .atomic)
  }
}

extension Theme {
  public struct Spec: ParsableCommand {
    @Option(help: "Chart appearance theme to use (default: light)")
    public var theme: String = "light"

    @Option(help: "Path to a chart theme configuration file",
            completion: .file(extensions: ["json"]),
            transform: { str in FilePath(str) })
    public var themeFile: FilePath?

    public init() {}

    public func resolve(with renderer: Renderer) throws -> Theme {
      if let path = themeFile {
        return try Theme.load(from: path)
      }
      guard let theme = Theme.knownThemes[self.theme] else {
        throw Benchmark.Error("Unknown theme '\(self.theme)'")
      }
      return renderer.resolve(theme)
    }
  }
}

extension Renderer {
  public func resolve(_ theme: Theme) -> Theme {
    var theme = theme
    theme.axisLabels.font = resolve(theme.axisLabels.font)
    theme.legendLabels.font = resolve(theme.legendLabels.font)
    return theme
  }
}

