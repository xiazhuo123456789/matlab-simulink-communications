# Troubleshooting

## No model is discovered

Confirm the project root, search recursively for `.slx`, and check that the file is not only an autosave or lock file. If several models exist, select the intended model explicitly.

## MATLAB opens but the run does not finish

Read the Command Window or batch log first. Check missing paths, model callbacks, workspace variables, solver errors, and stale `slprj` data. Do not change communication parameters as a first response.

## Figures are missing

Separate simulation from plotting. Look for the result `.mat`/`.csv` file and run the plotting entry point only if data exists. Check that the plotting script writes to the configured output directory.

## BER/SER looks wrong

Verify bit ordering, Gray mapping, samples per symbol, carrier sign convention, noise scaling, and the denominator used for BER (`bit errors / transmitted bits`) and SER (`symbol errors / transmitted symbols`). Record the sample count beside every metric.

## GUI has duplicate windows

Inspect all MATLAB processes and windows. Close only duplicates when the user asks for cleanup. Keep the selected model and its result figures available.
