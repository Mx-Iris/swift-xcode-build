# xcodebuild 封装：实现说明

> 配套提案见 [xcodebuild 的 Swift 封装：初始设计](../Evolutions/0001-xcodebuild-wrapper-initial-design.md)。
> 本文记录**实际落地的实现**、与提案的差异，以及当前覆盖范围与已知降级。面向维护者。
> 文中 xcodebuild 的行为都在 Xcode 27.2（27B5038j）和 Xcode 26.6（17F113）上实测过；swift-subprocess 的行为对照 1.0.2 的源码。

## 背景与目标

把 xcodebuild 的全部用法封装成类型化的命令值，再加一套 result builder DSL，用 swift-subprocess 执行。完整动机见提案；调用方契约见[使用指南](../Guides/RunningXcodeBuild.md)。

## 关键设计决策

### 1. 查询和动作是两个协议，不是一个协议加运行时标志

`XcodeBuildCommand` 只要求 `arguments` 和 `output(from:)`，下面再分两个标记协议：

- `XcodeBuildQueryCommand`：stdout 是结果。执行器用两条管道，分别收集 stdout 和 stderr。
- `XcodeBuildActionCommand`：stdout 是日志。执行器把 stderr 合进 stdout，逐行读。

执行器为两者各提供一个 `run(_:)` 重载，`run(_:body:)` 只接受动作命令。这样「拿闭包读查询的输出」在编译期就被拦下：查询的结果要从完整的 stdout 解码，不能同时交给闭包。用运行时标志也能选执行方式，但这个错误就拦不住了。

### 2. 动作的日志在文件描述符层合并

动作命令用 swift-subprocess 的 `error: .combinedWithOutput`，stderr 直接 dup 到 stdout 的管道上。这样只有一个读取者，不需要子任务和中转队列，行的先后顺序和 xcodebuild 写入的顺序完全一致。代价是日志行分不出来自哪个流。

出错时 `outputTail` 取合并日志的最后 50 行，恰好包含编译器的 `error:` 行、`The following build commands failed:` 列表和 `** BUILD FAILED **`。两个流分开收集的话，这些信息会散在两处。

### 3. 闭包返回后，执行器把剩下的日志读完

swift-subprocess 在 body 闭包返回时**立即关闭**管道读端，不管有没有读完（`API.swift` 里 `try? outputSequence?.close()`，注释写的是 "whether or not `body` fully drained them"）。读端关闭后，xcodebuild 下一次写入会收到 `SIGPIPE` 或 `EPIPE`，构建因此失败。

所以 `run(_:body:)` 在调用方的闭包返回后，先调用 `LineReader.drain()` 读到 EOF，再交还给 swift-subprocess。回归测试是 `returning from the closure early still lets xcodebuild write its whole log`：假脚本写 20000 行，闭包只读一行。

### 4. 查询也收集 stderr

`-help` 和 `-usage` 把全文写在 **stderr** 上，Xcode 27.2 和 26.6 都是这样：`xcodebuild -help > file` 得到的 file 是空的。所以查询的 stderr 不能只留末尾。执行器把 stderr 按行收进 `XcodeBuildCompletion.standardError`，上限和 stdout 一样，同时另存最后 50 行。`HelpCommand` 和 `UsageCommand` 读的是 `printedText`：stdout 为空时取 stderr。

### 5. 闭包为什么在调用方的 actor 上运行

本包和 swift-subprocess 的 `Subprocess` target 都开了 `NonisolatedNonsendingByDefault`。`Subprocess.run` 和它的 body 函数类型因此都是 `nonisolated(nonsending)`，`Configuration.swift` 里也注释了 "Body runs in the same isolation."。我们的 `run` 同样是 `nonisolated(nonsending)`，在 swift-subprocess 的 body 里直接调用调用方的闭包，闭包就跑在调用方的 actor 上，不需要子任务和 `AsyncStream` 转发。

这条保证依赖 swift-subprocess 的编译设置。如果它以后把 `run` 改成 `@concurrent`，测试 `the closure runs on the caller's actor` 会变红：这个测试在 `@MainActor` 上运行，用 `pthread_main_np()` 检查每一行是不是在主线程上收到的。

