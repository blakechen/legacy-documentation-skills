---
name: artifact-enumeration

description: |
  列舉儲存庫中的每一個主要單元，並把主清單持久化到磁碟。
  本 Skill 產出的列舉檔具有權威性，並作為所有 Phase 2 Skill 的關卡。
  它只計數與定位產出物，
  絕不描述它們做了什麼。

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

建立儲存庫中每一個主要單元的完整主清單。

本 Skill 是 Phase 1 與 Phase 2 之間的關卡。

套用 shared/enumeration-first.md。

套用 shared/fact-layer.md。

套用 shared/prioritization.md。

套用 shared/custom-framework-recognition.md。

這些清單是從 `fact-extraction` 所產生的 factbase「查詢」而來的，
不是靠搜尋原始碼文字產生的。見 shared/enumeration-first.md
「列舉是一次查詢，不是一次搜尋」。

本 Skill 只記錄身分與位置。

行為、邏輯與業務意義不在本 Skill 的範圍內。

---

# 職責

本 Skill「應當」

- 指出 dispatcher 或 router 類別

- 指出交易基底類別

- 指出 DB 物件基底類別

- 列舉「每一個」交易／動作類別

- 列舉「每一個」DB 物件子類別

- 列舉「每一個」servlet

- 記錄每一個被列舉類別的檔案路徑

- 記錄每一個 DB 物件（若有宣告）的目標資料表

- 把每一份清單以機器可讀的檔案持久化到磁碟

- 對照獨立掃描驗證每一份清單

- 回報每一份清單經驗證的數量

本 Skill「不得」

- 描述某個類別做了什麼

- 抽取業務規則

- 分析方法邏輯

- 產生逐單元文件

- 以概略數量取代清單

- 在代表性樣本之後就停止

---

# 輸入

docs/overview/repository-inventory.md

docs/overview/project-structure.md

docs/overview/technology-stack.md

docs/overview/frameworks.md

docs/architecture/architecture.md

docs/architecture/component-diagram.md

原始碼

部署描述檔

---

# 交付物

docs/enumeration/

transaction-classes.txt

db-object-classes.txt

servlet-classes.txt

enumeration-report.md

---

# 檔案格式

一行一筆條目。

以管線符號分隔。

無標題列。

無空行。

transaction-classes.txt

`ClassName|relative/path/to/File.java`

servlet-classes.txt

`ClassName|relative/path/to/File.java`

db-object-classes.txt

`ClassName|relative/path/to/File.java|TargetTable`

第三個欄位僅出現在 db-object-classes.txt。

當無法從原始碼判定目標資料表時，寫 `UNKNOWN`。

絕不省略該欄位。

---

# 證據規則

每一筆條目都必須參照真實存在的檔案。

每一個路徑都必須能從儲存庫根目錄解析。

無法定位的類別不列入列舉。

Unknown 是可以接受的。

臆測則是被禁止的。

---

# 完成判準

當下列條件成立時，列舉即為完成

docs/facts/types.psv 存在，且 bytecode 判準狀態已記錄

且

docs/enumeration/transaction-classes.txt 存在且行數 > 0

且

docs/enumeration/db-object-classes.txt 存在且行數 > 0

且

docs/enumeration/servlet-classes.txt 存在且行數 > 0

且

每一行都符合宣告的檔案格式

且

每一個記錄的路徑都能解析到存在的檔案

且

每一份清單的行數都已對照獨立掃描驗證。

若任一條件不成立，Phase 2 即被「阻斷」。

---

# 相依

inventory

technology-discovery

architecture-discovery

---

# 被下列 Skill 依賴

module-analysis

database-analysis

interface-analysis

business-rule-extraction

sequence-discovery

specification-generation

gap-analysis

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

違反任一共用規則的文件即為「不完整」，
無論其內容如何。

---

# Prompt

# 產出物列舉 Skill

---

## 目標

產出每一個主要單元的權威主清單。

不要記錄行為。

不要抽樣。

窮盡地列舉。

持久化到磁碟。

---

## 步驟 1

指出 Dispatcher

找出把進站請求路由到交易類別的那個類別。

搜尋

讀取交易代碼參數的 servlet

路由表

以交易代碼為鍵的 switch 或 map

依名稱實例化交易類別的 factory

把代碼對應到類別的組態檔

記錄

Dispatcher 類別

檔案路徑

路由機制

路由鍵（參數名稱、標頭、URL 片段）

若不存在 dispatcher，記錄 `Dispatcher: NONE` 後繼續。

---

## 步驟 2

指出基底類別

找出交易基底類別。

搜尋

dispatcher 所實例化之類別的父型別

帶有單一 execute 式進入方法的抽象類別

每個動作類別都實作的介面

找出 DB 物件基底類別。

搜尋

公開資料表名稱與欄位定義的抽象類別

基底 DAO 或記錄型別

持久化父類別

記錄

交易基底類別 + 檔案路徑

DB 物件基底類別 + 檔案路徑

偵測證據

若存在自製框架，在斷定「沒有基底類別」之前，
先套用 shared/custom-framework-recognition.md。

---

## 步驟 3

設定基底類別。

寫出 `docs/enumeration/enumeration-config.psv`

    {
      "transaction_base": ["StdTrxObject"],
      "db_object_base":   ["StdDbObject"],
      "servlet_base":     ["javax.servlet.http.HttpServlet"]
    }

只給簡單名稱即可；位於 jar 中的基底類別會以
`EXTERNAL:` 節點的形式比對。

