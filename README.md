# Legacy Documentation Skills

> AI Skill Library for Reverse Engineering Legacy Systems into High Quality Documentation.

---

## Overview

Legacy Documentation Skills is a modular AI Skill Library designed to transform legacy software systems into maintainable documentation.

Instead of asking AI to understand an entire codebase in one prompt, the repository breaks the work into specialized Skills.

Each Skill has a single responsibility and produces deterministic outputs that can be verified against source code.

The generated documentation can later be used by GitHub Copilot, Claude Code, ChatGPT, or other coding agents for maintenance, modernization, feature development, and knowledge transfer.

---

# Goals

This project focuses on four objectives.

1. Reverse engineer legacy systems.

2. Produce high-quality software documentation.

3. Preserve business knowledge hidden inside source code.

4. Build an AI-friendly knowledge base.

---

# Supported Technologies

The Skills are intentionally technology agnostic.

Examples include:

- Java
- Spring Boot
- Spring MVC
- WebSphere
- JBoss
- Tomcat
- Jakarta EE
- EJB
- Hibernate
- MyBatis
- JDBC
- COBOL
- .NET
- C#
- Node.js
- Express
- NestJS
- Python
- Django
- Flask
- Go
- PHP
- Oracle
- SQL Server
- PostgreSQL
- DB2
- MySQL

---

# Documentation Produced

The Skill Library generates documentation such as:

- System Overview
- Technology Stack
- Architecture
- Component Diagram
- Context Diagram
- Sequence Diagram
- Module Specification
- Business Rules
- API Documentation
- MQ Documentation
- Database Documentation
- ER Diagram
- Deployment Documentation
- Functional Specification
- Technical Specification
- Gap Analysis

---

# Repository Structure

```

legacy-documentation-skills/

├── skills/

├── orchestrators/

├── templates/

├── examples/

├── README.md

├── CHANGELOG.md

└── LICENSE

```

---

# Skill Execution Flow

```

Inventory

↓

Technology Discovery

↓

Architecture Discovery

↓

Module Analysis

↓

Database Analysis

↓

Interface Analysis

↓

Business Rule Extraction

↓

Sequence Discovery

↓

Specification Generation

↓

Gap Analysis

```

---

# Principles

Every Skill follows the same principles.

- Single Responsibility
- Deterministic Output
- Evidence Based
- Technology Neutral
- Incremental Documentation
- Human Readable
- AI Friendly

---

# Output Directory

Generated documents are written into:

```

docs/

```

Example:

```

docs/

overview/

architecture/

modules/

database/

integration/

business-rules/

sequence/

specifications/

deployment/

modernization/

```

---

# Evidence Rule

Every conclusion must be traceable back to source code.

The AI must never invent:

- architecture

- business rules

- database relationships

- APIs

- workflows

If evidence cannot be found, the output must explicitly state:

Unknown.

---

# Mermaid

All diagrams must use Mermaid.

Supported diagrams include:

- Flowchart
- Sequence Diagram
- Class Diagram
- ER Diagram
- State Diagram
- Journey Diagram

---

# Naming Convention

Markdown

lowercase-with-hyphen.md

Examples

system-overview.md

business-rules.md

loan-module.md

customer-api.md

---

# Design Philosophy

Large prompts are difficult to maintain.

Instead,

small deterministic Skills

↓

repeatable outputs

↓

reviewable documentation

↓

better AI coding.

---

# License

MIT