"""Re-run the reviewed CPU revision without changing the checkout."""
from pathlib import Path
import argparse
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
parser = argparse.ArgumentParser()
parser.add_argument("--ref", default="129cf29")
args = parser.parse_args()

def call(argv, cwd=ROOT):
    return subprocess.run(argv, cwd=cwd, capture_output=True, text=True, timeout=30)

revision = call(["git", "rev-parse", args.ref]).stdout.strip()
if not revision:
    raise SystemExit("Cannot resolve revision")
print("revision:", revision)
print(call(["iverilog", "-V"]).stdout.splitlines()[0])
failures = 0
with tempfile.TemporaryDirectory(prefix="bit-cpu-review-") as temporary:
    work = Path(temporary)
    listing = call(["git", "-c", "core.quotePath=false", "ls-tree", "-r", "--name-only", revision, "cpu"]).stdout.splitlines()
    for name in listing:
        contents = call(["git", "show", f"{revision}:{name}"])
        if contents.returncode:
            raise RuntimeError(contents.stderr)
        dest = work / name
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(contents.stdout)
    cases = [
        ("single_cycle_baseline", "cpu_sort_tb", "SORT_PASS"),
        ("single_cycle_baseline", "decode_tb", "DECODE_PASS"),
        ("single_cycle_baseline", "edge_cases_tb", "EDGE_CASES_PASS"),
        ("pipeline", "pipeline_sort_tb", "PIPE_SORT_PASS"),
        ("pipeline", "hazard_tb", "HAZARD_PASS"),
        ("pipeline", "review_tb", "IMMEDIATE_LOGIC_PASS"),
    ]
    for kind, top, marker in cases:
        base = work / "cpu" / kind
        source = base / "src" / ("Top.v" if kind == "single_cycle_baseline" else "pipeline_cpu.v")
        bench = HERE / "immediate_logic_tb.v" if top == "review_tb" else base / "sim" / f"{top}.v"
        executable = work / f"{top}.vvp"
        compile_result = call(["iverilog", "-g2012", "-s", top, "-o", str(executable), str(source), str(bench)])
        result = call(["vvp", str(executable)], base / "programs") if compile_result.returncode == 0 else compile_result
        output = result.stdout + result.stderr
        passed = result.returncode == 0 and marker in output and "FAIL" not in output and "TIMEOUT" not in output
        failures += int(not passed)
        print(f"\n{top}: {'PASS' if passed else 'FAIL'} (exit={result.returncode})")
        print(output.replace(str(work), "<temporary-checkout>").replace(str(ROOT), "<repository>"), end="")
print(f"\nfailed_cases={failures}")
raise SystemExit(1 if failures else 0)
