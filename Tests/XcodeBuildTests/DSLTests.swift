import System
import Testing
import XcodeBuild

/// A command built with one DSL component, next to the same command with the
/// property set directly, and the command with neither.
struct EquivalenceCase: CustomTestStringConvertible, Sendable {
    let component: String
    let componentArguments: [String]
    let propertyArguments: [String]
    let baseArguments: [String]

    init<Command: XcodeBuildCommand>(
        _ component: String,
        base: Command,
        component built: Command,
        property modify: (inout Command) -> Void
    ) {
        self.component = component
        self.componentArguments = built.arguments
        var modified = base
        modify(&modified)
        self.propertyArguments = modified.arguments
        self.baseArguments = base.arguments
    }

    var testDescription: String {
        component
    }
}

@Suite struct `Result builder DSL` {
    static let sharedCases: [EquivalenceCase] = [
        EquivalenceCase("Project", base: ListCommand(), component: ListCommand { Project("App.xcodeproj") }) {
            $0.container = .project("App.xcodeproj")
        },
        EquivalenceCase("Workspace", base: BuildCommand(), component: BuildCommand { Workspace("App.xcworkspace") }) {
            $0.container = .workspace("App.xcworkspace")
        },
        EquivalenceCase("Scheme", base: ShowBuildSettingsCommand(), component: ShowBuildSettingsCommand { Scheme("App") }) {
            $0.scheme = "App"
        },
        EquivalenceCase(
            "Target",
            base: BuildCommand(),
            component: BuildCommand {
                Target("App")
                Target("Framework")
            }
        ) {
            $0.targets = .targets(["App", "Framework"])
        },
        EquivalenceCase("AllTargets", base: BuildCommand(), component: BuildCommand { AllTargets() }) {
            $0.targets = .allTargets
        },
        EquivalenceCase("BuildConfiguration", base: BuildCommand(), component: BuildCommand { BuildConfiguration("Release") }) {
            $0.configuration = "Release"
        },
        EquivalenceCase("SDK", base: FindExecutableCommand(name: "clang"), component: FindExecutableCommand(name: "clang") { SDK("macosx") }) {
            $0.sdk = "macosx"
        },
        EquivalenceCase(
            "Architecture",
            base: BuildCommand(),
            component: BuildCommand {
                Architecture("arm64")
                Architecture("x86_64")
            }
        ) {
            $0.architectures = ["arm64", "x86_64"]
        },
        EquivalenceCase(
            "Destination",
            base: BuildCommand(),
            component: BuildCommand {
                Destination(.generic(.iOS))
                Destination(.macOS(architecture: "arm64"))
            }
        ) {
            $0.destinations = [.generic(.iOS), .macOS(architecture: "arm64")]
        },
        EquivalenceCase("DestinationTimeout", base: BuildCommand(), component: BuildCommand { DestinationTimeout(.seconds(90)) }) {
            $0.destinationTimeout = .seconds(90)
        },
        EquivalenceCase(
            "BuildSetting",
            base: BuildCommand(),
            component: BuildCommand {
                BuildSetting("CODE_SIGNING_ALLOWED", "NO")
                BuildSetting("CODE_SIGNING_ALLOWED", "YES")
            }
        ) {
            $0.buildSettings.append(name: "CODE_SIGNING_ALLOWED", value: "NO")
            $0.buildSettings.append(name: "CODE_SIGNING_ALLOWED", value: "YES")
        },
        EquivalenceCase("XCConfig", base: BuildCommand(), component: BuildCommand { XCConfig("CI.xcconfig") }) {
            $0.xcconfig = "CI.xcconfig"
        },
        EquivalenceCase("Toolchain", base: FindLibraryCommand(name: "libclang.dylib"), component: FindLibraryCommand(name: "libclang.dylib") { Toolchain("swift") }) {
            $0.toolchain = "swift"
        },
        EquivalenceCase(
            "DerivedDataPath",
            base: ResolvePackageDependenciesCommand(),
            component: ResolvePackageDependenciesCommand { DerivedDataPath("DerivedData") }
        ) {
            $0.derivedDataPath = "DerivedData"
        },
        EquivalenceCase(
            "ExportPath",
            base: DownloadPlatformCommand(platform: .visionOS),
            component: DownloadPlatformCommand(platform: .visionOS) { ExportPath("Runtimes") }
        ) {
            $0.exportPath = "Runtimes"
        },
        EquivalenceCase(
            "BuildVersion",
            base: ShowComponentCommand(component: .metalToolchain),
            component: ShowComponentCommand(component: .metalToolchain) { BuildVersion("27A266a") }
        ) {
            $0.buildVersion = "27A266a"
        },
        EquivalenceCase(
            "ArchitectureVariant",
            base: DownloadAllPlatformsCommand(),
            component: DownloadAllPlatformsCommand { ArchitectureVariant(.universal) }
        ) {
            $0.architectureVariant = .universal
        },
        EquivalenceCase("Quiet", base: BuildCommand(), component: BuildCommand { Quiet() }) {
            $0.verbosity = .quiet
        },
        EquivalenceCase(
            "Verbose",
            base: ExportNotarizedAppCommand(archivePath: "App.xcarchive", exportPath: "Export"),
            component: ExportNotarizedAppCommand(archivePath: "App.xcarchive", exportPath: "Export") { Verbose() }
        ) {
            $0.verbosity = .verbose
        },
        EquivalenceCase(
            "UserDefaultOverride",
            base: VersionCommand(),
            component: VersionCommand { UserDefaultOverride("IDEPackageSupportUseBuiltinSCM", "YES") }
        ) {
            $0.userDefaults.append(name: "IDEPackageSupportUseBuiltinSCM", value: "YES")
        },
        EquivalenceCase(
            "AdditionalArguments",
            base: HelpCommand(),
            component: HelpCommand {
                AdditionalArguments("-one", "two")
                AdditionalArguments(["-three"])
            }
        ) {
            $0.additionalArguments = ["-one", "two", "-three"]
        },
    ]

