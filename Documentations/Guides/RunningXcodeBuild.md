# 用 swift-xcode-build 运行 xcodebuild

> 把 xcodebuild 的每种用法当作类型化的命令值来构造、运行、取得结果。
> 所在模块：`XcodeBuild`。
> 配套提案：[xcodebuild 的 Swift 封装：初始设计](../Evolutions/0001-xcodebuild-wrapper-initial-design.md)。

面向**调用方**：怎么用、必须遵守什么、有哪些坑。内部实现见[实现说明](../Internal/XcodeBuildWrapperImplementation.md)，用词见[术语表](../Glossary.md)。

## 快速上手

```swift
import System
import XcodeBuild

let xcodebuild = XcodeBuildTool()

// 查询：结果解码成模型
let sdks = try await xcodebuild.run(.showSDKs)
let listing = try await xcodebuild.run(ListCommand(.workspace("App.xcworkspace")))

// 动作：边跑边读日志
let test = BuildCommand(.test) {
    Workspace("App.xcworkspace")
    Scheme("App")
    Destination(.simulator(.iOS, name: "iPhone 17 Pro"))
    OnlyTesting("AppTests/LoginTests")
}
try await xcodebuild.run(test) { output in
    for try await line in output {
        print(line.text)
    }
}
```

## 核心概念