结果的解码放在 `@concurrent` 的 `makeOutput(of:from:)` 里，几 MB 的 `-showBuildSettings` JSON 不会占用调用方的 actor。

### 6. 读日志时把迭代器移出来

`LineReader` 是一个 class，持有 swift-subprocess 的 `StringSequence.AsyncIterator`，调用方的迭代器和闭包之后的 drain 共用它。`next()` 先用 `Optional.take()` 把迭代器移出来，读完再放回去。如果写成 `var iterator = self.iterator`，就会有两份引用共享内部缓冲，修改时触发写时复制，每读一行都多拷一次。读到末尾或出错时不放回，之后的 `next()` 直接返回 `nil`。

### 7. 取消：swift-subprocess 的 teardown 序列，只发给 xcodebuild

`PlatformOptions.teardownSequence` 设为 `[.send(.interrupt, 10 秒), .send(.terminate, 5 秒)]`，swift-subprocess 在序列最后补发 `SIGKILL`。任务取消，或闭包抛错时（swift-subprocess 在 body 抛错时同样执行 teardown），都走这个序列。

信号只发给 xcodebuild，不发给进程组，也不为 xcodebuild 新建进程组。原因是要保留终端的语义：调用方的程序在终端里被 Control-C 打断时，终端把 `SIGINT` 发给整个前台进程组，xcodebuild 和调用方在同一组里，能一起收到。如果设了 `processGroupID` 让 xcodebuild 自成一组，Control-C 就到不了它；调用方没来得及取消任务就退出的话，xcodebuild 会继续跑。代价见使用指南：`SIGKILL` 时 xcodebuild 的子进程收不到信号。

取消之后的判断写在 `Invocation.checkCancellation`：只有 `Task.isCancelled` 为真、且 xcodebuild 没有成功退出时，才抛 `cancelled`。取消送达之前已经完成的运行保留结果。

信号顺序的回归测试有两个。一个假脚本记录收到的信号，但不退出，期望日志是 `INT\nTERM\n`，终止状态是 `SIGKILL`。另一个假脚本在收到 `SIGINT` 时退出，期望日志只有 `INT\n`。

### 8. 退出状态就是答案的两个命令

`-checkFirstLaunchStatus` 和 `-license check` 用 69（`EX_UNAVAILABLE`）表示「否」。依据是 xcodebuild 二进制里的字符串："User has NOT agreed to license, returning code 69"、"Packages need to be installed, returning code 69"、"First launch status check succeeded (license and package installation status OK), returning code 0"。

本机的五个 Xcode 都已接受许可，69 这条路径没法实测，测试用构造的 `XcodeBuildCompletion` 覆盖。注意 `-find-executable` 找不到工具时也退出 69，但那里 69 表示失败。

### 9. 内联导出选项：占位符加每次运行一个临时目录

`ExportArchiveCommand` 的选项为 `.options(…)` 时，`arguments` 里写的是占位符 `<temporary ExportOptions.plist>`。命令通过内部协议 `TemporaryFileRequiring` 声明需要哪些文件。`Invocation` 每次运行新建一个临时目录，写好文件、替换占位符后再启动，运行结束后删掉整个目录。没有采用的两种做法：

- **在命令初始化时生成随机路径。** 同一个命令值并发运行两次时，两次运行会删掉同一个文件；`arguments` 也不再确定，测试没法比较。
- **经 stdin 传 plist（`/dev/stdin`）。** xcodebuild 怎么读这个路径没有文档，也占用了 stdin。

`TemporaryFileRequiring` 是内部协议，执行器用 `as? any TemporaryFileRequiring` 检查。所以把 `ExportArchiveCommand` 包进自定义命令时，这个机制就不生效了。这种用法很少见，公开 API 因此保持最小。

### 10. DSL：组件以命令为泛型参数

实现的第一步，是用最小代码比较两种机制在误用时的报错：

| 机制 | `ListCommand { Scheme("App") }` 的报错 |
|---|---|
| A：组件不带泛型，builder 在受约束的扩展里为每个组件写一个 `buildExpression` | `referencing static method 'buildExpression' on 'XcodeBuildCommandBuilder' requires that 'ListCommand' conform to 'SchemeSelecting'` |
| B：组件以命令为泛型参数并要求能力协议，builder 只有一个泛型 `buildExpression` | `generic struct 'Scheme' requires that 'ListCommand' conform to 'SchemeSelecting'` |

