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
