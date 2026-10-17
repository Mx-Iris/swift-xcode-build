/// A description of the device or platform to build or test for, passed with `-destination`.
///
/// xcodebuild's destination specifier is a comma-separated list of
/// `key=value` pairs, such as `platform=iOS Simulator,name=iPhone 17 Pro,OS=27.0`,
/// optionally prefixed with `generic/` to build for a platform without a
/// specific device. The static methods build the common forms:
///
/// ```swift
/// .generic(.iOS)                                    // generic/platform=iOS
/// .simulator(.iOS, name: "iPhone 17 Pro")           // platform=iOS Simulator,name=iPhone 17 Pro
/// .device(identifier: "00008150-000E40603EF0401C")  // id=00008150-000E40603EF0401C
/// .macOS(architecture: "arm64")                     // platform=macOS,arch=arm64
/// ```
///
/// For other keys, use ``adding(_:_:)`` or create a specifier from its text
/// with ``init(_:)``. ``DestinationDescription/specifier`` turns a destination
/// listed by ``ShowDestinationsCommand`` into a specifier.
///
/// xcodebuild splits the specifier at every comma; neither a backslash nor
/// quotes escape one. Values can't contain commas.
public struct DestinationSpecifier: RawRepresentable, Sendable, Hashable {
    /// The specifier as xcodebuild reads it.
    public var rawValue: String

    /// Creates a specifier from its text, such as `platform=macOS,arch=arm64`.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Creates a specifier from its text, such as `platform=macOS,arch=arm64`.
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    /// Creates a specifier from key-value pairs, in order.
    ///
    /// - Parameters:
    ///   - keyValuePairs: The keys and values, such as `["platform": "iOS", "name": "My iPhone"]`.
    ///   - isGeneric: Whether to prefix the specifier with `generic/`.
    public init(_ keyValuePairs: KeyValuePairs<String, String>, isGeneric: Bool = false) {
        let pairs = keyValuePairs.map { "\($0.key)=\($0.value)" }.joined(separator: ",")
        self.rawValue = isGeneric ? "generic/" + pairs : pairs
    }

    /// Returns the specifier with one more `key=value` pair.
    public func adding(_ key: String, _ value: String) -> DestinationSpecifier {
        DestinationSpecifier(rawValue: rawValue + ",\(key)=\(value)")
    }

    /// Any device of a platform, for building without a device, such as
    /// Xcode's "Any iOS Device" (`generic/platform=iOS`).
    ///
    /// - Parameters:
    ///   - platform: The platform.
    ///   - variant: The variant of macOS, such as `Mac Catalyst`.
    public static func generic(_ platform: DestinationPlatform, variant: String? = nil) -> DestinationSpecifier {
        var specifier = DestinationSpecifier(rawValue: "generic/platform=\(platform.rawValue)")
        if let variant {
            specifier = specifier.adding("variant", variant)
        }
        return specifier
    }

    /// A simulated device, by name (`platform=iOS Simulator,name=…`).
    ///
    /// - Parameters:
    ///   - platform: The platform of the simulator, such as ``DestinationPlatform/iOS``.
    ///   - name: The name of the simulated device, such as `iPhone 17 Pro`.
    ///   - operatingSystemVersion: The version of the simulator runtime, such
    ///     as `27.0`, or `latest`. xcodebuild uses the latest when you omit it.
    ///   - architecture: The architecture, such as `arm64`.
    public static func simulator(
        _ platform: DestinationPlatform,
        name: String,
        operatingSystemVersion: String? = nil,
        architecture: String? = nil
    ) -> DestinationSpecifier {
        var specifier = DestinationSpecifier(rawValue: "platform=\(platform.rawValue) Simulator,name=\(name)")
        if let operatingSystemVersion {
            specifier = specifier.adding("OS", operatingSystemVersion)
        }
        if let architecture {
            specifier = specifier.adding("arch", architecture)
        }
        return specifier
    }

    /// A physical device, by name (`platform=iOS,name=…`).
    ///
    /// - Parameters:
    ///   - platform: The platform of the device, such as ``DestinationPlatform/iOS``.
    ///   - name: The name of the device, as shown in Xcode's Devices window.
    ///   - architecture: The architecture, such as `arm64`.
    public static func device(
        _ platform: DestinationPlatform,
        name: String,
        architecture: String? = nil
    ) -> DestinationSpecifier {
        var specifier = DestinationSpecifier(rawValue: "platform=\(platform.rawValue),name=\(name)")
        if let architecture {
            specifier = specifier.adding("arch", architecture)
        }
        return specifier
    }

    /// A device or simulator, by the identifier shown in Xcode's Devices
    /// window or by `xcrun simctl list` (`id=…`).
    public static func device(identifier: String) -> DestinationSpecifier {
        DestinationSpecifier(rawValue: "id=\(identifier)")
    }

    /// The Mac that runs xcodebuild, which Xcode calls My Mac (`platform=macOS`).
    ///
    /// - Parameters:
    ///   - architecture: The architecture, such as `arm64` or `x86_64`.
    ///   - variant: The variant, such as `Mac Catalyst` or `macOS`.
    public static func macOS(architecture: String? = nil, variant: String? = nil) -> DestinationSpecifier {
        var specifier = DestinationSpecifier(rawValue: "platform=macOS")
        if let architecture {
            specifier = specifier.adding("arch", architecture)
        }
        if let variant {
            specifier = specifier.adding("variant", variant)
        }
        return specifier
    }

    /// The DriverKit environment (`platform=DriverKit`).
    ///
    /// - Parameter architecture: The architecture, such as `arm64` or `x86_64`.
    public static func driverKit(architecture: String? = nil) -> DestinationSpecifier {
        var specifier = DestinationSpecifier(rawValue: "platform=DriverKit")
        if let architecture {
            specifier = specifier.adding("arch", architecture)
        }
        return specifier
    }
}

extension DestinationSpecifier: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

/// A platform in a destination specifier, such as `iOS` or `macOS`.
public struct DestinationPlatform: RawRepresentable, Sendable, Hashable {
    /// The platform as xcodebuild spells it.
    public var rawValue: String

    /// Creates a platform from its xcodebuild spelling.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// iOS and iPadOS.
    public static var iOS: DestinationPlatform {
        DestinationPlatform(rawValue: "iOS")
    }

    /// macOS.
    public static var macOS: DestinationPlatform {
        DestinationPlatform(rawValue: "macOS")
    }

    /// tvOS.
    public static var tvOS: DestinationPlatform {
        DestinationPlatform(rawValue: "tvOS")
    }

    /// watchOS.
    public static var watchOS: DestinationPlatform {
        DestinationPlatform(rawValue: "watchOS")
    }

    /// visionOS.
    public static var visionOS: DestinationPlatform {
        DestinationPlatform(rawValue: "visionOS")
    }

    /// DriverKit.
    public static var driverKit: DestinationPlatform {
        DestinationPlatform(rawValue: "DriverKit")
    }
}

extension DestinationPlatform: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}
