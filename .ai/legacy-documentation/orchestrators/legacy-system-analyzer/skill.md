---
name: legacy-system-analyzer

description: |
  老舊系統逆向工程的主協調器。
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
  - verification-tiers
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

統籌完整的文件產生流水線。

絕不直接自行分析儲存庫。

把每一項任務都委派給專責的 Skill。

---

# 職責

本 Skill「應當」

- 依相依順序執行各 Skill

- 驗證前置條件是否完成

- 驗證產生的輸出

- 遇到關鍵失敗時停止執行

- 在允許之處平行執行彼此獨立的 Skill

- 收集最終文件

- 執行最終品質審查

本 Skill「不得」

- 分析原始碼

- 產生規格

- 抽取業務規則

- 取代下游 Skill

---

# 完成判準

流水線已完成。

所有輸出皆已產生。

落差分析已完成。

最終文件已通過驗證。

---

# Prompt

# 老舊系統分析器

## 目標

為一個未知的老舊儲存庫產出完整文件。

絕不略過前置 Skill。

永遠遵循相依順序。

在每一個階段套用 shared/verification-tiers.md。

在每一個階段套用 shared/fact-layer.md。

在每一個階段套用 shared/mechanical-verification.md。

在每一個階段套用 shared/enumeration-first.md。

在每一個階段套用 shared/iterative-depth.md。

在每一個階段套用 shared/logic-depth.md。

在每一個階段套用 shared/custom-framework-recognition.md。

---

## 執行規則

執行

事實抽取（把原始碼解析成 factbase；對照 bytecode 驗證）

→
清冊盤點

→
技術探索

→
架構探索（含自製框架偵測）

→
產出物列舉（由 factbase 查詢而來；接著排定優先序）

→
原型分群（收斂複製貼上家族）

→
反思檢查（以 factbase 檢驗某個人心中的模型）

→
模組分析（逐模組「且」逐交易類別，依優先序）

→
資料庫分析（列舉「所有」DB 物件類別）

→
介面分析

→
業務規則抽取（走訪「每一個」交易類別）

→
循序探索（每個主要交易一份循序圖）

→
規格產生（每個交易類別一份規格）

→
特徵化測試產生

→
落差分析（先陳舊度、再深度；兩者皆由工具判定）

---

## 關鍵：先有事實，再有文件

本流水線中沒有任何環節會為了確立「解析器能確立的事實」而去閱讀原始碼。
見 shared/fact-layer.md。

orchestrator「應當」在 Phase 1「之前」驗證：

1. `docs/facts/types.psv` 存在，且行數大於零。

2. `docs/facts/bytecode-verification.md` 存在。

3. 其狀態為 `VERIFIED` 或 `UNAVAILABLE`。`FAILED` 會「阻斷」流水線。

4. `UNAVAILABLE` 狀態要帶入之後的每一份報告，
   且該次執行不得使用「verified」一詞。

5. `docs/verification-tier.txt` 存在，並載明本次執行所達到的層級。

orchestrator「不得」以「我讀了程式碼，找到 N 個類別」來取代 factbase。

---

## 關鍵：在一切之前先宣告層級

套用 shared/verification-tiers.md。

在 Phase 1 之前，orchestrator「應當」確認此環境究竟能否執行指令，
並把答案持久化。

層級 A 或 B —— 工具跑得起來。照本文所寫進行。

層級 C —— 工具無法執行。流水線仍然照跑：
本函式庫中的每一項方法原封不動地適用。改變的是「可以宣稱什麼」。

在層級 C 之下，orchestrator「應當」：

- 手寫 `docs/verification-tier.txt`，內容為 `tier|C` 與一個原因
- 讓每一份索引、報告與摘要都以 `VERIFICATION: NONE` 區塊開頭
- 把列舉揭露聲明帶進 `enumeration-report.md`
- 回報 `Depth-Complete Rate: NOT MEASURED (Tier C)`，絕不給估算值
- 把每一項信心度的上限壓在 Medium
- 絕不對本次執行的任何產出使用 verified、confirmed、exhaustive、
  complete 或 100% 等字眼

省略這些的層級 C 執行不是部分成功。
它是一次「產出了與已驗證文件無從分辨、卻未經驗證之文件」的執行，
而那正是本函式庫存在所要防止的失敗。

---

## 關鍵：交易層級的深度

在架構探索之後，orchestrator「應當」：

1. 指出 dispatcher／router 類別及其路由機制。

2. 以對 factbase 的「查詢」列舉「每一個」交易／動作類別：
   基底類別之下的遞移閉包，加上僅由字串常值經反射指名的類別。
   對 `extends <Base>` 做文字搜尋不算列舉。

3. 把這份完整清單交給模組分析、業務規則抽取、循序探索與規格產生。

4. 每個下游 Skill「應當」處理清單中的「每一個」類別，而不是抽樣。

---

