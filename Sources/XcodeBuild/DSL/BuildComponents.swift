public import System

// Components for options that only ``BuildCommand`` accepts.

/// Writes the archive of the `archive` action to a path (`-archivePath`).
public struct ArchivePath: XcodeBuildCommandComponent {
    /// The path of the `.xcarchive`.
    public var path: FilePath

    /// Creates the component.
    public init(_ path: FilePath) {
        self.path = path
    }

    public func apply(to command: inout BuildCommand) {
        command.archivePath = path
    }
}

/// Writes a result bundle to a path (`-resultBundlePath`).
public struct ResultBundlePath: XcodeBuildCommandComponent {
    /// The path of the `.xcresult`, which must not exist.
    public var path: FilePath

    /// Creates the component.
    public init(_ path: FilePath) {
        self.path = path
    }

    public func apply(to command: inout BuildCommand) {
        command.resultBundlePath = path
    }
}

/// Uses a result bundle version (`-resultBundleVersion`).
public struct ResultBundleVersion: XcodeBuildCommandComponent {
    /// The version. Only 3 exists.
    public var version: Int

    /// Creates the component.
    public init(_ version: Int) {
        self.version = version
    }

    public func apply(to command: inout BuildCommand) {
        command.resultBundleVersion = version
    }
}

/// Writes a result stream to an existing file (`-resultStreamPath`).
public struct ResultStreamPath: XcodeBuildCommandComponent {
    /// The path of the file.
    public var path: FilePath

    /// Creates the component.
    public init(_ path: FilePath) {
        self.path = path
    }

    public func apply(to command: inout BuildCommand) {
        command.resultStreamPath = path
    }
}

/// Builds independent targets in parallel (`-parallelizeTargets`).
public struct ParallelizeTargets: XcodeBuildCommandComponent {
    /// Creates the component.
    public init() {}

    public func apply(to command: inout BuildCommand) {
        command.parallelizeTargets = true
    }
}

/// Limits how many build operations run at once (`-jobs`).
public struct Jobs: XcodeBuildCommandComponent {
    /// The most operations at once.
    public var count: Int

    /// Creates the component.
    public init(_ count: Int) {
        self.count = count
    }

    public func apply(to command: inout BuildCommand) {
        command.jobs = count
    }
}

/// Leaves shell script environment variables out of the log (`-hideShellScriptEnvironment`).
public struct HideShellScriptEnvironment: XcodeBuildCommandComponent {
    /// Creates the component.
    public init() {}

    public func apply(to command: inout BuildCommand) {
        command.hideShellScriptEnvironment = true
    }
}

/// Prints how long each kind of build command took (`-showBuildTimingSummary`).
public struct ShowBuildTimingSummary: XcodeBuildCommandComponent {
    /// Creates the component.
    public init() {}

    public func apply(to command: inout BuildCommand) {
        command.showBuildTimingSummary = true
    }
}

/// Skips scheme actions that can't be performed instead of failing (`-skipUnavailableActions`).
public struct SkipUnavailableActions: XcodeBuildCommandComponent {
    /// Creates the component.
    public init() {}

    public func apply(to command: inout BuildCommand) {
        command.skipUnavailableActions = true
    }
}

/// Turns the address sanitizer on or off (`-enableAddressSanitizer`).
public struct AddressSanitizer: XcodeBuildCommandComponent {
    /// Whether the sanitizer is on.
    public var enabled: Bool

    /// Creates the component.
    public init(enabled: Bool = true) {
        self.enabled = enabled
    }

    public func apply(to command: inout BuildCommand) {
        command.sanitizers.addressSanitizerEnabled = enabled
    }
}

/// Turns the thread sanitizer on or off (`-enableThreadSanitizer`).
public struct ThreadSanitizer: XcodeBuildCommandComponent {
    /// Whether the sanitizer is on.
    public var enabled: Bool

    /// Creates the component.
    public init(enabled: Bool = true) {
        self.enabled = enabled
    }

    public func apply(to command: inout BuildCommand) {
        command.sanitizers.threadSanitizerEnabled = enabled
    }
}

/// Turns the undefined behavior sanitizer on or off (`-enableUndefinedBehaviorSanitizer`).
public struct UndefinedBehaviorSanitizer: XcodeBuildCommandComponent {
    /// Whether the sanitizer is on.
    public var enabled: Bool

