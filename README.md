# mgv

Tool for verifying file checksums and re-downloading them if not correct.

## `.mgv` File format

The file format was inspired from the Portage Manifest format used in Gentoo Linux, with some modifications.

Each line of a .mgv file represents a file name, size, its source URL and its checksums:

```
DIST example.tar.gz 12260 URL https://raw.githubusercontent.com/jnohlgard/mgv/d713b00304a07d14fbc6cf7094ce775a979ad697/example/example.tar.gz SHA256 da6c6de5f391058a9fb6ced11c9b41349042e22c377313fedaf894b50292ae0c
```

## Installation

Put `mgv` in your `PATH`.


## Dependencies

mgv requires curl or wget to download files and some external tools for computing checksums:

 - MD5: `md5sum`
 - SHA1: `sha1sum`
 - SHA256: `sha256sum`
 - SHA512: `sha512sum`
 - BLAKE2B: `b2sum`
 - SHA3_256, SHA3_512: `sha3sum` (found in e.g. BusyBox)

All of the above are part of the coreutils package on Linux and should be available on most systems.
Busybox also provides implementations of everything above except `b2sum`.
The script avoids bashisms and tries to be posix sh compliant. It should work with bash, dash and BusyBox sh.

## References

 - https://www.gentoo.org/glep/glep-0074.html
