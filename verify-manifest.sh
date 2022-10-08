#!/bin/sh

set -euo pipefail

cmd_check_md5='md5sum -c'
cmd_check_sha1='sha1sum -c'
cmd_check_sha256='sha256sum -c'
cmd_check_sha512='sha512sum -c'

verbose_verify=0

usage() {
  printf 'Usage: %s <manifest> <file1> [... <fileN>]\n' "$0"
  printf 'Verify checksums of the given files using the given Manifest file\n'
  printf 'Inspired by Gentoo Manifest2 format, see GLEP-74: https://www.gentoo.org/glep/glep-0074.html\n'
  printf 'Only the DIST tag is supported\n'
  printf 'Currently supported checksum tags:\n'
  printf ' - %s\n' MD5 SHA1 SHA256 SHA512
}

if [ "$#" -lt 2 ]; then
  >&2 usage
  exit 1
fi

manifest_file=$1;shift
if [ ! -r "${manifest_file}" ]; then
  >&2 printf 'Error: Not readable: %s\n' "${manifest_file}"
fi

verify_checksums() {
  filename=$1;shift
  checksum_type=
  checksum_value=
  for v in "$@"; do
    if [ -z "${checksum_type}" ]; then
      checksum_type=$v
      continue
    fi
    checksum_value=$v
    #printf 'type: %s, value: %s\n' "${checksum_type}" "${checksum_value}"
    printf '%s: ' "${checksum_type}"
    case "${checksum_type}" in
      MD5)
        printf '%s *%s\n' "${checksum_value}" "${filename}" | ${cmd_check_md5} || return 1
        ;;
      SHA1)
        printf '%s *%s\n' "${checksum_value}" "${filename}" | ${cmd_check_sha1} || return 1
        ;;
      SHA256)
        printf '%s *%s\n' "${checksum_value}" "${filename}" | ${cmd_check_sha256} || return 1
        ;;
      SHA512)
        printf '%s *%s\n' "${checksum_value}" "${filename}" | ${cmd_check_sha512} || return 1
        ;;
      *)
        printf 'not checked\n'
        ;;
    esac
    checksum_type=
  done
}

# suboptimal but simple N^2 solution
ret=0
for filename in "$@"; do
  filename_base="$(basename "${filename}")"
  actual_size=$(wc -c <"${filename}")
  result=
  found=0
  code=0
  while read -r tag filename_in_manifest expected_size checksums; do
    #printf 'tag: <%s>, filename: <%s>, size: <%s>, checksums: <%s>\n' "${tag}" "${filename_in_manifest}" "${expected_size}" "${checksums}"
    if [ "${tag}" != "DIST" ]; then
      continue
    fi
    if [ "${filename_in_manifest}" != "${filename_base}" ]; then
      continue
    fi
    found=1
    if [ "${expected_size}" != "-" ]; then
      if [ "${expected_size}" -ne "${actual_size}" ]; then
        >&2 printf '%s: Size mismatch, expected %d, actual %d\n' "${filename}"
        result='Size mismatch'
        code=2
        break
      fi
    fi
    verify_code=0
    # NB we want expansion of ${checksums} into multiple arguments on the function call below
    if [ "${verbose_verify}" -eq 0 ]; then
      verify_checksums "${filename}" ${checksums} > /dev/null || verify_code=$?
    else
      verify_checksums "${filename}" ${checksums} || verify_code=$?
    fi
    if [ "${verify_code}" -eq 9 ]; then
      # return value 9 means not checked.
      continue
    elif [ "${verify_code}" -ne 0 ]; then
      result='Checksum failure'
      code=${verify_code}
      break
    fi
    result=OK
  done < "${manifest_file}"
  if [ "${found}" -eq 0 ]; then
    result="Not found in manifest ${manifest_file}"
    code=8
  fi
  if [ -z "${result}" ]; then
    printf 'Not checked: %s\n' "${filename}"
  else
    printf '%s: %s\n' "${filename}" "${result}"
  fi
  if [ "${code}" -ne 0 ]; then
    ret=${code}
  fi
done
exit ${ret}
