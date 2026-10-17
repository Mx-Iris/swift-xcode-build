import System
import Testing
import XcodeBuild

/// A command's arguments next to the arguments it should render, written out by hand.
struct RenderingCase: CustomTestStringConvertible, Sendable {
    let name: String
    let arguments: [String]
    let expected: [String]

    init(_ name: String, _ command: some XcodeBuildCommand, _ expected: [String]) {
        self.name = name
        self.arguments = command.arguments
        self.expected = expected
    }

    var testDescription: String {
        name
    }
}

@Suite struct `Argument rendering` {
    static let fullBuildCommand: BuildCommand = {
        var command = BuildCommand(actions: [.clean, .test], container: .workspace("App.xcworkspace"), scheme: "App")
        command.configuration = "Debug"
        command.xcconfig = "Config/CI.xcconfig"
        command.architectures = ["arm64", "x86_64"]
        command.sdk = "iphonesimulator"
        command.toolchain = "com.apple.dt.toolchain.XcodeDefault"
        command.destinations = [
            .simulator(.iOS, name: "iPhone 17 Pro"),
            .simulator(.iOS, name: "iPad Air 11-inch (M3)", operatingSystemVersion: "27.0"),
        ]
        command.destinationTimeout = .seconds(60)
        command.derivedDataPath = "build/DerivedData"
        command.archivePath = "build/App.xcarchive"
        command.resultBundlePath = "build/App.xcresult"
        command.resultBundleVersion = 3
        command.resultStreamPath = "build/stream.json"
        command.packageResolution.clonedSourcePackagesDirectory = "build/SourcePackages"
        command.packageResolution.packageCachePath = "build/PackageCache"
        command.packageResolution.disableAutomaticPackageResolution = true
        command.packageResolution.onlyUsePackageVersionsFromResolvedFile = true
        command.packageResolution.skipPackageUpdates = true
        command.packageResolution.disablePackageRepositoryCache = true
        command.packageResolution.skipPackagePluginValidation = true
        command.packageResolution.skipMacroValidation = true
        command.packageResolution.skipPackageSignatureValidation = true
        command.packageResolution.packageAuthorizationProvider = .netrc
        command.packageResolution.defaultPackageRegistryURL = "https://packages.example.com"
        command.packageResolution.registryTransformation = .useRegistryIdentity
        command.packageResolution.packageFingerprintPolicy = .strict
        command.packageResolution.packageSigningEntityPolicy = .warn
        command.packageResolution.sourceControlProvider = .system
        command.provisioning.allowProvisioningUpdates = true
        command.provisioning.allowProvisioningDeviceRegistration = true
        command.provisioning.authenticationKey = AppStoreConnectKey(path: "AuthKey.p8", identifier: "KEY1234567", issuerIdentifier: "issuer")
        command.testing.xctestrun = "App.xctestrun"
        command.testing.testProductsPath = "App.xctestproducts"
        command.testing.testPlan = "UnitTests"
        command.testing.onlyTesting = ["AppTests/LoginTests", "@tests.txt"]
        command.testing.skipTesting = ["AppTests/SlowTests"]
        command.testing.onlyTestConfigurations = ["English"]
        command.testing.skipTestConfigurations = ["German"]
        command.testing.testLanguage = "en"
        command.testing.testRegion = "US"
        command.testing.parallelTestingEnabled = true
        command.testing.parallelTestingWorkerCount = 4
        command.testing.maximumParallelTestingWorkers = 6
        command.testing.maximumConcurrentTestDeviceDestinations = 2
        command.testing.maximumConcurrentTestSimulatorDestinations = 3
        command.testing.disableConcurrentDestinationTesting = true
        command.testing.parallelizeTestsAmongDestinations = true
        command.testing.testTimeoutsEnabled = true
        command.testing.defaultTestExecutionTimeAllowance = .seconds(120)
        command.testing.maximumTestExecutionTimeAllowance = .seconds(600)
        command.testing.testIterations = 5
        command.testing.testRepetition = .retryOnFailure
        command.testing.testRepetitionRelaunchEnabled = false
        command.testing.collectTestDiagnostics = .onFailure
        command.testing.performanceTestsDiagnosticsEnabled = true
        command.testing.codeCoverageEnabled = true
        command.testing.testEnumeration = TestEnumeration(style: .flat, format: .json, outputPath: "tests.json")
        command.sanitizers = SanitizerOptions(
            addressSanitizerEnabled: true,
            threadSanitizerEnabled: false,
            undefinedBehaviorSanitizerEnabled: true
        )
        command.codeSizeProfile = CodeSizeProfileOptions(enabled: true, outputDirectory: "build/CodeSize")
        command.parallelizeTargets = true
        command.jobs = 8
        command.verbosity = .verbose
        command.hideShellScriptEnvironment = true
        command.showBuildTimingSummary = true
        command.skipUnavailableActions = true
        command.buildSettings = ["CODE_SIGNING_ALLOWED": "NO", "OTHER_SWIFT_FLAGS": "$(inherited) -DCI"]
        command.userDefaults = ["IDEPackageSupportUseBuiltinSCM": "YES"]
        command.additionalArguments = ["-dry-run"]
        return command
    }()

