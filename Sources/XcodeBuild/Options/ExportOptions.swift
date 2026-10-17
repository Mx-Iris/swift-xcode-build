import Foundation

/// The settings for exporting an archive, which xcodebuild reads from the
/// property list passed with `-exportOptionsPlist`.
///
/// Every key that `xcodebuild -help` lists has a property; keys left `nil`
/// are left out of the property list, so xcodebuild's defaults apply.
///
/// ```swift
/// var options = ExportOptions(method: .appStoreConnect)
/// options.destination = .upload
/// options.teamIdentifier = "ABCDE12345"
/// let export = ExportArchiveCommand(archivePath: "build/App.xcarchive", exportOptions: .options(options))
/// ```
public struct ExportOptions: Sendable, Hashable {
    /// How to export the archive (`method`). Defaults to ``ExportMethod/debugging``.
    public var method: ExportMethod?

    /// Whether to export locally or upload to Apple (`destination`). Defaults
    /// to ``ExportDestination/export``.
    public var destination: ExportDestination?

    /// The team to export for (`teamID`). Defaults to the team the archive was built with.
    public var teamIdentifier: String?

    /// The signing style when re-signing for distribution (`signingStyle`).
    /// Defaults to the style the archive was signed with.
    public var signingStyle: SigningStyle?

    /// For manual signing, the certificate to sign with: a name, a SHA-1
    /// hash, or an automatic selector such as `Apple Distribution`
    /// (`signingCertificate`).
    public var signingCertificate: String?

    /// For manual signing, the certificate to sign the installer package
    /// with: a name, a SHA-1 hash, or `Developer ID Installer` or
    /// `Mac Installer Distribution` (`installerSigningCertificate`).
    public var installerSigningCertificate: String?

    /// For manual signing, the provisioning profile, by name or UUID, for each
    /// executable, keyed by bundle identifier or by path relative to the
    /// archive's `Products` directory (`provisioningProfiles`).
    public var provisioningProfiles: [String: String]?

    /// The bundle identifier of the target to focus the export on
    /// (`distributionBundleIdentifier`). Defaults to the top-level bundle identifier.
    public var distributionBundleIdentifier: String?

    /// The CloudKit container environment for the
    /// `com.apple.developer.icloud-container-environment` entitlement
    /// (`iCloudContainerEnvironment`).
    public var iCloudContainerEnvironment: CloudContainerEnvironment?

    /// For App Store exports, whether Xcode manages the build number when
    /// uploading (`manageAppVersionAndBuildNumber`). Defaults to `true`.
    public var manageAppVersionAndBuildNumber: Bool?

    /// For App Store exports, whether to generate App Store information for
    /// uploading with iTMSTransporter (`generateAppStoreInformation`).
    /// Defaults to `false`.
    public var generateAppStoreInformation: Bool?

    /// For App Store exports, whether the package includes symbols
    /// (`uploadSymbols`). Defaults to `true`.
    public var uploadSymbols: Bool?

    /// Whether to strip symbols from Swift libraries (`stripSwiftSymbols`). Defaults to `true`.
    public var stripSwiftSymbols: Bool?

    /// Whether the build may be distributed only to internal TestFlight
    /// testers (`testFlightInternalTestingOnly`).
    public var testFlightInternalTestingOnly: Bool?

    /// For non-App Store exports, how to thin the app for device variants (`thinning`).
    public var thinning: AppThinning?

    /// For non-App Store exports, the distribution manifest for installing
    /// the app over the web (`manifest`).
    public var manifest: DistributionManifest?

    /// For non-App Store exports, whether on-demand resource asset packs are
    /// embedded in the app (`embedOnDemandResourcesAssetPacksInBundle`).
    public var embedOnDemandResourcesAssetPacksInBundle: Bool?

    /// For non-App Store exports, the base URL where on-demand resource asset
    /// packs are hosted (`onDemandResourcesAssetPacksBaseURL`).
    public var onDemandResourcesAssetPacksBaseURL: String?

    /// Creates export options.
    public init(method: ExportMethod? = nil) {
        self.method = method
    }

    /// The options as an XML property list.
    public func propertyList() throws(XcodeBuildError) -> [UInt8] {
        var dictionary: [String: Any] = [:]
        dictionary["method"] = method?.rawValue
        dictionary["destination"] = destination?.rawValue
        dictionary["teamID"] = teamIdentifier
        dictionary["signingStyle"] = signingStyle?.rawValue
        dictionary["signingCertificate"] = signingCertificate
        dictionary["installerSigningCertificate"] = installerSigningCertificate
        dictionary["provisioningProfiles"] = provisioningProfiles
        dictionary["distributionBundleIdentifier"] = distributionBundleIdentifier
        dictionary["iCloudContainerEnvironment"] = iCloudContainerEnvironment?.rawValue
        dictionary["manageAppVersionAndBuildNumber"] = manageAppVersionAndBuildNumber
        dictionary["generateAppStoreInformation"] = generateAppStoreInformation
        dictionary["uploadSymbols"] = uploadSymbols
        dictionary["stripSwiftSymbols"] = stripSwiftSymbols
        dictionary["testFlightInternalTestingOnly"] = testFlightInternalTestingOnly
        dictionary["thinning"] = thinning?.rawValue
        dictionary["manifest"] = manifest?.propertyListValue
        dictionary["embedOnDemandResourcesAssetPacksInBundle"] = embedOnDemandResourcesAssetPacksInBundle
        dictionary["onDemandResourcesAssetPacksBaseURL"] = onDemandResourcesAssetPacksBaseURL
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: dictionary, format: .xml, options: 0)
            return Array(data)
        } catch {
            throw XcodeBuildError(
                code: .temporaryFileFailed,
                commandLine: [],
                reason: "the export options could not be encoded as a property list",
                underlyingError: error
            )
        }
    }
}

