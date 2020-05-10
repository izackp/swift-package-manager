/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
 */

/// Triple - Helper class for working with Destination.target values
///
/// Used for parsing values such as x86_64-apple-macosx10.10 into
/// set of enums. For os/arch/abi based conditions in build plan.
///
/// @see Destination.target
/// @see https://github.com/apple/swift-llvm/blob/stable/include/llvm/ADT/Triple.h
///
public struct Triple: Encodable {
    public let tripleString: String

    public let arch: Arch
    public let vendor: Vendor
    public let os: OS
    public let abi: ABI

    public enum Error: Swift.Error {
        case badFormat
        case unknownArch
        case unknownOS
    }

    public enum Arch: String, Encodable {
        case x86_64
        case i686
        case powerpc64le
        case s390x
        case aarch64
        case armv7
        case thumbv7m
        case thumbv7em
        case arm
    }

    public enum Vendor: String, Encodable {
        case unknown
        case apple
    }

    public enum OS: String, Encodable {
        case darwin
        case macOS = "macosx"
        case linux
        case windows
        case none

        fileprivate static let allKnown:[OS] = [
            .darwin,
            .macOS,
            .linux,
            .windows,
            .none
        ]
    }

    public enum ABI: String, Encodable {
        case unknown
        case android
        case eabi
    }

    public init(_ string: String) throws {
        let components = string.split(separator: "-").map(String.init)

        guard components.count == 3 || components.count == 4 else {
            throw Error.badFormat
        }

        guard let arch = Arch(rawValue: components[0]) else {
            throw Error.unknownArch
        }

        let vendor = Vendor(rawValue: components[1]) ?? .unknown

        guard let os = Triple.parseOS(components[2]) else {
            throw Error.unknownOS
        }

        let abi = components.count > 3 ? Triple.parseABI(components[3]) : nil

        self.tripleString = string
        self.arch = arch
        self.vendor = vendor
        self.os = os
        self.abi = abi ?? .unknown
    }

    fileprivate static func parseOS(_ string: String) -> OS? {
        for candidate in OS.allKnown {
            if string.hasPrefix(candidate.rawValue) {
                return candidate
            }
        }

        return nil
    }

    fileprivate static func parseABI(_ string: String) -> ABI? {
        if string.hasPrefix(ABI.android.rawValue) {
            return ABI.android
        }
        return nil
    }

    public func isAndroid() -> Bool {
        return os == .linux && abi == .android
    }

    public func isDarwin() -> Bool {
        return vendor == .apple || os == .macOS || os == .darwin
    }

    public func isLinux() -> Bool {
        return os == .linux
    }

    public func isWindows() -> Bool {
        return os == .windows
    }

    /// Returns the triple string for the given platform version.
    ///
    /// This is currently meant for Apple platforms only.
    public func tripleString(forPlatformVersion version: String) -> String {
        precondition(isDarwin())
        return self.tripleString + version
    }

    public static let macOS = try! Triple("x86_64-apple-macosx")
    public static let x86_64Linux = try! Triple("x86_64-unknown-linux-gnu")
    public static let i686Linux = try! Triple("i686-unknown-linux")
    public static let ppc64leLinux = try! Triple("powerpc64le-unknown-linux")
    public static let s390xLinux = try! Triple("s390x-unknown-linux")
    public static let arm64Linux = try! Triple("aarch64-unknown-linux-gnu")
    public static let armLinux = try! Triple("armv7-unknown-linux-gnueabihf")
    public static let armAndroid = try! Triple("armv7a-unknown-linux-androideabi")
    public static let arm64Android = try! Triple("aarch64-unknown-linux-android")
    public static let x86_64Android = try! Triple("x86_64-unknown-linux-android")
    public static let i686Android = try! Triple("i686-unknown-linux-android")
    public static let windows = try! Triple("x86_64-unknown-windows-msvc")

  #if os(macOS)
    public static let hostTriple: Triple = .macOS
  #elseif os(Windows)
    public static let hostTriple: Triple = .windows
  #elseif os(Linux)
    #if arch(x86_64)
      public static let hostTriple: Triple = .x86_64Linux
    #elseif arch(i386)
      public static let hostTriple: Triple = .i686Linux
    #elseif arch(powerpc64le)
      public static let hostTriple: Triple = .ppc64leLinux
    #elseif arch(s390x)
      public static let hostTriple: Triple = .s390xLinux
    #elseif arch(arm64)
      public static let hostTriple: Triple = .arm64Linux
    #elseif arch(arm)
      public static let hostTriple: Triple = .armLinux    
    #endif
  #elseif os(Android)
    #if arch(arm)
      public static let hostTriple: Triple = .armAndroid
    #elseif arch(arm64)
      public static let hostTriple: Triple = .arm64Android
    #elseif arch(x86_64)
      public static let hostTriple: Triple = .x86_64Android
    #elseif arch(i386)
      public static let hostTriple: Triple = .i686Android
    #endif
  #endif
}

extension Triple {
    /// The file extension for dynamic libraries (eg. `.dll`, `.so`, or `.dylib`)
    public var dynamicLibraryExtension: String {
        switch os {
        case .darwin, .macOS:
            return ".dylib"
        case .linux, .none:
            return ".so"
        case .windows:
            return ".dll"
        }
    }

    public var executableExtension: String {
      switch os {
      case .darwin, .macOS:
        return ""
      case .linux:
        return ""
      case .none:
        return ""
      case .windows:
        return ".exe"
      }
    }

    /// The file extension for Foundation-style bundle.
    public var nsbundleExtension: String {
        switch os {
        case .darwin, .macOS:
            return ".bundle"
        default:
            // See: https://github.com/apple/swift-corelibs-foundation/blob/master/Docs/FHS%20Bundles.md
            return ".resources"
        }
    }
}
