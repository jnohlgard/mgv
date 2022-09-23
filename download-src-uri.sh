#!/bin/sh

set -euo pipefail

usage() {
  printf 'Usage: %s <destination-file1> [... <destination-fileN>]\n' "$0"
  printf 'Download the files given from the URLs found in the <destination-file>.src-uri file\n'
  printf 'Only URLs understood by curl are supported\n'
}

if [ "$#" -lt 1 ] || [ "$1" = '--help' ]; then
  >&2 usage
  exit 1
fi

resume_download_to=
if command -v curl 2>&1 >/dev/null; then
  resume_download_to='curl -R -C - -f -L -o'
elif command -v wget 2>&1 >/dev/null; then
  resume_download_to='wget --timestamping -c -O'
else
  >&2 printf 'Required: curl or wget\n'
  exit 1
fi

while [ "$#" -gt 0 ]; do
  dest_file=${1%%.src-uri};shift
  if [ -s "${dest_file}" ]; then
    >&2 printf '%s: already downloaded\n' "${dest_file}"
    continue
  fi
  src_uri_file=${dest_file}.src-uri
  if [ ! -r "${src_uri_file}" ]; then
    >&2 printf '%s: not a file\n' "${src_uri_file}"
    exit 1
  fi
  download_file=${dest_file}.download
  src_uri=
  while read -r line; do
    if [ -z "${line}" ] || [ "${line:0:1}" = '#' ]; then
      continue
    fi
    src_uri=${line}
  done < "${src_uri_file}"
  if [ -z "${src_uri}" ]; then
    >&2 printf 'Error: Missing URL in %s\n' "${src_uri_file}"
    exit 1
  fi
  touch "${dest_file}"
  ${resume_download_to} "${download_file}" "${src_uri}"
  mv "${download_file}" "${dest_file}"
done
