#!/usr/bin/env python3
"""Portable MATLAB workflow CLI. Python standard library only; no AI SDK."""
import argparse
import json
import math
import os
from pathlib import Path
import shutil
import subprocess
import sys


def read_config(path):
    path = Path(path).resolve(strict=True)
    cfg = json.loads(path.read_text(encoding='utf-8-sig'))
    if cfg.get('schemaVersion') != 1:
        raise ValueError('schemaVersion must be 1')
    root = (path.parent / Path(cfg.get('projectRoot') or '.')).resolve(strict=True)
    entry = (root / cfg['entryPoint']).resolve(strict=True)
    if not entry.is_relative_to(root):
        raise ValueError('entryPoint cannot escape projectRoot')
    if entry.suffix != '.m' or not entry.is_file():
        raise ValueError('entryPoint must identify a MATLAB .m script')
    output = (root / cfg['outputs']['directory']).resolve()
    required = cfg['outputs']['requiredFiles']
    if not isinstance(required, list) or not required:
        raise ValueError('outputs.requiredFiles must be a nonempty list')
    if not isinstance(cfg['outputs'].get('directory'), str) or not cfg['outputs']['directory']:
        raise ValueError('outputs.directory must be a nonempty path')
    for name in required:
        if not isinstance(name, str) or not name or Path(name).is_absolute():
            raise ValueError('requiredFiles must contain relative file paths')
        if not (output / name).resolve().is_relative_to(output):
            raise ValueError('requiredFiles cannot escape the output directory')
    timeout = cfg.get('timeoutSeconds', 1200)
    if type(timeout) not in (int, float) or not math.isfinite(timeout) or timeout <= 0:
        raise ValueError('timeoutSeconds must be finite and positive')
    return path, cfg, root, entry, output


def discover(root):
    root = Path(root).resolve(strict=True)
    excluded = {'.git', 'slprj', '__pycache__'}
    files = [p for p in root.rglob('*') if p.is_file() and
             not any(part in excluded for part in p.relative_to(root).parts)]
    return {'projectRoot': str(root),
            'models': sorted(str(p.relative_to(root)) for p in files if p.suffix == '.slx'),
            'matlabFiles': sorted(str(p.relative_to(root)) for p in files if p.suffix == '.m')}


def verify(output, required, metrics_file=None):
    output = Path(output).resolve()
    missing = []
    for name in required:
        target = (output / name).resolve()
        if not target.is_relative_to(output):
            raise ValueError('requiredFiles cannot escape the output directory')
        if not target.is_file() or target.stat().st_size == 0:
            missing.append(name)
    errors = []
    if metrics_file:
        target = (output / metrics_file).resolve()
        if not target.is_relative_to(output):
            raise ValueError('metricsFile cannot escape the output directory')
        try:
            metrics = json.loads(target.read_text(encoding='utf-8-sig'))
            for count, total, rate in [('bitErrors', 'bits', 'BER'), ('symbolErrors', 'symbols', 'SER')]:
                n, k, r = metrics[total], metrics[count], metrics[rate]
                if (type(n) is not int or type(k) is not int or n <= 0 or
                        k < 0 or k > n or type(r) not in (int, float) or
                        not math.isfinite(r) or not math.isclose(r, k/n, rel_tol=1e-9, abs_tol=1e-12)):
                    errors.append(f'Invalid {rate}: check counts and denominator')
            if metrics.get('noiselessBitErrors') != 0:
                errors.append('Noiseless verification did not pass')
        except (OSError, ValueError, KeyError, TypeError) as exc:
            errors.append(f'Metrics could not be verified: {exc}')
    return {'ok': not missing and not errors, 'directory': str(output), 'missing': missing, 'errors': errors}


def matlab_literal(value):
    value = str(value)
    if '\n' in value or '\r' in value:
        raise ValueError('MATLAB paths must not contain newlines')
    return "'" + value.replace("'", "''") + "'"


def execute(config_path, matlab=None, dry_run=False):
    path, cfg, root, entry, output = read_config(config_path)
    expr = f'cd({matlab_literal(root)}); run({matlab_literal(entry)});'
    executable = matlab or os.environ.get('MATLAB_EXECUTABLE') or shutil.which('matlab')
    if dry_run:
        return {'ok': True, 'command': [executable or 'matlab', '-batch', expr],
                'config': str(path), 'output': str(output)}
    if not executable:
        raise ValueError('MATLAB not found. Set MATLAB_EXECUTABLE or use --matlab.')
    # Refuse stale output so it cannot be mistaken for new successful output.
    output.mkdir(parents=True, exist_ok=False)
    env = dict(os.environ, MSC_CONFIG_FILE=str(path), MSC_OUTPUT_DIR=str(output))
    with (output / 'matlab.log').open('w', encoding='utf-8') as log:
        result = subprocess.run([executable, '-batch', expr], cwd=root, env=env,
                                stdout=log, stderr=subprocess.STDOUT,
                                timeout=cfg.get('timeoutSeconds', 1200), check=False)
    if result.returncode:
        raise RuntimeError(f'MATLAB exited with code {result.returncode}; see {output / "matlab.log"}')
    result = verify(output, cfg['outputs']['requiredFiles'], cfg['outputs'].get('metricsFile'))
    (output / 'verification.json').write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
    return result


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='action', required=True)
    inspect = sub.add_parser('inspect')
    inspect.add_argument('root')
    run = sub.add_parser('run')
    run.add_argument('--config', required=True)
    run.add_argument('--matlab')
    run.add_argument('--dry-run', action='store_true')
    check = sub.add_parser('verify')
    check.add_argument('--config', required=True)
    args = parser.parse_args(argv)
    try:
        if args.action == 'inspect':
            result = discover(args.root)
        elif args.action == 'run':
            result = execute(args.config, args.matlab, args.dry_run)
        else:
            _, cfg, _, _, output = read_config(args.config)
            result = verify(output, cfg['outputs']['requiredFiles'], cfg['outputs'].get('metricsFile'))
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0 if result.get('ok', True) else 2
    except (OSError, ValueError, KeyError, TypeError, RuntimeError, subprocess.TimeoutExpired) as exc:
        print(json.dumps({'ok': False, 'error': str(exc)}, ensure_ascii=False), file=sys.stderr)
        return 2


if __name__ == '__main__':
    sys.exit(main())
