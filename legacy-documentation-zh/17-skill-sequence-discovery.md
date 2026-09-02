---
name: sequence-discovery

description: |
  運用先前各文件 Skill 的輸出，產生元件之間的互動循序。
  產出具決定性的 Mermaid 循序圖，描述已驗證的執行期互動。

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
  - module-analysis
  - database-analysis
  - interface-analysis
  - business-rule-extraction

outputs:
  - docs/sequence/sequence-index.md
  - docs/sequence/
---

# 目標

產生互動循序。

描述元件之間如何通訊。

循序圖必須以已驗證的證據為基礎。

---

# 職責

本 Skill 應（SHALL）

- 辨識請求流程

- 辨識回應流程

- 辨識元件互動

- 辨識資料庫互動

- 辨識外部系統互動

- 辨識 MQ 互動

- 辨識排程器流程

- 辨識批次執行流程

- 辨識例外流程

- 產生 Mermaid 循序圖

本 Skill 不得（SHALL NOT）

- 虛構執行路徑

- 推測業務意圖

- 產生功能規格

- 修改業務規則

- 建立新的架構

---

# 輸入

架構探索

模組分析

資料庫分析

介接分析

業務規則萃取

既有原始碼（僅用於驗證）

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

每一項互動都必須引用證據。

證據包含

方法呼叫

REST 對應（Mapping）

MQ 監聽器

SQL 呼叫

Repository 呼叫

組態設定

排程定義

訊息生產者

寫「Unknown（未知）」是可以接受的。

絕不虛構缺失的互動。

---

# 完成條件

每一項主要互動都已記錄。

每一份循序圖都已驗證。

Mermaid 圖已產生。

證據已記錄。

---

# 被以下 Skill 依賴

specification-generation

gap-analysis

---

# 提示（Prompt）

# 循序探索（Sequence Discovery）

---

# 目標

產生描述執行期互動的循序圖。

以先前 Skill 的輸出作為主要來源。

需要驗證時才查閱原始碼。

---

# 關鍵：逐交易循序圖

套用 shared/enumeration-first.md。

1. 從模組分析取得完整的交易類別清單。

2. 針對「每一個」主要交易類別，至少產生一份循序圖。

3. 每份圖都應呈現完整流程：
   使用者 → JSP → Dispatcher → 交易類別 → 資料庫／外部系統 → 回應。

4. 納入該交易內部的所有狀態轉換
   （例如 prompt → checkuser → confirm → result）。

5. 在 docs/sequence/transactions/ 底下，每個交易類別輸出一個循序圖檔案。

---

# 循序探索流程

## 步驟 1

辨識互動進入點

可能的來源

REST 端點

SOAP 端點

MQ 監聽器

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

絕不推測缺失的呼叫。

---

## 步驟 4

辨識資料庫互動

記錄

讀取

新增

更新

刪除

預存程序

交易邊界（若可明確辨識）

---

## 步驟 5

辨識外部互動

記錄

REST 用戶端

SOAP 用戶端

MQ 生產者

MQ 消費者

FTP

SFTP

Kafka

LDAP

SMTP

記錄

通訊協定

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

備援（fallback）

重試

死信佇列

記錄

觸發原因

處理者

結果

證據

---

## 步驟 7

產生 Mermaid 循序圖

使用

sequenceDiagram

納入

參與者（Actor）

Participant

啟用區間（Activation）

請求

回應

資料庫

外部系統

訊息

只納入已驗證的互動。

---

## 步驟 8

產生循序摘要

每份循序圖都應包含

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

每份循序圖都應

以一個參與者（actor）開始

以回應或完成結束

在適當處顯示啟用區間

避免推測出來的訊息

在證據存在時，不得省略參與者

---

# 輸出規則

絕不推測隱藏的執行路徑。

絕不虛構業務工作流程。

絕不假設非同步行為。

絕不把不相關的循序合併在一起。

只記錄以證據為基礎的互動。

---

# 品質檢查清單

☐ 已辨識進入點

☐ 已辨識參與者

☐ 已記錄呼叫鏈

☐ 已記錄資料庫互動

☐ 已記錄外部互動

☐ 已記錄例外流程

☐ Mermaid 語法正確

☐ 已納入證據

☐ 無幻覺內容

☐ 無推測出來的工作流程

---

結束。