B 的报错指名了组件。A 在只有两个组件时就已经不提组件名；组件多到几十个以后，几十个重载一起参与解析，报错更容易退化成 "no exact matches"。所以选 B。`if`、`for`、`#available` 里的误用也能报到正确的行上。

只有一个命令接受的选项（`BuildCommand` 的测试选项、`ExportLocalizationsCommand` 的语言选项等）不设协议，组件直接写 `apply(to command: inout BuildCommand)`。这里有一个坑：builder 原本还有第二个 `buildExpression`，专门接收 `XcodeBuildCommandContent`，误用这类组件时编译器挑中了它，报的是 `cannot convert value of type 'TestPlan' to expected argument type 'XcodeBuildCommandContent<ListCommand>'`，没提到 `BuildCommand`。现在让 `XcodeBuildCommandContent` 自己遵循组件协议，删掉第二个重载，报错变成 `static method 'buildExpression' requires the types 'ListCommand' and 'BuildCommand' be equivalent`。这三种误用的报错都实测过；为什么只留一个 `buildExpression`，写在它的源码注释里。

`BuildCommand` 的 DSL 初始化器写成 `init(_ action:, _ moreActions: BuildAction..., options: = { … })`，至少要传一个动作。如果写成纯可变参数，`BuildCommand()` 会同时匹配它和带全部默认参数的 `init(actions:container:scheme:)`，产生歧义。

### 11. 组件与值类型重名时改值类型的名字

组件按 xcodebuild 选项命名，便于从 man page 找过来。值类型和组件撞名时，改值类型的名字：

- `-scmProvider` 的值类型叫 `GitProvider`，组件叫 `SourceControlProvider`。
- `-packageDependencySCMToRegistryTransformation` 的值类型叫 `RegistryTransformation`，组件叫 `PackageRegistryTransformation`。
- App Store Connect 密钥的值类型叫 `AppStoreConnectKey`，组件叫 `AuthenticationKey`。
- `-packageAuthorizationProvider` 的值类型叫 `PackageCredentialStore`，组件叫 `PackageAuthorizationProvider`。

`-prepareDeviceSupport` 的 `-architecture` 和构建用的 `-arch` 是两个选项，组件分别叫 `DeviceArchitecture` 和 `Architecture`。`RegistryTransformation` 表示 `none` 的成员叫 `.disabled`：属性是 Optional 时，写 `.none` 会被当成 `Optional.none`。

### 12. 参数顺序

所有命令都按同一个顺序渲染参数：先是模式标志（`-list`、`-showBuildSettings` 等）和 `-json`，然后是选项（大体按 `-help` 的分组排列），接着是位置参数（动作、`NAME=value` 形式的 build setting），再是 `-NAME=value` 形式的 user default，最后是 `additionalArguments`。

`additionalArguments` 放在最后，是给 xcodebuild 新增的选项留的口子。它们放在哪里，xcodebuild 都能识别。

### 13. `-version -sdk -json` 前面那行字

两个版本都会在 JSON 前面多打一行 `SDK macOS 26.5:`，但打在不同的流上：Xcode 26.6 打在 **stdout**，27.2 打在 **stderr**。`decodeJSON` 从 stdout 里第一个 `[` 或 `{` 开始解码。单个 SDK 和全部 SDK 打印的都是数组，但解码也接受单个对象（`SDKListJSON`），以防将来的版本改格式。

### 14. `-showdestinations` 是文本，按 26 和 27 两种标题解析

`-showdestinations` 没有 JSON 输出。传 `-json` 只会让它变安静：去掉开头的 "Command line invocation"，列表照样是文本。命令故意不传 `-json`，因为将来的 Xcode 如果给它加上真正的 JSON 输出，文本解析就会坏。

两个版本的段落标题不同，都取自 `IDEFoundation.framework` 的字符串：

| | Xcode 27 | Xcode 26 |
|---|---|---|
| 能用的 | `Destinations compatible with the "%@" scheme:` | `Available destinations for the "%@" scheme:` |
| 不能用的 | `Destinations incompatible with the "%@" scheme:` | `Ineligible destinations for the "%@" scheme:` |

