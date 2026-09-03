# Emit one characterization test class from one unit document.
# Required -v: UNIT, PKG, OUTF.   Prints UNIT|testCount on stdout.

function camel(s,   n, p, i, out) {
    gsub(/[^A-Za-z0-9]+/, " ", s); gsub(/^ +| +$/, "", s)
    n = split(s, p, " ")
    if (n == 0) return "case"
    out = tolower(p[1])
    for (i = 2; i <= n; i++) out = out toupper(substr(p[i], 1, 1)) substr(p[i], 2)
    return substr(out, 1, 48)
}
function upper1(s) { return toupper(substr(s, 1, 1)) substr(s, 2) }
function isSep(row,   n, p, i, ok) {
    n = split(row, p, "|"); ok = 0
    for (i = 1; i <= n; i++) { gsub(/^[ \t]+|[ \t]+$/, "", p[i])
        if (p[i] == "") continue
        if (p[i] !~ /^:?-{2,}:?$/) return 0
        ok = 1 }
    return ok
}

{
    N++; L[N] = $0
    if ($0 ~ /^[ \t]*(```|~~~)/) { INF = !INF; FENCE[N] = 1; next }
    if (INF) { FENCE[N] = 1; next }
    if (match($0, /^#+[ \t]+/)) {
        h = substr($0, 1, RLENGTH); gsub(/[ \t]/, "", h)
        HL[N] = length(h); HT[N] = substr($0, RLENGTH + 1); gsub(/[ \t]+$/, "", HT[N])
    }
}

END {
    for (i = 1; i <= N; i++) {
        if (HL[i] < 3 || HT[i] !~ /^[Mm]ethod:/) continue
        nm = HT[i]; sub(/^[Mm]ethod:[ \t]*/, "", nm); gsub(/`/, "", nm)
        gsub(/^[ \t]+|[ \t]+$/, "", nm)
        if (nm == "") continue
        MN++; MNAME[MN] = nm; MS[MN] = i
        for (j = i + 1; j <= N; j++) if (HL[j] > 0 && HL[j] <= HL[i]) break
        ME[MN] = j
    }
    if (MN == 0) { printf "%s|0\n", UNIT; exit }

    print "package " PKG ";"                                   > OUTF
    print ""                                                   > OUTF
    print "import org.junit.Test;"                             > OUTF
    print "import static org.junit.Assert.*;"                   > OUTF
    print ""                                                   > OUTF
    print "/**"                                                > OUTF
    print " * Characterization tests for " UNIT "."            > OUTF
    print " *"                                                 > OUTF
    print " * Generated from the unit document by"             > OUTF
    print " * tools/chartest/gen_skeletons.sh. Each test states one claim the" > OUTF
    print " * document makes. A failing test means the document is wrong about" > OUTF
    print " * the code, or the code has changed."              > OUTF
    print " *"                                                 > OUTF
    print " * Supply setUp() for your harness; nothing here runs until you do." > OUTF
    print " */"                                                > OUTF
    print "public class " UNIT "CharacterizationTest {"        > OUTF
    print ""                                                   > OUTF

    for (m = 1; m <= MN; m++) {
        nm = MNAME[m]
        print "    // ---- " nm " ----"                        > OUTF
        print ""                                               > OUTF
        inputs = ""; sub_start = 0; sub_end = 0
        brs = 0; bre = 0
        for (i = MS[m] + 1; i < ME[m]; i++) {
            if (FENCE[i] || HL[i] == 0) continue
            t = tolower(HT[i])
            if (t == "field mapping") { sub_start = i
                for (j = i + 1; j < ME[m]; j++) if (HL[j] > 0 && HL[j] <= HL[i]) break
                sub_end = j }
            if (t == "branches and conditions") { brs = i
                for (j = i + 1; j < ME[m]; j++) if (HL[j] > 0 && HL[j] <= HL[i]) break
                bre = j }
        }
        if (sub_start) {
            r = 0
            for (i = sub_start + 1; i < sub_end; i++) {
                if (FENCE[i] || L[i] !~ /^[ \t]*\|.*\|[ \t]*$/ || isSep(L[i])) continue
                r++; if (r == 1) continue
                n = split(L[i], p, "|"); f = p[2]; gsub(/^[ \t]+|[ \t]+$|`/, "", f)
                if (f != "" && f != "-" && f != "None")
                    inputs = inputs (inputs == "" ? "" : ", ") f
            }
        }
        if (inputs != "") {
            print "    // Input fields named by the document:"  > OUTF
            print "    //   " inputs                            > OUTF
            print ""                                            > OUTF
        }
        rows = 0
        if (brs) {
            r = 0
            for (i = brs + 1; i < bre; i++) {
                if (FENCE[i] || L[i] !~ /^[ \t]*\|.*\|[ \t]*$/ || isSep(L[i])) continue
                r++; if (r == 1) continue
                n = split(L[i], p, "|")
                for (k = 1; k <= n; k++) gsub(/^[ \t]+|[ \t]+$/, "", p[k])
                cond = p[3]; wt = p[4]; wf = p[5]; ev = p[6]
                for (side = 0; side < 2; side++) {
                    out = (side == 0) ? wt : wf
                    if (out == "" || out == "-" || out == "None") continue
                    lbl = (side == 0) ? ("when" upper1(camel(cond))) \
                                      : ("whenNot" upper1(camel(cond)))
                    name = nm "_" lbl "_" camel(out)
                    print "    @Test"                           > OUTF
                    print "    public void " substr(name, 1, 110) "() {" > OUTF
                    print "        // Condition: " cond         > OUTF
                    print "        // Documented outcome: " out > OUTF
                    print "        // Evidence: " (ev == "" ? "-" : ev) > OUTF
                    print "        fail(\"supply the harness, then assert the outcome above\");" > OUTF
                    print "    }"                               > OUTF
                    print ""                                    > OUTF
                    rows++
                }
            }
        }
        if (rows == 0) {
            print "    @Test"                                   > OUTF
            print "    public void " nm "_hasNoDocumentedBranches() {" > OUTF
            print "        // The document records no branch for this method." > OUTF
            print "        // If the source has one, the document is incomplete." > OUTF
            print "        fail(\"supply the harness, then assert the observed behaviour\");" > OUTF
            print "    }"                                       > OUTF
            print ""                                            > OUTF
            rows++
        }
        TOTAL += rows
    }
    print "}"                                                  > OUTF
    printf "%s|%d\n", UNIT, TOTAL + 0
}
