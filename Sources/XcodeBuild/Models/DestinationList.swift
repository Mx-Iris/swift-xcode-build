import Foundation

/// The destinations `-showdestinations` lists for a scheme.
///
/// Xcode 26 and earlier call the two lists "available" and "ineligible".
public struct DestinationList: Sendable, Hashable {
    /// Destinations the scheme can build or test for.
    public var compatible: [DestinationDescription]

    /// Destinations the scheme can't use right now, with the reason in
    /// ``DestinationDescription/error``.
    public var incompatible: [DestinationDescription]

    /// Creates a list.
    public init(compatible: [DestinationDescription], incompatible: [DestinationDescription]) {
        self.compatible = compatible
        self.incompatible = incompatible
    }
}

/// A destination as `-showdestinations` prints it, such as
/// `{ platform:iOS Simulator, arch:arm64, id:…, OS:27.0, name:iPhone 17 Pro }`.
public struct DestinationDescription: Sendable, Hashable {
    /// The keys and values, in the order xcodebuild printed them.
    public var properties: [Property]

    /// A key and its value.
    public struct Property: Sendable, Hashable {
        /// The key, such as `platform` or `OS`.
        public var key: String

        /// The value.
        public var value: String

        /// Creates a property.
        public init(key: String, value: String) {
            self.key = key
            self.value = value
        }
    }

    /// Creates a description.
    public init(properties: [Property]) {
        self.properties = properties
    }

    /// The value of a key, such as `platform` or `OS`.
    public subscript(key: String) -> String? {
        properties.first { $0.key == key }?.value
    }

    /// The platform, such as `iOS Simulator` (`platform`).
    public var platform: String? {
        self["platform"]
    }

    /// The architecture, such as `arm64` (`arch`).
    public var architecture: String? {
        self["arch"]
    }

    /// The variant, such as `Mac Catalyst` (`variant`).
    public var variant: String? {
        self["variant"]
    }

    /// The identifier of the device or simulator (`id`).
    public var identifier: String? {
        self["id"]
    }

    /// The version of the simulator runtime, such as `27.0` (`OS`).
    public var operatingSystemVersion: String? {
        self["OS"]
    }

    /// The name, such as `iPhone 17 Pro` or `Any iOS Device` (`name`).
    public var name: String? {
        self["name"]
    }

    /// Why the destination can't be used (`error`).
    public var error: String? {
        self["error"]
    }

    /// Whether this stands for any device of a platform, such as "Any iOS Device".
    public var isGeneric: Bool {
        guard let identifier else {
            return true
        }
        return identifier.hasSuffix(":placeholder")
    }

    /// A specifier that selects this destination with `-destination`.
    ///
    /// Generic destinations become `generic/platform=…`; others select the
    /// device or simulator by identifier, with the architecture and variant.
    ///
    /// xcodebuild splits a specifier at every comma and has no way to escape
    /// one, so a destination whose values contain a comma, such as the
    /// variant `Designed for [iPad,iPhone]`, can't be selected: xcodebuild
    /// rejects the specifier with "unreadable input". The value is kept as it
    /// is rather than dropped, which would select a different destination.
    public var specifier: DestinationSpecifier {
        var pairs: [String] = []
        if let platform {
            pairs.append("platform=\(platform)")
        }
        if !isGeneric, let identifier {
            pairs.append("id=\(identifier)")
        }
        if !isGeneric, let architecture {
            pairs.append("arch=\(architecture)")
        }
        if let variant {
            pairs.append("variant=\(variant)")
        }
        let text = pairs.joined(separator: ",")
        return DestinationSpecifier(rawValue: isGeneric ? "generic/" + text : text)
    }
}

enum DestinationListParser {
    private enum Section {
        case compatible
        case incompatible
    }

    /// Parses the text of `-showdestinations`.
    static func parse(_ text: String) -> DestinationList? {
        var compatible: [DestinationDescription] = []
        var incompatible: [DestinationDescription] = []
        var section: Section?
        for rawLine in text.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.hasSuffix(" scheme:") {
                if line.hasPrefix("Destinations compatible with") || line.hasPrefix("Available destinations for") {
                    section = .compatible
                    continue
                }
                if line.hasPrefix("Destinations incompatible with") || line.hasPrefix("Ineligible destinations for") {
                    section = .incompatible
                    continue
                }
            }
            guard line.hasPrefix("{"), line.hasSuffix("}") else {
                continue
            }
            guard let section else {
                return nil
            }
            let description = parseDestination(line)
            switch section {
            case .compatible:
                compatible.append(description)
            case .incompatible:
                incompatible.append(description)
            }
        }
        return DestinationList(compatible: compatible, incompatible: incompatible)
    }

    /// Parses `{ key:value, key:value }`. Values can contain `, ` and `:`,
    /// as in `variant:Designed for [iPad,iPhone]` or an error message, so a
    /// property ends only where `, ` is followed by another key and a colon.
    static func parseDestination(_ line: String) -> DestinationDescription {
        var body = Substring(line)
        body = body.dropFirst()
        body = body.dropLast()
        body = body.drop { $0 == " " }
        while body.last == " " {
            body = body.dropLast()
        }

        var segments: [Substring] = []
        var segmentStart = body.startIndex
        var searchStart = body.startIndex
        while let separator = body[searchStart...].firstRange(of: ", ") {
            if startsWithKey(body[separator.upperBound...]) {
                segments.append(body[segmentStart..<separator.lowerBound])
                segmentStart = separator.upperBound
            }
            searchStart = separator.upperBound
        }
        segments.append(body[segmentStart...])

        let properties = segments.compactMap { segment -> DestinationDescription.Property? in
            guard let colon = segment.firstIndex(of: ":") else {
                return nil
            }
            return DestinationDescription.Property(
                key: String(segment[..<colon]),
                value: String(segment[segment.index(after: colon)...])
            )
        }
        return DestinationDescription(properties: properties)
    }

    private static func startsWithKey(_ text: Substring) -> Bool {
        guard let colon = text.firstIndex(of: ":") else {
            return false
        }
        let key = text[..<colon]
        return !key.isEmpty && key.allSatisfy { $0.isLetter || $0.isNumber }
    }
}
