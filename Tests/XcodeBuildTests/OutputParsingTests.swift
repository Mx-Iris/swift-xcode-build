import Foundation
import System
import Testing
import XcodeBuild

/// What an Xcode version printed when its output was recorded, read off the recordings by hand.
struct RecordedXcode: CustomTestStringConvertible, Sendable {
    let directory: String
    let version: String
    let buildVersion: String
    let sdkCanonicalNames: [String]
    let macOSSDKCanonicalName: String
    let compatibleDestinationCount: Int
    let incompatibleDestinationCount: Int
    let clangPath: String
    let metalToolchainBuildVersion: String

    var testDescription: String {
        directory
    }

    static let xcode27 = RecordedXcode(
        directory: "Xcode-27.2",
        version: "27.2",
        buildVersion: "27B5038j",
        sdkCanonicalNames: [
            "driverkit27.2", "iphoneos27.2", "iphonesimulator27.2", "macosx27.2", "macosx27.2", "appletvos27.2",
            "appletvsimulator27.2", "xros27.2", "xrsimulator27.2", "watchos27.2", "watchsimulator27.2",
        ],
        macOSSDKCanonicalName: "macosx27.2",
        compatibleDestinationCount: 56,
        incompatibleDestinationCount: 0,
        clangPath: "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang",
        metalToolchainBuildVersion: "27B5038h"
    )

    static let xcode26 = RecordedXcode(
        directory: "Xcode-26.6",
        version: "26.6",
        buildVersion: "17F113",
        sdkCanonicalNames: [
            "driverkit25.5", "iphoneos26.5", "iphonesimulator26.5", "macosx26.5", "macosx26.5", "appletvos26.5",
            "appletvsimulator26.5", "xros26.5", "xrsimulator26.5", "watchos26.5", "watchsimulator26.5",
        ],
        macOSSDKCanonicalName: "macosx26.5",
        compatibleDestinationCount: 49,
        incompatibleDestinationCount: 4,
        clangPath: "/Applications/Xcode-26.6.0.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang",
        metalToolchainBuildVersion: "17F109"
    )

    static let all = [xcode27, xcode26]
}

@Suite struct `Output parsing` {
    @Test(arguments: RecordedXcode.all)
    func `-version gives the version and build`(_ xcode: RecordedXcode) throws {
        let completion = try Fixtures.completion(standardOutput: "version.txt", recordedWith: xcode.directory)
        let version = try VersionCommand().output(from: completion)
        #expect(version == XcodeVersion(version: xcode.version, buildVersion: xcode.buildVersion))
    }

    @Test(arguments: RecordedXcode.all)
    func `-showsdks lists every SDK with its paths`(_ xcode: RecordedXcode) throws {
        let completion = try Fixtures.completion(standardOutput: "show-sdks.json", recordedWith: xcode.directory)
        let sdks = try ShowSDKsCommand().output(from: completion)
        #expect(sdks.map(\.canonicalName) == xcode.sdkCanonicalNames)
        let iOS = try #require(sdks.first { $0.platform == "iphoneos" })
        #expect(iOS.isBaseSDK)
        #expect(iOS.productName == "iPhone OS")
        #expect(iOS.path.string.hasSuffix("/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS\(iOS.version).sdk"))
        let driverKit = try #require(sdks.first { $0.platform == "driverkit" })
        #expect(driverKit.buildIdentifier == nil)
        #expect(driverKit.productName == nil)
    }

    @Test(arguments: RecordedXcode.all)
    func `-version -sdk -json for one SDK skips the line before the JSON`(_ xcode: RecordedXcode) throws {
        let completion = try Fixtures.completion(standardOutput: "version-sdk-macosx.stdout.txt", recordedWith: xcode.directory)
        let sdks = try SDKVersionCommand(sdk: "macosx").output(from: completion)
        #expect(sdks.map(\.canonicalName) == [xcode.macOSSDKCanonicalName])
        #expect(sdks.first?.iOSSupportVersion != nil)
    }

    @Test(arguments: RecordedXcode.all)
    func `-version -sdk -json for every SDK`(_ xcode: RecordedXcode) throws {
        let completion = try Fixtures.completion(standardOutput: "version-sdk-all.json", recordedWith: xcode.directory)
        let sdks = try SDKVersionCommand().output(from: completion)
        #expect(sdks.map(\.canonicalName) == xcode.sdkCanonicalNames)
    }

