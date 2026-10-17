public import System

/// Runs xcodebuild commands.
///
/// ```swift
/// let xcodebuild = XcodeBuildTool()
/// let sdks = try await xcodebuild.run(.showSDKs)
///
/// try await xcodebuild.run(BuildCommand(.test) {
///     Workspace("App.xcworkspace")
///     Scheme("App")
///     Destination(.simulator(.iOS, name: "iPhone 17 Pro"))
/// }) { output in
///     for try await line in output {
///         print(line.text)
///     }
/// }
/// ```
///
/// By default the tool runs `/usr/bin/xcodebuild`, which selects the Xcode
/// that `xcode-select` points to, or the one in the `DEVELOPER_DIR`
/// environment variable. Set ``developerDirectory`` to use a specific Xcode.
///
/// The tool is a value: copy it and change a property to run commands in
/// another directory or with another Xcode.
///
/// ## Cancellation
///
/// When the task running a command is cancelled, the tool stops xcodebuild
/// the way pressing Control-C in a terminal would: it sends `SIGINT`, which
/// lets xcodebuild cancel its build and clean up. If xcodebuild is still
/// running after ``CancellationGracePeriods/interrupt``, the tool sends
/// `SIGTERM`, and after ``CancellationGracePeriods/terminate`` `SIGKILL`.
/// The command then throws ``XcodeBuildError/Code/cancelled``.
public struct XcodeBuildTool: Sendable {
    /// The xcodebuild executable to run.
    public var executablePath: FilePath

    /// The Xcode to use, such as `/Applications/Xcode-26.6.0.app`.
    ///
    /// When set, the tool passes it to xcodebuild in the `DEVELOPER_DIR`
    /// environment variable, which takes precedence over `xcode-select`.
    /// Both the app bundle and its `Contents/Developer` directory work.
    public var developerDirectory: FilePath?

    /// The directory xcodebuild runs in, or `nil` for the current directory.
    ///
    /// Without `-project` or `-workspace`, xcodebuild looks for a project,
    /// workspace, or Swift package in this directory.
    public var workingDirectory: FilePath?

    /// Environment variables to add to the environment xcodebuild inherits.
    ///
    /// xcodebuild reads `XCODE_XCCONFIG_FILE` for an xcconfig file that
    /// overrides every other build setting, and passes variables named
    /// `TEST_RUNNER_<name>` to test runners as `<name>`.
    public var environment: [String: String]

    /// The most bytes a query may print before the tool stops it and throws
    /// ``XcodeBuildError/Code/outputLimitExceeded``. The default is 64 MiB.
    ///
    /// Action commands are not limited: their log is read line by line and
    /// not kept.
    public var standardOutputLimit: Int

    /// How long xcodebuild may take to stop after each signal when its task is cancelled.
    public var cancellationGracePeriods: CancellationGracePeriods

    /// Creates a tool.
    ///
    /// - Parameters:
    ///   - executablePath: The xcodebuild executable to run.
    ///   - developerDirectory: The Xcode to use, or `nil` for the one that
    ///     `xcode-select` or `DEVELOPER_DIR` selects.
    ///   - workingDirectory: The directory xcodebuild runs in, or `nil` for
    ///     the current directory.
    ///   - environment: Environment variables to add for xcodebuild.
    public init(
        executablePath: FilePath = "/usr/bin/xcodebuild",
        developerDirectory: FilePath? = nil,
        workingDirectory: FilePath? = nil,
        environment: [String: String] = [:]
    ) {
        self.executablePath = executablePath
        self.developerDirectory = developerDirectory
        self.workingDirectory = workingDirectory
        self.environment = environment
        self.standardOutputLimit = 64 * 1024 * 1024
        self.cancellationGracePeriods = CancellationGracePeriods()
    }
}

/// How long ``XcodeBuildTool`` waits after each signal it sends to stop a cancelled xcodebuild.
public struct CancellationGracePeriods: Sendable, Hashable {
    /// How long xcodebuild may take to stop after `SIGINT` before it receives
    /// `SIGTERM`. The default is 10 seconds.
    ///
    /// On `SIGINT` xcodebuild cancels the build, waits for the tasks it
    /// started, and prints `** BUILD INTERRUPTED **`.
    public var interrupt: Duration

    /// How long xcodebuild may take to stop after `SIGTERM` before it receives
    /// `SIGKILL`. The default is 5 seconds.
    public var terminate: Duration

    /// Creates grace periods.
    public init(interrupt: Duration = .seconds(10), terminate: Duration = .seconds(5)) {
        self.interrupt = interrupt
        self.terminate = terminate
    }
}