    static let buildCases: [RenderingCase] = [
        RenderingCase("BuildCommand with no options", BuildCommand(), []),
        RenderingCase(
            "BuildCommand with every option",
            fullBuildCommand,
            [
                "-workspace", "App.xcworkspace",
                "-scheme", "App",
                "-configuration", "Debug",
                "-xcconfig", "Config/CI.xcconfig",
                "-arch", "arm64", "-arch", "x86_64",
                "-sdk", "iphonesimulator",
                "-toolchain", "com.apple.dt.toolchain.XcodeDefault",
                "-destination", "platform=iOS Simulator,name=iPhone 17 Pro",
                "-destination", "platform=iOS Simulator,name=iPad Air 11-inch (M3),OS=27.0",
                "-destination-timeout", "60",
                "-derivedDataPath", "build/DerivedData",
                "-archivePath", "build/App.xcarchive",
                "-resultBundlePath", "build/App.xcresult",
                "-resultBundleVersion", "3",
                "-resultStreamPath", "build/stream.json",
                "-clonedSourcePackagesDirPath", "build/SourcePackages",
                "-packageCachePath", "build/PackageCache",
                "-disableAutomaticPackageResolution",
                "-onlyUsePackageVersionsFromResolvedFile",
                "-skipPackageUpdates",
                "-disablePackageRepositoryCache",
                "-skipPackagePluginValidation",
                "-skipMacroValidation",
                "-skipPackageSignatureValidation",
                "-packageAuthorizationProvider", "netrc",
                "-defaultPackageRegistryURL", "https://packages.example.com",
                "-packageDependencySCMToRegistryTransformation", "useRegistryIdentity",
                "-packageFingerprintPolicy", "strict",
                "-packageSigningEntityPolicy", "warn",
                "-scmProvider", "system",
                "-allowProvisioningUpdates",
                "-allowProvisioningDeviceRegistration",
                "-authenticationKeyPath", "AuthKey.p8",
                "-authenticationKeyID", "KEY1234567",
                "-authenticationKeyIssuerID", "issuer",
                "-xctestrun", "App.xctestrun",
                "-testProductsPath", "App.xctestproducts",
                "-testPlan", "UnitTests",
                "-only-testing", "AppTests/LoginTests",
                "-only-testing", "@tests.txt",
                "-skip-testing", "AppTests/SlowTests",
                "-only-test-configuration", "English",
                "-skip-test-configuration", "German",
                "-testLanguage", "en",
                "-testRegion", "US",
                "-parallel-testing-enabled", "YES",
                "-parallel-testing-worker-count", "4",
                "-maximum-parallel-testing-workers", "6",
                "-maximum-concurrent-test-device-destinations", "2",
                "-maximum-concurrent-test-simulator-destinations", "3",
                "-disable-concurrent-destination-testing",
                "-parallelize-tests-among-destinations",
                "-test-timeouts-enabled", "YES",
                "-default-test-execution-time-allowance", "120",
                "-maximum-test-execution-time-allowance", "600",
                "-test-iterations", "5",
                "-retry-tests-on-failure",
                "-test-repetition-relaunch-enabled", "NO",
                "-collect-test-diagnostics", "on-failure",
                "-enablePerformanceTestsDiagnostics", "YES",
                "-enableCodeCoverage", "YES",
                "-enumerate-tests",
                "-test-enumeration-style", "flat",
                "-test-enumeration-format", "json",
                "-test-enumeration-output-path", "tests.json",
                "-enableAddressSanitizer", "YES",
                "-enableThreadSanitizer", "NO",
                "-enableUndefinedBehaviorSanitizer", "YES",
                "-enableCodesizeProfile", "YES",
                "-codesizeProfileOutputDir", "build/CodeSize",
                "-parallelizeTargets",
                "-jobs", "8",
                "-verbose",
                "-hideShellScriptEnvironment",
                "-showBuildTimingSummary",
                "-skipUnavailableActions",
                "clean", "test",
                "CODE_SIGNING_ALLOWED=NO",
                "OTHER_SWIFT_FLAGS=$(inherited) -DCI",
                "-IDEPackageSupportUseBuiltinSCM=YES",
                "-dry-run",
            ]
        ),
        RenderingCase(
            "BuildCommand with targets of a project",
            {
                var command = BuildCommand(actions: [.build], container: .project("App.xcodeproj"))
                command.targets = .targets(["App", "Framework"])
                command.verbosity = .quiet
                return command
            }(),
            ["-project", "App.xcodeproj", "-target", "App", "-target", "Framework", "-quiet", "build"]
        ),
        RenderingCase(
            "BuildCommand with all targets",
            {
                var command = BuildCommand(actions: [.install])
                command.targets = .allTargets
                return command
            }(),
            ["-alltargets", "install"]
        ),
        RenderingCase(
            "BuildCommand that repeats tests until they fail",
            {
                var command = BuildCommand(actions: [.testWithoutBuilding])
                command.testing.testRepetition = .untilFailure
                command.testing.testEnumeration = TestEnumeration()
                return command
            }(),
            ["-run-tests-until-failure", "-enumerate-tests", "test-without-building"]
        ),
        RenderingCase(
            "BuildCommand with every action",
            BuildCommand(actions: [
                .build, .buildForTesting, .analyze, .archive, .test, .testWithoutBuilding, .buildDocumentation,
                .installSource, .install, .clean,
            ]),
            [
                "build", "build-for-testing", "analyze", "archive", "test", "test-without-building", "docbuild",
                "installsrc", "install", "clean",
            ]
        ),
    ]

