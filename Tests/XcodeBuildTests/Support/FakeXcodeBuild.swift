import Foundation
import System
import XcodeBuild

/// A shell script that stands in for xcodebuild, in a temporary directory of its own.
struct FakeXcodeBuild {
    let directory: URL
    let executablePath: FilePath

    /// Writes the script.
    ///
    /// - Parameter script: The body of a `/bin/sh` script. It receives the
    ///   command's arguments as `$@`.
    init(_ script: String) throws {
        directory = FileManager.default.temporaryDirectory
            .appending(path: "swift-xcode-build-tests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let executable = directory.appending(path: "xcodebuild")
        try ("#!/bin/sh\n" + script + "\n").write(to: executable, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path(percentEncoded: false))
        executablePath = FilePath(executable.path(percentEncoded: false))
    }

    /// A tool that runs the script, with short grace periods so that
    /// cancellation tests finish quickly.
    var tool: XcodeBuildTool {
        var tool = XcodeBuildTool(executablePath: executablePath)
        tool.cancellationGracePeriods = CancellationGracePeriods(interrupt: .milliseconds(500), terminate: .milliseconds(500))
        return tool
    }

    /// A path in the script's directory, for files the script writes.
    func path(_ name: String) -> String {
        directory.appending(path: name).path(percentEncoded: false)
    }

    func remove() {
        try? FileManager.default.removeItem(at: directory)
    }
}

/// A query with any arguments whose result is the completion itself.
struct RecordingQuery: XcodeBuildQueryCommand {
    var arguments: [String]

    func output(from completion: XcodeBuildCompletion) throws(XcodeBuildError) -> XcodeBuildCompletion {
        completion
    }
}

/// An action with any arguments whose result is the completion itself, including the last lines of its log.
struct RecordingAction: XcodeBuildActionCommand {
    var arguments: [String]

    func output(from completion: XcodeBuildCompletion) throws(XcodeBuildError) -> XcodeBuildCompletion {
        completion
    }
}

/// An error a test's closure throws.
struct ClosureFailure: Error, Equatable {
    var message: String
}
