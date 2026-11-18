# Reusable Workflow

## Configuration

Use a small JSON file rather than hard-coded paths. The minimum useful fields are:

```json
{
  "projectRoot": "C:/path/to/project",
  "model": "my_model.slx",
  "entryPoint": "run_simulation.m",
  "mode": "full",
  "metrics": {"ebN0Db": 10, "bits": 8000},
  "outputs": {"directory": "results", "figures": ["time", "constellation", "ber"]}
}
```

`projectRoot` may be omitted when the caller already supplies the working directory. Paths are resolved relative to that root. Do not encode a single user's Windows path in a reusable script.

## Run modes

`inspect` discovers `.slx`, `.m`, `.mat`, `.csv`, and existing figure outputs. It must not execute or edit the model.

`run` opens or invokes the configured model. A project-specific entry point is preferred because it can set workspace variables, callbacks, and logging consistently.

`generate-figures` runs only the plotting/report stage when result data already exists. It should not silently re-run a long Eb/N0 sweep.

`verify` checks that expected files exist, result arrays have matching lengths, BER/SER values are within `[0,1]`, and the report records the number of transmitted bits and symbols.

`explain` maps each visible block to a signal-processing operation and distinguishes measured values from theoretical curves.

## Output contract

An adapter should write:

- PNG figures for presentation;
- optional MATLAB `.fig` files for later editing;
- CSV for tabular BER/SER data;
- MAT for reproducible result data;
- a text or Markdown report containing parameters, run time, and verification status.

Names should be stable and descriptive, for example `01_input_bits.png`, `04_tx_constellation.png`, and `08_ber_ser.png`.

## Adapter design

Keep the core skill model-agnostic. Put assumptions such as Gray mapping, carrier frequency, pulse shape, or known symbol timing in an example adapter. New adapters can target QPSK, BPSK, 64QAM, OFDM, FM, or custom laboratory models without changing the core entry point.

Each adapter should expose:

1. a model or MATLAB entry point;
2. a configuration file;
3. an output manifest;
4. a verification function;
5. a short explanation reference.

## GUI behavior

When desktop control is requested, observe the current state first, restore minimized windows, act on one MATLAB instance, and verify the model status and output folder after clicking Run. Leave the requested model open, but close only explicitly requested duplicate windows.
