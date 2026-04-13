#!/usr/bin/env python3
"""Assemble a native Linux package for the external .love workflow.

The package uses an official LOVE 11.5 Linux AppImage as the runtime, plus a
wrapper script that launches the external .love archive.
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import stat
import subprocess
import tempfile
import textwrap
import zipfile
from pathlib import Path

from package_release_candidate import collect_release_files, parse_version

APPIMAGE_NAMES = [
    "love.AppImage",
    "love-11.5-x86_64.AppImage",
    "love-11.5-linux-x86_64.AppImage",
]
APP_ICON_RELATIVE_PATH = "assets/app_icon_linux.png"

REQUIRED_EXTERNAL_PACKAGE_FILES = [
    "steam_bridge_native.so",
    "libsteam_api.so",
    "love_runtime/bin/love",
    "steam_input_manifest.vdf",
    "steam_input_generic_controller.vdf",
    "steam_input_neptune_controller.vdf",
    "steam_input_ps4_controller.vdf",
    "steam_input_ps5_controller.vdf",
    "steam_input_steam_controller.vdf",
    "steam_input_switch_pro_controller.vdf",
    "steam_input_xbox360_controller.vdf",
    "steam_input_xbox_controller.vdf",
    "steam_input_xboxelite_controller.vdf",
    "integrations/steam/redist/linux64/steam_bridge_native.so",
    "integrations/steam/redist/linux64/libsteam_api.so",
]

EXTERNAL_ROOT_FILES = {
    "steam_appid.txt",
    "steam_input_manifest.vdf",
}


def is_external_runtime_file(path: Path, source_root: Path) -> bool:
    rel = path.relative_to(source_root).as_posix()
    name = path.name
    if rel in {
        "integrations/steam/redist/linux64/steam_bridge_native.so",
        "integrations/steam/redist/linux64/libsteam_api.so",
    }:
        return True
    if name in EXTERNAL_ROOT_FILES:
        return True
    if name.startswith("steam_input") and name.endswith(".vdf"):
        return True
    return False


def pick_target_folder(parent: Path, base_name: str) -> Path:
    candidate = parent / base_name
    if not candidate.exists():
        return candidate
    suffix = 2
    while True:
        candidate = parent / f"{base_name}_{suffix}"
        if not candidate.exists():
            return candidate
        suffix += 1


def resolve_appimage(runtime_root: Path) -> Path:
    for name in APPIMAGE_NAMES:
        candidate = runtime_root / name
        if candidate.is_file():
            return candidate
    candidates = sorted(runtime_root.glob("*.AppImage"))
    if candidates:
        return candidates[0]
    raise SystemExit(
        "Linux runtime folder is missing an official LOVE 11.5 AppImage. "
        f"Expected one of: {', '.join(APPIMAGE_NAMES)}"
    )


def collect_source_file_sets(source_root: Path) -> tuple[set[Path], set[Path]]:
    runtime_files, _ = collect_release_files(source_root)
    beside_files = {p for p in runtime_files if is_external_runtime_file(p, source_root)}
    inside_files = runtime_files - beside_files
    return inside_files, beside_files


def build_love_archive_from_files(source_root: Path, files: set[Path], target_file: Path) -> None:
    target_file.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(target_file, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(files):
            if not path.is_file():
                continue
            archive.write(path, path.relative_to(source_root).as_posix())


def copy_selected_files(source_root: Path, target_root: Path, files: set[Path]) -> None:
    for path in sorted(files):
        relative = path.relative_to(source_root)
        dest = target_root / relative
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, dest)


def copy_root_steam_runtime_files(package_root: Path) -> None:
    redist_root = package_root / "integrations" / "steam" / "redist" / "linux64"
    runtime_files = {
        "steam_bridge_native.so": redist_root / "steam_bridge_native.so",
        "libsteam_api.so": redist_root / "libsteam_api.so",
    }
    for file_name, source in runtime_files.items():
        if not source.is_file():
            raise SystemExit(f"Missing Steam runtime file after copy: {source}")
        shutil.copy2(source, package_root / file_name)


def copy_linux_app_icon(source_root: Path, package_root: Path) -> bool:
    icon_source = source_root / APP_ICON_RELATIVE_PATH
    if not icon_source.is_file():
        return False
    shutil.copy2(icon_source, package_root / "MOM.png")
    return True


def chmod_plus_x(path: Path) -> None:
    current = path.stat().st_mode
    path.chmod(current | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


def extract_runtime_from_appimage(appimage: Path, package_root: Path) -> Path:
    runtime_root = package_root / "love_runtime"
    if runtime_root.exists():
        shutil.rmtree(runtime_root)

    chmod_plus_x(appimage)

    with tempfile.TemporaryDirectory(prefix="mom_love_extract_") as temp_dir:
        temp_path = Path(temp_dir)
        extracted_root = temp_path / "squashfs-root"
        try:
            subprocess.run(
                [str(appimage), "--appimage-extract"],
                cwd=temp_path,
                check=True,
                stdout=subprocess.DEVNULL,
            )
        except OSError as exc:
            if exc.errno != 8:
                raise
            seven_zip = shutil.which("7z")
            if not seven_zip:
                raise SystemExit(
                    "Failed to execute the Linux AppImage on this host, and no `7z` fallback is available for extraction."
                ) from exc
            extracted_root.mkdir(parents=True, exist_ok=True)
            subprocess.run(
                [seven_zip, "x", str(appimage), f"-o{extracted_root}"],
                cwd=temp_path,
                check=True,
                stdout=subprocess.DEVNULL,
            )
        except subprocess.CalledProcessError as exc:
            seven_zip = shutil.which("7z")
            if not seven_zip:
                raise
            extracted_root.mkdir(parents=True, exist_ok=True)
            subprocess.run(
                [seven_zip, "x", str(appimage), f"-o{extracted_root}"],
                cwd=temp_path,
                check=True,
                stdout=subprocess.DEVNULL,
            )
        if not extracted_root.is_dir():
            raise SystemExit(f"Failed to extract LOVE AppImage: {appimage}")
        shutil.copytree(extracted_root, runtime_root, copy_function=shutil.copy2)

    runtime_binary = runtime_root / "bin" / "love"
    if not runtime_binary.is_file():
        raise SystemExit(f"Extracted LOVE runtime missing binary: {runtime_binary}")
    chmod_plus_x(runtime_binary)
    return runtime_binary


def write_launcher(package_root: Path, launcher_name: str = "MOM.sh") -> Path:
    launcher = package_root / launcher_name
    launcher.write_text(
        textwrap.dedent(
            """\
            #!/bin/sh
            set -eu
            SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
            export LD_LIBRARY_PATH="$SCRIPT_DIR/integrations/steam/redist/linux64:${LD_LIBRARY_PATH:-}"
            APPID_FILE="$SCRIPT_DIR/steam_appid.txt"
            if [ -f "$APPID_FILE" ]; then
                APPID="$(tr -d '\\r\\n' < "$APPID_FILE")"
                if [ -n "$APPID" ]; then
                    export SteamAppId="$APPID"
                    export SteamGameId="$APPID"
                fi
            fi
            LOVE_RUNTIME_BIN="$SCRIPT_DIR/love_runtime/bin/love"
            cd "$SCRIPT_DIR"
            if [ -x "$LOVE_RUNTIME_BIN" ]; then
                exec "$LOVE_RUNTIME_BIN" "$SCRIPT_DIR/MeowOverMoo.love" "$@"
            fi
            exec "$SCRIPT_DIR/love.AppImage" "$SCRIPT_DIR/MeowOverMoo.love" "$@"
            """
        ),
        encoding="utf-8",
    )
    chmod_plus_x(launcher)
    return launcher


def write_desktop_entry(package_root: Path, include_icon: bool) -> Path:
    desktop_entry = package_root / "MOM.desktop"
    icon_line = "Icon=MOM" if include_icon else "Icon=love"
    desktop_entry.write_text(
        textwrap.dedent(
            f"""\
            [Desktop Entry]
            Type=Application
            Version=1.0
            Name=Meow Over Moo
            Comment=Launch Meow Over Moo
            Exec=MOM.sh
            {icon_line}
            Terminal=false
            Categories=Game;StrategyGame;
            StartupNotify=true
            """
        ),
        encoding="utf-8",
    )
    return desktop_entry


def validate_package_contents(package_root: Path, keep_steam_appid: bool) -> dict:
    required = [
        "MOM.sh",
        "MOM.desktop",
        "love.AppImage",
        "MeowOverMoo.love",
    ]
    required.extend(REQUIRED_EXTERNAL_PACKAGE_FILES)
    if keep_steam_appid:
        required.append("steam_appid.txt")
    if (package_root / "MOM.png").is_file():
        required.append("MOM.png")

    missing = []
    for relative in required:
        if not (package_root / relative).is_file():
            missing.append(relative)
    return {
        "required": required,
        "missing": missing,
        "ok": len(missing) == 0,
    }


def build_validation_report(validation: dict) -> str:
    lines = [
        "MeowOverMoo native Linux package validation",
        "",
        f"Status: {'OK' if validation['ok'] else 'FAILED'}",
        f"Required files checked: {len(validation['required'])}",
        f"Missing files: {len(validation['missing'])}",
        "",
    ]
    if validation["missing"]:
        lines.append("Missing files:")
        for relative in validation["missing"]:
            lines.append(f"- {relative}")
    else:
        lines.append("All required Linux runtime files are present.")
    lines.append("")
    return "\n".join(lines)


def build_upload_instructions(package_root: Path, keep_steam_appid: bool) -> str:
    steam_appid_note = (
        "steam_appid.txt is intentionally present for local testing. Remove it for the final Steam-distributed depot."
        if keep_steam_appid
        else "steam_appid.txt is intentionally absent for the Steam-distributed depot."
    )
    return textwrap.dedent(
        f"""\
        MeowOverMoo native Linux upload instructions

        1. Upload the extracted contents of the `game` folder as the Linux depot content root.
        2. Do not upload a zip archive as the SteamPipe content root.
        3. Set the launch option/executable to `MOM.sh` for the Linux depot.
        4. Verify the installed depot preserves executable bits for `MOM.sh` and `love.AppImage`.
        5. The package also includes `MOM.desktop` and `MOM.png` for native desktop shortcuts.
        6. {steam_appid_note}
        """
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build native Linux package using LOVE AppImage runtime.")
    parser.add_argument(
        "--source-project",
        default="/Users/mdc/Documents/New project/MeowOverMoo_LinuxNative",
        help="Source project folder.",
    )
    parser.add_argument(
        "--linux-runtime-dir",
        default="/Users/mdc/Documents/New project/MeowOverMoo_LinuxNative/LOVE_11_5_LINUX_RUNTIME_DROP",
        help="Folder containing the official LOVE 11.5 Linux AppImage.",
    )
    parser.add_argument(
        "--output-parent",
        default="/Users/mdc/Documents/New project",
        help="Parent folder where the Linux package folder will be created.",
    )
    parser.add_argument(
        "--strip-steam-appid",
        action="store_true",
        help="Remove steam_appid.txt from the final package.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    source_root = Path(args.source_project).resolve()
    runtime_root = Path(args.linux_runtime_dir).resolve()
    output_parent = Path(args.output_parent).resolve()

    if not source_root.is_dir():
        raise SystemExit(f"Source project not found: {source_root}")
    if not runtime_root.is_dir():
        raise SystemExit(f"Linux runtime folder not found: {runtime_root}")
    if not output_parent.is_dir():
        raise SystemExit(f"Output parent not found: {output_parent}")

    appimage = resolve_appimage(runtime_root)
    inside_files, external_files = collect_source_file_sets(source_root)

    version = parse_version(source_root)
    target_root = pick_target_folder(output_parent, f"{source_root.name}_LinuxPackage_{version}")
    package_root = target_root / "game"
    build_root = target_root / "_build"
    package_root.mkdir(parents=True, exist_ok=True)
    build_root.mkdir(parents=True, exist_ok=True)

    love_archive = build_root / "MeowOverMoo.love"
    build_love_archive_from_files(source_root, inside_files, love_archive)
    shutil.copy2(love_archive, package_root / "MeowOverMoo.love")

    shutil.copy2(appimage, package_root / "love.AppImage")
    chmod_plus_x(package_root / "love.AppImage")
    extract_runtime_from_appimage(appimage, package_root)
    write_launcher(package_root)
    has_icon = copy_linux_app_icon(source_root, package_root)
    write_desktop_entry(package_root, include_icon=has_icon)

    copy_selected_files(source_root, package_root, external_files)
    copy_root_steam_runtime_files(package_root)

    if args.strip_steam_appid:
        steam_appid = package_root / "steam_appid.txt"
        if steam_appid.exists():
            steam_appid.unlink()

    validation = validate_package_contents(package_root, keep_steam_appid=not args.strip_steam_appid)
    (target_root / "VALIDATION_REPORT.txt").write_text(build_validation_report(validation), encoding="utf-8")
    (target_root / "STEAM_UPLOAD_INSTRUCTIONS.txt").write_text(
        build_upload_instructions(target_root, keep_steam_appid=not args.strip_steam_appid),
        encoding="utf-8",
    )
    manifest = {
        "source": str(source_root),
        "runtime": str(appimage),
        "target": str(target_root),
        "inside_love_files": len(inside_files),
        "external_files": len(external_files),
        "linux_icon_included": has_icon,
        "steam_appid_included": not args.strip_steam_appid,
    }
    (target_root / "PACKAGE_MANIFEST.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    if not validation["ok"]:
        raise SystemExit("Linux package validation failed. See VALIDATION_REPORT.txt")

    print(str(target_root))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