    static let queryCases: [RenderingCase] = [
        RenderingCase("ListCommand in the working directory", ListCommand(), ["-list", "-json"]),
        RenderingCase("ListCommand of a project", ListCommand(.project("App.xcodeproj")), ["-list", "-json", "-project", "App.xcodeproj"]),
        RenderingCase("ShowSDKsCommand", ShowSDKsCommand(), ["-showsdks", "-json"]),
        RenderingCase(
            "ShowBuildSettingsCommand with every option",
            {
                var command = ShowBuildSettingsCommand(container: .workspace("App.xcworkspace"), scheme: "App")
                command.targets = .targets(["App"])
                command.action = .test
                command.configuration = "Release"
                command.xcconfig = "CI.xcconfig"
                command.architectures = ["arm64"]
                command.sdk = "iphoneos"
                command.toolchain = "swift"
                command.destinations = [.generic(.iOS)]
                command.destinationTimeout = .seconds(5)
                command.derivedDataPath = "DerivedData"
                command.packageResolution.skipPackageUpdates = true
                command.buildSettings = ["ENABLE_TESTABILITY": "YES"]
                command.userDefaults = ["Name": "Value"]
                command.additionalArguments = ["-extra"]
                return command
            }(),
            [
                "-showBuildSettings", "-json",
                "-workspace", "App.xcworkspace",
                "-scheme", "App",
                "-target", "App",
                "-configuration", "Release",
                "-xcconfig", "CI.xcconfig",
                "-arch", "arm64",
                "-sdk", "iphoneos",
                "-toolchain", "swift",
                "-destination", "generic/platform=iOS",
                "-destination-timeout", "5",
                "-derivedDataPath", "DerivedData",
                "-skipPackageUpdates",
                "test",
                "ENABLE_TESTABILITY=YES",
                "-Name=Value",
                "-extra",
            ]
        ),
        RenderingCase(
            "ShowBuildSettingsForIndexCommand",
            {
                var command = ShowBuildSettingsForIndexCommand(container: .project("App.xcodeproj"), scheme: "App")
                command.configuration = "Debug"
                command.destinations = [.macOS()]
                return command
            }(),
            [
                "-showBuildSettingsForIndex", "-json",
                "-project", "App.xcodeproj",
                "-scheme", "App",
                "-configuration", "Debug",
                "-destination", "platform=macOS",
            ]
        ),
        RenderingCase(
            "ShowDestinationsCommand",
            {
                var command = ShowDestinationsCommand(container: .workspace("App.xcworkspace"), scheme: "App")
                command.derivedDataPath = "DerivedData"
                command.packageResolution.disableAutomaticPackageResolution = true
                return command
            }(),
            [
                "-showdestinations",
                "-workspace", "App.xcworkspace",
                "-scheme", "App",
                "-derivedDataPath", "DerivedData",
                "-disableAutomaticPackageResolution",
            ]
        ),
        RenderingCase(
            "ShowTestPlansCommand",
            ShowTestPlansCommand(container: .project("App.xcodeproj"), scheme: "App"),
            ["-showTestPlans", "-json", "-project", "App.xcodeproj", "-scheme", "App"]
        ),
        RenderingCase("VersionCommand", VersionCommand(), ["-version"]),
        RenderingCase("SDKVersionCommand for every SDK", SDKVersionCommand(), ["-version", "-sdk", "-json"]),
        RenderingCase("SDKVersionCommand for one SDK", SDKVersionCommand(sdk: "macosx"), ["-version", "-sdk", "macosx", "-json"]),
        RenderingCase(
            "SDKVersionItemCommand",
            SDKVersionItemCommand(sdk: "iphoneos", item: "Path"),
            ["-version", "-sdk", "iphoneos", "Path"]
        ),
        RenderingCase(
            "FindExecutableCommand",
            {
                var command = FindExecutableCommand(name: "clang")
                command.sdk = "macosx"
                command.toolchain = "com.apple.dt.toolchain.XcodeDefault"
                return command
            }(),
            ["-find-executable", "clang", "-sdk", "macosx", "-toolchain", "com.apple.dt.toolchain.XcodeDefault"]
        ),
        RenderingCase("FindLibraryCommand", FindLibraryCommand(name: "libclang.dylib"), ["-find-library", "libclang.dylib"]),
        RenderingCase(
            "ShowComponentCommand",
            {
                var command = ShowComponentCommand(component: .metalToolchain)
                command.buildVersion = "27A266a"
                return command
            }(),
            ["-showComponent", "metaltoolchain", "-json", "-buildVersion", "27A266a"]
        ),
        RenderingCase("CheckFirstLaunchStatusCommand", CheckFirstLaunchStatusCommand(), ["-checkFirstLaunchStatus"]),
        RenderingCase("CheckLicenseCommand", CheckLicenseCommand(), ["-license", "check"]),
        RenderingCase("UsageCommand", UsageCommand(), ["-usage"]),
        RenderingCase("HelpCommand", HelpCommand(), ["-help"]),
    ]

