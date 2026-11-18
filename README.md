# MATLAB + Simulink 通信仿真

**让具备本地工具权限的 AI 智能体，通过一句话完成通信系统建模、运行、出图和解释。**

这是一个不绑定 AI 厂商的 Agent Skill：核心由开放的 `SKILL.md`、JSON 配置、Python 标准库工具和 MATLAB 源码组成。支持原生加载 Agent Skills 的宿主，也支持让其他智能体直接读取说明并调用脚本。无需 OpenAI SDK、云 API Key 或指定桌面控制软件。

> 请读取这个项目的 SKILL.md，用 MATLAB + Simulink 建立 16QAM 通信系统，运行仿真，生成全部八张结果图和系统图，验证误码率，并解释每张图。

## 当前能做什么

- **下载即可复现的 16QAM 示例**：从 MATLAB 源码自动生成真正的 `.slx` 模型，顶层展示标准模块和连线。
- **完整链路**：比特输入 → Gray 映射 → I/Q 正交载波调制 → AWGN → 相干解调 → 匹配滤波 → 判决 → BER/SER 统计。统计由适配器从 Simulink 导出的收发数据计算。
- **八张结果图 + 系统结构图**，另存可编辑 FIG、CSV、MAT、指标 JSON、运行日志和说明报告。
- **验证**：无噪声零误码、收发时序对齐、独立 Gray 判决对照、BER/SER 计数与分母核对、必需文件检查。
- **通用入口**：Python 标准库实现工程发现、运行、验证；不依赖某个智能体 SDK。
- **可扩展适配器**：新通信模型可复用配置、执行和验证流程。QPSK、BPSK、64QAM、OFDM、FM 属于后续扩展方向，当前没有宣称已经实现。

## 能否用于所有智能体？

设计目标是跨智能体使用，但不承诺所有产品都能自动安装或执行。宿主必须能读取本地文件、执行命令，并访问有合法许可的 MATLAB/Simulink。纯聊天窗口、没有本地工具的模型不能直接运行软件。

| 接入方式 | 使用方式 | 限制 |
|---|---|---|
| 原生 Agent Skills 宿主 | 按宿主文档安装包含 SKILL.md 的目录 | 自动发现路径和配置由宿主决定 |
| 通用 AI / 自建 Agent | 读取 SKILL.md，再调用 Python 命令 | 需要文件和命令工具 |
| 桌面操作智能体 | 使用用户选定的桌面连接器操作 MATLAB | 不强制使用 agent-desktop |
| 人工 / CI | 直接运行以下命令 | 不需要 AI |

`agents/openai.yaml` 仅是可选的宿主展示信息，删除它不会影响核心脚本。尚未逐一实测各品牌智能体的自动安装过程。详见 [跨智能体接入](AGENT_INTEGRATION.md)。

## 新旧 MATLAB 版本怎么适配？

不需要作者逐个安装旧版本。AI 每次在使用者自己的电脑上先执行 [SKILL.md 中的环境自检](SKILL.md)，读取版本与实际可用能力，再选择直接运行或在副本中适配。新版本也走同样流程，不使用固定屏幕坐标或臆测版本号判断。

遇到接口缺失时，例如 tiledlayout、exportgraphics 或 JSON 接口不可用，AI 按 [环境适配指南](references/environment-adaptation.md) 查询本机帮助并选择等价方式，完成小规模检查后再跑完整仿真。检测、适配和实际结果写入本地 environment-report.md。无需把使用者的环境上传到 GitHub。

**这些是技能驱动的适配规则，不是现有脚本已内置所有版本的自动回退。** Markdown 文件本身不会执行检查，需要有工具权限的 AI 实际按文档操作。现在实际验证的是 R2024b；其他版本需在目标机验证后确认，无法提前保证所有历史或未来版本。缺软件、许可或必要能力时会报告具体原因。

## 快速开始

准备 Python 3.10+、MATLAB 和 Simulink。示例采用基本 Simulink 模块，不调用 Communications Toolbox 函数。具体测试环境见 [验证记录](VALIDATION.md)，其他版本需自行验证。

