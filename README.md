# swift-xcode-build

A Swift interface to `xcodebuild`: every mode and option of the tool as typed command values, a result builder DSL that describes the same commands, and a runner built on [swift-subprocess](https://github.com/swiftlang/swift-subprocess).

## Overview

Running xcodebuild from Swift usually means assembling string arrays, decoding JSON that some versions prefix with a line of text, scraping the text of `-showdestinations`, interpreting exit codes, and stopping the process when the task is cancelled. Every tool that builds Apple projects writes this code again.

swift-xcode-build models each mode of xcodebuild as a command type whose options are properties:

```swift
import XcodeBuild

let xcodebuild = XcodeBuildTool()

let sdks = try await xcodebuild.run(.showSDKs)        // [SDKDescription]

var test = BuildCommand(actions: [.test], container: .workspace("App.xcworkspace"), scheme: "App")
test.destinations = [.simulator(.iOS, name: "iPhone 17 Pro")]
test.testing.onlyTesting = ["AppTests/LoginTests"]

try await xcodebuild.run(test) { output in
    for try await line in output {
        print(line.text)
    }
}
```

The same commands can be described with components, and a component that a command doesn't accept fails to compile:

```swift
let archive = BuildCommand(.clean, .archive) {
    Workspace("App.xcworkspace")
    Scheme("App")
    BuildConfiguration("Release")
    Destination(.generic(.iOS))
    ArchivePath("build/App.xcarchive")
    if isContinuousIntegration {
        AllowProvisioningUpdates()
    }
}

ListCommand { Scheme("App") }
// error: generic struct 'Scheme' requires that 'ListCommand' conform to 'SchemeSelecting'
```

## Features

- **Every mode of xcodebuild**: the ten build actions, `-list`, `-showsdks`, `-showBuildSettings`, `-showBuildSettingsForIndex`, `-showdestinations`, `-showTestPlans`, `-version`, `-find-executable`, `-find-library`, `-exportArchive`, `-exportNotarizedApp`, `-exportLocalizations`, `-importLocalizations`, `-resolvePackageDependencies`, `-create-xcframework`, `-convert-project`, platform and component downloads, `-prepareDeviceSupport`, first launch, the license, and the usage text. 33 command types in all.
- **Every option** that `xcodebuild -help` and the man page document. A test parses the installed `xcodebuild -help` and fails when it lists an option that no command renders.
- **Typed results**: queries decode xcodebuild's JSON into models, parse the text of `-version` and `-showdestinations`, and turn the exit status of `-checkFirstLaunchStatus` and `-license check` into a `Bool`.
- **A result builder DSL** with 91 components. Each component states which commands accept it, so misuse is a compile-time error, and `if`, `switch`, `for`, and `#available` work inside the closure.
- **Streaming logs**: the log of an action is an `AsyncSequence` of lines whose iteration throws `XcodeBuildError`. The closure that reads it runs on the caller's actor.
- **Cancellation** stops xcodebuild the way Control-C does, then escalates: `SIGINT`, `SIGTERM` after a grace period, and `SIGKILL`.
- **Typed throws**: every API throws `XcodeBuildError`, which carries the command line, the termination status, and the last lines xcodebuild wrote.
- **Export options as a value**: `ExportOptions` covers every key of the export options property list and is written to a temporary file for the run.
- Escape hatches for anything new: `additionalArguments` and `userDefaults` on every command, and your own commands by conforming to `XcodeBuildQueryCommand` or `XcodeBuildActionCommand`.

## Requirements

- macOS 15 or later
- Swift 6.2 or later (Xcode 26 or later)

The options follow Xcode 27.2. Options that only Xcode 27 accepts, such as `-convert-project` and code size profiling, are marked in their documentation; an older xcodebuild rejects them with a usage error. The tests pass against the xcodebuild of Xcode 27.2 and Xcode 26.6.

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Mx-Iris/swift-xcode-build.git", from: "0.1.0"),
],
```

Then depend on the `XcodeBuild` module:

```swift
.target(
    name: "MyTool",
    dependencies: [
        .product(name: "XcodeBuild", package: "swift-xcode-build"),
    ]
),
```

## Usage

### Choosing an Xcode

`XcodeBuildTool()` runs `/usr/bin/xcodebuild`, which uses the Xcode that `xcode-select` selects or that `DEVELOPER_DIR` names. To use another Xcode, set `developerDirectory`:

```swift
let older = XcodeBuildTool(developerDirectory: "/Applications/Xcode-26.6.0.app")
```

The tool is a value. Copy it and change `workingDirectory`, `environment`, `standardOutputLimit`, or `cancellationGracePeriods` for a different run.

### Queries and actions

Commands come in two kinds:

- **Queries** print their result: `ListCommand`, `ShowSDKsCommand`, `ShowBuildSettingsCommand`, `VersionCommand`, and the others. `run(_:)` collects their output and returns the decoded result.
- **Actions** print a log: `BuildCommand`, the export and localization commands, downloads, and the others. `run(_:)` waits for them and returns an `XcodeBuildSummary`; `run(_:body:)` passes the log to a closure while xcodebuild writes it.

```swift
let listing = try await xcodebuild.run(ListCommand(.project("App.xcodeproj")))
print(listing.schemes)