- **命令是值。** xcodebuild 的每种用法对应一个命令类型（33 个），选项都是它的属性。命令可以存起来复用、改一个属性再跑，`arguments` 就是要传给 xcodebuild 的参数，可以直接打印或比较。
- **两类命令。** [查询命令](../Glossary.md#查询命令与动作命令)（`ListCommand`、`ShowSDKsCommand`……）把结果打印出来，`run(_:)` 收齐输出、解码后返回；[动作命令](../Glossary.md#查询命令与动作命令)（`BuildCommand`、导出、下载……）打印的是日志，`run(_:)` 等它结束、返回 `XcodeBuildSummary`，`run(_:body:)` 把日志逐行交给闭包。闭包版只对动作命令可用，传查询命令编译不过。
- **两种写法是同一个值。** DSL 的每个组件只是给同一个命令值设一个属性，参数渲染、执行和测试只有一条路径，两种写法可以混用：用 DSL 建好后再改属性。
- **[能力协议](../Glossary.md#能力协议)决定组件能用在哪。** 几个命令共用的选项各有一个协议（`SchemeSelecting`、`DestinationSelecting`……），组件以命令为泛型参数并要求这个协议；只属于一个命令的选项，组件直接绑定那个命令。用错时编译器指出原因：

  ```
  ListCommand { Scheme("App") }
  // error: generic struct 'Scheme' requires that 'ListCommand' conform to 'SchemeSelecting'

  ListCommand { TestPlan("Unit") }
  // error: static method 'buildExpression' requires the types 'ListCommand' and 'BuildCommand' be equivalent
  ```

- **执行器是值。** `XcodeBuildTool` 只保存怎么跑：可执行文件、Xcode、工作目录、环境变量、输出上限、取消的宽限期。要换个目录或换个 Xcode 跑，复制一份改属性即可。

## 调用方必须遵守的契约

**日志只在闭包运行期间有效。** `run(_:body:)` 交给闭包的 `XcodeBuildOutput` 背后是 xcodebuild 的管道，闭包返回后管道就关闭了。不要把它存下来，也不要交给别的任务（它不是 `Sendable`，编译器会拦）。它只能迭代一遍；再建一个迭代器会接着上一个停下的位置读。

**闭包提前返回，xcodebuild 照常跑完；闭包抛错，xcodebuild 会被停掉。**

- 提前 `break` 或 `return` 时，库读完并丢弃剩下的日志，等 xcodebuild 自己退出，所以 `run` 要等到构建结束才返回。
- 闭包抛错时，库按取消的信号序列停掉 xcodebuild，抛 `bodyFailed`，你的错误放在 `underlyingError` 里。
- 迭代日志本身抛出的 `XcodeBuildError` 原样抛出，不再包一层。

**取消时发三次信号，而且只发给 xcodebuild 本身。** 任务被取消时先发 `SIGINT`：xcodebuild 会取消构建、等它启动的编译任务结束，再打印 `** BUILD INTERRUPTED **`。之后按 `cancellationGracePeriods`（默认 10 秒和 5 秒）依次发 `SIGTERM`、`SIGKILL`，最后抛 `cancelled`。

- 信号不发给进程组。好处是你的进程被终端的 Control-C 打断时，xcodebuild 和你在同一个前台进程组里，会一起收到。代价是 xcodebuild 被 `SIGKILL` 时，它启动的编译器、测试 runner 不会跟着收到信号。所以宽限期别设得太短，要让 xcodebuild 有时间自己收尾。
- 如果取消送达之前 xcodebuild 已经成功结束，`run` 照常返回结果，不抛 `cancelled`。

**有两个命令把退出状态当答案。** `CheckFirstLaunchStatusCommand` 在退出状态为 69 时返回 `true`，表示需要跑 `RunFirstLaunchCommand`；`CheckLicenseCommand` 在退出状态为 69 时返回 `false`，表示许可协议没接受。这两个命令遇到别的非 0 状态照样抛 `commandFailed`。其余命令只要退出状态非 0 就抛错。69 是 `sysexits(3)` 里的 `EX_UNAVAILABLE`；xcodebuild 用它的还有 `-find-executable` 找不到工具的情况，那时它是错误。

**查询的输出有上限。** 查询的 stdout 和 stderr 都收集，上限是 `standardOutputLimit`，默认 64 MiB，超过就停掉 xcodebuild、抛 `outputLimitExceeded`。动作命令的日志不受限：它逐行流过，库只留最后 50 行，放进错误和 `XcodeBuildCompletion.outputTail`。`-help` 和 `-usage` 把文本写在 **stderr** 上，`HelpCommand` 和 `UsageCommand` 从那里取。

**`-derivedDataPath` 只能和 scheme 一起用。** xcodebuild 要求 `-derivedDataPath` 搭配 `-scheme`、`-xctestrun` 或 `-testProductsPath`，否则直接报用法错误（退出状态 64）。没有 scheme 的命令要把 DerivedData 放到别处时，比如对 Swift package 跑 `-list`（它会解析包并写 DerivedData），可以改用 user default：

```swift
ListCommand {
    UserDefaultOverride("IDECustomDerivedDataLocation", "/path/to/DerivedData")
}
```

这个值是 DerivedData 的根目录，xcodebuild 会在下面按项目建子目录。

**内联导出选项时，`arguments` 里是占位符。** `ExportArchiveCommand` 的 `exportOptions` 为 `.options(…)` 时，`arguments` 里 `-exportOptionsPlist` 后面跟的是 `ExportArchiveCommand.exportOptionsPlaceholder`（`<temporary ExportOptions.plist>`）。`XcodeBuildTool` 运行时把它换成一个临时 plist 的路径，xcodebuild 退出后删掉这个文件。如果你自己拿 `arguments` 去启动 xcodebuild，要先把选项写成文件、改用 `.propertyList(path)`。`ExportOptions.propertyList()` 可以给出 plist 内容。

**同一个设置写两次，后写的生效。** build settings 和 user defaults 都按命令行顺序渲染，xcodebuild 取最后一次赋值。两种写法的语义不同：DSL 组件 `BuildSetting`、`UserDefaultOverride` 总是**追加**一条赋值；属性写法的下标 `command.buildSettings["NAME"] = value` 会**替换**最后一次赋值，赋 `nil` 则删掉这个名字的所有赋值。`XcodeBuildTool.environment` 里的变量加在继承来的环境之上；库默认设置 `NSUnbufferedIO=YES`，让 xcodebuild 在管道里也逐行刷新输出。`developerDirectory` 优先于 `environment` 里的 `DEVELOPER_DIR`。

**只有 Xcode 27 才有的选项，旧版会拒绝。** 例如 `ConvertProjectCommand`（`-convert-project`）、`CodeSizeProfile`（`-enableCodesizeProfile`）、`DeleteComponentCommand` 与 `ShowComponentCommand` 的 `buildVersion`、`DownloadableComponent.deviceSupport`、`onlyTesting` 里以 `@` 开头的文件写法。库不判断运行的是哪个 Xcode，旧版 xcodebuild 会以用法错误退出。

**开了 `MemberImportVisibility` 的模块要 `import System`。** 路径类型是 System 框架的 `FilePath`。不导入 System，写 `"App.xcworkspace"` 这样的字符串字面量会报 `init(stringLiteral:)` 不可用。

## 深入

### 共享一组选项

用 `XcodeBuildCommandBuilder` 标一个属性或函数，返回 `XcodeBuildCommandContent`，就能在多个命令里复用：

```swift
@XcodeBuildCommandBuilder<BuildCommand>
var common: XcodeBuildCommandContent<BuildCommand> {
    Workspace("App.xcworkspace")
    Scheme("App")
    DerivedDataPath("build/DerivedData")
}

let build = BuildCommand(.build) { common }
let test = BuildCommand(.test) {
    common
    Destination(.simulator(.iOS, name: "iPhone 17 Pro"))
}
```

### 对任意命令设同一个选项

能力协议也可以用来写泛型代码：

```swift
func isolated<Command: DerivedDataLocating>(_ command: Command) -> Command {
    var command = command
    command.derivedDataPath = "/path/to/DerivedData"
    return command
}
```

### 选目标设备

`ShowDestinationsCommand` 的结果里，`DestinationDescription.specifier` 可以直接传回 `-destination`：通用设备（"Any iOS Device" 这类）变成 `generic/platform=…`，具体设备和模拟器按 `id` 选。

xcodebuild 在每个逗号处切分 destination specifier，反斜杠和引号都转义不了。在 Xcode 27.2 上实测，`variant=Designed for [iPad,iPhone]` 报 `unreadable input 'iPhone]'`。所以值里带逗号的 destination 选不中。`specifier` 照原样保留这个值，交给 xcodebuild 时会明确报错。不丢掉这个键，是因为丢掉后会悄悄选中另一个 destination。

### 写自己的命令

遵循 `XcodeBuildQueryCommand` 或 `XcodeBuildActionCommand`，给出 `arguments` 和 `output(from:)`。`output(from:)` 拿到的 `XcodeBuildCompletion` 带着退出状态、stdout、stderr 和最后几行输出；先调用 `requireSuccess()`，除非退出状态本身就是答案。动作命令的输出类型是 `XcodeBuildSummary` 时，`output(from:)` 有默认实现。

## 已知限制

- 构建和测试日志只给逐行文本，不解析成错误、警告、测试结果这样的结构化事件。
- `-license` 只支持 `accept` 和 `check`。不带子动作的 `-license` 会进入交互式分页器；`-license status` 的行为无法在许可已接受的机器上观察，没有建模。需要时可以写自己的命令。
- xcodebuild 未公开的选项（`-dry-run` 等）不建模，用 `additionalArguments`。
- `-showBuildSettingsForIndex` 的结果是 xcodebuild 打印的 JSON 原文。它的结构没有公开，而且随版本变化。

## 如何验证的

测试分五组：每个命令每个选项的参数渲染；91 个 DSL 组件逐一与属性写法对比；用 Xcode 27.2 和 26.6 实录的输出做解析测试；用假的 xcodebuild 脚本测流式日志、提前返回、闭包抛错、取消的信号顺序、输出上限、临时 plist；对真实 xcodebuild 做只读查询，并解析本机 `xcodebuild -help` 检查每个选项都有命令能渲染。构建测试用 `SWIFT_XCODE_BUILD_TESTS_BUILD=1` 打开。全部测试在 Xcode 27.2 和 26.6 下各跑过一遍。

## 延伸阅读

- [实现说明](../Internal/XcodeBuildWrapperImplementation.md)
- [术语表](../Glossary.md)
- `man xcodebuild`、`xcodebuild -help`
