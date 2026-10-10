#!/usr/bin/env python3
"""Package missing pinned classic Proton runners and update the starter catalog."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

SOURCES = (
    ("GE-Proton10-10", "GE-Proton-10-10", "ge-proton",
     "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton10-10/GE-Proton10-10.tar.gz",
     "f508eff3a5900f86bc44d1a4e790bfb445b348a0298262d04e8696031c7ef470"),
    ("proton-EM-10.0-37-HDR", "proton-EM-10.0-37-HDR", "proton-em",
     "https://github.com/BananaWorks07/Proton/releases/download/EM-10.0-37-HDR/proton-EM-10.0-37-HDR.tar.xz",
     "5bfd81ceb423b365b547803d434fd5157defeae51160bbf6657265bc4340586d"),
    ("GE-Proton10-25", "GE-Proton-10-25", "ge-proton",
     "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton10-25/GE-Proton10-25.tar.gz",
     "b0e4a71cd8a6110a222934d5512725110c0e3b780f5f293d127a6d1eb9c8ba6d"),
    ("dwproton-11.0-14", "dwproton-11.0-14", "dw-proton",
     "https://github.com/dawn-winery/dwproton-mirror/releases/download/dwproton-11.0-14/dwproton-11.0-14-x86_64.tar.xz",
     "c563cc99d464fb19a767a0eb90dc723746bfcdd402a4fdaa0737b12af081f99a"),
)
ROOT = Path(__file__).resolve().parents[1]
TAG = "starter-pack-2026.10"
REPO = "Thomson67/batocera-wine-runners"


def sha256(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def main():
    output = ROOT / "dist"
    output.mkdir(exist_ok=True)
    catalog = json.loads((ROOT / "runners.json").read_text())
    additions = []
    existing = {runner["id"]: runner for runner in catalog["runners"]}
    for rid, name, family, url, expected in SOURCES:
        if rid in existing:
            runner = existing[rid]
            assert (runner["name"], runner.get("source_url"), runner.get("source_sha256")) == (name, url, expected), f"Existing source differs: {rid}"
            print(f"Preserved existing runner: {rid}", flush=True)
            continue
        with tempfile.TemporaryDirectory(prefix="uwt-classic-") as tmp:
            work = Path(tmp)
            archive = work / url.rsplit("/", 1)[1]
            cached = Path(os.environ.get("RUNNER_SOURCE_CACHE", "")) / archive.name
            if os.environ.get("RUNNER_SOURCE_CACHE") and cached.is_file():
                shutil.copyfile(cached, archive)
            else:
                subprocess.run(["curl", "-fL", "--retry", "3", "--connect-timeout", "20",
                                url, "-o", str(archive)], check=True)
            assert sha256(archive) == expected, f"Upstream checksum mismatch: {rid}"
            extracted = work / "extracted"
            extracted.mkdir()
            subprocess.run(["tar", "--no-same-owner", "-xf", str(archive),
                            "-C", str(extracted)], check=True)
            roots = list(extracted.iterdir())
            assert len(roots) == 1 and roots[0].is_dir(), f"Unexpected layout: {rid}"
            runner = roots[0]
            assert (runner / "files/bin/wine").is_file(), f"Missing Wine: {rid}"
            assert (runner / "files/bin/wineserver").is_file(), f"Missing WineServer: {rid}"
            # Batocera's classic launcher expects bin/ and lib*/wine at the root.
            # Keep Proton's original files intact; only add relative entry points.
            for folder in ("bin", "lib", "lib64", "lib32", "share"):
                target = runner / folder
                if (runner / "files" / folder).is_dir() and not os.path.lexists(target):
                    target.symlink_to("files/" + folder)
            payload = work / "payload"
            payload.mkdir()
            runner = runner.rename(payload / name)
            for binary in ("wine", "wineserver"):
                assert os.access(runner / "bin" / binary, os.X_OK), f"Missing executable: {rid}"
            provenance = {"source_url": url, "source_sha256": expected,
                          "launch_mode": "classic-wine", "umu": False}
            (runner / "uwt-source.json").write_text(json.dumps(provenance, indent=2) + "\n")
            filename = rid + ".tar.xz"
            destination = output / filename
            packed = work / filename
            subprocess.run(["tar", "--sort=name", "--mtime=2026-10-01 00:00:00Z",
                            "--owner=0", "--group=0", "--numeric-owner", "-cJf",
                            str(packed), "-C", str(payload), name], check=True,
                           env=dict(os.environ, XZ_OPT="-T2 -1"))
            subprocess.run(["xz", "-t", str(packed)], check=True)
            shutil.move(packed, destination)
            additions.append({"id": rid, "name": name, "file": filename, "family": family,
                              "size_bytes": destination.stat().st_size, "release_tag": TAG,
                              "download_url": f"https://github.com/{REPO}/releases/download/{TAG}/{filename}",
                              "sha256": sha256(destination), **provenance})
            print(f"Prepared {rid}: {destination.stat().st_size} bytes", flush=True)
    existing = {runner["id"]: runner for runner in catalog["runners"]}
    for runner in additions:
        if runner["id"] in existing:
            assert existing[runner["id"]] == runner, "Refusing to change an existing runner"
        else:
            catalog["runners"].append(runner)
    (ROOT / "runners.json").write_text(json.dumps(catalog, indent=2) + "\n")
    starter_path = ROOT / "starter-pack.json"
    starter = json.loads(starter_path.read_text())
    for rid, *_ in SOURCES:
        if rid not in starter["classic_runner_ids"]:
            starter["classic_runner_ids"].append(rid)
    starter_path.write_text(json.dumps(starter, indent=2) + "\n")
    (output / "SHA256SUMS.txt").write_text("".join(
        f"{runner['sha256']}  {runner['file']}\n" for runner in catalog["runners"]))


if __name__ == "__main__":
    main()