    @Test(arguments: RecordedXcode.all)
    func `-list of a Swift package is a workspace`(_ xcode: RecordedXcode) throws {
        let completion = try Fixtures.completion(standardOutput: "list-package.json", recordedWith: xcode.directory)
        let listing = try ListCommand().output(from: completion)
        #expect(listing == .workspace(WorkspaceListing(name: "MinimalPackage", schemes: ["MinimalPackage"])))
    }

    @Test(arguments: RecordedXcode.all)
    func `-list of a project gives targets, configurations, and schemes`(_ xcode: RecordedXcode) throws {
        let completion = try Fixtures.completion(standardOutput: "list-project.json", recordedWith: xcode.directory)
        let listing = try ListCommand().output(from: completion)
        #expect(listing == .project(
            ProjectListing(
                name: "MinimalProject",
                targets: ["MinimalTool"],
                configurations: ["Debug", "Release"],
                schemes: ["MinimalTool"]
            )
        ))
        #expect(listing.schemes == ["MinimalTool"])
        #expect(listing.name == "MinimalProject")
    }

    @Test(arguments: RecordedXcode.all)
    func `-showBuildSettings gives the settings of each target`(_ xcode: RecordedXcode) throws {
        let completion = try Fixtures.completion(standardOutput: "show-build-settings-project.json", recordedWith: xcode.directory)
        let settings = try ShowBuildSettingsCommand().output(from: completion)
        #expect(settings.count == 1)
        let target = try #require(settings.first)
        #expect(target.action == "build")
        #expect(target.target == "MinimalTool")
        #expect(target["PRODUCT_NAME"] == "MinimalTool")
        #expect(target["CONFIGURATION"] == "Release")
        #expect(target["SDK_NAME"] == xcode.macOSSDKCanonicalName)
    }

    @Test(arguments: RecordedXcode.all)
    func `-showTestPlans gives the names of the test plans`(_ xcode: RecordedXcode) throws {
        let completion = try Fixtures.completion(standardOutput: "show-test-plans.json", recordedWith: xcode.directory)
        #expect(try ShowTestPlansCommand(scheme: "MinimalPackage").output(from: completion) == ["MinimalPackage"])
    }

    @Test(arguments: RecordedXcode.all)
    func `-showComponent gives the build and status`(_ xcode: RecordedXcode) throws {
        let completion = try Fixtures.completion(standardOutput: "show-component-metaltoolchain.json", recordedWith: xcode.directory)
        let component = try ShowComponentCommand(component: .metalToolchain).output(from: completion)
        #expect(component == ComponentDescription(buildVersion: xcode.metalToolchainBuildVersion, status: "uninstalled"))
    }

    @Test(arguments: RecordedXcode.all)
    func `-find-executable gives the path without the line break`(_ xcode: RecordedXcode) throws {
        let completion = try Fixtures.completion(standardOutput: "find-executable.txt", recordedWith: xcode.directory)
        #expect(try FindExecutableCommand(name: "clang").output(from: completion) == FilePath(xcode.clangPath))
    }

    @Test(arguments: RecordedXcode.all)
    func `-help is read from standard error`(_ xcode: RecordedXcode) throws {
        let help = try Fixtures.output("help.stderr.txt", recordedWith: xcode.directory)
        let completion = XcodeBuildCompletion(commandLine: ["xcodebuild", "-help"], terminationStatus: .exited(0), standardError: help)
        let text = try HelpCommand().output(from: completion)
        #expect(text.hasPrefix("Usage: xcodebuild [-project <projectname>]"))
        #expect(text.contains("Available keys for -exportOptionsPlist:"))
    }

    @Test(arguments: RecordedXcode.all)
    func `-usage is read from standard error`(_ xcode: RecordedXcode) throws {
        let usage = try Fixtures.output("usage.stderr.txt", recordedWith: xcode.directory)
        let completion = XcodeBuildCompletion(commandLine: ["xcodebuild", "-usage"], terminationStatus: .exited(0), standardError: usage)
        #expect(try UsageCommand().output(from: completion).hasPrefix("Usage: xcodebuild"))
    }

    @Test func `-showBuildSettingsForIndex gives the JSON as text`() throws {
        let completion = try Fixtures.completion(standardOutput: "show-build-settings-for-index-project.json", recordedWith: "Xcode-27.2")
        let json = try ShowBuildSettingsForIndexCommand().output(from: completion)
        #expect(json.hasPrefix("{"))
        #expect(json.hasSuffix("}"))
        #expect(json.contains("\"MinimalTool\""))
    }
}

