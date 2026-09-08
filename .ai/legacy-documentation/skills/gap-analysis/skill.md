---
name: gap-analysis

description: |
  對所有產生的文件執行全面性品質審查。
  驗證每一份產出物的文件覆蓋率、一致性、
  完整性與可追溯性。

version: 1.0.0

category: quality

author: Legacy Documentation Skills

tags:
  - quality
  - review
  - coverage
  - consistency
  - traceability
  - documentation

dependencies:
  - inventory
  - fact-extraction
  - technology-discovery
  - architecture-discovery
  - artifact-enumeration
  - module-analysis
  - database-analysis
  - interface-analysis
  - business-rule-extraction
  - sequence-discovery
  - specification-generation

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
  - mechanical-verification
  - verification-tiers
  - incremental-update
  - fact-layer

outputs:
  - docs/gap-analysis/gap-report.md
  - docs/gap-analysis/coverage-report.md
  - docs/gap-analysis/consistency-report.md
  - docs/gap-analysis/traceability-report.md
  - docs/gap-analysis/depth-report.md
  - docs/gap-analysis/depth-findings.psv
  - docs/gap-analysis/staleness-report.md
  - docs/model/unit-state.psv
  - docs/gap-analysis/todo.md
---

# 目標

評估所產生的文件。

本 Skill 只做品質保證。

套用 shared/mechanical-verification.md。

機械式檢查是靠執行程式完成的，而不是靠閱讀。
`tools/shell/verify/depth_checks.sh` 判定全部四項檢查，
並以 factbase 作為原始碼側的事實來源。
本 Skill 執行它，並回報它所回傳的結果。

只有在需要解釋工具「已經提出」的某項發現時，才可閱讀原始碼。

詮釋邏輯、判斷正確性，或從原始碼撰寫文件，都是「被禁止」的。

---

# 職責

本 Skill「應當」

- 驗證文件覆蓋率

- 驗證文件一致性

- 驗證可追溯性

- 驗證必要交付物

- 找出未被記錄的產出物

- 找出孤兒文件

- 找出彼此衝突的文件

- 找出缺少的參照

- 產生改進建議

本 Skill「不得」

- 產生新文件

- 分析業務邏輯（計算方法數量與解析引用行號範圍不算分析）

- 修改既有文件

- 推測缺少的資訊

- 改寫規格

---

# 輸入

所有已產生的文件。

---

# 交付物

docs/gap-analysis/

gap-report.md

coverage-report.md

consistency-report.md

traceability-report.md

depth-report.md

todo.md

---

# 證據規則

每一項回報的問題都應參照

文件

章節

相關產出物

原因

絕不回報沒有依據的問題。

---

# 完成判準

覆蓋率已驗證。

一致性已驗證。

可追溯性已驗證。

已產生改進清單。

品質報告已完成。

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
- shared/enumeration-first.md
- shared/logic-depth.md

違反任一共用規則的文件即為「不完整」，
無論其內容如何。

---

# Prompt

# 落差分析

---

# 目標

執行完整的文件品質審查。

審查文件。

「只有」在計算主要單元類別的公開方法數量，
以及確認某段引用的 `file:line` 摘錄確實對應到所引文字時，才可閱讀原始碼。

絕不詮釋邏輯。絕不判斷正確性。絕不從原始碼撰寫文件。

---

# 審查範圍

審查

overview/

architecture/

modules/

database/

integration/

business-rules/

sequence/

specifications/

---

# 步驟 1

覆蓋率審查

驗證

每個模組都已記錄。

每個交易類別都已記錄（與列舉清單比對）。

每個介面都已記錄。

每個資料庫物件都已記錄（與 DB 物件列舉比對）。

每一條業務規則都已記錄。

每一張循序圖都已記錄。

每一份規格都已產生。

每個交易類別都已產生逐交易規格。

回報缺少的產出物。

回報列舉清單與已產生文件之間的數量不符。

檔案存在但未達深度完備者，就覆蓋率而言算「缺少」。
見步驟 1b。

---

# 步驟 1a

陳舊度審查

