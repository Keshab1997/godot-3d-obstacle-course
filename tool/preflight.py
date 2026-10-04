#!/usr/bin/env python3
"""Lightweight project checks to run before pushing Neon Trail changes."""

from __future__ import annotations

import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ERRORS: list[str] = []


def require(condition: bool, message: str) -> None:
    if condition:
        print(f"PASS: {message}")
    else:
        ERRORS.append(message)
        print(f"FAIL: {message}")


def git_tracked_paths() -> list[str]:
    result = subprocess.run(
        ["git", "ls-files", "-z"],
        cwd=ROOT,
        check=True,
        stdout=subprocess.PIPE,
    )
    return [item.decode("utf-8", errors="replace") for item in result.stdout.split(b"\0") if item]


def check_git_whitespace() -> None:
    for args in (["git", "diff", "--check"], ["git", "diff", "--cached", "--check"]):
        result = subprocess.run(args, cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        require(result.returncode == 0, f"{' '.join(args)}")
        if result.stdout.strip():
            print(result.stdout.rstrip())


def check_secrets(paths: list[str]) -> None:
    forbidden_names = {".env", ".env.local", ".env.production", "google-services.json", "google-service-info.plist"}
    forbidden_suffixes = {".jks", ".keystore", ".p12", ".pfx", ".pem"}
    token_patterns = (
        re.compile(rb"-----BEGIN (?:OPENSSH |RSA |EC |DSA )?PRIVATE KEY-----"),
        re.compile(rb"\bgh[pousr]_[A-Za-z0-9_]{20,}\b"),
        re.compile(rb"\bgithub_pat_[A-Za-z0-9_]{20,}\b"),
        re.compile(rb"\bAKIA[0-9A-Z]{16}\b"),
    )
    issues: list[str] = []
    for relative_path in paths:
        path = Path(relative_path)
        if path.name.lower() in forbidden_names or path.suffix.lower() in forbidden_suffixes:
            issues.append(f"sensitive file is tracked: {relative_path}")
            continue
        file_path = ROOT / path
        try:
            data = file_path.read_bytes()
        except OSError:
            continue
        if any(pattern.search(data) for pattern in token_patterns):
            issues.append(f"possible credential material in: {relative_path}")
    require(not issues, "tracked files contain no keystores, service configs, or recognized credentials")
    for issue in issues:
        print(f"  {issue}")


def check_project_files() -> None:
    required = (
        "project.godot",
        "scenes/main.tscn",
        "scripts/game.gd",
        "scripts/player.gd",
        "export_presets.cfg",
        ".github/workflows/web-preview.yml",
        ".github/workflows/android-build.yml",
        "README.md",
        ".gitignore",
        "scripts/install_godot.sh",
        "tool/preflight.py",
    )
    missing = [name for name in required if not (ROOT / name).is_file()]
    require(not missing, "required game and workflow files are present")
    for name in missing:
        print(f"  missing: {name}")
    if missing:
        return

    project = (ROOT / "project.godot").read_text(encoding="utf-8")
    scene = (ROOT / "scenes/main.tscn").read_text(encoding="utf-8")
    game = (ROOT / "scripts/game.gd").read_text(encoding="utf-8")
    web_workflow = (ROOT / ".github/workflows/web-preview.yml").read_text(encoding="utf-8")
    android_workflow = (ROOT / ".github/workflows/android-build.yml").read_text(encoding="utf-8")
    presets = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")

    require('run/main_scene="res://scenes/main.tscn"' in project, "main scene is configured")
    require('path="res://scripts/game.gd"' in scene, "main scene references the game controller")
    require("func _finish(won: bool)" in game, "game controller includes end-of-course handling")
    require('name="Web"' in presets and 'name="Android APK"' in presets and 'name="Android AAB"' in presets, "Web, APK, and AAB export presets exist")
    require("workflow_dispatch:" in web_workflow and "workflow_dispatch:" in android_workflow, "web and Android workflows are manually triggered")
    require("--export-release \"Web\"" in web_workflow, "web workflow exports the Web preset")
    require("--export-debug \"Android APK\"" in android_workflow and "--export-release \"Android AAB\"" in android_workflow, "Android workflow exports APK and AAB presets")

    release_keys = re.findall(r"(?m)^keystore/release(?:_user|_password)?=(.*)$", presets)
    require(bool(release_keys) and all(value.strip().strip('"') == "" for value in release_keys), "release keystore values remain blank in the repository")


def check_godot() -> None:
    godot = os.environ.get("GODOT_BIN") or shutil.which("godot") or shutil.which("godot4")
    if not godot:
        print("SKIP: Godot not found; set GODOT_BIN to run the headless project scan")
        return
    command = [godot, "--headless", "--editor", "--path", str(ROOT), "--quit"]
    result = subprocess.run(command, cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if result.returncode == 0:
        print("PASS: Godot headless editor scan")
    else:
        ERRORS.append("Godot headless editor scan")
        print("FAIL: Godot headless editor scan")
        print("\n".join(result.stdout.splitlines()[-40:]))


def main() -> int:
    os.chdir(ROOT)
    check_project_files()
    check_git_whitespace()
    try:
        check_secrets(git_tracked_paths())
    except subprocess.CalledProcessError as error:
        ERRORS.append("could not inspect Git-tracked files")
        print(f"FAIL: could not inspect Git-tracked files ({error})")
    check_godot()
    if ERRORS:
        print(f"Preflight failed: {len(ERRORS)} issue(s).")
        return 1
    print("Preflight passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
