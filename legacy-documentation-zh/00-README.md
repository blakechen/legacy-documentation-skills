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

事實抽取（Fact Extraction：剖析、建 factbase、以 bytecode 驗證）

↓

清冊盤點（Inventory）

↓

技術探索（Technology Discovery）

↓

架構探索（Architecture Discovery）

↓

成品列舉（Artifact Enumeration，從 factbase 查詢）

↓

優先序排定（Prioritization）

↓

原型分群（Archetype Clustering）

↓

Reflexion 檢查（Reflexion Check）

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

Characterization 測試

↓

落差分析（Gap Analysis，深度與過期皆由工具判定）

---

文件必須是

- 標示自身驗證強度的（層級 A、B 或 C）

- 由剖析出的事實庫推導而來，而非靠閱讀

- 以編譯產物獨立驗證過

- 由可執行的關卡檢查，而非由宣稱

- 以證據為本的（evidence-based）

- 與實作無關的（implementation-independent）

- 可追溯的（traceable）

- 綁定版本的，使「有效引用」與「已腐爛的引用」可以區分

---

## 儲存庫結構

orchestrators/

skills/

skills/templates/

shared/

tools/          確定性的抽取與驗證工具（POSIX shell + awk）

examples/

examples/fixtures/   golden case；執行 `sh tools/selftest.sh`

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

剖析器負責確立事實。模型負責指派意義。絕不反過來。

一個沒有任何程式能夠推翻的完成宣告，不算是完成宣告。

六份深度完備的文件，勝過 458 份淺薄的文件。

---

## 環境需求

POSIX shell 與 `awk`。不需安裝任何東西。

若連這個都沒有，本技能組仍然可以執行，屬於層級 C：
完整的方法、零驗證，且每一份報告都標示 `VERIFICATION: NONE`。
見 `shared/verification-tiers.md`。

若要以編譯產物作為獨立 oracle，需要 `javap`、`javac` 與 `jar`。
它們不存在時會被記錄，而不是繞過。

其他無。沒有直譯器、沒有相依套件、沒有建置步驟、不需要網路。

---

## 授權

MIT
