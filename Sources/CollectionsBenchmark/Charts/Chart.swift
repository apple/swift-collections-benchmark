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

/// The data for a benchmark chart in a nice preprocessed format.
public struct Chart {
  public let options: Options
  public let sizeScale: ChartScale
  public let timeScale: ChartScale
  public let links: [TaskID: URL]
  internal let _data: _SimpleOrderedDictionary<TaskID, Band<Curve<Measurement>>>

  init(
    taskIDs: [TaskID],
    in results: BenchmarkResults,
    options: Options
  ) {
    self.options = options
    self.links = .init(
      uniqueKeysWithValues: taskIDs.lazy.compactMap { id in
        guard let link = results[id: id].link else { return nil }
        return (id, link) }
    )
    // Gather data in the results coordinate system.
    self._data = .init(
      uniqueKeysWithValues: taskIDs.lazy.map { id in
        var band = Band<Curve<Measurement>>(.init())
        for bi in BandIndex.allCases {
          let statistic = options.statistics[bi]
          guard statistic != .none else { continue }
          band[bi] = results[id: id].curve(
            for: statistic,
            percentile: options.percentile,
            amortizedTime: options.amortizedTime)
        }
        return (id, band)
      })

    // Determine size range to display.
    var sizeRange = _data.reduce(nil) { _union($0, $1.value.sizeRange) }
    if let minSize = options.minSize {
      sizeRange = minSize ... _max(minSize, sizeRange?.upperBound)!
    }
    if let maxSize = options.maxSize {
      sizeRange = _min(sizeRange?.lowerBound, maxSize)! ... maxSize
    }

    // Determine time range to display.
    var timeRange = _data.reduce(nil) { _union($0, $1.value.timeRange) }
    if let minTime = options.minTime {
      timeRange = minTime ... _max(minTime, timeRange?.upperBound)!
    }
    if let maxTime = options.maxTime {
      timeRange = _min(timeRange?.lowerBound, maxTime)! ... maxTime
    }
    // Don't go below picoseconds on the logarithmic scale.
    // Such small values usually indicate a timer problem or an amortized
    // display of a O(1)/O(log(n)) function.
    if options.logarithmicTime,
       let min = timeRange?.lowerBound,
       min < .picosecond
    {
      timeRange = .picosecond ... Swift.max(.picosecond, timeRange!.upperBound)
    }

    // Set the scales.
    self.sizeScale = options.sizeScale(for: sizeRange)
    self.timeScale = options.timeScale(for: timeRange)
  }
}

extension Chart {
  public func allTaskIDs() -> [TaskID] {
    _data.map { $0.key }
  }

  public func chartData(for taskID: TaskID) -> Band<Curve<Measurement>>? {
    _data[taskID]
  }
}

