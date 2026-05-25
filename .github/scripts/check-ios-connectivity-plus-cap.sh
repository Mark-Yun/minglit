#!/usr/bin/env bash
set -euo pipefail

MAX_EXCLUSIVE="${CONNECTIVITY_PLUS_MAX_EXCLUSIVE:-7.1.0}"

if [ "$#" -gt 0 ]; then
  PACKAGE_DIRS=("$@")
else
  PACKAGE_DIRS=(
    "apps/app_user"
    "apps/app_partner"
    "shared/packages/minglit_kit"
  )
fi

for package_dir in "${PACKAGE_DIRS[@]}"; do
  if [ ! -f "$package_dir/pubspec.yaml" ]; then
    echo "::error file=${package_dir}/pubspec.yaml::pubspec.yaml not found"
    exit 1
  fi

  deps_json="$(mktemp)"
  (cd "$package_dir" && dart pub deps --json) > "$deps_json"

  python3 - "$package_dir" "$MAX_EXCLUSIVE" "$deps_json" <<'PY'
import json
import sys

package_dir, max_exclusive, deps_json_path = sys.argv[1:]


def version_tuple(value: str) -> tuple[int, int, int]:
    core = value.split("-", 1)[0].split("+", 1)[0]
    parts = [int(part) for part in core.split(".")]
    return tuple((parts + [0, 0, 0])[:3])


with open(deps_json_path, encoding="utf-8") as deps_file:
    deps = json.load(deps_file)

package = next(
    (item for item in deps.get("packages", []) if item.get("name") == "connectivity_plus"),
    None,
)
if package is None:
    print(
        f"::error file={package_dir}/pubspec.yaml::connectivity_plus is not resolved; "
        "the iOS deploy guard cannot verify the dependency cap"
    )
    sys.exit(1)

version = package.get("version", "")
if version_tuple(version) >= version_tuple(max_exclusive):
    print(
        f"::error file={package_dir}/pubspec.yaml::connectivity_plus resolved to "
        f"{version}; keep it below {max_exclusive} until iOS deploy runners support "
        "the newer Network framework API used by 7.1.x"
    )
    sys.exit(1)

print(f"{package_dir}: connectivity_plus {version} < {max_exclusive}")
PY
  rm -f "$deps_json"
done
