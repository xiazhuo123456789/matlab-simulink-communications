---
name: matlab-simulink-communications
description: Build, run, inspect and explain MATLAB/Simulink communication simulations with a portable agent-neutral workflow. Use for requests to generate real Simulink models, time-domain and constellation figures, BER/SER sweeps, or communication-course explanations. Includes executable real-passband 16QAM; other models need adapters.
license: MIT
metadata:
  compatibility: "Requires file and shell tools, Python 3.10+, and licensed local MATLAB/Simulink for execution. Desktop automation is optional; no particular AI vendor or SDK is required."
---

# MATLAB + Simulink Communications

Use the bundled Python/MATLAB source as a portable execution layer. Host-specific metadata in agents/openai.yaml is optional. Read [AGENT_INTEGRATION.md](AGENT_INTEGRATION.md) when connecting a new host. Never equate vendor-neutral design with tested compatibility on every AI product.

## Choose the task

- For a new 16QAM simulation, use examples/16qam/config.json and its executable MATLAB adapter. It generates an actual .slx model from visible standard blocks and derives plots from Simulink output.
- For an existing project, discover its entry points before choosing a runner; inspect unfamiliar callbacks/scripts before execution. Preserve the original project.
- For inspection only, use inspect and read files without simulating, editing or regenerating results.
- For explanations, read references/16qam-reference.md only when 16QAM applies, and explain actual model outputs rather than assumed results.
- For other modulations, implement or select an adapter; do not claim QPSK/OFDM/etc. are already bundled.

## 使用者电脑上的环境自检与适配（执行前必读）

每次进入新的电脑、MATLAB 安装或升级后的环境，由执行本技能的 AI 在目标电脑上检测。不要要求维护者安装历代 MATLAB，也不要仅根据版本号拒绝运行或宣称兼容。普通 Markdown 不会自动执行：宿主 AI 必须实际运行检查并依据结果采取行动。

1. 尊重用户选定的 MATLAB 安装；已有可调用会话优先。记录 MATLAB release、平台、Simulink 安装情况及所需接口。若缺少文件/执行权限，明确报告无法检测，不猜测环境。
2. 在目标 MATLAB 中执行下列只读探测；使用现有 MATLAB 工具连接器、命令窗口或可用启动方式。若命令行不支持 -batch，按本机帮助选择 -r/GUI；不要强行启动不支持的参数。不要打印许可编号、用户路径或环境变量全集。

```matlab
% MSC_ENVIRONMENT_PROBE_BEGIN
msc_env = struct;
msc_env.matlabVersion = version;
msc_env.release = version('-release');
msc_env.platform = computer;
msc_sl = ver('simulink');
msc_env.simulinkInstalled = ~isempty(msc_sl);
msc_env.simulinkLicenseListed = license('test','Simulink');
msc_env.simulationInputClass = exist('Simulink.SimulationInput','class') == 8;
msc_names = {'load_system','add_block','get_param','set_param','sim', ...
    'save_system','jsondecode','jsonencode','tiledlayout','nexttile', ...
    'exportgraphics','print','subplot','xline','yline','savefig'};
msc_env.functions = struct;
for msc_i = 1:numel(msc_names)
    msc_name = msc_names{msc_i};
    msc_env.functions.(msc_name) = ...
        exist(msc_name,'file') ~= 0 || exist(msc_name,'builtin') ~= 0;
end
disp(msc_env);
disp(msc_env.functions);
% MSC_ENVIRONMENT_PROBE_END
```

3. 探测结果只表示接口存在和许可条目可见，不证明许可可签出、参数兼容或仿真正确。检查当前适配器源码：脚本局部函数、隐式数组扩展、JSON、块库路径/参数也是依赖。必要时查询目标版本的 help/doc，并在独立工作副本中做小规模编译和仿真。
4. 能直接运行就运行；有具体不兼容项时，按照 [环境适配指南](references/environment-adaptation.md) 做最小等价修改，再实际验证。新增绘图接口可回退到 subplot/print 等本机可用接口；不改变通信参数、噪声标定、时序或误码统计来消除报错。不要修改已安装技能、原模型或用户全局 MATLAB 路径。
5. 先做无噪声检查和少量符号的带噪检查，再执行用户要求的完整配置。验收必须包含真实 Simulink 仿真、收发对齐、计数/分母核对和新生成的图像。仅成功打开软件、接口探测通过或代码不报语法错误，不算任务完成。
6. 在本地输出目录记录 environment-report.md：环境、可用能力、适配改动、实际执行命令、验证结果和剩余限制。可附只含必要环境信息的 MAT 文件；不自动上传用户环境。若需要用户升级、安装工具箱或获得许可，说明具体缺项；不私自安装软件。

当前只有记录过的 R2024b 仿真被实测。其他新旧版本属于“目标机检测 → 必要适配 → 验证后确认”，不是预先承诺全部版本可用。GUI 布局变化时重新观察控件，不复用历史坐标。

## Run and verify

Resolve scripts relative to this skill directory, not the caller current directory. Read [references/workflow.md](references/workflow.md) when selecting or changing configuration.

```sh
python scripts/workflow.py inspect examples/16qam
python scripts/workflow.py run --config examples/16qam/config.json --dry-run
python scripts/workflow.py run --config examples/16qam/config.json
python scripts/workflow.py verify --config examples/16qam/config.json
```

Before running, choose a new output directory; existing output directories are deliberately rejected. Working configurations resolve projectRoot relative to their file and entryPoint relative to projectRoot. MATLAB receives MSC_CONFIG_FILE and MSC_OUTPUT_DIR. Arbitrary third-party scripts must explicitly consume that contract.

A successful MATLAB exit is insufficient: inspect verification.json, measured metrics and required outputs. The 16QAM adapter checks noiseless errors, sample alignment and independent Gray decoding. Keep bit/symbol counts with every rate. The historical 14/8000 baseline is evidence for one fixed-seed configuration, not a universal acceptance rule. Never adjust seeds or channel parameters merely to force that number.

On failure, read the log and [references/troubleshooting.md](references/troubleshooting.md). Preserve evidence. After two failed attempts with the same cause, report that cause and the needed capability/data instead of repeatedly rebuilding.

## GUI and results

Honor the user-selected desktop backend; agent-desktop is one optional choice. Read its instructions only when actually selected. Do not require desktop control for batch execution. For click-only use, open examples/16qam/run_example.m in MATLAB and run it; it creates a timestamped output folder. Figures are saved as PNG and FIG. To display them, open those outputs; batch figure windows need not remain open.

The bundled output set is eight result figures plus the model diagram, model, CSV, MAT, JSON metrics and report. Distinguish the structure diagram from runtime figures. Do not hard-code this count for unrelated models. Check files exist before linking them.

## Scope and evolution

Keep authorized model edits in a generated copy or back up an existing target first. Preserve user modifications and original course files. Cleanup applies only to requested duplicate windows or task-owned processes, never unrelated apps.

For extensions follow the adapter contract and add evidence of actual execution. Keep new assumptions in the adapter. Read [CONTRIBUTING.md](CONTRIBUTING.md) for improvement and testing. The skill does not silently rewrite itself or publish changes during ordinary simulations.

Report platform and MATLAB release tested, untested host integrations, scientific limitations and any missing capability. Do not claim commercial certification or production readiness from syntax checks alone.
