public import System

// Components for options that several commands share. Each is generic over
// the command and requires the protocol of its option; the builder infers
// the command.

/// Works on an Xcode project (`-project`).
public struct Project<Command: ProjectContainerSelecting>: XcodeBuildCommandComponent {
    /// The path of the `.xcodeproj`.
    public var path: FilePath

    /// Creates the component.
    public init(_ path: FilePath) {
        self.path = path
    }

    public func apply(to command: inout Command) {
        command.container = .project(path)
    }
}

/// Works on a workspace (`-workspace`).
public struct Workspace<Command: ProjectContainerSelecting>: XcodeBuildCommandComponent {
    /// The path of the `.xcworkspace`.
    public var path: FilePath

    /// Creates the component.
    public init(_ path: FilePath) {
        self.path = path
    }

    public func apply(to command: inout Command) {
        command.container = .workspace(path)
    }
}

/// Works on a scheme (`-scheme`).
public struct Scheme<Command: SchemeSelecting>: XcodeBuildCommandComponent {
    /// The name of the scheme.
    public var name: String

    /// Creates the component.
    public init(_ name: String) {
        self.name = name
    }

    public func apply(to command: inout Command) {
        command.scheme = name
    }
}

/// Adds a target to build without a scheme (`-target`).
public struct Target<Command: TargetSelecting>: XcodeBuildCommandComponent {
    /// The name of the target.
    public var name: String

    /// Creates the component.
    public init(_ name: String) {
        self.name = name
    }

    public func apply(to command: inout Command) {
        if case .targets(let names) = command.targets {
            command.targets = .targets(names + [name])
        } else {
            command.targets = .targets([name])
        }
    }
}

/// Builds every target of the project (`-alltargets`).
public struct AllTargets<Command: TargetSelecting>: XcodeBuildCommandComponent {
    /// Creates the component.
    public init() {}

    public func apply(to command: inout Command) {
        command.targets = .allTargets
    }
}

/// Uses a build configuration, such as `Release` (`-configuration`).
public struct BuildConfiguration<Command: BuildConfigurationSelecting>: XcodeBuildCommandComponent {
    /// The name of the build configuration.
    public var name: String

    /// Creates the component.
    public init(_ name: String) {
        self.name = name
    }

    public func apply(to command: inout Command) {
        command.configuration = name
    }
}

/// Uses an SDK, by canonical name such as `iphoneos` or by path (`-sdk`).
public struct SDK<Command: SDKSelecting>: XcodeBuildCommandComponent {
    /// The canonical name or path of the SDK.
    public var name: String

    /// Creates the component.
    public init(_ name: String) {
        self.name = name
    }

    public func apply(to command: inout Command) {
        command.sdk = name
    }
}

/// Adds an architecture to build for, such as `arm64` (`-arch`).
public struct Architecture<Command: ArchitectureSelecting>: XcodeBuildCommandComponent {
    /// The architecture.
    public var name: String

    /// Creates the component.
    public init(_ name: String) {
        self.name = name
    }

    public func apply(to command: inout Command) {
        command.architectures.append(name)
    }
}

/// Adds a destination (`-destination`).
public struct Destination<Command: DestinationSelecting>: XcodeBuildCommandComponent {
    /// The destination.
    public var specifier: DestinationSpecifier

    /// Creates the component.
    public init(_ specifier: DestinationSpecifier) {
        self.specifier = specifier
    }

    public func apply(to command: inout Command) {
        command.destinations.append(specifier)
    }
}

/// Sets how long to search for a destination device, in whole seconds (`-destination-timeout`).
public struct DestinationTimeout<Command: DestinationSelecting>: XcodeBuildCommandComponent {
    /// The timeout.
    public var timeout: Duration

    /// Creates the component.
    public init(_ timeout: Duration) {
        self.timeout = timeout
    }

    public func apply(to command: inout Command) {
        command.destinationTimeout = timeout
    }
}

/// Overrides a build setting (`NAME=value`).
///
/// The assignment is appended; when a setting is assigned more than once,
/// the last assignment wins.
public struct BuildSetting<Command: BuildSettingOverriding>: XcodeBuildCommandComponent {
    /// The name of the build setting, such as `CODE_SIGNING_ALLOWED`.
    public var name: String

    /// The value.
    public var value: String

