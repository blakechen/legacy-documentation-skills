---
name: artifact-enumeration

description: |
  列舉程式碼庫中的每一個主要單元，並將主清單持久化到磁碟。
  本 Skill 產生具權威性的列舉檔案，作為所有階段 2 Skill 的關卡。
  它只負責清點與定位成品，絕不描述這些成品「做什麼」。

version: 1.0.0

category: discovery

author: Legacy Documentation Skills

tags:
  - enumeration
  - transaction
  - servlet
  - db-object
  - gate
  - reverse-engineering

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

dependencies:
  - inventory
  - technology-discovery
  - architecture-discovery

shared:
  - enumeration-first
  - custom-framework-recognition
  - evidence-rules
  - confidence-scoring
  - documentation-style
  - markdown-style
  - naming-conventions
  - output-schema
  - quality-checklist

outputs:
  - docs/enumeration/transaction-classes.txt
  - docs/enumeration/db-object-classes.txt
  - docs/enumeration/servlet-classes.txt
  - docs/enumeration/enumeration-report.md
---

# 目標

建立程式碼庫中每一個主要單元的完整主清單。

本 Skill 是階段 1 與階段 2 之間的關卡。

套用 shared/enumeration-first.md。

套用 shared/custom-framework-recognition.md。

本 Skill 只記錄身分與位置。

行為、邏輯與業務意義都不在本 Skill 的範圍內。

---

# 職責

本 Skill 應（SHALL）

- 辨識派發器（dispatcher）或路由類別

- 辨識交易基底類別

- 辨識資料庫物件基底類別

- 列舉「每一個」交易／動作類別

- 列舉「每一個」資料庫物件子類別

- 列舉「每一個」servlet

- 記錄每一個已列舉類別的檔案路徑

- 記錄每一個資料庫物件已宣告的目標資料表

- 將每一份清單以機器可讀的檔案持久化到磁碟

- 以獨立掃描驗證每一份清單

- 回報每一份清單經驗證後的數量

本 Skill 不得（SHALL NOT）

- 描述某個類別做什麼

- 萃取業務規則

- 分析方法邏輯

- 產生逐單元文件

- 以近似數量取代清單

- 在取樣幾個代表性檔案後就停止

---

# 輸入

docs/overview/repository-inventory.md

docs/overview/project-structure.md

docs/overview/technology-stack.md

docs/overview/frameworks.md

docs/architecture/architecture.md

docs/architecture/component-diagram.md

原始碼

部署描述檔（Deployment Descriptors）

---

# 交付物

docs/enumeration/

transaction-classes.txt

db-object-classes.txt

servlet-classes.txt

enumeration-report.md

---

# 檔案格式

每行一筆。

以管線符號（`|`）分隔。

不得有標頭列。

不得有空行。

transaction-classes.txt

`ClassName|relative/path/to/File.java`

servlet-classes.txt

`ClassName|relative/path/to/File.java`

db-object-classes.txt

`ClassName|relative/path/to/File.java|TargetTable`

第三個欄位只出現在 db-object-classes.txt。

無法從原始碼判定目標資料表時，寫 `UNKNOWN`。

絕不省略該欄位。

---

# 證據規則

每一筆條目都必須對應到真實存在的檔案。

每一個路徑都必須能從程式碼庫根目錄解析。

無法定位的類別不列入列舉。

Unknown 是可接受的。

猜測是禁止的。

---

# 完成條件

列舉在滿足以下所有條件時才算完成

docs/enumeration/transaction-classes.txt 存在且行數 > 0

且

docs/enumeration/db-object-classes.txt 存在且行數 > 0

且

docs/enumeration/servlet-classes.txt 存在且行數 > 0

且

每一行都符合所宣告的檔案格式

且

每一個記錄的路徑都能解析到實際存在的檔案

且

每一份清單的行數都已用獨立掃描驗證過。

任一條件未滿足，階段 2 即為「封鎖（BLOCKED）」。

---

# 相依關係

inventory

technology-discovery

architecture-discovery

---

# 被以下 Skill 依賴

module-analysis

database-analysis

interface-analysis

business-rule-extraction

sequence-discovery

specification-generation

gap-analysis

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

違反任一共用規則的文件即為「未完成」，
無論其內容多寡。

---

# 提示（Prompt）

# 成品列舉 Skill

---

## 目的

產出每一個主要單元的權威性主清單。

不描述行為。

不取樣。

窮盡列舉。

持久化到磁碟。

---

## 步驟 1

辨識派發器（Dispatcher）

找出負責把進入的請求路由到交易類別的類別。

搜尋

讀取交易代碼參數的 servlet

路由表

以交易代碼為鍵的 switch 或 map

依名稱實體化交易類別的工廠（factory）

