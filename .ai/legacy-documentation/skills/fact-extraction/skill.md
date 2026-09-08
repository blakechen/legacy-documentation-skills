---
name: fact-extraction

description: |
  在任何文件產生 Skill 執行之前，先為儲存庫建立具決定性的事實庫。
  解析原始碼、解析型別階層、計算遞移閉包，
  並對照編譯產出物驗證結果。
  只產出事實；不描述任何東西。

version: 1.0.0

category: discovery

author: Legacy Documentation Skills

tags:
  - factbase
  - parsing
  - deterministic
  - verification
  - reverse-engineering

supported-languages:
  - Java

dependencies:
  - inventory

shared:
  - fact-layer
  - verification-tiers
  - mechanical-verification
  - evidence-rules
  - confidence-scoring
  - quality-checklist

outputs:
  - docs/facts/files.psv
  - docs/facts/types.psv
  - docs/facts/methods.psv
  - docs/facts/calls.psv
  - docs/facts/literals.psv
  - docs/facts/hashes.psv
  - docs/facts/supertype.psv
  - docs/facts/ancestor.psv
  - docs/facts/calls-resolved.psv
  - docs/facts/resolution.psv
  - docs/facts/manifest.psv
  - docs/facts/bytecode-verification.md
  - docs/verification-tier.txt
---

# 目標

以解析的方式確立每一項事實，否則後續 Skill 就只能靠閱讀去確立它們。

套用 shared/fact-layer.md。

本 Skill 執行的是程式。它自己不分析程式碼。

---

# 職責

本 Skill「應當」

- 對已宣告的原始碼根目錄執行 Layer 1 抽取器

- 建立 factbase 及其遞移閉包表格

- 當存在編譯產出物時，執行 bytecode 判準

- 回報解析統計數據以及每一個未解析的父型別

- 記錄 commit 與逐檔案的內容雜湊值

- 當判準與原始碼掃描不一致時，停止流水線

本 Skill「不得」

- 描述任何類別在做什麼

- 為業務概念命名

- 判定哪些類別是交易單元

- 詮釋任何東西

---

# 輸入

原始碼

編譯後的 class、jar、war（若有）

docs/overview/repository-inventory.md

docs/overview/technology-stack.md

---

# 交付物

docs/facts/

files.psv

types.psv

methods.psv

calls.psv

literals.psv

hashes.psv

supertype.psv

ancestor.psv

calls-resolved.psv

resolution.psv

manifest.psv

bytecode-verification.md

---

# Prompt

# 事實抽取 Skill

## 步驟 1

指出原始碼根目錄。

閱讀 `docs/overview/project-structure.md`。

排除建置輸出、相依套件與產生的原始碼。

記錄所使用的根目錄。

## 步驟 2

抽取。

    sh tools/shell/factbase/extract_java.sh \
        --repo <repo> --out <repo>/docs/facts --source-root <root>

回報工具印出的各項數量。

回報 `manifest.psv` 中 `parse_errors` 底下的每一筆條目。
解析錯誤是 factbase 中的破洞，「應當」逐一指名，不得摘要帶過。

## 步驟 3

建立 factbase。

    sh tools/shell/factbase/build_factbase.sh \
        --facts <repo>/docs/facts --facts <repo>/docs/facts

回報 `resolution_stats`。

`ambiguous` 計數大於零，表示有兩個型別共用同一個簡單名稱，
導致某個父型別參照無法解析。請指名它們。

`external` 計數屬正常：那正是「基底類別隨 jar 出貨」的記錄方式。
它們會成為 `EXTERNAL:<SimpleName>` 節點，而閉包仍會經由它們形成。

## 步驟 4

對照 bytecode 驗證。

    sh tools/shell/factbase/verify_bytecode.sh \
        --repo <repo> --facts <repo>/docs/facts \
        --out <repo>/docs/facts/bytecode-verification.md

三種結果，且三者都「應當」照字面回報：

`VERIFIED` —— 編譯後的 class 與原始碼掃描一致。

`FAILED` —— bytecode 中存在掃描沒找到的類別，或某個父型別不一致。
停止。列舉不可信。回報這些不一致並解決之後才能繼續。

`UNAVAILABLE` —— 找不到任何編譯產出物。可以繼續，
但之後的每一份報告「應當」聲明該列舉僅立基於詞法抽取。
該次執行的任何地方都不要寫「verified」這個字。

## 步驟 5

宣告驗證層級。

    sh tools/shell/verification_tier.sh \
        --facts <repo>/docs/facts --out <repo>/docs/verification-tier.txt

套用 shared/verification-tiers.md。

`A` —— 已建立 factbase，且判準將其驗證為 VERIFIED。

`B` —— 已建立 factbase，但沒有可供比對的編譯產出物。

`BLOCKED` —— 判準與掃描不一致。停止。

若本 Skill 根本無法執行 —— 該環境無法執行指令 ——
則該次執行屬於層級 C。手寫 `docs/verification-tier.txt`，
內容為 `tier|C` 以及一個指明具體限制的 `reason`，
並把層級 C 的規則帶進之後的每一個 Skill。

該層級會被引用於每一份產生文件的中繼資料區塊中。

---

## 步驟 6

回報。

說明

- 掃描過的原始碼根目錄
- 檔案、型別、方法、呼叫與常值的數量
- 解析錯誤，逐一列出
- 解析統計數據
- 判準狀態，逐字引用

---

# 完成判準

`docs/facts/types.psv` 存在且非空。

`docs/facts/ancestor.psv` 存在。

`docs/facts/bytecode-verification.md` 存在，且其狀態已記錄。

判準狀態不是 `FAILED`。

`docs/verification-tier.txt` 存在，並載明層級 A 或 B。

---

# 被下列 Skill 依賴

artifact-enumeration

architecture-discovery

module-analysis

database-analysis

business-rule-extraction

gap-analysis

---

# 品質檢查清單

☐ 已記錄原始碼根目錄

☐ 已執行抽取器並回報數量

☐ 解析錯誤已逐項列出

☐ 已建立 factbase

☐ 已回報解析統計數據

☐ 已指名含糊的解析結果

☐ 已執行 bytecode 判準，或已記錄其缺席

☐ 已逐字引用判準狀態

☐ 已宣告並持久化驗證層級

☐ 未描述任何類別

☐ 未指派任何業務意義

結束。
