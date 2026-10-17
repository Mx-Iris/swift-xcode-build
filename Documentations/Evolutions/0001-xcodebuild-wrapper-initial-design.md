# 0001 - xcodebuild 的 Swift 封装：初始设计

- **状态**: Implemented
- **创建日期**: 2026-10-17
- **最后更新**: 2026-10-17
- **配套文档**: [使用指南](../Guides/RunningXcodeBuild.md)、[实现说明](../Internal/XcodeBuildWrapperImplementation.md)

## 摘要

新建 Swift 包 swift-xcode-build（模块 `XcodeBuild`，最低 macOS 15），把 Xcode 27.2 的 `xcodebuild -help` 与 man page 里列出的全部用法封装成类型安全的 Swift API：10 个构建动作（build、test、archive……）和近 30 种独立模式（查询、导出、本地化、XCFramework、模拟器平台与组件下载、首次启动、许可协议等）。每种模式对应一个命令值类型，所有选项都是它的属性；在此之上再提供一套 result builder DSL，用声明式的写法拼出同一个命令值。执行器经 swift-subprocess 启动 xcodebuild，按命令把输出解析成类型化结果，运行中可以逐行读构建日志，任务取消时按信号序列终止进程。

动机：在 Swift 里调 xcodebuild，目前只能手拼字符串数组、自己解析 JSON 与文本输出、自己处理退出码和取消，每个用到它的工具都在重复这套代码。

## 方案

### 包

- 位置 `/Volumes/Repositories/Private/Personal/Library/macOS/swift-xcode-build`，本地 git 仓库。
- 一个 library product、一个模块 `XcodeBuild`；唯一依赖 swift-subprocess `from: "1.0.2"`。
- `swift-tools-version: 6.2`，Swift 6 语言模式，开关与 swift-proc 相同：`NonisolatedNonsendingByDefault`、`InternalImportsByDefault`、`MemberImportVisibility`、`ExistentialAny`、`.strictMemorySafety()`。

### 核心 API（已选定：命令值类型 + 执行器）

```swift
let xcodebuild = XcodeBuildTool()               // /usr/bin/xcodebuild, honours xcode-select and DEVELOPER_DIR
let older = XcodeBuildTool(developerDirectory: "/Applications/Xcode-26.6.0.app")

let sdks = try await xcodebuild.run(.showSDKs)  // [SDKDescription]

var command = BuildCommand(actions: [.test], container: .workspace("App.xcworkspace"), scheme: "App")
command.destinations = [.simulator(.iOS, name: "iPhone 17 Pro")]
command.testing.onlyTesting = ["AppTests/LoginTests"]
try await xcodebuild.run(command) { output in   // AsyncSequence<XcodeBuildOutput.Line, XcodeBuildError>
    for try await line in output { print(line.text) }
}
```

- `protocol XcodeBuildCommand: Sendable`：给出渲染好的参数数组，以及如何把结束的进程（退出码、收集到的 stdout）变成 `associatedtype Output`。
- 几个命令共用的选项分组成嵌套结构体：工程与 scheme（`ProjectContainer`：`.project`、`.workspace`，或在当前目录自动识别，包括 Swift package）、构建、测试、Swift package 解析、签名与 App Store Connect 认证、sanitizer、代码体积分析。
- 取值是几个固定字符串的选项（action、平台、导出 method、package 指纹策略……）用 struct + `rawValue` + static 成员（swift-system 与 swift-proc 的做法），Xcode 新增取值时不必等库升级。互斥的选项合成一个 enum（例如 `-retry-tests-on-failure` 与 `-run-tests-until-failure`）。
- destination（构建或测试的目标设备）类型化为 `DestinationSpecifier`（沿用 man page 的术语）：`.generic(.iOS)`、`.simulator(…)`、`.device(identifier:)`、`.macOS(architecture:variant:)`，也能加任意键值。build settings 与 user defaults 用保序的键值类型——命令行上后出现的覆盖先出现的。
- `ExportOptions` 覆盖 `-help` 列出的全部 18 个导出键，运行时写成临时 plist、结束后删除；也可以直接给现成的 plist。
- 每个命令都有 `additionalArguments`，给未公开或将来新增的选项留出口。

### DSL（命令值之上的第二种写法）

