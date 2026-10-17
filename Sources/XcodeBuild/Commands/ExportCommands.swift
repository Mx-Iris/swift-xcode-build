public import System

/// Exports or uploads an archive (`-exportArchive`).
///
/// ```swift
/// var options = ExportOptions(method: .appStoreConnect)
/// options.destination = .upload
/// let upload = ExportArchiveCommand(archivePath: "build/App.xcarchive", exportOptions: .options(options)) {
///     AuthenticationKey(path: "AuthKey.p8", identifier: "KEY1234567", issuerIdentifier: "issuer-uuid")
/// }
/// try await xcodebuild.run(upload)
/// ```
///
/// When the export options are given as an ``ExportOptions`` value,
/// ``arguments`` contains ``exportOptionsPlaceholder`` where the property list
/// path goes. ``XcodeBuildTool`` writes the property list to a temporary file,
/// passes its path instead, and removes it when xcodebuild exits.
public struct ExportArchiveCommand: XcodeBuildActionCommand, ExportPathSelecting, ProvisioningConfigurable,
    LogVerbositySelecting, UserDefaultOverriding, AdditionalArgumentsAccepting
{
    public typealias Output = XcodeBuildSummary

    /// Where the export options come from.
    public enum ExportOptionsSource: Sendable, Hashable {
        /// A property list file you wrote.
        case propertyList(FilePath)

        /// Options that ``XcodeBuildTool`` writes to a temporary property list.
        case options(ExportOptions)
    }

    /// The text that stands for the temporary property list path in
    /// ``arguments`` when the export options are an ``ExportOptions`` value.
    public static let exportOptionsPlaceholder = "<temporary ExportOptions.plist>"

    /// The archive to export (`-archivePath`).
    public var archivePath: FilePath

    /// The export options (`-exportOptionsPlist`).
    public var exportOptions: ExportOptionsSource

    /// Where to write the exported product, including its name (`-exportPath`).
    /// Required unless the export options upload the archive.
    public var exportPath: FilePath?

    public var provisioning: ProvisioningOptions

    public var verbosity: LogVerbosity?

    public var userDefaults: SettingAssignments

    public var additionalArguments: [String]

    /// Creates an export command.
    ///
    /// - Parameters:
    ///   - archivePath: The archive to export.
    ///   - exportOptions: The export options.
    ///   - exportPath: Where to write the exported product.
    public init(archivePath: FilePath, exportOptions: ExportOptionsSource, exportPath: FilePath? = nil) {
        self.archivePath = archivePath
        self.exportOptions = exportOptions
        self.exportPath = exportPath
        self.provisioning = ProvisioningOptions()
        self.userDefaults = SettingAssignments()
        self.additionalArguments = []
    }

    /// Creates an export command with options described by components.
    public init(
        archivePath: FilePath,
        exportOptions: ExportOptionsSource,
        @XcodeBuildCommandBuilder<ExportArchiveCommand> options: () -> XcodeBuildCommandContent<ExportArchiveCommand>
    ) {
        self.init(archivePath: archivePath, exportOptions: exportOptions)
        options().apply(to: &self)
    }

    public var arguments: [String] {
        var writer = ArgumentWriter()
        writer.append("-exportArchive")
        writer.option("-archivePath", archivePath)
        writer.option("-exportPath", exportPath)
        switch exportOptions {
        case .propertyList(let path):
            writer.option("-exportOptionsPlist", path)
        case .options:
            writer.option("-exportOptionsPlist", ExportArchiveCommand.exportOptionsPlaceholder)
        }
        provisioning.render(into: &writer)
        verbosity?.render(into: &writer)
        userDefaults.renderUserDefaults(into: &writer)
        writer.append(contentsOf: additionalArguments)
        return writer.arguments
    }
}

extension ExportArchiveCommand: TemporaryFileRequiring {
    func temporaryFiles(commandLine: [String]) throws(XcodeBuildError) -> [TemporaryFile] {
        guard case .options(let options) = exportOptions else {
            return []
        }
        let contents: [UInt8]
        do {
            contents = try options.propertyList()
        } catch {
            var error = error
            error.commandLine = commandLine
            throw error
        }
        return [
            TemporaryFile(
                placeholder: ExportArchiveCommand.exportOptionsPlaceholder,
                name: "ExportOptions.plist",
                contents: contents
            ),
        ]
    }
}

/// Exports an app from an archive that Apple's notary service has notarized (`-exportNotarizedApp`).
public struct ExportNotarizedAppCommand: XcodeBuildActionCommand, ProvisioningConfigurable, LogVerbositySelecting,
    UserDefaultOverriding, AdditionalArgumentsAccepting
{
    public typealias Output = XcodeBuildSummary

    /// The notarized archive (`-archivePath`).
    public var archivePath: FilePath

    /// Where to write the app (`-exportPath`).
    public var exportPath: FilePath

    public var provisioning: ProvisioningOptions

    public var verbosity: LogVerbosity?

    public var userDefaults: SettingAssignments

    public var additionalArguments: [String]

    /// Creates a command that exports a notarized app.
    public init(archivePath: FilePath, exportPath: FilePath) {
        self.archivePath = archivePath
        self.exportPath = exportPath
        self.provisioning = ProvisioningOptions()
        self.userDefaults = SettingAssignments()
        self.additionalArguments = []
    }

    /// Creates a command that exports a notarized app, with options described by components.
    public init(
        archivePath: FilePath,
        exportPath: FilePath,
        @XcodeBuildCommandBuilder<ExportNotarizedAppCommand> options: () -> XcodeBuildCommandContent<ExportNotarizedAppCommand>
    ) {
        self.init(archivePath: archivePath, exportPath: exportPath)
        options().apply(to: &self)
    }

    public var arguments: [String] {
        var writer = ArgumentWriter()
        writer.append("-exportNotarizedApp")
        writer.option("-archivePath", archivePath)
        writer.option("-exportPath", exportPath)
        provisioning.render(into: &writer)
        verbosity?.render(into: &writer)
        userDefaults.renderUserDefaults(into: &writer)
        writer.append(contentsOf: additionalArguments)
        return writer.arguments
    }
}

