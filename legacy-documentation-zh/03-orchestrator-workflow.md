# 工作流程（Workflow）

## 階段 0

事實抽取（強制，最先執行）

Skill：fact-extraction

把原始碼剖析成 factbase

解析遞移型別階層

以編譯產物驗證

### 關卡檢查

`docs/facts/types.psv` 必須存在且含有型別。

`docs/facts/bytecode-verification.md` 必須存在。

其狀態不得為 `FAILED`。

`UNAVAILABLE` 可接受，且必須帶入後續每一份報告。

關卡未過 → 中止。沒有 factbase，任何文件 Skill 都不得執行。

---

## 階段 1

儲存庫探索

清冊

技術

架構

自訂框架偵測

驗證

---

## 階段 1.5

成品列舉（關鍵）

Skill：artifact-enumeration

從 factbase 查詢「所有」交易／動作類別

查詢「所有」資料庫物件類別

查詢「所有」servlet

依文件價值排序

### 關卡檢查

以下檔案必須先存在於磁碟才可繼續：

- `docs/enumeration/transaction-classes.txt`
- `docs/enumeration/db-object-classes.txt`
- `docs/enumeration/servlet-classes.txt`
- `docs/enumeration/enumeration-evidence.psv`
- `docs/enumeration/priority.txt`

每個檔案必須包含 `ClassName|Path` 條目（不能只有數量）。

db-object-classes.txt 帶第三個欄位：`ClassName|Path|TargetTable`。

列舉報告必須記錄每一筆條目的繼承深度，
以及每一筆指向不存在之物的類別參照的解決結果。

關卡未過 → 中止。不得繼續。

---

## 階段 1.6

原型分群

Skill：archetype-clustering

收斂複製貼上家族

為每個單元指派「完整深度」或「差異」模式

---

## 階段 1.7

Reflexion 檢查

Skill：reflexion-check

向懂這個系統的人取得模組圖

計算 convergence、divergence、absence

### 關卡檢查

每一筆 divergence 與每一筆 absence 都有記錄的解決說明。

若 absence 的成因是缺漏的類別，管線退回階段 1.5。

---

## 階段 2

結構分析

模組

逐單元分析，依優先序

資料庫（來自資料庫物件列舉）

介面

驗證

---

## 階段 3

行為分析

領域變數（在任何規則抽取之前先推導）

業務規則（逐單元，套用領域變數判定）

時序（逐單元）

驗證

---

## 階段 4

文件產生

逐單元規格

系統規格

Characterization 測試

差異分析（先過期檢查，再深度檢查；兩者皆由工具執行）

驗證

---

以下情況立即中止

事實抽取失敗

或

Bytecode oracle 回報 FAILED

或

清冊失敗

或

無法建立架構

或

交易類別列舉結果為零。
