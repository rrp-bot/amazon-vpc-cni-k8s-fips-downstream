#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
UPSTREAM_VERSION="${UPSTREAM_VERSION:-v1.23.0}"
UPSTREAM="${ROOT}/upstream"

fail() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

cd "${ROOT}"
git submodule update --init --recursive upstream

test -e "${UPSTREAM}/.git" || fail "upstream submodule was not initialized"

if ! git -C "${UPSTREAM}" diff --quiet || \
   ! git -C "${UPSTREAM}" diff --cached --quiet; then
    fail "upstream submodule has local changes"
fi

git -C "${UPSTREAM}" checkout --detach "${UPSTREAM_VERSION}"

actual="$(git -C "${UPSTREAM}" describe --tags --exact-match 2>/dev/null || true)"
[ "${actual}" = "${UPSTREAM_VERSION}" ] || \
    fail "expected ${UPSTREAM_VERSION}, found ${actual:-unknown}"

shopt -s nullglob
patches=("${ROOT}"/patches/*.patch)
[ "${#patches[@]}" -gt 0 ] || fail "no patches found"

for patch_file in "${patches[@]}"; do
    printf 'checking %s\n' "${patch_file##*/}"
    git -C "${UPSTREAM}" apply --check "${patch_file}"
done

for patch_file in "${patches[@]}"; do
    printf 'applying %s\n' "${patch_file##*/}"
    git -C "${UPSTREAM}" apply "${patch_file}"
done

printf 'prepared upstream %s at %s\n' \
    "${UPSTREAM_VERSION}" \
    "$(git -C "${UPSTREAM}" rev-parse HEAD)"
