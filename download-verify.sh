#!/bin/sh
set -euo pipefail

cmd_check_md5='md5sum -c'
cmd_check_sha1='sha1sum -c'
cmd_check_sha256='sha256sum -c'

usage() {
  >&2 printf 'Usage: %s [-s <sha256>] [-m <md5>] [-1 <sha1>] [-o outfile] <URL>\n\n' "$0"
  >&2 printf 'Verify checksums of outfile and (re-)download from URL\n'
  >&2 printf 'outfile will use basename of URL by default\n'
}

verify_checksums() {
  [ -z "${checksum_md5}" ] || printf '%s *%s\n' "${checksum_md5}" "$1" | ${cmd_check_md5} || return 1
  [ -z "${checksum_sha1}" ] || printf '%s *%s\n' "${checksum_sha1}" "$1" | ${cmd_check_sha1} || return 1
  [ -z "${checksum_sha256}" ] || printf '%s *%s\n' "${checksum_sha256}" "$1" | ${cmd_check_sha256} || return 1
  return 0
}

checksum_md5=
checksum_sha1=
checksum_sha256=
outfile=

while getopts "1:m:s:" opt; do
  case "${opt}" in
  s)
    checksum_sha256=${OPTARG}
    ;;
  m)
    checksum_md5=${OPTARG}
    ;;
  1)
    checksum_sha1=${OPTARG}
    ;;
  o)
    outfile=${OPTARG}
    ;;
  *)
    usage
    exit 1
    ;;
  esac
done
shift $((OPTIND-1))

if [ $# -ne 1 ]; then
  usage
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
