import Foundation
import System
import XcodeBuild

/// Settings for the tests that run the real xcodebuild.
///
/// - `SWIFT_XCODE_BUILD_TESTS_SKIP_REAL=1` skips them.
/// - `SWIFT_XCODE_BUILD_TESTS_DERIVED_DATA` is the directory for their
///   derived data. Without it they use a directory in the temporary directory,
///   never Xcode's own derived data.
/// - `SWIFT_XCODE_BUILD_TESTS_BUILD=1` also runs the tests that build, which
///   take longer.
///
/// The tests run `/usr/bin/xcodebuild`, so `DEVELOPER_DIR` selects the Xcode they test against.
enum RealXcodeBuild {
    static let environment = ProcessInfo.processInfo.environment

    static var isEnabled: Bool {
        environment["SWIFT_XCODE_BUILD_TESTS_SKIP_REAL"] != "1"
            && FileManager.default.isExecutableFile(atPath: "/usr/bin/xcodebuild")
    }

    static var buildsAreEnabled: Bool {
        isEnabled && environment["SWIFT_XCODE_BUILD_TESTS_BUILD"] == "1"
    }

    static let derivedData: FilePath = {
        if let path = environment["SWIFT_XCODE_BUILD_TESTS_DERIVED_DATA"], !path.isEmpty {
            return FilePath(path)
        }
        let directory = FileManager.default.temporaryDirectory.appending(path: "swift-xcode-build-tests-derived-data")
        return FilePath(directory.path(percentEncoded: false))
    }()

    /// A tool that runs the real xcodebuild in a directory.
    static func tool(in workingDirectory: FilePath? = nil) -> XcodeBuildTool {
        XcodeBuildTool(workingDirectory: workingDirectory)
    }

    static let minimalProjectFile = Fixtures.minimalProject.appending("MinimalProject.xcodeproj")
}
