public import System

/// Lists the installed SDKs (`-showsdks`).
///
/// ```swift
/// let sdks = try await xcodebuild.run(.showSDKs)
/// let iOS = sdks.first { $0.platform == "iphoneos" }
/// ```
public struct ShowSDKsCommand: XcodeBuildQueryCommand, UserDefaultOverriding, AdditionalArgumentsAccepting {
    public typealias Output = [SDKDescription]

    public var userDefaults: SettingAssignments

    public var additionalArguments: [String]

    /// Creates a command that lists the installed SDKs.
    public init() {
        self.userDefaults = SettingAssignments()
        self.additionalArguments = []
    }

    /// Creates a command that lists the installed SDKs, with options described by components.
    public init(@XcodeBuildCommandBuilder<ShowSDKsCommand> options: () -> XcodeBuildCommandContent<ShowSDKsCommand>) {
        self.init()
        options().apply(to: &self)
    }

    public var arguments: [String] {
        var writer = ArgumentWriter()
        writer.append("-showsdks", "-json")
        userDefaults.renderUserDefaults(into: &writer)
        writer.append(contentsOf: additionalArguments)
        return writer.arguments
    }

    public func output(from completion: XcodeBuildCompletion) throws(XcodeBuildError) -> [SDKDescription] {
        try completion.requireSuccess()
        return try completion.decodeJSON(SDKListJSON.self).descriptions
    }
}

extension XcodeBuildQueryCommand where Self == ShowSDKsCommand {
    /// Lists the installed SDKs.
    public static var showSDKs: ShowSDKsCommand {
        ShowSDKsCommand()
    }
}

/// Shows the version of Xcode (`-version`).
public struct VersionCommand: XcodeBuildQueryCommand, UserDefaultOverriding, AdditionalArgumentsAccepting {
    public typealias Output = XcodeVersion

    public var userDefaults: SettingAssignments

    public var additionalArguments: [String]

    /// Creates a command that shows the version of Xcode.
    public init() {
        self.userDefaults = SettingAssignments()
        self.additionalArguments = []
    }

    /// Creates a command that shows the version of Xcode, with options described by components.
    public init(@XcodeBuildCommandBuilder<VersionCommand> options: () -> XcodeBuildCommandContent<VersionCommand>) {
        self.init()
        options().apply(to: &self)
    }

    public var arguments: [String] {
        var writer = ArgumentWriter()
        writer.append("-version")
        userDefaults.renderUserDefaults(into: &writer)
        writer.append(contentsOf: additionalArguments)
        return writer.arguments
    }

    /// Parses the two lines `Xcode 27.2` and `Build version 27B5038j`.
    public func output(from completion: XcodeBuildCompletion) throws(XcodeBuildError) -> XcodeVersion {
        try completion.requireSuccess()
        var version: String?
        var buildVersion: String?
        for line in completion.standardOutputText.split(whereSeparator: \.isNewline) {
            if line.hasPrefix("Xcode ") {
                version = String(line.dropFirst("Xcode ".count))
            } else if line.hasPrefix("Build version ") {
                buildVersion = String(line.dropFirst("Build version ".count))
            }
        }
        guard let version, let buildVersion else {
            throw completion.unexpectedOutput("expected the lines \"Xcode <version>\" and \"Build version <build>\"")
        }
        return XcodeVersion(version: version, buildVersion: buildVersion)
    }
}

extension XcodeBuildQueryCommand where Self == VersionCommand {
    /// Shows the version of Xcode.
    public static var version: VersionCommand {
        VersionCommand()
    }
}

/// Shows information about one or all installed SDKs (`-version -sdk`).
public struct SDKVersionCommand: XcodeBuildQueryCommand, UserDefaultOverriding, AdditionalArgumentsAccepting {
    public typealias Output = [SDKDescription]

    /// The SDK, by canonical name such as `macosx` or by path, or `nil` for all SDKs.
    public var sdk: String?

    public var userDefaults: SettingAssignments

    public var additionalArguments: [String]

    /// Creates a command that shows information about SDKs.
    ///
    /// - Parameter sdk: The SDK, by canonical name such as `macosx` or by
    ///   path, or `nil` for all SDKs.
    public init(sdk: String? = nil) {
        self.sdk = sdk
        self.userDefaults = SettingAssignments()
        self.additionalArguments = []
    }

    /// Creates a command that shows information about SDKs, with options described by components.
    public init(
        sdk: String? = nil,
        @XcodeBuildCommandBuilder<SDKVersionCommand> options: () -> XcodeBuildCommandContent<SDKVersionCommand>
    ) {
        self.init(sdk: sdk)
        options().apply(to: &self)
    }

