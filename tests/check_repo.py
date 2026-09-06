"""Offline TOC/XML, Lua syntax, and locale checks; no game or installed state access."""

import argparse
from pathlib import Path
import re
import subprocess
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
KEY = re.compile(r'L\["((?:\\.|[^"\\])*)"\]')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lua", required=True, help="Path to a Lua 5.1 executable")
    args = parser.parse_args()
    visited = set()

    def visit(path):
        path = path.resolve()
        assert path.is_relative_to(ROOT), f"Manifest escapes repository: {path}"
        assert path.is_file(), f"Missing packaged dependency: {path}"
        if path in visited:
            return
        visited.add(path)
        if path.suffix == ".xml":
            for element in ET.parse(path).iter():
                if "file" in element.attrib:
                    visit(path.parent / element.attrib["file"].replace("\\", "/"))

    for line in (ROOT / "ClassyMap.toc").read_text().splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            visit(ROOT / line.replace("\\", "/"))
    # The package uses an unquoted, literal-path ignore list (no glob patterns).
    package = (ROOT / ".pkgmeta").read_text()
    ignore_block = package.split("ignore:\n", 1)[1].split("\nmanual-changelog:", 1)[0]
    ignored = re.findall(r"^  - ([^\r\n]+)$", ignore_block, re.MULTILINE)
    for path in visited:
        relative = path.relative_to(ROOT).as_posix()
        assert not any(relative == item or relative.startswith(item + "/") for item in ignored), (
            f"Required dependency excluded from package: {relative}"
        )
    scripts = sorted(path for path in visited if path.suffix == ".lua")
    syntax = subprocess.run(
        [args.lua, "-e", 'for path in io.lines() do assert(loadfile(path)) end'],
        input="\n".join(path.as_posix() for path in scripts) + "\n",
        text=True,
        capture_output=True,
        check=False,
    )
    assert syntax.returncode == 0, syntax.stderr
    print(f"Manifest: {len(visited)} referenced files exist; {len(scripts)} Lua files compile")

    baseline = set(KEY.findall((ROOT / "Locales/enUS.lua").read_text(encoding="utf-8")))
    used = set()
    for path in [ROOT / "ClassyMap.lua", ROOT / "Settings.lua", ROOT / "Mechanic.lua"]:
        used.update(KEY.findall(path.read_text(encoding="utf-8")))
    assert not used - baseline, f"Missing English locale keys: {sorted(used - baseline)}"
    for path in sorted((ROOT / "Locales").glob("*.lua")):
        source = path.read_text(encoding="utf-8")
        keys = set(KEY.findall(source))
        assert not keys - baseline, f"Unknown locale keys in {path.name}: {keys - baseline}"
        assert 'if not L then' in source and source.index('if not L then') < source.index('L['), path
        print(f"Locale {path.stem}: {len(baseline - keys)} keys use English fallback")
    print(f"Localization: all {len(used)} used keys have English defaults")


if __name__ == "__main__":
    main()
