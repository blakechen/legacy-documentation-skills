# Decide Depth-Complete for one unit document.
#
# Input order: methods.psv (already filtered to this unit), tables.txt, doc.md
# Required -v: UNIT, REPO, FINDINGS
# Writes findings to FINDINGS as severity|check|unit|method|message|location
# and a summary line to stdout as unit|status|srcMethods|docMethods|fails|warns
#
# Five of the six Depth-Complete conditions in shared/logic-depth.md are
# decidable by machine once a factbase exists; this decides them. It does NOT
# judge whether prose is good, only whether it is consistent with the source
# it claims to describe.

function finding(sev, check, method, msg, loc) {
    printf "%s|%s|%s|%s|%s|%s\n", sev, check, UNIT, method, msg, loc > FINDINGS
    if (sev == "FAIL") NFAIL++; else NWARN++
}

function ceil(x,   i) { i = int(x); return (x > i) ? i + 1 : i }

function isSep(row,   n, p, i, ok) {
    n = split(row, p, "|"); ok = 0
    for (i = 1; i <= n; i++) {
        gsub(/^[ \t]+|[ \t]+$/, "", p[i])
        if (p[i] == "") continue
        if (p[i] !~ /^:?-{2,}:?$/) return 0
        ok = 1
    }
    return ok
}

# Return index of the heading that starts subsection `name` inside [s,e).
function subsec(s, e, name,   i) {
    for (i = s + 1; i < e; i++) {
        if (FENCE[i]) continue
        if (HL[i] > 0 && tolower(HT[i]) == tolower(name)) return i
        if (L[i] ~ /^[ \t]*\*\*[^*]+\*\*[ \t]*$/) {
            t = L[i]; gsub(/^[ \t]*\*\*|\*\*[ \t]*$/, "", t)
            if (tolower(t) == tolower(name)) return i
        }
    }
    return 0
}

function subsecEnd(i, e,   j) {
    for (j = i + 1; j < e; j++) {
        if (FENCE[j]) continue
        if (HL[j] > 0 && HL[j] <= HL[i]) return j
        if (HL[i] == 0 && L[j] ~ /^[ \t]*\*\*[^*]+\*\*[ \t]*$/) return j
    }
    return e
}

BEGIN { FS = "|" }

# ---- source methods for this unit (overloads merged) ------------------------
FILENAME ~ /methods\.psv$/ {
    m = $2
    if (!(m in SRC)) { SRC[m] = 1; SN++; SNAME[SN] = m; SPATH[m] = $3; SLO[m] = $4; SHI[m] = $5 }
    if ($5 > SHI[m]) SHI[m] = $5
    DIF[m] += $10; DFOR[m] += $11; DWH[m] += $12; DCA[m] += $13
    DCAT[m] += $14; DAND[m] += $15; DOR[m] += $16; DTER[m] += $17
    next
}
FILENAME ~ /tables\.txt$/ { TABLE[toupper($1)] = 1; NTABLE++; next }

# ---- document ----------------------------------------------------------------
{
    N++; L[N] = $0
    if ($0 ~ /^[ \t]*(```|~~~)/) {
        if (!INF) { INF = 1; FENCE[N] = 1; FOPEN[++NFENCE] = N
                    info = $0; sub(/^[ \t]*(```|~~~)/, "", info)
                    gsub(/[ \t]/, "", info); FINFO[NFENCE] = tolower(info) }
        else { INF = 0; FENCE[N] = 1; FCLOSE[NFENCE] = N }
        next
    }
    if (INF) { FENCE[N] = 1; next }
    if (match($0, /^#+[ \t]+/)) {
        h = substr($0, 1, RLENGTH); gsub(/[ \t]/, "", h)
        HL[N] = length(h)
        HT[N] = substr($0, RLENGTH + 1); gsub(/[ \t]+$/, "", HT[N])
    }
}

