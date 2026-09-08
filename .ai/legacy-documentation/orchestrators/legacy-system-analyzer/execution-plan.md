# 執行計畫

## 前置條件

事實抽取已完成。

`docs/facts/types.psv` 存在且非空。

bytecode 判準狀態已記錄，且不是 `FAILED`。

`docs/verification-tier.txt` 已寫出，並載明層級 A 或 B。

若根本無法執行指令，層級即為 C，由人手動宣告，
並由 shared/verification-tiers.md 規範該次執行可以宣稱什麼。

清冊盤點已完成。

技術探索已完成。

架構探索已完成。

自製框架已偵測（若適用）。

---

## 產出物列舉（Phase 2 之前強制完成）

在架構探索之後，執行 `artifact-enumeration` Skill。

列舉「所有」交易／動作類別。

列舉「所有」DB 物件子類別。

列舉「所有」servlet。

本步驟「必須」在任何 Phase 2 Skill 開始之前完成。

### 關卡判準（源自經驗教訓）

在下列條件成立之前，列舉「不算」完成：

1. `docs/enumeration/transaction-classes.txt` 存在一個持久化檔案，每個類別一筆條目。

2. `docs/enumeration/db-object-classes.txt` 存在一個持久化檔案，每個 DB 物件一筆條目。

3. `docs/enumeration/servlet-classes.txt` 存在一個持久化檔案，每個 servlet 一筆條目。

4. 每個檔案都包含 `ClassName|Path`；DB 物件則為 `ClassName|Path|TargetTable`。

5. `docs/enumeration/enumeration-evidence.psv` 逐筆記錄
   繼承深度以及該條目是如何被發現的。

6. 數量是對照「BYTECODE 判準」確認的，而不是對照第二次文字搜尋。
   見 shared/enumeration-first.md。若不存在任何編譯產出物，
   報告要如實說明，且該次執行不得被描述為已驗證。

7. `docs/enumeration/priority.txt` 存在，使分批依價值進行，
   而不是依套件名稱。

若關卡未達成，下游 Skill「不得」繼續。

---

## 分批規則（源自經驗教訓）

對於列舉結果超過 50 個主要單元的儲存庫：

0. 先執行原型分群。一個複製貼上家族等於 1 份全深度文件加上若干差異文件，
   而不是 N 份完整文件。
   見 shared/archetypes.md。

1. orchestrator「應當」依「優先序」把工作分批，取自
   `docs/enumeration/batches.txt`。見 shared/prioritization.md。

2. 每一批「應當」先為其範圍完成「所有」下游 Skill
   （模組分析 → 業務規則 → 循序 → 規格），再進入下一批。

3. 進度「應當」記錄於 `docs/gap-analysis/progress.md`，
   格式為：`Batch N: [package] [X/Y classes] [status]`。

4. orchestrator「不得」以單一系統層級文件取代逐單元文件。

5. 若 AI 上下文視窗不足以容納一整批，該批「應當」再往下細分。

---

## 平行執行

在事實抽取之前，什麼都不執行。

允許

模組分析

資料庫分析

介面分析

可在下列條件之後各自獨立執行

架構探索「且」產出物列舉「且」原型分群。

反思檢查可與 Phase 2 平行執行，
但其分歧與缺席「必須」在規格產生之前解決。

---

業務規則抽取

必須等到

模組

資料庫

介面

完成之後。

必須走訪「每一個」交易類別。

---

循序探索

必須等到

業務規則完成之後。

必須為每個主要交易產生一份循序圖。

---

逐交易規格產生

必須等到

所有文件產生 Skill 完成之後。

必須為每個交易類別產生一份規格。

---

系統規格產生

必須等到

逐交易規格完成之後。

---

特徵化測試產生

必須等到

逐交易規格完成之後。

---

落差分析

永遠最後執行。

必須驗證逐交易文件數量與列舉數量相符。

必須執行 tools/shell/verify/staleness.sh，接著執行 tools/shell/verify/depth_checks.sh，
並回報它們的結束狀態碼。「宣稱」不等於「驗證」。
