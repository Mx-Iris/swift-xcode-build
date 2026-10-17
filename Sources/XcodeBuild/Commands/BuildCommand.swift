public import System

/// Runs build actions: `build`, `test`, `archive`, `clean`, and the others in ``BuildAction``.
///
/// ```swift
/// var test = BuildCommand(actions: [.test], container: .workspace("App.xcworkspace"), scheme: "App")
/// test.destinations = [.simulator(.iOS, name: "iPhone 17 Pro")]
/// test.testing.onlyTesting = ["AppTests/LoginTests"]
///
/// let archive = BuildCommand(.clean, .archive) {
///     Workspace("App.xcworkspace")
///     Scheme("App")
///     BuildConfiguration("Release")
///     Destination(.generic(.iOS))
///     ArchivePath("build/App.xcarchive")
/// }
/// ```
///
/// Options left `nil`, empty, or `false` are left out, so the scheme and the
/// project's settings apply. The actions run in order; with no actions,
/// xcodebuild builds.
public struct BuildCommand: XcodeBuildActionCommand, ProjectContainerSelecting, SchemeSelecting, TargetSelecting,
    BuildConfigurationSelecting, SDKSelecting, ArchitectureSelecting, DestinationSelecting, BuildSettingOverriding,
    ToolchainSelecting, DerivedDataLocating, PackageResolutionConfigurable, ProvisioningConfigurable,
    LogVerbositySelecting, UserDefaultOverriding, AdditionalArgumentsAccepting
{
    public typealias Output = XcodeBuildSummary

    /// The actions to run, in order. Empty means `build`.
    public var actions: [BuildAction]

    public var container: ProjectContainer

    /// The scheme to build (`-scheme`). Required for every action except
    /// `build`, `clean`, `install`, and `installsrc`, and for workspaces.
    public var scheme: String?

    /// The targets to build without a scheme (`-target`, `-alltargets`).
    public var targets: TargetSelection?

    /// The build configuration, such as `Debug` or `Release` (`-configuration`).
    public var configuration: String?

    public var xcconfig: FilePath?

    /// The architectures to build for, overriding the project's (`-arch`).
    public var architectures: [String]

    /// The SDK to build against, by canonical name or path (`-sdk`).
    public var sdk: String?

    /// The toolchain, by identifier or name (`-toolchain`).
    public var toolchain: String?

    public var destinations: [DestinationSpecifier]

    public var destinationTimeout: Duration?

    /// The directory for build products and other derived data (`-derivedDataPath`).
    public var derivedDataPath: FilePath?

    /// Where the `archive` action writes the archive (`-archivePath`).
    public var archivePath: FilePath?

    /// Where to write a result bundle with logs, test results, and coverage
    /// (`-resultBundlePath`). xcodebuild fails if the path exists.
    public var resultBundlePath: FilePath?

    /// The result bundle version (`-resultBundleVersion`). Only 3 exists.
    public var resultBundleVersion: Int?

    /// An existing file to write a result stream to (`-resultStreamPath`).
    public var resultStreamPath: FilePath?

    public var packageResolution: PackageResolutionOptions

    public var provisioning: ProvisioningOptions

    /// Options for `test`, `build-for-testing`, and `test-without-building`.
    public var testing: TestingOptions

    /// Sanitizers, overriding the scheme.
    public var sanitizers: SanitizerOptions

    /// Code size profiling. Xcode 27 and later.
    public var codeSizeProfile: CodeSizeProfileOptions

    /// Whether to build independent targets in parallel (`-parallelizeTargets`).
    public var parallelizeTargets: Bool

    /// The most build operations to run at once (`-jobs`).
    public var jobs: Int?

    public var verbosity: LogVerbosity?

    /// Whether to leave shell script environment variables out of the log
    /// (`-hideShellScriptEnvironment`).
    public var hideShellScriptEnvironment: Bool

    /// Whether to print how long each kind of build command took (`-showBuildTimingSummary`).
    public var showBuildTimingSummary: Bool

    /// Whether to skip scheme actions that can't be performed instead of
    /// failing (`-skipUnavailableActions`). Requires a scheme.
    public var skipUnavailableActions: Bool

    public var buildSettings: SettingAssignments

    public var userDefaults: SettingAssignments

    public var additionalArguments: [String]

    /// Creates a build command.
    ///
    /// - Parameters:
    ///   - actions: The actions to run, in order. Empty means `build`.
    ///   - container: Where xcodebuild finds the project.
    ///   - scheme: The scheme to build.
    public init(actions: [BuildAction] = [], container: ProjectContainer = .automatic, scheme: String? = nil) {
        self.actions = actions
        self.container = container
        self.scheme = scheme
        self.architectures = []
        self.destinations = []
        self.packageResolution = PackageResolutionOptions()
        self.provisioning = ProvisioningOptions()
        self.testing = TestingOptions()
        self.sanitizers = SanitizerOptions()
        self.codeSizeProfile = CodeSizeProfileOptions()
        self.parallelizeTargets = false
        self.hideShellScriptEnvironment = false
        self.showBuildTimingSummary = false
        self.skipUnavailableActions = false
        self.buildSettings = SettingAssignments()
        self.userDefaults = SettingAssignments()
        self.additionalArguments = []
    }

    /// Creates a build command that runs actions in order, with options described by components.
    ///
    /// ```swift
    /// BuildCommand(.clean, .test) {
    ///     Scheme("App")
    ///     Destination(.macOS())
    /// }
    /// ```
    public init(
        _ action: BuildAction,
        _ moreActions: BuildAction...,
        @XcodeBuildCommandBuilder<BuildCommand> options: () -> XcodeBuildCommandContent<BuildCommand> = { XcodeBuildCommandContent() }
    ) {
        self.init(actions: [action] + moreActions)
        options().apply(to: &self)
    }

    /// Creates a build command that builds, with options described by components.
    public init(@XcodeBuildCommandBuilder<BuildCommand> options: () -> XcodeBuildCommandContent<BuildCommand>) {
        self.init()
        options().apply(to: &self)
    }

    public var arguments: [String] {
        var writer = ArgumentWriter()
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
        writer.option("-archivePath", archivePath)
        writer.option("-resultBundlePath", resultBundlePath)
        writer.option("-resultBundleVersion", resultBundleVersion)
        writer.option("-resultStreamPath", resultStreamPath)
        packageResolution.render(into: &writer)
        provisioning.render(into: &writer)
        testing.render(into: &writer)
        sanitizers.render(into: &writer)
        codeSizeProfile.render(into: &writer)
        writer.flag("-parallelizeTargets", parallelizeTargets)
        writer.option("-jobs", jobs)
        verbosity?.render(into: &writer)
        writer.flag("-hideShellScriptEnvironment", hideShellScriptEnvironment)
        writer.flag("-showBuildTimingSummary", showBuildTimingSummary)
        writer.flag("-skipUnavailableActions", skipUnavailableActions)
        writer.append(contentsOf: actions.map(\.rawValue))
        buildSettings.renderBuildSettings(into: &writer)
        userDefaults.renderUserDefaults(into: &writer)
        writer.append(contentsOf: additionalArguments)
        return writer.arguments
    }
}
