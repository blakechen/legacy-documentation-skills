# 工作流程

## Phase 0

事實抽取（強制，最先執行）

Skill：fact-extraction

把原始碼解析成 factbase

解析出遞移的型別階層

對照編譯產出物驗證

### 關卡檢查

`docs/facts/types.psv`「必須」存在且非空。

`docs/verification-tier.txt`「必須」存在，並載明層級 A 或 B。

`docs/facts/bytecode-verification.md`「必須」存在。

其狀態「不得」為 `FAILED`。

`UNAVAILABLE` 是允許的，且「必須」帶入之後的每一份報告。

若關卡失敗 → 停止。沒有 factbase，任何文件產生 Skill 都不得執行。

「除非」該環境根本無法執行指令。那屬於層級 C：
流水線繼續進行，`docs/verification-tier.txt` 以 `tier|C` 手寫產生，
且之後的每一個階段都套用 shared/verification-tiers.md 中的層級 C 規則。
層級 C 是一項已宣告的限制，不是一道失敗的關卡。
沒有宣告就略過關卡，才是失敗的關卡。

---

## Phase 1

儲存庫探索

清冊盤點

技術

架構

自製框架偵測

驗證

---

## Phase 1.5

產出物列舉（關鍵）

Skill：artifact-enumeration

從 factbase 查詢「所有」交易／動作類別

查詢「所有」DB 物件類別

查詢「所有」servlet

依文件價值排序

### 關卡檢查

在繼續之前，輸出檔案「必須」已存在於磁碟上：

- `docs/enumeration/transaction-classes.txt`
- `docs/enumeration/db-object-classes.txt`
- `docs/enumeration/servlet-classes.txt`
- `docs/enumeration/enumeration-evidence.psv`
- `docs/enumeration/priority.txt`

每個檔案「必須」包含 `ClassName|Path` 條目（而不只是數量）。

db-object-classes.txt 帶有第三個欄位：`ClassName|Path|TargetTable`。

列舉報告「必須」記錄每一筆條目的繼承深度，
以及每一個懸空類別參照的處置結果。

若關卡失敗 → 停止。不得繼續。

---

## Phase 1.6

原型分群

Skill：archetype-clustering

收斂複製貼上家族

為每一個單元指派全深度或差異模式

---

## Phase 1.7

反思檢查

Skill：reflexion-check

向懂這個系統的人取得一份模組地圖

計算收斂、分歧與缺席

### 關卡檢查

每一項分歧與每一項缺席都有已記錄的處置。

若缺席是由遺漏類別造成，流水線退回 Phase 1.5。

---

## Phase 2

結構分析

模組

逐單元分析，依優先序

資料庫（來自 DB 物件列舉）

介面

驗證

---

## Phase 3

行為分析

領域變數（推導而得，在任何規則抽取之前）

業務規則（逐單元，套用領域變數判定測試）

循序圖（逐單元）

驗證

---

## Phase 4

文件產出

逐單元規格

系統規格

特徵化測試

落差分析（先陳舊度，再深度；兩者皆由工具判定）

驗證

---

出現下列情況時立即停止

事實抽取失敗

或

bytecode 判準回報 FAILED

或

清冊盤點失敗

或

架構無法確立

或

交易類別列舉找到零個類別。
