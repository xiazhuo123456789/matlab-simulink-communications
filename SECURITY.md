# Security

Do not put GitHub tokens, MATLAB license files, passwords, or local credential material in this repository. Use GitHub CLI authentication or a credential manager. If a token has ever been pasted into chat or a terminal command, revoke it and create a replacement with the smallest required scope after the upload is complete.

Configuration files point to executable MATLAB scripts. Inspect an unfamiliar project's entryPoint and callbacks before running them. The bundled example writes generated models, caches, logs, and plots under its output directory. The runner refuses to overwrite that directory; use a fresh directory for each run. Timeout handling preserves logs, but child MATLAB processes may need manual inspection before you retry.
