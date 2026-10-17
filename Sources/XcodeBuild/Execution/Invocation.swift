import Foundation
import Subprocess
import System

/// One run of xcodebuild: the command line, the process configuration, and
/// any temporary files the command needs.
struct Invocation {
    let commandLine: [String]
    let configuration: Subprocess.Configuration
    private let temporaryDirectory: FilePath?

    init<Command: XcodeBuildCommand>(command: Command, tool: XcodeBuildTool) throws(XcodeBuildError) {
        var arguments = command.arguments
        var temporaryDirectory: FilePath?
        if let requiring = command as? any TemporaryFileRequiring {
            let files = try requiring.temporaryFiles(commandLine: [tool.executablePath.string] + arguments)
            if !files.isEmpty {
                let directory = try Invocation.makeTemporaryDirectory(commandLine: [tool.executablePath.string] + arguments)
                temporaryDirectory = directory
                for file in files {
                    let path = directory.appending(file.name)
                    do {
                        try Data(file.contents).write(to: URL(filePath: path.string))
                    } catch {
                        Invocation.removeDirectory(directory)
                        throw XcodeBuildError(
                            code: .temporaryFileFailed,
                            commandLine: [tool.executablePath.string] + arguments,
                            reason: "could not write \(path)",
                            underlyingError: error
                        )
                    }
                    arguments = arguments.map { argument in
                        argument == file.placeholder ? path.string : argument
                    }
                }
            }
        }
        self.commandLine = [tool.executablePath.string] + arguments
        self.temporaryDirectory = temporaryDirectory

        var overrides: [Environment.Key: String?] = ["NSUnbufferedIO": "YES"]
        for (name, value) in tool.environment {
            guard let key = Environment.Key(rawValue: name) else {
                if let temporaryDirectory {
                    Invocation.removeDirectory(temporaryDirectory)
                }
                throw XcodeBuildError(
                    code: .launchFailed,
                    commandLine: commandLine,
                    reason: "\"\(name)\" is not a valid environment variable name"
                )
            }
            overrides[key] = value
        }
        if let developerDirectory = tool.developerDirectory {
            overrides["DEVELOPER_DIR"] = developerDirectory.string
        }

        var platformOptions = PlatformOptions()
        platformOptions.teardownSequence = [
            .send(signal: .interrupt, allowedDurationToNextStep: tool.cancellationGracePeriods.interrupt),
            .send(signal: .terminate, allowedDurationToNextStep: tool.cancellationGracePeriods.terminate),
        ]

        self.configuration = Subprocess.Configuration(
            executable: .path(tool.executablePath),
            arguments: Arguments(arguments),
            environment: .inherit.updating(overrides),
            workingDirectory: tool.workingDirectory,
            platformOptions: platformOptions
        )
    }

    func removeTemporaryFiles() {
        if let temporaryDirectory {
            Invocation.removeDirectory(temporaryDirectory)
        }
    }

    /// Converts an error thrown while running xcodebuild into an ``XcodeBuildError``.
    func error(for error: any Error) -> XcodeBuildError {
        if let xcodeBuildError = error as? XcodeBuildError {
            return xcodeBuildError
        }
        if error is CancellationError || Task.isCancelled {
            return XcodeBuildError(code: .cancelled, commandLine: commandLine)
        }
        if let subprocessError = error as? SubprocessError {
            switch subprocessError.code {
            case .outputLimitExceeded:
                return XcodeBuildError(code: .outputLimitExceeded, commandLine: commandLine, underlyingError: subprocessError)
            case .spawnFailed, .executableNotFound, .failedToChangeWorkingDirectory:
                return XcodeBuildError(code: .launchFailed, commandLine: commandLine, underlyingError: subprocessError)
            default:
                return XcodeBuildError(code: .executionFailed, commandLine: commandLine, underlyingError: subprocessError)
            }
        }
        return XcodeBuildError(code: .executionFailed, commandLine: commandLine, underlyingError: error)
    }

    /// Throws ``XcodeBuildError/Code/cancelled`` when the task was cancelled
    /// and xcodebuild did not finish successfully.
    ///
    /// A run that completed before the cancellation reached xcodebuild keeps
    /// its result.
    func checkCancellation(_ completion: XcodeBuildCompletion) throws(XcodeBuildError) {
        if Task.isCancelled, !completion.terminationStatus.isSuccess {
            throw XcodeBuildError(
                code: .cancelled,
                commandLine: completion.commandLine,
                terminationStatus: completion.terminationStatus,
                outputTail: completion.outputTail
            )
        }
    }

    private static func makeTemporaryDirectory(commandLine: [String]) throws(XcodeBuildError) -> FilePath {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "swift-xcode-build-\(UUID().uuidString)", directoryHint: .isDirectory)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            throw XcodeBuildError(
                code: .temporaryFileFailed,
                commandLine: commandLine,
                reason: "could not create \(directory.path(percentEncoded: false))",
                underlyingError: error
            )
        }
        return FilePath(directory.path(percentEncoded: false))
    }

    private static func removeDirectory(_ directory: FilePath) {
        try? FileManager.default.removeItem(at: URL(filePath: directory.string, directoryHint: .isDirectory))
    }
}

/// A command that needs files on disk while xcodebuild runs.
///
/// Each file's ``TemporaryFile/placeholder`` appears in the command's
/// ``XcodeBuildCommand/arguments`` and is replaced with the path of the file,
/// which ``XcodeBuildTool`` writes to a new temporary directory before
/// launching xcodebuild and removes afterwards.
protocol TemporaryFileRequiring {
    func temporaryFiles(commandLine: [String]) throws(XcodeBuildError) -> [TemporaryFile]
}

struct TemporaryFile {
    var placeholder: String
    var name: String
    var contents: [UInt8]
}

/// The lines of a stream, collected up to a limit, and its last lines.
struct CollectedLines: Sendable {
    let limit: Int
    private(set) var bytes: [UInt8] = []
    private(set) var tail = OutputTail()

    init(limit: Int) {
        self.limit = limit
    }

    mutating func append(_ line: String) {
        tail.append(line)
        if bytes.count < limit {
            bytes.append(contentsOf: line.utf8)
            bytes.append(UInt8(ascii: "\n"))
        }
    }
}

/// The last lines of a log, kept for errors.
struct OutputTail: Sendable {
    static let lineCapacity = 50
    static let lineLengthLimit = 4096

    private(set) var lines: [String] = []

    mutating func append(_ line: String) {
        if line.utf8.count > OutputTail.lineLengthLimit {
            lines.append(String(line.prefix(OutputTail.lineLengthLimit)) + "…")
        } else {
            lines.append(line)
        }
        if lines.count > OutputTail.lineCapacity {
            lines.removeFirst(lines.count - OutputTail.lineCapacity)
        }
    }
}
