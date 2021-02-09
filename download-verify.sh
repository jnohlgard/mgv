#!/bin/sh
set -euo pipefail

cmd_check_md5='md5sum -c'
cmd_check_sha1='sha1sum -c'
cmd_check_sha256='sha256sum -c'

usage() {
  printf 'Usage: %s [--sha256 <sha256>] [--md5 <md5>] [--sha1 <sha1>] [-o|--outfile outfile] <URL>\n\n' "$0"
  printf 'Verify checksums of outfile and (re-)download from URL\n'
  printf 'outfile will use basename of URL by default\n'
}

verify_checksums() {
  # Check for file existence
  [ -f "$1" ] || return 1
  # Verify file size first because it is quick
  if [ -n "${target_size}" ]; then
    actual_size=$(wc -c < "$1")
    if [ "${actual_size}" -ne "${target_size}" ]; then
      >&2 printf 'Size mismatch, expected: %d, actual: %d\n' "${target_size}" "${actual_size}"
      return 1
    fi
  fi
  # Verify checksums
  [ -z "${checksum_md5}" ] || printf '%s *%s\n' "${checksum_md5}" "$1" | ${cmd_check_md5} || return 1
  [ -z "${checksum_sha1}" ] || printf '%s *%s\n' "${checksum_sha1}" "$1" | ${cmd_check_sha1} || return 1
  [ -z "${checksum_sha256}" ] || printf '%s *%s\n' "${checksum_sha256}" "$1" | ${cmd_check_sha256} || return 1
  return 0
}

assign_once() {
  if [ -n "$(eval printf '%s' "\${${1}}")" ]; then
    >&2 printf '%s given multiple times\n' "$1"
    exit 1
  fi
  eval "${1}='${2}'"
}

checksum_md5=
checksum_sha1=
checksum_sha256=
target_size=
outfile=

while [ "$#" -gt 0 ]; do
  while [ "$#" -ge 2 ]; do
    case "$1" in
    --sha256)
      assign_once checksum_sha256 "$2"
      ;;
    --md5)
      assign_once checksum_md5 "$2"
      ;;
    --sha1)
      assign_once checksum_sha1 "$2"
      ;;
    -s|--size)
      assign_once target_size "$2"
      ;;
    -o|--outfile)
      assign_once outfile "$2"
      ;;
    *)
      break
      ;;
    esac
    shift 2
  done

  case "$1" in
  -h|--help)
    usage
    exit 0
    ;;
  --)
    # Stop option processing
    shift
    break
    ;;
  -*)
    >&2 printf 'Error: unknown option %s\n' "$1"
    >&2 usage
    exit 1
    ;;
  *)
    break
    ;;
  esac
  shift
done

if [ $# -ne 1 ]; then
  >&2 usage
  exit 1
fi

url=$1; shift

if [ -z "${outfile}" ]; then
  outfile=$(basename "${url}")
fi

if [ -z "${checksum_md5}${checksum_sha1}${checksum_sha256}" ]; then
  >&2 printf 'Error: No checksums provided for URL %s\n' "${url}"
  usage
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

printf 'Checking %s...\n' "${outfile}"
if ! verify_checksums "${outfile}"; then
  if [ ! -f "${outfile}" ]; then
    >&2 printf '%s not found, will download...\n' "${outfile}"
  else
    >&2 printf 'Checksum verification failed: %s, will re-download...\n' "${outfile}"
    rm -f "${outfile}"
  fi
  ${resume_download_to} "${outfile}" "${url}"
  if ! verify_checksums "${outfile}"; then
    >&2 printf 'Checksum verification failed: %s\n' "${outfile}"
    exit 1
  fi
fi
