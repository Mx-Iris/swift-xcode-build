public import System

/// Lists the targets, configurations, and schemes of a project, or the schemes of a workspace (`-list`).
///
/// ```swift
/// let listing = try await xcodebuild.run(ListCommand(.workspace("App.xcworkspace")))
/// print(listing.schemes)
/// ```
public struct ListCommand: XcodeBuildQueryCommand, ProjectContainerSelecting, UserDefaultOverriding,
    AdditionalArgumentsAccepting
{
    public typealias Output = ListResult

    public var container: ProjectContainer

    public var userDefaults: SettingAssignments

    public var additionalArguments: [String]

    /// Creates a list command.
    public init(_ container: ProjectContainer = .automatic) {
        self.container = container
        self.userDefaults = SettingAssignments()
        self.additionalArguments = []
    }

    /// Creates a list command with options described by components.
    public init(@XcodeBuildCommandBuilder<ListCommand> options: () -> XcodeBuildCommandContent<ListCommand>) {
        self.init()
        options().apply(to: &self)
    }

    public var arguments: [String] {
        var writer = ArgumentWriter()
        writer.append("-list", "-json")
        container.render(into: &writer)
        userDefaults.renderUserDefaults(into: &writer)
        writer.append(contentsOf: additionalArguments)
        return writer.arguments
    }

    public func output(from completion: XcodeBuildCompletion) throws(XcodeBuildError) -> ListResult {
        try completion.requireSuccess()
        let listing = try completion.decodeJSON(ListJSON.self)
        if let project = listing.project {
            return .project(
                ProjectListing(
                    name: project.name,
                    targets: project.targets ?? [],
                    configurations: project.configurations ?? [],
                    schemes: project.schemes ?? []
                )
            )
        }
        if let workspace = listing.workspace {
            return .workspace(WorkspaceListing(name: workspace.name, schemes: workspace.schemes ?? []))
        }
        throw completion.unexpectedOutput("the JSON has neither a project nor a workspace")
    }
}

extension XcodeBuildQueryCommand where Self == ListCommand {
    /// Lists the project, workspace, or package in the working directory.
    public static var list: ListCommand {
        ListCommand()
    }
}

/// Shows the build settings of a scheme's or project's targets (`-showBuildSettings`).
///
/// ```swift
/// let settings = try await xcodebuild.run(ShowBuildSettingsCommand {
///     Workspace("App.xcworkspace")
///     Scheme("App")
///     BuildConfiguration("Release")
/// })
/// let bundleIdentifier = settings.first?["PRODUCT_BUNDLE_IDENTIFIER"]
/// ```
public struct ShowBuildSettingsCommand: XcodeBuildQueryCommand, ProjectContainerSelecting, SchemeSelecting,
    TargetSelecting, BuildConfigurationSelecting, SDKSelecting, ArchitectureSelecting, DestinationSelecting,
    BuildSettingOverriding, ToolchainSelecting, DerivedDataLocating, PackageResolutionConfigurable,
    UserDefaultOverriding, AdditionalArgumentsAccepting
{
    public typealias Output = [TargetBuildSettings]

    public var container: ProjectContainer

    public var scheme: String?

    public var targets: TargetSelection?

    /// With a scheme, the action whose targets to show, such as ``BuildAction/test``.
    public var action: BuildAction?

    public var configuration: String?

    public var sdk: String?

    public var architectures: [String]

    public var destinations: [DestinationSpecifier]

    public var destinationTimeout: Duration?

    public var buildSettings: SettingAssignments

    public var xcconfig: FilePath?

    public var toolchain: String?

    public var derivedDataPath: FilePath?

    public var packageResolution: PackageResolutionOptions

    public var userDefaults: SettingAssignments

    public var additionalArguments: [String]

    /// Creates a command that shows build settings.
    public init(container: ProjectContainer = .automatic, scheme: String? = nil) {
        self.container = container
        self.scheme = scheme
        self.architectures = []
        self.destinations = []
        self.buildSettings = SettingAssignments()
        self.packageResolution = PackageResolutionOptions()
        self.userDefaults = SettingAssignments()
        self.additionalArguments = []
    }

    /// Creates a command that shows build settings, with options described by components.
    public init(@XcodeBuildCommandBuilder<ShowBuildSettingsCommand> options: () -> XcodeBuildCommandContent<ShowBuildSettingsCommand>) {
        self.init()
        options().apply(to: &self)
    }

    public var arguments: [String] {
        var writer = ArgumentWriter()
        writer.append("-showBuildSettings", "-json")
        container.render(into: &writer)
        writer.option("-scheme", scheme)
        targets?.render(into: &writer)
        writer.option("-configuration", configuration)
        writer.option("-xcconfig", xcconfig)
        writer.repeatedOption("-arch", architectures)
        writer.option("-sdk", sdk)
        writer.option("-toolchain", toolchain)
        writer.repeatedOption("-destination", destinations.map(\.rawValue))
        writer.option("-destination-timeout", seconds: destinationTimeout)
        writer.option("-derivedDataPath", derivedDataPath)
        packageResolution.render(into: &writer)
        if let action {
            writer.append(action.rawValue)
        }
        buildSettings.renderBuildSettings(into: &writer)
        userDefaults.renderUserDefaults(into: &writer)
        writer.append(contentsOf: additionalArguments)
        return writer.arguments
    }

    public func output(from completion: XcodeBuildCompletion) throws(XcodeBuildError) -> [TargetBuildSettings] {
        try completion.requireSuccess()
        return try completion.decodeJSON([TargetBuildSettingsJSON].self).map(\.settings)
    }
}