每行的格式是 `{ key:value, key:value }`。值本身可以带 `,` 和 `:`，例如 `variant:Designed for [iPad,iPhone]` 和 `error:` 后面的提示文字。所以只有 `, ` 后面紧跟「字母数字组成的键加冒号」时，才切分成下一个属性。在已知段落之外出现 destination 行，说明格式变了，抛 `unexpectedOutput`；一行都没有则返回空列表。

### 15. destination 里的逗号没法转义

实测 Xcode 27.2：`-destination 'platform=macOS,variant=Designed for [iPad,iPhone]'` 报 `unreadable input 'iPhone]' at end of value for option 'Destination'`，在逗号前加反斜杠或给值加引号都一样。所以 `DestinationSpecifier` 不做转义，`DestinationDescription.specifier` 也照原样保留带逗号的值。如果悄悄丢掉这个键，会选中另一个 destination，这比 xcodebuild 明确报错更糟。

### 16. `-derivedDataPath` 必须配 scheme

`xcodebuild -list -json -derivedDataPath X` 报 `The flag -scheme, -testProductsPath, or -xctestrun is required when specifying -derivedDataPath.`，退出状态 64，而且每次用法错误都会往 TMPDIR 写一个 error result bundle。所以 `ListCommand` 不遵循 `DerivedDataLocating`。测试改用 user default `-IDECustomDerivedDataLocation=<目录>`，实测它能把 `-list` 解析包时写的 DerivedData 整个引到指定目录。

`ListCommand` 也没有包解析选项：没验证过 xcodebuild 在 `-list` 下是否接受它们，提供了却被拒绝，比不提供更糟。

### 17. 测试只走公开接口

解析测试不用 `@testable`：每个命令都通过公开的 `output(from:)` 喂录下来的输出，执行器测试通过公开的 `XcodeBuildTool` 跑假脚本。测试用的 `RecordingQuery`、`RecordingAction` 是普通的自定义命令，顺带验证了第三方也能自己写命令。

## 模块结构

```
Sources/XcodeBuild/
  Commands/
    XcodeBuildCommand.swift            三个命令协议；动作命令的默认 output(from:)
    CommandCapabilities.swift          18 个能力协议
    BuildCommand.swift                 10 个构建动作
    ProjectQueries.swift               -list、-showBuildSettings(ForIndex)、-showdestinations、-showTestPlans
    EnvironmentQueries.swift           -showsdks、-version（三种）、-find-*、-showComponent、首次启动与许可检查、-usage、-help
    ExportCommands.swift               -exportArchive、-exportNotarizedApp、本地化导出与导入
    PackageAndProjectCommands.swift    -resolvePackageDependencies、-create-xcframework、-convert-project
    InstallationCommands.swift         平台与组件的下载、导入、删除，-prepareDeviceSupport，-runFirstLaunch，-license accept
  Options/                             选项分组（测试、包解析、签名、sanitizer、代码体积）和取值类型
  Models/                              查询结果的模型；JSON 的解码类型；destination 文本解析
  Execution/
    XcodeBuildTool.swift               执行器的配置
    XcodeBuildTool+Run.swift           三个 run；@concurrent 解码
    Invocation.swift                   命令行、环境、teardown 序列、临时文件、错误映射；输出末尾的收集
    XcodeBuildOutput.swift             日志序列与 LineReader
    XcodeBuildCompletion.swift         命令拿到的运行结果；终止状态；动作的结果
    XcodeBuildError.swift              错误与可扩展的 Code
  DSL/
    XcodeBuildCommandBuilder.swift     builder、可复用的 content、组件协议
    ProjectComponents.swift            共享选项的组件
    PackageAndSigningComponents.swift  包解析与签名的组件
    BuildComponents.swift              BuildCommand 专用的组件
    CommandSpecificComponents.swift    其他命令专用的组件
Tests/
  XcodeBuildTests/                     见「验证」
  Fixtures/MinimalPackage/             最小 Swift package（一个库、一个测试 target）
  Fixtures/MinimalProject/             手写的最小 .xcodeproj（一个命令行工具 target）
  Fixtures/Outputs/Xcode-27.2|26.6/    实录的输出；设备名、设备 ID、本机路径和环境变量已替换或删除
```

## 与提案的差异

