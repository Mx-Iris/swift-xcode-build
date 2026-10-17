public import System

/// Downloads and installs the simulator runtime of a platform (`-downloadPlatform`).
///
/// With ``exportPath``, xcodebuild writes the runtime disk image there
/// instead of installing it; ``ImportPlatformCommand`` installs it later.
public struct DownloadPlatformCommand: XcodeBuildActionCommand, ExportPathSelecting, BuildVersionSelecting,
    ArchitectureVariantSelecting, LogVerbositySelecting, UserDefaultOverriding, AdditionalArgumentsAccepting
{
    public typealias Output = XcodeBuildSummary

    /// The platform.
    public var platform: DownloadablePlatform

    /// Where to write the runtime disk image instead of installing it (`-exportPath`).
    public var exportPath: FilePath?

    /// The version of the runtime, such as `27.0`, or `nil` for the one matching this Xcode (`-buildVersion`).
    public var buildVersion: String?

    public var architectureVariant: SimulatorArchitectureVariant?

    public var verbosity: LogVerbosity?

    public var userDefaults: SettingAssignments

    public var additionalArguments: [String]

    /// Creates a command that downloads a platform.
    public init(platform: DownloadablePlatform) {
        self.platform = platform
        self.userDefaults = SettingAssignments()
        self.additionalArguments = []
    }

    /// Creates a command that downloads a platform, with options described by components.
    public init(
        platform: DownloadablePlatform,
        @XcodeBuildCommandBuilder<DownloadPlatformCommand> options: () -> XcodeBuildCommandContent<DownloadPlatformCommand>
    ) {
        self.init(platform: platform)
        options().apply(to: &self)
    }

    public var arguments: [String] {
        var writer = ArgumentWriter()
        writer.option("-downloadPlatform", platform)
        writer.option("-exportPath", exportPath)
        writer.option("-buildVersion", buildVersion)
        writer.option("-architectureVariant", architectureVariant)
        verbosity?.render(into: &writer)
        userDefaults.renderUserDefaults(into: &writer)
        writer.append(contentsOf: additionalArguments)
        return writer.arguments
    }
}

/// Downloads and installs a simulator runtime for every platform this Xcode supports (`-downloadAllPlatforms`).
public struct DownloadAllPlatformsCommand: XcodeBuildActionCommand, ExportPathSelecting,
    ArchitectureVariantSelecting, LogVerbositySelecting, UserDefaultOverriding, AdditionalArgumentsAccepting
{
    public typealias Output = XcodeBuildSummary

    /// Where to write the runtime disk images instead of installing them (`-exportPath`).
    public var exportPath: FilePath?

    public var architectureVariant: SimulatorArchitectureVariant?

    public var verbosity: LogVerbosity?

    public var userDefaults: SettingAssignments

    public var additionalArguments: [String]

    /// Creates a command that downloads every platform.
    public init() {
        self.userDefaults = SettingAssignments()
        self.additionalArguments = []
    }

    /// Creates a command that downloads every platform, with options described by components.
    public init(
        @XcodeBuildCommandBuilder<DownloadAllPlatformsCommand> options: () -> XcodeBuildCommandContent<DownloadAllPlatformsCommand>
    ) {
        self.init()
        options().apply(to: &self)
    }

    public var arguments: [String] {
        var writer = ArgumentWriter()
        writer.append("-downloadAllPlatforms")
        writer.option("-exportPath", exportPath)
        writer.option("-architectureVariant", architectureVariant)
        verbosity?.render(into: &writer)
        userDefaults.renderUserDefaults(into: &writer)
        writer.append(contentsOf: additionalArguments)
        return writer.arguments
    }
}

extension XcodeBuildActionCommand where Self == DownloadAllPlatformsCommand {
    /// Downloads and installs a simulator runtime for every platform this Xcode supports.
    public static var downloadAllPlatforms: DownloadAllPlatformsCommand {
        DownloadAllPlatformsCommand()
    }
}

/// Installs a simulator runtime from a disk image (`-importPlatform`).
public struct ImportPlatformCommand: XcodeBuildActionCommand, LogVerbositySelecting, UserDefaultOverriding,
    AdditionalArgumentsAccepting
{
    public typealias Output = XcodeBuildSummary

    /// The simulator runtime disk image.
    public var path: FilePath

    public var verbosity: LogVerbosity?

    public var userDefaults: SettingAssignments

    public var additionalArguments: [String]

    /// Creates a command that imports a simulator runtime.
    public init(path: FilePath) {
        self.path = path
        self.userDefaults = SettingAssignments()
        self.additionalArguments = []
    }

    /// Creates a command that imports a simulator runtime, with options described by components.
    public init(
        path: FilePath,
        @XcodeBuildCommandBuilder<ImportPlatformCommand> options: () -> XcodeBuildCommandContent<ImportPlatformCommand>
    ) {
        self.init(path: path)
        options().apply(to: &self)
    }

    public var arguments: [String] {
        var writer = ArgumentWriter()
        writer.option("-importPlatform", path)
        verbosity?.render(into: &writer)
        userDefaults.renderUserDefaults(into: &writer)
        writer.append(contentsOf: additionalArguments)
        return writer.arguments
    }
}

