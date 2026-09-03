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
  - fact-extraction

shared:
  - enumeration-first
  - verification-tiers
  - fact-layer
  - prioritization
  - mechanical-verification
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
  - docs/enumeration/enumeration-evidence.psv
  - docs/enumeration/enumeration-config.psv
  - docs/enumeration/enumeration-report.md
  - docs/enumeration/priority.txt
  - docs/enumeration/batches.txt
  - docs/enumeration/priority-report.md
---

# 目標

建立程式碼庫中每一個主要單元的完整主清單。

本 Skill 是階段 1 與階段 2 之間的關卡。

套用 shared/enumeration-first.md。

套用 shared/custom-framework-recognition.md。

本 Skill 只記錄身分與位置。

行為、邏輯與業務意義都不在本 Skill 的範圍內。


套用 shared/fact-layer.md。

套用 shared/prioritization.md。

清單是從 `fact-extraction` 所建立的 factbase「查詢」出來的，
不是從原始碼文字「搜尋」出來的。
見 shared/enumeration-first.md 之「列舉是查詢，不是搜尋」。

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

設定基底類別。

寫入 `docs/enumeration/enumeration-config.psv`

    {
      "transaction_base": ["StdTrxObject"],
      "db_object_base":   ["StdDbObject"],
      "servlet_base":     ["javax.servlet.http.HttpServlet"]
    }

只寫簡單名稱即可；隨 jar 出貨的基底類別會被對應到 `EXTERNAL:` 節點。

若尚未確定基底類別，先不帶 config 執行步驟 4。
工具會從階層提出一份建議並寫出。建議不是結論：
對照步驟 1 與步驟 2 審視它，修正後才繼續。

---

## 步驟 4

列舉。

    sh tools/factbase/enumerate.sh \
        --facts <repo>/docs/facts \
        --out <repo>/docs/enumeration

這會依既定的管線分隔格式寫出三份主清單，
加上記錄每筆條目來源的 `enumeration-evidence.psv`，
以及 `enumeration-report.md`。

工具會處理、且本 Skill 應回報：

- 基底類別之下任何深度的遞移子類別
- 不在原始碼樹內之基底類別的子類別
- 僅由字串常值透過反射指名的類別
- 看起來像單元名稱、卻對應不到任何已知類別的字串常值

---

## 步驟 5

閱讀來源分佈。

`enumeration-report.md` 記錄每一筆條目的繼承深度。

每一筆深度 > 1 的條目，都是 `grep "extends <Base>"` 會漏掉的條目。
載明有多少筆。
若一個使用自訂框架的系統這個數字是零，
應該懷疑所設定的基底類別，而不是感到滿意。

每一筆指向不存在之物的類別參照都應被解決：
是掃描範圍外的類別，或是一筆死掉的註冊。記錄屬於哪一種。

---

## 步驟 6

獨立驗證

Oracle 是 bytecode，不是第二次搜尋。

`docs/facts/bytecode-verification.md` 由 `fact-extraction` Skill 產生。
閱讀其狀態。

`VERIFIED` — 繼續。

`FAILED` — 階段 2 遭封鎖。
編譯產物中存在掃描沒找到的類別。解決後才可繼續。

`UNAVAILABLE` — 繼續，但要在 `enumeration-report.md` 中載明
本次列舉僅依賴詞法抽取。不得稱之為已驗證。這是層級 B。

若本 Skill 的工具根本無法執行，列舉就是「讀」出來的。
那是層級 C，`enumeration-report.md` 應逐字載明
shared/verification-tiers.md 中的揭露：
本列舉「沒有」檢查遞移繼承、原始碼樹之外的基底類別、以及反射註冊，
而且本次執行無法指出漏了哪些。

以不同表示式重新掃描原始碼「不是」驗證，也不得如此回報。

---

## 步驟 7

路徑驗證

`enumerate.sh` 只會寫出「型別來自已剖析檔案」的條目，
因此每個路徑就結構而言必然可解析。

獨立確認檔案數：

    wc -l docs/enumeration/*.txt

並確認每份清單中的每個路徑都存在。

無法解析的路徑是 factbase 的缺陷，應予回報。

---

## 步驟 8

排定優先序。

    sh tools/factbase/prioritize.sh \
        --repo <repo> --facts <repo>/docs/facts \
        --enumeration <repo>/docs/enumeration \
        [--usage usage.csv --usage-map codes.csv] [--since 3.years]

產生 `priority.txt`、`batches.txt` 與 `priority-report.md`。

向現場索取執行期使用量檔案。
它是三個訊號中最強的一個，也是唯一儲存庫無法提供的一個。
若無法取得，載明排序僅依賴可達性與變更頻率。

逐一指名每一個不可達的單元。
不可達是死碼的候選，不是判決：
排程器、訊息監聽器與維運腳本都是此掃描不模擬的進入點。

---

## 步驟 9

列舉報告

`enumerate.sh` 會產生 `docs/enumeration/enumeration-report.md`。

以人工補上：

- 哪些基底類別是設定的、哪些是自動偵測的，以及自動偵測者為何被接受
- 每一筆指向不存在之物的類別參照的解決結果
- oracle 狀態，逐字引用
- 是否提供了執行期使用量檔案

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

☐ 已辨識 dispatcher，或明確記錄為 NONE

☐ 已辨識交易基底類別

☐ 已辨識資料庫物件基底類別

☐ transaction-classes.txt 存在且行數 > 0

☐ db-object-classes.txt 存在且行數 > 0

☐ servlet-classes.txt 存在且行數 > 0

☐ 每一行皆符合所定義的管線分隔格式

☐ 每個記錄的路徑都對應到存在的檔案

☐ 每個數量皆已對照 bytecode oracle 驗證，或已記錄 oracle 不存在

☐ 已記錄每一筆條目的繼承深度

☐ 已計算並回報「僅由遞移閉包找到」的條目數

☐ 已計算並回報「僅由反射找到」的條目數

☐ 每一筆指向不存在之物的類別參照皆已解決

☐ 已產生 priority.txt、batches.txt 與 priority-report.md

☐ 已逐一指名不可達的單元

☐ 已索取執行期使用量檔案，若未提供則已記錄

☐ 已產生列舉報告

☐ 沒有近似計數

☐ 沒有抽樣

☐ 沒有僅靠文字搜尋產生的列舉

☐ 未描述任何行為

結束。
