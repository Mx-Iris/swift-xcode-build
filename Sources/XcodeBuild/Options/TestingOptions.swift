public import System

/// Options for the `test`, `build-for-testing`, and `test-without-building` actions.
///
/// Options set to `nil` or `false` are left out, so the scheme's and test
/// plan's own settings apply.
public struct TestingOptions: Sendable, Hashable {
    /// The test plan of the scheme to use, by name without its extension (`-testPlan`).
    public var testPlan: String?

    /// Tests to run, excluding all others (`-only-testing`).
    ///
    /// An identifier has the form `TestTarget[/TestClass[/TestMethod]]`. An
    /// identifier that starts with `@` names a file of identifiers, one per
    /// line (Xcode 27 and later). `onlyTesting` takes precedence over
    /// ``skipTesting``.
    public var onlyTesting: [String]

    /// Tests to skip, including all others (`-skip-testing`).
    ///
    /// Identifiers have the same form as in ``onlyTesting``.
    public var skipTesting: [String]

    /// Test plan configurations to run, excluding all others (`-only-test-configuration`).
    public var onlyTestConfigurations: [String]

    /// Test plan configurations to skip (`-skip-test-configuration`).
    public var skipTestConfigurations: [String]

    /// The ISO 639-1 language to run the tests in (`-testLanguage`).
    public var testLanguage: String?

    /// The ISO 3166-1 region to run the tests in (`-testRegion`).
    public var testRegion: String?

    /// An xctestrun file that describes the tests to run with
    /// `test-without-building` (`-xctestrun`). Can't be combined with a
    /// project or workspace.
    public var xctestrun: FilePath?

    /// Where `build-for-testing` writes an xctestproducts archive, or where
    /// `test-without-building` reads it (`-testProductsPath`). Can't be
    /// combined with a project or workspace.
    public var testProductsPath: FilePath?

    /// Whether to run tests in parallel, overriding each test target's
    /// setting in the scheme (`-parallel-testing-enabled`).
    public var parallelTestingEnabled: Bool?

    /// The exact number of test runners for parallel testing (`-parallel-testing-worker-count`).
    public var parallelTestingWorkerCount: Int?

    /// The most test runners for parallel testing (`-maximum-parallel-testing-workers`).
    public var maximumParallelTestingWorkers: Int?

    /// The most devices to test on at once when there are several device
    /// destinations (`-maximum-concurrent-test-device-destinations`).
    public var maximumConcurrentTestDeviceDestinations: Int?

    /// The most simulators to test on at once when there are several
    /// simulator destinations (`-maximum-concurrent-test-simulator-destinations`).
    public var maximumConcurrentTestSimulatorDestinations: Int?

    /// Whether to finish testing on one destination before starting on the
    /// next (`-disable-concurrent-destination-testing`).
    public var disableConcurrentDestinationTesting: Bool

    /// Whether to distribute test classes among the destinations instead of
    /// running every test on every destination
    /// (`-parallelize-tests-among-destinations`). Requires parallel testing.
    public var parallelizeTestsAmongDestinations: Bool

    /// Whether test timeouts apply, overriding the test plan (`-test-timeouts-enabled`).
    public var testTimeoutsEnabled: Bool?

    /// How long a test may run when timeouts are enabled, in whole seconds
    /// (`-default-test-execution-time-allowance`).
    public var defaultTestExecutionTimeAllowance: Duration?

    /// The longest any test may run, whatever its own allowance, in whole
    /// seconds (`-maximum-test-execution-time-allowance`).
    public var maximumTestExecutionTimeAllowance: Duration?

    /// How many times to run the tests, or the most times when combined with
    /// ``testRepetition`` (`-test-iterations`).
    public var testIterations: Int?

    /// Whether to repeat tests until they fail or until they pass.
    public var testRepetition: TestRepetitionMode?

    /// Whether each repetition runs in a new process
    /// (`-test-repetition-relaunch-enabled`). Requires ``testIterations``
    /// or ``testRepetition``.
    public var testRepetitionRelaunchEnabled: Bool?

    /// When to collect diagnostics such as a sysdiagnose (`-collect-test-diagnostics`).
    public var collectTestDiagnostics: TestDiagnosticsCollection?

    /// Whether to collect a performance trace and memory graph for performance
    /// XCTests (`-enablePerformanceTestsDiagnostics`).
    public var performanceTestsDiagnosticsEnabled: Bool?

    /// Whether to gather code coverage, overriding the scheme (`-enableCodeCoverage`).
    public var codeCoverageEnabled: Bool?

    /// Lists the tests instead of running them (`-enumerate-tests`). Requires
    /// a destination.
    public var testEnumeration: TestEnumeration?

    /// Creates testing options that leave everything to the scheme and test plan.
    public init() {
        self.onlyTesting = []
        self.skipTesting = []
        self.onlyTestConfigurations = []
        self.skipTestConfigurations = []
        self.disableConcurrentDestinationTesting = false
        self.parallelizeTestsAmongDestinations = false
    }

