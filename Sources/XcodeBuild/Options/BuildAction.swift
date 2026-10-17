/// A build action, such as `build`, `test`, or `archive`.
///
/// ``BuildCommand`` runs one or more actions in order: `clean build` cleans
/// and then builds.
public struct BuildAction: RawRepresentable, Sendable, Hashable {
    /// The action as xcodebuild spells it.
    public var rawValue: String

    /// Creates an action from its xcodebuild spelling.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Builds the target in the build root. The default when no action is given.
    public static var build: BuildAction {
        BuildAction(rawValue: "build")
    }

    /// Builds the target and its tests, and writes an xctestrun file to the
    /// build root (`build-for-testing`). Requires a scheme.
    public static var buildForTesting: BuildAction {
        BuildAction(rawValue: "build-for-testing")
    }

    /// Builds and analyzes the target or scheme. Requires a scheme.
    public static var analyze: BuildAction {
        BuildAction(rawValue: "analyze")
    }

    /// Archives the scheme. Requires a scheme.
    public static var archive: BuildAction {
        BuildAction(rawValue: "archive")
    }

    /// Builds and tests the scheme. Requires a scheme.
    public static var test: BuildAction {
        BuildAction(rawValue: "test")
    }

    /// Tests bundles that were already built, found through the scheme or
    /// an xctestrun file (`test-without-building`).
    public static var testWithoutBuilding: BuildAction {
        BuildAction(rawValue: "test-without-building")
    }

    /// Builds the target and its documentation (`docbuild`).
    public static var buildDocumentation: BuildAction {
        BuildAction(rawValue: "docbuild")
    }

    /// Copies the project's source to the source root (`installsrc`).
    public static var installSource: BuildAction {
        BuildAction(rawValue: "installsrc")
    }

    /// Builds the target and installs it into the distribution root.
    public static var install: BuildAction {
        BuildAction(rawValue: "install")
    }

    /// Removes build products and intermediate files from the build root.
    public static var clean: BuildAction {
        BuildAction(rawValue: "clean")
    }
}

extension BuildAction: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}