    /// Creates the component.
    public init(_ name: String, _ value: String) {
        self.name = name
        self.value = value
    }

    public func apply(to command: inout Command) {
        command.buildSettings.append(name: name, value: value)
    }
}

/// Applies an xcconfig file whose settings override all others (`-xcconfig`).
public struct XCConfig<Command: BuildSettingOverriding>: XcodeBuildCommandComponent {
    /// The path of the xcconfig file.
    public var path: FilePath

    /// Creates the component.
    public init(_ path: FilePath) {
        self.path = path
    }

    public func apply(to command: inout Command) {
        command.xcconfig = path
    }
}

/// Uses a toolchain, by identifier or name (`-toolchain`).
public struct Toolchain<Command: ToolchainSelecting>: XcodeBuildCommandComponent {
    /// The identifier or name of the toolchain.
    public var identifier: String

    /// Creates the component.
    public init(_ identifier: String) {
        self.identifier = identifier
    }

    public func apply(to command: inout Command) {
        command.toolchain = identifier
    }
}

/// Puts derived data in a directory (`-derivedDataPath`).
public struct DerivedDataPath<Command: DerivedDataLocating>: XcodeBuildCommandComponent {
    /// The directory.
    public var path: FilePath

    /// Creates the component.
    public init(_ path: FilePath) {
        self.path = path
    }

    public func apply(to command: inout Command) {
        command.derivedDataPath = path
    }
}

/// Writes the product to a path (`-exportPath`).
public struct ExportPath<Command: ExportPathSelecting>: XcodeBuildCommandComponent {
    /// The path.
    public var path: FilePath

    /// Creates the component.
    public init(_ path: FilePath) {
        self.path = path
    }

    public func apply(to command: inout Command) {
        command.exportPath = path
    }
}

/// Works on a specific build of a component or platform (`-buildVersion`).
public struct BuildVersion<Command: BuildVersionSelecting>: XcodeBuildCommandComponent {
    /// The build version.
    public var version: String

    /// Creates the component.
    public init(_ version: String) {
        self.version = version
    }

    public func apply(to command: inout Command) {
        command.buildVersion = version
    }
}

/// Chooses the architectures of a simulator runtime (`-architectureVariant`).
public struct ArchitectureVariant<Command: ArchitectureVariantSelecting>: XcodeBuildCommandComponent {
    /// The architectures.
    public var variant: SimulatorArchitectureVariant

    /// Creates the component.
    public init(_ variant: SimulatorArchitectureVariant) {
        self.variant = variant
    }

    public func apply(to command: inout Command) {
        command.architectureVariant = variant
    }
}

/// Prints only warnings and errors (`-quiet`).
public struct Quiet<Command: LogVerbositySelecting>: XcodeBuildCommandComponent {
    /// Creates the component.
    public init() {}

    public func apply(to command: inout Command) {
        command.verbosity = .quiet
    }
}

/// Prints additional status output (`-verbose`).
public struct Verbose<Command: LogVerbositySelecting>: XcodeBuildCommandComponent {
    /// Creates the component.
    public init() {}

    public func apply(to command: inout Command) {
        command.verbosity = .verbose
    }
}

/// Overrides a user default for this run of xcodebuild (`-NAME=value`).
///
/// The assignment is appended; when a default is assigned more than once,
/// the last assignment wins.
public struct UserDefaultOverride<Command: UserDefaultOverriding>: XcodeBuildCommandComponent {
    /// The name of the user default, such as `IDEPackageSupportUseBuiltinSCM`.
    public var name: String

    /// The value.
    public var value: String

    /// Creates the component.
    public init(_ name: String, _ value: String) {
        self.name = name
        self.value = value
    }

    public func apply(to command: inout Command) {
        command.userDefaults.append(name: name, value: value)
    }
}

/// Appends arguments that this library doesn't model.
public struct AdditionalArguments<Command: AdditionalArgumentsAccepting>: XcodeBuildCommandComponent {
    /// The arguments.
    public var arguments: [String]

    /// Creates the component.
    public init(_ arguments: String...) {
        self.arguments = arguments
    }

    /// Creates the component.
    public init(_ arguments: [String]) {
        self.arguments = arguments
    }

    public func apply(to command: inout Command) {
        command.additionalArguments.append(contentsOf: arguments)
    }
}