    static let packageAndSigningCases: [EquivalenceCase] = [
        EquivalenceCase("ClonedSourcePackagesDirectory", base: BuildCommand(), component: BuildCommand { ClonedSourcePackagesDirectory("SourcePackages") }) {
            $0.packageResolution.clonedSourcePackagesDirectory = "SourcePackages"
        },
        EquivalenceCase("PackageCachePath", base: BuildCommand(), component: BuildCommand { PackageCachePath("PackageCache") }) {
            $0.packageResolution.packageCachePath = "PackageCache"
        },
        EquivalenceCase("DisableAutomaticPackageResolution", base: BuildCommand(), component: BuildCommand { DisableAutomaticPackageResolution() }) {
            $0.packageResolution.disableAutomaticPackageResolution = true
        },
        EquivalenceCase("OnlyUsePackageVersionsFromResolvedFile", base: BuildCommand(), component: BuildCommand { OnlyUsePackageVersionsFromResolvedFile() }) {
            $0.packageResolution.onlyUsePackageVersionsFromResolvedFile = true
        },
        EquivalenceCase("SkipPackageUpdates", base: BuildCommand(), component: BuildCommand { SkipPackageUpdates() }) {
            $0.packageResolution.skipPackageUpdates = true
        },
        EquivalenceCase("DisablePackageRepositoryCache", base: BuildCommand(), component: BuildCommand { DisablePackageRepositoryCache() }) {
            $0.packageResolution.disablePackageRepositoryCache = true
        },
        EquivalenceCase("SkipPackagePluginValidation", base: BuildCommand(), component: BuildCommand { SkipPackagePluginValidation() }) {
            $0.packageResolution.skipPackagePluginValidation = true
        },
        EquivalenceCase("SkipMacroValidation", base: BuildCommand(), component: BuildCommand { SkipMacroValidation() }) {
            $0.packageResolution.skipMacroValidation = true
        },
        EquivalenceCase("SkipPackageSignatureValidation", base: BuildCommand(), component: BuildCommand { SkipPackageSignatureValidation() }) {
            $0.packageResolution.skipPackageSignatureValidation = true
        },
        EquivalenceCase("PackageAuthorizationProvider", base: BuildCommand(), component: BuildCommand { PackageAuthorizationProvider(.keychain) }) {
            $0.packageResolution.packageAuthorizationProvider = .keychain
        },
        EquivalenceCase(
            "DefaultPackageRegistryURL",
            base: BuildCommand(),
            component: BuildCommand { DefaultPackageRegistryURL("https://packages.example.com") }
        ) {
            $0.packageResolution.defaultPackageRegistryURL = "https://packages.example.com"
        },
        EquivalenceCase(
            "PackageRegistryTransformation",
            base: BuildCommand(),
            component: BuildCommand { PackageRegistryTransformation(.useRegistryIdentityAndSources) }
        ) {
            $0.packageResolution.registryTransformation = .useRegistryIdentityAndSources
        },
        EquivalenceCase("PackageFingerprintPolicy", base: BuildCommand(), component: BuildCommand { PackageFingerprintPolicy(.warn) }) {
            $0.packageResolution.packageFingerprintPolicy = .warn
        },
        EquivalenceCase("PackageSigningEntityPolicy", base: BuildCommand(), component: BuildCommand { PackageSigningEntityPolicy(.strict) }) {
            $0.packageResolution.packageSigningEntityPolicy = .strict
        },
        EquivalenceCase("SourceControlProvider", base: BuildCommand(), component: BuildCommand { SourceControlProvider(.xcode) }) {
            $0.packageResolution.sourceControlProvider = .xcode
        },
        EquivalenceCase(
            "AllowProvisioningUpdates",
            base: ExportArchiveCommand(archivePath: "App.xcarchive", exportOptions: .propertyList("Options.plist")),
            component: ExportArchiveCommand(archivePath: "App.xcarchive", exportOptions: .propertyList("Options.plist")) {
                AllowProvisioningUpdates()
            }
        ) {
            $0.provisioning.allowProvisioningUpdates = true
        },
        EquivalenceCase("AllowProvisioningDeviceRegistration", base: BuildCommand(), component: BuildCommand { AllowProvisioningDeviceRegistration() }) {
            $0.provisioning.allowProvisioningDeviceRegistration = true
        },
        EquivalenceCase(
            "AuthenticationKey",
            base: BuildCommand(),
            component: BuildCommand { AuthenticationKey(path: "AuthKey.p8", identifier: "KEY", issuerIdentifier: "ISSUER") }
        ) {
            $0.provisioning.authenticationKey = AppStoreConnectKey(path: "AuthKey.p8", identifier: "KEY", issuerIdentifier: "ISSUER")
        },
    ]