/// Shows the build settings that the index service uses, per target and source file (`-showBuildSettingsForIndex`).
///
/// The result is the JSON that xcodebuild prints. Its structure is not
/// documented and changes between Xcode versions.
public struct ShowBuildSettingsForIndexCommand: XcodeBuildQueryCommand, ProjectContainerSelecting, SchemeSelecting,
    BuildConfigurationSelecting, SDKSelecting, ArchitectureSelecting, DestinationSelecting, BuildSettingOverriding,
    ToolchainSelecting, DerivedDataLocating, PackageResolutionConfigurable, UserDefaultOverriding,
    AdditionalArgumentsAccepting
{
    public typealias Output = String

    public var container: ProjectContainer

    public var scheme: String?

    public var configuration: String?

    public var sdk: String?

    public var architectures: [String]

    public var destinations: [DestinationSpecifier]

    public var destinationTimeout: Duration?

    public var buildSettings: SettingAssignments

    public var xcconfig: FilePath?

    public var toolchain: String?

    public var derivedDataPath: FilePath?

    public var packageResolution: PackageResolutionOptions

    public var userDefaults: SettingAssignments

    public var additionalArguments: [String]

    /// Creates a command that shows build settings for the index service.
    public init(container: ProjectContainer = .automatic, scheme: String? = nil) {
        self.container = container
        self.scheme = scheme
        self.architectures = []
        self.destinations = []
        self.buildSettings = SettingAssignments()
        self.packageResolution = PackageResolutionOptions()
        self.userDefaults = SettingAssignments()
        self.additionalArguments = []
    }

    /// Creates a command that shows build settings for the index service, with options described by components.
    public init(
        @XcodeBuildCommandBuilder<ShowBuildSettingsForIndexCommand> options: () -> XcodeBuildCommandContent<ShowBuildSettingsForIndexCommand>
    ) {
        self.init()
        options().apply(to: &self)
    }

    public var arguments: [String] {
        var writer = ArgumentWriter()
        writer.append("-showBuildSettingsForIndex", "-json")
        container.render(into: &writer)
        writer.option("-scheme", scheme)
        writer.option("-configuration", configuration)
        writer.option("-xcconfig", xcconfig)
        writer.repeatedOption("-arch", architectures)
        writer.option("-sdk", sdk)
        writer.option("-toolchain", toolchain)
        writer.repeatedOption("-destination", destinations.map(\.rawValue))
        writer.option("-destination-timeout", seconds: destinationTimeout)
        writer.option("-derivedDataPath", derivedDataPath)
        packageResolution.render(into: &writer)
        buildSettings.renderBuildSettings(into: &writer)
        userDefaults.renderUserDefaults(into: &writer)
        writer.append(contentsOf: additionalArguments)
        return writer.arguments
    }

    public func output(from completion: XcodeBuildCompletion) throws(XcodeBuildError) -> String {
        try completion.requireSuccess()
        return completion.trimmedStandardOutputText
    }
}

