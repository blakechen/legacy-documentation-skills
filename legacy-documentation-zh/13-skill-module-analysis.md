---
name: module-analysis

description: |
  分析程式碼庫中的每一個邏輯模組，並產生模組層級文件，
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

outputs:
  - docs/modules/
  - docs/modules/module-index.md
  - docs/modules/transactions/
---

# 目標

獨立分析每一個邏輯模組。

目標是描述每個模組包含什麼、
它如何被組織、
以及它如何與其他模組互動。

業務意義（某條規則「為什麼」存在）不在本 Skill 範圍內。

程式邏輯（每個方法「如何」處理一筆請求）「在」本 Skill 範圍內，
並且由本 Skill 擁有。

---

# 職責

本 Skill 應（SHALL）

- 辨識邏輯模組

- 辨識模組邊界

- 辨識模組職責

- 辨識進入點

- 辨識對外匯出的介面

- 辨識內部元件

- 辨識重要類別

- 辨識套件層級結構

- 辨識相依關係

- 辨識共用元件

- 辨識與該模組相關的組態設定

- 為每一個主要單元，記錄其每一個方法的逐步處理邏輯

- 引用原始碼片段，佐證每一項關鍵判斷、計算與 SQL 敘述

- 將輸入欄位經由中間變數對應到資料庫欄位與電文欄位

- 以語言中立的虛擬碼重述每個方法的邏輯

本 Skill 不得（SHALL NOT）

- 為邏輯賦予業務意義或業務理由（見 business-rule-extraction）

- 配發 BR-ID

- 設計或正規化資料模型（見 database-analysis）

- 產生規格（見 specification-generation）

---

# 輸入

程式碼庫清冊

技術探索

架構探索

原始碼

組態檔案

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

每一項陳述都必須引用可觀察到的證據。

證據可包含

目錄

套件

命名空間

組態設定

註解（Annotation）

類別

介面

相依關係

寫「Unknown（未知）」是可以接受的。

絕不在可得證據之外推測模組職責。

---

# 完成條件

每一個邏輯模組都已

- 被辨識

- 被記錄

- 列出進入點

- 列出相依關係

- 列出公開介面

---

# 被以下 Skill 依賴

database-analysis

interface-analysis

business-rule-extraction

sequence-discovery

specification-generation

---

# 提示（Prompt）

# 模組分析（Module Analysis）

---

## 目標

分析程式碼庫中的每一個邏輯模組。

每個模組產生一份文件。

此外，若系統採用 dispatcher 模式，則每個交易／動作類別也各產生一份文件。

描述模組結構「以及」交易類別行為。

---

## 關鍵：交易類別列舉

套用 shared/enumeration-first.md。

若架構探索辨識出 dispatcher 模式：

1. 找出「每一個」繼承交易基底類別的類別。

2. 找出「每一個」被 dispatcher 或其 factory／registry 引用的類別。

3. 建立一份包含「所有」交易類別及其檔案路徑的主清單。

4. 每個交易類別產生一份文件。

套用 shared/logic-depth.md。

每份交易類別文件都要以 skills/templates/transaction.md 作為「必要」結構。
不得省略任何章節。

每份交易類別文件都應包含：

- 類別名稱、檔案路徑與行號範圍

- 一份列出「每一個」public method 的 State Method 索引

- 索引中每個方法各一個 `### Method:` 子章節，各自包含
  處理流程、虛擬碼、關鍵原始碼引用、欄位對應、
  分支與條件、資料庫存取、外部呼叫、錯誤路徑

- 一段跨越各 state method 的端到端處理流程敘述

- 相關的 JSP 頁面

- 相關的資料庫物件

- 相關的 properties／組態設定

本 Skill「擁有」整條管線中方法層級的邏輯敘述。

下游 Skill 引用這些文件，不再自行推導。

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

擁有的功能

主要套件

組態檔案

避免假設。

只描述可觀察到的職責。

---

## 步驟 3

辨識進入點

範例

REST Controller

SOAP 端點

訊息監聽器（Message Listener）

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

MQ 監聽器

發布的事件

公開服務

對外匯出的套件

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

組態設定

資源

工具類別

Factory

Builder

Adapter

---

## 步驟 6

辨識相依關係

記錄

內部相依關係

外部相依關係

共用模組

基礎設施相依關係

只記錄可觀察到的關聯。

---

## 步驟 7

辨識組態設定

找出

application.yml

properties

XML

註解（Annotation）

環境變數

模組專屬設定

記錄

用途

證據

---

## 步驟 8

產生模組摘要

包含

目的

職責

進入點

介面

相依關係

重要類別

組態設定

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

每份模組文件都應包含

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

依 shared/logic-depth.md 所定義的深度，記錄每一個方法可觀察到的處理邏輯。

每一個分支、計算與 SQL 敘述都要引用原始碼。
絕不在程式碼區塊內改寫。

絕不推測未記錄的行為。

絕不虛構不存在的方法、類別、資料表或欄位。

絕不為了省空間而縮短文件。深度就是交付物。

---

## 品質檢查清單

☐ 每個模組都已記錄

☐ 已辨識各項職責

☐ 已辨識進入點

☐ 已辨識公開介面

☐ 已記錄套件結構

☐ 已記錄相依關係

☐ 已記錄組態設定

☐ 已納入證據

☐ 無幻覺內容

☐ 逐交易文件數量與列舉數量相符

☐ 每份交易文件都符合 skills/templates/transaction.md

☐ 每個 public method 都有 `### Method:` 子章節

☐ 每個方法子章節都有處理流程、虛擬碼、至少一段附 file:line 的原始碼引用，以及欄位對應

☐ 未賦予業務意義（只引用 BR-ID，絕不自創）

---

## 經驗教訓

### 問題：產出模組索引，而非逐交易文件

AI 只產出了 `docs/modules/module-index.md`（1 個檔案），
而不是每個交易類別一個檔案（預期 458 個）。
這會導致所有下游 Skill（業務規則、循序圖、規格）都無法正確執行。

**修正**：本 Skill 的主要交付物「不是」單一索引檔。而是：
- `docs/modules/module-index.md`（摘要）
- 「加上」`docs/enumeration/transaction-classes.txt` 中「每一個」類別各自的
  `docs/modules/transactions/[ClassName].md`

完成條件：`ls docs/modules/transactions/*.md | wc -l` 必須等於
`docs/enumeration/transaction-classes.txt` 的行數。

### 問題：面對規模時選擇跳過而非分批

面對 458 個類別時，正確的做法是分批處理（例如依套件），
「而不是」產出一份摘要就宣告完成。

**修正**：若需要分批處理，就把進度記錄在 `docs/gap-analysis/progress.md`，
並在後續回合持續進行，直到所有類別都被涵蓋。

---

結束。
