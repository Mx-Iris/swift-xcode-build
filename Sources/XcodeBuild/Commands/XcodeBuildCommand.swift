/// A command that ``XcodeBuildTool`` can run.
///
/// Each mode of xcodebuild has a command type: ``BuildCommand`` for the build
/// actions, ``ListCommand`` for `-list`, ``ExportArchiveCommand`` for
/// `-exportArchive`, and so on. A command is a plain value. Create it, set its
/// properties or describe it with the result builder DSL, and pass it to
/// ``XcodeBuildTool``.
///
/// Commands come in two kinds, and a command conforms to exactly one of them:
///
/// - ``XcodeBuildQueryCommand``: the result is printed on standard output,
///   which the tool collects and decodes.
/// - ``XcodeBuildActionCommand``: standard output is a log that you can read
///   line by line while xcodebuild writes it.
///
/// You can write your own command by conforming a type to one of the two
/// protocols, although ``BuildCommand/additionalArguments`` and the
/// `additionalArguments` property of the other commands cover most needs.
public protocol XcodeBuildCommand: Sendable {
    /// The result of running the command.
    associatedtype Output: Sendable

    /// The arguments that follow `xcodebuild` on the command line.
    var arguments: [String] { get }

    /// Creates the result of a finished run.
    ///
    /// ``XcodeBuildTool`` calls this after xcodebuild exits, whatever its exit
    /// status, so that commands whose exit status is the answer can interpret
    /// it. Other commands call ``XcodeBuildCompletion/requireSuccess()``
    /// first.
    func output(from completion: XcodeBuildCompletion) throws(XcodeBuildError) -> Output
}

/// A command that prints its result, such as `-list`, `-showsdks`, or `-version`.
///
/// ``XcodeBuildTool`` collects standard output, up to
/// ``XcodeBuildTool/standardOutputLimit``, and hands it to
/// ``XcodeBuildCommand/output(from:)`` in ``XcodeBuildCompletion/standardOutput``.
public protocol XcodeBuildQueryCommand: XcodeBuildCommand {}

/// A command whose standard output is a log, such as a build, an export, or a download.
///
/// ``XcodeBuildTool`` merges standard output and standard error into one log.
/// Read it with ``XcodeBuildTool/run(_:body:)``, or let
/// ``XcodeBuildTool`` discard it when you run the command without a closure. Either way the last
/// lines are kept in ``XcodeBuildCompletion/outputTail`` and in the error
/// when the command fails.
public protocol XcodeBuildActionCommand: XcodeBuildCommand {}

extension XcodeBuildActionCommand where Output == XcodeBuildSummary {
    /// Returns a summary of the run, or throws if xcodebuild failed.
    public func output(from completion: XcodeBuildCompletion) throws(XcodeBuildError) -> XcodeBuildSummary {
        try completion.requireSuccess()
        return XcodeBuildSummary(commandLine: completion.commandLine, duration: completion.duration)
    }
}
