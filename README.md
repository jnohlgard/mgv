# download-verify.sh

Downloader script which only downloads a file when it is missing or corrupt.

    Usage: ./download-verify.sh [--sha256 <sha256>] [--md5 <md5>] [--sha1 <sha1>] [-o|--outfile outfile] <URL>

    Verify checksums of outfile and (re-)download from URL
    outfile will use basename of URL by default
