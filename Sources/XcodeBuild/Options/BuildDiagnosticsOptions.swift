public import System

/// Sanitizer settings that override the scheme's launch and test actions.
///
/// Options set to `nil` are left out, so the scheme's settings apply.
public struct SanitizerOptions: Sendable, Hashable {
    /// Whether the address sanitizer is on (`-enableAddressSanitizer`).
    public var addressSanitizerEnabled: Bool?

    /// Whether the thread sanitizer is on (`-enableThreadSanitizer`).
    public var threadSanitizerEnabled: Bool?

    /// Whether the undefined behavior sanitizer is on (`-enableUndefinedBehaviorSanitizer`).
    public var undefinedBehaviorSanitizerEnabled: Bool?

    /// Creates sanitizer options that leave every sanitizer to the scheme.
    public init(
        addressSanitizerEnabled: Bool? = nil,
        threadSanitizerEnabled: Bool? = nil,
        undefinedBehaviorSanitizerEnabled: Bool? = nil
    ) {
        self.addressSanitizerEnabled = addressSanitizerEnabled
        self.threadSanitizerEnabled = threadSanitizerEnabled
        self.undefinedBehaviorSanitizerEnabled = undefinedBehaviorSanitizerEnabled
    }

    func render(into writer: inout ArgumentWriter) {
        writer.option("-enableAddressSanitizer", yesOrNo: addressSanitizerEnabled)
        writer.option("-enableThreadSanitizer", yesOrNo: threadSanitizerEnabled)
        writer.option("-enableUndefinedBehaviorSanitizer", yesOrNo: undefinedBehaviorSanitizerEnabled)
    }
}

/// Code size profiling, which keeps SIL, LLVM IR, and optimization records
/// for each compiled file. Xcode 27 and later.
public struct CodeSizeProfileOptions: Sendable, Hashable {
    /// Whether to generate code size profiling files (`-enableCodesizeProfile`).
    public var enabled: Bool?

    /// Where to write the files (`-codesizeProfileOutputDir`).
    public var outputDirectory: FilePath?

    /// Creates code size profiling options.
    public init(enabled: Bool? = nil, outputDirectory: FilePath? = nil) {
        self.enabled = enabled
        self.outputDirectory = outputDirectory
    }

    func render(into writer: inout ArgumentWriter) {
        writer.option("-enableCodesizeProfile", yesOrNo: enabled)
        writer.option("-codesizeProfileOutputDir", outputDirectory)
    }
}
