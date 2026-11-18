# Agent Integration

This repository provides an agent-neutral workflow, not a vendor-specific plugin. It does not require a particular model provider, desktop connector, or orchestration runtime.

## Minimal contract

An AI assistant or automation host should:

1. read `SKILL.md` and the reference for the selected adapter;
2. create or update JSON configuration from `templates/run_config.json`;
3. call the discovery, run, and verification scripts, or implement equivalent shell calls;
4. report the output manifest, measured metrics, and finite-sample limitations.

The model project provides its own MATLAB entry point and plotting callbacks. This keeps the workflow portable across ChatGPT/Codex, Claude, Gemini, open-source agents, CI jobs, and manual use.

## Optional host capabilities

- Shell access supports discovery, MATLAB batch execution, and verification.
- File access supports reading the model project and result files.
- Desktop automation is optional and needed only for clicking MATLAB/Simulink or taking screenshots.
- MATLAB/Simulink is required to execute `.slx` models, not to read the workflow.

## Porting the scripts

The scripts use JSON configuration and a stable output contract. A non-Windows host can implement equivalent wrappers in Bash, Python, or Node.js without changing the domain references or result naming rules.