    func render(into writer: inout ArgumentWriter) {
        writer.option("-xctestrun", xctestrun)
        writer.option("-testProductsPath", testProductsPath)
        writer.option("-testPlan", testPlan)
        writer.repeatedOption("-only-testing", onlyTesting)
        writer.repeatedOption("-skip-testing", skipTesting)
        writer.repeatedOption("-only-test-configuration", onlyTestConfigurations)
        writer.repeatedOption("-skip-test-configuration", skipTestConfigurations)
        writer.option("-testLanguage", testLanguage)
        writer.option("-testRegion", testRegion)
        writer.option("-parallel-testing-enabled", yesOrNo: parallelTestingEnabled)
        writer.option("-parallel-testing-worker-count", parallelTestingWorkerCount)
        writer.option("-maximum-parallel-testing-workers", maximumParallelTestingWorkers)
        writer.option("-maximum-concurrent-test-device-destinations", maximumConcurrentTestDeviceDestinations)
        writer.option("-maximum-concurrent-test-simulator-destinations", maximumConcurrentTestSimulatorDestinations)
        writer.flag("-disable-concurrent-destination-testing", disableConcurrentDestinationTesting)
        writer.flag("-parallelize-tests-among-destinations", parallelizeTestsAmongDestinations)
        writer.option("-test-timeouts-enabled", yesOrNo: testTimeoutsEnabled)
        writer.option("-default-test-execution-time-allowance", seconds: defaultTestExecutionTimeAllowance)
        writer.option("-maximum-test-execution-time-allowance", seconds: maximumTestExecutionTimeAllowance)
        writer.option("-test-iterations", testIterations)
        testRepetition?.render(into: &writer)
        writer.option("-test-repetition-relaunch-enabled", yesOrNo: testRepetitionRelaunchEnabled)
        writer.option("-collect-test-diagnostics", collectTestDiagnostics)
        writer.option("-enablePerformanceTestsDiagnostics", yesOrNo: performanceTestsDiagnosticsEnabled)
        writer.option("-enableCodeCoverage", yesOrNo: codeCoverageEnabled)
        testEnumeration?.render(into: &writer)
    }
}

/// How xcodebuild repeats tests. The two modes can't be combined.
public enum TestRepetitionMode: Sendable, Hashable {
    /// Repeat failing tests until they pass, at most ``TestingOptions/testIterations``
    /// times or 3 (`-retry-tests-on-failure`).
    case retryOnFailure

    /// Repeat tests until they fail, at most ``TestingOptions/testIterations``
    /// times or 100 (`-run-tests-until-failure`).
    case untilFailure

    func render(into writer: inout ArgumentWriter) {
        switch self {
        case .retryOnFailure:
            writer.append("-retry-tests-on-failure")
        case .untilFailure:
            writer.append("-run-tests-until-failure")
        }
    }
}

/// When testing collects diagnostics such as a sysdiagnose.
public struct TestDiagnosticsCollection: RawRepresentable, Sendable, Hashable {
    /// The value as xcodebuild spells it.
    public var rawValue: String

    /// Creates a value from its xcodebuild spelling.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Collect diagnostics when a test fails.
    public static var onFailure: TestDiagnosticsCollection {
        TestDiagnosticsCollection(rawValue: "on-failure")
    }

    /// Never collect diagnostics.
    public static var never: TestDiagnosticsCollection {
        TestDiagnosticsCollection(rawValue: "never")
    }
}

/// How to list tests instead of running them (`-enumerate-tests`).
public struct TestEnumeration: Sendable, Hashable {
    /// How the list is organized (`-test-enumeration-style`).
    public var style: Style?

    /// The format of the list (`-test-enumeration-format`).
    public var format: Format?

    /// The file to write the list to, or `nil` for standard output
    /// (`-test-enumeration-output-path`).
    public var outputPath: FilePath?

    /// Creates an enumeration.
    public init(style: Style? = nil, format: Format? = nil, outputPath: FilePath? = nil) {
        self.style = style
        self.format = format
        self.outputPath = outputPath
    }

    func render(into writer: inout ArgumentWriter) {
        writer.append("-enumerate-tests")
        writer.option("-test-enumeration-style", style)
        writer.option("-test-enumeration-format", format)
        writer.option("-test-enumeration-output-path", outputPath)
    }

    /// How a test list is organized.
    public struct Style: RawRepresentable, Sendable, Hashable {
        /// The value as xcodebuild spells it.
        public var rawValue: String

        /// Creates a style from its xcodebuild spelling.
        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        /// Grouped by test plan, target, and class. The default.
        public static var hierarchical: Style {
            Style(rawValue: "hierarchical")
        }

        /// A flat list of identifiers that ``TestingOptions/onlyTesting`` and
        /// ``TestingOptions/skipTesting`` accept.
        public static var flat: Style {
            Style(rawValue: "flat")
        }
    }

    /// The format of a test list.
    public struct Format: RawRepresentable, Sendable, Hashable {
        /// The value as xcodebuild spells it.
        public var rawValue: String

        /// Creates a format from its xcodebuild spelling.
        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        /// Human-readable text. The default.
        public static var text: Format {
            Format(rawValue: "text")
        }

        /// JSON.
        public static var json: Format {
            Format(rawValue: "json")
        }
    }
}
