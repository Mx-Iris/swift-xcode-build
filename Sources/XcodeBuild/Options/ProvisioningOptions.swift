public import System

/// Options that let xcodebuild talk to the Apple Developer website for signing.
public struct ProvisioningOptions: Sendable, Hashable {
    /// Whether xcodebuild may create and update provisioning profiles, app
    /// IDs, and certificates for automatically signed targets, and download
    /// profiles for manually signed ones (`-allowProvisioningUpdates`).
    ///
    /// Requires an account in Xcode's settings or an ``authenticationKey``.
    public var allowProvisioningUpdates: Bool

    /// Whether xcodebuild may register the destination device on the
    /// developer website (`-allowProvisioningDeviceRegistration`). Requires
    /// ``allowProvisioningUpdates``.
    public var allowProvisioningDeviceRegistration: Bool

    /// An App Store Connect API key to authenticate with instead of an
    /// account in Xcode's settings.
    public var authenticationKey: AppStoreConnectKey?

    /// Creates provisioning options.
    public init(
        allowProvisioningUpdates: Bool = false,
        allowProvisioningDeviceRegistration: Bool = false,
        authenticationKey: AppStoreConnectKey? = nil
    ) {
        self.allowProvisioningUpdates = allowProvisioningUpdates
        self.allowProvisioningDeviceRegistration = allowProvisioningDeviceRegistration
        self.authenticationKey = authenticationKey
    }

    func render(into writer: inout ArgumentWriter) {
        writer.flag("-allowProvisioningUpdates", allowProvisioningUpdates)
        writer.flag("-allowProvisioningDeviceRegistration", allowProvisioningDeviceRegistration)
        if let authenticationKey {
            writer.option("-authenticationKeyPath", authenticationKey.path)
            writer.option("-authenticationKeyID", authenticationKey.identifier)
            writer.option("-authenticationKeyIssuerID", authenticationKey.issuerIdentifier)
        }
    }
}

/// An App Store Connect API key, which xcodebuild uses to authenticate with
/// the Apple Developer website.
///
/// The identifier and the issuer identifier are shown with the key in the
/// Users and Access section of App Store Connect.
public struct AppStoreConnectKey: Sendable, Hashable {
    /// The path of the `.p8` key file (`-authenticationKeyPath`).
    public var path: FilePath

    /// The key identifier (`-authenticationKeyID`).
    public var identifier: String

    /// The issuer identifier (`-authenticationKeyIssuerID`).
    public var issuerIdentifier: String

    /// Creates a key.
    public init(path: FilePath, identifier: String, issuerIdentifier: String) {
        self.path = path
        self.identifier = identifier
        self.issuerIdentifier = issuerIdentifier
    }
}
