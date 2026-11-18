# 跨智能体接入

核心工作流无需某个 AI 厂商的 API 或桌面连接器。兼容性指“可以通过开放文件和命令契约接入”，不等于所有产品的自动发现或插件安装方式相同。

## 能力协商

1. 确定宿主能读取文件、运行 Python 命令，并能访问有许可的 MATLAB/Simulink。没有执行能力时明确说明限制，不声称已经生成仿真结果。
2. 读取 SKILL.md，在使用者电脑上执行其中的环境探测；只按需加载相关参考资料。不要求维护者安装各历史版本，也不跳过新版本的实测。
3. 选择内置示例或用户已有工程，填写 JSON 配置。
4. 运行 scripts/workflow.py，并依据退出码、verification.json 和实际输出汇报结果。

原生 Agent Skills 宿主可按各自官方安装方式加载整个目录。其他智能体可由用户指定仓库路径，要求其读取 SKILL.md 并使用命令行工具。不要臆测不同宿主的安装路径。

## 稳定工具接口

```sh
python scripts/workflow.py inspect PROJECT_DIRECTORY
python scripts/workflow.py run --config CONFIG_PATH --dry-run
python scripts/workflow.py run --config CONFIG_PATH
python scripts/workflow.py verify --config CONFIG_PATH
```

标准输出为 JSON；错误输出也是 JSON。退出码 0 表示成功，2 表示配置、运行或验证失败。调用方应保留失败日志，避免无界重试。脚本使用参数数组启动 MATLAB，不拼接 Shell 命令。

GUI 模式使用用户已经选定的桌面工具。只有明确要求 agent-desktop 时才选择它；其他桌面工具、MATLAB 工具连接器或批处理方式均可按能力适配。

宿主名称只用于说明接入方向，尚未分别认证各品牌 AI 的行为。Windows/Linux/macOS 上的 Python 工具测试与真实 MATLAB 仿真验证应分别记录。
