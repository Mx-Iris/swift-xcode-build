/// An error from running xcodebuild.
///
/// Check ``code`` first. When xcodebuild ran, ``commandLine``,
/// ``terminationStatus``, and ``outputTail`` describe what happened; the
/// last lines of output usually contain xcodebuild's own `error:` message.
public struct XcodeBuildError: Error, Sendable {
    /// The kind of failure.
    public var code: Code

    /// The command line that ran or was about to run, starting with the path of the xcodebuild executable.
    public var commandLine: [String]

    /// How xcodebuild ended, when it was launched and ended.
    public var terminationStatus: XcodeBuildTerminationStatus?

    /// The last lines xcodebuild wrote: standard error for a query, the
    /// combined log for an action.
    public var outputTail: [String]

    /// A description of the failure beyond its code, when there is one.
    public var reason: String?

    /// The error that caused this one, such as the error your closure threw
    /// for ``Code/bodyFailed`` or the decoding error for ``Code/unexpectedOutput``.
    public var underlyingError: (any Error)?

    /// Creates an error.
    public init(
        code: Code,
        commandLine: [String],
        terminationStatus: XcodeBuildTerminationStatus? = nil,
        outputTail: [String] = [],
        reason: String? = nil,
        underlyingError: (any Error)? = nil
    ) {
        self.code = code
        self.commandLine = commandLine
        self.terminationStatus = terminationStatus
        self.outputTail = outputTail
        self.reason = reason
        self.underlyingError = underlyingError
    }
}

extension XcodeBuildError {
    /// The kind of an ``XcodeBuildError``.
    ///
    /// New kinds may be added; compare against the static members instead of
    /// switching exhaustively.
    public struct Code: Hashable, Sendable {
        private enum Storage: Hashable, Sendable {
            case launchFailed
            case executionFailed
            case commandFailed
            case cancelled
            case outputLimitExceeded
            case unexpectedOutput
            case bodyFailed
            case temporaryFileFailed
        }

        private var storage: Storage

        private init(_ storage: Storage) {
            self.storage = storage
        }

        /// xcodebuild could not be started: the executable is missing, the
        /// working directory does not exist, or the environment is invalid.
        public static var launchFailed: Code {
            Code(.launchFailed)
        }

        /// xcodebuild started, but reading its output or waiting for it failed.
        public static var executionFailed: Code {
            Code(.executionFailed)
        }

        /// xcodebuild exited with a nonzero status or was killed by a signal.
        public static var commandFailed: Code {
            Code(.commandFailed)
        }

        /// The task running xcodebuild was cancelled, and xcodebuild was
        /// stopped before it finished.
        public static var cancelled: Code {
            Code(.cancelled)
        }

        /// A query printed more than ``XcodeBuildTool/standardOutputLimit`` bytes.
        public static var outputLimitExceeded: Code {
            Code(.outputLimitExceeded)
        }

        /// xcodebuild succeeded, but its output was not in the expected format.
        public static var unexpectedOutput: Code {
            Code(.unexpectedOutput)
        }

        /// The closure you passed to ``XcodeBuildTool/run(_:body:)`` threw
        /// ``XcodeBuildError/underlyingError``. xcodebuild was stopped.
        public static var bodyFailed: Code {
            Code(.bodyFailed)
        }

        /// A file the command needs while xcodebuild runs, such as the
        /// property list for inline ``ExportOptions``, could not be written.
        public static var temporaryFileFailed: Code {
            Code(.temporaryFileFailed)
        }
    }
}

extension XcodeBuildError.Code: CustomStringConvertible {
    public var description: String {
        switch storage {
        case .launchFailed:
            "launchFailed"
        case .executionFailed:
            "executionFailed"
        case .commandFailed:
            "commandFailed"
        case .cancelled:
            "cancelled"
        case .outputLimitExceeded:
            "outputLimitExceeded"
        case .unexpectedOutput:
            "unexpectedOutput"
        case .bodyFailed:
            "bodyFailed"
        case .temporaryFileFailed:
            "temporaryFileFailed"
        }
    }
}

extension XcodeBuildError: CustomStringConvertible {
    public var description: String {
        var summary: String
        switch code {
        case .launchFailed:
            summary = "xcodebuild could not be launched"
        case .executionFailed:
            summary = "xcodebuild could not be run to completion"
        case .commandFailed:
            if let terminationStatus {
                summary = "xcodebuild failed with \(terminationStatus)"
            } else {
                summary = "xcodebuild failed"
            }
        case .cancelled:
            summary = "xcodebuild was cancelled"
        case .outputLimitExceeded:
            summary = "xcodebuild printed more output than the limit allows"
        case .unexpectedOutput:
            summary = "xcodebuild printed output in an unexpected format"
        case .bodyFailed:
            summary = "reading the xcodebuild log failed"
        case .temporaryFileFailed:
            summary = "a temporary file for xcodebuild could not be written"
        default:
            summary = "xcodebuild failed: \(code)"
        }
        if let reason {
            summary += ": \(reason)"
        }
        if let underlyingError {
            summary += " (\(underlyingError))"
        }
        if !commandLine.isEmpty {
            summary += "\n" + commandLine.map(XcodeBuildError.shellQuoted).joined(separator: " ")
        }
        if !outputTail.isEmpty {
            summary += "\n" + outputTail.joined(separator: "\n")
        }
        return summary
    }

    /// Quotes an argument the way a shell would need it, for display.
    static func shellQuoted(_ argument: String) -> String {
        let plainCharacters = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_./=:,@%+")
        if !argument.isEmpty, argument.allSatisfy(plainCharacters.contains) {
            return argument
        }
        return "'" + argument.replacing("'", with: "'\\''") + "'"
    }
}
