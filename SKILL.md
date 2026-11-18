---
name: matlab-simulink-communications
description: Automate, inspect, verify, and explain MATLAB/Simulink communication-system simulations. Use when a user wants a model built or run, standard figures generated, BER/SER checked, or results explained. Supports configurable examples such as 16QAM and is designed to extend to other modulation and DSP workflows.
---

# MATLAB Simulink Communications

Use this skill for repeatable MATLAB/Simulink communication-system work. The skill is model-aware, but it must not assume the user's project lives at a fixed path or that every model is 16QAM.

## Choose an operating mode

- `inspect`: discover the project, identify `.slx` models and helper scripts, and report what can be run without editing files.
- `run`: execute the user's selected model or click-run copy and wait for completion.
- `generate-figures`: run the model's plotting/report helpers and collect the configured figure set.
- `verify`: check output files, dimensions, BER/SER metrics, and finite-sample limitations.
- `explain`: explain the signal chain, each block, and each figure in terms suitable for a course report or oral defense.
- `cleanup`: close duplicate MATLAB/Simulink windows or stale sessions only when the user explicitly requests it; do not delete result files.

## Project discovery and configuration

1. Read `references/workflow.md` for the output contract and configuration rules.
2. Prefer a user-supplied project root. Otherwise discover candidate folders using `scripts/discover_project.ps1` and ask only when multiple models are equally plausible.
3. Load `templates/run_config.json` and override only values the user specified. Keep model-specific details in the project folder or an example adapter.
4. Preserve the original model. If a run requires callbacks or temporary changes, use a copy and report its path.

## MATLAB and Simulink operation

- Use the MATLAB/Simulink GUI when the user asks for clicking, screenshots, or `agent-desktop` control. Read the `agent-desktop` skill before interacting with the desktop.
- Use `matlab -batch` or the project's existing `.m` entry point for deterministic verification when GUI interaction is not required.
- Reuse an existing MATLAB process when possible. Do not launch duplicate instances without a reason.
- Never change solver settings, model blocks, random seeds, or channel parameters merely to make a run pass. Inspect logs and model status first.

## Output contract

The active example declares its outputs in `run_config.json`. A complete communication run commonly includes:

- source or recovered bit timing plots;
- I/Q or passband time-domain waveforms;
- transmit and receive constellation plots;
- BER/SER versus Eb/N0 or SNR;
- a CSV/MAT result file and a plain-text verification report.

Treat a zero observed error count as a finite-sample result, not proof that the true BER is zero. Report the sample count with every BER/SER claim.

## Safety and reversibility

- Inspection is read-only.
- Before an authorized model edit, create a timestamped backup and name the target file.
- Do not overwrite the user's original `.slx` when a click-run or generated copy is sufficient.
- Do not delete unrelated files or close unrelated applications.
- Never put credentials, access tokens, or machine-specific absolute paths in source files, README text, logs, or Git history.

## References

- Read [references/workflow.md](references/workflow.md) for discovery, modes, configuration, and output validation.
- Read [references/16qam-reference.md](references/16qam-reference.md) when the active example is the real-passband Gray-coded 16QAM workflow.
- Read [references/troubleshooting.md](references/troubleshooting.md) after a failed run or missing output.
