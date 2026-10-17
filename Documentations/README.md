# Documentations

swift-xcode-build 的项目文档索引。

| 文档 | 说明 |
|------|------|
| [Evolutions/README.md](Evolutions/README.md) | 演进提案及其状态 |
| [Evolutions/0001-xcodebuild-wrapper-initial-design.md](Evolutions/0001-xcodebuild-wrapper-initial-design.md) | 初始设计：命令值类型 + 执行器、result builder DSL、覆盖范围、执行与取消语义、错误模型 |
| [Guides/RunningXcodeBuild.md](Guides/RunningXcodeBuild.md) | 使用指南：快速上手，以及日志的生命周期、取消的信号序列、退出状态即答案、输出上限、`-derivedDataPath` 与 scheme、导出选项占位符等从签名看不出的契约 |
| [Internal/XcodeBuildWrapperImplementation.md](Internal/XcodeBuildWrapperImplementation.md) | 实现说明：两类命令的执行方式、闭包返回后读完日志、DSL 机制的取舍与报错实测、xcodebuild 各版本的输出差异，以及与提案的差异 |
| [Glossary.md](Glossary.md) | 术语表：查询命令与动作命令、能力协议、组件、destination specifier、user default 覆盖、宽限期 |
