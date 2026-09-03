---
name: reflexion-check

description: |
  將人所陳述的系統模型，與 factbase 中實際存在的關係相互比對，
  回報 convergence、divergence 與 absence。
  這是本技能組中唯一使用「程式碼本身不含之知識」的檢查。

version: 1.0.0

category: quality

author: Legacy Documentation Skills

tags:
  - reflexion
  - architecture
  - validation
  - top-down

dependencies:
  - fact-extraction
  - artifact-enumeration
  - architecture-discovery

shared:
  - reflexion-model
  - fact-layer
  - evidence-rules
  - quality-checklist

outputs:
  - docs/architecture/hypothesis-map.txt
  - docs/architecture/reflexion-report.md
---

# 目標

以一份獨立於回復結果而形成的認知，檢驗回復出來的架構。

套用 shared/reflexion-model.md。

---

# 職責

本 Skill 應

- 取得一份由懂這個系統的人所撰寫的假設圖

- 把 factbase 中的每一個型別映射到該模型上

- 計算 convergence、divergence 與 absence

- 要求每一筆 divergence 與 absence 都有解決說明

- 回報每一個未映射的型別

本 Skill 不得

- 以套件結構自動產生假設圖，再拿它來檢驗

- 把 divergence 當成工具錯誤而丟棄

- 在假設圖是由程式碼推導而來時，把乾淨的報告當成證據

---

# 輸入

docs/facts/types.psv

docs/architecture/hypothesis-map.txt

---

# 交付項目

docs/architecture/reflexion-report.md

---

# Prompt

# Reflexion 檢查 Skill

## 步驟 1

取得假設。

向懂這個系統的人索取一張模組圖：
十到十五個模組、他們預期模組之間的邊、以及每個模組的映射規則。

若找不到這樣的人，就在報告中載明，並把地圖作者記為分析者。
由讀過程式碼的人所寫的地圖是較弱的證據，報告應載明屬於哪一種情況。

「不得」以套件名稱自動產生地圖來取代之。
由程式碼推導出的地圖，不可能與程式碼不一致。

## 步驟 2

執行。

    sh tools/reflexion/reflexion.sh \
        --facts <repo>/docs/facts \
        --map <repo>/docs/architecture/hypothesis-map.txt \
        --out <repo>/docs/architecture/reflexion-report.md

## 步驟 3

解決每一筆 divergence。

逐筆記錄下列之一

- 一項關於此系統、現在被寫下來的未記載事實
- 一個缺陷：分層違規或抄捷徑，記入 gap analysis
- 映射規則錯誤，在地圖中修正，並註記該修正

## 步驟 4

解決每一筆 absence。

逐筆記錄下列之一

- 認知是錯的，以及為什麼
- 該關係經由此掃描看不到的機制存在：指名該機制
  （排程器、佇列、預存程序、檔案傳輸、維運腳本）
- 列舉漏掉了承載該關係的類別。
  這個結果屬於 CRITICAL 發現：回到 artifact-enumeration。

## 步驟 5

交代未映射的型別。

未映射代表模型沒有對應的模組，
或該型別不屬於模型所描述的系統。
逐型別或逐群決定屬於哪一種，並記錄該決定。

---

# 完成條件

`docs/architecture/reflexion-report.md` 存在。

每一筆 divergence 都有記錄的解決說明。

每一筆 absence 都有記錄的解決說明。

未映射型別均已交代。

報告載明假設圖由誰撰寫。

---

# 被下列 Skill 依賴

specification-generation

gap-analysis

---

# 品質檢查清單

☐ 已記錄假設圖作者

☐ 地圖非由套件結構推導而來

☐ 已執行工具並產生報告

☐ 每一筆 divergence 已解決

☐ 每一筆 absence 已解決

☐ 未映射型別已交代

☐ 凡 absence 指向缺漏類別者，已重新開啟列舉

結束。
