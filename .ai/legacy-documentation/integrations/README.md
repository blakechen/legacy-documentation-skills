# 整合

如何把這套 Skill 函式庫載入 AI 編碼工具。

---

## 整合合約

每一種整合都要做同樣的三件事。

1. 讓 AI 先讀 `orchestrators/legacy-system-analyzer/skill.md`。

2. 給 AI 對 `skills/`、`shared/`、`skills/templates/` 與 `tools/` 的讀取權限，
   以及「執行」這些工具的權限。流水線的關卡是帶有結束狀態碼的指令；
   一個 AI 只能讀、不能執行的工具，就是一道只會被宣稱、不會被檢查的關卡。

3. 把 AI 的工作輸出指向目標儲存庫中的 `docs/`。

本函式庫中沒有任何東西是綁定特定 AI 工具的。

只要某個 AI 工具能從儲存庫讀取 Markdown 指令檔、把檔案寫到磁碟，
並執行 POSIX shell，它就是受支援的。

對一次「經過驗證」的執行而言，最後一項要求不是選配。見
`shared/fact-layer.md`：列舉是從解析出的事實庫「查詢」而來，
而不是在文字中搜尋而來；而 `shared/mechanical-verification.md`
把每一道完成關卡都變成一個指令。

無法執行指令的整合也受支援，但落在層級 C。
它得到本函式庫的全部方法，卻得不到任何驗證，
而它的輸出會帶著 `VERIFICATION: NONE`，好讓沒有人把兩者混為一談。見
`shared/verification-tiers.md`。

---

## 進入點

唯一的進入點是

`.ai/legacy-documentation/orchestrators/legacy-system-analyzer/skill.md`

該檔案指名了每一個下游 Skill 以及它們的執行順序。

除非你打算單獨執行某一個階段，否則不要把工具指向個別的 Skill。

---

## 各工具的入口檔案

每種工具都會從自己的檔案載入專案指令。請在該處放一個指向 orchestrator 的指標。

| 工具 | 專案指令檔 |
| --- | --- |
| Claude Code | `CLAUDE.md` |
| GitHub Copilot | `.github/copilot-instructions.md` |
| Cursor | `.cursor/rules/` |
| Codex CLI | `AGENTS.md` |
| Gemini CLI | `GEMINI.md` |
| Continue.dev | `.continue/` |
| Windsurf | `.windsurf/rules/` |

這些檔名由各家廠商決定，且會隨版本更動。

在把某個整合回報為失效之前，請先對照該工具自己的文件確認目前的檔名。

---

## 指標內容

對每一種工具而言，這段指標內容都相同。

```markdown
當被要求為這個老舊系統撰寫文件時，請閱讀
`.ai/legacy-documentation/orchestrators/legacy-system-analyzer/skill.md`
並確實遵循它。

依該檔案宣告的順序執行各個 Skill。

不要略過產出物列舉關卡。

把所有產生的文件寫在 `docs/` 底下。
```

---

## 上下文視窗

對大型儲存庫而言，整套函式庫無法塞進單一上下文視窗。

在一次工作階段開始時，把 `shared/` 規則載入一次。

一次只載入一個 Skill。

當列舉結果超過 50 個主要單元時，
使用 `orchestrators/legacy-system-analyzer/execution-plan.md` 中的分批規則。

---

## 驗證

當 AI 做到下列各項時，該整合即為正常運作

- 在分析任何原始碼檔案之前先讀 orchestrator

- 在 Phase 2 之前寫出 `docs/enumeration/transaction-classes.txt`

- 在列舉關卡失敗時停止

- 為每一個被列舉的單元產出一份文件，而不是一份摘要

若 AI 產出的是單一系統層級摘要，而不是逐單元文件，
就代表 Skill 函式庫並未被載入。