把代碼對應到類別的設定檔

記錄

派發器類別

檔案路徑

路由機制

路由鍵（參數名稱、標頭、URL 片段）

若不存在派發器，記錄 `Dispatcher: NONE` 後繼續。

---

## 步驟 2

辨識基底類別

找出交易基底類別。

搜尋

派發器所實體化之類別的共同父型別

只有單一 execute 型進入方法的抽象類別

每個 action 類別都實作的介面

找出資料庫物件基底類別。

搜尋

對外提供資料表名稱與欄位定義的抽象類別

基底 DAO 或 record 型別

持久化父類別

記錄

交易基底類別 + 檔案路徑

資料庫物件基底類別 + 檔案路徑

偵測證據

若系統使用自訂框架，在斷定「不存在基底類別」之前，
必須先套用 shared/custom-framework-recognition.md。

---

## 步驟 3

列舉交易類別

找出「每一個」符合下列任一條件的類別

繼承或實作交易基底類別

或

被派發器的路由機制所參照

或

登錄在路由設定檔中

將三種搜尋的結果取聯集。

以完整類別名稱去除重複。

每個類別寫一行到

`docs/enumeration/transaction-classes.txt`

格式

`ClassName|relative/path/to/File.java`

「數量」不是列舉。

`grep -c` 的輸出不是列舉。

檔案必須包含實際的名稱與路徑。

---

## 步驟 4

列舉資料庫物件類別

找出「每一個」符合下列任一條件的類別

繼承資料庫物件基底類別

或

宣告了資料表對應註解

或

登錄在 ORM 對應檔中

從每個類別取出目標資料表名稱。

每個類別寫一行到

`docs/enumeration/db-object-classes.txt`

格式

`ClassName|relative/path/to/File.java|TargetTable`

無法判定目標資料表時，寫 `UNKNOWN`。

不得從類別名稱反推資料表名稱。

---

## 步驟 5

列舉 Servlet

找出「每一個」符合下列任一條件的類別

繼承 HttpServlet

或

宣告於 web.xml

或

帶有 servlet 註解

或

宣告於容器專屬的部署描述檔

每個類別寫一行到

`docs/enumeration/servlet-classes.txt`

格式

`ClassName|relative/path/to/File.java`

---

## 步驟 6

獨立驗證

對每一個已產生的檔案

計算行數

以「不同的」搜尋表達式重新掃描程式碼庫

比對兩次的數量

若數量不一致

回報差異

指出缺少的條目

重新掃描

差異未解決前，不得繼續。

---

## 步驟 7

路徑驗證

對每個檔案中的每一筆條目

確認記錄的路徑能解析到實際存在的檔案

不得無聲移除任何條目。

無法解析的路徑是缺陷，必須回報並修正。

---

## 步驟 8

列舉報告

產生 `docs/enumeration/enumeration-report.md`

記錄

派發器類別與路由機制

交易基底類別

資料庫物件基底類別

交易類別數量

資料庫物件類別數量

Servlet 數量

每個數量所使用的驗證方法

尚未解決的差異

目標資料表為 UNKNOWN 的類別

---

## 步驟 9

批次規劃建議

若交易類別數量超過 50

依套件或模組提出批次計畫

將建議的批次記錄在列舉報告中

格式

`batch N | package | units in batch`

此計畫由協調器（orchestrator）取用。

本 Skill 不負責執行這些批次。

---

# 輸出規則

絕不描述某個類別做什麼。

絕不分析方法。

絕不萃取規則。

絕不產生逐單元文件。

絕不在沒有對應清單的情況下回報數量。

只做列舉。

---

# 必要輸出

產生

docs/enumeration/transaction-classes.txt

docs/enumeration/db-object-classes.txt

docs/enumeration/servlet-classes.txt

docs/enumeration/enumeration-report.md

---

# 失敗回報

若交易類別數量為零

停止整條管線。

回報

- 已執行過哪些搜尋
- 評估過哪些基底類別候選
- 評估過哪些派發器候選
- 各自因為什麼理由被排除

「零個交易類別」是關鍵失敗（critical failure），不是空結果。

---

# 品質檢查清單

☐ 已辨識派發器，或已明確記錄為 NONE

☐ 已辨識交易基底類別

☐ 已辨識資料庫物件基底類別

☐ transaction-classes.txt 存在且行數 > 0

☐ db-object-classes.txt 存在且行數 > 0

☐ servlet-classes.txt 存在且行數 > 0

☐ 每一行都符合所宣告的管線分隔格式

☐ 每一個記錄的路徑都能解析到實際存在的檔案

☐ 每一個數量都經過獨立驗證

☐ 已產生列舉報告

☐ 沒有近似數量

☐ 沒有取樣

☐ 沒有描述任何行為

---

結束。