```swift
let archive = BuildCommand(.clean, .archive) {
    Workspace("App.xcworkspace")
    Scheme("App")
    BuildConfiguration("Release")
    Destination(.generic(.iOS))
    ArchivePath("build/App.xcarchive")
    BuildSetting("CODE_SIGNING_ALLOWED", "NO")
    if isContinuousIntegration {
        AllowProvisioningUpdates()
    }
}
try await xcodebuild.run(archive) { output in
    for try await line in output { print(line.text) }
}

let settings = try await xcodebuild.run(ShowBuildSettingsCommand {
    Workspace("App.xcworkspace")
    Scheme("App")
})

ListCommand { Scheme("App") }                   // compile-time error: -list does not take -scheme
```

- DSL 只是前端：每个有可选项的命令类型多一个接收 result builder 闭包的初始化器，闭包里的组件按顺序改写同一个命令值。参数渲染、执行和测试都只有一条路径；两种写法可以混用（用 DSL 建好后再改属性）。
- 必填项（例如 `-exportArchive` 的归档路径、`-create-xcframework` 的输出路径）仍是初始化器参数，DSL 里只放可选项。
- 闭包里可以用 `if`、`if let`、`switch`、`for` 与 `#available`。
- **选项是否适用于该命令，在编译期检查**：命令类型通过能力协议声明自己接受哪些选项组（例如 `SchemeSelecting`）；组件类型以命令为泛型参数、由 builder 推断，所以 `ListCommand { Scheme("App") }` 编译失败，报 `ListCommand` 不满足 `SchemeSelecting`。上一轮否决「result builder DSL」的理由正是编译器查不出这种错，按命令区分 builder 之后它不再成立。这套机制是实现的第一步：先用最小代码确认编译器的推断和报错符合预期，再铺开全部组件。
- 组件命名避开常见的重名：用 `BuildConfiguration` 而不是 `Configuration`（swift-subprocess 有同名类型），用 `UserDefaultOverride` 而不是 `UserDefault`（很多 app 自己有同名的 property wrapper）；组件与值类型不同名（组件 `Destination` 包装值类型 `DestinationSpecifier`）。

### 覆盖

| xcodebuild 用法 | 命令类型 | 结果 |
|---|---|---|
| `action ...`（10 个动作，可连用） | `BuildCommand` | 完成信息（耗时、命令行、结果包与归档路径） |
| `-list`、`-showsdks`、`-showBuildSettings`、`-showTestPlans` | 各一个 | 解码成模型，能用 `-json` 的都用 `-json` |
| `-showBuildSettingsForIndex` | 一个 | 原始 JSON（Apple 未公开结构） |
| `-showdestinations` | 一个 | 可用 / 不可用 destination 列表（只有文本输出） |
| `-version`、`-version -sdk [-json] [infoitem]` | 两个 | Xcode 版本与 build 号；SDK 信息或单项值 |
| `-find-executable`、`-find-library` | 各一个 | `FilePath` |
| `-exportArchive`、`-exportNotarizedApp` | 各一个 | 导出路径 |
| `-exportLocalizations`、`-importLocalizations` | 各一个 | 完成信息 |
| `-resolvePackageDependencies`、`-create-xcframework`、`-convert-project` | 各一个 | 完成信息 / 输出路径 |
| `-downloadPlatform`、`-downloadAllPlatforms`、`-importPlatform` | 各一个 | 完成信息 |
| `-downloadComponent`、`-importComponent`、`-deleteComponent`、`-showComponent` | 各一个 | 完成信息；`-showComponent -json` 解码成模型 |
| `-prepareDeviceSupport` | 一个 | 完成信息 |
| `-checkFirstLaunchStatus`、`-runFirstLaunch` | 各一个 | 是否需要首次启动（退出码本身就是答案，不当错误抛）；完成信息 |
| `-license accept`、`check`、`status` | 一个 | 是否已接受；完成信息 |
| `-usage`、`-help` | 一个 | 文本 |

### 执行、取消与错误

