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

import ArgumentParser

internal protocol _BenchmarkCommand: ParsableCommand {
  func run(benchmark: Benchmark) throws
}

internal struct _BenchmarkCLI: ParsableCommand {
  internal static var _name: String? {
    guard let invocation = CommandLine.arguments.first else { return nil }
    guard let lastSlash = invocation.lastIndex(of: "/") else { return nil }
    let component = invocation.index(after: lastSlash)
    return String(invocation[component...])
  }

  public static var configuration: CommandConfiguration {
    CommandConfiguration(
      commandName: _name ?? "swift-collections-benchmark",
      abstract: "A utility for running collection benchmarks and displaying their results.",
      subcommands: [
        Info.self,
        Run.self,
        Render.self,
        Results.self,
        Library.self,
      ])
  }
}