    static let actionCases: [RenderingCase] = [
        RenderingCase(
            "ExportArchiveCommand with a property list",
            {
                var command = ExportArchiveCommand(
                    archivePath: "App.xcarchive",
                    exportOptions: .propertyList("ExportOptions.plist"),
                    exportPath: "Export"
                )
                command.provisioning.allowProvisioningUpdates = true
                command.verbosity = .quiet
                return command
            }(),
            [
                "-exportArchive",
                "-archivePath", "App.xcarchive",
                "-exportPath", "Export",
                "-exportOptionsPlist", "ExportOptions.plist",
                "-allowProvisioningUpdates",
                "-quiet",
            ]
        ),
        RenderingCase(
            "ExportArchiveCommand with inline options",
            ExportArchiveCommand(archivePath: "App.xcarchive", exportOptions: .options(ExportOptions(method: .appStoreConnect))),
            ["-exportArchive", "-archivePath", "App.xcarchive", "-exportOptionsPlist", "<temporary ExportOptions.plist>"]
        ),
        RenderingCase(
            "ExportNotarizedAppCommand",
            ExportNotarizedAppCommand(archivePath: "App.xcarchive", exportPath: "Export"),
            ["-exportNotarizedApp", "-archivePath", "App.xcarchive", "-exportPath", "Export"]
        ),
        RenderingCase(
            "ExportLocalizationsCommand",
            {
                var command = ExportLocalizationsCommand(localizationPath: "Localizations", container: .project("App.xcodeproj"))
                command.defaultLanguage = "en"
                command.exportLanguages = ["zh-Hans", "es-MX"]
                command.includeScreenshots = true
                return command
            }(),
            [
                "-exportLocalizations",
                "-localizationPath", "Localizations",
                "-project", "App.xcodeproj",
                "-defaultLanguage", "en",
                "-exportLanguage", "zh-Hans",
                "-exportLanguage", "es-MX",
                "-includeScreenshots",
            ]
        ),
        RenderingCase(
            "ImportLocalizationsCommand",
            {
                var command = ImportLocalizationsCommand(localizationPath: "fr.xliff", container: .project("App.xcodeproj"))
                command.mergeImport = true
                return command
            }(),
            ["-importLocalizations", "-localizationPath", "fr.xliff", "-project", "App.xcodeproj", "-mergeImport"]
        ),
        RenderingCase(
            "ResolvePackageDependenciesCommand",
            {
                var command = ResolvePackageDependenciesCommand(container: .workspace("App.xcworkspace"), scheme: "App")
                command.derivedDataPath = "DerivedData"
                command.packageResolution.clonedSourcePackagesDirectory = "SourcePackages"
                command.packageResolution.onlyUsePackageVersionsFromResolvedFile = true
                return command
            }(),
            [
                "-resolvePackageDependencies",
                "-workspace", "App.xcworkspace",
                "-scheme", "App",
                "-derivedDataPath", "DerivedData",
                "-clonedSourcePackagesDirPath", "SourcePackages",
                "-onlyUsePackageVersionsFromResolvedFile",
            ]
        ),
        RenderingCase(
            "CreateXCFrameworkCommand",
            {
                var command = CreateXCFrameworkCommand(
                    output: "MyKit.xcframework",
                    contents: [
                        .framework("iOS/MyKit.framework", debugSymbols: ["iOS/MyKit.framework.dSYM"]),
                        .framework(named: "MyKit.framework", inArchive: "MyKit-macOS.xcarchive"),
                        .library("libMyKit.a", headers: "include", debugSymbols: ["a.dSYM", "b.bcsymbolmap"]),
                        .library(named: "libMyKit.a", inArchive: "MyKit-tvOS.xcarchive"),
                    ]
                )
                command.allowInternalDistribution = true
                return command
            }(),
            [
                "-create-xcframework",
                "-framework", "iOS/MyKit.framework", "-debug-symbols", "iOS/MyKit.framework.dSYM",
                "-archive", "MyKit-macOS.xcarchive", "-framework", "MyKit.framework",
                "-library", "libMyKit.a", "-headers", "include", "-debug-symbols", "a.dSYM", "-debug-symbols", "b.bcsymbolmap",
                "-archive", "MyKit-tvOS.xcarchive", "-library", "libMyKit.a",
                "-allow-internal-distribution",
                "-output", "MyKit.xcframework",
            ]
        ),
        RenderingCase(
            "ConvertProjectCommand",
            ConvertProjectCommand(format: .xcode("16.0"), container: .project("App.xcodeproj")),
            ["-convert-project", "Xcode 16.0", "-project", "App.xcodeproj"]
        ),
        RenderingCase(
            "DownloadPlatformCommand",
            {
                var command = DownloadPlatformCommand(platform: .iOS)
                command.exportPath = "Runtimes"
                command.buildVersion = "27.0"
                command.architectureVariant = .arm64
                return command
            }(),
            ["-downloadPlatform", "iOS", "-exportPath", "Runtimes", "-buildVersion", "27.0", "-architectureVariant", "arm64"]
        ),
        RenderingCase(
            "DownloadAllPlatformsCommand",
            {
                var command = DownloadAllPlatformsCommand()
                command.architectureVariant = .universal
                return command
            }(),
            ["-downloadAllPlatforms", "-architectureVariant", "universal"]
        ),
        RenderingCase("ImportPlatformCommand", ImportPlatformCommand(path: "iOS_27.dmg"), ["-importPlatform", "iOS_27.dmg"]),
        RenderingCase(
            "DownloadComponentCommand",
            {
                var command = DownloadComponentCommand(component: .metalToolchain)
                command.exportPath = "Components"
                return command
            }(),
            ["-downloadComponent", "metaltoolchain", "-exportPath", "Components"]
        ),
        RenderingCase(
            "ImportComponentCommand",
            ImportComponentCommand(component: .metalToolchain, importPath: "Components/MetalToolchain.exportedBundle"),
            ["-importComponent", "metaltoolchain", "-importPath", "Components/MetalToolchain.exportedBundle"]
        ),
        RenderingCase(
            "DeleteComponentCommand",
            {
                var command = DeleteComponentCommand(component: .deviceSupport)
                command.buildVersion = "27B5038h"
                return command
            }(),
            ["-deleteComponent", "devicesupport", "-buildVersion", "27B5038h"]
        ),
        RenderingCase(
            "PrepareDeviceSupportCommand",
            {
                var command = PrepareDeviceSupportCommand(platform: .iOS, operatingSystemVersion: "26.2")
                command.modelCode = "iPhone16,1"
                command.architecture = "arm64e"
                return command
            }(),
            ["-prepareDeviceSupport", "-platform", "iOS", "-osVersion", "26.2", "-modelCode", "iPhone16,1", "-architecture", "arm64e"]
        ),
        RenderingCase(
            "RunFirstLaunchCommand",
            RunFirstLaunchCommand(checkForNewerComponents: true),
            ["-runFirstLaunch", "-checkForNewerComponents"]
        ),
        RenderingCase("AcceptLicenseCommand", AcceptLicenseCommand(), ["-license", "accept"]),
    ]

