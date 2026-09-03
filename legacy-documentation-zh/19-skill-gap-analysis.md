---
name: gap-analysis

description: |
  對所有已產生的文件執行全面的品質審查。
  驗證每一份產出物的文件涵蓋率、一致性、
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

評估已產生的文件。

本 Skill 只執行品質保證。

套用 shared/mechanical-verification.md。

機械檢查由「執行程式」完成，不是靠閱讀。
`tools/verify/depth_checks.sh` 判定全部四項，
其原始碼端的事實取自 factbase。
本 Skill 執行它，並回報它的結果。

原始碼僅可在「解釋工具已經提出的發現」時閱讀。

詮釋邏輯、判斷正確性、或依原始碼撰寫文件，皆為「禁止」。

---

# 職責

本 Skill 應（SHALL）

- 驗證文件涵蓋率

- 驗證文件一致性

- 驗證可追溯性

- 驗證必要交付物

- 找出未被記錄的產出物

- 找出孤立文件

- 找出互相矛盾的文件

- 找出缺漏的引用

- 產生改善建議

本 Skill 不得（SHALL NOT）

- 產生新文件

- 分析業務邏輯（計算方法數與解析引用行號範圍不算分析）

- 修改既有文件

- 推測缺失的資訊

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

每一項發現都必須引用實際的文件。

絕不虛構缺失的資訊。

---

# 完成條件

涵蓋率已驗證。

一致性已驗證。

可追溯性已驗證。

改善清單已產生。

品質報告已完成。

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
- shared/enumeration-first.md
- shared/logic-depth.md

違反任一共用規則的文件即為「未完成」，
無論其內容多寡。

---

# 提示（Prompt）

# 落差分析（Gap Analysis）

---

# 目標

執行完整的文件品質審查。

審查文件。

原始碼「僅」能用於：計算主要單元類別中的 public method 數量，
以及確認引用的 `file:line` 能對應到所引述的文字。

絕不詮釋邏輯。絕不判斷正確性。絕不依原始碼撰寫文件。

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

涵蓋率審查

驗證

每個模組都已記錄。

每個交易類別都已記錄（與列舉清單比對）。

每個介接都已記錄。

每個資料庫物件都已記錄（與資料庫物件列舉比對）。

每條業務規則都已記錄。

每份循序圖都已記錄。

每份規格都已產生。

每個交易類別都有對應的逐交易規格。

回報缺漏的產出物。

回報列舉清單與已產生文件之間的數量落差。

檔案雖然存在、但未達深度完備者，在涵蓋率檢查中一律計為「缺漏」。見步驟 1b。

---

# 步驟 1a

過期檢查

套用 shared/incremental-update.md。

    sh tools/verify/staleness.sh \
        --repo <repo> --facts <repo>/docs/facts \
        --docs <repo>/docs/modules/transactions \
        --enumeration <repo>/docs/enumeration \
        --state <repo>/docs/model/unit-state.psv \
        --out <repo>/docs/gap-analysis/staleness-report.md

過期文件描述的是此後已經改動過的原始碼。
它是對現行系統的不實陳述，計為 MISSING，不是警告。

在深度檢查「之前」執行：過期文件通常也會在引文檢查上失敗，
而修補它的引文卻不重新產生，會得到一份半真的文件。

單元通過深度檢查後，以 `--record` 重跑一次，
讓下一輪知道它是對照什麼版本驗證的。

---

# 步驟 1b

深度審查

套用 shared/logic-depth.md。

針對 docs/modules/transactions/ 與 docs/specifications/transactions/ 中的
「每一個」檔案，依據「深度完備的定義」進行評估，並記錄一列：

| 單元 | 原始碼中的方法數 | Method 子章節數 | 流程 ≥3 步 | 虛擬碼區塊 | 附 file:line 的引用 | 欄位對應表 | 深度完備 |
|------|------------------|-----------------|------------|------------|---------------------|------------|----------|

檢查項目

1. `### Method:` 子章節數量等於原始碼類別中的 public method 數量。
   不相符 ＝ CRITICAL。

2. 每個子章節的處理流程至少有 3 個編號步驟，或那句「無分支方法」的固定文字。
   否則 ＝ CRITICAL。

3. 每個子章節都有非空的虛擬碼圍欄區塊。否則 ＝ CRITICAL。

4. 每個子章節都有至少一段符合 `path:line` 的引用，且該引用能對應到所引述的文字，
   或那句「無關鍵邏輯」的固定文字。否則 ＝ HIGH。

5. 每個子章節都有至少一列的欄位對應表格。否則 ＝ HIGH。

6. 規格的子章節不得短於模組的子章節。否則 ＝ HIGH。

回報

深度完備的單元數 ／ 列舉出的單元總數。

各項檢查未通過的單元完整清單。

深度完備率 ＝ 深度完備的單元數 ÷ 列舉檔案的行數。

若深度完備率低於 100%，即使每個檔案都存在，管線仍「未」完成。


