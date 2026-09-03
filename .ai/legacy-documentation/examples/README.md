# Examples

Two kinds of thing live here, and they do different jobs.

---

## `fixtures/` — executable golden cases

Small, complete, runnable source trees with the expected tool output beside
them.

    sh tools/selftest.sh

runs the whole tool chain against `fixtures/java-dispatcher` and diffs the
result against `fixtures/java-dispatcher/expected/`. 20 checks, two of
which must FAIL: a plausible but wrong document, and a class missing from
the factbase.

A change to a tool that alters those files is a regression until the expected
files are updated deliberately.

### `fixtures/java-dispatcher`

A miniature legacy system that reproduces, on purpose, the four extraction
failures recorded in `shared/enumeration-first.md` and
`shared/custom-framework-recognition.md`:

| Trap | What it breaks |
|---|---|
| Base class in a jar, not in the source tree | strategies that start by reading the base class |
| Transitive inheritance | `grep "extends StdTrxObject"` |
| Reflection registration | scanning the dispatcher for class names |
| Dead code | documenting every unit at equal weight |

It also carries a copy-and-paste family, so archetype clustering has
something to find, and two unit documents — one correct, one plausible but
wrong — so the depth checks are shown to reject as well as accept.

---

## `cobol/`, `dotnet/`, `nodejs/`, `spring-boot/`, `websphere/` — narrative examples

Descriptions of what a run against that kind of system should look like:
technology summary, expected documents, validation notes.

Repository source code is intentionally excluded.

These are for orientation. They are NOT regression tests: nothing checks
them, and nothing can. Only `fixtures/` carries expected output that a
program compares.

---

## Adding a fixture

A fixture earns its place by reproducing a failure that actually happened.

1. Put the smallest source tree that reproduces it in `fixtures/<name>/`.
2. Record what the tools should produce in `fixtures/<name>/expected/`.
3. Add the checks to `tools/selftest.sh`.
4. Write down, in the fixture's README, which failure it reproduces.

A fixture that reproduces no failure is a demonstration, not a test.
