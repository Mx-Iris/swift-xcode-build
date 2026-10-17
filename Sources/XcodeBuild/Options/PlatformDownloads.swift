/// A platform whose simulator runtime xcodebuild can download or import.
public struct DownloadablePlatform: RawRepresentable, Sendable, Hashable {
    /// The platform as xcodebuild spells it.
    public var rawValue: String

    /// Creates a platform from its xcodebuild spelling.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// iOS.
    public static var iOS: DownloadablePlatform {
        DownloadablePlatform(rawValue: "iOS")
    }

    /// watchOS.
    public static var watchOS: DownloadablePlatform {
        DownloadablePlatform(rawValue: "watchOS")
    }

    /// tvOS.
    public static var tvOS: DownloadablePlatform {
        DownloadablePlatform(rawValue: "tvOS")
    }

    /// visionOS.
    public static var visionOS: DownloadablePlatform {
        DownloadablePlatform(rawValue: "visionOS")
    }
}

/// An optional Xcode component that xcodebuild can download, import, show, or delete.
public struct DownloadableComponent: RawRepresentable, Sendable, Hashable {
    /// The component as xcodebuild spells it.
    public var rawValue: String

    /// Creates a component from its xcodebuild spelling.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// The Metal toolchain.
    public static var metalToolchain: DownloadableComponent {
        DownloadableComponent(rawValue: "metaltoolchain")
    }

    /// Device support files for debugging on devices. Xcode 27 and later.
    public static var deviceSupport: DownloadableComponent {
        DownloadableComponent(rawValue: "devicesupport")
    }
}

/// The architectures of a simulator runtime to download.
public struct SimulatorArchitectureVariant: RawRepresentable, Sendable, Hashable {
    /// The value as xcodebuild spells it.
    public var rawValue: String

    /// Creates a value from its xcodebuild spelling.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Apple silicon and Intel.
    public static var universal: SimulatorArchitectureVariant {
        SimulatorArchitectureVariant(rawValue: "universal")
    }

    /// Apple silicon only.
    public static var arm64: SimulatorArchitectureVariant {
        SimulatorArchitectureVariant(rawValue: "arm64")
    }
}

/// A project file format that `-convert-project` converts to.
///
/// xcodebuild accepts a format by name, such as `Xcode 16.0`, or by version
/// number. An unknown format makes xcodebuild fail and list the formats it
/// knows.
public struct ProjectFormat: RawRepresentable, Sendable, Hashable {
    /// The format as xcodebuild spells it.
    public var rawValue: String

    /// Creates a format from its xcodebuild spelling.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// The format of an Xcode version, such as `Xcode 16.0` for `xcode("16.0")`.
    public static func xcode(_ version: String) -> ProjectFormat {
        ProjectFormat(rawValue: "Xcode \(version)")
    }
}
