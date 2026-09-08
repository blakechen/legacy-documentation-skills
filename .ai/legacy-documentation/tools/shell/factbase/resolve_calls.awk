# Resolve call sites to a target type where the simple name is unambiguous.
#
# Input : types.psv then calls.psv   (order matters)
# Output: calls-resolved.psv  fromType|fromMethod|receiver|callee|kind|resolvedType|path|line
#
# Unambiguous means exactly one declared type carries that simple name. Where
# two do, the call is emitted with an empty target rather than a guess.

BEGIN { FS = "|" }

FILENAME ~ /types\.psv$/ { SIMPLEN[$2]++; SIMPLE1[$2] = $1; next }

{
    key = ($3 != "") ? $3 : (($5 == "new") ? $4 : "")
    target = ""
    if (key != "") {
        s = key; sub(/^.*\./, "", s)
        if (s in SIMPLEN && SIMPLEN[s] == 1) target = SIMPLE1[s]
    }
    printf "%s|%s|%s|%s|%s|%s|%s|%s\n", $1, $2, $3, $4, $5, target, $6, $7
}
