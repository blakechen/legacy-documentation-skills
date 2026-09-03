# Global Quality Checklist

Every Skill shall verify:

- Evidence recorded
- References valid
- No hallucinations
- No duplicated findings
- No undocumented assumptions
- Unknown used when evidence missing
- Terminology consistent
- Markdown valid
- Mermaid valid (if present)
- Output files generated
- Traceability preserved

---

# Mechanical Gates

Assertion is not verification. Every gate below is a command with an exit
status, and the Skill that owns it SHALL run it. See
shared/mechanical-verification.md.

| Gate | Command | Owner |
|---|---|---|
| Factbase built | `tools/factbase/build_factbase.sh` | fact-extraction |
| Source scan independently checked | `tools/factbase/verify_bytecode.sh` | fact-extraction |
| Enumeration derived from the factbase | `tools/factbase/enumerate.sh` | artifact-enumeration |
| Units ordered by value | `tools/factbase/prioritize.sh` | artifact-enumeration |
| Clone families collapsed | `tools/factbase/archetypes.sh` | archetype-clustering |
| Domain variables derived | `tools/factbase/domain_variables.sh` | business-rule-extraction |
| Architecture model tested | `tools/reflexion/reflexion.sh` | reflexion-check |
| Documents depth-complete | `tools/verify/depth_checks.sh` | gap-analysis |
| Documents match current source | `tools/verify/staleness.sh` | gap-analysis |

A Skill that reports a gate as passed without the command output is in
violation of this checklist.

---

# Self-Test

The tools themselves are covered by a fixture:

    sh tools/selftest.sh

A change to a tool that alters the expected output in
`examples/fixtures/java-dispatcher/expected/` is a regression until those
files are updated deliberately.
