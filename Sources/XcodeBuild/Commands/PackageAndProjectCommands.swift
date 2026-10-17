public import System

/// Resolves the Swift package dependencies of a project, workspace, or package (`-resolvePackageDependencies`).
///
/// ```swift
/// try await xcodebuild.run(ResolvePackageDependenciesCommand {
///     Workspace("App.xcworkspace")
///     Scheme("App")
///     ClonedSourcePackagesDirectory("build/SourcePackages")
/// })
/// ```
public struct ResolvePackageDependenciesCommand: XcodeBuildActionCommand, ProjectContainerSelecting, SchemeSelecting,
    DerivedDataLocating, PackageResolutionConfigurable, LogVerbositySelecting, UserDefaultOverriding,
    AdditionalArgumentsAccepting
{
    public typealias Output = XcodeBuildSummary

    public var container: ProjectContainer

    public var scheme: String?

    public var derivedDataPath: FilePath?

    public var packageResolution: PackageResolutionOptions

    public var verbosity: LogVerbosity?

    public var userDefaults: SettingAssignments

    public var additionalArguments: [String]

    /// Creates a command that resolves package dependencies.
    public init(container: ProjectContainer = .automatic, scheme: String? = nil) {
        self.container = container
        self.scheme = scheme
        self.packageResolution = PackageResolutionOptions()
        self.userDefaults = SettingAssignments()
        self.additionalArguments = []
    }

    /// Creates a command that resolves package dependencies, with options described by components.
    public init(
        @XcodeBuildCommandBuilder<ResolvePackageDependenciesCommand> options: () -> XcodeBuildCommandContent<ResolvePackageDependenciesCommand>
    ) {
        self.init()
        options().apply(to: &self)
    }

    public var arguments: [String] {
        var writer = ArgumentWriter()
        writer.append("-resolvePackageDependencies")
        container.render(into: &writer)
        writer.option("-scheme", scheme)
        writer.option("-derivedDataPath", derivedDataPath)
        packageResolution.render(into: &writer)
        verbosity?.render(into: &writer)
        userDefaults.renderUserDefaults(into: &writer)
        writer.append(contentsOf: additionalArguments)
        return writer.arguments
    }
}

/// Packages frameworks or libraries built for several platforms into an XCFramework (`-create-xcframework`).
///
/// ```swift
/// let create = CreateXCFrameworkCommand(output: "build/MyKit.xcframework") {
///     Framework("build/iOS/MyKit.framework", debugSymbols: ["build/iOS/MyKit.framework.dSYM"])
///     Framework("build/Simulator/MyKit.framework")
///     Framework(named: "MyKit.framework", inArchive: "build/MyKit-macOS.xcarchive")
/// }
/// ```
public struct CreateXCFrameworkCommand: XcodeBuildActionCommand, UserDefaultOverriding, AdditionalArgumentsAccepting {
    public typealias Output = XcodeBuildSummary

    /// Where to write the XCFramework (`-output`).
    public var output: FilePath

    /// The frameworks and libraries to include, one per platform variant.
    public var contents: [XCFrameworkContent]

    /// Whether the XCFramework contains information not suitable for public
    /// distribution (`-allow-internal-distribution`).
    public var allowInternalDistribution: Bool

    public var userDefaults: SettingAssignments

    public var additionalArguments: [String]

    /// Creates a command that creates an XCFramework.
    ///
    /// - Parameters:
    ///   - output: Where to write the XCFramework.
    ///   - contents: The frameworks and libraries to include.
    public init(output: FilePath, contents: [XCFrameworkContent] = []) {
        self.output = output
        self.contents = contents
        self.allowInternalDistribution = false
        self.userDefaults = SettingAssignments()
        self.additionalArguments = []
    }

    /// Creates a command that creates an XCFramework, with its contents and options described by components.
    public init(
        output: FilePath,
        @XcodeBuildCommandBuilder<CreateXCFrameworkCommand> options: () -> XcodeBuildCommandContent<CreateXCFrameworkCommand>
    ) {
        self.init(output: output)
        options().apply(to: &self)
    }

    public var arguments: [String] {
        var writer = ArgumentWriter()
        writer.append("-create-xcframework")
        for content in contents {
            content.render(into: &writer)
        }
        writer.flag("-allow-internal-distribution", allowInternalDistribution)
        writer.option("-output", output)
        userDefaults.renderUserDefaults(into: &writer)
        writer.append(contentsOf: additionalArguments)
        return writer.arguments
    }
}

