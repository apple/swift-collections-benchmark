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

extension _BenchmarkCLI {
  internal struct Results: ParsableCommand {
    internal static var configuration: CommandConfiguration {
      CommandConfiguration(
        commandName: "results",
        abstract: "Operations on benchmark results.",
        subcommands: [
          ListTasks.self,
          Compare.self,
          Merge.self,
          Delete.self,
        ])
    }
  }
}
