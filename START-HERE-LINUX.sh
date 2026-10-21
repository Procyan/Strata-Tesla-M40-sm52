#!/usr/bin/env bash
# Strata for Linux: first run creates the venv; later runs just start the model.
# Requires Python 3.10+ and an NVIDIA or AMD graphics driver.

set -euo pipefail

cd "$(dirname "$0")"

if [[ ! -x ".venv/bin/python" ]]; then
    PY=""
    for candidate in python3 python; do
        if command -v "$candidate" >/dev/null 2>&1; then
            if "$candidate" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 10) and sys.maxsize > 2**32 else 1)' >/dev/null 2>&1; then
                PY="$candidate"
                break
            fi
        fi
    done

    if [[ -z "$PY" ]]; then
        echo
        echo "Python 3.10 or newer (64-bit) was not found."
        echo "Install it first, for example:"
        echo
        echo "  Debian/Ubuntu: sudo apt install python3 python3-venv python3-pip"
        echo "  Fedora:        sudo dnf install python3 python3-pip"
        echo "  Arch:          sudo pacman -S python"
        echo
        echo "Then run this script again."
        read -r -p "Press Enter to exit..." _
        exit 1
    fi

    echo "Creating Python virtual environment in .venv ..."
    "$PY" -m venv .venv

    if [[ ! -x ".venv/bin/python" ]]; then
        echo "Could not create the Python environment in .venv"
        echo "On Debian/Ubuntu, install: sudo apt install python3-venv"
        read -r -p "Press Enter to exit..." _
        exit 1
    fi
fi

# shellcheck disable=SC1091
source .venv/bin/activate

if ! .venv/bin/python setup.py "$@"; then
    read -r -p "Setup failed. Press Enter to exit..." _
    exit 1
fi
