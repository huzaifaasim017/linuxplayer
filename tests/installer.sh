#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT
mkdir -p "$test_dir/bin"

cat > "$test_dir/bin/curl" <<'MOCK'
#!/usr/bin/env bash
url=""
output=""
while (($#)); do
    case "$1" in
        -o) output="$2"; shift 2 ;;
        http*) url="$1"; shift ;;
        *) shift ;;
    esac
done
asset="${url##*/}"
if [[ "$asset" == *.sha256 ]]; then
    package="${asset%.sha256}"
    if [[ "${MOCK_BAD_CHECKSUM:-0}" == 1 ]]; then
        printf '%s  %s\n' "$(printf wrong | sha256sum | cut -d' ' -f1)" "$package" > "$output"
    else
        printf '%s  %s\n' "$(printf '%s' "$package" | sha256sum | cut -d' ' -f1)" "$package" > "$output"
    fi
else
    printf '%s' "$asset" > "$output"
fi
MOCK

cat > "$test_dir/bin/apt-get" <<'MOCK'
#!/usr/bin/env bash
if [[ "$1" == -s ]]; then
    [[ "$4" == *"${MOCK_COMPAT}.deb" ]]
else
    printf '%s\n' "$3" >> "$MOCK_INSTALL_LOG"
fi
MOCK

cat > "$test_dir/bin/sudo" <<'MOCK'
#!/usr/bin/env bash
"$@"
MOCK
chmod +x "$test_dir/bin/"*
export PATH="$test_dir/bin:$PATH"
export MOCK_INSTALL_LOG="$test_dir/installed"

MOCK_COMPAT=ubuntu26.04_amd64 bash "$repo_root/scripts/install.sh" > "$test_dir/output"
grep -q 'ubuntu26.04_amd64.deb' "$MOCK_INSTALL_LOG"

: > "$MOCK_INSTALL_LOG"
MOCK_COMPAT=ubuntu24.04_amd64 bash "$repo_root/scripts/install.sh" > "$test_dir/output"
grep -q 'ubuntu24.04_amd64.deb' "$MOCK_INSTALL_LOG"

: > "$MOCK_INSTALL_LOG"
if MOCK_COMPAT=none bash "$repo_root/scripts/install.sh" > "$test_dir/output" 2>&1; then
    echo 'Installer accepted an incompatible package.' >&2
    exit 1
fi
test ! -s "$MOCK_INSTALL_LOG"

if MOCK_COMPAT=ubuntu26.04_amd64 MOCK_BAD_CHECKSUM=1 bash "$repo_root/scripts/install.sh" > "$test_dir/output" 2>&1; then
    echo 'Installer accepted a bad checksum.' >&2
    exit 1
fi
grep -q 'Checksum verification failed' "$test_dir/output"
test ! -s "$MOCK_INSTALL_LOG"

echo 'Installer selection and checksum checks passed.'