let destinations = try await xcodebuild.run(ShowDestinationsCommand(scheme: "App"))
let simulator = destinations.compatible.first { $0.platform == "iOS Simulator" }

let settings = try await xcodebuild.run(ShowBuildSettingsCommand {
    Workspace("App.xcworkspace")
    Scheme("App")
    BuildConfiguration("Release")
})
let bundleIdentifier = settings.first?["PRODUCT_BUNDLE_IDENTIFIER"]
```

The log of an action merges standard output and standard error in the order xcodebuild wrote them. If the closure returns early, the tool reads and discards the rest so that xcodebuild never blocks on a full pipe. The log is valid only while the closure runs.

### Exporting an archive

```swift
var options = ExportOptions(method: .appStoreConnect)
options.destination = .upload
options.teamIdentifier = "ABCDE12345"

try await xcodebuild.run(ExportArchiveCommand(archivePath: "build/App.xcarchive", exportOptions: .options(options)) {
    AuthenticationKey(path: "AuthKey.p8", identifier: "KEY1234567", issuerIdentifier: "issuer-identifier")
})
```

With inline options, the command's `arguments` contain a placeholder that the tool replaces with the path of a temporary property list, which it removes when xcodebuild exits. Pass `.propertyList(path)` to use a file of your own.

### Errors

Every API throws `XcodeBuildError`. Check its `code`:

| Code | Meaning |
|---|---|
| `commandFailed` | xcodebuild exited with a nonzero status or was killed. |
| `cancelled` | The task was cancelled and xcodebuild was stopped. |
| `launchFailed` | xcodebuild could not be started. |
| `outputLimitExceeded` | A query printed more than `standardOutputLimit` bytes. |
| `unexpectedOutput` | xcodebuild succeeded, but its output could not be decoded. |
| `bodyFailed` | Your closure threw; its error is in `underlyingError`. |
| `temporaryFileFailed` | The property list for inline export options could not be written. |
| `executionFailed` | Reading xcodebuild's output or waiting for it failed. |

The error's description includes the command line, quoted for a shell, and the last lines of output, which usually contain xcodebuild's own `error:` message.

### Cancellation

When the task running a command is cancelled, the tool sends `SIGINT`, which makes xcodebuild cancel the build and print `** BUILD INTERRUPTED **`. If xcodebuild is still running after 10 seconds it receives `SIGTERM`, and 5 seconds later `SIGKILL`. Change the periods with `cancellationGracePeriods`.

### Paths

Paths are `FilePath` values from the System framework. To write them as string literals in a module that enables the `MemberImportVisibility` upcoming feature, add `import System`.

## Testing

```bash
swift test
```

The tests include read-only queries against the real `/usr/bin/xcodebuild`, so `DEVELOPER_DIR` selects the Xcode they test. Environment variables control them:

| Variable | Effect |
|---|---|
| `SWIFT_XCODE_BUILD_TESTS_SKIP_REAL=1` | Skips every test that runs the real xcodebuild. |
| `SWIFT_XCODE_BUILD_TESTS_BUILD=1` | Also runs the tests that build the fixture project. |
| `SWIFT_XCODE_BUILD_TESTS_DERIVED_DATA` | The directory for the tests' derived data. Without it, a directory in the temporary directory is used, never Xcode's own derived data. |

## License

swift-xcode-build is available under the MIT license. See [LICENSE](LICENSE).