若基底類別尚未確定，就在沒有設定檔的情況下執行步驟 4。
工具會從階層中提出一個建議並寫出。建議不是結論：
請對照步驟 1 與步驟 2 檢視並修正之後再繼續。

---

## 步驟 4

列舉。

    sh tools/shell/factbase/enumerate.sh \
        --facts <repo>/docs/facts \
        --out <repo>/docs/enumeration

這會以文件所述的管線分隔格式寫出三份主清單，
外加承載每一筆條目來源的 `enumeration-evidence.psv`，
以及 `enumeration-report.md`。

工具會解析出下列各項，而本 Skill「應當」回報：

- 遞移子類別，位於基底類別之下的任何深度
- 不在原始碼樹中的基底類別的子類別
- 僅由字串常值經反射指名的類別
- 看起來像單元名稱、卻對應不到任何已知類別的字串常值

---

## 步驟 5

閱讀發現方式的分佈。

`enumeration-report.md` 記錄了每一筆條目的繼承深度。

每一筆深度 > 1 的條目，都是 `grep "extends <Base>"` 會漏掉的條目。
請說明有多少筆。若在一個帶有自製框架的系統中這個數字是零，
該懷疑的是所設定的基底類別，而不是感到滿意。

每一個懸空類別參照都「應當」獲得處置：
是掃描根目錄之外的類別，還是一個失效的註冊。請記錄是哪一種。

---

## 步驟 6

獨立驗證

判準是 bytecode，而不是第二次搜尋。

`docs/facts/bytecode-verification.md` 由 `fact-extraction` Skill 產生。
閱讀它的狀態。

`VERIFIED` —— 繼續。

`FAILED` —— Phase 2 被「阻斷」。編譯產出物中存在掃描沒找到的類別。
解決之後才能繼續。

`UNAVAILABLE` —— 繼續，並在 `enumeration-report.md` 中記錄
該列舉僅立基於詞法抽取。不要稱它為已驗證。
這屬於層級 B。

若本 Skill 的工具根本無法執行，該列舉就是靠閱讀產生的。
那屬於層級 C，且 `enumeration-report.md`「應當」逐字帶上
shared/verification-tiers.md 中的揭露聲明：該列舉「未」針對
遞移繼承、樹外基底類別或反射註冊做過檢查，
且本次執行無法說出它漏掉了其中哪些。

以不同的表示式重新掃描原始碼「不是」驗證，
且「不得」以驗證之名回報。

---

## 步驟 7

路徑驗證

`enumerate.sh` 只寫出型別來自已解析檔案的條目，
因此每一個路徑依其構造方式都能解析。

獨立確認檔案數量：

    wc -l docs/enumeration/*.txt

並確認每一份清單中的每一個路徑都存在。

無法解析的路徑是 factbase 的缺陷，且「應當」回報。

---

## 步驟 8

排定優先序。

    sh tools/shell/factbase/prioritize.sh \
        --repo <repo> --facts <repo>/docs/facts \
        --enumeration <repo>/docs/enumeration \
        [--usage usage.csv --usage-map codes.csv] [--since 3.years]

會產生 `priority.txt`、`batches.txt` 與 `priority-report.md`。

向現場索取執行期使用量檔案。它是三種訊號中最強的一個，
也是唯一儲存庫無法提供的。若取得不到，
就記錄該排序僅立基於可達性與變更頻率。

逐一指名回報每一個不可達的單元。不可達是死碼的候選，不是判決：
排程器、訊息監聽器與維運腳本都是這次掃描沒有建模的進入點。

---

## 步驟 9

列舉報告

`enumerate.sh` 會產生 `docs/enumeration/enumeration-report.md`。

請以人工補上：

- 哪些基底類別是設定的、哪些是自動偵測的，
  以及為什麼接受那些自動偵測的結果
- 每一個懸空類別參照的處置結果
- 判準狀態，逐字引用
- 是否提供了執行期使用量檔案

---

# 輸出規則

絕不描述某個類別做了什麼。

絕不分析方法。

絕不抽取規則。

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

若找到零個交易類別

停止流水線。

回報

- 執行過的搜尋
- 評估過的基底類別候選
- 評估過的 dispatcher 候選
- 每一個候選被排除的原因

零個交易類別是關鍵失敗，不是一個空結果。

---

# 品質檢查清單

☐ 已指出 dispatcher，或已明確記錄為 NONE

☐ 已指出交易基底類別

☐ 已指出 DB 物件基底類別

☐ transaction-classes.txt 存在且行數 > 0

☐ db-object-classes.txt 存在且行數 > 0

☐ servlet-classes.txt 存在且行數 > 0

☐ 每一行都符合宣告的管線分隔格式

☐ 每一個記錄的路徑都能解析到存在的檔案

☐ 每一項數量都已對照 bytecode 判準驗證，或已記錄判準的缺席

☐ 已記錄每一筆條目的繼承深度

☐ 僅透過遞移閉包找到的條目已計數並回報

☐ 僅透過反射找到的條目已計數並回報

☐ 每一個懸空類別參照都已獲得處置

☐ 已產生 priority.txt、batches.txt 與 priority-report.md

☐ 已逐一指名列出不可達的單元

☐ 已索取執行期使用量檔案；若未提供，已記錄其缺席

☐ 已產生列舉報告

☐ 沒有概略數量

☐ 沒有抽樣

☐ 沒有僅靠文字搜尋產生的列舉

☐ 未描述任何行為

---

結束。