執行檢查，不要靠閱讀來做：

    sh tools/verify/depth_checks.sh \
        --repo <repo> --facts <repo>/docs/facts \
        --docs <repo>/docs/modules/transactions \
        --enumeration <repo>/docs/enumeration \
        --out <repo>/docs/gap-analysis/depth-report.md \
        

exit 0 表示每個單元都深度完備。exit 1 表示至少一個失敗。
exit 3 表示列舉中有單元完全沒有文件。

回報工具計算出的深度完備率。沒有工具輸出而宣稱的比率不是比率。

工具提出的每一筆 FAIL，補上一行說明其成因。
這是本 Skill 唯一需要打開原始碼的理由。

通過的執行結果應報告為「與原始碼一致；意義未驗證」，
不得報告為「已驗證的文件」。見 shared/mechanical-verification.md。

用詞取決於 `docs/verification-tier.txt` 中的層級：

層級 A —— 「與原始碼一致；意義未驗證。」

層級 B —— 「與詞法讀取到的原始碼一致；未經獨立驗證。」

層級 C —— 檢查無法執行。應回報
`深度完備率：未量測（層級 C）`、已有文件的單元數，
以及「已對照原始碼檢查過的單元文件數：0」。
每一份報告開頭都要放 shared/verification-tiers.md 的
`VERIFICATION: NONE` 區塊。估算該比率是「禁止」的。

---

# 步驟 2

一致性審查

驗證

模組名稱一致。

API 名稱一致。

資料庫物件名稱一致。

業務規則編號唯一。

循序圖名稱一致。

規格引用有效。

回報不一致之處。

---

# 步驟 3

可追溯性審查

驗證

架構引用模組。

模組引用介接。

模組引用資料庫物件。

業務規則引用證據。

循序圖引用業務規則。

規格引用架構。

規格引用模組。

規格引用業務規則。

規格引用循序圖。

每一項關聯都應可追溯。

---

# 步驟 4

交叉引用驗證

檢查

模組 ↔ 資料庫

模組 ↔ API

模組 ↔ 循序圖

業務規則 ↔ 模組

業務規則 ↔ 資料庫

業務規則 ↔ 循序圖

API ↔ 循序圖

資料庫 ↔ 規格

架構 ↔ 規格

回報缺漏的引用。

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

引用

未知章節

回報不完整的文件。

---

# 步驟 6

孤立項目偵測

偵測

未被使用的模組文件

未被使用的循序圖

未被引用的業務規則

未被引用的 API

未被引用的資料庫物件

重複的文件

回報發現。

---

# 步驟 7

品質指標

產生

文件涵蓋率

引用涵蓋率

可追溯性涵蓋率

圖表涵蓋率

證據涵蓋率

文件完整性

---

# 步驟 8

產生 TODO

依優先度分級

Critical（嚴重）

High（高）

Medium（中）

Low（低）

每一項 TODO 都應包含

問題

原因

相關文件

建議行動

優先度

---

# 輸出規則

絕不虛構缺失的資訊。

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

# 列舉對文件的驗證（由經驗教訓新增）

落差分析 Skill「必須」執行下列數值檢查：

1. 計算 `docs/enumeration/transaction-classes.txt` 的行數 → 預期的交易文件數量。

2. 計算 `docs/modules/transactions/*.md` 的檔案數 → 實際的交易文件數量。

3. 計算 `docs/business-rules/transactions/*.md` 的檔案數 → 實際的業務規則文件數量。

4. 計算 `docs/sequence/transactions/*.md` 的檔案數 → 實際的循序圖文件數量。

5. 計算 `docs/specifications/transactions/*.md` 的檔案數 → 實際的規格文件數量。

6. 計算 `docs/enumeration/db-object-classes.txt` 的行數 → 預期的資料庫條目數量。

7. 計算 `docs/database/table-reference.md` 的條目數 → 實際的資料庫條目數量。

8. 檔案雖然存在、但未達深度完備者（步驟 1b），在檢查 2 與檢查 5 中一律計為「缺漏」。

若「任何一項」實際數量 < 預期數量，以 CRITICAL 落差回報，並附上確切數字。

涵蓋率與深度是兩道獨立的關卡。兩者都必須通過。

---

# 品質檢查清單

☐ 已驗證涵蓋率

☐ 已驗證一致性

☐ 已驗證可追溯性

☐ 已驗證交叉引用

☐ 已偵測孤立項目

☐ 已偵測重複文件

☐ 已產生品質指標

☐ TODO 已分級

☐ 已驗證列舉對文件的數量

☐ 深度已由執行 tools/verify/depth_checks.sh 驗證

☐ 深度完備率取自工具輸出，而非宣稱

☐ 工具每一筆 FAIL 皆已說明

☐ 已在深度檢查之前執行過期檢查

☐ 已通過的單元以 tools/verify/staleness.sh --record 記錄

☐ Reflexion 的 divergence 與 absence 皆已解決（shared/reflexion-model.md）

☐ 已從 docs/verification-tier.txt 讀取驗證層級並標示於報告

☐ 結果用詞符合該層級

☐ 層級 C：已放上 VERIFICATION: NONE 區塊，且未宣稱任何比率

☐ 無幻覺內容

---

結束。
