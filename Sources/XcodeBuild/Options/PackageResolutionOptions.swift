public import System

/// Options for resolving and fetching Swift package dependencies.
///
/// Options set to `nil` or `false` are left out, so xcodebuild's defaults apply.
public struct PackageResolutionOptions: Sendable, Hashable {
    /// Where remote packages are cloned, or are expected to be found
    /// (`-clonedSourcePackagesDirPath`).
    public var clonedSourcePackagesDirectory: FilePath?

    /// Where package caches are kept (`-packageCachePath`).
    public var packageCachePath: FilePath?

    /// Whether to keep packages at the versions recorded in `Package.resolved`
    /// instead of resolving them again (`-disableAutomaticPackageResolution`).
    public var disableAutomaticPackageResolution: Bool

    /// Whether to fail rather than resolve packages to versions other than
    /// those in `Package.resolved` (`-onlyUsePackageVersionsFromResolvedFile`).
    public var onlyUsePackageVersionsFromResolvedFile: Bool

    /// Whether to skip updating packages from their remotes (`-skipPackageUpdates`).
    public var skipPackageUpdates: Bool

    /// Whether to skip the local cache of remote package repositories
    /// (`-disablePackageRepositoryCache`).
    public var disablePackageRepositoryCache: Bool

    /// Whether to skip the validation of package plugins
    /// (`-skipPackagePluginValidation`). Only for plugins from trusted sources.
    public var skipPackagePluginValidation: Bool

    /// Whether to skip the validation of macros (`-skipMacroValidation`).
    /// Only for macros from trusted sources.
    public var skipMacroValidation: Bool

    /// Whether to skip the validation of package signatures
    /// (`-skipPackageSignatureValidation`). Only for packages from trusted sources.
    public var skipPackageSignatureValidation: Bool

    /// Where to find credentials for package repositories and registries
    /// (`-packageAuthorizationProvider`).
    public var packageAuthorizationProvider: PackageCredentialStore?

    /// The URL of the default package registry (`-defaultPackageRegistryURL`).
    public var defaultPackageRegistryURL: String?

    /// How to turn source control dependencies into registry dependencies
    /// (`-packageDependencySCMToRegistryTransformation`).
    public var registryTransformation: RegistryTransformation?

    /// What to do when a package's fingerprint changes (`-packageFingerprintPolicy`).
    public var packageFingerprintPolicy: PackageSecurityPolicy?

    /// What to do when a package's signing entity changes (`-packageSigningEntityPolicy`).
    public var packageSigningEntityPolicy: PackageSecurityPolicy?

    /// Which implementation of Git to use (`-scmProvider`).
    public var sourceControlProvider: GitProvider?

    /// Creates package options that leave everything to xcodebuild.
    public init() {
        self.disableAutomaticPackageResolution = false
        self.onlyUsePackageVersionsFromResolvedFile = false
        self.skipPackageUpdates = false
        self.disablePackageRepositoryCache = false
        self.skipPackagePluginValidation = false
        self.skipMacroValidation = false
        self.skipPackageSignatureValidation = false
    }

    func render(into writer: inout ArgumentWriter) {
        writer.option("-clonedSourcePackagesDirPath", clonedSourcePackagesDirectory)
        writer.option("-packageCachePath", packageCachePath)
        writer.flag("-disableAutomaticPackageResolution", disableAutomaticPackageResolution)
        writer.flag("-onlyUsePackageVersionsFromResolvedFile", onlyUsePackageVersionsFromResolvedFile)
        writer.flag("-skipPackageUpdates", skipPackageUpdates)
        writer.flag("-disablePackageRepositoryCache", disablePackageRepositoryCache)
        writer.flag("-skipPackagePluginValidation", skipPackagePluginValidation)
        writer.flag("-skipMacroValidation", skipMacroValidation)
        writer.flag("-skipPackageSignatureValidation", skipPackageSignatureValidation)
        writer.option("-packageAuthorizationProvider", packageAuthorizationProvider)
        writer.option("-defaultPackageRegistryURL", defaultPackageRegistryURL)
        writer.option("-packageDependencySCMToRegistryTransformation", registryTransformation)
        writer.option("-packageFingerprintPolicy", packageFingerprintPolicy)
        writer.option("-packageSigningEntityPolicy", packageSigningEntityPolicy)
        writer.option("-scmProvider", sourceControlProvider)
    }
}

/// Where xcodebuild finds credentials for package repositories and registries.
public struct PackageCredentialStore: RawRepresentable, Sendable, Hashable {
    /// The value as xcodebuild spells it.
    public var rawValue: String

    /// Creates a value from its xcodebuild spelling.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// The keychain.
    public static var keychain: PackageCredentialStore {
        PackageCredentialStore(rawValue: "keychain")
    }

    /// A `.netrc` file.
    public static var netrc: PackageCredentialStore {
        PackageCredentialStore(rawValue: "netrc")
    }
}

/// How source control package dependencies are turned into registry dependencies.
public struct RegistryTransformation: RawRepresentable, Sendable, Hashable {
    /// The value as xcodebuild spells it.
    public var rawValue: String

    /// Creates a value from its xcodebuild spelling.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Keep source control dependencies as they are (`none`).
    public static var disabled: RegistryTransformation {
        RegistryTransformation(rawValue: "none")
    }

    /// Identify packages by their registry identity (`useRegistryIdentity`).
    public static var useRegistryIdentity: RegistryTransformation {
        RegistryTransformation(rawValue: "useRegistryIdentity")
    }

    /// Identify packages by their registry identity and fetch them from the
    /// registry (`useRegistryIdentityAndSources`).
    public static var useRegistryIdentityAndSources: RegistryTransformation {
        RegistryTransformation(rawValue: "useRegistryIdentityAndSources")
    }
}

/// What xcodebuild does when a package security check finds a change.
public struct PackageSecurityPolicy: RawRepresentable, Sendable, Hashable {
    /// The value as xcodebuild spells it.
    public var rawValue: String

    /// Creates a value from its xcodebuild spelling.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Print a warning and continue.
    public static var warn: PackageSecurityPolicy {
        PackageSecurityPolicy(rawValue: "warn")
    }

    /// Fail.
    public static var strict: PackageSecurityPolicy {
        PackageSecurityPolicy(rawValue: "strict")
    }
}

/// The implementation of Git that xcodebuild uses for packages.
public struct GitProvider: RawRepresentable, Sendable, Hashable {
    /// The value as xcodebuild spells it.
    public var rawValue: String

    /// Creates a value from its xcodebuild spelling.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// The `git` command-line tool, which honours the user's Git configuration.
    public static var system: GitProvider {
        GitProvider(rawValue: "system")
    }

    /// Xcode's built-in Git.
    public static var xcode: GitProvider {
        GitProvider(rawValue: "xcode")
    }
}
