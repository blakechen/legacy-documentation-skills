# 執行計畫（Execution Plan）

## 前置條件

事實抽取已完成。

`docs/facts/types.psv` 存在。

Bytecode oracle 狀態已記錄，且不是 `FAILED`。

清冊盤點已完成。

技術探索已完成。

架構探索已完成。

已偵測自訂框架（若適用）。

---

## 產出物列舉（進入階段 2 前為必要步驟）

本階段由 `artifact-enumeration` Skill 執行。

在架構探索之後：

列舉「所有」交易／動作類別。

列舉「所有」資料庫物件子類別。

列舉「所有」servlet。

此步驟必須在任何階段 2 的 Skill 開始前完成。

### 關卡條件（由經驗教訓新增）

列舉在滿足以下條件前都不算完成：

1. `docs/enumeration/transaction-classes.txt` 實體檔案存在，且每個類別一筆條目。

2. `docs/enumeration/db-object-classes.txt` 實體檔案存在，且每個資料庫物件一筆條目。

3. `docs/enumeration/servlet-classes.txt` 實體檔案存在，且每個 servlet 一筆條目。

4. 每個檔案都包含 `ClassName|Path`；資料庫物件為 `ClassName|Path|TargetTable`。

5. `docs/enumeration/enumeration-evidence.psv` 逐筆記錄了
   繼承深度與發現方式。

6. 數量已對照 **BYTECODE ORACLE** 確認，而不是對照第二次文字搜尋。
   見 shared/enumeration-first.md。
   若不存在編譯產物，報告載明此事，且該次執行不得描述為已驗證。

7. `docs/enumeration/priority.txt` 存在，
   使批次依價值而非依套件名稱切分。

若關卡未達成，下游 Skill 不得繼續執行。

---

## 批次規則（由經驗教訓新增）

當程式碼庫列舉出的主要單元超過 50 個時：

0. 先執行原型分群。一個複製貼上家族是
   「1 份完整深度文件 + 若干差異文件」，而不是 N 份完整文件。
   見 shared/archetypes.md。

1. 協調器應依「優先序」切分批次，來源為 `docs/enumeration/batches.txt`。
   見 shared/prioritization.md。

2. 每個批次都應在其範圍內完成「所有」下游 Skill（模組分析 → 業務規則 → 循序圖 → 規格），才可進入下一批次。

3. 進度應記錄於 `docs/gap-analysis/progress.md`，格式為：`Batch N: [package] [X/Y classes] [status]`。

4. 協調器不得以單一份系統層級文件取代逐單元文件。

5. 若 AI 的上下文視窗不足以處理一整個批次，該批次應再進一步細分。

---

## 平行執行

在事實抽取之前，什麼都不執行。

允許

模組分析

資料庫分析

介接分析

可在「架構探索」、「產出物列舉」與「原型分群」完成後獨立執行。

Reflexion 檢查可與階段 2 平行執行，
但其 divergence 與 absence 必須在規格產生之前解決。

---

業務規則萃取

必須等待

模組

資料庫

介接

完成。

必須逐一走過「每一個」交易類別。

---

循序探索

必須等待

業務規則完成。

必須為每個主要交易產生一份循序圖。

---

逐交易規格產生

必須等待

所有文件類 Skill 完成。

必須為每個交易類別產生一份規格。

---

系統規格產生

必須等待

逐交易規格完成。

---

Characterization 測試產生

必須等待

逐交易規格完成。

---

落差分析

永遠最後執行。

必須驗證逐交易文件數量與列舉數量相符。

必須執行 tools/verify/staleness.sh，接著執行
tools/verify/depth_checks.sh，並回報兩者的結束狀態。
宣稱不等於驗證。
