# Shared shell helpers. POSIX sh. Sourced, never executed.
#
# Everything here exists because the same three portability traps keep
# appearing: BSD versus GNU tools, `mktemp` argument differences, and the
# absence of a hash command by a predictable name.

die() { printf '%s: %s\n' "${0##*/}" "$*" >&2; exit 1; }

warn() { printf '%s: %s\n' "${0##*/}" "$*" >&2; }

abspath() {
    case "$1" in
        /*) printf '%s\n' "${1%/}" ;;
        *)  printf '%s\n' "$(CDPATH= cd -- "$1" 2>/dev/null && pwd)" ;;
    esac
}

# mktemp differs between BSD and GNU; -t with a template works on both.
mktemp_file() { mktemp -t ldsk.XXXXXX; }
mktemp_dir()  { mktemp -d -t ldsk.XXXXXX; }

count_lines() {
    [ -f "$1" ] || { echo 0; return; }
    wc -l < "$1" | tr -d ' '
}

# sha256 has three common spellings and may have none at all.
hash_file() {
    if command -v shasum > /dev/null 2>&1; then
        shasum -a 256 "$1" | awk '{print $1}'
    elif command -v sha256sum > /dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    elif command -v openssl > /dev/null 2>&1; then
        openssl dgst -sha256 "$1" | awk '{print $NF}'
    else
        # cksum is POSIX and always present. Weaker, and labelled as such so
        # nobody mistakes it for a cryptographic hash.
        printf 'cksum:%s\n' "$(cksum < "$1" | awk '{print $1"-"$2}')"
    fi
}

git_head() {
    if command -v git > /dev/null 2>&1 && [ -d "$1/.git" ] || \
       git -C "$1" rev-parse --git-dir > /dev/null 2>&1; then
        git -C "$1" rev-parse HEAD 2>/dev/null || echo UNKNOWN
    else
        echo UNKNOWN
    fi
}

filter_excluded() {
    _ex=$1
    if [ -z "$_ex" ]; then
        grep -v -e '/target/' -e '/build/' -e '/out/' -e '/bin/' \
                -e '/node_modules/' -e '/dist/' -e '/\.git/' \
                -e '/\.gradle/' -e '/generated-sources/' || true
    else
        _pat=""
        for d in $_ex; do _pat="$_pat -e /$d/"; done
        grep -v -e '/target/' -e '/build/' -e '/out/' -e '/bin/' \
                -e '/node_modules/' -e '/dist/' -e '/\.git/' \
                -e '/\.gradle/' -e '/generated-sources/' $_pat || true
    fi
}

# Feed a file list to a command in batches, so a 10,000-file repository does
# not overflow the argument list.
xargs_files() {
    _list=$1; shift
    tr '\n' '\0' < "$_list" | xargs -0 "$@"
}

# Read one field from a `key|value` file.
meta_get() {
    awk -F'|' -v k="$2" '$1 == k { print $2; exit }' "$1" 2>/dev/null
}

require_file() {
    [ -f "$1" ] || die "required file missing: $1"
}
