public import System

/// Where xcodebuild finds the project to work on.
public enum ProjectContainer: Sendable, Hashable {
    /// The project, workspace, or Swift package in the working directory.
    ///
    /// xcodebuild picks the one in ``XcodeBuildTool/workingDirectory``, and
    /// fails when the directory has more than one project and no workspace.
    /// A directory with a `Package.swift` is opened as a workspace.
    case automatic

    /// An Xcode project (`-project`).
    case project(FilePath)

    /// A workspace (`-workspace`).
    case workspace(FilePath)

    func render(into writer: inout ArgumentWriter) {
        switch self {
        case .automatic:
            break
        case .project(let path):
            writer.option("-project", path)
        case .workspace(let path):
            writer.option("-workspace", path)
        }
    }
}

/// The targets to build, when building a project without a scheme.
public enum TargetSelection: Sendable, Hashable {
    /// These targets (`-target`, repeated).
    case targets([String])

    /// Every target in the project (`-alltargets`).
    case allTargets

    func render(into writer: inout ArgumentWriter) {
        switch self {
        case .targets(let names):
            writer.repeatedOption("-target", names)
        case .allTargets:
            writer.append("-alltargets")
        }
    }
}

/// How much xcodebuild prints while it works.
public enum LogVerbosity: Sendable, Hashable {
    /// Only warnings and errors (`-quiet`).
    case quiet

    /// Additional status output (`-verbose`).
    case verbose

    func render(into writer: inout ArgumentWriter) {
        switch self {
        case .quiet:
            writer.append("-quiet")
        case .verbose:
            writer.append("-verbose")
        }
    }
}