    @Test(arguments: buildCases)
    func `build command arguments`(_ rendering: RenderingCase) {
        #expect(rendering.arguments == rendering.expected)
    }

    @Test(arguments: queryCases)
    func `query command arguments`(_ rendering: RenderingCase) {
        #expect(rendering.arguments == rendering.expected)
    }

    @Test(arguments: actionCases)
    func `action command arguments`(_ rendering: RenderingCase) {
        #expect(rendering.arguments == rendering.expected)
    }

    @Test func `user defaults and additional arguments come last on every kind of command`() {
        var command = ShowSDKsCommand()
        command.userDefaults = ["First": "1", "Second": "2"]
        command.additionalArguments = ["-future-option", "value"]
        #expect(command.arguments == ["-showsdks", "-json", "-First=1", "-Second=2", "-future-option", "value"])
    }

    @Test func `static shortcuts create the default commands`() {
        func arguments(of command: some XcodeBuildQueryCommand) -> [String] {
            command.arguments
        }
        #expect(arguments(of: .showSDKs) == ["-showsdks", "-json"])
        #expect(arguments(of: .list) == ["-list", "-json"])
        #expect(arguments(of: .version) == ["-version"])
        #expect(arguments(of: .usage) == ["-usage"])
        #expect(arguments(of: .help) == ["-help"])
        #expect(arguments(of: .checkFirstLaunchStatus) == ["-checkFirstLaunchStatus"])
        #expect(arguments(of: .checkLicense) == ["-license", "check"])
    }
}

