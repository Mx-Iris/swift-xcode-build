import Foundation

extension XcodeBuildCompletion {
    /// Decodes standard output as JSON, skipping any text before the JSON.
    ///
    /// Some versions of xcodebuild print a line such as `SDK macOS 26.5:`
    /// before the JSON of `-version -sdk -json`.
    func decodeJSON<Value: Decodable>(_ type: Value.Type) throws(XcodeBuildError) -> Value {
        let openingBrackets: Set<UInt8> = [UInt8(ascii: "["), UInt8(ascii: "{")]
        guard let start = standardOutput.firstIndex(where: openingBrackets.contains) else {
            throw unexpectedOutput("expected JSON, found \(standardOutput.isEmpty ? "no output" : "text")")
        }
        do {
            return try JSONDecoder().decode(Value.self, from: Data(standardOutput[start...]))
        } catch {
            throw unexpectedOutput("the JSON could not be decoded", underlyingError: error)
        }
    }

    /// Standard output without surrounding whitespace and line breaks.
    var trimmedStandardOutputText: String {
        standardOutputText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
