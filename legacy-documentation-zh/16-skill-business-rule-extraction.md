---
name: business-rule-extraction

description: |
  萃取隱藏在舊有原始碼、資料庫邏輯、組態設定
  與整合定義中的業務規則。
  將技術實作轉換為人類可讀、且具可追溯證據的規則。

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
  - module-analysis
  - database-analysis
  - interface-analysis

outputs:
  - docs/business-rules/business-rule-index.md
  - docs/business-rules/
---

# 目標

探索系統內部所實作的業務規則。

將技術性條件轉換為可讀的規則。

每一條規則都必須可追溯回原始碼證據。

---

# 職責

本 Skill 應（SHALL）

- 辨識條件邏輯

- 辨識驗證規則

- 辨識計算規則

- 辨識狀態轉換規則

- 辨識授權規則

- 辨識以例外為基礎的規則

- 辨識由組態驅動的規則

- 辨識資料庫規則

- 辨識預存程序規則

- 辨識整合路由規則

- 辨識工作流程限制

本 Skill 不得（SHALL NOT）

- 修改原始碼

- 產生新的業務邏輯

- 假設業務意圖

- 虛構缺失的規則

- 建立功能規格

---

# 輸入

原始碼

模組分析

資料庫分析

介接分析

架構分析

組態檔案

SQL

預存程序

訊息定義

---

# 規則探索來源

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

狀態機（state machine）

## 資料庫邏輯

範例：

SQL CASE

CHECK 限制條件

觸發器（Trigger）

預存程序

函式（Function）

## 組態設定

範例：

Properties

YAML

XML

功能旗標（Feature Flags）

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

BR-001.md

BR-002.md

BR-003.md

---

# 證據規則

每一條業務規則都必須包含證據。

證據格式：

來源檔案

類別

方法

行號（若可取得）

SQL

組態鍵值

訊息定義

---

# 規則信心度

每條規則都必須標示信心度。

可用值：

高（High）

直接實作出來的規則。

中（Medium）

證據充分，但需要一定程度的詮釋。

低（Low）

可能的規則，但證據不完整。

---

# 完成條件

業務規則在以下項目都完成時才算完整：

- 所有驗證邏輯都已檢視

- 所有決策點都已檢視

- 所有狀態變更都已檢視

- 所有計算都已檢視

- 所有授權檢查都已檢視

- 證據都已記錄

---

# 被以下 Skill 依賴

sequence-discovery

specification-generation

gap-analysis

---

# 提示（Prompt）

# 業務規則萃取（Business Rule Extraction）

---

# 目標

從舊有實作中萃取業務規則。

每一筆業務規則條目，都以業務語言描述系統「強制執行了什麼」（WHAT）。

程式碼「如何」實作它（HOW），由 module-analysis 記錄在
docs/modules/transactions/[ClassName].md 中。不要在此重複那份敘述。

取而代之，每條規則都應連結到實作它的方法子章節：

`Implemented at: ../../modules/transactions/[ClassName].md#method-[name] (step N)`

這樣的分工是刻意的。

它不是任何一份文件可以寫得淺薄的理由。

---

# 關鍵：窮盡式萃取

套用 shared/enumeration-first.md。

套用 shared/iterative-depth.md。

1. 從模組分析取得完整的交易類別清單。

2. 針對「每一個」交易類別，分析「每一個」state method。

3. 萃取「所有」條件邏輯、驗證、計算、授權與狀態規則。

4. 「不要」在找到幾條規則後就停止。持續進行，直到每個交易類別都已被檢視。

5. 輸出時依交易類別將規則分組。

---

# 規則探索流程

## 步驟 1

分析條件邏輯

搜尋：

if

else

switch

case

三元運算子（ternary）

防衛子句（guard clause）

驗證方法

範例：

原始碼：

if(amount > 1000000)

requireApproval();

轉換為：

規則：

大額交易需要核准。

證據：

類別

方法

條件

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

僅限經理核准後。

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

利率

記錄：

輸入

公式

輸出

證據

---

# 步驟 5

分析授權規則

搜尋：

角色（Role）

權限（Permission）

授權層級（Authority）

使用者等級

存取控制

記錄：

參與者（Actor）

權限

條件

證據

---

# 步驟 6

分析資料庫規則

搜尋：

CHECK

觸發器（Trigger）

預存程序

函式

限制條件（Constraint）

記錄：

規則

物件

條件

證據

---

# 步驟 7

分析組態規則

搜尋：

門檻值（threshold）

上限（limit）

開關（switch）

功能旗標（feature flag）

properties

yaml

記錄：

組態設定

意義

用途

證據

---

# 步驟 8

分析例外規則

搜尋：

Exception

錯誤碼

錯誤訊息

Catch

轉換：

將技術性例外

轉換為

業務限制

但僅限證據足以支持時。

---

# 業務規則文件格式

每條規則都必須包含：

```

# BR-ID

BR-001


## 名稱

規則名稱


## 描述

人類可讀的規則。


## 分類

驗證（Validation）

計算（Calculation）

授權（Authorization）

流程（Workflow）

限制（Restriction）

整合（Integration）


## 條件

這條規則在什麼時候適用？


## 動作

會發生什麼事？


## 證據

來源：

類別：

方法：

檔案：

SQL：

組態設定：


## 實作位置（Implemented At）

../../modules/transactions/[ClassName].md#method-[name], step N


## 原始碼位置（Source）

path/to/Class.java:120-128


## 信心度

高／中／低

```

---

# 輸出規則

絕不寫：

「系統大概會……」

「開發者的用意是……」

「看起來像是……」

只有在證據存在時，才使用：

「程式碼強制執行……」

---

# 禁止事項

不要：

虛構業務意義

臆測領域術語

在沒有證據的情況下重新命名實體

推測使用者需求

---

# 品質檢查清單

☐ 規則有編號

☐ 規則有描述

☐ 規則有條件

☐ 規則有動作

☐ 規則有證據

☐ 規則連結到實作它的方法子章節（Implemented At）

☐ 已指定信心度

☐ 無任何假設

☐ 無虛構的業務意義

☐ 來源可追溯

---

結束。
