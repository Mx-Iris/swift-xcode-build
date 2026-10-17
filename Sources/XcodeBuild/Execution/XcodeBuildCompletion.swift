/// A finished xcodebuild run, as ``XcodeBuildCommand/output(from:)`` receives it.
public struct XcodeBuildCompletion: Sendable, Hashable {
    /// The command line that ran, starting with the path of the xcodebuild executable.
    public var commandLine: [String]

    /// How xcodebuild ended.
    public var terminationStatus: XcodeBuildTerminationStatus

    /// Everything xcodebuild wrote to standard output.
    ///
    /// Collected for ``XcodeBuildQueryCommand`` only; empty for
    /// ``XcodeBuildActionCommand``, whose output is a log.
    public var standardOutput: [UInt8]

    /// What xcodebuild wrote to standard error, one line after another.
    ///
    /// Collected for ``XcodeBuildQueryCommand`` only, up to
    /// ``XcodeBuildTool/standardOutputLimit``; empty for
    /// ``XcodeBuildActionCommand``. Some queries print their result here:
    /// `-help` and `-usage` write to standard error.
    public var standardError: [UInt8]

    /// The last lines xcodebuild wrote.
    ///
    /// For a query these are the last lines of standard error. For an action
    /// they are the last lines of the log, which merges standard output and
    /// standard error.
    public var outputTail: [String]

    /// How long xcodebuild ran.
    public var duration: Duration

    /// Creates a completion.
    ///
    /// ``XcodeBuildTool`` creates completions; this initializer exists so that
    /// you can test your own commands' ``XcodeBuildCommand/output(from:)``.
    public init(
        commandLine: [String],
        terminationStatus: XcodeBuildTerminationStatus,
        standardOutput: [UInt8] = [],
        standardError: [UInt8] = [],
        outputTail: [String] = [],
        duration: Duration = .zero
    ) {
        self.commandLine = commandLine
        self.terminationStatus = terminationStatus
        self.standardOutput = standardOutput
        self.standardError = standardError
        self.outputTail = outputTail
        self.duration = duration
    }

    /// Standard output decoded as UTF-8, with invalid bytes replaced.
    public var standardOutputText: String {
        String(decoding: standardOutput, as: UTF8.self)
    }

    /// Standard error decoded as UTF-8, with invalid bytes replaced.
    public var standardErrorText: String {
        String(decoding: standardError, as: UTF8.self)
    }

    /// Throws ``XcodeBuildError/Code/commandFailed`` unless xcodebuild exited with status 0.
    public func requireSuccess() throws(XcodeBuildError) {
        guard terminationStatus.isSuccess else {
            throw XcodeBuildError(
                code: .commandFailed,
                commandLine: commandLine,
                terminationStatus: terminationStatus,
                outputTail: outputTail
            )
        }
    }

    /// Creates the error for output that a command could not interpret.
    public func unexpectedOutput(_ reason: String, underlyingError: (any Error)? = nil) -> XcodeBuildError {
        XcodeBuildError(
            code: .unexpectedOutput,
            commandLine: commandLine,
            terminationStatus: terminationStatus,
            outputTail: outputTail,
            reason: reason,
            underlyingError: underlyingError
        )
    }
}

/// How an xcodebuild process ended.
public enum XcodeBuildTerminationStatus: Sendable, Hashable {
    /// The process exited with this status. xcodebuild uses the codes of
    /// `sysexits(3)`: 0 on success, 64 (`EX_USAGE`) for malformed options, 65
    /// (`EX_DATAERR`) and 70 (`EX_SOFTWARE`) when the work it was asked to do
    /// failed, 66 (`EX_NOINPUT`) when an input file is missing.
    case exited(Int32)

    /// A signal killed the process.
    case signaled(Int32)

    /// Whether the process exited with status 0.
    public var isSuccess: Bool {
        self == .exited(0)
    }
}

extension XcodeBuildTerminationStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .exited(let status):
            "exit status \(status)"
        case .signaled(let signal):
            "signal \(signal)"
        }
    }
}

/// The result of an action command: what ran and how long it took.
public struct XcodeBuildSummary: Sendable, Hashable {
    /// The command line that ran, starting with the path of the xcodebuild executable.
    public var commandLine: [String]

    /// How long xcodebuild ran.
    public var duration: Duration

    /// Creates a summary.
    public init(commandLine: [String], duration: Duration) {
        self.commandLine = commandLine
        self.duration = duration
    }
}