    static let buildCases: [EquivalenceCase] = [
        EquivalenceCase("ArchivePath", base: BuildCommand(), component: BuildCommand { ArchivePath("App.xcarchive") }) {
            $0.archivePath = "App.xcarchive"
        },
        EquivalenceCase("ResultBundlePath", base: BuildCommand(), component: BuildCommand { ResultBundlePath("App.xcresult") }) {
            $0.resultBundlePath = "App.xcresult"
        },
        EquivalenceCase("ResultBundleVersion", base: BuildCommand(), component: BuildCommand { ResultBundleVersion(3) }) {
            $0.resultBundleVersion = 3
        },
        EquivalenceCase("ResultStreamPath", base: BuildCommand(), component: BuildCommand { ResultStreamPath("stream.json") }) {
            $0.resultStreamPath = "stream.json"
        },
        EquivalenceCase("ParallelizeTargets", base: BuildCommand(), component: BuildCommand { ParallelizeTargets() }) {
            $0.parallelizeTargets = true
        },
        EquivalenceCase("Jobs", base: BuildCommand(), component: BuildCommand { Jobs(4) }) {
            $0.jobs = 4
        },
        EquivalenceCase("HideShellScriptEnvironment", base: BuildCommand(), component: BuildCommand { HideShellScriptEnvironment() }) {
            $0.hideShellScriptEnvironment = true
        },
        EquivalenceCase("ShowBuildTimingSummary", base: BuildCommand(), component: BuildCommand { ShowBuildTimingSummary() }) {
            $0.showBuildTimingSummary = true
        },
        EquivalenceCase("SkipUnavailableActions", base: BuildCommand(), component: BuildCommand { SkipUnavailableActions() }) {
            $0.skipUnavailableActions = true
        },
        EquivalenceCase("AddressSanitizer", base: BuildCommand(), component: BuildCommand { AddressSanitizer() }) {
            $0.sanitizers.addressSanitizerEnabled = true
        },
        EquivalenceCase("ThreadSanitizer", base: BuildCommand(), component: BuildCommand { ThreadSanitizer(enabled: false) }) {
            $0.sanitizers.threadSanitizerEnabled = false
        },
        EquivalenceCase("UndefinedBehaviorSanitizer", base: BuildCommand(), component: BuildCommand { UndefinedBehaviorSanitizer() }) {
            $0.sanitizers.undefinedBehaviorSanitizerEnabled = true
        },
        EquivalenceCase("CodeSizeProfile", base: BuildCommand(), component: BuildCommand { CodeSizeProfile() }) {
            $0.codeSizeProfile.enabled = true
        },
        EquivalenceCase("CodeSizeProfileOutputDirectory", base: BuildCommand(), component: BuildCommand { CodeSizeProfileOutputDirectory("CodeSize") }) {
            $0.codeSizeProfile.outputDirectory = "CodeSize"
        },
        EquivalenceCase("TestPlan", base: BuildCommand(), component: BuildCommand { TestPlan("Unit") }) {
            $0.testing.testPlan = "Unit"
        },
        EquivalenceCase(
            "OnlyTesting",
            base: BuildCommand(),
            component: BuildCommand {
                OnlyTesting("AppTests/A", "AppTests/B")
                OnlyTesting(["AppTests/C"])
            }
        ) {
            $0.testing.onlyTesting = ["AppTests/A", "AppTests/B", "AppTests/C"]
        },
        EquivalenceCase("SkipTesting", base: BuildCommand(), component: BuildCommand { SkipTesting("AppTests/Slow") }) {
            $0.testing.skipTesting = ["AppTests/Slow"]
        },
        EquivalenceCase("OnlyTestConfiguration", base: BuildCommand(), component: BuildCommand { OnlyTestConfiguration("English") }) {
            $0.testing.onlyTestConfigurations = ["English"]
        },
        EquivalenceCase("SkipTestConfiguration", base: BuildCommand(), component: BuildCommand { SkipTestConfiguration("German") }) {
            $0.testing.skipTestConfigurations = ["German"]
        },
        EquivalenceCase("TestLanguage", base: BuildCommand(), component: BuildCommand { TestLanguage("ja") }) {
            $0.testing.testLanguage = "ja"
        },
        EquivalenceCase("TestRegion", base: BuildCommand(), component: BuildCommand { TestRegion("JP") }) {
            $0.testing.testRegion = "JP"
        },
        EquivalenceCase("XCTestRun", base: BuildCommand(), component: BuildCommand { XCTestRun("App.xctestrun") }) {
            $0.testing.xctestrun = "App.xctestrun"
        },
        EquivalenceCase("TestProductsPath", base: BuildCommand(), component: BuildCommand { TestProductsPath("App.xctestproducts") }) {
            $0.testing.testProductsPath = "App.xctestproducts"
        },
        EquivalenceCase("ParallelTesting", base: BuildCommand(), component: BuildCommand { ParallelTesting(enabled: false) }) {
            $0.testing.parallelTestingEnabled = false
        },
        EquivalenceCase("ParallelTestingWorkerCount", base: BuildCommand(), component: BuildCommand { ParallelTestingWorkerCount(2) }) {
            $0.testing.parallelTestingWorkerCount = 2
        },
        EquivalenceCase("MaximumParallelTestingWorkers", base: BuildCommand(), component: BuildCommand { MaximumParallelTestingWorkers(3) }) {
            $0.testing.maximumParallelTestingWorkers = 3
        },
        EquivalenceCase(
            "MaximumConcurrentTestDeviceDestinations",
            base: BuildCommand(),
            component: BuildCommand { MaximumConcurrentTestDeviceDestinations(2) }
        ) {
            $0.testing.maximumConcurrentTestDeviceDestinations = 2
        },
        EquivalenceCase(
            "MaximumConcurrentTestSimulatorDestinations",
            base: BuildCommand(),
            component: BuildCommand { MaximumConcurrentTestSimulatorDestinations(4) }
        ) {
            $0.testing.maximumConcurrentTestSimulatorDestinations = 4
        },
        EquivalenceCase(
            "DisableConcurrentDestinationTesting",
            base: BuildCommand(),
            component: BuildCommand { DisableConcurrentDestinationTesting() }
        ) {
            $0.testing.disableConcurrentDestinationTesting = true
        },
        EquivalenceCase(
            "ParallelizeTestsAmongDestinations",
            base: BuildCommand(),
            component: BuildCommand { ParallelizeTestsAmongDestinations() }
        ) {
            $0.testing.parallelizeTestsAmongDestinations = true
        },
        EquivalenceCase("TestTimeouts", base: BuildCommand(), component: BuildCommand { TestTimeouts() }) {
            $0.testing.testTimeoutsEnabled = true
        },
        EquivalenceCase(
            "DefaultTestExecutionTimeAllowance",
            base: BuildCommand(),
            component: BuildCommand { DefaultTestExecutionTimeAllowance(.seconds(30)) }
        ) {
            $0.testing.defaultTestExecutionTimeAllowance = .seconds(30)
        },
        EquivalenceCase(
            "MaximumTestExecutionTimeAllowance",
            base: BuildCommand(),
            component: BuildCommand { MaximumTestExecutionTimeAllowance(.seconds(300)) }
        ) {
            $0.testing.maximumTestExecutionTimeAllowance = .seconds(300)
        },
        EquivalenceCase("TestIterations", base: BuildCommand(), component: BuildCommand { TestIterations(10) }) {
            $0.testing.testIterations = 10
        },
        EquivalenceCase("RetryTestsOnFailure", base: BuildCommand(), component: BuildCommand { RetryTestsOnFailure() }) {
            $0.testing.testRepetition = .retryOnFailure
        },
        EquivalenceCase("RunTestsUntilFailure", base: BuildCommand(), component: BuildCommand { RunTestsUntilFailure() }) {
            $0.testing.testRepetition = .untilFailure
        },
        EquivalenceCase("TestRepetitionRelaunch", base: BuildCommand(), component: BuildCommand { TestRepetitionRelaunch() }) {
            $0.testing.testRepetitionRelaunchEnabled = true
        },
        EquivalenceCase("CollectTestDiagnostics", base: BuildCommand(), component: BuildCommand { CollectTestDiagnostics(.never) }) {
            $0.testing.collectTestDiagnostics = .never
        },
        EquivalenceCase("PerformanceTestsDiagnostics", base: BuildCommand(), component: BuildCommand { PerformanceTestsDiagnostics() }) {
            $0.testing.performanceTestsDiagnosticsEnabled = true
        },
        EquivalenceCase("CodeCoverage", base: BuildCommand(), component: BuildCommand { CodeCoverage() }) {
            $0.testing.codeCoverageEnabled = true
        },
        EquivalenceCase(
            "EnumerateTests",
            base: BuildCommand(),
            component: BuildCommand { EnumerateTests(style: .hierarchical, format: .text, outputPath: "-") }
        ) {
            $0.testing.testEnumeration = TestEnumeration(style: .hierarchical, format: .text, outputPath: "-")
        },
    ]