@Suite struct `Destination parsing` {
    @Test(arguments: RecordedXcode.all)
    func `both sections are read in Xcode 26 and 27`(_ xcode: RecordedXcode) throws {
        let completion = try Fixtures.completion(standardOutput: "show-destinations.txt", recordedWith: xcode.directory)
        let destinations = try ShowDestinationsCommand(scheme: "MinimalPackage").output(from: completion)
        #expect(destinations.compatible.count == xcode.compatibleDestinationCount)
        #expect(destinations.incompatible.count == xcode.incompatibleDestinationCount)
    }

    @Test(arguments: RecordedXcode.all)
    func `a device keeps its properties in order`(_ xcode: RecordedXcode) throws {
        let completion = try Fixtures.completion(standardOutput: "show-destinations.txt", recordedWith: xcode.directory)
        let destinations = try ShowDestinationsCommand(scheme: "MinimalPackage").output(from: completion)
        let myMac = try #require(destinations.compatible.first)
        #expect(myMac.properties == [
            .init(key: "platform", value: "macOS"),
            .init(key: "arch", value: "arm64"),
            .init(key: "id", value: "00006032-000C0000000000CC"),
            .init(key: "name", value: "My Mac"),
        ])
        #expect(!myMac.isGeneric)
        #expect(myMac.specifier.rawValue == "platform=macOS,id=00006032-000C0000000000CC,arch=arm64")
    }

    @Test(arguments: RecordedXcode.all)
    func `a value with a comma inside brackets stays whole`(_ xcode: RecordedXcode) throws {
        let completion = try Fixtures.completion(standardOutput: "show-destinations.txt", recordedWith: xcode.directory)
        let destinations = try ShowDestinationsCommand(scheme: "MinimalPackage").output(from: completion)
        let designedForIPad = try #require(destinations.compatible.first { $0.variant?.hasPrefix("Designed for") == true })
        #expect(designedForIPad.variant == "Designed for [iPad,iPhone]")
        #expect(designedForIPad.name == "My Mac")
    }

    @Test(arguments: RecordedXcode.all)
    func `placeholder devices become generic specifiers`(_ xcode: RecordedXcode) throws {
        let completion = try Fixtures.completion(standardOutput: "show-destinations.txt", recordedWith: xcode.directory)
        let destinations = try ShowDestinationsCommand(scheme: "MinimalPackage").output(from: completion)
        let anyIOSDevice = try #require(destinations.compatible.first { $0.name == "Any iOS Device" })
        #expect(anyIOSDevice.isGeneric)
        #expect(anyIOSDevice.specifier.rawValue == "generic/platform=iOS")
        let anyCatalystMac = try #require(destinations.compatible.first { $0.name == "Any Mac" && $0.variant == "Mac Catalyst" })
        #expect(anyCatalystMac.specifier.rawValue == "generic/platform=macOS,variant=Mac Catalyst")
    }

    @Test func `a simulator gives its runtime version`() throws {
        let completion = try Fixtures.completion(standardOutput: "show-destinations.txt", recordedWith: "Xcode-27.2")
        let destinations = try ShowDestinationsCommand(scheme: "MinimalPackage").output(from: completion)
        let simulator = try #require(destinations.compatible.first { $0.identifier == "7F0E47DF-DEAB-4149-BD0A-3F52E9F02857" })
        #expect(simulator.platform == "iOS Simulator")
        #expect(simulator.operatingSystemVersion == "27.0")
        #expect(simulator.name == "iPhone 17 Pro")
        #expect(simulator.specifier.rawValue == "platform=iOS Simulator,id=7F0E47DF-DEAB-4149-BD0A-3F52E9F02857,arch=arm64")
    }

    @Test func `an incompatible destination gives the reason, which contains periods and a greater-than sign`() throws {
        let completion = try Fixtures.completion(standardOutput: "show-destinations.txt", recordedWith: "Xcode-26.6")
        let destinations = try ShowDestinationsCommand(scheme: "MinimalPackage").output(from: completion)
        let appleTV = try #require(destinations.incompatible.first)
        #expect(appleTV.name == "Tester's Apple TV")
        #expect(appleTV.error == "tvOS 26.5 is not installed. Please download and install the platform from Xcode > Settings > Components.")
    }

    @Test func `a destination outside a known section is unexpected output`() {
        let completion = XcodeBuildCompletion.exited(0, standardOutput: "\t\t{ platform:macOS, name:My Mac }\n")
        #expect {
            try ShowDestinationsCommand(scheme: "App").output(from: completion)
        } throws: { error in
            (error as? XcodeBuildError)?.code == .unexpectedOutput
        }
    }

    @Test func `no destinations at all is an empty list`() throws {
        let destinations = try ShowDestinationsCommand(scheme: "App").output(from: .exited(0, standardOutput: "\n"))
        #expect(destinations == DestinationList(compatible: [], incompatible: []))
    }
}

