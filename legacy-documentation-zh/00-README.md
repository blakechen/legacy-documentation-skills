# 舊系統文件產生技能組（Legacy Documentation Skills）

以 AI 驅動的舊有軟體系統逆向工程框架。

從既有的程式碼庫產生架構文件、模組文件、
資料庫規格、API 文件、
業務規則與功能規格。

---

# 特性

支援

- Java

- Spring Boot

- Jakarta EE

- WebSphere

- EJB

- COBOL

- C#

- .NET

- Node.js

- Python

- Go

- PHP

- Kotlin

- Scala

---

產出

- 架構文件

- 模組文件

- 資料庫文件

- API 文件

- 業務規則

- 循序圖

- 功能規格

- 技術規格

- 落差分析

---

程式碼庫

↓

清冊盤點（Inventory）

↓

技術探索（Technology Discovery）

↓

架構探索（Architecture Discovery）

↓

成品列舉（Artifact Enumeration）

↓

模組分析（Module Analysis）

↓

資料庫分析（Database Analysis）

↓

介接分析（Interface Analysis）

↓

業務規則萃取（Business Rule Extraction）

↓

循序探索（Sequence Discovery）

↓

規格產生（Specification Generation）

↓

落差分析（Gap Analysis）

---

文件必須是

- 具決定性的（deterministic）

- 以證據為本的（evidence-based）

- 與實作無關的（implementation-independent）

- 可追溯的（traceable）

---

## 儲存庫結構

orchestrators/

skills/

skills/templates/

shared/

examples/

integrations/

---

## 支援的 AI 工具

GitHub Copilot

Claude Code

Cursor

Codex CLI

Gemini CLI

Continue.dev

Windsurf

---

## 設計理念

寫「未知」優於臆測。

證據是必要的。

每一個陳述都必須可追溯。

每一個 Skill 只負責單一職責。

---

## 授權

MIT
