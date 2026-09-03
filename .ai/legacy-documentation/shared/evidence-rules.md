# Evidence Rules

## Objective

Ensure every conclusion produced by any Skill is supported by verifiable evidence.

---

## Principles

Evidence always takes precedence over inference.

Unknown is preferable to guessing.

Never fabricate information.

Every important statement shall be traceable.

---

## Acceptable Evidence

### Source Code

- Class
- Interface
- Method
- Package
- Namespace
- Annotation

### Configuration

- application.yml
- application.properties
- XML
- JSON
- YAML
- Environment Variables

### Build

- pom.xml
- build.gradle
- package.json
- Dockerfile

### Database

- SQL
- DDL
- Stored Procedure
- Trigger
- Constraint

### Integration

- REST Endpoint
- SOAP WSDL
- MQ Configuration
- Kafka Configuration
- Scheduler

---

## Evidence Format

Source

Location

Artifact

Line Range

Factbase commit

Confidence

### Version pinning

A line citation is true of one version of a file. Record the version.

Every generated document SHALL carry, in its metadata block

    Factbase commit: <sha>

and the per-unit source hashes SHALL be recorded by
`tools/verify/staleness.sh --record` after the unit passes its depth checks.

See shared/incremental-update.md. Without this, a citation cannot be
distinguished from a citation that has rotted.

---

## Missing Evidence

If evidence cannot be located

Output

Unknown

Do not infer.

---

## The Citation Rule

Every assertion about behaviour SHALL carry a citation, or SHALL be written
as Unknown.

    <assertion>   requires   path/to/File.java:<line>-<line>
                             or a table from the enumeration
                             or a domain variable from the derived list
                             or a configuration key with its file

An assertion with no citation is not a low-confidence assertion. It is not an
assertion; it is Unknown.

### Why this replaces a banned-word list

Earlier versions of this rule banned hedging words: "it appears", "probably",
"should". The words were the target, not the problem.

Removing the hedge from an unsupported claim does not make the claim
supported. It makes it read as certain, which is worse: the reader loses the
only signal that the writer was unsure.

Hedging language is a symptom. The citation requirement addresses the cause.

So:

- an assertion with a citation needs no hedge; write it plainly
- an assertion without a citation is written as Unknown, with what is missing
- where evidence supports a range of readings, state the readings and cite
  the evidence for each

Never write "the developer intended". Intent is not an observable artefact.

---

## Traceability

Every generated document shall include

Evidence

Source Artifact

Reference