@Suite struct `Exit status interpretation` {
    @Test func `first launch is needed when xcodebuild exits with 69`() throws {
        #expect(try CheckFirstLaunchStatusCommand().output(from: .exited(69)) == true)
        #expect(try CheckFirstLaunchStatusCommand().output(from: .exited(0)) == false)
    }

    @Test func `the license is accepted when xcodebuild exits with 0`() throws {
        #expect(try CheckLicenseCommand().output(from: .exited(0)) == true)
        #expect(try CheckLicenseCommand().output(from: .exited(69)) == false)
    }

    @Test(arguments: [Int32(1), 64, 65, 70])
    func `other exit statuses of the checks are failures`(_ status: Int32) {
        #expect {
            try CheckFirstLaunchStatusCommand().output(from: .exited(status))
        } throws: { error in
            (error as? XcodeBuildError)?.terminationStatus == .exited(status)
        }
        #expect {
            try CheckLicenseCommand().output(from: .exited(status))
        } throws: { error in
            (error as? XcodeBuildError)?.code == .commandFailed
        }
    }

    @Test func `a query that fails throws with its exit status and last lines`() {
        let completion = XcodeBuildCompletion(
            commandLine: ["/usr/bin/xcodebuild", "-list", "-json"],
            terminationStatus: .exited(66),
            outputTail: ["xcodebuild: error: The directory does not contain an Xcode project."]
        )
        #expect {
            try ListCommand().output(from: completion)
        } throws: { error in
            guard let error = error as? XcodeBuildError else {
                return false
            }
            return error.code == .commandFailed
                && error.terminationStatus == .exited(66)
                && error.outputTail == ["xcodebuild: error: The directory does not contain an Xcode project."]
                && error.commandLine == ["/usr/bin/xcodebuild", "-list", "-json"]
        }
    }

    @Test func `an action killed by a signal is a failure`() {
        let completion = XcodeBuildCompletion(commandLine: ["xcodebuild"], terminationStatus: .signaled(9))
        #expect {
            try BuildCommand().output(from: completion)
        } throws: { error in
            (error as? XcodeBuildError)?.terminationStatus == .signaled(9)
        }
    }

    @Test func `text where JSON was expected is unexpected output`() {
        #expect {
            try ListCommand().output(from: .exited(0, standardOutput: "Information about project \"App\":"))
        } throws: { error in
            (error as? XcodeBuildError)?.code == .unexpectedOutput
        }
    }

    @Test func `JSON of the wrong shape is unexpected output with the decoding error`() {
        #expect {
            try ShowSDKsCommand().output(from: .exited(0, standardOutput: "{\"unexpected\": true}"))
        } throws: { error in
            guard let error = error as? XcodeBuildError else {
                return false
            }
            return error.code == .unexpectedOutput && error.underlyingError is DecodingError
        }
    }

    @Test func `a version without a build line is unexpected output`() {
        #expect {
            try VersionCommand().output(from: .exited(0, standardOutput: "Xcode 27.2\n"))
        } throws: { error in
            (error as? XcodeBuildError)?.code == .unexpectedOutput
        }
    }
}