- 默认给子进程加 `NSUnbufferedIO=YES`，让 xcodebuild 在管道里也逐行刷新输出。
- 查询命令把 stdout 收齐再解析（有上限，默认 64 MiB，可调）；JSON 解码标 `@concurrent`，大输出不占用调用方的 actor。stderr 只留末尾一段，放进错误信息。
- 带闭包的 `run` 把 stdout 与 stderr 合成一条输出流交给闭包；闭包提前返回时库继续读完剩余输出，避免 xcodebuild 写满管道后卡住。
- 任务取消时先发 SIGINT（相当于在终端按 Ctrl-C，让 xcodebuild 自己收尾），宽限 10 秒后发 SIGTERM（请求退出），再过 5 秒发 SIGKILL（强杀），时长可配置，最后抛 `cancelled`。
- `XcodeBuildError` 是 struct：`code` + 退出码 + 完整命令行 + stderr 末尾 + `underlyingError`；`Code` 是包着私有 enum 的 struct（swift-subprocess、swift-proc 的形状），以后加错误种类不破坏源码。公开 API 一律 `throws(XcodeBuildError)`。非 0 退出默认抛错；「退出码就是答案」的命令由命令自己解释。

### 用到的 Swift 新特性

只用有实际用处的：typed throws（SE-0413，签名写明只抛 `XcodeBuildError`）；带 `Failure` 类型的 `AsyncSequence`（SE-0421，要 macOS 15，`for try await` 拿到的错误就是 `XcodeBuildError`）；`nonisolated(nonsending)` 默认化与 `@concurrent`（SE-0461，`run` 与观察闭包跑在调用方的 actor 上，`@MainActor` 代码可以在闭包里直接改界面状态）；严格内存安全检查（SE-0458）；`InternalImportsByDefault`（SE-0409，swift-subprocess 不出现在公开 API 里，以后换掉它或跟进它的大版本都不影响调用方）；测试用 Swift Testing 的参数化测试与 raw identifier 测试名（SE-0451）。

### 测试

- 参数渲染：每个命令、每个选项（参数化测试）。
- DSL：每个组件与等价的属性写法渲染出完全相同的参数（参数化测试）。
- **覆盖率测试**：解析本机 `xcodebuild -help` 的选项表，断言每一项都能由某个命令渲染出来——Xcode 新增选项时它会变红。
- 输出解析：用 Xcode 27.2 与 26.6 实录的输出做 fixture（测试用的样例数据）。例如 `-version -sdk macosx -json` 会在 JSON 前多打一行 `SDK macOS 27.2:`。
- 执行器：用假的 xcodebuild 脚本测流式输出、退出码映射、取消时的信号顺序。
- 真实 xcodebuild：只读查询默认跑（对一个最小的 fixture 包做 `-list`、`-showBuildSettings`、`-showdestinations`）；真正构建的测试默认关闭、用环境变量打开，DerivedData 目录可配置。Xcode 27.2 与 26.6 各跑一遍。

### 文档

英文 README、MIT LICENSE、`Documentations/` 索引；实现完成时按判据决定是否补使用指南（取消、输出上限、退出码这类签名里看不出的契约）和实现说明。

### 不在本提案范围内

- 把构建 / 测试日志解析成结构化事件（错误、警告、测试结果，类似 xcbeautify）：先只给逐行文本，需要时另起提案。
- `.xcresult` 解析（那是 `xcresulttool` 的事）以及 `simctl`、`notarytool` 等其他工具。
- 未公开选项（`-dry-run`、`-only-testing-tags`、`-skipUnsupportedDestinations`、`-createNewProject` 等几十个，只出现在 Xcode3Core 的字符串里）：不建模，可走 `additionalArguments`。
- 需要终端交互的 `-license`（不带子动作时会进入分页器）。
- 发布到 GitHub。

### 采用的假设（不同意请指出）

