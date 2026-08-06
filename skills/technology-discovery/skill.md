---
name: technology-discovery

description: |
  Discover technologies, frameworks, runtime environments,
  libraries and infrastructure components used by the repository.

version: 1.0.0

category: discovery

author: Legacy Documentation Skills

tags:
  - technology
  - framework
  - runtime
  - discovery

supported-languages:
  - Java
  - Kotlin
  - Scala
  - COBOL
  - C#
  - VB.NET
  - Node.js
  - JavaScript
  - TypeScript
  - Python
  - Go
  - PHP

dependencies:
  - inventory

outputs:
  - docs/overview/technology-stack.md
  - docs/overview/frameworks.md
  - docs/overview/runtime-environment.md
  - docs/overview/dependency-summary.md
---

# Objective

Discover technologies used by the repository.

Only identify observable technologies.

Do not analyse architecture.

Do not analyse business logic.

---

# Responsibilities

This Skill SHALL

- identify programming languages

- identify frameworks

- identify runtime

- identify application servers

- identify databases

- identify ORM frameworks

- identify logging frameworks

- identify testing frameworks

- identify build systems

- identify dependency managers

- identify messaging technologies

- identify cache technologies

- identify scheduling technologies

- identify container technologies

- identify cloud technologies

- identify API technologies

- identify security frameworks

This Skill SHALL NOT

- infer architecture

- analyse business rules

- analyse source code flow

- generate specifications

- generate sequence diagrams

---

# Inputs

Repository Inventory

Build Files

Configuration Files

Dependency Definitions

Container Files

---

# Deliverables

docs/overview/

technology-stack.md

frameworks.md

runtime-environment.md

dependency-summary.md

---

# Evidence Rule

Every identified technology must be supported by evidence.

Examples

pom.xml

build.gradle

package.json

Dockerfile

server.xml

application.yml

Imports

Annotations

Configuration

Unknown is acceptable.

Never guess.

---

# Completion Criteria

Every major technology has been classified.

Every framework has evidence.

Every runtime has evidence.

Every database technology has evidence.

---

# Required By

architecture-discovery

module-analysis

database-analysis

interface-analysis