END {
    # method sections
    for (i = 1; i <= N; i++) {
        if (HL[i] < 3) continue
        if (HT[i] !~ /^[Mm]ethod:/) continue
        nm = HT[i]; sub(/^[Mm]ethod:[ \t]*/, "", nm); gsub(/`/, "", nm)
        gsub(/^[ \t]+|[ \t]+$/, "", nm)
        if (nm == "") continue
        MSEC[nm] = i; MN++; MNAME[MN] = nm; MLEV[nm] = HL[i]
        for (j = i + 1; j <= N; j++) if (HL[j] > 0 && HL[j] <= HL[i]) break
        MEND[nm] = j
    }

    # ---- structure ----------------------------------------------------------
    for (i = 1; i <= SN; i++)
        if (!(SNAME[i] in MSEC))
            finding("FAIL", "structure", SNAME[i],
                    "public method declared in source has no `### Method:` subsection", "")
    for (i = 1; i <= MN; i++)
        if (!(MNAME[i] in SRC))
            finding("FAIL", "structure", MNAME[i],
                    "documented method is not a public method declared in the source class", "")

    for (i = 1; i <= MN; i++) {
        nm = MNAME[i]; s = MSEC[nm]; e = MEND[nm]
        body = ""
        for (j = s; j < e; j++) body = body "\n" L[j]

        k = subsec(s, e, "Processing Flow")
        if (k == 0) finding("FAIL", "structure", nm, "no Processing Flow subsection", "")
        else {
            ke = subsecEnd(k, e); steps = 0
            for (j = k + 1; j < ke; j++) if (!FENCE[j] && L[j] ~ /^[ \t]*[0-9]+[.)][ \t]+[^ \t]/) steps++
            if (steps < 3 && body !~ /Method body contains no branching logic/)
                finding("FAIL", "structure", nm,
                    sprintf("Processing Flow has %d numbered steps; 3 required, or the literal trivial-method sentence", steps), "")
        }

        k = subsec(s, e, "Pseudocode")
        if (k == 0) finding("FAIL", "structure", nm, "no Pseudocode subsection", "")
        else {
            ke = subsecEnd(k, e); content = 0; pbr = 0
            for (f = 1; f <= NFENCE; f++) {
                if (FOPEN[f] <= k || FOPEN[f] >= ke) continue
                for (j = FOPEN[f] + 1; j < FCLOSE[f]; j++) {
                    if (L[j] ~ /[^ \t]/) content = 1
                    if (toupper(L[j]) ~ /^[ \t]*(ELSE[ \t]+IF|ELSIF|ELIF|IF|FOR[ \t]+EACH|FOREACH|FOR|WHILE|REPEAT|CASE|WHEN|SWITCH|CATCH|ON[ \t]+ERROR)([^A-Z]|$)/) pbr++
                }
            }
            if (!content) finding("FAIL", "structure", nm, "Pseudocode block is empty", "")
            PBR[nm] = pbr; HASPSEUDO[nm] = 1
        }

        k = subsec(s, e, "Key Source Excerpts")
        if (k == 0) finding("FAIL", "structure", nm, "no Key Source Excerpts subsection", "")
        else {
            ke = subsecEnd(k, e); cited = 0
            for (j = k + 1; j < ke; j++)
                if (L[j] ~ /[A-Za-z0-9_.\/-]+\.[A-Za-z]+:[0-9]+[ \t]*-[ \t]*[0-9]+/) cited = 1
            if (!cited && body !~ /No critical logic; no excerpt required\./)
                finding("FAIL", "structure", nm,
                    "no `path:line-line` excerpt and no explicit no-critical-logic sentence", "")
        }

        k = subsec(s, e, "Field Mapping")
        if (k == 0) finding("FAIL", "structure", nm, "no Field Mapping subsection", "")
        else {
            ke = subsecEnd(k, e); rows = 0
            for (j = k + 1; j < ke; j++) {
                if (FENCE[j] || L[j] !~ /^[ \t]*\|.*\|[ \t]*$/) continue
                if (isSep(L[j])) continue
                rows++
                if (rows == 1) continue          # header
                checkFieldRow(nm, L[j])
            }
            if (rows < 2) finding("FAIL", "structure", nm, "Field Mapping table has no data rows", "")
        }

        # ---- branches -------------------------------------------------------
        if ((nm in SRC) && HASPSEUDO[nm]) {
            st = DIF[nm] + DFOR[nm] + DWH[nm] + DCA[nm] + DCAT[nm] + DTER[nm]
            up = st + DAND[nm] + DOR[nm]
            loc = sprintf("source %s:%d-%d", SPATH[nm], SLO[nm], SHI[nm])
            if (PBR[nm] > up)
                finding("FAIL", "branches", nm,
                    sprintf("pseudocode has %d control constructs; the source method has at most %d decision points. Logic not present in the source has been introduced.", PBR[nm], up), loc)
            else if (st >= 1 && PBR[nm] < ceil(0.6 * st))
                finding("FAIL", "branches", nm,
                    sprintf("pseudocode has %d control constructs for %d structural decision points in the source; branches are missing.", PBR[nm], st), loc)
            else if (st == 0 && PBR[nm] > 0)
                finding("WARN", "branches", nm,
                    sprintf("pseudocode shows %d control constructs but the source method has none", PBR[nm]), loc)
        }
    }

    # ---- excerpts -------------------------------------------------------------
    for (f = 1; f <= NFENCE; f++) {
        if (FINFO[f] == "" || FINFO[f] == "text" || FINFO[f] == "pseudocode") continue
        ref = ""
        for (j = FOPEN[f] - 1; j >= 1 && j > FOPEN[f] - 5; j--) {
            if (L[j] !~ /[^ \t]/) continue
            if (match(L[j], /[A-Za-z0-9_.\/-]+\.[A-Za-z]+:[0-9]+[ \t]*-[ \t]*[0-9]+/))
                ref = substr(L[j], RSTART, RLENGTH)
            break
        }
        meth = methodAtLine(FOPEN[f])
        loc = DOCREL ":" FOPEN[f]
        if (ref == "") {
            finding("FAIL", "excerpts", meth,
                "code excerpt has no `path:line-line` citation on the preceding line", loc)
            continue
        }
        gsub(/[ \t]/, "", ref)
        p = index(ref, ":")
        file = substr(ref, 1, p - 1); rng = substr(ref, p + 1)
        d = index(rng, "-"); lo = substr(rng, 1, d - 1) + 0; hi = substr(rng, d + 1) + 0
        full = REPO "/" file
        na = 0
        while ((getline s < full) > 0) { na++; if (na >= lo && na <= hi) A[na - lo + 1] = s }
        close(full)
        if (na == 0) { finding("FAIL", "excerpts", meth, "cited file does not exist: " file, loc)
                       continue }
        if (lo < 1 || hi > na || lo > hi) {
            finding("FAIL", "excerpts", meth,
                sprintf("cited range %d-%d is outside %s (%d lines)", lo, hi, file, na), loc)
            split("", A); continue
        }
        nq = 0; ok = 1
        for (j = FOPEN[f] + 1; j < FCLOSE[f]; j++) { nq++; Q[nq] = L[j] }
        if (nq != hi - lo + 1) ok = 0
        for (j = 1; ok && j <= nq; j++) {
            a = Q[j]; b = A[j]
            sub(/[ \t]+$/, "", a); sub(/[ \t]+$/, "", b)
            if (a != b) ok = 0
        }
        if (!ok) finding("FAIL", "excerpts", meth,
                    sprintf("excerpt does not match %s:%d-%d", file, lo, hi), loc)
        split("", A); split("", Q)
    }

    status = (NFAIL > 0) ? "INCOMPLETE" : "DEPTH-COMPLETE"
    printf "%s|%s|%d|%d|%d|%d\n", UNIT, status, SN, MN, NFAIL + 0, NWARN + 0
}

function methodAtLine(ln,   i, nm) {
    for (i = 1; i <= MN; i++) {
        nm = MNAME[i]
        if (MSEC[nm] <= ln && ln < MEND[nm]) return nm
    }
    return ""
}

function checkFieldRow(nm, row,   n, p, i, f, inter, tgt, kind, bare, needle, body, tbl) {
    n = split(row, p, "|")
    for (i = 1; i <= n; i++) gsub(/^[ \t]+|[ \t]+$/, "", p[i])
    f = p[2]; inter = p[4]; tgt = p[6]; kind = p[7]
    if ((f == "None" || f == "-" || f == "") && (tgt == "-" || tgt == "" || tgt == "None")) return
    if (!(nm in SRC)) return
    body = methodBody(nm)
    for (i = 0; i < 2; i++) {
        bare = (i == 0) ? f : inter
        gsub(/[`*]/, "", bare)
        if (bare == "" || bare == "-" || bare == "None") continue
        if (bare !~ /^[A-Za-z0-9_$.\[\]]+$/) continue
        needle = bare; sub(/[.\[].*$/, "", needle)
        if (needle == "") continue
        if (index(body, needle) == 0)
            finding("FAIL", "fields", nm,
                sprintf("field-mapping names `%s`, which does not appear in %s:%d-%d",
                        bare, SPATH[nm], SLO[nm], SHI[nm]), "")
    }
    if (tolower(kind) ~ /db column/) {
        tbl = tgt; gsub(/[`*]/, "", tbl); sub(/\..*$/, "", tbl); tbl = toupper(tbl)
        if (tbl != "" && NTABLE > 0 && !(tbl in TABLE))
            finding("FAIL", "fields", nm,
                sprintf("target table `%s` is not in docs/enumeration/db-object-classes.txt", tbl), "")
    }
}

function methodBody(nm,   full, k, s, out) {
    if (nm in BODY) return BODY[nm]
    full = REPO "/" SPATH[nm]; k = 0; out = ""
    while ((getline s < full) > 0) { k++; if (k >= SLO[nm] && k <= SHI[nm]) out = out "\n" s }
    close(full)
    BODY[nm] = out
    return out
}
