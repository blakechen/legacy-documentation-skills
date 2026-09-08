---
name: sequence-discovery

description: |
  運用先前各文件產生 Skill 的輸出，產生元件之間的互動循序。
  產出具決定性的 Mermaid 循序圖，
  描述已驗證的執行期互動。

version: 1.0.0

category: interaction

author: Legacy Documentation Skills

tags:
  - sequence
  - interaction
  - workflow
  - mermaid
  - reverse-engineering

dependencies:
  - inventory
  - architecture-discovery
  - artifact-enumeration
  - module-analysis
  - database-analysis
  - interface-analysis
  - business-rule-extraction

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
  - sequence

outputs:
  - docs/sequence/sequence-index.md
  - docs/sequence/transactions/
---

# 目標

產生互動循序。

描述各元件如何通訊。

循序圖必須立基於已驗證的證據。

---

# 職責

本 Skill「應當」

- 辨識請求流程

- 辨識回應流程

- 辨識元件互動

- 辨識資料庫互動

- 辨識外部系統互動

- 辨識 MQ 互動

- 辨識排程流程

- 辨識批次執行流程

- 辨識例外流程

- 產生 Mermaid 循序圖

本 Skill「不得」

- 憑空造出執行路徑

- 推測業務意圖

- 產生功能規格

- 修改業務規則

- 創造新的架構

---

# 輸入

架構探索

模組分析

資料庫分析

介面分析

業務規則抽取

既有原始碼（僅供驗證用）

---

# 交付物

docs/sequence/

sequence-index.md

api-sequences.md

mq-sequences.md

batch-sequences.md

exception-sequences.md

---

# 證據規則

每一項互動都必須參照證據。

證據包括

方法呼叫

REST 對應

MQ Listener

SQL 呼叫

Repository 呼叫

組態

排程定義

訊息生產端

Unknown 是可以接受的。

絕不憑空造出缺少的互動。

---

# 完成判準

每一項主要互動都已記錄。

每一個循序都已驗證。

已產生 Mermaid 圖表。

已記錄證據。

---

# 被下列 Skill 依賴

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
- shared/mermaid-guidelines.md
- shared/logic-depth.md

文件結構「應當」遵循：

- skills/templates/sequence.md

違反任一共用規則的文件即為「不完整」，
無論其內容如何。

---

# Prompt

# 循序探索

---

# 目標

產生描述執行期互動的循序圖。

以先前各 Skill 的輸出為主要來源。

需要驗證時再查閱原始碼。

---

# 關鍵：逐交易的循序圖

套用 shared/enumeration-first.md。

1. 從模組分析取得完整的交易類別清單。

2. 為「每一個」主要交易類別產生至少一張循序圖。

3. 每張圖都應顯示完整流程：
   使用者 → JSP → Dispatcher → 交易類別 → DB／外部系統 → 回應。

4. 納入該交易內部的所有狀態轉換
   （例如 prompt → checkuser → confirm → result）。

5. 在 docs/sequence/transactions/ 底下，每個交易類別輸出一個循序檔。

---

# 循序探索流程

## 步驟 1

辨識互動進入點

可能來源

REST Endpoint

SOAP Endpoint

MQ Listener

批次工作

排程器

CLI

Servlet

記錄

進入點

證據

---

## 步驟 2

辨識參與者

可能的參與者

使用者

瀏覽器

外部系統

API Gateway

Controller

Service

Domain

Repository

DAO

資料庫

MQ

批次

排程器

通知

第三方服務

---

## 步驟 3

辨識呼叫鏈

只追蹤已驗證的呼叫。

範例

Controller

→
Service

→
Repository

→
資料庫

或

REST

→
Controller

→
MQ

→
外部系統

絕不推測缺少的呼叫。

---

## 步驟 4

辨識資料庫互動

記錄

讀取

新增

更新

刪除

Stored Procedure

交易邊界（若可明確辨識）

---

## 步驟 5

辨識外部互動

記錄

REST Client

SOAP Client

MQ Producer

MQ Consumer

FTP

SFTP

Kafka

LDAP

SMTP

記錄

協定

方向

證據

---

## 步驟 6

辨識例外流程

找出

try

catch

throws

錯誤對應

fallback

retry

dead letter queue

記錄

觸發條件

處理者

結果

證據

---

## 步驟 7

產生 Mermaid 循序圖

使用

sequenceDiagram

包含

Actor

Participant

Activation

請求

回應

資料庫

外部系統

訊息

只納入已驗證的互動。

---

## 步驟 8

產生循序摘要

每個循序都應包含

概觀

觸發條件

參與者

前置條件

互動步驟

資料庫存取

外部呼叫

例外

證據

---

# 輸出結構

產生

docs/sequence/

sequence-index.md

api-sequences.md

mq-sequences.md

batch-sequences.md

exception-sequences.md

---

# Mermaid 規則

每個循序都應

以一個 actor 開始

以一個回應或完成結束

在適當之處顯示 activation

避免推測出來的訊息

在有證據時，不要省略參與者

---

# 輸出規則

絕不推測隱藏的執行路徑。

絕不憑空造出業務工作流程。

絕不假設非同步行為。

絕不把不相關的循序合併。

只記錄有證據支撐的互動。

---

# 品質檢查清單

☐ 已辨識進入點

☐ 已辨識參與者

☐ 已記錄呼叫鏈

☐ 已記錄資料庫互動

☐ 已記錄外部互動

☐ 已記錄例外流程

☐ Mermaid 語法正確

☐ 已附上證據

☐ 沒有任何幻覺內容

☐ 沒有推測出來的工作流程

---

結束。