    /// Creates the component.
    public init(enabled: Bool = true) {
        self.enabled = enabled
    }

    public func apply(to command: inout BuildCommand) {
        command.sanitizers.undefinedBehaviorSanitizerEnabled = enabled
    }
}

/// Turns code size profiling on or off (`-enableCodesizeProfile`). Xcode 27 and later.
public struct CodeSizeProfile: XcodeBuildCommandComponent {
    /// Whether profiling is on.
    public var enabled: Bool

    /// Creates the component.
    public init(enabled: Bool = true) {
        self.enabled = enabled
    }

    public func apply(to command: inout BuildCommand) {
        command.codeSizeProfile.enabled = enabled
    }
}

/// Writes code size profiling files to a directory (`-codesizeProfileOutputDir`). Xcode 27 and later.
public struct CodeSizeProfileOutputDirectory: XcodeBuildCommandComponent {
    /// The directory.
    public var path: FilePath

    /// Creates the component.
    public init(_ path: FilePath) {
        self.path = path
    }

    public func apply(to command: inout BuildCommand) {
        command.codeSizeProfile.outputDirectory = path
    }
}

/// Uses a test plan of the scheme (`-testPlan`).
public struct TestPlan: XcodeBuildCommandComponent {
    /// The name of the test plan, without its extension.
    public var name: String

    /// Creates the component.
    public init(_ name: String) {
        self.name = name
    }

    public func apply(to command: inout BuildCommand) {
        command.testing.testPlan = name
    }
}

/// Runs only these tests (`-only-testing`).
///
/// See ``TestingOptions/onlyTesting`` for the form of the identifiers.
public struct OnlyTesting: XcodeBuildCommandComponent {
    /// The test identifiers.
    public var identifiers: [String]

    /// Creates the component.
    public init(_ identifiers: String...) {
        self.identifiers = identifiers
    }

    /// Creates the component.
    public init(_ identifiers: [String]) {
        self.identifiers = identifiers
    }

    public func apply(to command: inout BuildCommand) {
        command.testing.onlyTesting.append(contentsOf: identifiers)
    }
}

/// Skips these tests (`-skip-testing`).
///
/// See ``TestingOptions/onlyTesting`` for the form of the identifiers.
public struct SkipTesting: XcodeBuildCommandComponent {
    /// The test identifiers.
    public var identifiers: [String]

    /// Creates the component.
    public init(_ identifiers: String...) {
        self.identifiers = identifiers
    }

    /// Creates the component.
    public init(_ identifiers: [String]) {
        self.identifiers = identifiers
    }

    public func apply(to command: inout BuildCommand) {
        command.testing.skipTesting.append(contentsOf: identifiers)
    }
}

/// Runs only a configuration of the test plan (`-only-test-configuration`).
public struct OnlyTestConfiguration: XcodeBuildCommandComponent {
    /// The name of the configuration.
    public var name: String

    /// Creates the component.
    public init(_ name: String) {
        self.name = name
    }

    public func apply(to command: inout BuildCommand) {
        command.testing.onlyTestConfigurations.append(name)
    }
}

/// Skips a configuration of the test plan (`-skip-test-configuration`).
public struct SkipTestConfiguration: XcodeBuildCommandComponent {
    /// The name of the configuration.
    public var name: String

    /// Creates the component.
    public init(_ name: String) {
        self.name = name
    }

    public func apply(to command: inout BuildCommand) {
        command.testing.skipTestConfigurations.append(name)
    }
}

/// Runs the tests in an ISO 639-1 language (`-testLanguage`).
public struct TestLanguage: XcodeBuildCommandComponent {
    /// The language code.
    public var code: String

    /// Creates the component.
    public init(_ code: String) {
        self.code = code
    }

    public func apply(to command: inout BuildCommand) {
        command.testing.testLanguage = code
    }
}

/// Runs the tests in an ISO 3166-1 region (`-testRegion`).
public struct TestRegion: XcodeBuildCommandComponent {
    /// The region code.
    public var code: String

    /// Creates the component.
    public init(_ code: String) {
        self.code = code
    }

    public func apply(to command: inout BuildCommand) {
        command.testing.testRegion = code
    }
}

/// Runs the tests an xctestrun file describes (`-xctestrun`).
public struct XCTestRun: XcodeBuildCommandComponent {
    /// The path of the xctestrun file.
    public var path: FilePath

