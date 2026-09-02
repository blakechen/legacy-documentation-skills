# Pipeline

Stage 1

Inventory

↓

Technology Discovery

↓

Architecture Discovery + Custom Framework Detection

---

Stage 1.5

Artifact Enumeration

Transaction Class Enumeration

↓

DB Object Class Enumeration

↓

Servlet Enumeration

---

Stage 2

Module Analysis (per-module + per-transaction)

↓

Database Analysis (from DB object enumeration)

↓

Interface Analysis

---

Stage 3

Business Rule Extraction (per transaction class)

↓

Sequence Discovery (per transaction class)

---

Stage 4

Per-Transaction Specification Generation

↓

System Specification Generation

↓

Gap Analysis