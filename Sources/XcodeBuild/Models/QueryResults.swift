/// The build settings of one target, as `-showBuildSettings` reports them.
public struct TargetBuildSettings: Sendable, Hashable {
    /// The action the settings are for, such as `build`.
    public var action: String

    /// The name of the target.
    public var target: String

    /// The resolved build settings, by name.
    public var buildSettings: [String: String]

    /// Creates target build settings.
    public init(action: String, target: String, buildSettings: [String: String]) {
        self.action = action
        self.target = target
        self.buildSettings = buildSettings
    }

    /// The value of a build setting, such as `PRODUCT_BUNDLE_IDENTIFIER`.
    public subscript(name: String) -> String? {
        buildSettings[name]
    }
}

/// The JSON for one target that `-showBuildSettings -json` prints.
struct TargetBuildSettingsJSON: Decodable {
    var action: String
    var target: String
    var buildSettings: [String: String]

    var settings: TargetBuildSettings {
        TargetBuildSettings(action: action, target: target, buildSettings: buildSettings)
    }
}

/// The version of Xcode, as `-version` reports it.
public struct XcodeVersion: Sendable, Hashable {
    /// The marketing version, such as `27.2`.
    public var version: String

    /// The build, such as `27B5038j`.
    public var buildVersion: String

    /// Creates a version.
    public init(version: String, buildVersion: String) {
        self.version = version
        self.buildVersion = buildVersion
    }
}

/// An optional Xcode component, as `-showComponent` reports it.
public struct ComponentDescription: Sendable, Hashable {
    /// The build of the component that matches this Xcode, such as `27B5038h`.
    public var buildVersion: String

    /// Whether the component is installed, such as `installed` or `uninstalled`.
    public var status: String

    /// Creates a component description.
    public init(buildVersion: String, status: String) {
        self.buildVersion = buildVersion
        self.status = status
    }
}

/// The JSON that `-showComponent -json` prints.
struct ComponentJSON: Decodable {
    var buildVersion: String
    var status: String
}

/// The JSON that `-showTestPlans -json` prints.
struct TestPlansJSON: Decodable {
    struct TestPlan: Decodable {
        var name: String
    }

    var testPlans: [TestPlan]
}