/// Downloads and installs an optional component, such as the Metal toolchain (`-downloadComponent`).
public struct DownloadComponentCommand: XcodeBuildActionCommand, ExportPathSelecting, BuildVersionSelecting,
    LogVerbositySelecting, UserDefaultOverriding, AdditionalArgumentsAccepting
{
    public typealias Output = XcodeBuildSummary

    /// The component.
    public var component: DownloadableComponent

    /// Where to write the component instead of installing it (`-exportPath`).
    public var exportPath: FilePath?

    /// The build of the component, or `nil` for the one matching this Xcode (`-buildVersion`).
    public var buildVersion: String?

    public var verbosity: LogVerbosity?

    public var userDefaults: SettingAssignments

    public var additionalArguments: [String]

    /// Creates a command that downloads a component.
    public init(component: DownloadableComponent) {
        self.component = component
        self.userDefaults = SettingAssignments()
        self.additionalArguments = []
    }

    /// Creates a command that downloads a component, with options described by components.
    public init(
        component: DownloadableComponent,
        @XcodeBuildCommandBuilder<DownloadComponentCommand> options: () -> XcodeBuildCommandContent<DownloadComponentCommand>
    ) {
        self.init(component: component)
        options().apply(to: &self)
    }

    public var arguments: [String] {
        var writer = ArgumentWriter()
        writer.option("-downloadComponent", component)
        writer.option("-exportPath", exportPath)
        writer.option("-buildVersion", buildVersion)
        verbosity?.render(into: &writer)
        userDefaults.renderUserDefaults(into: &writer)
        writer.append(contentsOf: additionalArguments)
        return writer.arguments
    }
}

/// Installs an optional component from a bundle that ``DownloadComponentCommand`` exported (`-importComponent`).
public struct ImportComponentCommand: XcodeBuildActionCommand, LogVerbositySelecting, UserDefaultOverriding,
    AdditionalArgumentsAccepting
{
    public typealias Output = XcodeBuildSummary

    /// The component.
    public var component: DownloadableComponent

    /// The bundle to install (`-importPath`).
    public var importPath: FilePath

    public var verbosity: LogVerbosity?

    public var userDefaults: SettingAssignments

    public var additionalArguments: [String]

    /// Creates a command that imports a component.
    public init(component: DownloadableComponent, importPath: FilePath) {
        self.component = component
        self.importPath = importPath
        self.userDefaults = SettingAssignments()
        self.additionalArguments = []
    }

    /// Creates a command that imports a component, with options described by components.
    public init(
        component: DownloadableComponent,
        importPath: FilePath,
        @XcodeBuildCommandBuilder<ImportComponentCommand> options: () -> XcodeBuildCommandContent<ImportComponentCommand>
    ) {
        self.init(component: component, importPath: importPath)
        options().apply(to: &self)
    }

    public var arguments: [String] {
        var writer = ArgumentWriter()
        writer.option("-importComponent", component)
        writer.option("-importPath", importPath)
        verbosity?.render(into: &writer)
        userDefaults.renderUserDefaults(into: &writer)
        writer.append(contentsOf: additionalArguments)
        return writer.arguments
    }
}

/// Deletes an installed optional component (`-deleteComponent`).
public struct DeleteComponentCommand: XcodeBuildActionCommand, BuildVersionSelecting, LogVerbositySelecting,
    UserDefaultOverriding, AdditionalArgumentsAccepting
{
    public typealias Output = XcodeBuildSummary

    /// The component.
    public var component: DownloadableComponent

    /// The build of the component to delete, or `nil` for the one matching
    /// this Xcode (`-buildVersion`). Xcode 27 and later.
    public var buildVersion: String?

    public var verbosity: LogVerbosity?

    public var userDefaults: SettingAssignments

    public var additionalArguments: [String]

    /// Creates a command that deletes a component.
    public init(component: DownloadableComponent) {
        self.component = component
        self.userDefaults = SettingAssignments()
        self.additionalArguments = []
    }

    /// Creates a command that deletes a component, with options described by components.
    public init(
        component: DownloadableComponent,
        @XcodeBuildCommandBuilder<DeleteComponentCommand> options: () -> XcodeBuildCommandContent<DeleteComponentCommand>
    ) {
        self.init(component: component)
        options().apply(to: &self)
    }

    public var arguments: [String] {
        var writer = ArgumentWriter()
        writer.option("-deleteComponent", component)
        writer.option("-buildVersion", buildVersion)
        verbosity?.render(into: &writer)
        userDefaults.renderUserDefaults(into: &writer)
        writer.append(contentsOf: additionalArguments)
        return writer.arguments
    }
}

