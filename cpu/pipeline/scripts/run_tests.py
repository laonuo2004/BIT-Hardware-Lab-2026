"""Portable functional regression. Run from any directory; no Vivado required."""
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[3]
CPU = ROOT / "cpu"
PIPE = CPU / "pipeline"
CASES = [
    ("address_guard_tb", "ADDRESS_GUARD_PASS", "pipeline", [], False),
    ("fault_tb", "FAULT_PASS", "pipeline", [], False),
    ("cpu_sort_tb", "SORT_PASS", "single_cycle_baseline", [], False),
    ("decode_tb", "DECODE_PASS", "single_cycle_baseline", [], False),
    ("edge_cases_tb", "EDGE_CASES_PASS", "single_cycle_baseline", [], False),
    ("pipeline_sort_tb", "PIPE_SORT_PASS", "pipeline", [], False),
    ("hazard_tb", "HAZARD_PASS", "pipeline", [], False),
    ("immediate_logic_tb", "IMMEDIATE_LOGIC_PASS", "pipeline", [], False),
    ("isa_execute_tb", "ISA_EXECUTE_PASS", "pipeline", [], False),
    ("illegal_tb", "ILLEGAL_FLUSH_PASS", "pipeline", [], False),
    ("illegal_tb", "ILLEGAL_INSTRUCTION", "pipeline", ["+ILLEGAL"], True),
]

def run(argv, cwd):
    return subprocess.run(argv, cwd=cwd, text=True, capture_output=True, timeout=60)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path, default=PIPE / "build" / "regression")
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    records = []
    for number, (top, marker, group, flags, expected_error) in enumerate(CASES):
        name = f"{number:02d}_{top}" + ("_illegal" if expected_error else "")
        with tempfile.TemporaryDirectory(prefix="m3-sim-") as temp:
            work = Path(temp)
            for file in (CPU / group / "programs").glob("*.mem"):
                shutil.copyfile(file, work / file.name)
            sources = list((CPU / group / "src").glob("*.v"))
            command = ["iverilog", "-g2012", "-I", str(PIPE / "sim"), "-s", top,
                       "-o", str(work / "sim.vvp"), *map(str, sources), str(CPU / group / "sim" / f"{top}.v")]
            try:
                compiled = run(command, work)
                result = run(["vvp", str(work / "sim.vvp"), *flags], work) if compiled.returncode == 0 else compiled
                output = result.stdout + result.stderr
                passed = compiled.returncode == 0 and marker in output
                passed &= (result.returncode != 0) if expected_error else (result.returncode == 0 and not any(word in output for word in ["FAIL", "TIMEOUT", "WARNING", "ERROR"]))
                output = (compiled.stderr + output).replace(str(work), "<build>").replace(str(ROOT), "<repository>")
                (args.out / f"{name}.log").write_text(output)
            except (subprocess.TimeoutExpired, OSError) as error:
                passed = False
                (args.out / f"{name}.log").write_text(str(error))
            records.append({"name": name, "passed": bool(passed), "expected_error": expected_error})
            print(f"{'PASS' if passed else 'FAIL'} {name}", flush=True)
    report = {"revision": run(["git", "rev-parse", "HEAD"], ROOT).stdout.strip(),
              "working_tree": run(["git", "status", "--short"], ROOT).stdout,
              "tool": run(["iverilog", "-V"], ROOT).stdout.splitlines()[0], "cases": records}
    (args.out / "summary.json").write_text(json.dumps(report, indent=2, ensure_ascii=False)+"\n")
    failed = sum(not r["passed"] for r in records)
    print(f"{len(records)-failed}/{len(records)} passed")
    raise SystemExit(1 if failed else 0)

if __name__ == "__main__":
    main()
