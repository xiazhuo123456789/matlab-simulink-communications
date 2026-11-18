# 设计依据与资料来源

查阅日期：2026-11-18。以下是接口设计依据，不是第三方对本仓库的认证。未复制第三方示例代码。

| 来源 | 用于本项目的设计决定 |
|---|---|
| [Agent Skills specification](https://agentskills.io/specification) | 使用 SKILL.md、name/description 前置元数据和按需读取的参考资料；核心不绑定特定宿主。 |
| [Anthropic skills](https://github.com/anthropics/skills) | 对照自包含技能目录及脚本/参考资料布局，避免依赖作者个人工程路径。 |
| [MathWorks sim](https://ww2.mathworks.cn/help/simulink/slref/sim.html) | 使用 SimulationInput 和 sim 运行仿真，针对基准和扫描传递模型工作区变量。 |
| [MathWorks add_block](https://ww2.mathworks.cn/help/simulink/slref/add_block.html) | 以程序化建模 API 添加真实 Simulink 模块，保留可见连接。 |
| [MathWorks run-command action](https://github.com/matlab-actions/run-command) | 了解 MATLAB CI 执行接口；当前 CI 模板仅覆盖 Python 测试，云端 CI 未启用，MATLAB 云 CI 未接入。 |
| [GitHub repository topics](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/classifying-your-repository-with-topics) | 用 matlab、simulink、agent-skills 等准确主题帮助发现，不承诺搜索排名。 |

MathWorks 英文站的部分抓取返回 403，改用可读取的 MathWorks 中文官方页面核对接口。规范和文档会变化，跨版本行为以真实运行和各宿主官方文档为准。
