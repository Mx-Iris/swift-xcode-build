public import System

// Components for options that only one command other than ``BuildCommand`` accepts.

/// With a scheme, shows the build settings of the targets of a scheme action, such as `test`.
public struct BuildSettingsAction: XcodeBuildCommandComponent {
    /// The action.
    public var action: BuildAction

    /// Creates the component.
    public init(_ action: BuildAction) {
        self.action = action
    }

    public func apply(to command: inout ShowBuildSettingsCommand) {
        command.action = action
    }
}

/// Sets the language of the source strings (`-defaultLanguage`).
public struct DefaultLanguage: XcodeBuildCommandComponent {
    /// The ISO 639-1 language code.
    public var code: String

    /// Creates the component.
    public init(_ code: String) {
        self.code = code
    }

    public func apply(to command: inout ExportLocalizationsCommand) {
        command.defaultLanguage = code
    }
}

/// Adds languages to export besides the development language (`-exportLanguage`).
public struct ExportLanguage: XcodeBuildCommandComponent {
    /// The language codes, such as `zh-Hans`.
    public var codes: [String]

    /// Creates the component.
    public init(_ codes: String...) {
        self.codes = codes
    }

    /// Creates the component.
    public init(_ codes: [String]) {
        self.codes = codes
    }

    public func apply(to command: inout ExportLocalizationsCommand) {
        command.exportLanguages.append(contentsOf: codes)
    }
}

/// Includes screenshots from test plans in the export (`-includeScreenshots`).
public struct IncludeScreenshots: XcodeBuildCommandComponent {
    /// Creates the component.
    public init() {}

    public func apply(to command: inout ExportLocalizationsCommand) {
        command.includeScreenshots = true
    }
}

/// Merges imported strings with the existing ones (`-mergeImport`).
public struct MergeImport: XcodeBuildCommandComponent {
    /// Creates the component.
    public init() {}

    public func apply(to command: inout ImportLocalizationsCommand) {
        command.mergeImport = true
    }
}

/// Adds a framework to an XCFramework (`-framework`).
public struct Framework: XcodeBuildCommandComponent {
    /// The framework.
    public var content: XCFrameworkContent

    /// Adds the framework at a path.
    ///
    /// - Parameters:
    ///   - path: The path of the `.framework`.
    ///   - debugSymbols: dSYM bundles or bcsymbolmap files to include.
    public init(_ path: FilePath, debugSymbols: [FilePath] = []) {
        self.content = .framework(path, debugSymbols: debugSymbols)
    }

    /// Adds a framework from an archive, by name (`-archive`, `-framework`).
    ///
    /// - Parameters:
    ///   - name: The name of the framework, such as `MyKit.framework`.
    ///   - archive: The archive that contains it.
    ///   - debugSymbols: dSYM bundles or bcsymbolmap files to include.
    public init(named name: FilePath, inArchive archive: FilePath, debugSymbols: [FilePath] = []) {
        self.content = .framework(named: name, inArchive: archive, debugSymbols: debugSymbols)
    }

    public func apply(to command: inout CreateXCFrameworkCommand) {
        command.contents.append(content)
    }
}

/// Adds a static or dynamic library to an XCFramework (`-library`).
public struct Library: XcodeBuildCommandComponent {
    /// The library.
    public var content: XCFrameworkContent

    /// Adds the library at a path.
    ///
    /// - Parameters:
    ///   - path: The path of the library.
    ///   - headers: The directory of its headers.
    ///   - debugSymbols: dSYM bundles or bcsymbolmap files to include.
    public init(_ path: FilePath, headers: FilePath? = nil, debugSymbols: [FilePath] = []) {
        self.content = .library(path, headers: headers, debugSymbols: debugSymbols)
    }

    /// Adds a library from an archive, by name (`-archive`, `-library`).
    ///
    /// - Parameters:
    ///   - name: The name of the library, such as `libMyKit.a`.
    ///   - archive: The archive that contains it.
    ///   - headers: The directory of its headers.
    ///   - debugSymbols: dSYM bundles or bcsymbolmap files to include.
    public init(named name: FilePath, inArchive archive: FilePath, headers: FilePath? = nil, debugSymbols: [FilePath] = []) {
        self.content = .library(named: name, inArchive: archive, headers: headers, debugSymbols: debugSymbols)
    }

    public func apply(to command: inout CreateXCFrameworkCommand) {
        command.contents.append(content)
    }
}

/// Marks the XCFramework as containing information not suitable for public
/// distribution (`-allow-internal-distribution`).
public struct AllowInternalDistribution: XcodeBuildCommandComponent {
    /// Creates the component.
    public init() {}

    public func apply(to command: inout CreateXCFrameworkCommand) {
        command.allowInternalDistribution = true
    }
}

/// Sets the model code of the device, such as `iPhone16,1` (`-modelCode`).
public struct ModelCode: XcodeBuildCommandComponent {
    /// The model code.
    public var code: String

    /// Creates the component.
    public init(_ code: String) {
        self.code = code
    }

    public func apply(to command: inout PrepareDeviceSupportCommand) {
        command.modelCode = code
    }
}

/// Sets the architecture of the device, such as `arm64e` (`-architecture`).
public struct DeviceArchitecture: XcodeBuildCommandComponent {
    /// The architecture.
    public var name: String

    /// Creates the component.
    public init(_ name: String) {
        self.name = name
    }

    public func apply(to command: inout PrepareDeviceSupportCommand) {
        command.architecture = name
    }
}

/// Also checks for newer device support components (`-checkForNewerComponents`).
public struct CheckForNewerComponents: XcodeBuildCommandComponent {
    /// Creates the component.
    public init() {}

    public func apply(to command: inout RunFirstLaunchCommand) {
        command.checkForNewerComponents = true
    }
}