- **命令协议分成查询和动作两个子协议**（决策 1）。提案只写了一个 `XcodeBuildCommand`。
- **动作命令的结果统一是 `XcodeBuildSummary`**，只含命令行和耗时。提案写的是「完成信息（耗时、命令行、结果包与归档路径）」和「导出路径」，但这些路径就是调用方自己设的属性，回显它们没有增加信息。
- **`-license` 拆成 `AcceptLicenseCommand` 和 `CheckLicenseCommand`，不建模 `status`。** 提案写的是一个命令覆盖 accept、check、status。`status` 在本机的 Xcode 27.2 上静默退出 0，因为许可已接受，看不出它在未接受时的行为（决策 8）。
- **`-version` 是三个命令**：`VersionCommand`、`SDKVersionCommand`、`SDKVersionItemCommand`。提案写的是两个，单项值的结果类型是 `String`，与 SDK 列表不同，所以拆开。
- **`-usage` 和 `-help` 是两个命令。** 提案写的是一个。
- **查询的 stderr 完整收集**（决策 4）。提案写的是「stderr 只留末尾一段」。
- **`-showdestinations` 的两个列表叫 `compatible` 和 `incompatible`**，沿用 Xcode 27 的用词。提案写的是「可用 / 不可用」。
- **`ListCommand` 没有包解析选项**（决策 16）。
- **新增 `ShowBuildSettingsCommand.action`**（`-showBuildSettings` 的 scheme 动作参数）、对应的组件 `BuildSettingsAction`，以及可复用的 `XcodeBuildCommandContent`。
- **测试环境变量**：提案只说「用环境变量打开、DerivedData 目录可配置」，实际是三个：`SWIFT_XCODE_BUILD_TESTS_SKIP_REAL`、`SWIFT_XCODE_BUILD_TESTS_BUILD`、`SWIFT_XCODE_BUILD_TESTS_DERIVED_DATA`。

## 验证

89 个测试（Swift Testing），在 Xcode 27.2（Swift 6.4.2）和 Xcode 26.6（Swift 6.3.3）下各跑一遍，两次都开着构建测试，全部通过：

- `ArgumentRenderingTests`：每个命令每个选项的参数，期望值手写；destination specifier 的各种写法；`SettingAssignments` 的顺序与覆盖语义。
- `DSLTests`：91 个组件逐一与属性写法比较渲染结果，并断言组件确实改变了参数；控制流、`#available` 和共享 content。
- `OutputParsingTests`：两个 Xcode 版本的实录输出；退出状态的解释；格式不对时的 `unexpectedOutput`。
- `ExecutionTests`：用假的 xcodebuild 脚本测参数原样传递、环境变量、工作目录、日志合并与顺序、回车分行、提前返回、闭包抛错、取消的两种信号序列、输出上限、启动失败、临时 plist、闭包所在的 actor。
- `RealXcodeBuildTests` 与 `CoverageTests`：对真实 xcodebuild 做只读查询；解析本机 `xcodebuild -help` 和 `-create-xcframework -help`，确认每个选项都有命令能渲染，`-exportOptionsPlist` 的每个键都由 `ExportOptions` 写出。

## 已知降级

- 没有在 Swift 6.2 工具链（Xcode 26.0 到 26.3）上编译过，本机最旧的是 Xcode 26.6 的 Swift 6.3.3。用到的语言特性都是 6.2 就有的。
- 带逗号的 destination 值无法传给 xcodebuild（决策 15）。
- 真实 xcodebuild 每次以用法错误退出时，都会往 TMPDIR 写一个 error result bundle（`ResultBundle_<日期>.xcresult`），测试里的失败用例也不例外。这是 xcodebuild 自己的行为。
- `-license status` 没有建模。

## 后续工作

- 把构建、测试日志解析成结构化事件，需要另起提案。
- 真实 xcodebuild 的取消测试：现在取消只用假脚本测过，没有验证 xcodebuild 收到 `SIGINT` 后实际怎么收尾。

## 延伸阅读

- [使用指南](../Guides/RunningXcodeBuild.md)
- [术语表](../Glossary.md)
- swift-subprocess 1.0.2：`Sources/Subprocess/API.swift`（body 返回后关闭管道）、`Configuration.swift`（teardown 与隔离）
