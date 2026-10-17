/// A result builder that describes a command's options as a list of components.
///
/// Commands with options have initializers that take a closure built with
/// this builder. Each component sets one option, in order, on the same
/// command value that the property-based API uses:
///
/// ```swift
/// let archive = BuildCommand(.clean, .archive) {
///     Workspace("App.xcworkspace")
///     Scheme("App")
///     BuildConfiguration("Release")
///     Destination(.generic(.iOS))
///     ArchivePath("build/App.xcarchive")
///     if isContinuousIntegration {
///         AllowProvisioningUpdates()
///     }
/// }
/// ```
///
/// The builder is generic over the command, and every component states which
/// commands accept it, so a component a command doesn't accept fails to
/// compile. Closures can use `if`, `if let`, `switch`, `for`, and
/// `#available`, and can include the result of another builder:
///
/// ```swift
/// @XcodeBuildCommandBuilder<BuildCommand>
/// var common: XcodeBuildCommandContent<BuildCommand> {
///     Workspace("App.xcworkspace")
///     Scheme("App")
/// }
///
/// let test = BuildCommand(.test) {
///     common
///     Destination(.simulator(.iOS, name: "iPhone 17 Pro"))
/// }
/// ```
@resultBuilder
public enum XcodeBuildCommandBuilder<Command: XcodeBuildCommand> {
    // A single generic `buildExpression` takes both components and content,
    // which is itself a component. With a second overload for content, a
    // component of another command was reported as "cannot convert value of
    // type 'TestPlan' to expected argument type 'XcodeBuildCommandContent<…>'"
    // instead of naming the command the component belongs to.
    public static func buildExpression<Component: XcodeBuildCommandComponent>(
        _ component: Component
    ) -> XcodeBuildCommandContent<Command> where Component.Command == Command {
        XcodeBuildCommandContent(modifications: [component.apply(to:)])
    }

    public static func buildBlock(_ contents: XcodeBuildCommandContent<Command>...) -> XcodeBuildCommandContent<Command> {
        XcodeBuildCommandContent(modifications: contents.flatMap(\.modifications))
    }

    public static func buildOptional(_ content: XcodeBuildCommandContent<Command>?) -> XcodeBuildCommandContent<Command> {
        content ?? XcodeBuildCommandContent()
    }

    public static func buildEither(first content: XcodeBuildCommandContent<Command>) -> XcodeBuildCommandContent<Command> {
        content
    }

    public static func buildEither(second content: XcodeBuildCommandContent<Command>) -> XcodeBuildCommandContent<Command> {
        content
    }

    public static func buildArray(_ contents: [XcodeBuildCommandContent<Command>]) -> XcodeBuildCommandContent<Command> {
        XcodeBuildCommandContent(modifications: contents.flatMap(\.modifications))
    }

    public static func buildLimitedAvailability(_ content: XcodeBuildCommandContent<Command>) -> XcodeBuildCommandContent<Command> {
        content
    }
}

/// The options that a ``XcodeBuildCommandBuilder`` closure describes, in order.
///
/// Commands apply the content when they are created. You create content only
/// to share options between commands, with a property or function marked
/// with ``XcodeBuildCommandBuilder``.
public struct XcodeBuildCommandContent<Command: XcodeBuildCommand>: XcodeBuildCommandComponent {
    let modifications: [(inout Command) -> Void]

    /// Creates empty content.
    public init() {
        self.modifications = []
    }

    init(modifications: [(inout Command) -> Void]) {
        self.modifications = modifications
    }

    /// Applies the options to a command, in order.
    public func apply(to command: inout Command) {
        for modification in modifications {
            modification(&command)
        }
    }
}

/// One option in a ``XcodeBuildCommandBuilder`` closure.
///
/// A component sets one option on a command. Components for options that
/// several commands share are generic over the command and constrained to
/// the protocol of that option, such as ``SchemeSelecting``; the builder
/// infers the command. Components for options of a single command use that
/// command directly.
public protocol XcodeBuildCommandComponent<Command> {
    /// The command this component applies to.
    associatedtype Command: XcodeBuildCommand

    /// Sets the option on the command.
    func apply(to command: inout Command)
}
