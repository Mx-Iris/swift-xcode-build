import Foundation
import System
import Testing
import XcodeBuild

/// Checks the library against what the installed xcodebuild says it accepts,
/// so that an option a new Xcode adds turns these tests red.
@Suite(.enabled(if: RealXcodeBuild.isEnabled), .timeLimit(.minutes(2)))
struct `Coverage of xcodebuild -help` {
    /// Every argument that some command in the rendering tests produces.
    static let renderedArguments: Set<String> = {
        let cases = `Argument rendering`.buildCases + `Argument rendering`.queryCases + `Argument rendering`.actionCases
        return Set(cases.flatMap(\.arguments))
    }()

    @Test func `every option in the usage and the option list is rendered by some command`() async throws {
        let help = try await RealXcodeBuild.tool().run(.help)
        let options = HelpText.options(in: help)

        #expect(options.count > 100)
        let missing = options.subtracting(Self.renderedArguments).sorted()
        #expect(missing.isEmpty, "Options that no command renders: \(missing.joined(separator: ", "))")
    }

    @Test func `every option of -create-xcframework is rendered`() async throws {
        let completion = try await RealXcodeBuild.tool().run(RecordingQuery(arguments: ["-create-xcframework", "-help"]))
        let text = completion.standardOutputText + completion.standardErrorText
        let options = HelpText.createXCFrameworkOptions(in: text)

        #expect(options.contains("-debug-symbols"))
        let missing = options.subtracting(Self.renderedArguments).sorted()
        #expect(missing.isEmpty, "Options that no command renders: \(missing.joined(separator: ", "))")
    }

    @Test func `every export options key is written by ExportOptions`() async throws {
        let help = try await RealXcodeBuild.tool().run(.help)
        let keys = HelpText.exportOptionKeys(in: help)

        #expect(keys.count >= 18)
        let written = try Set(`Export options`.propertyList(of: `Export options`.everyOption).keys)
        let missing = keys.subtracting(written).sorted()
        #expect(missing.isEmpty, "Export options keys that ExportOptions doesn't write: \(missing.joined(separator: ", "))")
    }
}

/// Reads option names out of xcodebuild's usage text.
enum HelpText {
    private enum Section {
        case usage
        case options
        case exportOptionKeys
    }

    /// The options in the usage lines and in the option list.
    static func options(in help: String) -> Set<String> {
        var options = Set<String>()
        var section = Section.usage
        for line in help.split(separator: "\n") {
            if line.hasPrefix("Options:") {
                section = .options
                continue
            }
            if line.hasPrefix("Available keys for -exportOptionsPlist:") {
                section = .exportOptionKeys
                continue
            }
            switch section {
            case .usage:
                options.formUnion(optionTokens(in: line))
            case .options:
                if let first = line.split(whereSeparator: \.isWhitespace).first, isOption(first) {
                    options.insert(optionName(first))
                }
            case .exportOptionKeys:
                break
            }
        }
        return options
    }

    /// The options listed under `OPTIONS:` by `xcodebuild -create-xcframework -help`.
    static func createXCFrameworkOptions(in help: String) -> Set<String> {
        var options = Set<String>()
        var isInOptions = false
        for line in help.split(separator: "\n") {
            if line.hasPrefix("OPTIONS:") {
                isInOptions = true
                continue
            }
            if isInOptions, let first = line.split(whereSeparator: \.isWhitespace).first, isOption(first) {
                options.insert(optionName(first))
            }
        }
        return options
    }

    /// The keys listed under "Available keys for -exportOptionsPlist:", such as `teamID`.
    static func exportOptionKeys(in help: String) -> Set<String> {
        var keys = Set<String>()
        var isInKeys = false
        for line in help.split(separator: "\n") {
            if line.hasPrefix("Available keys for -exportOptionsPlist:") {
                isInKeys = true
                continue
            }
            guard isInKeys, line.hasPrefix("\t"), !line.hasPrefix("\t\t") else {
                continue
            }
            let parts = line.dropFirst().split(separator: " : ")
            if parts.count == 2 {
                keys.insert(String(parts[0]))
            }
        }
        return keys
    }

    private static func optionTokens(in line: Substring) -> [String] {
        line.split { $0.isWhitespace || $0 == "[" || $0 == "]" || $0 == "|" }
            .filter(isOption)
            .map(optionName)
    }

    private static func isOption(_ token: Substring) -> Bool {
        token.count > 1 && token.first == "-" && token.dropFirst().first?.isLetter == true
    }

    /// `-only-testing:TEST-IDENTIFIER` is the option `-only-testing`.
    private static func optionName(_ token: Substring) -> String {
        String(token.prefix { $0 != ":" && $0 != "." })
    }
}