    static let commandSpecificCases: [EquivalenceCase] = [
        EquivalenceCase("BuildSettingsAction", base: ShowBuildSettingsCommand(), component: ShowBuildSettingsCommand { BuildSettingsAction(.test) }) {
            $0.action = .test
        },
        EquivalenceCase(
            "DefaultLanguage",
            base: ExportLocalizationsCommand(localizationPath: "Localizations"),
            component: ExportLocalizationsCommand(localizationPath: "Localizations") { DefaultLanguage("en") }
        ) {
            $0.defaultLanguage = "en"
        },
        EquivalenceCase(
            "ExportLanguage",
            base: ExportLocalizationsCommand(localizationPath: "Localizations"),
            component: ExportLocalizationsCommand(localizationPath: "Localizations") {
                ExportLanguage("zh-Hans", "ja")
                ExportLanguage(["fr"])
            }
        ) {
            $0.exportLanguages = ["zh-Hans", "ja", "fr"]
        },
        EquivalenceCase(
            "IncludeScreenshots",
            base: ExportLocalizationsCommand(localizationPath: "Localizations"),
            component: ExportLocalizationsCommand(localizationPath: "Localizations") { IncludeScreenshots() }
        ) {
            $0.includeScreenshots = true
        },
        EquivalenceCase(
            "MergeImport",
            base: ImportLocalizationsCommand(localizationPath: "fr.xliff"),
            component: ImportLocalizationsCommand(localizationPath: "fr.xliff") { MergeImport() }
        ) {
            $0.mergeImport = true
        },
        EquivalenceCase(
            "Framework",
            base: CreateXCFrameworkCommand(output: "MyKit.xcframework"),
            component: CreateXCFrameworkCommand(output: "MyKit.xcframework") {
                Framework("iOS/MyKit.framework", debugSymbols: ["iOS/MyKit.framework.dSYM"])
                Framework(named: "MyKit.framework", inArchive: "MyKit.xcarchive")
            }
        ) {
            $0.contents = [
                .framework("iOS/MyKit.framework", debugSymbols: ["iOS/MyKit.framework.dSYM"]),
                .framework(named: "MyKit.framework", inArchive: "MyKit.xcarchive"),
            ]
        },
        EquivalenceCase(
            "Library",
            base: CreateXCFrameworkCommand(output: "MyKit.xcframework"),
            component: CreateXCFrameworkCommand(output: "MyKit.xcframework") {
                Library("libMyKit.a", headers: "include")
                Library(named: "libMyKit.a", inArchive: "MyKit.xcarchive", debugSymbols: ["MyKit.dSYM"])
            }
        ) {
            $0.contents = [
                .library("libMyKit.a", headers: "include"),
                .library(named: "libMyKit.a", inArchive: "MyKit.xcarchive", debugSymbols: ["MyKit.dSYM"]),
            ]
        },
        EquivalenceCase(
            "AllowInternalDistribution",
            base: CreateXCFrameworkCommand(output: "MyKit.xcframework"),
            component: CreateXCFrameworkCommand(output: "MyKit.xcframework") { AllowInternalDistribution() }
        ) {
            $0.allowInternalDistribution = true
        },
        EquivalenceCase(
            "ModelCode",
            base: PrepareDeviceSupportCommand(platform: .iOS, operatingSystemVersion: "26.2"),
            component: PrepareDeviceSupportCommand(platform: .iOS, operatingSystemVersion: "26.2") { ModelCode("iPhone16,1") }
        ) {
            $0.modelCode = "iPhone16,1"
        },
        EquivalenceCase(
            "DeviceArchitecture",
            base: PrepareDeviceSupportCommand(platform: .iOS, operatingSystemVersion: "26.2"),
            component: PrepareDeviceSupportCommand(platform: .iOS, operatingSystemVersion: "26.2") { DeviceArchitecture("arm64e") }
        ) {
            $0.architecture = "arm64e"
        },
        EquivalenceCase("CheckForNewerComponents", base: RunFirstLaunchCommand(), component: RunFirstLaunchCommand { CheckForNewerComponents() }) {
            $0.checkForNewerComponents = true
        },
    ]

