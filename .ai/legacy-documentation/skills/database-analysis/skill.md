---
name: database-analysis

description: |
  分析儲存庫的持久化層，並記錄資料庫物件、實體對應、
  repository、SQL 使用情形與持久化技術。

version: 1.0.0

category: persistence

author: Legacy Documentation Skills

tags:
  - database
  - sql
  - repository
  - dao
  - entity
  - persistence

dependencies:
  - inventory
  - technology-discovery
  - architecture-discovery
  - artifact-enumeration
  - module-analysis

shared:
  - evidence-rules
  - confidence-scoring
  - documentation-style
  - markdown-style
  - naming-conventions
  - output-schema
  - quality-checklist
  - enumeration-first
  - mermaid-guidelines
  - logic-depth

templates:
  - database

outputs:
  - docs/database/database-overview.md
  - docs/database/table-reference.md
  - docs/database/entity-mapping.md
  - docs/database/sql-reference.md
  - docs/database/er-diagram.md
---

# 目標

記錄持久化層。

只聚焦於資料持久化。

業務意義不在範圍內。

---

# 職責

本 Skill「應當」

- 辨識資料庫技術

- 辨識 schema

- 辨識資料表

- 辨識檢視表

- 辨識序號產生器（sequence）

- 辨識索引

- 辨識實體類別

- 辨識 repository 類別

- 辨識 DAO 類別

- 辨識 SQL 敘述

- 辨識 stored procedure

- 辨識 ORM 對應

- 辨識交易 annotation

- 辨識資料庫組態

本 Skill「不得」

- 推測業務規則

- 解釋 SQL 的意圖

- 描述工作流程

- 產生規格

- 分析驗證邏輯（由 module-analysis 負責，見 shared/logic-depth.md）

---

# 輸入

儲存庫清冊

技術探索

架構探索

模組分析

原始碼

SQL 檔

資料庫腳本

組態檔

---

# 交付物

docs/database/

database-overview.md

table-reference.md

entity-mapping.md

sql-reference.md

er-diagram.md

---

# 證據規則

每一個資料庫物件都必須有證據。

證據包括

DDL

SQL

Annotation

Repository

DAO

XML 對應檔

組態

Unknown 是可以接受的。

絕不憑空造出關聯。

---

# 完成判準

每一項持久化技術都已記錄。

每一張資料表都已建立索引。

每一個實體都已記錄。

每一個 repository 都已記錄。

已產生 ER 圖。

---

# 被下列 Skill 依賴

business-rule-extraction

sequence-discovery

specification-generation

---

# 共用規則

本 Skill 的每一項輸出「應當」遵循：

- shared/evidence-rules.md
- shared/confidence-scoring.md
- shared/documentation-style.md
- shared/markdown-style.md
- shared/naming-conventions.md
- shared/output-schema.md
- shared/quality-checklist.md
- shared/enumeration-first.md
- shared/mermaid-guidelines.md
- shared/logic-depth.md

文件結構「應當」遵循：

- skills/templates/database.md

違反任一共用規則的文件即為「不完整」，
無論其內容如何。

---

# Prompt

# 資料庫分析

---

## 目標

分析持久化層。

不要分析業務邏輯。

---

## 步驟 1

辨識資料庫技術

範例

DB2

Oracle

SQL Server

MySQL

PostgreSQL

SQLite

MongoDB

Redis

記錄

技術

版本（若已知）

證據

---

## 步驟 2

辨識 Schema

找出

Schema

Catalog

資料庫名稱

擁有者

記錄

Schema

用途

證據

---

## 步驟 3

辨識資料表

對每一張資料表

記錄

資料表名稱

Schema

主鍵

外鍵

索引

被誰參照

對應的實體

證據

---

## 步驟 4

辨識檢視表

記錄

檢視表名稱

用途

被誰參照

證據

---

## 步驟 5

辨識序號產生器

記錄

Sequence

使用者

證據

---

## 步驟 6

辨識實體對應

找出

@Entity

@Table

@Column

@OneToOne

@OneToMany

@ManyToOne

@ManyToMany

XML 對應檔

MyBatis Mapper

自製 DB 物件模式（關鍵）：

若系統使用帶有程式化欄位定義的基底類別：

- 找出 DB 物件基底類別（例如 SecuredDBObject、DBObject）。

- 列舉「每一個」子類別。

- 對每一個子類別，取出：

  - 來自 setTargetTable() 的資料表名稱

  - 來自 addField() 呼叫的欄位（名稱、型別、長度、是否可為空、說明）

  - 來自 addKey() 的主鍵

  - 來自 setDescription() 的說明

- 這等同於一次 DDL 抽取。

對 DB 物件類別套用 shared/enumeration-first.md。

記錄

實體

對應的資料表

欄位與型別

關聯

證據

---

## 步驟 7

辨識 Repository 層

找出

Repository

DAO

Mapper

JdbcTemplate

NamedParameterJdbcTemplate

記錄

Repository

實體

資料庫存取樣式

證據

---

## 步驟 8

辨識 SQL

找出

SELECT

INSERT

UPDATE

DELETE

MERGE

WITH

CALL

Stored Procedure

Native Query

Named Query

記錄

位置

操作

資料表

證據

不要解釋業務目的。

---

## 步驟 9

辨識交易

找出

@Transactional

TransactionTemplate

JTA

EJB Transaction

記錄

交易類型

位置

證據

---

## 步驟 10

產生 ER 圖

產生 Mermaid ER Diagram。

只納入已驗證的實體。

不要推測基數。

未知的基數是可以接受的。

---

## 輸出規則

絕不推測業務意義。

絕不解釋業務規則。

絕不解釋交易工作流程。

絕不推測隱含的資料表關聯。

絕不產生循序圖。

---

## 必要輸出

產生

docs/database/database-overview.md

docs/database/table-reference.md

docs/database/entity-mapping.md

docs/database/sql-reference.md

docs/database/er-diagram.md

---

## 品質檢查清單

☐ 已辨識資料庫

☐ 已記錄 schema

☐ 已記錄資料表

☐ 已記錄檢視表

☐ 已記錄序號產生器

☐ 已記錄 repository 層

☐ 已記錄 ORM

☐ 已記錄 SQL

☐ 已記錄交易

☐ Mermaid ER 圖語法正確

☐ 已附上證據

☐ 沒有任何幻覺內容

---

結束。
