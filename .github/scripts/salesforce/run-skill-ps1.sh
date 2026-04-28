#!/usr/bin/env sh
set -eu

if [ "$#" -lt 1 ]; then
  echo "Usage: $(basename "$0") <relative-ps1-path> [args...]" >&2
  exit 64
fi

script_path=$1
shift

if ! command -v pwsh >/dev/null 2>&1; then
  echo "PowerShell 7 (pwsh) is required to run this wrapper. Install pwsh or run the matching .ps1 script directly." >&2
  exit 127
fi

if repo_root=$(git --no-pager rev-parse --show-toplevel 2>/dev/null); then
  :
else
  script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
  repo_root=$(CDPATH= cd -- "$script_dir/../../.." && pwd)
fi

exec pwsh -NoLogo -NoProfile -File "$repo_root/$script_path" "$@"
