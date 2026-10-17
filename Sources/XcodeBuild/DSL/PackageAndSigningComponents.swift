public import System

// Components for ``PackageResolutionOptions`` and ``ProvisioningOptions``.

/// Clones remote packages into a directory, or expects them there (`-clonedSourcePackagesDirPath`).
public struct ClonedSourcePackagesDirectory<Command: PackageResolutionConfigurable>: XcodeBuildCommandComponent {
    /// The directory.
    public var path: FilePath

    /// Creates the component.
    public init(_ path: FilePath) {
        self.path = path
    }

    public func apply(to command: inout Command) {
        command.packageResolution.clonedSourcePackagesDirectory = path
    }
}

/// Keeps package caches in a directory (`-packageCachePath`).
public struct PackageCachePath<Command: PackageResolutionConfigurable>: XcodeBuildCommandComponent {
    /// The directory.
    public var path: FilePath

    /// Creates the component.
    public init(_ path: FilePath) {
        self.path = path
    }

    public func apply(to command: inout Command) {
        command.packageResolution.packageCachePath = path
    }
}

/// Keeps packages at the versions in `Package.resolved` (`-disableAutomaticPackageResolution`).
public struct DisableAutomaticPackageResolution<Command: PackageResolutionConfigurable>: XcodeBuildCommandComponent {
    /// Creates the component.
    public init() {}

    public func apply(to command: inout Command) {
        command.packageResolution.disableAutomaticPackageResolution = true
    }
}

/// Fails rather than resolve packages to versions not in `Package.resolved`
/// (`-onlyUsePackageVersionsFromResolvedFile`).
public struct OnlyUsePackageVersionsFromResolvedFile<Command: PackageResolutionConfigurable>: XcodeBuildCommandComponent {
    /// Creates the component.
    public init() {}

    public func apply(to command: inout Command) {
        command.packageResolution.onlyUsePackageVersionsFromResolvedFile = true
    }
}

/// Skips updating packages from their remotes (`-skipPackageUpdates`).
public struct SkipPackageUpdates<Command: PackageResolutionConfigurable>: XcodeBuildCommandComponent {
    /// Creates the component.
    public init() {}

    public func apply(to command: inout Command) {
        command.packageResolution.skipPackageUpdates = true
    }
}

/// Skips the local cache of remote package repositories (`-disablePackageRepositoryCache`).
public struct DisablePackageRepositoryCache<Command: PackageResolutionConfigurable>: XcodeBuildCommandComponent {
    /// Creates the component.
    public init() {}

    public func apply(to command: inout Command) {
        command.packageResolution.disablePackageRepositoryCache = true
    }
}

/// Skips the validation of package plugins (`-skipPackagePluginValidation`).
/// Only for plugins from trusted sources.
public struct SkipPackagePluginValidation<Command: PackageResolutionConfigurable>: XcodeBuildCommandComponent {
    /// Creates the component.
    public init() {}

    public func apply(to command: inout Command) {
        command.packageResolution.skipPackagePluginValidation = true
    }
}

/// Skips the validation of macros (`-skipMacroValidation`). Only for macros
/// from trusted sources.
public struct SkipMacroValidation<Command: PackageResolutionConfigurable>: XcodeBuildCommandComponent {
    /// Creates the component.
    public init() {}

    public func apply(to command: inout Command) {
        command.packageResolution.skipMacroValidation = true
    }
}

/// Skips the validation of package signatures (`-skipPackageSignatureValidation`).
/// Only for packages from trusted sources.
public struct SkipPackageSignatureValidation<Command: PackageResolutionConfigurable>: XcodeBuildCommandComponent {
    /// Creates the component.
    public init() {}

    public func apply(to command: inout Command) {
        command.packageResolution.skipPackageSignatureValidation = true
    }
}

/// Finds package credentials in a store (`-packageAuthorizationProvider`).
public struct PackageAuthorizationProvider<Command: PackageResolutionConfigurable>: XcodeBuildCommandComponent {
    /// The credential store.
    public var store: PackageCredentialStore

