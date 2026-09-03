# Tools

The deterministic half of this library.

POSIX shell and awk. No interpreter to install, no dependencies, no build
step, no network. `javap`, `javac` and `jar` are used when present, and their
absence is reported rather than worked around.

Everything here answers a question that a language model reading source code
answers plausibly and sometimes wrongly. See `shared/fact-layer.md`.

---

## Layer 1 — facts

| Tool | Does |
|---|---|
| `lib/mask.awk` | Comment and literal masking. Library, loaded alongside another awk program. |
| `factbase/extract_java.awk` | The scanner: frame stack over masked source. |
| `factbase/extract_java.sh` | Source tree → `docs/facts/*.psv` |
| `factbase/hierarchy.awk` | Name resolution and transitive closure. |
| `factbase/resolve_calls.awk` | Call sites → target types where unambiguous. |
| `factbase/build_factbase.sh` | Runs both; writes `supertype.psv`, `ancestor.psv`, `calls-resolved.psv` |
| `factbase/verify_bytecode.sh` | Independent oracle: `javap` versus the factbase |

## Layer 2 — structure

| Tool | Does |
|---|---|
| `factbase/enumerate.sh` | Factbase → the three enumeration master lists |
| `factbase/prioritize.sh` | Reachability + git churn + usage → `priority.txt` |
| `factbase/archetypes.sh` + `.awk` | Clone clustering → `archetypes.txt` |
| `factbase/domain_variables.sh` | DB columns, input fields, config keys |
| `reflexion/reflexion.sh` | A person's module map versus the call graph |

## Verification

| Tool | Does |
|---|---|
| `verify/depth_checks.awk` | The four depth checks over one document |
| `verify/depth_checks.sh` | Runs them per unit → `depth-report.md` |
| `verify/staleness.sh` | Binds documents to source versions; incremental re-runs |
| `chartest/gen_skeletons.sh` + `.awk` | Documented branches → executable test skeletons |

## Self-test

    sh tools/selftest.sh

Runs the whole chain against `examples/fixtures/java-dispatcher` and compares
with `expected/`. 20 checks, including two that must FAIL: a plausible but
wrong document, and a class missing from the factbase. A tool change that
alters the expected output is a regression until those files are updated on
purpose.

---

## The factbase

Plain pipe-separated text, one record per line, no header. Greppable,
diffable, and reviewable in a pull request.

| File | Fields |
|---|---|
| `files.psv` | path, package, lines |
| `hashes.psv` | path, sha256 |
| `types.psv` | fqn, simple, kind, owner, path, line, bodyStart, bodyEnd, modifiers, package, extends, implements, imports |
| `methods.psv` | type, name, path, line, endLine, ctor, public, abstract, inAnon, if, for, while, case, catch, and, or, ternary, total, modifiers |
| `calls.psv` | fromType, fromMethod, receiver, callee, kind, path, line |
| `calls-resolved.psv` | the above plus the resolved target type |
| `literals.psv` | path, line, value |
| `supertype.psv` | child, parent, parentRaw, relation, resolution |
| `ancestor.psv` | type, ancestor, depth — the transitive closure |
| `resolution.psv` | resolution kind, count |
| `manifest.psv` | key, value |

A `|` inside a literal is written as `&#124;`.

Query it with the tools you already have:

    # every subclass of StdTrxObject at any depth
    awk -F'|' '$2 == "EXTERNAL:StdTrxObject" { print $1, $3 }' docs/facts/ancestor.psv

    # public methods with more than 10 decision points
    awk -F'|' '$7 == 1 && $18 > 10 { print $1 "." $2, $18 }' docs/facts/methods.psv

---

## Order

    extract_java.sh  ->  build_factbase.sh  ->  verify_bytecode.sh
                                            ->  enumerate.sh
                                                  ->  prioritize.sh
                                                  ->  archetypes.sh
                                                  ->  domain_variables.sh
                                            ->  reflexion.sh

    (documents are written)

    ->  depth_checks.sh  ->  staleness.sh --record
    ->  gen_skeletons.sh

---

## A worked example

    REPO=/path/to/legacy-app

    sh tools/factbase/extract_java.sh --repo $REPO \
        --out $REPO/docs/facts --source-root src/main/java
    sh tools/factbase/build_factbase.sh --facts $REPO/docs/facts
    sh tools/factbase/verify_bytecode.sh --repo $REPO \
        --facts $REPO/docs/facts \
        --out $REPO/docs/facts/bytecode-verification.md

    sh tools/factbase/enumerate.sh \
        --facts $REPO/docs/facts --out $REPO/docs/enumeration
    sh tools/factbase/prioritize.sh --repo $REPO \
        --facts $REPO/docs/facts --enumeration $REPO/docs/enumeration
    sh tools/factbase/archetypes.sh --repo $REPO \
        --facts $REPO/docs/facts --enumeration $REPO/docs/enumeration

Then write documents, then:

    sh tools/verify/depth_checks.sh --repo $REPO \
        --facts $REPO/docs/facts \
        --docs $REPO/docs/modules/transactions \
        --enumeration $REPO/docs/enumeration \
        --out $REPO/docs/gap-analysis/depth-report.md

---

## Portability

Written for POSIX `sh` and POSIX `awk`. Exercised on macOS: BSD awk, BSD sed,
bash 3.2. Not yet run under GNU awk or busybox awk -- the constructs that
differ between them are avoided on purpose, but that is a design claim, not a
test result. Run `sh tools/selftest.sh` on your target platform before relying
on it there.

Specifically avoided: `gensub`, `asort`, regex `RS`, `length(array)`, GNU-only
`sed -i`, `\s` and `\d` in regular expressions, and process substitution.

`sha256` is spelled three different ways across systems; `lib/common.sh` tries
`shasum`, `sha256sum` and `openssl` in turn and falls back to `cksum`, which
it labels as such so nobody mistakes it for a cryptographic hash.

---

## Limits

`extract_java.awk` is a lexical scanner over masked source. It does not
resolve generics, overloads or types. It marks what it cannot resolve rather
than guessing, and the bytecode oracle exists because a lexical scanner alone
should not be trusted with the enumeration.

Text blocks (`""" ... """`) are not masked. Legacy code predates them.

Java only, today. A new language needs a new Layer 1 extractor emitting the
same records. Nothing above Layer 1 changes.

Where no extractor exists for a language, `shared/confidence-scoring.md`
forbids reporting findings about that language's code as High confidence.
