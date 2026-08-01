"""Child process that runs ONE `sc doctor` under a described environment.

Usage: python3 qa_child.py <config.json>
Exits with doctor's own exit status; the report goes to fd 1 exactly as the real command
writes it (so streaming, flushing and the non-TTY contract are observed, not simulated).

Config keys (all optional except root/mode):
  mode        "doctor" | "main" | "status"
  root        sandbox root (repointed) or null → the REAL /etc/sing-box paths
  lang        "en" | "zh"
  systemd     bool (default false)   openrc bool (default false)
  argv        for mode=="main": the argv tail, e.g. ["doctor"]
  egress      null → real query; {"value": "..."} → stub; {"raise": "msg"} → stub raises
  clash       null → real call; {"answer": {...}} ; {"answer": null}
  sleep_s7    seconds the S7 probe sleeps before answering (AC-12 streaming)
  echo_file   path: S7 probe copies the capture file's current content to stderr first
"""
import json
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import qa_load  # noqa: E402  (installs the guards)

cfg = json.loads(open(sys.argv[1]).read())
_src = None
if os.environ.get("QA_MUTANT"):             # non-vacuity runs: a deliberately broken copy
    _src = open(os.environ["QA_MUTANT"]).read()
mod = qa_load.load(text=_src, real_init=True)   # we set the flags ourselves below
mod.SYSTEMD = bool(cfg.get("systemd", False))
mod.OPENRC = bool(cfg.get("openrc", False))
if cfg.get("root"):
    qa_load.repoint(mod, cfg["root"])
mod.LANG = cfg.get("lang", "en")

if cfg.get("egress") is not None:
    spec = cfg["egress"]
    if "raise" in spec:
        def _eg():
            raise OSError(spec["raise"])
    else:
        def _eg():
            return spec["value"]
    mod._egress_ip = _eg

if cfg.get("clash") is not None:
    ans = cfg["clash"]["answer"]
    mod.clash_api = lambda *a, **k: ans

if cfg.get("sleep_s7") or cfg.get("echo_file"):
    _inner = mod._doctor_egress

    def _slow():
        if cfg.get("echo_file"):
            try:
                with open(cfg["echo_file"], "rb") as fh:
                    sys.stderr.write("<<<SEEN-AT-S7>>>\n")
                    sys.stderr.write(fh.read().decode("utf-8", "replace"))
                    sys.stderr.write("<<<END>>>\n")
                    sys.stderr.flush()
            except Exception as e:
                sys.stderr.write("echo_file failed: %r\n" % (e,))
        if cfg.get("sleep_s7"):
            time.sleep(cfg["sleep_s7"])
        return _inner()
    mod._doctor_egress = _slow
    mod.DOCTOR_SECTIONS = tuple(
        (lbl, _slow if p is _inner else p) for lbl, p in mod.DOCTOR_SECTIONS)

mode = cfg.get("mode", "doctor")
if mode == "doctor":
    mod.cmd_doctor(None)
elif mode == "status":
    mod.cmd_status(None)
elif mode == "main":
    sys.argv = ["sc"] + cfg.get("argv", [])
    mod.main()
else:
    raise SystemExit("bad mode")
