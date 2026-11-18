# MATLAB + Simulink 通信仿真

这是一个面向 Codex/AI Agent 的可复用 Skill，用于自动检查、运行、出图、验证和解释 MATLAB/Simulink 通信系统仿真。项目采用配置驱动方式，内置经过验证的 16QAM 真实载波示例，同时为 QPSK、BPSK、64QAM、OFDM、FM 以及自定义 DSP 模型预留扩展接口。

英文检索关键词：MATLAB Simulink communications simulation automation, digital communications, 16QAM, BER, SER, signal processing, AI agent, Codex skill。

## 项目简介

它适合通信原理课程设计、实验室模型、教学演示和重复性仿真任务。用户可以用一句自然语言提出目标，AI 再根据工程配置完成模型发现、运行、批量出图、指标校验和结果解释。

## 核心能力

- discovers `.slx` models and MATLAB entry points without assuming a fixed user path;
- runs a selected model through MATLAB batch mode or the MATLAB/Simulink GUI;
- generates a stable set of time-domain, constellation, BER/SER, CSV, MAT, and report outputs;
- verifies dimensions, required files, BER/SER denominators, and finite-sample limits;
- explains the signal chain and figures in plain language for reports and oral defenses;
- keeps model-specific assumptions in adapters instead of hard-coding them into the core skill.

## 一句话使用

> 使用 MATLAB + Simulink 通信仿真，检查我的工程，运行选定模型，生成全部配置的结果图，验证 BER/SER，并解释输出。

For the supplied 16QAM example:

> 使用 MATLAB + Simulink 通信仿真，运行我的 16QAM Simulink 模型，生成八张完整结果图和 BER/SER 扫描，验证指标，并解释每个模块。

## 仓库结构

`SKILL.md` is the Codex entry point. `references/` contains workflow and domain guidance. `scripts/` contains deterministic discovery, execution, and output checks. `templates/` contains a portable JSON configuration. `examples/16qam/` documents the adapter contract without publishing a personal course model or absolute path.

## 快速开始

1. Copy `templates/run_config.json` and set `projectRoot`, `entryPoint`, and the output policy.
2. Discover the project:

   `powershell -File scripts/discover_project.ps1 -Root C:/path/to/project`

3. Preview the MATLAB command:

   `powershell -File scripts/run_workflow.ps1 -Config run_config.json -DryRun`

4. Run the verified project entry point:

   `powershell -File scripts/run_workflow.ps1 -Config run_config.json`

5. Verify the output directory:

   `powershell -File scripts/verify_outputs.ps1 -Directory C:/path/to/project/results`

运行模型需要安装 MATLAB 和 Simulink；若要通过窗口点击运行，还需要本机可用的 `agent-desktop` 能力。

## 16QAM 示例

The example uses 8000 bits, 2000 symbols, 4 bits per symbol, 2 kHz carrier, 10 kHz sample rate, 50 samples per symbol, Gray-coded levels `[-3,-1,1,3]/sqrt(10)`, coherent I/Q demodulation, rectangular matched filtering, and an Eb/N0 sweep of `0:2:20` dB. Read [examples/16qam/README.md](examples/16qam/README.md) and [references/16qam-reference.md](references/16qam-reference.md) for the adapter contract and figure meanings.

## 可进化与扩展

Add an adapter with a model or MATLAB entry point, a configuration file, an output manifest, a verification function, and a short reference. Keep the core modes unchanged. This makes a new modulation or channel a data/configuration addition instead of a rewrite of the skill.

## 安全

Never commit MATLAB license data, access tokens, passwords, local credentials, or machine-specific absolute paths. GitHub authentication should use `gh auth login`, a credential manager, or a short-lived environment mechanism outside the repository. Review `SECURITY.md` before publishing.

## 开源协议与贡献

This project is released under the MIT License. See [CONTRIBUTING.md](CONTRIBUTING.md) for adapter and documentation guidelines.

Useful search terms: `matlab`, `simulink`, `matlab automation`, `simulink automation`, `digital communications`, `16QAM`, `QAM`, `BER`, `SER`, `signal processing`, `simulation`, `AI agent`, `Codex skill`, and `desktop automation`.