extension Chart {
  public func draw(
    bounds: Rectangle,
    theme: Theme,
    renderer: Renderer
  ) -> Graphics {
    let axisMetrics = renderer.measure(theme.axisLabels.font, "XXXXXX")
    var g = Graphics(bounds: bounds.integral)
    // Render the background.
    g.addRect(bounds, fill: theme.background)

    var rect = g.bounds.inset(by: theme.margins)

    // Allocate space for the caption text.
    let caption = options.captionText
    if !caption.isEmpty {
      let metrics = renderer.measure(theme.axisLabels.font, caption)
      let division = rect.divided(
        atDistance: metrics.height + theme.axisLeading,
        from: .maxY)
      rect = division.remainder
      let captionRect =
        division.slice
        .inset(by: EdgeInsets(minX: axisMetrics.width))
        .divided(atDistance: metrics.width, from: .minX)
        .slice
      g.addText(caption,
                style: theme.axisLabels,
                in: Rectangle(
                    x: captionRect.minX,
                    y: captionRect.maxY - metrics.height,
                    width: metrics.width,
                    height: metrics.height),
                descender: metrics.descender)

      // Render hallmark.
      let hallmark = _projectName
      let hmMetrics = renderer.measure(theme.axisLabels.font, hallmark)
      g.addText(hallmark,
                style: theme.axisLabels,
                linkTarget: URL(string: _projectURL)!,
                in: Rectangle(
                    x: max(captionRect.maxX + theme.xPadding,
                           division.slice.maxX - axisMetrics.width - hmMetrics.width),
                    y: captionRect.maxY - hmMetrics.height,
                    width: hmMetrics.width,
                    height: hmMetrics.height),
                descender: hmMetrics.descender)
    }

    // Allocate space for axis labels.
    rect = rect.inset(
      by: EdgeInsets(
        minX: axisMetrics.width,
        maxX: axisMetrics.width,
        maxY: axisMetrics.height + theme.axisLeading))

    let chartBounds = rect
    let chartTransform = Transform.identity
      .translated(x: rect.minX, y: rect.minY)
      .scaled(x: rect.width, y: rect.height)

    _renderGridlinesForSizeAxis(
      chartBounds: chartBounds,
      in: &g,
      theme: theme,
      renderer: renderer)
    _renderGridlinesForTimeAxis(
      chartBounds: chartBounds,
      in: &g,
      theme: theme,
      renderer: renderer)

    let legend = _layoutLegend(
      chartBounds: chartBounds,
      options: options,
      theme: theme,
      renderer: renderer)

    // Render legend background.
    if let legend = legend {
      g.addRect(legend.box, fill: theme.background)
    }

    // Convert curve data into chart coordinates.
    let bands = _data.map { item in
      item.value.map { curve in
        curve.map { point -> Point in
          Point(
            x: sizeScale.position(for: Double(point.size.rawValue)),
            y: 1 - timeScale.position(for: point.time.seconds))
          .applying(chartTransform)
        }
      }
    }

    g.addGroup(clippingRect: chartBounds) { g in
      // Render bands.
      for (index, band) in bands.enumerated().reversed() {
        g.addLines(band.top.points + band.bottom.points.reversed(),
                   fill: theme._colorForBand(index: index, of: bands.count))
      }
      // Render main curves.
      for (index, band) in bands.enumerated().reversed() {
        let theme = theme._themeForCurve(index: index, of: bands.count)
        g.addLines(band.center.points, stroke: theme.stroke)
      }
      // Render hairlines.
      for band in bands.reversed() {
        g.addLines(band.center.points, stroke: theme.hairlines)
      }
    }

    // Render legend contents.
    if let legend = legend {
      g.addRect(
        legend.box,
        fill: theme.background.withAlphaFactor(0.7),
        stroke: theme.border)
      for item in legend.items {
        for stroke in item.strokes {
          g.addLine(from: item.start, to: item.end, stroke: stroke)
        }
        g.add(item.label)
      }
    }

    // Render chart border.
    g.addRect(chartBounds, stroke: theme.border)
    return g
  }
}

extension Chart {
  internal func _renderGridlinesForSizeAxis(
    chartBounds: Rectangle,
    in g: inout Graphics,
    theme: Theme,
    renderer: Renderer
  ) {
    typealias Line = (line: Shape, label: Text?)
    var lines: [Line] = sizeScale.gridlines.map { gridline in
      let xMid = chartBounds.minX + gridline.position * chartBounds.width
      let yTop = chartBounds.maxY + 3
      let start = Point(x: xMid, y: chartBounds.minY)
      let end = Point(x: xMid, y: chartBounds.maxY)
      let line = Shape(
        path: .line(from: start, to: end),
        stroke: gridline.kind == .major ? theme.majorGridline : theme.minorGridline)
      let label: Text? = gridline.label.map { label in
        let metrics = renderer.measure(theme.axisLabels.font, label)
        let pos = Point(x: xMid - metrics.width / 2, y: yTop)
        let box = Rectangle(
          x: pos.x, y: pos.y,
          width: metrics.width, height: metrics.height)
        return Text(label, style: theme.axisLabels,
                    in: box, descender: metrics.descender)
      }
      return (line, label)
    }
    // Returns true if there isn't enough space to display all labels.
    func needsThinning(_ lines: [Line]) -> Bool {
      var previousFrame: Rectangle = .null
      for line in lines {
        guard let label = line.label else { continue }
        let enlarged = label.boundingBox.inset(dx: -3, dy: 0)
        if previousFrame.intersects(enlarged) { return true }
        previousFrame = enlarged
      }
      return false
    }
    while needsThinning(lines) {
      // Discard every other label.
      var discardNext = false
      for i in lines.indices {
        guard lines[i].label != nil else { continue }
        if discardNext {
          lines[i].label = nil
        }
        discardNext = !discardNext
      }
    }
    for line in lines {
      g.add(line.line)
      if let label = line.label {
        g.add(label)
      }
    }
  }
}

