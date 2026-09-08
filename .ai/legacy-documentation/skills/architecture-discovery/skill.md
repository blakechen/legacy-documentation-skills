---
name: architecture-discovery

description: |
  透過分析儲存庫的結構組織來發掘軟體架構。
  本 Skill 辨識架構分層、元件、相依關係與系統邊界，
  但不詮釋業務邏輯。

version: 1.0.0

category: architecture

author: Legacy Documentation Skills

tags:
  - architecture
  - component
  - dependency
  - layer
  - reverse-engineering

dependencies:
  - inventory
  - technology-discovery

shared:
  - evidence-rules
  - confidence-scoring
  - documentation-style
  - markdown-style
  - naming-conventions
  - output-schema
  - quality-checklist
  - custom-framework-recognition
  - mermaid-guidelines
  - logic-depth

templates:
  - architecture

outputs:
  - docs/architecture/architecture.md
  - docs/architecture/component-diagram.md
  - docs/architecture/context-diagram.md
  - docs/architecture/dependency-graph.md
  - docs/architecture/layer-analysis.md
---

# 目標

辨識軟體的結構架構。

目標是描述這套軟體是如何組織的。

本 Skill 不分析業務行為。

---

# 職責

本 Skill「應當」

- 辨識架構分層

- 辨識應用邊界

- 辨識模組

- 辨識元件

- 辨識套件

- 辨識命名空間

- 辨識相依關係

- 辨識共用函式庫

- 辨識可重用元件

- 辨識外部系統

- 辨識部署邊界

- 辨識架構模式

本 Skill「不得」

- 分析業務規則

- 分析交易流程

- 分析 SQL 邏輯

- 產生規格

- 推測使用者工作流程

- 評價實作品質

---

# 輸入

儲存庫清冊

技術堆疊

原始碼

組態檔

建置定義

---

# 交付物

docs/architecture/

architecture.md

component-diagram.md

context-diagram.md

dependency-graph.md

layer-analysis.md

---

# 證據規則

每個元件都應參照證據。

範例

套件

命名空間

目錄

組態

Annotation

相依關係

Import

建置檔

Unknown 是可以接受的。

絕不推測缺少的架構。

---

# 完成判準

當下列條件成立時，架構即為完成

所有分層皆已辨識

主要元件皆已記錄

外部系統皆已列出

已產生相依圖

已產生架構圖

---

# 被下列 Skill 依賴

artifact-enumeration

module-analysis

database-analysis

interface-analysis

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
- shared/custom-framework-recognition.md
- shared/mermaid-guidelines.md
- shared/logic-depth.md

文件結構「應當」遵循：

- skills/templates/architecture.md

違反任一共用規則的文件即為「不完整」，
無論其內容如何。

---

# Prompt

# 架構探索

---

## 目標

發掘儲存庫的結構架構。

聚焦於軟體的組織方式。

不要分析業務行為。

---

## 步驟 1

辨識架構模式

範例

分層架構

Hexagonal

Clean Architecture

Onion

MVC

微服務

模組化單體

SOA

事件驅動

主從式

自製 Dispatcher（帶交易路由的 Front Controller）

自製框架（專有基底類別與慣例）

記錄

模式

證據

信心度

---

## 步驟 1.1

辨識自製框架（關鍵）

套用 shared/custom-framework-recognition.md。

搜尋：

- 依請求參數把工作分派給交易類別的中央 Servlet。

- 所有業務邏輯都繼承的交易基底類別。

- 所有資料存取都繼承的 DB 物件基底類別。

- 自製的組態載入器。

若找到，記錄：

- Dispatcher 類別與路由參數

- 交易基底類別名稱

- DB 物件基底類別名稱

- 組態載入器與路徑

- Factory／registry 類別（例如 TrxFactory）

本步驟是「關鍵」。一旦偵測到自製框架，
「所有」下游 Skill 都必須用這項資訊來列舉產出物。

---

## 步驟 2

辨識分層

範例

Presentation

Controller

API

Application

Service

Domain

Repository

DAO

Persistence

Infrastructure

Integration

Batch

Scheduler

Security

Shared

每一層記錄

用途

位置

證據

---

## 步驟 3

辨識元件

範例

Loan Service

Customer Service

Authentication

Notification

Payment

Reporting

Scheduler

Batch Processor

記錄

元件名稱

職責

位置

證據

---

## 步驟 4

辨識套件結構

記錄

頂層套件

命名空間

模組歸屬

共用套件

工具套件

記錄

階層

用途

證據

---

## 步驟 5

辨識相依關係

記錄

模組相依

函式庫相依

共用元件

基礎設施相依

避免對循環相依做出假設。

只回報可觀察到的關聯。

---

## 步驟 6

辨識外部系統

範例

資料庫

REST 服務

SOAP 服務

IBM MQ

Kafka

LDAP

SMTP

FTP

SFTP

主機（Mainframe）

雲端服務

記錄

系統

連線型態

證據

---

## 步驟 7

產生分層分析

描述

職責

相依方向

分層隔離

潛在違規

證據

---

## 步驟 8

產生 Context Diagram

使用 Mermaid。

包含

系統

使用者

外部系統

資料庫

訊息系統

只納入已驗證的關聯。

---

## 步驟 9

產生 Component Diagram

使用 Mermaid。

包含

元件

相依關係

介面

外部系統

不要憑空造出缺少的元件。

---

## 步驟 10

產生相依圖

記錄

模組相依

套件相依

共用函式庫

外部相依

只納入已驗證的參照。

---

## 輸出規則

絕不描述業務規則。

絕不描述使用者工作流程。

絕不在此解釋交易流程。逐方法的處理流程由
module-analysis 負責（見 shared/logic-depth.md）。

絕不推測缺少的元件。

絕不憑空造出架構決策。

---

## 必要輸出

產生

docs/architecture/architecture.md

docs/architecture/component-diagram.md

docs/architecture/context-diagram.md

docs/architecture/dependency-graph.md

docs/architecture/layer-analysis.md

---

## Mermaid 規則

Component Diagram

- 只有元件

- 相依箭頭

Context Diagram

- 系統

- 外部系統

- 資料庫

- 訊息傳遞

不要循序圖。

不要 ER 圖。

---

## 品質檢查清單

☐ 已辨識架構模式

☐ 已記錄分層

☐ 已記錄元件

☐ 已記錄套件結構

☐ 已記錄外部系統

☐ 已完成相依圖

☐ Mermaid 圖表語法正確

☐ 已附上證據

☐ 沒有任何幻覺內容

☐ 沒有業務規則

---

結束。
