# Legacy Documentation Skills

以 AI 驅動的老舊軟體系統逆向工程框架。

從既有的程式碼庫產生架構文件、模組文件、
資料庫規格、API 文件、
業務規則與功能規格。

---

# 功能特性

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

事實抽取（解析；建立 factbase；對照 bytecode 驗證）

↓

清冊盤點

↓

技術探索

↓

架構探索

↓

產出物列舉（由 factbase 查詢而來）

↓

優先排序

↓

原型分群

↓

反思檢查

↓

模組分析

↓

資料庫分析

↓

介面分析

↓

業務規則抽取

↓

循序探索

↓

規格產生

↓

特徵化測試

↓

落差分析（深度與陳舊度，由工具判定）

---

本框架產出的文件

- 標示自身驗證強度（層級 A、B 或 C）

- 由解析出的事實庫推導而來，而非靠閱讀

- 對照編譯產出物獨立驗證

- 由可執行的關卡檢查，而非靠口頭宣稱

- 以證據為本

- 與實作方式無關

- 可追溯

- 版本鎖定，因此可分辨有效引用與已腐化的引用

---

## 儲存庫結構

orchestrators/

skills/

skills/templates/

shared/

tools/          決定性的抽取與驗證
tools/shell/         POSIX shell + awk
tools/powershell/    PowerShell 7

examples/

examples/fixtures/   黃金案例；`sh tools/shell/selftest.sh`

integrations/

---

## 支援的 AI

GitHub Copilot

Claude Code

Cursor

Codex CLI

Gemini CLI

Continue.dev

Windsurf

---

## 理念

「未知」優於「臆測」。

證據是強制要求。

每一句陳述都必須可追溯。

每個 Skill 只負一項責任。

由解析器確立事實。由模型賦予意義。順序絕不可顛倒。

沒有任何程式能夠推翻的完成宣稱，就不算完成宣稱。

六份深度完備的文件，勝過 458 份淺薄的文件。

---

## 環境需求

一個 POSIX shell 與 `awk`。無須安裝任何東西。

即使連這些都沒有，本函式庫仍可執行，但落在層級 C：方法完整保留、
驗證全部缺席，且每一份報告都會標記
`VERIFICATION: NONE`。見 `shared/verification-tiers.md`。

當需要以編譯產出物作為獨立判準時，則需 `javap`、`javac` 與 `jar`。
它們的缺席會被記錄下來，而不會被繞過。

除此之外別無所需。不需直譯器、不需相依套件、不需建置步驟、不需網路。

---

## 授權

MIT