@Suite struct `Destination specifiers` {
    static let cases: [(DestinationSpecifier, String)] = [
        (.generic(.iOS), "generic/platform=iOS"),
        (.generic(.macOS, variant: "Mac Catalyst"), "generic/platform=macOS,variant=Mac Catalyst"),
        (.simulator(.iOS, name: "iPhone 17 Pro"), "platform=iOS Simulator,name=iPhone 17 Pro"),
        (
            .simulator(.watchOS, name: "Apple Watch Series 11 (46mm)", operatingSystemVersion: "latest", architecture: "arm64"),
            "platform=watchOS Simulator,name=Apple Watch Series 11 (46mm),OS=latest,arch=arm64"
        ),
        (.device(.iOS, name: "My iPhone"), "platform=iOS,name=My iPhone"),
        (.device(.tvOS, name: "Living Room", architecture: "arm64"), "platform=tvOS,name=Living Room,arch=arm64"),
        (.device(identifier: "00008150-000B0000000000BB"), "id=00008150-000B0000000000BB"),
        (.macOS(), "platform=macOS"),
        (.macOS(architecture: "x86_64", variant: "Mac Catalyst"), "platform=macOS,arch=x86_64,variant=Mac Catalyst"),
        (.driverKit(architecture: "arm64"), "platform=DriverKit,arch=arm64"),
        (DestinationSpecifier(["platform": "visionOS Simulator", "name": "Apple Vision Pro"]), "platform=visionOS Simulator,name=Apple Vision Pro"),
        (DestinationSpecifier(["platform": "tvOS"], isGeneric: true), "generic/platform=tvOS"),
        (DestinationSpecifier("platform=iOS,id=abc").adding("arch", "arm64"), "platform=iOS,id=abc,arch=arm64"),
    ]