/// Lists the destinations a scheme can build or test for (`-showdestinations`).
///
/// ```swift
/// let destinations = try await xcodebuild.run(ShowDestinationsCommand(scheme: "App"))
/// let simulator = destinations.compatible.first { $0.platform == "iOS Simulator" }
/// ```
public struct ShowDestinationsCommand: XcodeBuildQueryCommand, ProjectContainerSelecting, DerivedDataLocating,
    PackageResolutionConfigurable, UserDefaultOverriding, AdditionalArgumentsAccepting
{
    public typealias Output = DestinationList

    public var container: ProjectContainer

    /// The scheme whose destinations to list (`-scheme`).
    public var scheme: String

    public var derivedDataPath: FilePath?

    public var packageResolution: PackageResolutionOptions

    public var userDefaults: SettingAssignments

    public var additionalArguments: [String]

    /// Creates a command that lists destinations.
    public init(container: ProjectContainer = .automatic, scheme: String) {
        self.container = container
        self.scheme = scheme
        self.packageResolution = PackageResolutionOptions()
        self.userDefaults = SettingAssignments()
        self.additionalArguments = []
    }

    /// Creates a command that lists destinations, with options described by components.
    public init(
        scheme: String,
        @XcodeBuildCommandBuilder<ShowDestinationsCommand> options: () -> XcodeBuildCommandContent<ShowDestinationsCommand>
    ) {
        self.init(scheme: scheme)
        options().apply(to: &self)
    }

    public var arguments: [String] {
        var writer = ArgumentWriter()
        writer.append("-showdestinations")
        container.render(into: &writer)
        writer.option("-scheme", scheme)
        writer.option("-derivedDataPath", derivedDataPath)
        packageResolution.render(into: &writer)
        userDefaults.renderUserDefaults(into: &writer)
        writer.append(contentsOf: additionalArguments)
        return writer.arguments
    }

    public func output(from completion: XcodeBuildCompletion) throws(XcodeBuildError) -> DestinationList {
        try completion.requireSuccess()
        guard let list = DestinationListParser.parse(completion.standardOutputText) else {
            throw completion.unexpectedOutput("destinations were listed outside a known section")
        }
        return list
    }
}

/// Lists the test plans of a scheme (`-showTestPlans`).
public struct ShowTestPlansCommand: XcodeBuildQueryCommand, ProjectContainerSelecting, DerivedDataLocating,
    PackageResolutionConfigurable, UserDefaultOverriding, AdditionalArgumentsAccepting
{
    /// The names of the test plans.
    public typealias Output = [String]

    public var container: ProjectContainer

    /// The scheme whose test plans to list (`-scheme`).
    public var scheme: String

    public var derivedDataPath: FilePath?

    public var packageResolution: PackageResolutionOptions

    public var userDefaults: SettingAssignments

    public var additionalArguments: [String]

    /// Creates a command that lists test plans.
    public init(container: ProjectContainer = .automatic, scheme: String) {
        self.container = container
        self.scheme = scheme
        self.packageResolution = PackageResolutionOptions()
        self.userDefaults = SettingAssignments()
        self.additionalArguments = []
    }

    /// Creates a command that lists test plans, with options described by components.
    public init(
        scheme: String,
        @XcodeBuildCommandBuilder<ShowTestPlansCommand> options: () -> XcodeBuildCommandContent<ShowTestPlansCommand>
    ) {
        self.init(scheme: scheme)
        options().apply(to: &self)
    }

    public var arguments: [String] {
        var writer = ArgumentWriter()
        writer.append("-showTestPlans", "-json")
        container.render(into: &writer)
        writer.option("-scheme", scheme)
        writer.option("-derivedDataPath", derivedDataPath)
        packageResolution.render(into: &writer)
        userDefaults.renderUserDefaults(into: &writer)
        writer.append(contentsOf: additionalArguments)
        return writer.arguments
    }

    public func output(from completion: XcodeBuildCompletion) throws(XcodeBuildError) -> [String] {
        try completion.requireSuccess()
        return try completion.decodeJSON(TestPlansJSON.self).testPlans.map(\.name)
    }
}