/// Exports a project's localizations to XLIFF files in a localization catalog (`-exportLocalizations`).
public struct ExportLocalizationsCommand: XcodeBuildActionCommand, ProjectContainerSelecting, LogVerbositySelecting,
    UserDefaultOverriding, AdditionalArgumentsAccepting
{
    public typealias Output = XcodeBuildSummary

    /// The directory to export to (`-localizationPath`).
    public var localizationPath: FilePath

    /// The project to export from. xcodebuild documents `-project`.
    public var container: ProjectContainer

    /// The ISO 639-1 language of the source strings (`-defaultLanguage`).
    public var defaultLanguage: String?

    /// The languages to include besides the development language, such as
    /// `zh-Hans` (`-exportLanguage`, repeated).
    public var exportLanguages: [String]

    /// Whether to include screenshots from test plans (`-includeScreenshots`).
    public var includeScreenshots: Bool

    public var verbosity: LogVerbosity?

    public var userDefaults: SettingAssignments

    public var additionalArguments: [String]

    /// Creates a command that exports localizations.
    ///
    /// - Parameters:
    ///   - localizationPath: The directory to export to.
    ///   - container: The project to export from.
    public init(localizationPath: FilePath, container: ProjectContainer = .automatic) {
        self.localizationPath = localizationPath
        self.container = container
        self.exportLanguages = []
        self.includeScreenshots = false
        self.userDefaults = SettingAssignments()
        self.additionalArguments = []
    }

    /// Creates a command that exports localizations, with options described by components.
    public init(
        localizationPath: FilePath,
        @XcodeBuildCommandBuilder<ExportLocalizationsCommand> options: () -> XcodeBuildCommandContent<ExportLocalizationsCommand>
    ) {
        self.init(localizationPath: localizationPath)
        options().apply(to: &self)
    }

    public var arguments: [String] {
        var writer = ArgumentWriter()
        writer.append("-exportLocalizations")
        writer.option("-localizationPath", localizationPath)
        container.render(into: &writer)
        writer.option("-defaultLanguage", defaultLanguage)
        writer.repeatedOption("-exportLanguage", exportLanguages)
        writer.flag("-includeScreenshots", includeScreenshots)
        verbosity?.render(into: &writer)
        userDefaults.renderUserDefaults(into: &writer)
        writer.append(contentsOf: additionalArguments)
        return writer.arguments
    }
}

/// Imports localizations from an XLIFF file or localization catalog into a project (`-importLocalizations`).
public struct ImportLocalizationsCommand: XcodeBuildActionCommand, ProjectContainerSelecting, LogVerbositySelecting,
    UserDefaultOverriding, AdditionalArgumentsAccepting
{
    public typealias Output = XcodeBuildSummary

    /// The XLIFF file or localization catalog to import (`-localizationPath`).
    public var localizationPath: FilePath

    /// The project to import into. xcodebuild documents `-project`.
    public var container: ProjectContainer

    /// Whether to merge the imported strings with the existing ones (`-mergeImport`).
    public var mergeImport: Bool

    public var verbosity: LogVerbosity?

    public var userDefaults: SettingAssignments

    public var additionalArguments: [String]

    /// Creates a command that imports localizations.
    ///
    /// - Parameters:
    ///   - localizationPath: The XLIFF file or localization catalog to import.
    ///   - container: The project to import into.
    public init(localizationPath: FilePath, container: ProjectContainer = .automatic) {
        self.localizationPath = localizationPath
        self.container = container
        self.mergeImport = false
        self.userDefaults = SettingAssignments()
        self.additionalArguments = []
    }

    /// Creates a command that imports localizations, with options described by components.
    public init(
        localizationPath: FilePath,
        @XcodeBuildCommandBuilder<ImportLocalizationsCommand> options: () -> XcodeBuildCommandContent<ImportLocalizationsCommand>
    ) {
        self.init(localizationPath: localizationPath)
        options().apply(to: &self)
    }

    public var arguments: [String] {
        var writer = ArgumentWriter()
        writer.append("-importLocalizations")
        writer.option("-localizationPath", localizationPath)
        container.render(into: &writer)
        writer.flag("-mergeImport", mergeImport)
        verbosity?.render(into: &writer)
        userDefaults.renderUserDefaults(into: &writer)
        writer.append(contentsOf: additionalArguments)
        return writer.arguments
    }
}
