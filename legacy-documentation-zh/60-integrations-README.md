# 整合（Integrations）

如何把這套 Skill Library 載入 AI 程式開發工具。

---

## 整合契約

每一種整合方式做的都是同樣三件事。

1. 讓 AI 先讀 `orchestrators/legacy-system-analyzer/skill.md`。

2. 給 AI 對 `skills/`、`shared/` 與 `skills/templates/` 的讀取權限。

3. 把 AI 的產出目標指向目標程式碼庫中的 `docs/`。

這套 Library 沒有任何內容是綁定特定工具的。

只要一個工具能從程式碼庫讀取 Markdown 指令檔、並能把檔案寫入磁碟，
它就屬於「支援」範圍。

---

## 進入點

唯一的進入點是

`.ai/legacy-documentation/orchestrators/legacy-system-analyzer/skill.md`

該檔案指明了每一個下游 Skill 以及執行順序。

除非你刻意要單獨執行某一個階段，
否則不要把工具直接指向個別的 Skill。

---

## 各工具的專案指令檔

每個工具都從自己的檔案載入專案層級指令。把指向協調器的指標放在該檔案裡。

| 工具 | 專案指令檔 |
| --- | --- |
| Claude Code | `CLAUDE.md` |
| GitHub Copilot | `.github/copilot-instructions.md` |
| Cursor | `.cursor/rules/` |
| Codex CLI | `AGENTS.md` |
| Gemini CLI | `GEMINI.md` |
| Continue.dev | `.continue/` |
| Windsurf | `.windsurf/rules/` |

這些檔名由各家廠商決定，且會隨版本改變。

在判定某個整合「壞掉」之前，
請先對照該工具自己的官方文件確認目前的檔名。

---

## 指標內容

每個工具要放的指標內容都相同。

```markdown
當被要求為這個舊系統產生文件時，請讀取
`.ai/legacy-documentation/orchestrators/legacy-system-analyzer/skill.md`
並嚴格依循。

依該檔案所宣告的順序執行各個 Skill。

不得跳過「成品列舉」關卡。

所有產生的文件一律寫入 `docs/` 之下。
```

---

## 脈絡視窗（Context Window）

面對大型程式碼庫時，整套 Library 無法一次塞進單一脈絡視窗。

在工作階段開始時，`shared/` 規則載入一次即可。

Skill 一次載入一個。

當列舉出的主要單元超過 50 個時，
套用 `orchestrators/legacy-system-analyzer/execution-plan.md` 中的批次規則。

---

## 驗證整合是否生效

當 AI 出現以下行為時，代表整合正常運作

- 在分析任何原始碼「之前」先讀取協調器

- 在進入階段 2 之前先寫出 `docs/enumeration/transaction-classes.txt`

- 列舉關卡失敗時會停止

- 產出「逐單元」文件，而不是一份摘要

如果 AI 產出的是單一份系統層級摘要、而非逐單元文件，
代表這套 Skill Library 根本沒有被載入。
