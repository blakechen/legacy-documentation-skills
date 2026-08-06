# Business Rule Extraction

---

# Goal

Extract business rules from legacy implementation.

The output must describe WHAT the system enforces.

Not HOW the code works.

---

# Rule Discovery Process

## Step 1

Analyse Conditional Logic

Search:

if

else

switch

case

ternary

guard clause

validation method


Example:

Source:

if(amount > 1000000)

requireApproval();


Convert:

Rule:

Large transaction requires approval.

Evidence:

Class

Method

Condition


---

# Step 2

Analyse Validation

Search:

Validator

validate

check

verify

assert

throw exception


Identify:

Input limitation

Required field

Format restriction

Range limitation

Dependency rule


---

# Step 3

Analyse Status Rules

Search:

enum

status

state

transition

workflow


Identify:

Allowed states

Forbidden transitions

State conditions


Example:

PENDING

↓

APPROVED

Only after manager approval.

---

# Step 4

Analyse Calculation Rules

Search:

Arithmetic

Formula

Percentage

Interest

Amount

Balance

Rate


Document:

Input

Formula

Output

Evidence


---

# Step 5

Analyse Authorization Rules

Search:

Role

Permission

Authority

User Level

Access Control


Document:

Actor

Permission

Condition

Evidence


---

# Step 6

Analyse Database Rules

Search:

CHECK

Trigger

Stored Procedure

Function

Constraint


Document:

Rule

Object

Condition

Evidence


---

# Step 7

Analyse Configuration Rules

Search:

threshold

limit

switch

feature flag

properties

yaml


Document:

Configuration

Meaning

Usage

Evidence


---

# Step 8

Analyse Exception Rules

Search:

Exception

Error Code

Error Message

Catch


Convert:

Technical Exception

into

Business Constraint

only if evidence supports it.


---

# Business Rule Document Format

Each rule must contain:

```

# BR-ID

BR-001


## Name

Rule Name


## Description

Human readable rule.


## Category

Validation

Calculation

Authorization

Workflow

Restriction

Integration


## Condition

When does this rule apply?


## Action

What happens?


## Evidence

Source:

Class:

Method:

File:

SQL:

Configuration:


## Confidence

High / Medium / Low

```

---

# Output Rules

Never write:

"The system probably..."

"The developer intended..."

"It seems..."

Use:

"The code enforces..."

only when evidence exists.


---

# Forbidden

Do not:

invent business meaning

guess domain terminology

rename entities without evidence

infer user requirements

---

# Quality Checklist

✓ Rule has ID

✓ Rule has description

✓ Rule has condition

✓ Rule has action

✓ Rule has evidence

✓ Confidence assigned

✓ No assumptions

✓ No invented business meaning

✓ Source traceable

---

End.