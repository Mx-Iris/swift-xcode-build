public import System

/// An installed SDK, as `-showsdks` and `-version -sdk` report it.
public struct SDKDescription: Sendable, Hashable {
    /// The name to pass to `-sdk`, such as `iphoneos27.2`.
    public var canonicalName: String

    /// The name to show, such as `iOS 27.2` or `Simulator - iOS 27.2`.
    public var displayName: String

    /// The platform, such as `iphoneos`, `iphonesimulator`, or `macosx`.
    public var platform: String

    /// The version of the platform, such as `27.2`.
    public var platformVersion: String

    /// The path of the platform directory.
    public var platformPath: FilePath

    /// The version of the SDK, such as `27.2`.
    public var version: String

    /// The path of the SDK.
    public var path: FilePath

    /// Whether the SDK can be the base SDK of a target.
    public var isBaseSDK: Bool

    /// The build identifier of the SDK.
    public var buildIdentifier: String?

    /// The name of the operating system, such as `iPhone OS` or `macOS`.
    public var productName: String?

    /// The version of the operating system, such as `27.2`.
    public var productVersion: String?

    /// The version of the operating system as shown to users.
    public var productUserVisibleVersion: String?

    /// The build of the operating system, such as `24B5109a`.
    public var productBuildVersion: String?

    /// The copyright notice of the operating system.
    public var productCopyright: String?

    /// For macOS SDKs, the version of iOS that Mac Catalyst apps can use.
    public var iOSSupportVersion: String?

    /// Creates an SDK description.
    public init(
        canonicalName: String,
        displayName: String,
        platform: String,
        platformVersion: String,
        platformPath: FilePath,
        version: String,
        path: FilePath,
        isBaseSDK: Bool,
        buildIdentifier: String? = nil,
        productName: String? = nil,
        productVersion: String? = nil,
        productUserVisibleVersion: String? = nil,
        productBuildVersion: String? = nil,
        productCopyright: String? = nil,
        iOSSupportVersion: String? = nil
    ) {
        self.canonicalName = canonicalName
        self.displayName = displayName
        self.platform = platform
        self.platformVersion = platformVersion
        self.platformPath = platformPath
        self.version = version
        self.path = path
        self.isBaseSDK = isBaseSDK
        self.buildIdentifier = buildIdentifier
        self.productName = productName
        self.productVersion = productVersion
        self.productUserVisibleVersion = productUserVisibleVersion
        self.productBuildVersion = productBuildVersion
        self.productCopyright = productCopyright
        self.iOSSupportVersion = iOSSupportVersion
    }
}

/// The JSON for one SDK that `-showsdks -json` and `-version -sdk -json` print.
struct SDKJSON: Decodable {
    var canonicalName: String
    var displayName: String
    var platform: String
    var platformVersion: String
    var platformPath: String
    var sdkVersion: String
    var sdkPath: String
    var isBaseSdk: Bool?
    var buildID: String?
    var productName: String?
    var productVersion: String?
    var productUserVisibleVersion: String?
    var productBuildVersion: String?
    var productCopyright: String?
    var iOSSupportVersion: String?

    var description: SDKDescription {
        SDKDescription(
            canonicalName: canonicalName,
            displayName: displayName,
            platform: platform,
            platformVersion: platformVersion,
            platformPath: FilePath(platformPath),
            version: sdkVersion,
            path: FilePath(sdkPath),
            isBaseSDK: isBaseSdk ?? false,
            buildIdentifier: buildID,
            productName: productName,
            productVersion: productVersion,
            productUserVisibleVersion: productUserVisibleVersion,
            productBuildVersion: productBuildVersion,
            productCopyright: productCopyright,
            iOSSupportVersion: iOSSupportVersion
        )
    }
}

/// Either one SDK or a list of them, since `-version -sdk -json` has printed both.
enum SDKListJSON: Decodable {
    case list([SDKJSON])
    case single(SDKJSON)

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let list = try? container.decode([SDKJSON].self) {
            self = .list(list)
        } else {
            self = .single(try container.decode(SDKJSON.self))
        }
    }

    var descriptions: [SDKDescription] {
        switch self {
        case .list(let list):
            list.map(\.description)
        case .single(let single):
            [single.description]
        }
    }
}
