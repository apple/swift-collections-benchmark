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

public enum ImageFormat: String, CaseIterable, Hashable, ExpressibleByArgument {
  case png
  case pdf
  case svg
  case html
  case json

  public static var defaultSinglefile: ImageFormat {
    .html
  }

  public static var defaultMultifile: ImageFormat {
    Graphics.bestAvailableRenderer.defaultImageFormat
  }

  public var supportsSinglefileRendering: Bool {
    switch self {
    case .html: return true
    case .pdf: return false // FIXME: implement
    case .json: return false // FIXME: implement
    case .png, .svg: return false
    }
  }

  public static func resolve(
    stem: String,
    output: FilePath?,
    format: ImageFormat?,
    multifile: Bool?
  ) throws -> (output: FilePath, format: ImageFormat, multifile: Bool) {
    switch (output, format, multifile) {
    case (nil, nil, nil):
      let format = defaultSinglefile
      let output = FilePath("\(stem).\(format)")
      return (output, format, false)

    case let (output?, nil, nil):
      let url = URL(output)
      if let format = ImageFormat(rawValue: url.pathExtension.lowercased()) {
        return (output, format, !format.supportsSinglefileRendering)
      }
      if output._isDirectory {
        return (output, .defaultMultifile, true)
      }
      throw Benchmark.Error("Please specify an image format")

    case let (nil, nil, multifile?):
      if multifile {
        return (".", defaultMultifile, true)
      }
      return (FilePath("\(stem).\(defaultSinglefile)"), defaultSinglefile, false)

    case let (output?, nil, multifile?):
      let f = ImageFormat(rawValue: URL(output).pathExtension.lowercased())
      if multifile {
        return (output, f ?? defaultMultifile, true)
      }
      guard let format = f else {
        throw Benchmark.Error("Please specify an image format")
      }
      guard format.supportsSinglefileRendering else {
        throw Benchmark.Error("Can't render single file output in '\(format)' format")
      }
      return (output, format, false)

    case let (output, format?, nil):
      guard format.supportsSinglefileRendering else {
        return (output ?? ".", format, true)
      }
      return (output ?? FilePath("\(stem).\(format)"), format, false)

    case let (output, format?, multifile?):
      if multifile {
        return (output ?? ".", format, true)
      }
      guard format.supportsSinglefileRendering else {
        throw Benchmark.Error("Can't render single file output in '\(format)' format")
      }
      return (output ?? FilePath("\(stem).\(format)"), format, multifile)
    }
  }
}