1. **tools version 定 6.2，不是 6.4**：查过 6.3 / 6.4 的新增（模块选择器 `::`、`@diagnose`、`defer` 里 `await`、async 版 `Result(catching:)`、`withTaskCancellationShield`），对这个库要么只是写法不同，要么要 macOS 27 的运行时。定 6.2 让 Xcode 26 也能用，与 swift-subprocess 1.0、swift-proc 一致。
2. **覆盖基准是 Xcode 27.2**：只在 27 才有的选项（`-convert-project`、`-enableCodesizeProfile`、`-codesizeProfileOutputDir`、`-deleteComponent` / `-showComponent` 的 `-buildVersion`、`devicesupport` 组件、测试标识的 `@文件` 写法）在文档注释里注明，不做运行时版本判断；旧版 xcodebuild 遇到它们会自己报用法错误。
3. **库内不打日志**，因此不依赖 FrameworkToolbox：它会把 swift-syntax 带给每个依赖方；调用方能拿到每次执行的完整命令行，自己决定怎么记。
4. **执行器叫 `XcodeBuildTool`，不叫 `XcodeBuild`**：类型与模块同名时，调用方写不出 `XcodeBuild.某类型` 这种限定名。
5. **专有名词白名单**：SDK、JSON、XCFramework、XLIFF、URL、UUID、ISO，以及 xcconfig、xctestrun、xcarchive 这类文件类型名；其余写全称（`teamIdentifier`、`architecture`、`operatingSystemVersion`）。
6. **路径用 `FilePath`**（System 框架），与 swift-subprocess、swift-proc 一致；License 用 MIT；只建本地仓库。
7. **DSL 与核心放在同一个模块 `XcodeBuild`**，不像 Apple 的 RegexBuilder 那样拆成单独模块。代价是 `import XcodeBuild` 会多出几十个组件类型名，与其他模块重名时写 `XcodeBuild.Scheme` 限定。
8. **`ExportOptions` 不做 DSL**：它是一张导出配置表，用普通初始化器写更直接。

## 决策日志

| 日期 | 决定 | 理由 |
|------|------|------|
| 2026-10-17 | Created as Draft：「写一个Swift库，将xcodebuild的所有命令封装起来，包名swift-xcode-build，模块名XcodeBuild，要用上最新的Swift特性，最低版本macOS15.0」 | — |
| 2026-10-17 | 进程执行用 swift-subprocess，不用 Foundation 的 `Process` | 用户要求 |
| 2026-10-17 | 公开 API 采用「命令值类型 + 执行器」 | 用户选择。否决「每个命令一个方法」：archive、test 要几十个默认参数，命令不能当值保存复用，加选项就要改签名；否决 result builder DSL：编译器查不出选项与模式不匹配 |
| 2026-10-17 | 公开 API 用 typed throws，错误类型是 struct + 可扩展的 `Code` | 与 swift-proc 一致；`Code` 可扩展，缓解 typed throws 对库演进的约束 |
| 2026-10-17 | 增加 result builder DSL，作为命令值类型之上的第二种写法 | 用户要求（「加多一个DSL接口」）。上一条否决它，是因为编译器查不出选项与模式不匹配；改成按命令区分的 builder、用能力协议约束组件之后，这类错误在编译期就能查出 |
| 2026-10-17 | 状态改为 Accepted | 用户批准（「可以」），开始实现 |
| 2026-10-17 | DSL 采用「组件以命令为泛型参数」，不用「builder 上按组件写受约束的重载」 | 实现第一步用最小代码比较两者的误用报错：前者报 `generic struct 'Scheme' requires that 'ListCommand' conform to 'SchemeSelecting'`，后者不提组件名，组件多了更易退化。单命令选项的组件直接绑定命令，builder 只留一个 `buildExpression`，误用时报 `requires the types 'ListCommand' and 'BuildCommand' be equivalent`。详见实现说明决策 10 |
| 2026-10-17 | 命令协议分成查询与动作两个子协议；查询的 stderr 完整收集；`-license` 只建模 accept 与 check；动作命令的结果统一为 `XcodeBuildSummary` | 实现中发现：带闭包的运行只对动作有意义，分协议能在编译期拦下误用；`-help` 与 `-usage` 写在 stderr 上；`-license status` 在许可已接受的机器上看不出行为。全部差异见实现说明「与提案的差异」 |
| 2026-10-17 | 状态改为 In Progress | 实现、测试与文档完成，89 个测试在 Xcode 27.2 与 26.6 下全部通过；代码尚未提交，提交到 main 时编号并改为 Implemented |
| 2026-10-17 | 编号 0001，状态改为 Implemented | 用户要求提交推送（「提交推送一下」），随首个提交落地到 main。配套文档：写了使用指南（日志生命周期、取消、退出状态即答案、`-derivedDataPath` 等签名里看不出的契约）和实现说明（看起来更简单的做法为什么不行，以及与提案的差异），已登记在头部。新术语：查询命令与动作命令、能力协议、组件、destination specifier、user default 覆盖、宽限期，已登记进 `Documentations/Glossary.md` |