    public var arguments: [String] {
        var writer = ArgumentWriter()
        writer.append("-version", "-sdk")
        if let sdk {
            writer.append(sdk)
        }
        writer.append("-json")
        userDefaults.renderUserDefaults(into: &writer)
        writer.append(contentsOf: additionalArguments)
        return writer.arguments
    }

    public func output(from completion: XcodeBuildCompletion) throws(XcodeBuildError) -> [SDKDescription] {
        try completion.requireSuccess()
        return try completion.decodeJSON(SDKListJSON.self).descriptions
    }
}

/// Shows one item of information about an SDK, such as its path (`-version -sdk <sdk> <infoitem>`).
public struct SDKVersionItemCommand: XcodeBuildQueryCommand, UserDefaultOverriding, AdditionalArgumentsAccepting {
    /// The value of the item.
    public typealias Output = String

    /// The SDK, by canonical name such as `macosx` or by path.
    public var sdk: String

    /// The item, such as `Path`, `SDKVersion`, `PlatformPath`, or `ProductBuildVersion`.
    public var item: String

    public var userDefaults: SettingAssignments

    public var additionalArguments: [String]

    /// Creates a command that shows one item of information about an SDK.
    ///
    /// - Parameters:
    ///   - sdk: The SDK, by canonical name such as `macosx` or by path.
    ///   - item: The item, such as `Path`, `SDKVersion`, `PlatformPath`, or
    ///     `ProductBuildVersion`.
    public init(sdk: String, item: String) {
        self.sdk = sdk
        self.item = item
        self.userDefaults = SettingAssignments()
        self.additionalArguments = []
    }

    /// Creates a command that shows one item of information about an SDK, with options described by components.
    public init(
        sdk: String,
        item: String,
        @XcodeBuildCommandBuilder<SDKVersionItemCommand> options: () -> XcodeBuildCommandContent<SDKVersionItemCommand>
    ) {
        self.init(sdk: sdk, item: item)
        options().apply(to: &self)
    }

    public var arguments: [String] {
        var writer = ArgumentWriter()
        writer.append("-version", "-sdk", sdk, item)
        userDefaults.renderUserDefaults(into: &writer)
        writer.append(contentsOf: additionalArguments)
        return writer.arguments
    }

    public func output(from completion: XcodeBuildCompletion) throws(XcodeBuildError) -> String {
        try completion.requireSuccess()
        return completion.trimmedStandardOutputText
    }
}

/// Finds an executable in the selected SDK and toolchain, such as `clang` (`-find-executable`).
public struct FindExecutableCommand: XcodeBuildQueryCommand, SDKSelecting, ToolchainSelecting,
    UserDefaultOverriding, AdditionalArgumentsAccepting
{
    /// The full path of the executable.
    public typealias Output = FilePath

    /// The name of the executable.
    public var name: String

    public var sdk: String?

    public var toolchain: String?

    public var userDefaults: SettingAssignments

    public var additionalArguments: [String]

    /// Creates a command that finds an executable.
    public init(name: String) {
        self.name = name
        self.userDefaults = SettingAssignments()
        self.additionalArguments = []
    }

    /// Creates a command that finds an executable, with options described by components.
    public init(
        name: String,
        @XcodeBuildCommandBuilder<FindExecutableCommand> options: () -> XcodeBuildCommandContent<FindExecutableCommand>
    ) {
        self.init(name: name)
        options().apply(to: &self)
    }

    public var arguments: [String] {
        var writer = ArgumentWriter()
        writer.option("-find-executable", name)
        writer.option("-sdk", sdk)
        writer.option("-toolchain", toolchain)
        userDefaults.renderUserDefaults(into: &writer)
        writer.append(contentsOf: additionalArguments)
        return writer.arguments
    }

    /// Returns the path, or throws ``XcodeBuildError/Code/commandFailed`` when
    /// xcodebuild can't find the executable.
    public func output(from completion: XcodeBuildCompletion) throws(XcodeBuildError) -> FilePath {
        try completion.requireSuccess()
        let path = completion.trimmedStandardOutputText
        guard !path.isEmpty else {
            throw completion.unexpectedOutput("expected a path")
        }
        return FilePath(path)
    }
}

