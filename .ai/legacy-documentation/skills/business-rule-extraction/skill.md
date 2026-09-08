---
name: business-rule-extraction

description: |
  從老舊原始碼、資料庫邏輯、組態與整合定義中，
  抽取隱藏其中的業務規則。
  把技術實作轉換成人類可讀、
  且具可追溯證據的規則。

version: 1.0.0

category: business-analysis

author: Legacy Documentation Skills

tags:
  - business-rule
  - validation
  - rule-mining
  - reverse-engineering
  - legacy

dependencies:
  - inventory
  - architecture-discovery
  - fact-extraction
  - artifact-enumeration
  - module-analysis
  - database-analysis
  - interface-analysis

shared:
  - business-rule-criteria
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
  - fact-layer
  - archetypes

templates:
  - business-rule

outputs:
  - docs/business-rules/domain-variables.txt
  - docs/business-rules/domain-variables-report.md
  - docs/business-rules/business-rule-index.md
  - docs/business-rules/transactions/
  - docs/business-rules/cross-cutting.md
  - docs/business-rules/technical-logic.md
---

# 目標

發掘系統內部所實作的業務規則。

把技術條件轉換成可讀的規則。

每一條規則都必須可追溯到原始碼證據。

套用 shared/business-rule-criteria.md。

規則是一個讀取或寫入「領域變數」的條件。其餘一切都是技術邏輯，
屬於模組文件。沒有這項判定測試，
每一個 null 檢查都會變成業務規則，
而真正重要的規則會淹沒在雜訊之中。

---

# 職責

本 Skill「應當」

- 辨識條件邏輯

- 辨識驗證規則

- 辨識計算規則

- 辨識狀態轉換規則

- 辨識授權規則

- 辨識以例外為基礎的規則

- 辨識由組態驅動的規則

- 辨識資料庫規則

- 辨識 stored procedure 規則

- 辨識整合路由規則

- 辨識工作流程限制

本 Skill「不得」

- 修改原始碼

- 產生新的業務邏輯

- 假設業務意圖

- 憑空造出缺少的規則

- 建立功能規格

- 把技術邏輯記錄成業務規則

- 在沒有指名所治理之領域變數的情況下回報規則

---

# 輸入

原始碼

模組分析

資料庫分析

介面分析

架構分析

組態檔

SQL

Stored Procedure

訊息定義

---

# 規則發掘來源

分析：

## 應用程式碼

範例：

if

switch

case

enum

validator

exception

assertion

annotation

state machine

## 資料庫邏輯

範例：

SQL CASE

CHECK Constraint

Trigger

Stored Procedure

Function

## 組態

範例：

Properties

YAML

XML

Feature Flag

門檻值

## 整合

範例：

訊息路由

錯誤碼對應

回應處理

---

# 交付物

docs/business-rules/

business-rule-index.md

transactions/[ClassName].md

cross-cutting.md

`transactions/` 底下每個交易類別一個檔案，以類別命名。

該類別所擁有的每一條規則都放在那個檔案裡，
以「業務規則文件格式」寫成一個 `## BR-NNN` 章節。

不屬於任何單一交易類別的規則放進 `cross-cutting.md`。

BR-ID 在所有檔案之間全域唯一。

`business-rule-index.md` 把每一個 BR-ID 對應到它所屬的檔案。

---

# 證據規則

每一條業務規則都必須包含證據。

證據格式：

原始碼檔案

Class

Method

行號參照（若有）

SQL

組態鍵

訊息定義

---

# 規則信心度

每一條規則都必須附上信心度。

值：

High

直接實作的規則。

Medium

證據充分，但需要詮釋。

Low

可能的規則，證據不完整。

---

# 完成判準

當下列條件成立時，業務規則即為完成：

- `docs/business-rules/domain-variables.txt` 存在且非空

- 每一條記錄的規則都指名至少一個領域變數

- `docs/business-rules/technical-logic.md` 存在，
  使得被排除的內容可見、可供審閱

- 所有驗證邏輯都已檢視

- 所有決策點都已檢視

- 所有狀態變更都已檢視

- 所有計算都已檢視

- 所有授權檢查都已檢視

- 已記錄證據

- `ls docs/business-rules/transactions/*.md | wc -l` 等於
  `docs/enumeration/transaction-classes.txt` 的行數

即使某個交易類別沒有產出任何規則，仍然要有一個檔案，
記錄 `No business rules found` 以及所檢視過的方法。
檔案缺席是落差；結果為空則是一項發現。

---

# 被下列 Skill 依賴

sequence-discovery

specification-generation

gap-analysis

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

- skills/templates/business-rule.md

違反任一共用規則的文件即為「不完整」，
無論其內容如何。

---

# Prompt

# 業務規則抽取

---

# 目標

從老舊實作中抽取業務規則。

每一筆業務規則條目以業務語彙描述系統「施行了什麼」。

程式碼「如何」實作它，由 module-analysis 記錄於
docs/modules/transactions/[ClassName].md。不要在此重複那段敘事。

取而代之，每一條規則「應當」連結到實作它的方法小節：

`Implemented at: ../../modules/transactions/[ClassName].md#method-[name] (step N)`

這樣的分工是刻意的。

它不是任一份文件可以淺薄的理由。

---

# 關鍵：窮盡式抽取

套用 shared/enumeration-first.md。

套用 shared/iterative-depth.md。

1. 從模組分析取得完整的交易類別清單。

