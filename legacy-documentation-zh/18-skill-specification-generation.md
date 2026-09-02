---
name: specification-generation

description: |
  依據先前各 Skill 所產生的文件，產出完整的軟體規格。
  本 Skill 將架構、技術與業務知識整合為
  與實作無關的規格。

version: 1.0.0

category: specification

author: Legacy Documentation Skills

tags:
  - specification
  - documentation
  - functional-spec
  - technical-spec
  - reverse-engineering

dependencies:
  - inventory
  - technology-discovery
  - architecture-discovery
  - artifact-enumeration
  - module-analysis
  - database-analysis
  - interface-analysis
  - business-rule-extraction
  - sequence-discovery

shared:
  - evidence-rules
  - confidence-scoring
  - documentation-style
  - markdown-style
  - naming-conventions
  - output-schema
  - quality-checklist
  - enumeration-first
  - logic-depth

templates:
  - specification
  - transaction
  - glossary

outputs:
  - docs/specifications/system-specification.md
  - docs/specifications/functional-specification.md
  - docs/specifications/technical-specification.md
  - docs/specifications/module-specifications/
  - docs/specifications/transactions/
  - docs/specifications/api-specification.md
  - docs/specifications/database-specification.md
  - docs/specifications/glossary.md
  - docs/specifications/assumptions.md
  - docs/specifications/limitations.md
---

# 目標

產生與實作無關的規格。

規格應僅以已驗證的文件為基礎。

本 Skill 不執行一手的原始碼分析。

原始碼只能用來驗證上游文件中「已經存在」的陳述。

---

# 職責

本 Skill 應（SHALL）

- 整合文件

- 產生功能規格

- 產生技術規格

- 產生模組規格

- 產生 API 規格

- 產生資料庫規格

- 產生詞彙表

- 產生假設清單

- 產生限制清單

- 指出未解決的問題

本 Skill 不得（SHALL NOT）

- 執行一手的原始碼分析（方法層級邏輯由 module-analysis 擁有）

- 降低上游模組文件的深度

- 探索新的業務規則

- 推測未記錄的行為

- 修改先前的文件

---

# 輸入

清冊盤點

技術探索

架構探索

模組分析

資料庫分析

介接分析

業務規則萃取

循序探索

---

# 交付物

docs/specifications/

system-specification.md

functional-specification.md

technical-specification.md

api-specification.md

database-specification.md

module-specifications/

glossary.md

assumptions.md

limitations.md

---

# 證據規則

每個章節都應引用先前產生的文件。

絕不引入新的事實。

若資訊無法取得，

就寫

Unknown（未知）

不要臆測。

---

# 完成條件

功能規格已完成。

技術規格已完成。

API 規格已完成。

資料庫規格已完成。

模組規格已完成。

所有引用皆有效。

---

# 被以下 Skill 依賴

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
- shared/enumeration-first.md
- shared/logic-depth.md

文件結構應（SHALL）依循：

- skills/templates/specification.md
- skills/templates/transaction.md
- skills/templates/glossary.md

違反任一共用規則的文件即為「未完成」，
無論其內容多寡。

---

# 提示（Prompt）

# 規格產生（Specification Generation）

---

# 目標

運用先前產生的文件來產出軟體規格。

原始碼只能用來驗證上游文件中「已經存在」的陳述。
深度來自 docs/modules/transactions/，而不是來自重新閱讀原始碼。

不要推測未記錄的行為。

---

# 關鍵：逐交易規格

套用 shared/enumeration-first.md。

套用 shared/logic-depth.md。

以 skills/templates/transaction.md 作為必要結構。

1. 從模組分析取得完整的交易類別清單。

2. 針對「每一個」交易類別，在 docs/specifications/transactions/ 底下產生一份規格。