/// A framework or library to put in an XCFramework.
public struct XCFrameworkContent: Sendable, Hashable {
    /// Whether the content is a framework or a library.
    public enum Kind: Sendable, Hashable {
        /// A framework (`-framework`).
        case framework

        /// A static or dynamic library (`-library`), with an optional
        /// directory of headers (`-headers`).
        case library(headers: FilePath?)
    }

    /// Whether the content is a framework or a library.
    public var kind: Kind

    /// The path of the framework or library, or its name when it comes from ``archive``.
    public var path: FilePath

    /// An archive that contains the framework or library (`-archive`).
    public var archive: FilePath?

    /// dSYM bundles or bcsymbolmap files to include (`-debug-symbols`, repeated).
    public var debugSymbols: [FilePath]

    /// Creates content.
    public init(kind: Kind, path: FilePath, archive: FilePath? = nil, debugSymbols: [FilePath] = []) {
        self.kind = kind
        self.path = path
        self.archive = archive
        self.debugSymbols = debugSymbols
    }

    /// A framework at a path.
    public static func framework(_ path: FilePath, debugSymbols: [FilePath] = []) -> XCFrameworkContent {
        XCFrameworkContent(kind: .framework, path: path, debugSymbols: debugSymbols)
    }

    /// A framework in an archive, by name.
    public static func framework(named name: FilePath, inArchive archive: FilePath, debugSymbols: [FilePath] = []) -> XCFrameworkContent {
        XCFrameworkContent(kind: .framework, path: name, archive: archive, debugSymbols: debugSymbols)
    }

    /// A library at a path, with its headers.
    public static func library(_ path: FilePath, headers: FilePath? = nil, debugSymbols: [FilePath] = []) -> XCFrameworkContent {
        XCFrameworkContent(kind: .library(headers: headers), path: path, debugSymbols: debugSymbols)
    }

    /// A library in an archive, by name, with its headers.
    public static func library(
        named name: FilePath,
        inArchive archive: FilePath,
        headers: FilePath? = nil,
        debugSymbols: [FilePath] = []
    ) -> XCFrameworkContent {
        XCFrameworkContent(kind: .library(headers: headers), path: name, archive: archive, debugSymbols: debugSymbols)
    }

    func render(into writer: inout ArgumentWriter) {
        writer.option("-archive", archive)
        switch kind {
        case .framework:
            writer.option("-framework", path)
        case .library(let headers):
            writer.option("-library", path)
            writer.option("-headers", headers)
        }
        writer.repeatedOption("-debug-symbols", debugSymbols.map(\.string))
    }
}

/// Converts a project to another project file format (`-convert-project`). Xcode 27 and later.
///
/// The project is converted in place.
public struct ConvertProjectCommand: XcodeBuildActionCommand, ProjectContainerSelecting, LogVerbositySelecting,
    UserDefaultOverriding, AdditionalArgumentsAccepting
{
    public typealias Output = XcodeBuildSummary

    /// The format to convert to.
    public var format: ProjectFormat

    public var container: ProjectContainer

    public var verbosity: LogVerbosity?

    public var userDefaults: SettingAssignments

    public var additionalArguments: [String]

    /// Creates a command that converts a project.
    ///
    /// - Parameters:
    ///   - format: The format to convert to, such as `.xcode("16.0")`.
    ///   - container: The project to convert.
    public init(format: ProjectFormat, container: ProjectContainer = .automatic) {
        self.format = format
        self.container = container
        self.userDefaults = SettingAssignments()
        self.additionalArguments = []
    }

    /// Creates a command that converts a project, with options described by components.
    public init(
        format: ProjectFormat,
        @XcodeBuildCommandBuilder<ConvertProjectCommand> options: () -> XcodeBuildCommandContent<ConvertProjectCommand>
    ) {
        self.init(format: format)
        options().apply(to: &self)
    }

    public var arguments: [String] {
        var writer = ArgumentWriter()
        writer.option("-convert-project", format)
        container.render(into: &writer)
        verbosity?.render(into: &writer)
        userDefaults.renderUserDefaults(into: &writer)
        writer.append(contentsOf: additionalArguments)
        return writer.arguments
    }
}
