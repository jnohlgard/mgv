#!/bin/sh

set -euo pipefail

usage() {
  printf 'Usage: %s <manifest-file> <destination-file1> [... <destination-fileN>]\n\n' "$0"
  printf 'Download the given files and verify agains the manifest-file\n'
}

if [ "$#" -lt 2 ] || [ "$1" = '--help' ]; then
  >&2 usage
  exit 1
fi

manifest_file=$1;shift
if [ ! -r "${manifest_file}" ]; then
  >&2 printf 'Error: Not readable: %s\n' "${manifest_file}"
fi

tools_path=$(cd "$(dirname "$0")"; pwd)
download_cmd="${tools_path}/download-src-uri.sh"
verify_cmd="${tools_path}/verify-manifest.sh"

ret=0
for dest in "$@"; do
  dest_file=${dest%%.src-uri}
  code=0
  "${download_cmd}" "${dest_file}" || code=$?
  if [ "${code}" -ne 0 ]; then
    >&2 printf '%s: Download failure\n' "${dest_file}"
    ret=${code}
    continue
  fi
  "${verify_cmd}" "${manifest_file}" "${dest_file}" || code=$?
  if [ "${code}" -ne 0 ]; then
    mv -f "${dest_file}" "${dest_file}.verify-failed"
    >&2 printf '%s: Verification failure\n' "${dest_file}"
    ret=${code}
    continue
  fi
done
exit ${ret}
