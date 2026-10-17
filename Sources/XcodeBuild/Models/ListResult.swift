/// What `-list` reports about a project or workspace.
public enum ListResult: Sendable, Hashable {
    /// An Xcode project.
    case project(ProjectListing)

    /// A workspace, including a Swift package opened as one.
    case workspace(WorkspaceListing)

    /// The name of the project or workspace.
    public var name: String {
        switch self {
        case .project(let project):
            project.name
        case .workspace(let workspace):
            workspace.name
        }
    }

    /// The schemes.
    public var schemes: [String] {
        switch self {
        case .project(let project):
            project.schemes
        case .workspace(let workspace):
            workspace.schemes
        }
    }
}

/// The targets, build configurations, and schemes of an Xcode project.
public struct ProjectListing: Sendable, Hashable {
    /// The name of the project.
    public var name: String

    /// The targets, in project order.
    public var targets: [String]

    /// The build configurations, such as `Debug` and `Release`.
    public var configurations: [String]

    /// The schemes, including schemes xcodebuild generates for targets that have none.
    public var schemes: [String]

    /// Creates a listing.
    public init(name: String, targets: [String], configurations: [String], schemes: [String]) {
        self.name = name
        self.targets = targets
        self.configurations = configurations
        self.schemes = schemes
    }
}

/// The schemes of a workspace.
public struct WorkspaceListing: Sendable, Hashable {
    /// The name of the workspace, or of the Swift package.
    public var name: String

    /// The schemes.
    public var schemes: [String]

    /// Creates a listing.
    public init(name: String, schemes: [String]) {
        self.name = name
        self.schemes = schemes
    }
}

/// The JSON that `-list -json` prints.
struct ListJSON: Decodable {
    struct Project: Decodable {
        var name: String
        var targets: [String]?
        var configurations: [String]?
        var schemes: [String]?
    }

    struct Workspace: Decodable {
        var name: String
        var schemes: [String]?
    }

    var project: Project?
    var workspace: Workspace?
}
