import Subprocess

/// The log of a running action command, one line at a time.
///
/// ``XcodeBuildTool/run(_:body:)`` passes the log to its closure. The log
/// merges standard output and standard error in the order xcodebuild wrote
/// them, and splits it at line breaks, which include the carriage returns
/// that download progress uses.
///
/// The log can be iterated once; a second iterator continues where the
/// first stopped. It is valid only while the closure runs.
public struct XcodeBuildOutput: AsyncSequence {
    public typealias Element = Line
    public typealias Failure = XcodeBuildError

    let reader: LineReader

    init(reader: LineReader) {
        self.reader = reader
    }

    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(reader: reader)
    }

    /// An iterator over the lines of the log.
    public struct AsyncIterator: AsyncIteratorProtocol {
        let reader: LineReader

        public mutating func next() async throws(XcodeBuildError) -> Line? {
            try await reader.next().map(Line.init(text:))
        }

        public mutating func next(isolation actor: isolated (any Actor)?) async throws(XcodeBuildError) -> Line? {
            try await reader.next().map(Line.init(text:))
        }
    }

    /// A line of the log.
    public struct Line: Sendable, Hashable, CustomStringConvertible {
        /// The text of the line, without its line break.
        public var text: String

        /// Creates a line.
        public init(text: String) {
            self.text = text
        }

        public var description: String {
            text
        }
    }
}

@available(*, unavailable)
extension XcodeBuildOutput: Sendable {}

@available(*, unavailable)
extension XcodeBuildOutput.AsyncIterator: Sendable {}

/// Reads the lines of a log once, for both the caller's closure and the
/// drain that follows it, and keeps the last lines.
final class LineReader {
    /// The iterator, or `nil` once the log has ended or failed.
    ///
    /// `next()` moves it out while it reads, so that no second copy shares
    /// its buffers and the reads don't copy them.
    private var iterator: SubprocessOutputSequence.StringSequence<UTF8>.AsyncIterator?
    private(set) var tail = OutputTail()
    private let commandLine: [String]

    init(lines: SubprocessOutputSequence.StringSequence<UTF8>, commandLine: [String]) {
        self.iterator = lines.makeAsyncIterator()
        self.commandLine = commandLine
    }

    func next() async throws(XcodeBuildError) -> String? {
        guard var iterator = self.iterator.take() else {
            return nil
        }
        do {
            guard let line = try await iterator.next(isolation: #isolation) else {
                return nil
            }
            self.iterator = iterator
            tail.append(line)
            return line
        } catch {
            if error is CancellationError || Task.isCancelled {
                throw XcodeBuildError(code: .cancelled, commandLine: commandLine, outputTail: tail.lines)
            }
            throw XcodeBuildError(
                code: .executionFailed,
                commandLine: commandLine,
                outputTail: tail.lines,
                reason: "reading the log failed",
                underlyingError: error
            )
        }
    }

    /// Reads the rest of the log.
    func drain() async throws(XcodeBuildError) {
        while try await next() != nil {}
    }
}
