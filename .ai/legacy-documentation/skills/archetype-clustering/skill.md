---
name: archetype-clustering

description: |
  依結構相似度把主要單元分群成原型，
  使一整族複製貼上的單元只需以全深度記錄一次，
  其餘每個成員則以差異文件記錄。

version: 1.0.0

category: analysis

author: Legacy Documentation Skills

tags:
  - clone-detection
  - archetype
  - scale
  - reverse-engineering

dependencies:
  - fact-extraction
  - artifact-enumeration

shared:
  - archetypes
  - fact-layer
  - evidence-rules
  - quality-checklist

outputs:
  - docs/enumeration/archetypes.txt
  - docs/enumeration/archetype-report.md
---

# 目標

找出單元清單背後的那些「形狀」。

套用 shared/archetypes.md。

---

# 職責

本 Skill「應當」

- 依結構相似度將每一個被列舉的主要單元分群

- 為每一群選出一個代表單元

- 記錄每個成員與其代表單元的相似度

- 回報這次分群省下了多少份全深度文件

本 Skill「不得」

- 假設同一群中的兩個單元行為完全相同

- 用代表單元的原始碼去寫某個成員的文件

- 把分群當成不必閱讀成員原始碼的理由

---

# 輸入

docs/facts/types.psv

docs/facts/ancestor.psv

docs/enumeration/transaction-classes.txt

原始碼

---

# 交付物

docs/enumeration/archetypes.txt

docs/enumeration/archetype-report.md

---

# Prompt

# 原型分群 Skill

## 步驟 1

分群。

    sh tools/shell/factbase/archetypes.sh \
        --repo <repo> --facts <repo>/docs/facts \
        --enumeration <repo>/docs/enumeration

預設門檻 0.75。只有在提出明確理由時才調低，並記錄所使用的值。

## 步驟 2

閱讀報告。

對每一個多成員原型，打開其中兩個成員確認：
這個分群反映的是真實的重複，而不是短檔案造成的假象。

記錄這項確認。沒有人看過的群集只是一個猜測。

## 步驟 3

指派文件模式。

對每一個原型

- 代表單元：全深度文件，含 shared/logic-depth.md 的全部四項要素
- 其他成員：依 shared/archetypes.md 撰寫差異文件
- 單一成員原型：一般的全深度文件

把這項指派寫入 `docs/enumeration/archetype-report.md`。

## 步驟 4

把計畫交給 orchestrator。

每個原型的代表單元「應當」在其任何成員之前先被記錄，
因為在代表單元存在之前，差異文件沒有可參照的對象。

---

# 完成判準

`docs/enumeration/archetypes.txt` 存在，且每個被列舉的單元各有一筆條目。

每個單元都被指派到恰好一個原型。

每個多成員原型都有一個指名的代表單元。

每個多成員原型都至少有兩個成員被打開檢視過，且分群已獲確認。

---

# 被下列 Skill 依賴

module-analysis

business-rule-extraction

specification-generation

gap-analysis

---

# 品質檢查清單

☐ 已記錄門檻值

☐ 每個單元都已指派

☐ 已指名代表單元

☐ 每一群的分群結果都已透過閱讀確認

☐ 已為每個單元指派文件模式

☐ 沒有任何成員是僅憑代表單元的原始碼寫成的

結束。
