# Transaction Specification

> This template is MANDATORY for every file under `docs/modules/transactions/`
> and `docs/specifications/transactions/`.
>
> Depth requirements: see `shared/logic-depth.md`.
>
> A document with an empty Processing Detail section is INCOMPLETE.

---

## Transaction Class

---

## Entry URL

---

## Routing Parameters

| Parameter | Value |
|-----------|-------|

---

## Purpose

---

## State Methods (Index)

One row per public method. This table is an index only.

Every row MUST have a matching `### Method:` subsection in Processing Detail below.

| Method | Purpose (one line) | Entry Condition | Next State / Output |
|--------|--------------------|-----------------|---------------------|

---

## End-to-End Processing Flow

Numbered narrative of one complete execution of this transaction, from the entry
URL through each state method to the final page or redirect.

Name each state transition and the condition that causes it.

---

## Processing Detail

One subsection per method listed in the State Methods index.

All four depth elements are mandatory. See `shared/logic-depth.md`.

### Method: `methodName`

**Signature**: `<visibility> <returnType> methodName(<params>)`

**Source**: `path/to/Class.java:<startLine>-<endLine>`

**Invoked when**: the state value, routing parameter or caller that reaches this method

#### Processing Flow

1. What it reads, checks, calls, writes, or where it goes next.

2. ...

3. ...

#### Pseudocode

```text
BEGIN methodName
  READ ...
  IF <condition> THEN
    ...
    RETURN <state>
  END IF
  CALL ...
  WRITE ...
  RETURN <state>
END
```

#### Key Source Excerpts

`path/to/Class.java:120-128`

```java
verbatim source lines
```

Explanation: one or two sentences on what this decides or computes.

#### Field Mapping

| Input Field | Source | Intermediate | Transformation | Target | Target Kind |
|-------------|--------|--------------|----------------|--------|-------------|

#### Branches and Conditions

| # | Condition | When True | When False | Evidence |
|---|-----------|-----------|------------|----------|

#### Database Access In This Method

| # | Table | Operation | Key / Where | Columns Read | Columns Written | Evidence |
|---|-------|-----------|-------------|--------------|-----------------|----------|

#### External Calls

| Target | Protocol | Request Fields | Response Fields | On Failure | Evidence |
|--------|----------|----------------|-----------------|------------|----------|

#### Error Paths

| Trigger | Detection | Handling | User-Visible Result | Evidence |
|---------|-----------|----------|---------------------|----------|

#### Business Rules Enforced Here

| BR-ID | Enforced At (step #) |
|-------|----------------------|

---

The sections below are transaction-wide rollups. They summarise across all methods.
They never replace the per-method detail above.

---

## Input Fields

| Field | Type | Validation | Required |
|-------|------|------------|----------|

---

## Business Rules

| Rule ID | Description |
|---------|-------------|

---

## Database Access

| Table | Operation | Condition |
|-------|-----------|-----------|

---

## External System Calls

| System | Protocol | Purpose |
|--------|----------|---------|

---

## Output Pages

| State | JSP/Redirect |
|-------|--------------|

---

## Error Handling

| Error | Handler | Output |
|-------|---------|--------|

---

## Security

---

## Related Sequences

---

## Related Business Rules

---

## Evidence