    /// Creates the component.
    public init(_ store: PackageCredentialStore) {
        self.store = store
    }

    public func apply(to command: inout Command) {
        command.packageResolution.packageAuthorizationProvider = store
    }
}

/// Uses a default package registry (`-defaultPackageRegistryURL`).
public struct DefaultPackageRegistryURL<Command: PackageResolutionConfigurable>: XcodeBuildCommandComponent {
    /// The URL of the registry.
    public var url: String

    /// Creates the component.
    public init(_ url: String) {
        self.url = url
    }

    public func apply(to command: inout Command) {
        command.packageResolution.defaultPackageRegistryURL = url
    }
}

/// Turns source control dependencies into registry dependencies
/// (`-packageDependencySCMToRegistryTransformation`).
public struct PackageRegistryTransformation<Command: PackageResolutionConfigurable>: XcodeBuildCommandComponent {
    /// The transformation.
    public var transformation: RegistryTransformation

    /// Creates the component.
    public init(_ transformation: RegistryTransformation) {
        self.transformation = transformation
    }

    public func apply(to command: inout Command) {
        command.packageResolution.registryTransformation = transformation
    }
}

/// Sets what happens when a package's fingerprint changes (`-packageFingerprintPolicy`).
public struct PackageFingerprintPolicy<Command: PackageResolutionConfigurable>: XcodeBuildCommandComponent {
    /// The policy.
    public var policy: PackageSecurityPolicy

    /// Creates the component.
    public init(_ policy: PackageSecurityPolicy) {
        self.policy = policy
    }

    public func apply(to command: inout Command) {
        command.packageResolution.packageFingerprintPolicy = policy
    }
}

/// Sets what happens when a package's signing entity changes (`-packageSigningEntityPolicy`).
public struct PackageSigningEntityPolicy<Command: PackageResolutionConfigurable>: XcodeBuildCommandComponent {
    /// The policy.
    public var policy: PackageSecurityPolicy

    /// Creates the component.
    public init(_ policy: PackageSecurityPolicy) {
        self.policy = policy
    }

    public func apply(to command: inout Command) {
        command.packageResolution.packageSigningEntityPolicy = policy
    }
}

/// Uses an implementation of Git for packages (`-scmProvider`).
public struct SourceControlProvider<Command: PackageResolutionConfigurable>: XcodeBuildCommandComponent {
    /// The implementation.
    public var provider: GitProvider

    /// Creates the component.
    public init(_ provider: GitProvider) {
        self.provider = provider
    }

    public func apply(to command: inout Command) {
        command.packageResolution.sourceControlProvider = provider
    }
}

/// Lets xcodebuild update signing assets on the developer website (`-allowProvisioningUpdates`).
public struct AllowProvisioningUpdates<Command: ProvisioningConfigurable>: XcodeBuildCommandComponent {
    /// Creates the component.
    public init() {}

    public func apply(to command: inout Command) {
        command.provisioning.allowProvisioningUpdates = true
    }
}

/// Lets xcodebuild register the destination device on the developer website
/// (`-allowProvisioningDeviceRegistration`).
public struct AllowProvisioningDeviceRegistration<Command: ProvisioningConfigurable>: XcodeBuildCommandComponent {
    /// Creates the component.
    public init() {}

    public func apply(to command: inout Command) {
        command.provisioning.allowProvisioningDeviceRegistration = true
    }
}

/// Authenticates with an App Store Connect API key (`-authenticationKeyPath`,
/// `-authenticationKeyID`, `-authenticationKeyIssuerID`).
public struct AuthenticationKey<Command: ProvisioningConfigurable>: XcodeBuildCommandComponent {
    /// The key.
    public var key: AppStoreConnectKey

    /// Creates the component.
    public init(path: FilePath, identifier: String, issuerIdentifier: String) {
        self.key = AppStoreConnectKey(path: path, identifier: identifier, issuerIdentifier: issuerIdentifier)
    }

    /// Creates the component.
    public init(_ key: AppStoreConnectKey) {
        self.key = key
    }

    public func apply(to command: inout Command) {
        command.provisioning.authenticationKey = key
    }
}