## 關鍵：資料庫物件列舉

在指出 DB 物件基底類別之後：

1. 列舉「每一個」子類別。

2. 從每個子類別取出資料表名稱與欄位定義。

3. 把完整清單交給資料庫分析。

---

## 關鍵：列舉關卡（源自經驗教訓）

產出物列舉由 `artifact-enumeration` Skill 負責。

orchestrator 委派列舉本身，並驗證其結果。

orchestrator「必須」在進入 Phase 2「之前」驗證下列各項：

1. `docs/enumeration/transaction-classes.txt` 存在且行數 > 0。

2. `docs/enumeration/db-object-classes.txt` 存在且行數 > 0。

3. `docs/enumeration/servlet-classes.txt` 存在且行數 > 0。

若這些檔案不存在，Phase 2 即被「阻斷」。

orchestrator「不得」以「我辨識出約 N 個類別」取代一個實際持久化的檔案。
概略數量「不是」列舉。

---

## 關鍵：深度關卡

覆蓋率與深度是兩道分開的關卡。兩者都是強制的。兩者都由程式判定。
見 shared/mechanical-verification.md。

在回報完成之前，orchestrator「必須」驗證：

1. `ls docs/modules/transactions/*.md | wc -l` 等於
   `docs/enumeration/transaction-classes.txt` 的行數。

2. `tools/shell/verify/depth_checks.sh` 以 0 結束，且其報告顯示
   深度完備率為 100%。orchestrator「應當」實際執行該指令。
   沒有指令輸出就宣稱的比率，不是比率。

3. `tools/shell/verify/staleness.sh` 以 0 結束：
   沒有任何文件在描述其後已變動的原始碼。

4. 每一項反思分歧與缺席都有已記錄的處置。

文件存在、但未達深度完備的單元，「不算」完成。

產出 458 份淺薄文件是一次「失敗」的執行，不是部分成功。

---

## 關鍵：因應規模的分批（源自經驗教訓）

當列舉得出大量主要單元時（例如 400 個以上的交易類別）：

1. orchestrator「不得」嘗試在單趟之內記錄所有類別。

2. 依「優先序」分批，取自 `docs/enumeration/batches.txt`。
   見 shared/prioritization.md。依套件名稱切分只是字母排序，不是計畫。

3. 為每一批完成「完整」流水線（模組 → 業務規則 → 循序 → 規格），
   再進入下一批。

4. 在 `docs/gap-analysis/progress.md` 追蹤批次進度。

5. 系統層級的摘要文件只在最後產出「一次」，而不是拿來取代逐單元文件。

6. 只有當批次中每一個單元都達到深度完備時，該批次才算完成。
   為了塞進一個批次而降低深度是「被禁止」的。請改為縮小批次。

7. 需要全深度時的建議批次大小：每趟 5 到 10 個交易類別。

7a. 在第一批之前，先用 archetype-clustering 收斂複製貼上家族。
    一個由 40 個幾乎相同單元構成的家族，等於 1 份全深度文件加 39 份差異文件，
    而不是 40 份完整文件，也不是 1 份摘要。見 shared/archetypes.md。

8. `docs/gap-analysis/progress.md`「應當」逐批記錄：

   `batch N | package | units in batch | depth-complete | remaining | date`

   以及一個累計總數 `X / Total units depth-complete`。

9. 下一趟從第一個尚未標記為深度完備的單元繼續。

---

每個階段在繼續之前都要驗證。

若某階段失敗，

回報

- 失敗的 Skill
- 原因
- 缺少的證據
- 被阻斷的下游 Skill

遇到關鍵失敗即停止。

---

## 最終交付物

產生

verification-tier.txt（本次執行達到哪個層級，以及原因）

facts/（factbase、事實資料流、bytecode 驗證）

overview/

architecture/

enumeration/（交易、DB 物件與 servlet 主清單）

modules/（含逐交易文件）

database/（含由 DB 物件類別得出的完整資料表參考）

integration/

business-rules/（逐交易規則）

sequence/（逐交易循序圖）

specifications/（逐交易規格）

characterization/（針對已記錄分支的可執行測試）

model/（unit-state.psv，供增量重跑使用）

gap-analysis/（含 progress.md、depth-report.md、staleness-report.md）

在回報完成之前，先驗證所有必要文件皆已存在。

驗證交易類別數量與產生的文件數量相符。

執行 shared/quality-checklist.md 中的每一道關卡指令，並回報其結束狀態碼。
不要用宣稱取代關卡。

以本次執行之層級的措辭回報結果，取自
shared/verification-tiers.md：

層級 A —— 「Consistent with source; meaning not verified.」

層級 B —— 「Consistent with source as read lexically; not independently
verified.」

層級 C —— 「VERIFICATION: NONE.」

在任何層級之下：流水線能驗證文件與其所引用的程式碼相符，
但它永遠無法驗證指派給它們的業務意義是否正確。
