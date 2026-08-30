#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
/bin/bash "$PROJECT_ROOT/scripts/install-macos.sh"

printf '\nYou can close this window.\n'
read -r -p "Press Return to finish. " _
