---
name: technology-discovery

description: |
  發掘儲存庫所使用的技術、框架、執行環境、
  函式庫與基礎設施元件。

version: 1.0.0

category: discovery

author: Legacy Documentation Skills

tags:
  - technology
  - framework
  - runtime
  - discovery

supported-languages:
  - Java
  - Kotlin
  - Scala
  - COBOL
  - C#
  - VB.NET
  - Node.js
  - JavaScript
  - TypeScript
  - Python
  - Go
  - PHP

dependencies:
  - inventory

shared:
  - evidence-rules
  - confidence-scoring
  - documentation-style
  - markdown-style
  - naming-conventions
  - output-schema
  - quality-checklist
  - logic-depth

outputs:
  - docs/overview/technology-stack.md
  - docs/overview/frameworks.md
  - docs/overview/runtime-environment.md
  - docs/overview/dependency-summary.md
---

# 目標

發掘儲存庫所使用的技術。

只辨識可觀察到的技術。

不要分析架構。

不要分析業務邏輯。

---

# 職責

本 Skill「應當」

- 辨識程式語言

- 辨識框架

- 辨識執行環境

- 辨識應用伺服器

- 辨識資料庫

- 辨識 ORM 框架

- 辨識日誌框架

- 辨識測試框架

- 辨識建置系統

- 辨識相依套件管理工具

- 辨識訊息傳遞技術

- 辨識快取技術

- 辨識排程技術

- 辨識容器技術

- 辨識雲端技術

- 辨識 API 技術

- 辨識安全框架

本 Skill「不得」

- 推測架構

- 分析業務規則

- 分析原始碼流程（由 module-analysis 負責，見 shared/logic-depth.md）

- 產生規格

- 產生循序圖

---

# 輸入

儲存庫清冊

建置檔

組態檔

相依定義

容器檔案

---

# 交付物

docs/overview/

technology-stack.md

frameworks.md

runtime-environment.md

dependency-summary.md

---

# 證據規則

每一項辨識出的技術都必須有證據支撐。

範例

pom.xml

build.gradle

package.json

Dockerfile

server.xml

application.yml

Import 敘述

Annotation

組態

Unknown 是可以接受的。

絕不臆測。

---

# 完成判準

每一項主要技術都已分類。

每一個框架都有證據。

每一個執行環境都有證據。

每一項資料庫技術都有證據。

---

# 被下列 Skill 依賴

architecture-discovery

artifact-enumeration

module-analysis

database-analysis

interface-analysis

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
- shared/logic-depth.md

違反任一共用規則的文件即為「不完整」，
無論其內容如何。

---

# Prompt

# 技術探索

---

## 目標

辨識儲存庫所使用的每一項技術。

本 Skill 只記錄技術。

不要分析軟體設計。

---

## 步驟 1

辨識程式語言

範例

Java

Kotlin

Scala

COBOL

JavaScript

TypeScript

C#

Python

Go

PHP

SQL

XML

YAML

JSON

Shell

記錄

語言

版本（若已知）

證據

---

## 步驟 2

辨識框架

範例

Spring Boot

Spring MVC

Spring Security

Jakarta EE

Java EE

EJB

Hibernate

MyBatis

Express

NestJS

ASP.NET

Django

Flask

React

Angular

Vue

記錄

框架

版本

證據

---

## 步驟 3

辨識執行環境

範例

JDK

.NET Runtime

Node.js

Python

Go Runtime

PHP Runtime

記錄

執行環境

版本

證據

---

## 步驟 4

辨識應用伺服器

範例

WebSphere

Tomcat

JBoss

WildFly

WebLogic

Jetty

Undertow

記錄

伺服器

版本

證據

---

## 步驟 5

辨識建置系統

範例

Maven

Gradle

Ant

npm

pnpm

yarn

MSBuild

Make

記錄

工具

版本

Wrapper

證據

---

## 步驟 6

辨識資料庫

範例

Oracle

DB2

SQL Server

PostgreSQL

MySQL

MariaDB

SQLite

MongoDB

Redis

記錄

資料庫

驅動程式

證據

---

## 步驟 7

辨識 ORM

範例

Hibernate

JPA

MyBatis

JDBC

Entity Framework

Dapper

記錄

ORM

證據

---

## 步驟 8

辨識訊息傳遞

範例

IBM MQ

JMS

Kafka

RabbitMQ

ActiveMQ

Azure Service Bus

AWS SQS

記錄

技術

證據

---

## 步驟 9

辨識 API 技術

範例

REST

SOAP

GraphQL

gRPC

JAX-RS

OpenAPI

Swagger

記錄

技術

證據

---

## 步驟 10

辨識安全機制

範例

Spring Security

JAAS

LDAP

OAuth

OIDC

JWT

SAML

TLS

SSL

記錄

技術

證據

---

## 步驟 11

辨識日誌

範例

SLF4J

Logback

Log4j

java.util.logging

NLog

Serilog

記錄

技術

證據

---

## 步驟 12

辨識測試

範例

JUnit

Mockito

Spock

TestNG

Jest

Mocha

PyTest

NUnit

記錄

技術

證據

---

## 步驟 13

辨識容器

範例

Docker

Docker Compose

Kubernetes

OpenShift

Helm

Podman

記錄

技術

證據

---

## 步驟 14

辨識 CI/CD

範例

GitHub Actions

GitLab CI

Jenkins

Azure DevOps

Bamboo

記錄

技術

證據

---

## 輸出規則

只做分類。

絕不推測架構。

絕不推測模組之間的相依關係。

絕不解釋執行流程。

絕不描述業務規則。

---

## 必要輸出

產生

docs/overview/technology-stack.md

docs/overview/frameworks.md

docs/overview/runtime-environment.md

docs/overview/dependency-summary.md

---

## 品質檢查清單

☐ 每種語言都已分類

☐ 每個框架都已分類

☐ 已辨識執行環境

☐ 已辨識建置工具

☐ 已辨識資料庫

☐ 已辨識 ORM

☐ 已辨識訊息傳遞

☐ 已辨識安全機制

☐ 已辨識日誌

☐ 已辨識測試

☐ 已辨識容器技術

☐ 已辨識 CI/CD

☐ 已附上證據

☐ 沒有任何幻覺內容

---

結束。