    @Test(arguments: cases)
    func `specifiers render as xcodebuild reads them`(_ specifier: DestinationSpecifier, _ expected: String) {
        #expect(specifier.rawValue == expected)
    }
}

@Suite struct `Setting assignments` {
    @Test func `a dictionary literal keeps its order`() {
        let assignments: SettingAssignments = ["B": "2", "A": "1", "C": "3"]
        #expect(assignments.assignments.map(\.name) == ["B", "A", "C"])
    }

    @Test func `the subscript reads the last assignment of a name`() {
        var assignments = SettingAssignments()
        assignments.append(name: "SWIFT_VERSION", value: "5")
        assignments.append(name: "SWIFT_VERSION", value: "6")
        #expect(assignments["SWIFT_VERSION"] == "6")
    }

    @Test func `setting through the subscript replaces the last assignment in place`() {
        var assignments: SettingAssignments = ["A": "1", "B": "2", "C": "3"]
        assignments["B"] = "20"
        #expect(assignments.assignments == [
            .init(name: "A", value: "1"),
            .init(name: "B", value: "20"),
            .init(name: "C", value: "3"),
        ])
    }

    @Test func `setting a new name through the subscript appends it`() {
        var assignments: SettingAssignments = ["A": "1"]
        assignments["B"] = "2"
        #expect(assignments.assignments.map(\.name) == ["A", "B"])
    }

    @Test func `setting nil removes every assignment of the name`() {
        var assignments = SettingAssignments()
        assignments.append(name: "A", value: "1")
        assignments.append(name: "B", value: "2")
        assignments.append(name: "A", value: "3")
        assignments["A"] = nil
        #expect(assignments.assignments == [.init(name: "B", value: "2")])
    }
}