    @Test(arguments: sharedCases + packageAndSigningCases + buildCases + commandSpecificCases)
    func `a component renders the same arguments as setting the property`(_ equivalence: EquivalenceCase) {
        #expect(equivalence.componentArguments == equivalence.propertyArguments)
        #expect(equivalence.componentArguments != equivalence.baseArguments)
    }

    @Test func `components apply in order and later ones win`() {
        let command = BuildCommand {
            Scheme("First")
            Scheme("Second")
        }
        #expect(command.scheme == "Second")
    }

    @Test func `control flow, availability, and shared content work in the closure`() {
        @XcodeBuildCommandBuilder<BuildCommand>
        var common: XcodeBuildCommandContent<BuildCommand> {
            Workspace("App.xcworkspace")
            Scheme("App")
        }
        let isContinuousIntegration = true
        let configuration: String? = "Release"
        let simulators = ["iPhone 17 Pro", "iPad Pro 13-inch (M5)"]
        enum Platform {
            case iOS
            case macOS
        }
        let platform = Platform.iOS

        let command = BuildCommand(.clean, .build) {
            common
            if isContinuousIntegration {
                AllowProvisioningUpdates()
            } else {
                Quiet()
            }
            if let configuration {
                BuildConfiguration(configuration)
            }
            switch platform {
            case .iOS:
                SDK("iphonesimulator")
            case .macOS:
                SDK("macosx")
            }
            for simulator in simulators {
                Destination(.simulator(.iOS, name: simulator))
            }
            if #available(macOS 15, *) {
                Jobs(4)
            }
        }

        #expect(command.arguments == [
            "-workspace", "App.xcworkspace",
            "-scheme", "App",
            "-configuration", "Release",
            "-sdk", "iphonesimulator",
            "-destination", "platform=iOS Simulator,name=iPhone 17 Pro",
            "-destination", "platform=iOS Simulator,name=iPad Pro 13-inch (M5)",
            "-allowProvisioningUpdates",
            "-jobs", "4",
            "clean", "build",
        ])
    }

    @Test func `a command built with components can still be changed through its properties`() {
        var command = BuildCommand(.test) {
            Scheme("App")
        }
        command.testing.onlyTesting = ["AppTests/LoginTests"]
        #expect(command.arguments == ["-scheme", "App", "-only-testing", "AppTests/LoginTests", "test"])
    }

    @Test func `a build command without a closure keeps its actions`() {
        #expect(BuildCommand(.clean, .build).arguments == ["clean", "build"])
    }
}
