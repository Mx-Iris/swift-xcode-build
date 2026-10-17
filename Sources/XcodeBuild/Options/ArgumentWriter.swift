import System

/// Collects command-line arguments in order.
struct ArgumentWriter {
    private(set) var arguments: [String] = []

    /// Appends arguments as they are.
    mutating func append(_ newArguments: String...) {
        arguments.append(contentsOf: newArguments)
    }

    /// Appends arguments as they are.
    mutating func append(contentsOf newArguments: [String]) {
        arguments.append(contentsOf: newArguments)
    }

    /// Appends `name` when `isSet` is true.
    mutating func flag(_ name: String, _ isSet: Bool) {
        if isSet {
            arguments.append(name)
        }
    }

    /// Appends `name value` when there is a value.
    mutating func option(_ name: String, _ value: String?) {
        if let value {
            arguments.append(name)
            arguments.append(value)
        }
    }

    /// Appends `name path` when there is a path.
    mutating func option(_ name: String, _ path: FilePath?) {
        option(name, path?.string)
    }

    /// Appends `name number` when there is a number.
    mutating func option(_ name: String, _ number: Int?) {
        option(name, number.map(String.init))
    }

    /// Appends `name seconds`, in whole seconds, when there is a duration.
    mutating func option(_ name: String, seconds duration: Duration?) {
        option(name, duration.map { String($0.components.seconds) })
    }

    /// Appends `name YES` or `name NO` when there is a value.
    mutating func option(_ name: String, yesOrNo value: Bool?) {
        option(name, value.map { $0 ? "YES" : "NO" })
    }

    /// Appends `name value` for each value.
    mutating func repeatedOption(_ name: String, _ values: [String]) {
        for value in values {
            option(name, value)
        }
    }

    /// Appends `name value` for each raw value.
    mutating func option<Value: RawRepresentable<String>>(_ name: String, _ value: Value?) {
        option(name, value?.rawValue)
    }
}
