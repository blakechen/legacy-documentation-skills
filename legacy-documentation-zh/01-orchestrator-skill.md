---
name: legacy-system-analyzer

description: |
  舊系統逆向工程的主協調器。
  統籌每一個文件產生 Skill，並管理執行順序、
  相依關係、驗證與最終交付物。

version: 1.0.0

category: orchestrator

author: Legacy Documentation Skills

outputs:
  - docs/

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
  - specification-generation
  - gap-analysis

shared:
  - enumeration-first
  - iterative-depth
  - logic-depth
  - custom-framework-recognition
---

# 目標

統籌完整的文件產生管線。

絕不直接執行程式碼庫分析。

將每一項任務都委派給專責的 Skill。

---

# 職責

本 Skill 應（SHALL）

- 依相依順序執行各 Skill

- 驗證前置條件是否完成

- 驗證已產生的輸出

- 在發生嚴重失敗時停止執行

- 在允許的情況下平行執行彼此獨立的 Skill

- 彙整最終文件

- 執行最終品質審查

本 Skill 不得（SHALL NOT）

- 分析原始碼

- 產生規格

- 萃取業務規則

- 取代下游 Skill

---

# 完成條件

管線已完成。

所有輸出皆已產生。

落差分析已完成。

最終文件已通過驗證。

---

# 提示（Prompt）

# 舊系統分析器（Legacy System Analyzer）

## 目標

為一個未知的舊有程式碼庫產出完整文件。

絕不跳過前置 Skill。

永遠遵循相依順序。

每個階段都套用 shared/enumeration-first.md。

每個階段都套用 shared/iterative-depth.md。

每個階段都套用 shared/logic-depth.md。

每個階段都套用 shared/custom-framework-recognition.md。

---

## 執行規則

執行順序

清冊盤點（Inventory）

→
技術探索（Technology Discovery）

→
架構探索（Architecture Discovery，含自訂框架偵測）

→
成品列舉（交易／動作類別、資料庫物件類別、Servlet）

→
模組分析（逐模組「且」逐交易類別）

→
資料庫分析（列舉「所有」資料庫物件類別）

→
介接分析（Interface Analysis）

→
業務規則萃取（逐一走過「每一個」交易類別）

→
循序探索（每個主要交易一份循序圖）

→
規格產生（每個交易類別一份規格）

→
落差分析（Gap Analysis）

---

## 關鍵：交易層級的深度

在架構探索之後，協調器應：

1. 辨識出 dispatcher／router 類別及其路由機制。

2. 列舉「每一個」被 dispatcher 引用、或繼承自交易基底類別的交易／動作類別。

3. 將這份完整清單交給模組分析、業務規則萃取、循序探索與規格產生。

4. 每個下游 Skill 都應處理清單中的「每一個」類別，而非抽樣。

---

## 關鍵：資料庫物件列舉

在辨識出資料庫物件基底類別之後：

1. 列舉「每一個」子類別。

2. 從每個子類別中擷取資料表名稱與欄位定義。

3. 將完整清單交給資料庫分析。

---

## 關鍵：列舉關卡（由經驗教訓新增）

成品列舉由 `artifact-enumeration` Skill 負責。

協調器只委派列舉工作並驗證其結果，不自行列舉。

協調器在進入階段 2「之前」必須驗證：

1. `docs/enumeration/transaction-classes.txt` 存在且行數 > 0。

2. `docs/enumeration/db-object-classes.txt` 存在且行數 > 0。

3. `docs/enumeration/servlet-classes.txt` 存在且行數 > 0。

若這些檔案不存在，階段 2 即為「阻擋」狀態。

協調器不得以「我辨識出大約 N 個類別」來取代實際持久化的檔案。概略數量「不算」列舉。

---

## 關鍵：深度關卡

涵蓋率與深度是兩道獨立的關卡。兩者皆為必要。

在回報完成之前，協調器必須驗證：

1. `ls docs/modules/transactions/*.md | wc -l` 的結果等於
   `docs/enumeration/transaction-classes.txt` 的行數。

2. `docs/gap-analysis/depth-report.md` 存在，且回報的「深度完備率」為 100%。

一個單元即使文件存在，只要未達深度完備，就「不算」完成。

產出 458 份淺薄的文件是一次「失敗」的執行，而非部分成功。

---

## 關鍵：規模化批次處理（由經驗教訓新增）

當列舉結果包含大量主要單元時（例如 400 個以上的交易類別）：

1. 協調器不得嘗試在單一回合內完成所有類別的文件。

2. 而應依套件／模組群組切分為批次。

3. 每個批次都要跑完「完整」管線（模組 → 業務規則 → 循序圖 → 規格），才進入下一批。

4. 於 `docs/gap-analysis/progress.md` 追蹤批次進度。

5. 系統層級的摘要文件在最後「產生一次」，不得用來取代逐單元文件。

6. 一個批次只有在其中每個單元都達到深度完備時才算完成。
   為了塞進批次而降低深度是「禁止」的。應該縮小的是批次大小。

7. 需要完整深度時的建議批次大小：每回合 5-10 個交易類別。

8. `docs/gap-analysis/progress.md` 應逐批記錄：

   `batch N | package | units in batch | depth-complete | remaining | date`

   以及累計總計 `X / Total units depth-complete`。

9. 下一回合從第一個尚未標記為深度完備的單元繼續。

---

每個階段都要先驗證再繼續。

若某個階段失敗，

回報

- 失敗的 Skill
- 原因
- 缺少的證據
- 被阻擋的下游 Skill

發生嚴重失敗時停止。

---

## 最終交付物

產生

overview/

architecture/

enumeration/（交易類別、資料庫物件類別、Servlet 主清單）

modules/（含逐交易文件）

database/（含由資料庫物件類別彙整的完整資料表對照）

integration/

business-rules/（逐交易規則）

sequence/（逐交易循序圖）

specifications/（逐交易規格）

gap-analysis/（含 progress.md 與 depth-report.md）

在回報完成前，先驗證所有必要文件都已存在。

驗證交易類別數量與已產生的文件數量相符。
