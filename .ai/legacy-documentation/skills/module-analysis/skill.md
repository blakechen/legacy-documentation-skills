---
name: module-analysis

description: |
  分析儲存庫中的每一個邏輯模組，並產生模組層級文件，
  描述其職責、結構、進入點、相依關係與公開介面。

version: 1.0.0

category: architecture

author: Legacy Documentation Skills

tags:
  - module
  - package
  - component
  - documentation
  - reverse-engineering

dependencies:
  - inventory
  - technology-discovery
  - architecture-discovery
  - artifact-enumeration

shared:
  - evidence-rules
  - confidence-scoring
  - documentation-style
  - markdown-style
  - naming-conventions
  - output-schema
  - quality-checklist
  - enumeration-first
  - iterative-depth
  - logic-depth

templates:
  - module
  - transaction

outputs:
  - docs/modules/
  - docs/modules/module-index.md
  - docs/modules/transactions/
---

# 目標

獨立分析每一個邏輯模組。

目標是描述每個模組包含什麼、
它是如何組織的，
以及它如何與其他模組互動。

業務意義（某條規則「為何」存在）不在本 Skill 的範圍內。

程式邏輯（每個方法「如何」處理一個請求）在範圍「之內」，
並由本 Skill 負責。

---

# 職責

本 Skill「應當」

- 辨識邏輯模組

- 辨識模組邊界

- 辨識模組職責

- 辨識進入點

- 辨識對外輸出的介面

- 辨識內部元件

- 辨識重要類別

- 辨識套件階層

- 辨識相依關係

- 辨識共用元件

- 辨識與該模組相關的組態

- 為每一個主要單元記錄其每一個方法的逐步處理邏輯

- 引用原始碼摘錄，佐證每一個關鍵決策、計算與 SQL 敘述

- 把輸入欄位經由中間變數對應到資料庫欄位與訊息欄位

- 以與語言無關的虛擬碼重述每個方法的邏輯

本 Skill「不得」

- 為邏輯指派業務意義或業務理由（見 business-rule-extraction）

- 配發 BR-ID

- 設計或正規化資料模型（見 database-analysis）

- 產生規格（見 specification-generation）

---

# 輸入

儲存庫清冊

技術探索

架構探索

原始碼

組態檔

---

# 交付物

docs/modules/

module-index.md

每個模組一份 Markdown 文件。

範例

loan.md

customer.md

payment.md

batch.md

security.md

common.md

---

# 證據規則

每一句陳述都必須參照可觀察的證據。

證據可包括

目錄

套件

命名空間

組態

Annotation

Class

Interface

相依關係

Unknown 是可以接受的。

絕不在可得證據之外推測模組職責。

---

# 完成判準

每一個邏輯模組都

- 已被辨識

- 已被記錄

- 已列出進入點

- 已列出相依關係

- 已列出公開介面

---

# 被下列 Skill 依賴

database-analysis

interface-analysis

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
- shared/iterative-depth.md
- shared/logic-depth.md

文件結構「應當」遵循：

- skills/templates/module.md
- skills/templates/transaction.md

違反任一共用規則的文件即為「不完整」，
無論其內容如何。

---

# Prompt

# 模組分析

---

## 目標

分析儲存庫中的每一個邏輯模組。

每個模組產生一份文件。

此外，若系統採用 dispatcher 模式，
還要為每一個交易／動作類別產生一份文件。

描述模組結構「以及」交易類別的行為。

---

## 關鍵：交易類別列舉

套用 shared/enumeration-first.md。

若架構探索辨識出 dispatcher 模式：

1. 找出「每一個」繼承交易基底類別的類別。

2. 找出「每一個」被 dispatcher 或其 factory／registry 參照的類別。

3. 建立一份包含「所有」交易類別及其檔案路徑的主清單。

4. 每個交易類別產生一份文件。

套用 shared/logic-depth.md。

以 skills/templates/transaction.md 作為每一份交易類別文件的
「必要」結構。不得省略章節。

每一份交易類別文件「應當」包含：

- 類別名稱、檔案路徑與行號範圍

- 一份列出「每一個」公開方法的 State Methods 索引

- 索引中每個方法各一個 `### Method:` 小節，每節包含
  Processing Flow、Pseudocode、Key Source Excerpts、Field Mapping、
  Branches and Conditions、資料庫存取、外部呼叫、錯誤路徑

- 一段跨越各狀態方法的端到端處理流程敘事

- 相關的 JSP 頁面

