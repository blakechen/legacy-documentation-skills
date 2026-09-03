# Fixture: java-dispatcher

A miniature legacy system that reproduces, on purpose, the four extraction
failures recorded in `shared/enumeration-first.md` and
`shared/custom-framework-recognition.md`.

| Trap | Where | What it breaks |
|---|---|---|
| Base class lives in a jar, not in the source tree | `StdTrxObject`, `StdDbObject` in `lib-src/` | "read the base class first" strategies |
| Transitive inheritance | `AcctInquiryTrx` → `BaseInquiryTrx` → `StdTrxObject` | `grep "extends StdTrxObject"` misses it |
| Reflection registration | `TrxFactory.create` builds the class name from a prefix | dispatcher-reference scans find no class names |
| Dead code | `LegacyFxTrx` is registered nowhere | equal-weight documentation of 100% of units |

## Expected facts

`expected/` holds the enumeration this repository's tools must reproduce.
`tools/selftest.sh` regenerates the facts and diffs them against `expected/`.
It also checks that the tools can REJECT: a plausible but wrong unit
document, and a factbase with a class missing from it.
A change to the extractor that alters these files is a regression until the
expected files are updated deliberately.

## Layout

    lib-src/   framework and servlet API stubs; compiled into a jar
    src/       the application under analysis
    expected/  golden enumeration output
