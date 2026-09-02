---
name: interface-analysis

description: |
  分析所有對外與對內的系統整合介接。
  探索通訊協定、訊息格式、API 端點、
  訊息傳遞系統與整合邊界。

version: 1.0.0

category: integration

author: Legacy Documentation Skills

tags:
  - integration
  - api
  - rest
  - soap
  - mq
  - jms
  - kafka
  - grpc

dependencies:
  - inventory
  - technology-discovery
  - architecture-discovery
  - artifact-enumeration
  - module-analysis
  - database-analysis

shared:
  - evidence-rules
  - confidence-scoring
  - documentation-style
  - markdown-style
  - naming-conventions
  - output-schema
  - quality-checklist
  - mermaid-guidelines

templates:
  - api

outputs:
  - docs/integration/interface-overview.md
  - docs/integration/rest-api.md
  - docs/integration/soap-services.md
  - docs/integration/message-queue.md
  - docs/integration/file-transfer.md
  - docs/integration/external-systems.md
---

# 目標

記錄每一個整合介接。

只聚焦於系統之間的通訊。

業務處理不在範圍內。

---

# 職責

本 Skill 應（SHALL）

- 辨識 REST 端點

- 辨識 SOAP 服務

- 辨識 MQ 消費者

- 辨識 MQ 生產者

- 辨識 JMS 監聽器

- 辨識 Kafka 生產者

- 辨識 Kafka 消費者

- 辨識 FTP 整合

- 辨識 SFTP 整合

- 辨識檔案交換

- 辨識 gRPC 服務

- 辨識 GraphQL 端點

- 辨識排程式整合工作

- 辨識外部系統

- 辨識請求訊息

- 辨識回應訊息

- 辨識訊息格式

- 辨識身分驗證方式

本 Skill 不得（SHALL NOT）

- 分析業務規則

- 解釋業務意義

- 分析 SQL 邏輯

- 產生規格

- 推測訊息語意

---

# 輸入

程式碼庫清冊

技術探索

架構探索

模組分析

資料庫分析

原始碼

組態檔案

整合定義

---

# 交付物

docs/integration/

interface-overview.md

rest-api.md

soap-services.md

message-queue.md

file-transfer.md

external-systems.md

---

# 證據規則

每個介接都必須引用可觀察到的證據。

證據可包含

Controller

註解（Annotation）

WSDL

OpenAPI

Swagger

MQ 組態

Listener

Producer

Scheduler

XML

Properties

YAML

寫「Unknown（未知）」是可以接受的。

絕不虛構介接。

---

# 完成條件

每項整合技術都已記錄。

每個外部系統都已辨識。

每個端點都已記錄。

每個訊息傳遞介接都已記錄。

每個檔案整合都已記錄。

---

# 被以下 Skill 依賴

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
- shared/mermaid-guidelines.md

文件結構應（SHALL）依循：

- skills/templates/api.md

違反任一共用規則的文件即為「未完成」，
無論其內容多寡。

---

# 提示（Prompt）

# 介接分析（Interface Analysis）

---

## 目標

分析每一個整合介接。

只聚焦於技術面的通訊。

不要解釋業務行為。

---

## 步驟 1

辨識 REST API

找出

@RestController

@RequestMapping

@GetMapping

@PostMapping

@PutMapping

@DeleteMapping

@Path

OpenAPI

Swagger

以 Servlet 為基礎的 URL 樣式（例如 /servlet/ClassName?param=value）

記錄

端點

方法

路徑

Consumes

Produces

身分驗證

證據

---

## 步驟 2

辨識 SOAP 服務

找出

@WebService

@WebMethod

WSDL

JAX-WS

CXF

Axis

記錄

服務

操作

端點

證據

---

## 步驟 3

辨識訊息佇列

找出

IBM MQ

JMS

ActiveMQ

RabbitMQ

Kafka

Azure Service Bus

AWS SQS

記錄

佇列（Queue）

主題（Topic）

生產者

消費者

監聽器

組態設定

證據

---

## 步驟 4

辨識檔案傳輸

找出

FTP

SFTP

檔案輪詢（File Polling）

目錄監看（Directory Watch）

共用資料夾

批次匯入

批次匯出

記錄

方向

檔案樣式

位置

證據

---

## 步驟 5

辨識外部系統

找出

REST 用戶端

SOAP 用戶端

MQ 連線

資料庫連結（Database Link）

LDAP

SMTP

支付閘道

身分提供者（Identity Provider）

雲端服務

記錄

系統

通訊協定

證據

---

## 步驟 6

辨識身分驗證

範例

Basic Auth

OAuth2

JWT

雙向 TLS（Mutual TLS）

API Key

LDAP

Kerberos

SAML

記錄

驗證類型

證據

---

## 步驟 7

辨識訊息格式

找出

JSON

XML

CSV

固定長度（Fixed Length）

EDI

Protocol Buffers

Avro

記錄

格式

生產者

消費者

證據

---

## 步驟 8

辨識重試策略

找出

Retry

死信佇列（Dead Letter Queue）

重新遞送（Redelivery）

退避（Backoff）

斷路器（Circuit Breaker）

備援（Fallback）

記錄

機制

證據

---

## 步驟 9

產生整合摘要

包含

REST

SOAP

MQ

Kafka

JMS

FTP

SFTP

gRPC

GraphQL

外部系統

身分驗證

訊息格式

證據

---

## 輸出規則

絕不解釋業務規則。

絕不推測訊息的意義。

絕不描述交易流程。

絕不產生循序圖。

絕不推測未記載的通訊協定。

---

## 必要輸出

產生

docs/integration/interface-overview.md

docs/integration/rest-api.md

docs/integration/soap-services.md

docs/integration/message-queue.md

docs/integration/file-transfer.md

docs/integration/external-systems.md

---

## 品質檢查清單

☐ 已記錄 REST

☐ 已記錄 SOAP

☐ 已記錄 MQ

☐ 已記錄 Kafka

☐ 已記錄 JMS

☐ 已記錄檔案傳輸

☐ 已記錄外部系統

☐ 已記錄身分驗證

☐ 已記錄訊息格式

☐ 已記錄重試策略

☐ 已納入證據

☐ 無幻覺內容

---

結束。
