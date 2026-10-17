import Darwin
import Foundation
import System
import Testing
import XcodeBuild

@Suite(.timeLimit(.minutes(1)))
struct `Running xcodebuild` {
    @Test func `a query collects standard output and standard error separately`() async throws {
        let fake = try FakeXcodeBuild(#"printf '{"a":1}'; echo "warning: something" >&2"#)
        defer { fake.remove() }

        let completion = try await fake.tool.run(RecordingQuery(arguments: []))

        #expect(completion.standardOutputText == #"{"a":1}"#)
        #expect(completion.standardErrorText == "warning: something\n")
        #expect(completion.outputTail == ["warning: something"])
        #expect(completion.terminationStatus == .exited(0))
        #expect(completion.commandLine == [fake.executablePath.string])
    }

    @Test func `arguments reach xcodebuild unchanged`() async throws {
        let fake = try FakeXcodeBuild(#"for argument in "$@"; do printf '%s\n' "$argument"; done"#)
        defer { fake.remove() }
        let arguments = ["-destination", "platform=iOS Simulator,name=iPhone 17 Pro", "OTHER_SWIFT_FLAGS=$(inherited) -DCI", "it's", ""]

        let completion = try await fake.tool.run(RecordingQuery(arguments: arguments))

        #expect(completion.standardOutputText == arguments.map { $0 + "\n" }.joined())
        #expect(completion.commandLine == [fake.executablePath.string] + arguments)
    }

    @Test func `xcodebuild gets unbuffered output, the developer directory, and added variables`() async throws {
        let fake = try FakeXcodeBuild(#"printf '%s|%s|%s' "$NSUnbufferedIO" "$DEVELOPER_DIR" "$CUSTOM_VARIABLE""#)
        defer { fake.remove() }
        var tool = fake.tool
        tool.developerDirectory = "/Applications/Xcode-26.6.0.app"
        tool.environment = ["CUSTOM_VARIABLE": "value"]

        let completion = try await tool.run(RecordingQuery(arguments: []))

        #expect(completion.standardOutputText == "YES|/Applications/Xcode-26.6.0.app|value")
    }

    @Test func `the developer directory wins over the same variable in the environment`() async throws {
        let fake = try FakeXcodeBuild(#"printf '%s' "$DEVELOPER_DIR""#)
        defer { fake.remove() }
        var tool = fake.tool
        tool.environment = ["DEVELOPER_DIR": "/Applications/Other.app"]
        tool.developerDirectory = "/Applications/Xcode.app"

        let completion = try await tool.run(RecordingQuery(arguments: []))

        #expect(completion.standardOutputText == "/Applications/Xcode.app")
    }

    @Test func `xcodebuild runs in the working directory`() async throws {
        let fake = try FakeXcodeBuild("pwd -P")
        defer { fake.remove() }
        var tool = fake.tool
        tool.workingDirectory = Fixtures.minimalPackage

        let completion = try await tool.run(RecordingQuery(arguments: []))

        #expect(completion.standardOutputText == Fixtures.minimalPackage.string + "\n")
    }

    @Test func `an action's log merges standard output and standard error in the order they were written`() async throws {
        let fake = try FakeXcodeBuild("echo one; echo two >&2; echo three")
        defer { fake.remove() }
        var lines: [String] = []

        _ = try await fake.tool.run(RecordingAction(arguments: [])) { output in
            for try await line in output {
                lines.append(line.text)
            }
        }

        #expect(lines == ["one", "two", "three"])
    }

    @Test func `progress written with carriage returns becomes separate lines`() async throws {
        let fake = try FakeXcodeBuild(#"printf 'progress 1%%\rprogress 2%%\rdone\n'"#)
        defer { fake.remove() }
        var lines: [String] = []

        _ = try await fake.tool.run(RecordingAction(arguments: [])) { output in
            for try await line in output {
                lines.append(line.text)
            }
        }

        #expect(lines == ["progress 1%", "progress 2%", "done"])
    }

    @Test func `returning from the closure early still lets xcodebuild write its whole log`() async throws {
        // Far more than a pipe holds, so xcodebuild would block if nobody read the rest.
        let fake = try FakeXcodeBuild(#"i=0; while [ $i -lt 20000 ]; do echo "line $i"; i=$((i+1)); done; echo finished"#)
        defer { fake.remove() }
        var firstLine: String?

        let completion = try await fake.tool.run(RecordingAction(arguments: [])) { output in
            for try await line in output {
                firstLine = line.text
                break
            }
        }

        #expect(firstLine == "line 0")
        #expect(completion.terminationStatus == .exited(0))
        #expect(completion.outputTail.last == "finished")
        #expect(completion.outputTail.count == 50)
    }

    @Test func `running an action without a closure discards the log but keeps its end`() async throws {
        let fake = try FakeXcodeBuild("echo first; echo last")
        defer { fake.remove() }

        let completion = try await fake.tool.run(RecordingAction(arguments: []))

        #expect(completion.outputTail == ["first", "last"])
        #expect(completion.standardOutput.isEmpty)
    }

    @Test func `a failing action throws with its exit status and the end of its log`() async throws {
        let fake = try FakeXcodeBuild(#"echo "Compiling"; echo "error: something broke" >&2; echo "** BUILD FAILED **"; exit 65"#)
        defer { fake.remove() }

        let error = await #expect(throws: XcodeBuildError.self) {
            try await fake.tool.run(BuildCommand(.build))
        }

        #expect(error?.code == .commandFailed)
        #expect(error?.terminationStatus == .exited(65))
        #expect(error?.outputTail == ["Compiling", "error: something broke", "** BUILD FAILED **"])
        #expect(error?.commandLine == [fake.executablePath.string, "build"])
    }

    @Test func `a successful action returns its command line`() async throws {
        let fake = try FakeXcodeBuild("echo built")
        defer { fake.remove() }

        let summary = try await fake.tool.run(BuildCommand(.build) { Scheme("App") })

        #expect(summary.commandLine == [fake.executablePath.string, "-scheme", "App", "build"])
    }

    @Test func `an error thrown by the closure stops xcodebuild and is wrapped`() async throws {
        let fake = try FakeXcodeBuild(#"trap 'exit 130' INT; echo ready; while true; do sleep 0.05; done"#)
        defer { fake.remove() }
        let start = ContinuousClock.now

        let error = await #expect(throws: XcodeBuildError.self) {
            try await fake.tool.run(RecordingAction(arguments: [])) { output in
                for try await line in output where line.text == "ready" {
                    throw ClosureFailure(message: "stop")
                }
            }
        }

        #expect(error?.code == .bodyFailed)
        #expect(error?.underlyingError as? ClosureFailure == ClosureFailure(message: "stop"))
        #expect(error?.outputTail == ["ready"])
        #expect(ContinuousClock.now - start < .seconds(10))
    }

    @Test func `cancellation sends SIGINT, then SIGTERM, then SIGKILL`() async throws {
        // The script records each signal and keeps running, so every step of the sequence is needed.
        let fake = try FakeXcodeBuild(
            #"trap 'echo INT >> "$1"' INT; trap 'echo TERM >> "$1"' TERM; echo ready; while true; do sleep 0.05; done"#
        )
        defer { fake.remove() }
        let signalLog = fake.path("signals.log")

        let error = try await cancelAfterReady(fake.tool, arguments: [signalLog])

        #expect(error?.code == .cancelled)
        #expect(error?.terminationStatus == .signaled(SIGKILL))
        #expect(try String(contentsOfFile: signalLog, encoding: .utf8) == "INT\nTERM\n")
    }

    @Test func `xcodebuild that stops on SIGINT receives no other signal`() async throws {
        let fake = try FakeXcodeBuild(
            #"trap 'echo INT >> "$1"; exit 130' INT; trap 'echo TERM >> "$1"' TERM; echo ready; while true; do sleep 0.05; done"#
        )
        defer { fake.remove() }
        let signalLog = fake.path("signals.log")

        let error = try await cancelAfterReady(fake.tool, arguments: [signalLog])

        #expect(error?.code == .cancelled)
        #expect(error?.terminationStatus == .exited(130))
        #expect(try String(contentsOfFile: signalLog, encoding: .utf8) == "INT\n")
    }

    /// Runs an action, cancels its task once the action prints `ready`, and returns the error it throws.
    private func cancelAfterReady(_ tool: XcodeBuildTool, arguments: [String]) async throws -> XcodeBuildError? {
        let (readiness, readinessContinuation) = AsyncStream.makeStream(of: Void.self)
        let task = Task {
            try await tool.run(RecordingAction(arguments: arguments)) { output in
                for try await line in output where line.text == "ready" {
                    readinessContinuation.yield()
                }
            }
        }
        for await _ in readiness {
            break
        }
        task.cancel()
        let result = await task.result
        guard case .failure(let error) = result else {
            Issue.record("The cancelled action returned \(result)")
            return nil
        }
        return error as? XcodeBuildError
    }

    @Test func `a query that prints more than the limit is stopped`() async throws {
        let fake = try FakeXcodeBuild("head -c 4096 /dev/zero | tr '\\000' 'a'")
        defer { fake.remove() }
        var tool = fake.tool
        tool.standardOutputLimit = 16

        let error = await #expect(throws: XcodeBuildError.self) {
            try await tool.run(RecordingQuery(arguments: []))
        }

        #expect(error?.code == .outputLimitExceeded)
    }

    @Test func `a missing executable can't be launched`() async {
        let tool = XcodeBuildTool(executablePath: "/nonexistent/xcodebuild")

        let error = await #expect(throws: XcodeBuildError.self) {
            try await tool.run(VersionCommand())
        }

        #expect(error?.code == .launchFailed)
        #expect(error?.commandLine == ["/nonexistent/xcodebuild", "-version"])
    }

    @Test func `a missing working directory can't be launched`() async throws {
        let fake = try FakeXcodeBuild("echo unreachable")
        defer { fake.remove() }
        var tool = fake.tool
        tool.workingDirectory = "/nonexistent/directory"

        let error = await #expect(throws: XcodeBuildError.self) {
            try await tool.run(RecordingQuery(arguments: []))
        }

        #expect(error?.code == .launchFailed)
    }

    @Test func `output a command can't decode is reported with the command line`() async throws {
        let fake = try FakeXcodeBuild("echo nonsense")
        defer { fake.remove() }

        let error = await #expect(throws: XcodeBuildError.self) {
            try await fake.tool.run(ListCommand())
        }

        #expect(error?.code == .unexpectedOutput)
        #expect(error?.commandLine == [fake.executablePath.string, "-list", "-json"])
    }

    @Test func `inline export options are written to a property list that is removed afterwards`() async throws {
        let fake = try FakeXcodeBuild(
            #"while [ $# -gt 0 ]; do if [ "$1" = "-exportOptionsPlist" ]; then plist="$2"; fi; shift; done; cat "$plist"; echo; echo "$plist""#
        )
        defer { fake.remove() }
        var options = ExportOptions(method: .appStoreConnect)
        options.teamIdentifier = "ABCDE12345"
        options.provisioningProfiles = ["com.example.app": "App Store Profile"]
        var lines: [String] = []

        _ = try await fake.tool.run(ExportArchiveCommand(archivePath: "App.xcarchive", exportOptions: .options(options))) { output in
            for try await line in output {
                lines.append(line.text)
            }
        }

        let plistPath = try #require(lines.last)
        #expect(plistPath.hasSuffix("/ExportOptions.plist"))
        #expect(!FileManager.default.fileExists(atPath: plistPath))
        let plist = lines.dropLast().joined(separator: "\n")
        // `format:` is an optional pointer; passing nil is safe.
        let decoded = try unsafe PropertyListSerialization.propertyList(from: Data(plist.utf8), format: nil) as? [String: Any]
        #expect(decoded?["method"] as? String == "app-store-connect")
        #expect(decoded?["teamID"] as? String == "ABCDE12345")
        #expect(decoded?["provisioningProfiles"] as? [String: String] == ["com.example.app": "App Store Profile"])
    }

    @MainActor
    @Test func `the closure runs on the caller's actor`() async throws {
        let fake = try FakeXcodeBuild("echo one; echo two")
        defer { fake.remove() }
        var linesOnMainThread: [Bool] = []

        _ = try await fake.tool.run(RecordingAction(arguments: [])) { output in
            for try await _ in output {
                linesOnMainThread.append(pthread_main_np() != 0)
            }
        }

        #expect(linesOnMainThread == [true, true])
    }
}

@Suite struct `Error descriptions` {
    @Test func `the description shows the failure, the command line quoted for a shell, and the last lines`() {
        let error = XcodeBuildError(
            code: .commandFailed,
            commandLine: ["/usr/bin/xcodebuild", "-destination", "platform=iOS Simulator,name=iPhone 17", "it's"],
            terminationStatus: .exited(65),
            outputTail: ["error: something broke", "** BUILD FAILED **"]
        )
        #expect(error.description == """
            xcodebuild failed with exit status 65
            /usr/bin/xcodebuild -destination 'platform=iOS Simulator,name=iPhone 17' 'it'\\''s'
            error: something broke
            ** BUILD FAILED **
            """)
    }

    @Test func `a code describes itself by name`() {
        #expect(XcodeBuildError.Code.outputLimitExceeded.description == "outputLimitExceeded")
        #expect("\(XcodeBuildError.Code.cancelled)" == "cancelled")
    }
}