套用 shared/incremental-update.md。

    sh tools/shell/verify/staleness.sh \
        --repo <repo> --facts <repo>/docs/facts \
        --docs <repo>/docs/modules/transactions \
        --enumeration <repo>/docs/enumeration \
        --state <repo>/docs/model/unit-state.psv \
        --out <repo>/docs/gap-analysis/staleness-report.md

陳舊的文件描述的是其後已變動的原始碼。
它是對現行系統的不實宣稱，算「缺少」，而不是警告。

在深度審查「之前」先執行本步驟：陳舊的文件通常連摘錄檢查也一併失敗，
而修補它的摘錄而不重新產生它，只會得到一份半真半假的文件。

在某個單元通過深度檢查之後，加上 `--record` 再跑一次，
讓下一次執行知道它當時是對照什麼驗證的。

---

# 步驟 1b

深度審查

套用 shared/logic-depth.md。

執行檢查；不要靠閱讀來做這些檢查：

    sh tools/shell/verify/depth_checks.sh \
        --repo <repo> --facts <repo>/docs/facts \
        --docs <repo>/docs/modules/transactions \
        --enumeration <repo>/docs/enumeration \
        --out <repo>/docs/gap-analysis/depth-report.md

結束碼 0 代表每個單元都達到深度完備。結束碼 1 代表至少有一個失敗。
結束碼 3 代表列舉中有某個單元根本沒有文件。

回報工具計算出的深度完備率。
沒有工具輸出就陳述的比率，不是比率。

工具提出的每一項 FAIL，都補上一行說明指出成因。
那是本 Skill 唯一有理由打開原始碼的時機。

把通過的執行結果回報為「consistent with source; meaning not verified」。
不要回報成已驗證的文件。見
shared/mechanical-verification.md。

措辭取決於 `docs/verification-tier.txt` 中的層級：

層級 A —— 「Consistent with source; meaning not verified.」

層級 B —— 「Consistent with source as read lexically; not independently
verified.」

層級 C —— 檢查無法執行。回報
`Depth-Complete Rate: NOT MEASURED (Tier C)`、有文件的單元數，
以及 `Units whose document was checked against source: 0`。
每一份報告都要以 shared/verification-tiers.md 中的
`VERIFICATION: NONE` 區塊開頭。估算比率是「被禁止」的。

對 docs/modules/transactions/ 與 docs/specifications/transactions/ 中的
「每一個」檔案，評估「深度完備的定義」，並記錄一列：

| Unit | Methods in Source | Method Subsections | Flows >=3 Steps | Pseudocode Blocks | Excerpts with file:line | Field Mapping Tables | Depth-Complete |
|------|-------------------|--------------------|-----------------|-------------------|-------------------------|----------------------|----------------|

檢查項目

1. `### Method:` 小節數量等於原始碼類別中的公開方法數量。
   不符 = CRITICAL。

2. 每個小節的 Processing Flow 至少有 3 個編號步驟，
   或有那句明確的簡單方法字面句。否則 = CRITICAL。

3. 每個小節都有一個非空的虛擬碼 fenced 區塊。否則 = CRITICAL。

4. 每個小節至少有一段符合 `path:line` 的摘錄，且該摘錄能對應到所引文字，
   或有那句明確的無關鍵邏輯字面句。
   否則 = HIGH。

5. 每個小節都有一張至少一列的 Field Mapping 表。否則 = HIGH。

6. 規格中的小節不短於模組文件中的對應小節。
   否則 = HIGH。

回報

深度完備的單元數 ÷ 已列舉的單元總數。

未通過各項檢查的單元完整清單。

深度完備率 ＝ 深度完備單元數 ÷ 列舉檔行數。

若深度完備率低於 100%，即使每個檔案都存在，
流水線也「不算」完成。

---

# 步驟 2

一致性審查

驗證

模組名稱一致。

API 名稱一致。

資料庫物件名稱一致。

業務規則識別碼唯一。

循序圖名稱一致。

規格參照有效。

回報不一致之處。

---

# 步驟 3

