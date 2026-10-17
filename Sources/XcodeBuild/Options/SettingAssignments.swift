/// Name-value assignments in command-line order, for build settings and user defaults.
///
/// When a name is assigned more than once, xcodebuild uses the assignment
/// that comes last. Assigning through the subscript replaces an existing
/// assignment in place and appends a new one otherwise:
///
/// ```swift
/// command.buildSettings["CODE_SIGNING_ALLOWED"] = "NO"
/// command.buildSettings = ["SWIFT_ACTIVE_COMPILATION_CONDITIONS": "$(inherited) CI", "ONLY_ACTIVE_ARCH": "YES"]
/// ```
public struct SettingAssignments: Sendable, Hashable {
    /// A single `name=value` assignment.
    public struct Assignment: Sendable, Hashable {
        /// The name of the build setting or user default.
        public var name: String

        /// The value assigned to it.
        public var value: String

        /// Creates an assignment.
        public init(name: String, value: String) {
            self.name = name
            self.value = value
        }
    }

    /// The assignments, in command-line order.
    public var assignments: [Assignment]

    /// Creates assignments, in order.
    public init(_ assignments: [Assignment] = []) {
        self.assignments = assignments
    }

    /// Whether there are no assignments.
    public var isEmpty: Bool {
        assignments.isEmpty
    }

    /// The value xcodebuild uses for a name: the last one assigned.
    ///
    /// Setting a value replaces the last assignment of the name, or appends
    /// one. Setting `nil` removes every assignment of the name.
    public subscript(name: String) -> String? {
        get {
            assignments.last { $0.name == name }?.value
        }
        set {
            if let newValue {
                if let index = assignments.lastIndex(where: { $0.name == name }) {
                    assignments[index].value = newValue
                } else {
                    assignments.append(Assignment(name: name, value: newValue))
                }
            } else {
                assignments.removeAll { $0.name == name }
            }
        }
    }

    /// Appends an assignment, even if the name is already assigned.
    public mutating func append(name: String, value: String) {
        assignments.append(Assignment(name: name, value: value))
    }
}

extension SettingAssignments: ExpressibleByDictionaryLiteral {
    /// Creates assignments in the order of the literal.
    public init(dictionaryLiteral elements: (String, String)...) {
        self.init(elements.map { Assignment(name: $0.0, value: $0.1) })
    }
}

extension SettingAssignments {
    /// Renders build settings as `NAME=value`.
    func renderBuildSettings(into writer: inout ArgumentWriter) {
        for assignment in assignments {
            writer.append("\(assignment.name)=\(assignment.value)")
        }
    }

    /// Renders user defaults as `-NAME=value`.
    func renderUserDefaults(into writer: inout ArgumentWriter) {
        for assignment in assignments {
            writer.append("-\(assignment.name)=\(assignment.value)")
        }
    }
}
