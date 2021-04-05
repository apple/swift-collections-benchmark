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
  public typealias Point = BenchmarkResults.Point

  public let options: Options
  public let sizeScale: ChartScale
  public let timeScale: ChartScale
  public let links: [TaskID: URL]
  internal let _data: _SimpleOrderedDictionary<TaskID, Band<Curve<Point>>>

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
        var band = Band<Curve<Point>>(.init())
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

  public func chartData(for taskID: TaskID) -> Band<Curve<Point>>? {
    _data[taskID]
  }
}

extension Chart {
  public func draw(
    bounds: CGRect,
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
        atDistance: metrics.size.height + theme.axisLeading,
        from: .maxYEdge)
      rect = division.remainder
      let captionRect =
        division.slice
        .inset(by: EdgeInsets(left: axisMetrics.size.width))
        .divided(atDistance: metrics.size.width, from: .minXEdge)
        .slice
      g.addText(caption,
                style: theme.axisLabels,
                in: CGRect(
                    x: captionRect.minX,
                    y: captionRect.maxY - metrics.size.height,
                    width: metrics.size.width,
                    height: metrics.size.height),
                descender: metrics.descender)

      // Render hallmark.
      let hallmark = _projectName
      let hmMetrics = renderer.measure(theme.axisLabels.font, hallmark)
      g.addText(hallmark,
                style: theme.axisLabels,
                linkTarget: URL(string: _projectURL)!,
                in: CGRect(
                    x: max(captionRect.maxX + theme.xPadding,
                           division.slice.maxX - axisMetrics.size.width - hmMetrics.size.width),
                    y: captionRect.maxY - hmMetrics.size.height,
                    width: hmMetrics.size.width,
                    height: hmMetrics.size.height),
                descender: hmMetrics.descender)
    }

    // Allocate space for axis labels.
    rect = rect.inset(
      by: EdgeInsets(
        left: axisMetrics.size.width,
        bottom: axisMetrics.size.height + theme.axisLeading,
        right: axisMetrics.size.width))

    let chartBounds = rect
    var chartTransform = AffineTransform.identity
    chartTransform.translate(x: rect.minX, y: rect.minY)
    chartTransform.scale(x: rect.width, y: rect.height)

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
        curve.map { point -> CGPoint in
          let p = CGPoint(x: sizeScale.position(for: Double(point.size.rawValue)),
                          y: 1 - timeScale.position(for: point.time.seconds))
          return chartTransform.transform(p)
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
    chartBounds: CGRect,
    in g: inout Graphics,
    theme: Theme,
    renderer: Renderer
  ) {
    typealias Line = (line: Shape, label: Text?)
    var lines: [Line] = sizeScale.gridlines.map { gridline in
      let xMid = chartBounds.minX + gridline.position * chartBounds.width
      let yTop = chartBounds.maxY + 3
      let start = CGPoint(x: xMid, y: chartBounds.minY)
      let end = CGPoint(x: xMid, y: chartBounds.maxY)
      let line = Shape(
        path: .line(from: start, to: end),
        stroke: gridline.kind == .major ? theme.majorGridline : theme.minorGridline)
      let label: Text? = gridline.label.map { label in
        let metrics = renderer.measure(theme.axisLabels.font, label)
        let pos = CGPoint(x: xMid - metrics.size.width / 2, y: yTop)
        let box = CGRect(origin: pos, size: metrics.size)
        return Text(label, style: theme.axisLabels,
                    in: box, descender: metrics.descender)
      }
      return (line, label)
    }
    // Returns true if there isn't enough space to display all labels.
    func needsThinning(_ lines: [Line]) -> Bool {
      var previousFrame: CGRect = .null
      for line in lines {
        guard let label = line.label else { continue }
        let enlarged = label.boundingBox.insetBy(dx: -3, dy: 0)
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
    chartBounds: CGRect,
    in g: inout Graphics,
    theme: Theme,
    renderer: Renderer
  ) {
    let suppressMinorLines = (!options.amortizedTime || chartBounds.height < 200)
    var previousLabelBox = CGRect.null
    for gridline in timeScale.gridlines {
      guard gridline.kind == .major || !suppressMinorLines else { continue }
      let y = chartBounds.maxY - gridline.position * chartBounds.height
      g.addLine(
        from: CGPoint(x: chartBounds.minX, y: y),
        to: CGPoint(x: chartBounds.maxX, y: y),
        stroke: gridline.kind == .major ? theme.majorGridline : theme.minorGridline)
      if gridline.kind == .major, let label = gridline.label {
        let metrics = renderer.measure(theme.axisLabels.font, label)
        let yMid = y - metrics.size.height / 6
        let left = CGRect(
          x: chartBounds.minX - theme.xPadding - metrics.size.width,
          y: yMid - metrics.size.height / 2,
          width: metrics.size.width,
          height: metrics.size.height)
        let right = CGRect(
          x: chartBounds.maxX + theme.xPadding,
          y: yMid - metrics.size.height / 2,
          width: metrics.size.width,
          height: metrics.size.height)
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
    var start: CGPoint
    var end: CGPoint
    var strokes: [Stroke]
    var label: Text

    mutating func _offset(by delta: CGPoint) {
      start.x += delta.x
      start.y += delta.y
      end.x += delta.x
      end.y += delta.y
      label.boundingBox.origin.x += delta.x
      label.boundingBox.origin.y += delta.y
    }
  }

  internal func _layoutLegend(
    chartBounds: CGRect,
    options: Options,
    theme: Theme,
    renderer: Renderer
  ) -> (box: CGRect, items: [_LegendItem])? {
    guard theme.legendPosition != .hidden else { return nil }
    typealias Metrics = (size: CGSize, descender: CGFloat)
    let labels: [(taskID: TaskID, string: String, metrics: Metrics)] =
      _data.map { item in
        let label = item.key.typesetDescription
        let metrics = renderer.measure(theme.legendLabels.font, label)
        return (item.key, label, metrics)
      }
    let maxHeight: CGFloat = labels.reduce(0) {
      Swift.max($0, $1.metrics.size.height)
    }
    let maxWidth: CGFloat = labels.reduce(0) {
      Swift.max($0, $1.metrics.size.width)
    }

    var y = theme.legendPadding.top
    var items: [_LegendItem] = labels.enumerated().map { (index, label) in
      let metrics = label.metrics

      if index > 0 {
        y += theme.legendLineLeading
      }
      var x = theme.legendPadding.left
      let sampleRect = CGRect(
        x: x,
        y: y + maxHeight - metrics.size.height,
        width: theme.legendLineSampleWidth,
        height: metrics.size.height)

      x += sampleRect.width + theme.legendSeparation
      let text = Text(
        label.string,
        style: theme.legendLabels,
        linkTarget: self.links[label.taskID],
        in: CGRect(origin: CGPoint(x: x, y: y), size: metrics.size),
        descender: metrics.descender)
      
      let curveTheme = theme._themeForCurve(index: index, of: labels.count)
      let lineRect = sampleRect.insetBy(dx: curveTheme.lineWidth / 2, dy: 0)
      let item = _LegendItem(
        start: CGPoint(x: lineRect.minX, y: lineRect.midY),
        end: CGPoint(x: lineRect.maxX, y: lineRect.midY),
        strokes: [curveTheme.stroke, theme.hairlines],
        label: text)
      y += maxHeight
      return item
    }
    y += theme.legendPadding.bottom

    let size = CGSize(
      width: theme.legendPadding.left + theme.legendLineSampleWidth
        + theme.legendSeparation + maxWidth + theme.legendPadding.right,
      height: y)
    let box = theme._legendFrame(for: size, in: chartBounds)
    for i in items.indices {
      items[i]._offset(by: box.origin)
    }
    return (box, items)
  }
}