可追溯性審查

驗證

架構參照模組。

模組參照介面。

模組參照資料庫物件。

業務規則參照證據。

循序圖參照業務規則。

規格參照架構。

規格參照模組。

規格參照業務規則。

規格參照循序圖。

每一項關聯都應可追溯。

---

# 步驟 4

交叉參照驗證

檢查

模組 → 資料庫

模組 → API

模組 → 循序圖

業務規則 → 模組

業務規則 → 資料庫

業務規則 → 循序圖

API → 循序圖

資料庫 → 規格

架構 → 規格

回報缺少的參照。

---

# 步驟 5

文件完整性

驗證必要章節。

範例

概觀

目的

職責

證據

相依關係

參考資料

Unknown 章節

回報不完整的文件。

---

# 步驟 6

孤兒偵測

偵測

未被使用的模組文件

未被使用的循序圖

未被參照的業務規則

未被參照的 API

未被參照的資料庫物件

重複的文件

回報發現。

---

# 步驟 7

品質指標

產生

文件覆蓋率

參照覆蓋率

可追溯性覆蓋率

圖表覆蓋率

證據覆蓋率

文件完整性

---

# 步驟 8

產生 TODO

排定優先序

Critical

High

Medium

Low

每一筆 TODO 都應包含

問題

原因

相關文件

建議動作

優先序

---

# 輸出規則

絕不憑空補上缺少的資訊。

絕不修改文件。

絕不改寫證據。

絕不推測未記錄的關聯。

只回報可觀察到的落差。

---

# 必要輸出

產生

docs/gap-analysis/gap-report.md

docs/gap-analysis/coverage-report.md

docs/gap-analysis/consistency-report.md

docs/gap-analysis/traceability-report.md

docs/gap-analysis/depth-report.md

docs/gap-analysis/todo.md

docs/gap-analysis/progress.md

---

# 列舉對文件的驗證（源自經驗教訓）

落差分析 Skill「必須」執行下列數值檢查：

1. 計算 `docs/enumeration/transaction-classes.txt` 的行數 → 預期的交易文件數。

2. 計算 `docs/modules/transactions/*.md` 的檔案數 → 實際的交易文件數。

3. 計算 `docs/business-rules/transactions/*.md` 的檔案數 → 實際的 BR 文件數。

4. 計算 `docs/sequence/transactions/*.md` 的檔案數 → 實際的循序文件數。

5. 計算 `docs/specifications/transactions/*.md` 的檔案數 → 實際的規格文件數。

6. 計算 `docs/enumeration/db-object-classes.txt` 的行數 → 預期的 DB 條目數。

7. 計算 `docs/database/table-reference.md` 的條目數 → 實際的 DB 條目數。

8. 檔案存在但未達深度完備者（步驟 1b），在檢查 2 與檢查 5 中算「缺少」。

若「任何」實際數量 < 預期數量，就以 CRITICAL 落差回報，並附上確切數字。

覆蓋率與深度是兩道分開的關卡。兩者都必須通過。

---

# 品質檢查清單

☐ 已驗證覆蓋率

☐ 已驗證一致性

☐ 已驗證可追溯性

☐ 已驗證交叉參照

☐ 已偵測孤兒

☐ 已偵測重複文件

☐ 已產生品質指標

☐ TODO 已排定優先序

☐ 已驗證列舉對文件的數量

☐ 深度已透過執行 tools/shell/verify/depth_checks.sh 驗證

☐ 深度完備率取自工具輸出，而非自行宣稱

☐ 工具的每一項 FAIL 都已說明

☐ 已在深度檢查之前檢查陳舊度

☐ 已驗證的單元已用 tools/shell/verify/staleness.sh --record 記錄

☐ 反思分歧與缺席都已處置（shared/reflexion-model.md）

☐ 已從 docs/verification-tier.txt 讀取驗證層級並蓋在報告上

☐ 結果措辭與層級相符

☐ 層級 C 時：VERIFICATION: NONE 區塊已存在，且未宣稱任何比率

☐ 沒有任何幻覺內容

---

結束。
