---
name: interface-analysis

description: |
  分析所有對外與對內的系統整合介面。
  發掘通訊協定、訊息格式、API 端點、
  訊息系統與整合邊界。

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

記錄每一個整合介面。

只聚焦於系統之間的通訊。

業務處理不在範圍內。

---

# 職責

本 Skill「應當」

- 辨識 REST 端點

- 辨識 SOAP 服務

- 辨識 MQ 消費端

- 辨識 MQ 生產端

- 辨識 JMS listener

- 辨識 Kafka 生產端

- 辨識 Kafka 消費端

- 辨識 FTP 整合

- 辨識 SFTP 整合

- 辨識檔案交換

- 辨識 gRPC 服務

- 辨識 GraphQL 端點

- 辨識排程整合工作

- 辨識外部系統

- 辨識請求訊息

- 辨識回應訊息

- 辨識訊息格式

- 辨識認證方式

本 Skill「不得」

- 分析業務規則

- 解釋業務意義

- 分析 SQL 邏輯

- 產生規格

- 推測訊息語意

---

# 輸入

儲存庫清冊

技術探索

架構探索

模組分析

資料庫分析

原始碼

組態檔

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

每一個介面都必須參照可觀察的證據。

證據可包括

Controller

Annotation

WSDL

OpenAPI

Swagger

MQ 組態

Listener

Producer

排程器

XML

Properties

YAML

Unknown 是可以接受的。

絕不憑空造出介面。

---

# 完成判準

每一項整合技術都已記錄。

每一個外部系統都已辨識。

每一個端點都已記錄。

每一個訊息介面都已記錄。

每一項檔案整合都已記錄。

---

# 被下列 Skill 依賴

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
- shared/mermaid-guidelines.md

文件結構「應當」遵循：

- skills/templates/api.md

違反任一共用規則的文件即為「不完整」，
無論其內容如何。

---

# Prompt

# 介面分析

---

## 目標

分析每一個整合介面。

只聚焦於技術層面的通訊。

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

認證

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

Queue

Topic

生產端

消費端

Listener

組態

證據

---

## 步驟 4

辨識檔案傳輸

找出

FTP

SFTP

檔案輪詢

目錄監看

共享資料夾

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

REST Client

SOAP Client

MQ 連線

Database Link

LDAP

SMTP

金流閘道

身分提供者

雲端服務

記錄

系統

協定

證據

---

## 步驟 6

辨識認證

範例

Basic Auth

OAuth2

JWT

Mutual TLS

API Key

LDAP

Kerberos

SAML

記錄

認證類型

證據

---

## 步驟 7

辨識訊息格式

找出

JSON

XML

CSV

固定長度

EDI

Protocol Buffers

Avro

記錄

格式

生產端

消費端

證據

---

## 步驟 8

辨識重試策略

找出

Retry

Dead Letter Queue

Redelivery

Backoff

Circuit Breaker

Fallback

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

認證

訊息格式

證據

---

## 輸出規則

絕不解釋業務規則。

絕不推測訊息含義。

絕不描述交易流程。

絕不產生循序圖。

絕不推測未記錄的協定。

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

☐ 已記錄認證

☐ 已記錄訊息格式

☐ 已記錄重試策略

☐ 已附上證據

☐ 沒有任何幻覺內容

---

結束。
