---
name: archetype-clustering

description: |
  依結構相似度將主要單元分群為原型，
  使一整個複製貼上家族只需撰寫一次完整深度文件，
  其餘成員以差異文件記錄。

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

找出單元清單背後的「形狀」。

套用 shared/archetypes.md。

---

# 職責

本 Skill 應

- 依結構相似度將每一個被列舉的主要單元分群

- 為每一群選出代表單元

- 記錄每個成員與其代表單元的相似度

- 回報此分群可避免產出多少份完整深度文件

本 Skill 不得

- 假設同一群中的兩個單元行為完全相同

- 以代表單元的原始碼撰寫成員的文件

- 把分群當成不必閱讀成員的理由

---

# 輸入

docs/facts/types.psv

docs/enumeration/transaction-classes.txt

原始碼

---

# 交付項目

docs/enumeration/archetypes.txt

docs/enumeration/archetype-report.md

---

# Prompt

# 原型分群 Skill

## 步驟 1

分群。

    sh tools/factbase/archetypes.sh \
        --repo <repo> --facts <repo>/docs/facts \
        --enumeration <repo>/docs/enumeration

預設門檻 0.75。只有在說明理由的前提下才可調低，並記錄所使用的值。

## 步驟 2

閱讀報告。

對每一個多成員原型，實際打開其中兩個成員，
確認該分群反映的是真實的重複，而不是短檔案造成的假象。

記錄這項確認。沒人看過的分群只是猜測。

## 步驟 3

指派文件撰寫模式。

對每一個原型

- 代表單元：完整深度文件，滿足 shared/logic-depth.md 的四項元素
- 其他成員：依 shared/archetypes.md 撰寫差異文件
- 單一成員原型：一般的完整深度文件

把指派結果寫入 `docs/enumeration/archetype-report.md`。

## 步驟 4

把計畫交給協調器。

每個原型的代表單元應在其任何成員之前完成文件，
因為代表單元不存在時，差異文件沒有東西可以參照。

---

# 完成條件

`docs/enumeration/archetypes.txt` 存在，且被列舉的每個單元皆有一筆。

每個單元恰好被指派到一個原型。

每個多成員原型都有指名的代表單元。

每個多成員原型至少有兩個成員被實際打開，且分群已被確認。

---

# 被下列 Skill 依賴

module-analysis

business-rule-extraction

specification-generation

gap-analysis

---

# 品質檢查清單

☐ 已記錄門檻值

☐ 每個單元皆已指派

☐ 已指名代表單元

☐ 已逐群以閱讀確認分群

☐ 已逐單元指派文件撰寫模式

☐ 沒有任何成員僅憑代表單元的原始碼撰寫

結束。
