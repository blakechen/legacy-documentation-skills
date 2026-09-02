---
name: database-analysis

description: |
  分析程式碼庫的持久層，記錄資料庫物件、實體對應、
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

記錄持久層。

只聚焦於資料持久化。

業務意義不在範圍內。

---

# 職責

本 Skill 應（SHALL）

- 辨識資料庫技術

- 辨識綱要（schema）

- 辨識資料表

- 辨識檢視表

- 辨識序列（sequence）

- 辨識索引

- 辨識實體類別

- 辨識 repository 類別

- 辨識 DAO 類別

- 辨識 SQL 敘述

- 辨識預存程序

- 辨識 ORM 對應

- 辨識交易註解

- 辨識資料庫組態設定

本 Skill 不得（SHALL NOT）

- 推測業務規則

- 解釋 SQL 的意圖

- 描述工作流程

- 產生規格

- 分析驗證邏輯（由 module-analysis 負責，見 shared/logic-depth.md）

---

# 輸入

程式碼庫清冊

技術探索

架構探索

模組分析

原始碼

SQL 檔案

資料庫指令碼

組態檔案

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

每個資料庫物件都必須有證據。

證據包含

DDL

SQL

註解（Annotation）

Repository

DAO

XML 對應

組態設定

寫「Unknown（未知）」是可以接受的。

絕不虛構關聯。

---

# 完成條件

每項持久化技術都已記錄。

每個資料表都已建立索引。

每個實體都已記錄。

每個 repository 都已記錄。

ER 圖已產生。

---

# 被以下 Skill 依賴

business-rule-extraction

sequence-discovery

specification-generation

---

# 共用規則

本 Skill 的每一份產出都應（SHALL）符合：

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

文件結構應（SHALL）依循：

- skills/templates/database.md

違反任一共用規則的文件即為「未完成」，
無論其內容多寡。

---

# 提示（Prompt）

# 資料庫分析（Database Analysis）

---

## 目標

分析持久層。

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

辨識綱要

找出

Schema

Catalog

資料庫名稱

擁有者

記錄

綱要

用途

證據

---

## 步驟 3

辨識資料表

針對每個資料表

記錄

資料表名稱

綱要

主鍵

外鍵

索引

被誰引用

對應的實體

證據

---

## 步驟 4

辨識檢視表

記錄

檢視表名稱

用途

被誰引用

證據

---

## 步驟 5

辨識序列

記錄

序列

使用者（consumer）

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

XML 對應

MyBatis Mapper

自訂資料庫物件模式（關鍵）：

若系統使用一個以程式化方式定義欄位的基底類別：

- 找出資料庫物件基底類別（例如 SecuredDBObject、DBObject）。

- 列舉「每一個」子類別。

- 針對每個子類別，擷取：

  - 由 setTargetTable() 取得的資料表名稱

  - 由 addField() 呼叫取得的欄位（名稱、型別、長度、是否可為 null、說明）

  - 由 addKey() 取得的主鍵

  - 由 setDescription() 取得的說明

- 這等同於 DDL 的擷取。

對資料庫物件類別套用 shared/enumeration-first.md。

記錄

實體

對應的資料表

欄位與其型別

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

資料庫存取模式

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

預存程序

原生查詢（Native Query）

具名查詢（Named Query）

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

產生 Mermaid ER 圖。

只納入已驗證的實體。

不要推測基數（cardinality）。

基數未知是可以接受的。

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

☐ 已記錄綱要

☐ 已記錄資料表

☐ 已記錄檢視表

☐ 已記錄序列

☐ 已記錄 repository 層

☐ 已記錄 ORM

☐ 已記錄 SQL

☐ 已記錄交易

☐ Mermaid ER 圖語法正確

☐ 已納入證據

☐ 無幻覺內容

---

結束。
