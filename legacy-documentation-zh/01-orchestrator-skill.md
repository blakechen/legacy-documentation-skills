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
  - fact-extraction
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
  - archetype-clustering
  - reflexion-check
  - gap-analysis

shared:
  - fact-layer
  - mechanical-verification
  - enumeration-first
  - iterative-depth
  - logic-depth
  - business-rule-criteria
  - prioritization
  - archetypes
  - reflexion-model
  - incremental-update
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

每個階段都套用 shared/fact-layer.md。

每個階段都套用 shared/mechanical-verification.md。

每個階段都套用 shared/enumeration-first.md。

每個階段都套用 shared/iterative-depth.md。

每個階段都套用 shared/logic-depth.md。

每個階段都套用 shared/custom-framework-recognition.md。

---

## 執行規則

執行順序

事實抽取（Fact Extraction，把原始碼剖析成 factbase；以 bytecode 驗證）

→
清冊盤點（Inventory）

→
技術探索（Technology Discovery）

→
架構探索（Architecture Discovery，含自訂框架偵測）

→
成品列舉（從 factbase 查詢；接著排定優先序）

→
原型分群（收斂複製貼上家族）

→
Reflexion 檢查（以人的模型對照 factbase 檢驗）

→
模組分析（逐模組「且」逐交易類別，依優先序）

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

## 關鍵：事實先於文件

本管線中沒有任何步驟會用「閱讀」去確立剖析器可以確立的事實。
見 shared/fact-layer.md。

協調器應在階段 1 之前驗證：

1. `docs/facts/types.psv` 存在，且型別數量大於零。

2. `docs/facts/bytecode-verification.md` 存在。

3. 其狀態為 `VERIFIED` 或 `UNAVAILABLE`。`FAILED` 封鎖整條管線。

4. `UNAVAILABLE` 狀態帶入後續每一份報告，
   且該次執行不得使用「已驗證」一詞。

協調器不得以「我讀過程式碼，找到 N 個類別」取代 factbase。

---

## 關鍵：交易層級的深度

在架構探索之後，協調器應：

1. 辨識出 dispatcher／router 類別及其路由機制。

2. 以對 factbase 的「查詢」列舉每一個交易／動作類別：
   基底類別之下的遞移閉包，加上僅由字串常值透過反射指名的類別。
   對 `extends <Base>` 做文字搜尋不構成列舉。

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
兩者皆由程式判定。見 shared/mechanical-verification.md。

在回報完成之前，協調器必須驗證：

1. `ls docs/modules/transactions/*.md | wc -l` 的結果等於
   `docs/enumeration/transaction-classes.txt` 的行數。

2. `tools/verify/depth_checks.sh` exit 0，
   且其報告顯示深度完備率 100%。
   協調器應「執行」該指令。沒有指令輸出而宣稱的比率不是比率。

3. `tools/verify/staleness.sh` exit 0：
   沒有任何文件描述的是此後已改動過的原始碼。

4. 每一筆 reflexion 的 divergence 與 absence 都有記錄的解決說明。

一個單元即使文件存在，只要未達深度完備，就「不算」完成。

產出 458 份淺薄的文件是一次「失敗」的執行，而非部分成功。

---

## 關鍵：規模化批次處理（由經驗教訓新增）

當列舉結果包含大量主要單元時（例如 400 個以上的交易類別）：

1. 協調器不得嘗試在單一回合內完成所有類別的文件。

2. 應改依「優先序」切分批次，來源為 `docs/enumeration/batches.txt`。
   見 shared/prioritization.md。依套件名稱切分是字典序，不是計畫。

3. 每個批次都要跑完「完整」管線（模組 → 業務規則 → 循序圖 → 規格），才進入下一批。

4. 於 `docs/gap-analysis/progress.md` 追蹤批次進度。

5. 系統層級的摘要文件在最後「產生一次」，不得用來取代逐單元文件。

6. 一個批次只有在其中每個單元都達到深度完備時才算完成。
   為了塞進批次而降低深度是「禁止」的。應該縮小的是批次大小。

7. 需要完整深度時的建議批次大小：每回合 5-10 個交易類別。

7a. 在第一批之前，先以 archetype-clustering 收斂複製貼上家族。
    一個 40 個近乎相同單元的家族，是「1 份完整深度文件 + 39 份差異文件」，
    不是 40 份完整文件，也不是 1 份摘要。見 shared/archetypes.md。

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

facts/（factbase、事實串流、bytecode 驗證報告）

overview/

architecture/

enumeration/（交易類別、資料庫物件類別、Servlet 主清單）

modules/（含逐交易文件）

database/（含由資料庫物件類別彙整的完整資料表對照）

integration/

business-rules/（逐交易規則）

sequence/（逐交易循序圖）

specifications/（逐交易規格）

characterization/（對照已記錄分支的可執行測試）

model/（unit-state.psv，供增量重跑使用）

gap-analysis/（含 progress.md、depth-report.md、staleness-report.md）

在回報完成前，先驗證所有必要文件都已存在。

驗證交易類別數量與已產生的文件數量相符。

執行 shared/quality-checklist.md 中的每一道關卡指令，並回報其結束狀態。
不得以宣稱代替執行。

結果報告為「與原始碼一致；意義未驗證」。
本管線驗證的是「文件與其所引用的程式碼相符」，
不驗證「指派給它們的業務意義是否正確」。
