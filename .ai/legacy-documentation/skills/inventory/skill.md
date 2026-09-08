---
name: inventory

description: |
  掃描儲存庫並建立軟體專案的決定性清冊。
  本 Skill 只發掘可觀察的事實，
  並為所有下游文件產生 Skill 打下基礎。

version: 1.0.0

category: discovery

author: Legacy Documentation Skills

tags:
  - inventory
  - repository
  - discovery
  - reverse engineering
  - documentation

supported-languages:
  - Java
  - Kotlin
  - Scala
  - COBOL
  - C#
  - VB.NET
  - Node.js
  - TypeScript
  - JavaScript
  - Python
  - Go
  - PHP

shared:
  - evidence-rules
  - confidence-scoring
  - documentation-style
  - markdown-style
  - naming-conventions
  - output-schema
  - quality-checklist

templates:
  - system-overview

outputs:
  - docs/overview/system-overview.md
  - docs/overview/project-structure.md
  - docs/overview/repository-inventory.md
  - docs/overview/file-statistics.md
---

# 目標

為儲存庫建立完整的清冊。

本 Skill 只記錄可觀察的事實。

業務邏輯不在本 Skill 的範圍內。

---

# 職責

本 Skill「應當」

- 辨識專案

- 辨識模組

- 辨識程式語言

- 辨識建置系統

- 辨識相依套件管理工具

- 辨識組態檔

- 辨識部署描述檔

- 辨識基礎設施檔案

- 辨識文件

- 辨識測試專案

- 辨識腳本

- 辨識容器

- 辨識 CI/CD

- 辨識產生的原始碼

- 辨識外部函式庫

本 Skill「不得」

- 推測業務規則

- 分析 SQL 邏輯

- 分析 API

- 分析架構

- 分析工作流程

- 建立規格

---

# 輸入

儲存庫根目錄

原始碼

組態檔

建置檔

文件

腳本

容器檔案

CI/CD 定義

---

# 交付物

docs/overview/

system-overview.md

project-structure.md

repository-inventory.md

file-statistics.md

---

# 證據規則

每一項觀察都必須參照實際存在的檔案。

絕不推測缺少的資訊。

Unknown 是可以接受的。

臆測則是被禁止的。

---

# 完成判準

當下列各項

每個目錄

每個專案

每個模組

每個建置檔

每份組態

都已建立索引時，清冊即為完成。

---

# 相依

無

---

# 被下列 Skill 依賴

technology-discovery

architecture-discovery

artifact-enumeration

module-analysis

database-analysis

interface-analysis

business-rule-extraction

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

文件結構「應當」遵循：

- skills/templates/system-overview.md

違反任一共用規則的文件即為「不完整」，
無論其內容如何。

---

# Prompt

# 清冊盤點 Skill

---

## 目標

遞迴掃描整個儲存庫。

建立完整清冊。

不要進行架構分析。

不要推測業務邏輯。

只記錄可觀察的事實。

---

## 步驟 1

辨識儲存庫類型

判定該儲存庫是

- Monorepo

- 多模組

- 單一應用程式

- 多儲存庫匯入

記錄證據。

---

## 步驟 2

辨識專案

找出每一個專案。

範例

Java

Node

.NET

Python

Go

PHP

COBOL

記錄

專案名稱

位置

主要語言

框架（若已知）

建置工具

進入點

---

## 步驟 3

辨識模組

對每一個專案

辨識其邏輯模組。

範例

loan

payment

customer

batch

shared

common

security

api

web

scheduler

---

## 步驟 4

程式語言

辨識每一種語言。

範例

Java

Kotlin

Groovy

Scala

COBOL

JavaScript

TypeScript

C#

Python

SQL

XML

YAML

JSON

Properties

Shell

PowerShell

Batch

---

## 步驟 5

建置系統

辨識

Gradle

Maven

Ant

npm

pnpm

yarn

MSBuild

Make

CMake

記錄

版本（若有）

wrapper

外掛

---

## 步驟 6

相依套件管理工具

找出

pom.xml

build.gradle

build.gradle.kts

package.json

packages.config

requirements.txt

go.mod

composer.json

記錄

相依管理工具

相依套件數量

重要函式庫

---

## 步驟 7

組態檔

找出

application.yml

application.properties

bootstrap.yml

server.xml

web.xml

context.xml

ibm-web-ext.xml

ibm-web-bnd.xml

docker-compose.yml

Dockerfile

.env

記錄

用途

位置

---

## 步驟 8

基礎設施

找出

Docker

Kubernetes

Helm

Terraform

Ansible

OpenShift

GitHub Actions

GitLab CI

Jenkins

Azure DevOps

---

## 步驟 9

資料庫線索

找出

SQL

DDL

Liquibase

Flyway

Hibernate

MyBatis

Stored Procedure

---

## 步驟 10

整合線索

找出

REST

SOAP

MQ

Kafka

FTP

SFTP

JMS

gRPC

RabbitMQ

---

## 步驟 11

文件

找出

README

架構文件

Wiki

設計文件

ADR

決策記錄

規格

Runbook

---

## 步驟 12

統計

蒐集

總檔案數

目錄數

專案數

模組數

語言數

組態檔數

文件檔數

SQL 檔數

測試數

建置檔數

---

# 輸出規則

絕不描述架構。

絕不描述業務規則。

絕不推測關聯。

絕不解釋工作流程。

只做清冊。

---

# 必要輸出

產生

docs/overview/system-overview.md

docs/overview/project-structure.md

docs/overview/repository-inventory.md

docs/overview/file-statistics.md

---

# 品質檢查清單

☐ 每個目錄都已建立索引

☐ 每個專案都已建立索引

☐ 每個模組都已建立索引

☐ 每個建置檔都已建立索引

☐ 每份組態都已建立索引

☐ 每種語言都已辨識

☐ 沒有任何假設

☐ 沒有任何幻覺內容

☐ 證據可取得

---

結束。