    /// Creates the component.
    public init(_ path: FilePath) {
        self.path = path
    }

    public func apply(to command: inout BuildCommand) {
        command.testing.xctestrun = path
    }
}

/// Writes or reads an xctestproducts archive (`-testProductsPath`).
public struct TestProductsPath: XcodeBuildCommandComponent {
    /// The path of the `.xctestproducts`.
    public var path: FilePath

    /// Creates the component.
    public init(_ path: FilePath) {
        self.path = path
    }

    public func apply(to command: inout BuildCommand) {
        command.testing.testProductsPath = path
    }
}

/// Turns parallel testing on or off, overriding the scheme (`-parallel-testing-enabled`).
public struct ParallelTesting: XcodeBuildCommandComponent {
    /// Whether tests run in parallel.
    public var enabled: Bool

    /// Creates the component.
    public init(enabled: Bool = true) {
        self.enabled = enabled
    }

    public func apply(to command: inout BuildCommand) {
        command.testing.parallelTestingEnabled = enabled
    }
}

/// Uses exactly this many test runners for parallel testing (`-parallel-testing-worker-count`).
public struct ParallelTestingWorkerCount: XcodeBuildCommandComponent {
    /// The number of test runners.
    public var count: Int

    /// Creates the component.
    public init(_ count: Int) {
        self.count = count
    }

    public func apply(to command: inout BuildCommand) {
        command.testing.parallelTestingWorkerCount = count
    }
}

/// Uses at most this many test runners for parallel testing (`-maximum-parallel-testing-workers`).
public struct MaximumParallelTestingWorkers: XcodeBuildCommandComponent {
    /// The most test runners.
    public var count: Int

    /// Creates the component.
    public init(_ count: Int) {
        self.count = count
    }

    public func apply(to command: inout BuildCommand) {
        command.testing.maximumParallelTestingWorkers = count
    }
}

/// Tests on at most this many devices at once (`-maximum-concurrent-test-device-destinations`).
public struct MaximumConcurrentTestDeviceDestinations: XcodeBuildCommandComponent {
    /// The most devices.
    public var count: Int

    /// Creates the component.
    public init(_ count: Int) {
        self.count = count
    }

    public func apply(to command: inout BuildCommand) {
        command.testing.maximumConcurrentTestDeviceDestinations = count
    }
}

/// Tests on at most this many simulators at once (`-maximum-concurrent-test-simulator-destinations`).
public struct MaximumConcurrentTestSimulatorDestinations: XcodeBuildCommandComponent {
    /// The most simulators.
    public var count: Int

    /// Creates the component.
    public init(_ count: Int) {
        self.count = count
    }

    public func apply(to command: inout BuildCommand) {
        command.testing.maximumConcurrentTestSimulatorDestinations = count
    }
}

/// Finishes testing on one destination before starting on the next
/// (`-disable-concurrent-destination-testing`).
public struct DisableConcurrentDestinationTesting: XcodeBuildCommandComponent {
    /// Creates the component.
    public init() {}

    public func apply(to command: inout BuildCommand) {
        command.testing.disableConcurrentDestinationTesting = true
    }
}

/// Distributes test classes among the destinations (`-parallelize-tests-among-destinations`).
public struct ParallelizeTestsAmongDestinations: XcodeBuildCommandComponent {
    /// Creates the component.
    public init() {}

    public func apply(to command: inout BuildCommand) {
        command.testing.parallelizeTestsAmongDestinations = true
    }
}

/// Turns test timeouts on or off, overriding the test plan (`-test-timeouts-enabled`).
public struct TestTimeouts: XcodeBuildCommandComponent {
    /// Whether timeouts apply.
    public var enabled: Bool

    /// Creates the component.
    public init(enabled: Bool = true) {
        self.enabled = enabled
    }

    public func apply(to command: inout BuildCommand) {
        command.testing.testTimeoutsEnabled = enabled
    }
}

/// Sets how long a test may run, in whole seconds (`-default-test-execution-time-allowance`).
public struct DefaultTestExecutionTimeAllowance: XcodeBuildCommandComponent {
    /// The allowance.
    public var allowance: Duration

    /// Creates the component.
    public init(_ allowance: Duration) {
        self.allowance = allowance
    }