```sh
git clone https://github.com/xiazhuo123456789/matlab-simulink-communications.git
cd matlab-simulink-communications
python scripts/workflow.py inspect examples/16qam
python scripts/workflow.py run --config examples/16qam/config.json --dry-run
python scripts/workflow.py run --config examples/16qam/config.json
python scripts/workflow.py verify --config examples/16qam/config.json
```

如果系统找不到 MATLAB，在运行命令末尾添加 `--matlab "MATLAB 可执行文件完整路径"`，或设置 `MATLAB_EXECUTABLE` 环境变量。

默认输出到 `examples/16qam/results/default/`。再次运行时，把配置中的 `outputs.directory` 改成一个新的目录名；工具拒绝复用已存在的输出目录，避免旧结果被误报为新仿真。运行期间可以查看该目录；Windows 下标准输出可能在 MATLAB 退出时才完整写入日志。

不想输入命令：在 MATLAB 文件浏览器中打开 `examples/16qam/run_example.m`，点击编辑器的运行按钮。此方式会在 `results/` 下创建带时间戳的新目录；图像文件和 FIG 可直接双击打开。

## 输出图说明

| 文件 | 表达的内容 |
|---|---|
| model.png / msc_16qam.slx | 顶层 Simulink 模块与通信流程 |
| 01_input_bits.png | 输入二进制比特和时间关系 |
| 02_tx_iq.png | 发送端 I/Q 四电平基带信号 |
| 03_carrier.png | 幅度、相位随符号变化的真实载波 |
| 04_tx_constellation.png | 理想 16 点星座，每点携带 4 bit |
| 05_rx_constellation.png | 带噪接收采样点与判决阈值 |
| 06_recovered_iq.png | 发送符号与匹配滤波采样值对比 |
| 07_recovered_bits.png | 恢复比特、误码位置和误码数量 |
| 08_ber_ser.png | Eb/N0 扫描的 BER/SER 与理论 BER 近似 |

默认 8000 bit、2000 symbol、200 Baud、2 kHz 载波、10 kHz 采样、10 dB 基准，扫描 `0:2:20 dB`。可配置比特数、Eb/N0、扫描点和随机种子；载波及采样参数暂固定，以保持矩形符号内载波正交条件。高信噪比下零观测误码不代表真实 BER 为零。

## 可进化、可扩展

为新模型增加一个独立目录，提供 `run_example.m`、`config.json`、输出清单和验证方法即可。入口通过 `MSC_CONFIG_FILE` 和 `MSC_OUTPUT_DIR` 传递配置和输出位置。详细契约见 [workflow.md](references/workflow.md)。

改进流程是“记录实际失败 → 添加可复现测试 → 修正适配器 → 更新验证记录”。工作流不会自行修改自身、联网下载代码或发布新版本；新能力需要开发、验证后合并。

## 成熟度与开源协议

这是可复现的开源教学与工程起点，**不宣称已经获得商用级可靠性认证**。MIT 许可允许按协议商用、修改与分发，但 MATLAB/Simulink 需要独立授权；生产使用仍需针对自身场景验证。当前质量复核、已验证能力和待补齐项见 [QUALITY.md](QUALITY.md)。

已提供 Python 自动化测试和 Windows/Linux/macOS 的 [CI 模板](templates/ci-checks.yml)。当前发布凭据无 workflow 权限，云端 CI 尚未启用；有相应权限的维护者可将模板复制到 `.github/workflows/checks.yml`。模板检查通用执行工具，不包含 MATLAB 许可或完整 MATLAB 仿真测试。详见 [VALIDATION.md](VALIDATION.md)、[CONTRIBUTING.md](CONTRIBUTING.md)、[SECURITY.md](SECURITY.md) 和 [资料来源](references/sources.md)。

检索关键词：MATLAB、Simulink、通信原理课程设计、通信系统仿真、自动建模、16QAM、星座图、误码率、BER、SER、Agent Skills、AI Agent、digital communications、signal processing。
