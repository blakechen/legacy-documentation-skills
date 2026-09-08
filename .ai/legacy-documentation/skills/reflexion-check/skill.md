---
name: reflexion-check

description: |
  把某個人所陳述的系統模型，與 factbase 中實際存在的關聯相比較，
  並回報收斂、分歧與缺席。
  這是本函式庫中唯一使用「程式碼裡沒有的知識」的檢查。

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

以一個獨立於還原結果之外所形成的信念，來檢驗還原出的架構。

套用 shared/reflexion-model.md。

---

# 職責

本 Skill「應當」

- 取得一份由懂這個系統的人所寫的假說地圖

- 把 factbase 中的每一個型別對應到該模型上

- 計算收斂、分歧與缺席

- 要求每一項分歧與每一項缺席都有處置

- 回報每一個未對應的型別

本 Skill「不得」

- 先從套件結構產生假說地圖，再拿它來檢驗

- 把分歧當成工具錯誤而丟棄

- 在地圖是從程式碼推導而來時，把乾淨的報告當成證據

---

# 輸入

docs/facts/types.psv

docs/facts/ancestor.psv

docs/architecture/hypothesis-map.txt

---

# 交付物

docs/architecture/reflexion-report.md

---

# Prompt

# 反思檢查 Skill

## 步驟 1

取得假說。

向懂這個系統的人索取一份模組地圖。十到十五個模組、
他們預期模組之間存在的邊，以及每個模組一條對應規則。

若找不到這樣的人，就在報告中如實說明，
並把地圖作者記錄為分析師本人。由讀過程式碼的人所寫的地圖是較弱的證據，
而報告「應當」說明適用的是哪一種情況。

「不要」以套件名稱產生地圖作為替代方案。
從程式碼推導出來的地圖不可能與程式碼不一致。

## 步驟 2

執行。

    sh tools/shell/reflexion/reflexion.sh \
        --facts <repo>/docs/facts \
        --map <repo>/docs/architecture/hypothesis-map.txt \
        --out <repo>/docs/architecture/reflexion-report.md

## 步驟 3

處置每一項分歧。

對每一項，記錄下列其中之一

- 一項關於系統的未記錄事實，現已寫下
- 一項缺陷：分層違規或抄捷徑，記錄於落差分析中
- 一項對應規則錯誤，已在地圖中修正，並註記該修正

## 步驟 4

處置每一項缺席。

對每一項，記錄下列其中之一

- 該信念是錯的，以及錯在哪裡
- 該關聯確實存在，但透過本次掃描看不見的機制：
  請指名該機制（排程器、佇列、stored procedure、檔案傳輸、
  維運腳本）
- 列舉漏掉了承載該關聯的類別。這個結果屬於
  「關鍵」發現：退回 artifact-enumeration。

## 步驟 5

交代未對應的型別。

未對應的型別意味著模型中沒有對應它的模組，
或它根本不屬於模型所描述的系統。逐一或逐群判定是哪一種，
並記錄該決定。

---

# 完成判準

`docs/architecture/reflexion-report.md` 存在。

每一項分歧都有已記錄的處置。

每一項缺席都有已記錄的處置。

未對應的型別都已交代清楚。

報告載明假說地圖是由誰所寫。

---

# 被下列 Skill 依賴

specification-generation

gap-analysis

---

# 品質檢查清單

☐ 已記錄假說地圖的作者

☐ 地圖並非從套件結構推導而來

☐ 已執行工具並產生報告

☐ 每一項分歧都已處置

☐ 每一項缺席都已處置

☐ 未對應的型別都已交代

☐ 凡缺席指向遺漏類別者，已重新開啟列舉

結束。