    public func apply(to command: inout BuildCommand) {
        command.testing.defaultTestExecutionTimeAllowance = allowance
    }
}

/// Sets the longest any test may run, in whole seconds (`-maximum-test-execution-time-allowance`).
public struct MaximumTestExecutionTimeAllowance: XcodeBuildCommandComponent {
    /// The allowance.
    public var allowance: Duration

    /// Creates the component.
    public init(_ allowance: Duration) {
        self.allowance = allowance
    }

    public func apply(to command: inout BuildCommand) {
        command.testing.maximumTestExecutionTimeAllowance = allowance
    }
}

/// Runs the tests this many times, or at most this many times when repeating
/// until failure or retrying (`-test-iterations`).
public struct TestIterations: XcodeBuildCommandComponent {
    /// The number of iterations.
    public var count: Int

    /// Creates the component.
    public init(_ count: Int) {
        self.count = count
    }

    public func apply(to command: inout BuildCommand) {
        command.testing.testIterations = count
    }
}

/// Repeats failing tests until they pass (`-retry-tests-on-failure`).
public struct RetryTestsOnFailure: XcodeBuildCommandComponent {
    /// Creates the component.
    public init() {}

    public func apply(to command: inout BuildCommand) {
        command.testing.testRepetition = .retryOnFailure
    }
}

/// Repeats tests until they fail (`-run-tests-until-failure`).
public struct RunTestsUntilFailure: XcodeBuildCommandComponent {
    /// Creates the component.
    public init() {}

    public func apply(to command: inout BuildCommand) {
        command.testing.testRepetition = .untilFailure
    }
}

/// Runs each repetition of the tests in a new process, or in the same one
/// (`-test-repetition-relaunch-enabled`).
public struct TestRepetitionRelaunch: XcodeBuildCommandComponent {
    /// Whether each repetition runs in a new process.
    public var enabled: Bool

    /// Creates the component.
    public init(enabled: Bool = true) {
        self.enabled = enabled
    }

    public func apply(to command: inout BuildCommand) {
        command.testing.testRepetitionRelaunchEnabled = enabled
    }
}

/// Sets when testing collects diagnostics such as a sysdiagnose (`-collect-test-diagnostics`).
public struct CollectTestDiagnostics: XcodeBuildCommandComponent {
    /// When to collect diagnostics.
    public var collection: TestDiagnosticsCollection

    /// Creates the component.
    public init(_ collection: TestDiagnosticsCollection) {
        self.collection = collection
    }

    public func apply(to command: inout BuildCommand) {
        command.testing.collectTestDiagnostics = collection
    }
}

/// Turns the collection of performance traces and memory graphs for
/// performance XCTests on or off (`-enablePerformanceTestsDiagnostics`).
public struct PerformanceTestsDiagnostics: XcodeBuildCommandComponent {
    /// Whether diagnostics are collected.
    public var enabled: Bool

    /// Creates the component.
    public init(enabled: Bool = true) {
        self.enabled = enabled
    }

    public func apply(to command: inout BuildCommand) {
        command.testing.performanceTestsDiagnosticsEnabled = enabled
    }
}

/// Turns code coverage on or off, overriding the scheme (`-enableCodeCoverage`).
public struct CodeCoverage: XcodeBuildCommandComponent {
    /// Whether coverage is gathered.
    public var enabled: Bool

    /// Creates the component.
    public init(enabled: Bool = true) {
        self.enabled = enabled
    }

    public func apply(to command: inout BuildCommand) {
        command.testing.codeCoverageEnabled = enabled
    }
}

/// Lists the tests instead of running them (`-enumerate-tests`).
public struct EnumerateTests: XcodeBuildCommandComponent {
    /// How to list the tests.
    public var enumeration: TestEnumeration

    /// Creates the component.
    ///
    /// - Parameters:
    ///   - style: How the list is organized.
    ///   - format: The format of the list.
    ///   - outputPath: The file to write the list to, or `nil` for standard output.
    public init(style: TestEnumeration.Style? = nil, format: TestEnumeration.Format? = nil, outputPath: FilePath? = nil) {
        self.enumeration = TestEnumeration(style: style, format: format, outputPath: outputPath)
    }

    public func apply(to command: inout BuildCommand) {
        command.testing.testEnumeration = enumeration
    }
}