/// How xcodebuild exports an archive.
public struct ExportMethod: RawRepresentable, Sendable, Hashable {
    /// The method as xcodebuild spells it.
    public var rawValue: String

    /// Creates a method from its xcodebuild spelling.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Distribution through App Store Connect, to TestFlight and the App Store.
    public static var appStoreConnect: ExportMethod {
        ExportMethod(rawValue: "app-store-connect")
    }

    /// Distribution to registered devices for testing; formerly ad hoc.
    public static var releaseTesting: ExportMethod {
        ExportMethod(rawValue: "release-testing")
    }

    /// Distribution within an organization through the Apple Developer Enterprise Program.
    public static var enterprise: ExportMethod {
        ExportMethod(rawValue: "enterprise")
    }

    /// Development builds for registered devices; formerly development. The default.
    public static var debugging: ExportMethod {
        ExportMethod(rawValue: "debugging")
    }

    /// Distribution outside the Mac App Store, signed with a Developer ID.
    public static var developerID: ExportMethod {
        ExportMethod(rawValue: "developer-id")
    }

    /// A Mac app exported without re-signing.
    public static var macApplication: ExportMethod {
        ExportMethod(rawValue: "mac-application")
    }

    /// Validation with App Store Connect without uploading.
    public static var validation: ExportMethod {
        ExportMethod(rawValue: "validation")
    }

    /// The former name of ``appStoreConnect``.
    @available(*, deprecated, renamed: "appStoreConnect")
    public static var appStore: ExportMethod {
        ExportMethod(rawValue: "app-store")
    }

    /// The former name of ``releaseTesting``.
    @available(*, deprecated, renamed: "releaseTesting")
    public static var adHoc: ExportMethod {
        ExportMethod(rawValue: "ad-hoc")
    }

    /// The former name of ``debugging``.
    @available(*, deprecated, renamed: "debugging")
    public static var development: ExportMethod {
        ExportMethod(rawValue: "development")
    }
}

/// Whether an export is written locally or uploaded to Apple.
public struct ExportDestination: RawRepresentable, Sendable, Hashable {
    /// The value as xcodebuild spells it.
    public var rawValue: String

    /// Creates a value from its xcodebuild spelling.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Write the exported product to the export path.
    public static var export: ExportDestination {
        ExportDestination(rawValue: "export")
    }

    /// Upload the exported product to Apple.
    public static var upload: ExportDestination {
        ExportDestination(rawValue: "upload")
    }
}

/// How an export is signed.
public struct SigningStyle: RawRepresentable, Sendable, Hashable {
    /// The value as xcodebuild spells it.
    public var rawValue: String

    /// Creates a value from its xcodebuild spelling.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// With the certificates and profiles you name.
    public static var manual: SigningStyle {
        SigningStyle(rawValue: "manual")
    }

    /// With certificates and profiles Xcode manages.
    public static var automatic: SigningStyle {
        SigningStyle(rawValue: "automatic")
    }
}

/// A CloudKit container environment.
public struct CloudContainerEnvironment: RawRepresentable, Sendable, Hashable {
    /// The value as xcodebuild spells it.
    public var rawValue: String

    /// Creates a value from its xcodebuild spelling.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// The development environment. The default for development signing.
    public static var development: CloudContainerEnvironment {
        CloudContainerEnvironment(rawValue: "Development")
    }

    /// The production environment. The default for distribution signing.
    public static var production: CloudContainerEnvironment {
        CloudContainerEnvironment(rawValue: "Production")
    }
}

/// How an exported app is thinned for device variants.
public struct AppThinning: RawRepresentable, Sendable, Hashable {
    /// The value as xcodebuild spells it.
    public var rawValue: String

    /// Creates a value from its xcodebuild spelling.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// A universal app that is not thinned (`<none>`). The default.
    public static var universal: AppThinning {
        AppThinning(rawValue: "<none>")
    }

    /// A universal app and a thinned variant for every device (`<thin-for-all-variants>`).
    public static var allVariants: AppThinning {
        AppThinning(rawValue: "<thin-for-all-variants>")
    }

    /// A variant for one device model, such as `iPhone7,1`.
    public static func device(modelIdentifier: String) -> AppThinning {
        AppThinning(rawValue: modelIdentifier)
    }
}

/// The distribution manifest for installing an app over the web.
public struct DistributionManifest: Sendable, Hashable {
    /// The URL of the app (`appURL`).
    public var appURL: String

    /// The URL of the image shown while the app downloads (`displayImageURL`).
    public var displayImageURL: String

    /// The URL of the full-size image (`fullSizeImageURL`).
    public var fullSizeImageURL: String

    /// The URL of the asset pack manifest, required for apps with on-demand
    /// resources (`assetPackManifestURL`).
    public var assetPackManifestURL: String?

    /// Creates a manifest.
    public init(appURL: String, displayImageURL: String, fullSizeImageURL: String, assetPackManifestURL: String? = nil) {
        self.appURL = appURL
        self.displayImageURL = displayImageURL
        self.fullSizeImageURL = fullSizeImageURL
        self.assetPackManifestURL = assetPackManifestURL
    }

    var propertyListValue: [String: String] {
        var dictionary = [
            "appURL": appURL,
            "displayImageURL": displayImageURL,
            "fullSizeImageURL": fullSizeImageURL,
        ]
        dictionary["assetPackManifestURL"] = assetPackManifestURL
        return dictionary
    }
}
