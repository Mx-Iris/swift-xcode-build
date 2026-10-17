import Foundation
import System
import Testing
import XcodeBuild

/// Read-only queries against the real xcodebuild and the fixture project and package.
///
/// Commands that can't take `-derivedDataPath` get the `IDECustomDerivedDataLocation`
/// user default instead, so no test writes to Xcode's own derived data.
@Suite(.enabled(if: RealXcodeBuild.isEnabled), .timeLimit(.minutes(5)))
struct `Real xcodebuild queries` {
    /// A derived data location of its own for each test, for the `IDECustomDerivedDataLocation` user default.
    func derivedDataLocation(_ test: String) -> String {
        RealXcodeBuild.derivedData.appending(test).string
    }

    @Test func `-version gives the version and build of the selected Xcode`() async throws {
        let version = try await RealXcodeBuild.tool().run(.version)
        #expect(version.version.contains("."))
        #expect(!version.buildVersion.isEmpty)
    }

    @Test func `-showsdks includes the macOS SDK`() async throws {
        let sdks = try await RealXcodeBuild.tool().run(.showSDKs)
        let macOS = try #require(sdks.first { $0.platform == "macosx" })
        #expect(FileManager.default.fileExists(atPath: macOS.path.string))
    }

    @Test func `-version -sdk agrees with its single item form`() async throws {
        let tool = RealXcodeBuild.tool()
        let sdks = try await tool.run(SDKVersionCommand(sdk: "macosx"))
        let macOS = try #require(sdks.first)
        #expect(sdks.count == 1)
        #expect(macOS.platform == "macosx")
        #expect(try await tool.run(SDKVersionItemCommand(sdk: "macosx", item: "SDKVersion")) == macOS.version)
        #expect(try await tool.run(SDKVersionItemCommand(sdk: "macosx", item: "Path")) == macOS.path.string)
    }

    @Test func `-list of the fixture package`() async throws {
        let listing = try await RealXcodeBuild.tool(in: Fixtures.minimalPackage).run(ListCommand {
            UserDefaultOverride("IDECustomDerivedDataLocation", derivedDataLocation("ListPackage"))
        })
        #expect(listing == .workspace(WorkspaceListing(name: "MinimalPackage", schemes: ["MinimalPackage"])))
    }

