import Foundation
import System
import XcodeBuild

/// Recorded xcodebuild output and the projects the real-xcodebuild tests work on.
enum Fixtures {
    /// `Tests/Fixtures`.
    static let directory = URL(filePath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appending(path: "Fixtures", directoryHint: .isDirectory)

    /// The Xcode versions whose output was recorded, as directory names under `Tests/Fixtures/Outputs`.
    static let recordedXcodeVersions = ["Xcode-27.2", "Xcode-26.6"]

    /// The bytes of a recorded output file.
    static func output(_ name: String, recordedWith xcodeVersion: String) throws -> [UInt8] {
        let url = directory.appending(path: "Outputs/\(xcodeVersion)/\(name)")
        return Array(try Data(contentsOf: url))
    }

    /// A completion as if xcodebuild had printed a recorded file on standard output and exited with status 0.
    static func completion(standardOutput name: String, recordedWith xcodeVersion: String) throws -> XcodeBuildCompletion {
        XcodeBuildCompletion(
            commandLine: ["/usr/bin/xcodebuild"],
            terminationStatus: .exited(0),
            standardOutput: try output(name, recordedWith: xcodeVersion)
        )
    }

    /// The Swift package with one library and one test target.
    static let minimalPackage = FilePath(directory.appending(path: "MinimalPackage").path(percentEncoded: false))

    /// The Xcode project with one command-line tool target.
    static let minimalProject = FilePath(directory.appending(path: "MinimalProject").path(percentEncoded: false))
}

extension XcodeBuildCompletion {
    /// A completion with only an exit status and output.
    static func exited(_ status: Int32, standardOutput: String = "", standardError: String = "") -> XcodeBuildCompletion {
        XcodeBuildCompletion(
            commandLine: ["/usr/bin/xcodebuild"],
            terminationStatus: .exited(status),
            standardOutput: Array(standardOutput.utf8),
            standardError: Array(standardError.utf8)
        )
    }
}