/// Prepares the device support symbols for a device's operating system (`-prepareDeviceSupport`).
public struct PrepareDeviceSupportCommand: XcodeBuildActionCommand, LogVerbositySelecting, UserDefaultOverriding,
    AdditionalArgumentsAccepting
{
    public typealias Output = XcodeBuildSummary

    /// The platform of the device, such as ``DestinationPlatform/iOS`` (`-platform`).
    public var platform: DestinationPlatform

    /// The operating system version, such as `26.2` (`-osVersion`).
    public var operatingSystemVersion: String

    /// The model code of the device, such as `iPhone16,1` (`-modelCode`).
    public var modelCode: String?

    /// The architecture of the device, such as `arm64e` (`-architecture`).
    public var architecture: String?

    public var verbosity: LogVerbosity?

    public var userDefaults: SettingAssignments

    public var additionalArguments: [String]

    /// Creates a command that prepares device support.
    ///
    /// - Parameters:
    ///   - platform: The platform of the device.
    ///   - operatingSystemVersion: The operating system version, such as `26.2`.
    public init(platform: DestinationPlatform, operatingSystemVersion: String) {
        self.platform = platform
        self.operatingSystemVersion = operatingSystemVersion
        self.userDefaults = SettingAssignments()
        self.additionalArguments = []
    }

    /// Creates a command that prepares device support, with options described by components.
    public init(
        platform: DestinationPlatform,
        operatingSystemVersion: String,
        @XcodeBuildCommandBuilder<PrepareDeviceSupportCommand> options: () -> XcodeBuildCommandContent<PrepareDeviceSupportCommand>
    ) {
        self.init(platform: platform, operatingSystemVersion: operatingSystemVersion)
        options().apply(to: &self)
    }

    public var arguments: [String] {
        var writer = ArgumentWriter()
        writer.append("-prepareDeviceSupport")
        writer.option("-platform", platform)
        writer.option("-osVersion", operatingSystemVersion)
        writer.option("-modelCode", modelCode)
        writer.option("-architecture", architecture)
        verbosity?.render(into: &writer)
        userDefaults.renderUserDefaults(into: &writer)
        writer.append(contentsOf: additionalArguments)
        return writer.arguments
    }
}

/// Installs the system packages Xcode needs and agrees to the license (`-runFirstLaunch`).
///
/// Installing packages and agreeing to the license require administrator
/// privileges.
public struct RunFirstLaunchCommand: XcodeBuildActionCommand, LogVerbositySelecting, UserDefaultOverriding,
    AdditionalArgumentsAccepting
{
    public typealias Output = XcodeBuildSummary

    /// Whether to also check for newer device support components (`-checkForNewerComponents`).
    public var checkForNewerComponents: Bool

    public var verbosity: LogVerbosity?

    public var userDefaults: SettingAssignments

    public var additionalArguments: [String]

    /// Creates a command that runs the first launch tasks.
    public init(checkForNewerComponents: Bool = false) {
        self.checkForNewerComponents = checkForNewerComponents
        self.userDefaults = SettingAssignments()
        self.additionalArguments = []
    }

    /// Creates a command that runs the first launch tasks, with options described by components.
    public init(@XcodeBuildCommandBuilder<RunFirstLaunchCommand> options: () -> XcodeBuildCommandContent<RunFirstLaunchCommand>) {
        self.init()
        options().apply(to: &self)
    }

    public var arguments: [String] {
        var writer = ArgumentWriter()
        writer.append("-runFirstLaunch")
        writer.flag("-checkForNewerComponents", checkForNewerComponents)
        verbosity?.render(into: &writer)
        userDefaults.renderUserDefaults(into: &writer)
        writer.append(contentsOf: additionalArguments)
        return writer.arguments
    }
}

extension XcodeBuildActionCommand where Self == RunFirstLaunchCommand {
    /// Installs the system packages Xcode needs and agrees to the license.
    public static var runFirstLaunch: RunFirstLaunchCommand {
        RunFirstLaunchCommand()
    }
}

/// Accepts the Xcode and SDK license agreements without showing them (`-license accept`).
///
/// Requires administrator privileges: run the process as root, or xcodebuild fails.
public struct AcceptLicenseCommand: XcodeBuildActionCommand, UserDefaultOverriding, AdditionalArgumentsAccepting {
    public typealias Output = XcodeBuildSummary

    public var userDefaults: SettingAssignments

    public var additionalArguments: [String]

    /// Creates a command that accepts the license agreements.
    public init() {
        self.userDefaults = SettingAssignments()
        self.additionalArguments = []
    }

    /// Creates a command that accepts the license agreements, with options described by components.
    public init(@XcodeBuildCommandBuilder<AcceptLicenseCommand> options: () -> XcodeBuildCommandContent<AcceptLicenseCommand>) {
        self.init()
        options().apply(to: &self)
    }

    public var arguments: [String] {
        var writer = ArgumentWriter()
        writer.append("-license", "accept")
        userDefaults.renderUserDefaults(into: &writer)
        writer.append(contentsOf: additionalArguments)
        return writer.arguments
    }
}

extension XcodeBuildActionCommand where Self == AcceptLicenseCommand {
    /// Accepts the Xcode and SDK license agreements.
    public static var acceptLicense: AcceptLicenseCommand {
        AcceptLicenseCommand()
    }
}
