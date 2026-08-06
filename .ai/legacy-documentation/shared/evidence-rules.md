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

Optional Line Number

Confidence

---

## Missing Evidence

If evidence cannot be located

Output

Unknown

Do not infer.

---

## Forbidden

Never write

"It probably..."

"It appears..."

"It should..."

"The developer intended..."

Replace with

"Unknown"

---

## Traceability

Every generated document shall include

Evidence

Source Artifact

Reference