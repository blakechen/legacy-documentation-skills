---
name: fact-extraction

description: |
  在任何文件 Skill 執行之前，先為程式碼庫建立確定性的事實庫。
  剖析原始碼、解析型別階層、計算遞移閉包，
  並以編譯產物驗證結果。只產生事實，不描述任何東西。

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
---

# 目標

以「剖析」確立每一項事實，避免後續 Skill 改以「閱讀」來確立它們。

套用 shared/fact-layer.md。

本 Skill 執行程式。它自己不分析程式碼。

---

# 職責

本 Skill 應

- 對宣告的原始碼根目錄執行 Layer 1 抽取器

- 建立 factbase 及其遞移閉包資料表

- 在存在編譯產物時執行 bytecode oracle

- 回報名稱解析統計，以及每一個無法解析的父型別

- 記錄 commit 與每個檔案的內容雜湊值

- 當 oracle 與原始碼掃描不一致時，中止整條管線

本 Skill 不得

- 描述任何類別做什麼

- 指名任何業務概念

- 判定哪些類別是交易單元

- 詮釋任何東西

---

# 輸入

原始碼

編譯後的 class、jar、war（若存在）

docs/overview/repository-inventory.md

docs/overview/technology-stack.md

---

# 交付項目

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

確認原始碼根目錄。

閱讀 `docs/overview/project-structure.md`。

排除建置產物、相依套件與自動產生的原始碼。

記錄所使用的根目錄。

## 步驟 2

抽取。

    sh tools/factbase/extract_java.sh \
        --repo <repo> --out <repo>/docs/facts --source-root <root>

回報工具印出的各項計數。

回報 `manifest.psv` 中 `parse_errors` 的每一筆。
剖析錯誤是事實庫中的破洞，應逐一指名，不得以摘要帶過。

## 步驟 3

建立 factbase。

    sh tools/factbase/build_factbase.sh \
        --facts <repo>/docs/facts --facts <repo>/docs/facts

回報 `resolution_stats`。

`ambiguous` 計數大於零，表示有兩個型別共用同一個簡單名稱，
導致父型別參照無法解析。逐一指名。

`external` 計數屬正常：這是「基底類別隨 jar 出貨」的記錄方式。
它們成為 `EXTERNAL:<SimpleName>` 節點，閉包仍會經由它們形成。

## 步驟 4

以 bytecode 驗證。

    sh tools/factbase/verify_bytecode.sh \
        --repo <repo> --facts <repo>/docs/facts \
        --out <repo>/docs/facts/bytecode-verification.md

三種結果，三種都應原文回報：

`VERIFIED` — 編譯後的類別與原始碼掃描一致。

`FAILED` — bytecode 中存在掃描沒找到的類別，或父型別不一致。
中止。列舉不可信。回報不一致之處並解決後才可繼續。

`UNAVAILABLE` — 找不到編譯產物。可以繼續，
但後續每一份報告都應載明「本次列舉僅依賴詞法抽取」。
該次執行中，任何地方都不得出現「已驗證」字樣。

## 步驟 5

回報。

載明

- 掃描的原始碼根目錄
- 檔案、型別、方法、呼叫與常值的計數
- 剖析錯誤，逐一列出
- 名稱解析統計
- oracle 狀態，逐字引用

---

# 完成條件

`docs/facts/types.psv` 存在。

型別數量 > 0。

`docs/facts/bytecode-verification.md` 存在，且其狀態已被記錄。

oracle 狀態不是 `FAILED`。

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

☐ 已執行抽取器並回報計數

☐ 剖析錯誤逐一列出

☐ 已建立 factbase

☐ 已回報名稱解析統計

☐ 已指名 ambiguous 的解析結果

☐ 已執行 bytecode oracle，或已記錄其不存在

☐ oracle 狀態逐字引用

☐ 未描述任何類別

☐ 未指派任何業務意義

結束。
