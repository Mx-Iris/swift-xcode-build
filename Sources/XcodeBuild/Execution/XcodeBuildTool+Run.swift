import Subprocess

extension XcodeBuildTool {
    /// Runs a query and returns its result.
    ///
    /// ```swift
    /// let sdks = try await xcodebuild.run(.showSDKs)
    /// let schemes = try await xcodebuild.run(ListCommand(.workspace("App.xcworkspace")))
    /// ```
    ///
    /// Standard output is collected up to ``standardOutputLimit`` and decoded
    /// off the caller's actor. Standard error is collected as well, since a
    /// few queries print their result there, and its last lines go into the
    /// error when the query fails.
    ///
    /// - Throws: ``XcodeBuildError/Code/commandFailed`` when xcodebuild fails,
    ///   ``XcodeBuildError/Code/cancelled`` when the task is cancelled, and the
    ///   other codes of ``XcodeBuildError/Code``.
    public func run<Command: XcodeBuildQueryCommand>(_ command: Command) async throws(XcodeBuildError) -> Command.Output {
        let invocation = try Invocation(command: command, tool: self)
        defer {
            invocation.removeTemporaryFiles()
        }
        let start = ContinuousClock.now
        let limit = standardOutputLimit
        let terminationStatus: TerminationStatus
        let standardOutput: [UInt8]
        let standardError: CollectedLines
        do {
            let result = try await Subprocess.run(
                invocation.configuration,
                input: .none,
                output: .bytes(limit: limit),
                error: .sequence
            ) { execution in
                var collected = CollectedLines(limit: limit)
                for try await line in execution.standardError.strings(bufferingPolicy: .unbounded) {
                    collected.append(line)
                }
                return collected
            }
            terminationStatus = result.terminationStatus
            standardOutput = result.standardOutput
            standardError = result.closureResult
        } catch {
            throw invocation.error(for: error)
        }
        let completion = XcodeBuildCompletion(
            commandLine: invocation.commandLine,
            terminationStatus: XcodeBuildTerminationStatus(terminationStatus),
            standardOutput: standardOutput,
            standardError: standardError.bytes,
            outputTail: standardError.tail.lines,
            duration: ContinuousClock.now - start
        )
        try invocation.checkCancellation(completion)
        return try await makeOutput(of: command, from: completion)
    }

    /// Runs an action and waits for it to finish, discarding its log.
    ///
    /// The last lines of the log are kept for the error when the action fails.
    /// To read the log while xcodebuild writes it, use ``run(_:body:)``.
    ///
    /// - Throws: ``XcodeBuildError/Code/commandFailed`` when xcodebuild fails,
    ///   ``XcodeBuildError/Code/cancelled`` when the task is cancelled, and the
    ///   other codes of ``XcodeBuildError/Code``.
    public func run<Command: XcodeBuildActionCommand>(_ command: Command) async throws(XcodeBuildError) -> Command.Output {
        try await run(command) { output in
            for try await _ in output {}
        }
    }

    /// Runs an action and passes its log to a closure while xcodebuild writes it.
    ///
    /// ```swift
    /// try await xcodebuild.run(archive) { output in
    ///     for try await line in output {
    ///         print(line.text)
    ///     }
    /// }
    /// ```
    ///
    /// The log merges standard output and standard error in the order
    /// xcodebuild wrote them. The tool sets `NSUnbufferedIO=YES` so that
    /// xcodebuild writes each line as soon as it has it.
    ///
    /// The closure runs on the caller's actor, so code on the main actor can
    /// update its state for every line. If the closure returns before the log
    /// ends, the tool reads and discards the rest, so that xcodebuild never
    /// blocks on a full pipe, and returns when xcodebuild exits. If the closure
    /// throws, the tool stops xcodebuild as it would on cancellation and throws
    /// ``XcodeBuildError/Code/bodyFailed`` with the closure's error as
    /// ``XcodeBuildError/underlyingError``. Errors from iterating the log are
    /// rethrown as they are.
    ///
    /// The log is valid only while the closure runs; don't keep it.
    ///
    /// - Throws: ``XcodeBuildError/Code/commandFailed`` when xcodebuild fails,
    ///   ``XcodeBuildError/Code/cancelled`` when the task is cancelled, and the
    ///   other codes of ``XcodeBuildError/Code``.
    public func run<Command: XcodeBuildActionCommand>(
        _ command: Command,
        body: (XcodeBuildOutput) async throws -> Void
    ) async throws(XcodeBuildError) -> Command.Output {
        let invocation = try Invocation(command: command, tool: self)
        defer {
            invocation.removeTemporaryFiles()
        }
        let start = ContinuousClock.now
        let terminationStatus: TerminationStatus
        let outputTail: [String]
        do {
            let result = try await Subprocess.run(
                invocation.configuration,
                input: .none,
                output: .sequence,
                error: .combinedWithOutput
            ) { execution in
                let reader = LineReader(
                    lines: execution.standardOutput.strings(bufferingPolicy: .unbounded),
                    commandLine: invocation.commandLine
                )
                do {
                    try await body(XcodeBuildOutput(reader: reader))
                } catch let error as XcodeBuildError {
                    throw error
                } catch {
                    if error is CancellationError {
                        throw XcodeBuildError(
                            code: .cancelled,
                            commandLine: invocation.commandLine,
                            outputTail: reader.tail.lines
                        )
                    }
                    throw XcodeBuildError(
                        code: .bodyFailed,
                        commandLine: invocation.commandLine,
                        outputTail: reader.tail.lines,
                        underlyingError: error
                    )
                }
                try await reader.drain()
                return reader.tail.lines
            }
            terminationStatus = result.terminationStatus
            outputTail = result.closureResult
        } catch {
            throw invocation.error(for: error)
        }
        let completion = XcodeBuildCompletion(
            commandLine: invocation.commandLine,
            terminationStatus: XcodeBuildTerminationStatus(terminationStatus),
            outputTail: outputTail,
            duration: ContinuousClock.now - start
        )
        try invocation.checkCancellation(completion)
        return try await makeOutput(of: command, from: completion)
    }
}

/// Creates a command's output off the caller's actor, so that decoding a large
/// result does not block it.
@concurrent
private func makeOutput<Command: XcodeBuildCommand>(
    of command: Command,
    from completion: XcodeBuildCompletion
) async throws(XcodeBuildError) -> Command.Output {
    try command.output(from: completion)
}

extension XcodeBuildTerminationStatus {
    init(_ status: TerminationStatus) {
        switch status {
        case .exited(let code):
            self = .exited(code)
        case .signaled(let signal):
            self = .signaled(signal)
        }
    }
}