/// Finds a library in the selected SDK and toolchain, such as `libclang.dylib` (`-find-library`).
public struct FindLibraryCommand: XcodeBuildQueryCommand, SDKSelecting, ToolchainSelecting,
    UserDefaultOverriding, AdditionalArgumentsAccepting
{
    /// The full path of the library.
    public typealias Output = FilePath

    /// The name of the library.
    public var name: String

    public var sdk: String?

    public var toolchain: String?

    public var userDefaults: SettingAssignments

    public var additionalArguments: [String]

    /// Creates a command that finds a library.
    public init(name: String) {
        self.name = name
        self.userDefaults = SettingAssignments()
        self.additionalArguments = []
    }

    /// Creates a command that finds a library, with options described by components.
    public init(
        name: String,
        @XcodeBuildCommandBuilder<FindLibraryCommand> options: () -> XcodeBuildCommandContent<FindLibraryCommand>
    ) {
        self.init(name: name)
        options().apply(to: &self)
    }

    public var arguments: [String] {
        var writer = ArgumentWriter()
        writer.option("-find-library", name)
        writer.option("-sdk", sdk)
        writer.option("-toolchain", toolchain)
        userDefaults.renderUserDefaults(into: &writer)
        writer.append(contentsOf: additionalArguments)
        return writer.arguments
    }

    /// Returns the path, or throws ``XcodeBuildError/Code/commandFailed`` when
    /// xcodebuild can't find the library.
    public func output(from completion: XcodeBuildCompletion) throws(XcodeBuildError) -> FilePath {
        try completion.requireSuccess()
        let path = completion.trimmedStandardOutputText
        guard !path.isEmpty else {
            throw completion.unexpectedOutput("expected a path")
        }
        return FilePath(path)
    }
}

/// Shows the build and installation status of an optional component (`-showComponent`).
public struct ShowComponentCommand: XcodeBuildQueryCommand, BuildVersionSelecting, UserDefaultOverriding,
    AdditionalArgumentsAccepting
{
    public typealias Output = ComponentDescription

    /// The component.
    public var component: DownloadableComponent

    /// The build of the component, or `nil` for the one matching this Xcode. Xcode 27 and later.
    public var buildVersion: String?

    public var userDefaults: SettingAssignments

    public var additionalArguments: [String]

    /// Creates a command that shows a component.
    public init(component: DownloadableComponent) {
        self.component = component
        self.userDefaults = SettingAssignments()
        self.additionalArguments = []
    }

    /// Creates a command that shows a component, with options described by components.
    public init(
        component: DownloadableComponent,
        @XcodeBuildCommandBuilder<ShowComponentCommand> options: () -> XcodeBuildCommandContent<ShowComponentCommand>
    ) {
        self.init(component: component)
        options().apply(to: &self)
    }

    public var arguments: [String] {
        var writer = ArgumentWriter()
        writer.option("-showComponent", component)
        writer.append("-json")
        writer.option("-buildVersion", buildVersion)
        userDefaults.renderUserDefaults(into: &writer)
        writer.append(contentsOf: additionalArguments)
        return writer.arguments
    }

    public func output(from completion: XcodeBuildCompletion) throws(XcodeBuildError) -> ComponentDescription {
        try completion.requireSuccess()
        let component = try completion.decodeJSON(ComponentJSON.self)
        return ComponentDescription(buildVersion: component.buildVersion, status: component.status)
    }
}

/// Checks whether Xcode's first launch tasks, such as installing system
/// packages or agreeing to the license, still need to run (`-checkFirstLaunchStatus`).
public struct CheckFirstLaunchStatusCommand: XcodeBuildQueryCommand, UserDefaultOverriding,
    AdditionalArgumentsAccepting
{
    /// Whether ``RunFirstLaunchCommand`` needs to run: `true` when xcodebuild
    /// exits with status 69, `false` when it exits with 0.
    public typealias Output = Bool

    public var userDefaults: SettingAssignments

    public var additionalArguments: [String]

    /// Creates a command that checks the first launch status.
    public init() {
        self.userDefaults = SettingAssignments()
        self.additionalArguments = []
    }

    /// Creates a command that checks the first launch status, with options described by components.
    public init(@XcodeBuildCommandBuilder<CheckFirstLaunchStatusCommand> options: () -> XcodeBuildCommandContent<CheckFirstLaunchStatusCommand>) {
        self.init()
        options().apply(to: &self)
    }

    public var arguments: [String] {
        var writer = ArgumentWriter()
        writer.append("-checkFirstLaunchStatus")
        userDefaults.renderUserDefaults(into: &writer)
        writer.append(contentsOf: additionalArguments)
        return writer.arguments
    }

    public func output(from completion: XcodeBuildCompletion) throws(XcodeBuildError) -> Bool {
        if completion.terminationStatus == .exited(unavailableExitStatus) {
            return true
        }
        try completion.requireSuccess()
        return false
    }
}

extension XcodeBuildQueryCommand where Self == CheckFirstLaunchStatusCommand {
    /// Checks whether Xcode's first launch tasks still need to run.
    public static var checkFirstLaunchStatus: CheckFirstLaunchStatusCommand {
        CheckFirstLaunchStatusCommand()
    }
}

