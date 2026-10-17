public import System

// The protocols in this file say which options a command accepts. The DSL's
// components are generic over the command and require one of them, so a
// component that a command doesn't accept is a compile-time error:
//
//     ListCommand { Scheme("App") }
//     // error: generic struct 'Scheme' requires that 'ListCommand' conform to 'SchemeSelecting'
//
// They also let you write code that works with any command accepting an
// option, such as a function that sets the derived data path.

/// A command that works on a project, workspace, or Swift package (`-project`, `-workspace`).
public protocol ProjectContainerSelecting: XcodeBuildCommand {
    /// Where xcodebuild finds the project.
    var container: ProjectContainer { get set }
}

/// A command that can work on a scheme (`-scheme`).
public protocol SchemeSelecting: XcodeBuildCommand {
    /// The scheme, or `nil` for none.
    var scheme: String? { get set }
}

/// A command that can work on targets of a project without a scheme (`-target`, `-alltargets`).
public protocol TargetSelecting: XcodeBuildCommand {
    /// The targets, or `nil` for the project's first target.
    var targets: TargetSelection? { get set }
}

/// A command that can use a build configuration (`-configuration`).
public protocol BuildConfigurationSelecting: XcodeBuildCommand {
    /// The build configuration, such as `Release`, or `nil` for the default.
    var configuration: String? { get set }
}

/// A command that can use a specific SDK (`-sdk`).
public protocol SDKSelecting: XcodeBuildCommand {
    /// The SDK, by canonical name such as `iphoneos` or `macosx27.2`, or by path.
    var sdk: String? { get set }
}

/// A command that can override the architectures to build (`-arch`).
public protocol ArchitectureSelecting: XcodeBuildCommand {
    /// The architectures, such as `arm64`, or empty for the project's.
    var architectures: [String] { get set }
}

/// A command that can use destinations (`-destination`, `-destination-timeout`).
public protocol DestinationSelecting: XcodeBuildCommand {
    /// The destinations, in order. Testing runs on each of them.
    var destinations: [DestinationSpecifier] { get set }

    /// How long to search for a destination device, in whole seconds. xcodebuild waits 30 seconds by default.
    var destinationTimeout: Duration? { get set }
}

/// A command that can override build settings (`NAME=value`, `-xcconfig`).
public protocol BuildSettingOverriding: XcodeBuildCommand {
    /// Build settings that override the project's, in command-line order.
    var buildSettings: SettingAssignments { get set }

    /// An xcconfig file whose settings override all others, including
    /// ``buildSettings``.
    var xcconfig: FilePath? { get set }
}

/// A command that can use a specific toolchain (`-toolchain`).
public protocol ToolchainSelecting: XcodeBuildCommand {
    /// The toolchain, by identifier or name.
    var toolchain: String? { get set }
}

/// A command that can put derived data in a specific directory (`-derivedDataPath`).
///
/// xcodebuild accepts the option only together with a scheme, an xctestrun
/// file, or a test products path.
public protocol DerivedDataLocating: XcodeBuildCommand {
    /// The derived data directory, or `nil` for Xcode's.
    var derivedDataPath: FilePath? { get set }
}

/// A command that can resolve Swift package dependencies.
public protocol PackageResolutionConfigurable: XcodeBuildCommand {
    /// How to resolve and fetch packages.
    var packageResolution: PackageResolutionOptions { get set }
}

/// A command that can talk to the Apple Developer website for signing.
public protocol ProvisioningConfigurable: XcodeBuildCommand {
    /// What xcodebuild may do on the developer website, and how it authenticates.
    var provisioning: ProvisioningOptions { get set }
}

/// A command whose log can be made quieter or more detailed (`-quiet`, `-verbose`).
public protocol LogVerbositySelecting: XcodeBuildCommand {
    /// How much xcodebuild prints, or `nil` for its default.
    var verbosity: LogVerbosity? { get set }
}

/// A command that can override user defaults for the xcodebuild process (`-NAME=value`).
///
/// Every command conforms.
public protocol UserDefaultOverriding: XcodeBuildCommand {
    /// User defaults that apply to this run of xcodebuild, such as
    /// `IDEPackageSupportUseBuiltinSCM`.
    var userDefaults: SettingAssignments { get set }
}

/// A command that passes arguments it doesn't model to xcodebuild.
///
/// Every command conforms.
public protocol AdditionalArgumentsAccepting: XcodeBuildCommand {
    /// Arguments appended after all others, for options this library doesn't
    /// model, such as options a newer Xcode adds.
    var additionalArguments: [String] { get set }
}

/// A command that can write its product to a chosen path (`-exportPath`).
public protocol ExportPathSelecting: XcodeBuildCommand {
    /// Where to write the product.
    var exportPath: FilePath? { get set }
}

/// A command that can work on a specific build of a component or platform (`-buildVersion`).
public protocol BuildVersionSelecting: XcodeBuildCommand {
    /// The build version, such as `27A266a`, or `nil` for the one matching this Xcode.
    var buildVersion: String? { get set }
}

/// A command that can choose the architectures of a simulator runtime (`-architectureVariant`).
public protocol ArchitectureVariantSelecting: XcodeBuildCommand {
    /// The architectures of the runtime, or `nil` for xcodebuild's default.
    var architectureVariant: SimulatorArchitectureVariant? { get set }
}
