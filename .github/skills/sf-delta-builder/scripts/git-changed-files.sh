#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec "$script_dir/../../../scripts/salesforce/run-skill-ps1.sh" ".github/skills/sf-delta-builder/scripts/git-changed-files.ps1" "$@"