2. 對「每一個」交易類別，分析「每一個」狀態方法。

3. 抽取「所有」條件邏輯、驗證、計算、授權與狀態規則。

4. 找到幾條規則之後「不要」停止。持續進行，直到每一個交易類別都已檢視。

5. 走訪 `docs/enumeration/transaction-classes.txt` 中的完整清單，
   為每個交易類別寫出一個檔案到
   `docs/business-rules/transactions/[ClassName].md`。

6. 該清單中的每一個交易類別都要有檔案，
   包括那些沒有產出任何規則的類別。

---

# 規則發掘流程

## 步驟 0

推導領域變數。

    sh tools/shell/factbase/domain_variables.sh \
        --facts <repo>/docs/facts \
        --enumeration <repo>/docs/enumeration \
        --out <repo>/docs/business-rules/domain-variables.txt

這會產出業務所擁有的 DB 欄位、輸入欄位與組態鍵的集合，
每一項都附帶證據。

該清單是從程式碼推導而來，因此凡是動態組出欄位名稱之處都會不完整。
請以人工補上那些名稱，並記錄原因。

在此檔案存在之前，不得開始任何規則抽取。

---

## 步驟 0b

套用判定測試。

對每一個候選條件，問：

> 這個條件讀取或寫入了哪一個領域變數？

指名了一個   -> 業務規則。把該變數記錄在證據中。

一個都沒有   -> 技術邏輯。記錄於
                `docs/business-rules/technical-logic.md`，
                以逐單元計數的形式，而不是當成規則。

判斷不出來   -> 記錄成信心度 Low 的規則，並說明缺少了什麼證據。
                不要默默地把它丟掉。

「永遠屬於技術邏輯」與「永遠屬於業務規則」的清單，
見 shared/business-rule-criteria.md。

---

## 步驟 1

分析條件邏輯

搜尋：

if

else

switch

case

三元運算

guard clause

驗證方法


範例：

原始碼：

if(amount > 1000000)

requireApproval();


轉換為：

規則：

大額交易需要核准。

領域變數：

TRSFAMT（input-field）、LIMIT_CTL.DAILY_MAX（db-column）

證據：

Class

Method

行號範圍

條件成立時的結果，以及不成立時的結果

反例，這「不是」規則：

原始碼：

if(acctNo == null) return;

沒有為了業務決策而讀取任何領域變數；這是一個 guard。
它應記錄於 technical-logic.md，並出現在模組文件的
Processing Flow 中，而不是這裡。


---

# 步驟 2

分析驗證

搜尋：

Validator

validate

check

verify

assert

throw exception


辨識：

輸入限制

必填欄位

格式限制

範圍限制

相依規則


---

# 步驟 3

分析狀態規則

搜尋：

enum

status

state

transition

workflow


辨識：

允許的狀態

禁止的轉換

狀態條件


範例：

PENDING

→
APPROVED

僅在主管核准之後。

---

# 步驟 4

分析計算規則

搜尋：

算術運算

公式

百分比

利息

金額

餘額

費率


記錄：

輸入

公式

輸出

證據


---

# 步驟 5

分析授權規則

搜尋：

Role

Permission

Authority

使用者層級

存取控制


記錄：

行為者

權限

條件

證據


---

# 步驟 6

分析資料庫規則

搜尋：

CHECK

Trigger

Stored Procedure

Function

Constraint


記錄：

規則

物件

條件

證據


---

# 步驟 7

分析組態規則

搜尋：

threshold

limit

switch

feature flag

properties

yaml


記錄：

組態

意義

用法

證據


---

# 步驟 8

分析例外規則

搜尋：

Exception

錯誤碼

錯誤訊息

Catch


只有在證據支持時，才把

技術例外

轉換為

業務限制。


---

# 業務規則文件格式

每一條規則都是其所屬檔案中的一個章節，而不是獨立文件。

以 `## BR-NNN` 作為章節標題，使錨點保持穩定。

每一條規則都必須包含：

```

# BR-ID

BR-001


## 名稱

規則名稱


## 說明

人類可讀的規則。


## 分類

Validation

Calculation

Authorization

Workflow

Restriction

Integration


## 條件

這條規則在什麼情況下適用？


## 動作

會發生什麼？


## 證據

Source:

Class:

Method:

File:

SQL:

Configuration:


## 實作於

../../modules/transactions/[ClassName].md#method-[name]，步驟 N


## 原始碼

path/to/Class.java:120-128


## 信心度

High / Medium / Low

```

---

# 輸出規則

絕不寫：

「系統大概……」

「開發者的意圖是……」

「看起來……」

只有在有證據時，才使用：

「程式碼施行了……」


---

# 禁止事項

不要：

憑空造出業務意義

臆測領域術語

在沒有證據的情況下為實體改名

推測使用者需求

---

# 品質檢查清單

☐ 規則有 ID

☐ 規則有說明

☐ 規則有條件

☐ 規則有動作

☐ 規則有證據

☐ 規則連結到實作它的方法小節（Implemented At）

☐ 已指派信心度

☐ 沒有任何假設

☐ 沒有憑空造出的業務意義

☐ 來源可追溯

☐ docs/business-rules/transactions/ 底下每個交易類別一個檔案

☐ 檔案數量與 docs/enumeration/transaction-classes.txt 的行數相符

☐ 每一個 BR-ID 都能由 business-rule-index.md 解析

---

結束。
