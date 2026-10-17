# 术语表

本项目专有名词与约定用法。跨项目通用的术语收录在全局术语表（iCloud Global 镜像的 `Documentations/Glossary.md`），本表只收本项目特有的。

提案或文章引入新术语时，同批次登记进本表。

## 术语

### 查询命令与动作命令

命令的两种类别，各对应一个协议，决定执行器怎么处理 xcodebuild 的输出。

- **查询命令**（`XcodeBuildQueryCommand`）：结果打印在输出上，例如 `-list`、`-showsdks`、`-version`。执行器分别收集 stdout 和 stderr，再由命令解码。
- **动作命令**（`XcodeBuildActionCommand`）：输出是日志，例如构建、导出、下载。执行器把 stderr 合进 stdout，逐行交给闭包或丢弃，只留最后 50 行。

只有动作命令能用带闭包的 `run(_:body:)`。

- **主要出现在**：`Sources/XcodeBuild/Commands/XcodeBuildCommand.swift`、`Sources/XcodeBuild/Execution/XcodeBuildTool+Run.swift`
- **延伸阅读**：[使用指南](Guides/RunningXcodeBuild.md)、[实现说明](Internal/XcodeBuildWrapperImplementation.md) 决策 1、2

### 能力协议

声明「这个命令接受某组选项」的协议，例如 `SchemeSelecting`（`-scheme`）、`DestinationSelecting`（`-destination`）、`PackageResolutionConfigurable`（包解析选项），共 18 个。DSL 组件要求这些协议，所以用在不接受它的命令上会编译失败；也可以拿来写对任意命令都适用的泛型代码。只有一个命令接受的选项不设能力协议。

- **主要出现在**：`Sources/XcodeBuild/Commands/CommandCapabilities.swift`
- **不要混淆**：Swift 里一般意义上的 protocol conformance。这里专指这 18 个描述选项的协议。

### 组件

DSL 闭包里的一行，例如 `Scheme("App")`、`Destination(.generic(.iOS))`，作用是给命令值设一个选项。共享选项的组件以命令为泛型参数，由 builder 推断；单命令选项的组件直接绑定那个命令。`XcodeBuildCommandContent` 也是组件，用来复用一组选项。

- **主要出现在**：`Sources/XcodeBuild/DSL/`
- **不要混淆**：`DownloadableComponent`。它是 Xcode 的可选组件（Metal toolchain、device support），与 DSL 无关。

### Destination specifier

`-destination` 的参数：逗号分隔的 `key=value` 对，可带 `generic/` 前缀，例如 `platform=iOS Simulator,name=iPhone 17 Pro,OS=27.0`。xcodebuild 在每个逗号处切分，没有转义方式。类型是 `DestinationSpecifier`；`-showdestinations` 列出的条目是另一种格式（`{ key:value, … }`），类型是 `DestinationDescription`，它的 `specifier` 属性负责转换成前者。

- **主要出现在**：`Sources/XcodeBuild/Options/DestinationSpecifier.swift`、`Sources/XcodeBuild/Models/DestinationList.swift`

### User default 覆盖

xcodebuild 命令行上 `-NAME=value` 形式的参数，为这一次 xcodebuild 进程设置一个 user default，例如 `-IDECustomDerivedDataLocation=/path`。它和 build setting 的 `NAME=value` 只差一个前导短横线，作用完全不同。类型是 `SettingAssignments`，属性名是 `userDefaults`，组件是 `UserDefaultOverride`。

- **主要出现在**：`Sources/XcodeBuild/Options/SettingAssignments.swift`
- **延伸阅读**：[使用指南](Guides/RunningXcodeBuild.md)里 `-derivedDataPath` 那一条

### 宽限期

任务取消后，执行器每发一个信号要等多久才发下一个：`SIGINT` 之后等 `interrupt`（默认 10 秒）再发 `SIGTERM`，之后等 `terminate`（默认 5 秒）再发 `SIGKILL`。类型是 `CancellationGracePeriods`。

- **主要出现在**：`Sources/XcodeBuild/Execution/XcodeBuildTool.swift`、`Invocation.swift`