- 相關的 DB 物件

- 相關的 properties／組態

本 Skill「擁有」整條流水線中方法層級的邏輯敘事。

下游 Skill 參照這些文件，而不重新推導它們。

---

## 步驟 1

辨識模組

可能的範例

loan

customer

payment

account

authentication

authorization

batch

report

scheduler

integration

notification

common

shared

security

api

記錄

模組名稱

位置

證據

---

## 步驟 2

判定模組職責

描述

主要職責

所擁有的功能

主要套件

組態檔

避免假設。

只描述可觀察到的職責。

---

## 步驟 3

辨識進入點

範例

REST Controller

SOAP Endpoint

Message Listener

批次工作

排程器

CLI

Servlet

Filter

Interceptor

記錄

類型

位置

證據

---

## 步驟 4

辨識公開介面

範例

REST API

SOAP 介面

MQ Listener

發布的事件

公開服務

對外輸出的套件

記錄

介面

用途

證據

---

## 步驟 5

辨識內部結構

記錄

套件

子套件

主要類別

介面

組態

資源

工具類別

Factory

Builder

Adapter

---

## 步驟 6

辨識相依關係

記錄

內部相依

外部相依

共用模組

基礎設施相依

只記錄可觀察到的關聯。

---

## 步驟 7

辨識組態

找出

application.yml

properties

XML

Annotation

環境變數

模組專屬設定

記錄

用途

證據

---

## 步驟 8

產生模組摘要

包含

用途

職責

進入點

介面

相依關係

重要類別

組態

外部系統

證據

---

## 輸出格式

產生

docs/modules/module-index.md

每個模組產生一份文件。

在 docs/modules/transactions/ 底下，每個交易類別產生一份文件

範例

loan.md

customer.md

payment.md

security.md

batch.md

transactions/abankLogin.md

transactions/abankPwdChange.md

transactions/AbankSngMergeTrsf.md

---

## 模組文件結構

以 skills/templates/module.md 作為必要結構。

每一份模組文件都應包含

# 概觀

# 職責

# 目錄結構

# 套件結構

# 進入點

# 公開介面

# 內部元件

# 重要類別

# 交易類別索引

# 主要處理流程

# 相依關係

# 組態設定

# 外部系統

# 證據

---

## 輸出規則

以 shared/logic-depth.md 所定義的深度，
記錄每一個方法可觀察到的處理邏輯。

為每一個分支、計算與 SQL 敘述引用原始碼。
絕不在程式碼區塊內改寫。

絕不推測未記錄的行為。

絕不虛構不存在的方法、類別、資料表或欄位。

絕不為了省版面而縮短文件。深度就是交付物。

---

## 品質檢查清單

☐ 每個模組都已記錄

☐ 已辨識職責

☐ 已辨識進入點

☐ 已辨識公開介面

☐ 已記錄套件結構

☐ 已記錄相依關係

☐ 已記錄組態

☐ 已附上證據

☐ 沒有任何幻覺內容

☐ 逐交易文件數量與列舉數量相符

☐ 每一份交易文件都符合 skills/templates/transaction.md

☐ 每一個公開方法都有 `### Method:` 小節

☐ 每個方法小節都有 Processing Flow、Pseudocode、
  至少一段帶 file:line 的原始碼摘錄，以及 Field Mapping

☐ 未指派業務意義（BR-ID 只做參照，絕不自行創造）

---

## 經驗教訓

### 問題：產出了模組索引，卻沒有逐交易文件

AI 只產出了 `docs/modules/module-index.md`（1 個檔案），
而不是每個交易類別一個檔案（預期 458 個）。
這使得所有下游 Skill（業務規則、循序、規格）都無法正確執行。

**修正**：本 Skill 的主要交付物「不是」單一索引檔。它是：
- `docs/modules/module-index.md`（摘要）
- 「加上」為 `docs/enumeration/transaction-classes.txt` 中
  「每一個」類別產生的 `docs/modules/transactions/[ClassName].md`

完成判準：`ls docs/modules/transactions/*.md | wc -l` 必須等於
`docs/enumeration/transaction-classes.txt` 的行數。

### 問題：以略過而非分批來因應規模

面對 458 個類別時，正確的做法是分批處理（例如依套件），
而「不是」產出一份摘要就宣告完成。

**修正**：若需要分批處理，就在 `docs/gap-analysis/progress.md`
記錄進度，並在後續各趟持續進行，直到所有類別都被涵蓋。

---

結束。