3. 每份交易規格都應包含：

   - 目的、進入 URL 與路由參數

   - 一份 State Method 索引

   - 每個方法一個 `### Method:` 子章節，
     由 docs/modules/transactions/[ClassName].md 承接下列內容：

     * 處理流程（逐字照錄或加以澄清，絕不縮短）

     * 虛擬碼（逐字照錄）

     * 欄位對應（逐字照錄）

     * 分支與條件

   - 在原本「關鍵原始碼引用」的位置，改放一行參照：

     `Source evidence: ../../modules/transactions/[ClassName].md#method-[name]`

   - 輸入欄位與驗證規則

   - 存取到的資料庫資料表，含操作與欄位

   - 外部系統呼叫

   - 強制執行的業務規則（引用 BR-ID）

   - 輸出頁面／轉導

   - 錯誤處理

   - 安全需求

   - 相關循序圖（引用）

4. 「不要」只產出系統層級的摘要。逐交易規格是「必要」的。

5. 若某份規格的方法子章節比對應的模組文件章節還短，即為「不完整」。

---

# 輸入文件

讀取

overview/

architecture/

modules/

database/

integration/

business-rules/

sequence/

只使用已驗證的文件。

---

# 步驟 1

產生系統規格

包含

目的

範圍

架構摘要

技術摘要

主要模組

外部系統

限制條件

已知限制

引用

---

# 步驟 2

產生功能規格

套用 shared/logic-depth.md。

以 skills/templates/specification.md 作為必要結構。

描述

系統職責

功能領域

參與者（Actor）

業務能力

業務規則

系統輸入

系統輸出

相依關係

引用的循序圖

引用的 API

引用的資料庫物件

---

# 步驟 3

產生技術規格

套用 shared/logic-depth.md。

以 skills/templates/specification.md 作為必要結構。

描述

架構

層次

元件

套件

技術堆疊

執行環境

部署假設

資料庫技術

訊息傳遞技術

安全技術

---

# 步驟 4

產生模組規格

每個模組產生一份文件。

每個模組都應包含

目的

職責

相依關係

進入點

介面

組態設定

資料庫物件

相關業務規則

相關循序圖

引用的 API

---

# 步驟 5

產生 API 規格

彙整

REST

SOAP

MQ

Kafka

gRPC

檔案介接

身分驗證

錯誤處理

重試

外部系統

---

# 步驟 6

產生資料庫規格

彙整

資料庫技術

綱要

資料表

檢視表

序列

Repository

實體

交易

持久化技術

ER 圖引用

---

# 步驟 7

產生詞彙表

蒐集

業務術語

技術術語

縮寫

系統名稱

模組名稱

外部系統

不要自創術語。

---

# 步驟 8

產生假設清單

列出

僅限明確的假設。

絕不推測。

---

# 步驟 9

產生限制清單

範例

未知模組

證據不完整

文件缺漏

組態無法取得

引用無法解析

---

# 輸出規則

每一項陳述都必須引用先前產生的文件。

絕不執行一手的原始碼分析。只能為了驗證既有陳述而閱讀原始碼。

絕不把 docs/modules/transactions/ 中既有的處理流程、虛擬碼或欄位對應
摘要掉。要把它們承接下來。

絕不引入新的業務規則。

絕不虛構需求。

絕不改寫證據。

絕不移除不確定性。

---

# 必要輸出

產生

docs/specifications/system-specification.md

docs/specifications/functional-specification.md

docs/specifications/technical-specification.md

docs/specifications/api-specification.md

docs/specifications/database-specification.md

docs/specifications/glossary.md

docs/specifications/assumptions.md

docs/specifications/limitations.md

docs/specifications/module-specifications/

docs/specifications/transactions/（每個交易類別一個檔案）

---

# 品質檢查清單

☐ 功能規格已完成

☐ 技術規格已完成

☐ 模組規格已完成

☐ API 規格已完成

☐ 資料庫規格已完成

☐ 詞彙表已完成

☐ 已記錄假設

☐ 已記錄限制

☐ 每一項陳述皆可追溯

☐ 未引入新知識

☐ 無幻覺內容

---

結束。