extension Chart {
  internal func _renderGridlinesForTimeAxis(
    chartBounds: Rectangle,
    in g: inout Graphics,
    theme: Theme,
    renderer: Renderer
  ) {
    let suppressMinorLines = (!options.amortizedTime || chartBounds.height < 200)
    var previousLabelBox = Rectangle.null
    for gridline in timeScale.gridlines {
      guard gridline.kind == .major || !suppressMinorLines else { continue }
      let y = chartBounds.maxY - gridline.position * chartBounds.height
      g.addLine(
        from: Point(x: chartBounds.minX, y: y),
        to: Point(x: chartBounds.maxX, y: y),
        stroke: gridline.kind == .major ? theme.majorGridline : theme.minorGridline)
      if gridline.kind == .major, let label = gridline.label {
        let metrics = renderer.measure(theme.axisLabels.font, label)
        let yMid = y - metrics.height / 6
        let left = Rectangle(
          x: chartBounds.minX - theme.xPadding - metrics.width,
          y: yMid - metrics.height / 2,
          width: metrics.width,
          height: metrics.height)
        let right = Rectangle(
          x: chartBounds.maxX + theme.xPadding,
          y: yMid - metrics.height / 2,
          width: metrics.width,
          height: metrics.height)
        if left.intersects(previousLabelBox) { continue }
        previousLabelBox = left
        g.addText(label, style: theme.axisLabels,
                  in: left, descender: metrics.descender)
        g.addText(label, style: theme.axisLabels,
                  in: right, descender: metrics.descender)
      }
    }
  }
}

extension Chart {
  struct _LegendItem {
    var start: Point
    var end: Point
    var strokes: [Stroke]
    var label: Text

    mutating func _offset(by delta: Point) {
      start.x += delta.x
      start.y += delta.y
      end.x += delta.x
      end.y += delta.y
      label.boundingBox.origin.x += delta.x
      label.boundingBox.origin.y += delta.y
    }
  }

  internal func _layoutLegend(
    chartBounds: Rectangle,
    options: Options,
    theme: Theme,
    renderer: Renderer
  ) -> (box: Rectangle, items: [_LegendItem])? {
    guard theme.legendPosition != .hidden else { return nil }
    typealias Metrics = (width: Double, height: Double, descender: Double)
    let labels: [(taskID: TaskID, string: String, metrics: Metrics)] =
      _data.map { item in
        let label = item.key.typesetDescription
        let metrics = renderer.measure(theme.legendLabels.font, label)
        return (item.key, label, metrics)
      }
    let maxHeight: Double = labels.reduce(0) {
      Swift.max($0, $1.metrics.height)
    }
    let maxWidth: Double = labels.reduce(0) {
      Swift.max($0, $1.metrics.width)
    }

    var y = theme.legendPadding.minY
    var items: [_LegendItem] = labels.enumerated().map { (index, label) in
      let metrics = label.metrics

      if index > 0 {
        y += theme.legendLineLeading
      }
      var x = theme.legendPadding.minX
      let sampleRect = Rectangle(
        x: x,
        y: y + maxHeight - metrics.height,
        width: theme.legendLineSampleWidth,
        height: metrics.height)

      x += sampleRect.width + theme.legendSeparation
      let text = Text(
        label.string,
        style: theme.legendLabels,
        linkTarget: self.links[label.taskID],
        in: Rectangle(x: x, y: y, width: metrics.width, height: metrics.height),
        descender: metrics.descender)
      
      let curveTheme = theme._themeForCurve(index: index, of: labels.count)
      let lineRect = sampleRect.inset(dx: curveTheme.lineWidth / 2, dy: 0)
      let item = _LegendItem(
        start: Point(x: lineRect.minX, y: lineRect.midY),
        end: Point(x: lineRect.maxX, y: lineRect.midY),
        strokes: [curveTheme.stroke, theme.hairlines],
        label: text)
      y += maxHeight
      return item
    }
    y += theme.legendPadding.maxY

    let size = Vector(
      dx: theme.legendPadding.minY + theme.legendLineSampleWidth
        + theme.legendSeparation + maxWidth + theme.legendPadding.maxY,
      dy: y)
    let box = theme._legendFrame(for: size, in: chartBounds)
    for i in items.indices {
      items[i]._offset(by: box.origin)
    }
    return (box, items)
  }
}

