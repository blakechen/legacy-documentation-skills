# Tools

The deterministic half of this library.

Standard library Python 3 only. No build step, no dependencies, no network.
`javap` and `javac` are used when present and their absence is reported, not
worked around.

Everything here answers a question that a language model reading source code
answers plausibly and sometimes wrongly. See `shared/fact-layer.md`.

---

## Layer 1 — facts

| Tool | Does |
|---|---|
| `factbase/javalex.py` | Lexical Java scanner. Library, not a CLI. |
| `factbase/extract_java.py` | Source tree → `docs/facts/*.jsonl` |
| `factbase/build_factbase.py` | JSONL → SQLite, name resolution, transitive closure |
| `factbase/verify_bytecode.py` | Independent oracle: `javap` vs the factbase |

## Layer 2 — structure

| Tool | Does |
|---|---|
| `factbase/enumerate.py` | Factbase → the three enumeration master lists |
| `factbase/prioritize.py` | Reachability + git churn + usage → `priority.txt` |
| `factbase/archetypes.py` | Clone clustering → `archetypes.txt` |
| `factbase/domain_variables.py` | DB columns, input fields, config keys |
| `reflexion/reflexion.py` | A person's module map vs the call graph |

## Verification

| Tool | Does |
|---|---|
| `verify/depthlib.py` | Markdown and factbase parsing. Library. |
| `verify/run_depth_checks.py` | The four depth checks → `depth-report.md` |
| `verify/staleness.py` | Binds documents to source versions; incremental re-runs |
| `chartest/gen_skeletons.py` | Documented branches → executable test skeletons |

## Self-test

    sh tools/selftest.sh

Runs the whole chain against `examples/fixtures/java-dispatcher` and compares
with `expected/`. 18 checks. A tool change that alters the expected output is
a regression until those files are updated on purpose.

---

## Order

    extract_java.py  ->  build_factbase.py  ->  verify_bytecode.py
                                            ->  enumerate.py
                                                  ->  prioritize.py
                                                  ->  archetypes.py
                                                  ->  domain_variables.py
                                            ->  reflexion.py

    (documents are written)

    ->  run_depth_checks.py  ->  staleness.py --record
    ->  gen_skeletons.py

---

## A worked example

    REPO=/path/to/legacy-app

    python3 tools/factbase/extract_java.py --repo $REPO \
        --out $REPO/docs/facts --source-root src/main/java
    python3 tools/factbase/build_factbase.py --facts $REPO/docs/facts \
        --db $REPO/docs/facts/factbase.sqlite
    python3 tools/factbase/verify_bytecode.py --repo $REPO \
        --db $REPO/docs/facts/factbase.sqlite \
        --out $REPO/docs/facts/bytecode-verification.md

    python3 tools/factbase/enumerate.py \
        --db $REPO/docs/facts/factbase.sqlite --out $REPO/docs/enumeration
    python3 tools/factbase/prioritize.py --repo $REPO \
        --db $REPO/docs/facts/factbase.sqlite --enumeration $REPO/docs/enumeration
    python3 tools/factbase/archetypes.py --repo $REPO \
        --db $REPO/docs/facts/factbase.sqlite --enumeration $REPO/docs/enumeration

Then write documents, then:

    python3 tools/verify/run_depth_checks.py --repo $REPO \
        --db $REPO/docs/facts/factbase.sqlite \
        --docs $REPO/docs/modules/transactions \
        --enumeration $REPO/docs/enumeration \
        --out $REPO/docs/gap-analysis/depth-report.md

---

## Limits

`extract_java.py` is a lexical scanner. It does not resolve generics,
overloads or types. It marks what it cannot resolve rather than guessing, and
the bytecode oracle exists because a lexical scanner alone should not be
trusted with the enumeration.

Java only, today. A new language needs a new Layer 1 extractor emitting the
same JSONL records. Nothing above Layer 1 changes.

Where no extractor exists for a language, `shared/confidence-scoring.md`
forbids reporting findings about that language's code as High confidence.
