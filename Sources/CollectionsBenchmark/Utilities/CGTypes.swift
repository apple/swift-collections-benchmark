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

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import CoreGraphics
import Foundation

public typealias CGFloat = CoreGraphics.CGFloat
public typealias CGPoint = CoreGraphics.CGPoint
public typealias CGSize = CoreGraphics.CGSize
public typealias CGRect = CoreGraphics.CGRect
public typealias AffineTransform = Foundation.AffineTransform
#else
import Foundation

public typealias CGFloat = Foundation.CGFloat
public typealias CGPoint = Foundation.CGPoint
public typealias CGSize = Foundation.CGSize
public typealias CGRect = Foundation.CGRect
public typealias AffineTransform = Foundation.AffineTransform
#endif
