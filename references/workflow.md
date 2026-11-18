# Workflow contract v1

The canonical runner is scripts/workflow.py (Python 3.10+, standard library). It needs no AI SDK, network service, API token, or GUI connector. A licensed local MATLAB/Simulink is needed for actual simulations.

## Configuration

Use examples/16qam/config.json as a working example. Required fields:

- schemaVersion: 1. Unknown schema versions fail.
- projectRoot: directory relative to the config file, or an absolute local path; defaults to the config directory.
- entryPoint: MATLAB .m script relative to projectRoot. This is executable project code: inspect it before executing an unfamiliar project.
- timeoutSeconds: positive finite limit for the process (default 1200).
- outputs.directory: relative to projectRoot or absolute; must not exist before a CLI run.
- outputs.requiredFiles: nonempty list of nonempty files to verify; paths cannot escape the output directory.
- outputs.metricsFile: optional relative JSON path for numeric metric checks.
- parameters: adapter-specific values. The core passes these through; only the adapter consumes them. Do not imply arbitrary values affect a model that ignores them.

The built-in adapter consumes bits (64..4000000, multiple of four), ebN0Db, increasing sweepDb (at least two points), bitSeed and noiseSeed. It fixes carrier/symbol/sample rates and rectangular pulse shaping. Other adapters declare their own parameters.

## Execution

The runner passes absolute MSC_CONFIG_FILE and MSC_OUTPUT_DIR environment variables to MATLAB. An adapter reads them with getenv, jsondecode and fileread, then writes its declared outputs. No user course model is modified by the bundled example.

The MATLAB executable is chosen using --matlab, then MATLAB_EXECUTABLE, then PATH. A fresh output directory is created before starting MATLAB. Errors and timeouts return a failure and preserve logs. On a timeout, inspect the launched process before retrying; platform-specific child process cleanup is not guaranteed.

The Python verifier checks files are nonempty. When metricsFile is set, it additionally checks integer bit/symbol counts, finite rates, exact rate/count consistency within numeric tolerance, and noiselessBitErrors=0. It cannot infer the scientific validity of arbitrary third-party models.

## Modes

inspect is read-only; run builds/runs the configured adapter; verify checks existing output without a new simulation. explain and GUI cleanup are agent workflows, not CLI subcommands. To generate figures without a simulation, use an adapter-specific plotting function and previously saved data. No generic plot-only command is claimed.

## Extension and evolution

Add a model adapter with executable MATLAB source, example configuration, an explicit output manifest, independent scientific checks, and a reference explaining assumptions. Share no hidden caller workspace. Record supported MATLAB releases and toolboxes after tests.

For each improvement: reproduce a real failure, add a test where useful, change the narrow affected component, rerun validation, document remaining limitations, then submit a pull request. Increment schemaVersion for incompatible configuration changes. Do not claim planned modulations are implemented.