    @Test func `-list of the fixture project`() async throws {
        let listing = try await RealXcodeBuild.tool().run(ListCommand {
            Project(RealXcodeBuild.minimalProjectFile)
            UserDefaultOverride("IDECustomDerivedDataLocation", derivedDataLocation("ListProject"))
        })
        #expect(listing == .project(
            ProjectListing(name: "MinimalProject", targets: ["MinimalTool"], configurations: ["Debug", "Release"], schemes: ["MinimalTool"])
        ))
    }

    @Test func `-showBuildSettings of a target with an overridden setting`() async throws {
        let settings = try await RealXcodeBuild.tool().run(ShowBuildSettingsCommand {
            Project(RealXcodeBuild.minimalProjectFile)
            Target("MinimalTool")
            BuildConfiguration("Debug")
            BuildSetting("SWIFT_ACTIVE_COMPILATION_CONDITIONS", "FROM_SWIFT_XCODE_BUILD")
            UserDefaultOverride("IDECustomDerivedDataLocation", derivedDataLocation("ShowBuildSettings"))
        })
        let target = try #require(settings.first)
        #expect(target.target == "MinimalTool")
        #expect(target["CONFIGURATION"] == "Debug")
        #expect(target["SWIFT_ACTIVE_COMPILATION_CONDITIONS"] == "FROM_SWIFT_XCODE_BUILD")
    }

    @Test func `-showdestinations of the fixture package includes the Mac`() async throws {
        let destinations = try await RealXcodeBuild.tool(in: Fixtures.minimalPackage).run(
            ShowDestinationsCommand(scheme: "MinimalPackage") {
                DerivedDataPath(RealXcodeBuild.derivedData.appending("MinimalPackage-Destinations"))
            }
        )
        #expect(destinations.compatible.contains { $0.platform == "macOS" && $0.name == "My Mac" })
    }

    @Test func `-showTestPlans of the fixture package`() async throws {
        let testPlans = try await RealXcodeBuild.tool(in: Fixtures.minimalPackage).run(
            ShowTestPlansCommand(scheme: "MinimalPackage") {
                DerivedDataPath(RealXcodeBuild.derivedData.appending("MinimalPackage-TestPlans"))
            }
        )
        #expect(testPlans == ["MinimalPackage"])
    }

    @Test func `-find-executable and -find-library give existing files`() async throws {
        let tool = RealXcodeBuild.tool()
        let clang = try await tool.run(FindExecutableCommand(name: "clang") { SDK("macosx") })
        #expect(clang.lastComponent?.string == "clang")
        #expect(FileManager.default.isExecutableFile(atPath: clang.string))
        let library = try await tool.run(FindLibraryCommand(name: "libclang.dylib"))
        #expect(FileManager.default.fileExists(atPath: library.string))
    }

    @Test func `-find-executable of an unknown tool fails with xcodebuild's message`() async throws {
        let error = await #expect(throws: XcodeBuildError.self) {
            try await RealXcodeBuild.tool().run(FindExecutableCommand(name: "no-such-tool-swift-xcode-build"))
        }
        #expect(error?.code == .commandFailed)
        #expect(error?.terminationStatus == .exited(69))
        #expect(error?.outputTail.contains { $0.contains("'no-such-tool-swift-xcode-build' not found") } == true)
    }

    @Test func `the first launch and license checks answer without failing`() async throws {
        let tool = RealXcodeBuild.tool()
        _ = try await tool.run(.checkFirstLaunchStatus)
        _ = try await tool.run(.checkLicense)
    }

    @Test func `-showComponent gives the Metal toolchain's build`() async throws {
        let component = try await RealXcodeBuild.tool().run(ShowComponentCommand(component: .metalToolchain))
        #expect(!component.buildVersion.isEmpty)
        #expect(!component.status.isEmpty)
    }

    @Test func `-help and -usage print the usage`() async throws {
        let tool = RealXcodeBuild.tool()
        #expect(try await tool.run(.help).hasPrefix("Usage: xcodebuild"))
        #expect(try await tool.run(.usage).hasPrefix("Usage: xcodebuild"))
    }

    @Test func `a build with an unknown scheme fails before building, with xcodebuild's message`() async throws {
        let error = await #expect(throws: XcodeBuildError.self) {
            try await RealXcodeBuild.tool().run(BuildCommand(.build) {
                Project(RealXcodeBuild.minimalProjectFile)
                Scheme("NoSuchScheme")
                DerivedDataPath(RealXcodeBuild.derivedData.appending("MinimalProject-UnknownScheme"))
            })
        }
        #expect(error?.code == .commandFailed)
        #expect(error?.outputTail.contains { $0.contains("NoSuchScheme") } == true)
    }
}

/// Builds with the real xcodebuild. Off unless `SWIFT_XCODE_BUILD_TESTS_BUILD=1`.
@Suite(.enabled(if: RealXcodeBuild.buildsAreEnabled), .serialized, .timeLimit(.minutes(10)))
struct `Real xcodebuild builds` {
    @Test func `building the fixture project streams the log and succeeds`() async throws {
        var sawSuccess = false
        var lineCount = 0
        let summary = try await RealXcodeBuild.tool().run(BuildCommand(.build) {
            Project(RealXcodeBuild.minimalProjectFile)
            Scheme("MinimalTool")
            BuildConfiguration("Debug")
            Destination(.macOS())
            DerivedDataPath(RealXcodeBuild.derivedData.appending("MinimalProject-Build"))
            BuildSetting("CODE_SIGNING_ALLOWED", "NO")
        }) { output in
            for try await line in output {
                lineCount += 1
                if line.text.hasPrefix("** BUILD SUCCEEDED **") {
                    sawSuccess = true
                }
            }
        }
        #expect(sawSuccess)
        #expect(lineCount > 10)
        #expect(summary.commandLine.last == "CODE_SIGNING_ALLOWED=NO")
    }

    @Test func `cleaning the fixture project succeeds`() async throws {
        _ = try await RealXcodeBuild.tool().run(BuildCommand(.clean) {
            Project(RealXcodeBuild.minimalProjectFile)
            Scheme("MinimalTool")
            DerivedDataPath(RealXcodeBuild.derivedData.appending("MinimalProject-Clean"))
        })
    }
}
