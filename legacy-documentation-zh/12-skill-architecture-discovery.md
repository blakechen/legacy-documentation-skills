---
name: architecture-discovery

description: |
  透過分析程式碼庫的結構組織來探索軟體架構。
  本 Skill 辨識架構層次、元件、相依關係與系統邊界，
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

辨識軟體的結構性架構。

目標是描述軟體「如何被組織」。

本 Skill 不分析業務行為。

---

# 職責

本 Skill 應（SHALL）

- 辨識架構層次

- 辨識應用程式邊界

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

本 Skill 不得（SHALL NOT）

- 分析業務規則

- 分析交易流程

- 分析 SQL 邏輯

- 產生規格

- 推測使用者工作流程

- 評價實作品質

---

# 輸入

程式碼庫清冊

技術堆疊

原始碼

組態檔案

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

每個元件都應引用證據。

範例

套件（Package）

命名空間（Namespace）

目錄

組態設定

註解（Annotation）

相依關係

Import

建置檔

寫「Unknown（未知）」是可以接受的。

絕不推測缺失的架構。

---

# 完成條件

架構在以下條件都滿足時才算完成

所有層次都已辨識

主要元件都已記錄

外部系統都已列出

相依關係圖已產生

架構圖已產生

---

# 被以下 Skill 依賴

module-analysis

database-analysis

interface-analysis

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
- shared/custom-framework-recognition.md
- shared/mermaid-guidelines.md
- shared/logic-depth.md

文件結構應（SHALL）依循：

- skills/templates/architecture.md

違反任一共用規則的文件即為「未完成」，
無論其內容多寡。

---

# 提示（Prompt）

# 架構探索（Architecture Discovery）

---

## 目標

探索程式碼庫的結構性架構。

聚焦於軟體的組織方式。

不要分析業務行為。

---

## 步驟 1

辨識架構模式

範例

分層架構（Layered Architecture）

六角形架構（Hexagonal）

Clean Architecture

洋蔥式架構（Onion）

MVC

微服務（Microservice）

模組化單體（Modular Monolith）

SOA

事件驅動（Event Driven）

主從式（Client Server）

自訂 Dispatcher（具交易路由的 Front Controller）

自訂框架（專有基底類別與慣例）

記錄

模式

證據

信心度

---

## 步驟 1.1

辨識自訂框架（關鍵）

套用 shared/custom-framework-recognition.md。

搜尋：

- 一個依請求參數把工作分派給交易類別的中央 Servlet。

- 一個所有業務邏輯都繼承的交易基底類別。

- 一個所有資料存取都繼承的資料庫物件基底類別。

- 一個自訂的組態載入器。

若找到，記錄：

- Dispatcher 類別與路由參數

- 交易基底類別名稱

- 資料庫物件基底類別名稱

- 組態載入器與其路徑

- Factory／registry 類別（例如 TrxFactory）

本步驟屬「關鍵」。
一旦偵測到自訂框架，「所有」下游 Skill 都必須使用這項資訊來列舉產出物。

---

## 步驟 2

辨識層次

範例

展現層（Presentation）

Controller

API

應用層（Application）

服務層（Service）

領域層（Domain）

Repository

DAO

持久層（Persistence）

基礎設施（Infrastructure）

整合（Integration）

批次（Batch）

排程（Scheduler）

安全（Security）

共用（Shared）

每個層次都要記錄

用途

位置

證據

---

## 步驟 3

辨識元件

範例

貸款服務

客戶服務

身分驗證

通知

支付

報表

排程器

批次處理器

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

層級結構

用途

證據

---

## 步驟 5

辨識相依關係

記錄

模組相依關係

函式庫相依關係

共用元件

基礎設施相依關係

避免對循環相依做假設。

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

大型主機（Mainframe）

雲端服務

記錄

系統

連線類型

證據

---

## 步驟 7

產生層次分析

描述

職責

相依方向

層次隔離

潛在違規

證據

---

## 步驟 8

產生情境圖（Context Diagram）

使用 Mermaid。

納入

系統

使用者

外部系統

資料庫

訊息傳遞系統

只納入已驗證的關聯。

---

## 步驟 9

產生元件圖（Component Diagram）

使用 Mermaid。

納入

元件

相依關係

介面

外部系統

不要虛構不存在的元件。

---

## 步驟 10

產生相依關係圖

記錄

模組相依關係

套件相依關係

共用函式庫

外部相依關係

只納入已驗證的引用。

---

## 輸出規則

絕不描述業務規則。

絕不描述使用者工作流程。

絕不在此解釋交易流程。逐方法的處理流程由 module-analysis 負責
（見 shared/logic-depth.md）。

絕不推測缺失的元件。

絕不虛構架構決策。

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

元件圖

- 只放元件

- 相依關係箭頭

情境圖

- 系統

- 外部系統

- 資料庫

- 訊息傳遞

不放循序圖。

不放 ER 圖。

---

## 品質檢查清單

☐ 已辨識架構模式

☐ 已記錄各層次

☐ 已記錄各元件

☐ 已記錄套件結構

☐ 已記錄外部系統

☐ 相依關係圖已完成

☐ Mermaid 圖語法正確

☐ 已納入證據

☐ 無幻覺內容

☐ 未涉及業務規則

---

結束。