/// Checks whether the Xcode and SDK license agreements have been accepted (`-license check`).
public struct CheckLicenseCommand: XcodeBuildQueryCommand, UserDefaultOverriding, AdditionalArgumentsAccepting {
    /// Whether the license agreements have been accepted: `true` when
    /// xcodebuild exits with status 0, `false` when it exits with 69.
    public typealias Output = Bool

    public var userDefaults: SettingAssignments

    public var additionalArguments: [String]

    /// Creates a command that checks the license agreements.
    public init() {
        self.userDefaults = SettingAssignments()
        self.additionalArguments = []
    }

    /// Creates a command that checks the license agreements, with options described by components.
    public init(@XcodeBuildCommandBuilder<CheckLicenseCommand> options: () -> XcodeBuildCommandContent<CheckLicenseCommand>) {
        self.init()
        options().apply(to: &self)
    }

    public var arguments: [String] {
        var writer = ArgumentWriter()
        writer.append("-license", "check")
        userDefaults.renderUserDefaults(into: &writer)
        writer.append(contentsOf: additionalArguments)
        return writer.arguments
    }

    public func output(from completion: XcodeBuildCompletion) throws(XcodeBuildError) -> Bool {
        if completion.terminationStatus == .exited(unavailableExitStatus) {
            return false
        }
        try completion.requireSuccess()
        return true
    }
}

extension XcodeBuildQueryCommand where Self == CheckLicenseCommand {
    /// Checks whether the Xcode and SDK license agreements have been accepted.
    public static var checkLicense: CheckLicenseCommand {
        CheckLicenseCommand()
    }
}

/// Prints a brief usage summary (`-usage`).
///
/// xcodebuild writes the summary to standard error; the command returns it
/// from there.
public struct UsageCommand: XcodeBuildQueryCommand, UserDefaultOverriding, AdditionalArgumentsAccepting {
    /// The text xcodebuild prints.
    public typealias Output = String

    public var userDefaults: SettingAssignments

    public var additionalArguments: [String]

    /// Creates a command that prints the usage summary.
    public init() {
        self.userDefaults = SettingAssignments()
        self.additionalArguments = []
    }

    /// Creates a command that prints the usage summary, with options described by components.
    public init(@XcodeBuildCommandBuilder<UsageCommand> options: () -> XcodeBuildCommandContent<UsageCommand>) {
        self.init()
        options().apply(to: &self)
    }

    public var arguments: [String] {
        var writer = ArgumentWriter()
        writer.append("-usage")
        userDefaults.renderUserDefaults(into: &writer)
        writer.append(contentsOf: additionalArguments)
        return writer.arguments
    }

    public func output(from completion: XcodeBuildCompletion) throws(XcodeBuildError) -> String {
        try completion.requireSuccess()
        return completion.printedText
    }
}

extension XcodeBuildQueryCommand where Self == UsageCommand {
    /// Prints a brief usage summary.
    public static var usage: UsageCommand {
        UsageCommand()
    }
}

/// Prints the complete usage, including every option and the keys of the export options property list (`-help`).
///
/// xcodebuild writes the usage to standard error; the command returns it
/// from there.
public struct HelpCommand: XcodeBuildQueryCommand, UserDefaultOverriding, AdditionalArgumentsAccepting {
    /// The text xcodebuild prints.
    public typealias Output = String

    public var userDefaults: SettingAssignments

    public var additionalArguments: [String]

    /// Creates a command that prints the complete usage.
    public init() {
        self.userDefaults = SettingAssignments()
        self.additionalArguments = []
    }

    /// Creates a command that prints the complete usage, with options described by components.
    public init(@XcodeBuildCommandBuilder<HelpCommand> options: () -> XcodeBuildCommandContent<HelpCommand>) {
        self.init()
        options().apply(to: &self)
    }

    public var arguments: [String] {
        var writer = ArgumentWriter()
        writer.append("-help")
        userDefaults.renderUserDefaults(into: &writer)
        writer.append(contentsOf: additionalArguments)
        return writer.arguments
    }

    public func output(from completion: XcodeBuildCompletion) throws(XcodeBuildError) -> String {
        try completion.requireSuccess()
        return completion.printedText
    }
}

extension XcodeBuildQueryCommand where Self == HelpCommand {
    /// Prints the complete usage.
    public static var help: HelpCommand {
        HelpCommand()
    }
}

/// The exit status, `EX_UNAVAILABLE` from `sysexits(3)`, with which xcodebuild
/// answers "no" to `-checkFirstLaunchStatus` and `-license check`.
let unavailableExitStatus: Int32 = 69

extension XcodeBuildCompletion {
    /// The text a help query printed. xcodebuild writes `-help` and `-usage`
    /// to standard error; standard output is used if a version prints there.
    var printedText: String {
        standardOutput.isEmpty ? standardErrorText : standardOutputText
    }
}
