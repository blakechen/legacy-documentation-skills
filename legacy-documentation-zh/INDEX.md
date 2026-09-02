# 舊系統文件產生技能組 — 繁體中文版

本目錄是 `.ai/legacy-documentation/` 的完整繁體中文譯本，
原本的巢狀結構已扁平化為單一目錄。

> **注意**：英文原檔仍是「實際運作」的版本。
> 本中文版供閱讀、審閱與交流使用；修改中文版不會影響 skill 的執行行為。
> 原始結構中有 9 個 `skill.md`、6 個 `README.md`、5 個 `notes.md` 同名，
> 因此檔名加上編號前綴以避免衝突。

---

## 總覽

| 中文檔案 | 對應原檔 |
|----------|----------|
| [00-README.md](00-README.md) | `README.md` |

## 協調器（Orchestrator）

| 中文檔案 | 對應原檔 |
|----------|----------|
| [01-orchestrator-skill.md](01-orchestrator-skill.md) | `orchestrators/legacy-system-analyzer/skill.md` |
| [02-orchestrator-pipeline.md](02-orchestrator-pipeline.md) | `orchestrators/legacy-system-analyzer/pipeline.md` |
| [03-orchestrator-workflow.md](03-orchestrator-workflow.md) | `orchestrators/legacy-system-analyzer/workflow.md` |
| [04-orchestrator-execution-plan.md](04-orchestrator-execution-plan.md) | `orchestrators/legacy-system-analyzer/execution-plan.md` |

## 各項 Skill（依管線執行順序）

| 中文檔案 | 對應原檔 |
|----------|----------|
| [10-skill-inventory.md](10-skill-inventory.md) | `skills/inventory/skill.md` |
| [11-skill-technology-discovery.md](11-skill-technology-discovery.md) | `skills/technology-discovery/skill.md` |
| [12-skill-architecture-discovery.md](12-skill-architecture-discovery.md) | `skills/architecture-discovery/skill.md` |
| [13-skill-module-analysis.md](13-skill-module-analysis.md) | `skills/module-analysis/skill.md` |
| [14-skill-database-analysis.md](14-skill-database-analysis.md) | `skills/database-analysis/skill.md` |
| [15-skill-interface-analysis.md](15-skill-interface-analysis.md) | `skills/interface-analysis/skill.md` |
| [16-skill-business-rule-extraction.md](16-skill-business-rule-extraction.md) | `skills/business-rule-extraction/skill.md` |
| [17-skill-sequence-discovery.md](17-skill-sequence-discovery.md) | `skills/sequence-discovery/skill.md` |
| [18-skill-specification-generation.md](18-skill-specification-generation.md) | `skills/specification-generation/skill.md` |
| [19-skill-gap-analysis.md](19-skill-gap-analysis.md) | `skills/gap-analysis/skill.md` |

## 共用規則（shared/）

被 skill 以 `Apply shared/X.md.` 實際掛載的有 4 個，以「★」標示。

| 中文檔案 | 對應原檔 | 已掛載 |
|----------|----------|--------|
| [30-shared-logic-depth.md](30-shared-logic-depth.md) | `shared/logic-depth.md` | ★ |
| [30-shared-enumeration-first.md](30-shared-enumeration-first.md) | `shared/enumeration-first.md` | ★ |
| [30-shared-iterative-depth.md](30-shared-iterative-depth.md) | `shared/iterative-depth.md` | ★ |
| [30-shared-custom-framework-recognition.md](30-shared-custom-framework-recognition.md) | `shared/custom-framework-recognition.md` | ★ |
| [30-shared-documentation-style.md](30-shared-documentation-style.md) | `shared/documentation-style.md` | |
| [30-shared-evidence-rules.md](30-shared-evidence-rules.md) | `shared/evidence-rules.md` | |
| [30-shared-output-schema.md](30-shared-output-schema.md) | `shared/output-schema.md` | |
| [30-shared-confidence-scoring.md](30-shared-confidence-scoring.md) | `shared/confidence-scoring.md` | |
| [30-shared-naming-conventions.md](30-shared-naming-conventions.md) | `shared/naming-conventions.md` | |
| [30-shared-markdown-style.md](30-shared-markdown-style.md) | `shared/markdown-style.md` | |
| [30-shared-mermaid-guidelines.md](30-shared-mermaid-guidelines.md) | `shared/mermaid-guidelines.md` | |
| [30-shared-quality-checklist.md](30-shared-quality-checklist.md) | `shared/quality-checklist.md` | |

## 文件模板（templates/）

| 中文檔案 | 對應原檔 |
|----------|----------|
| [40-template-transaction.md](40-template-transaction.md) | `skills/templates/transaction.md` |
| [40-template-module.md](40-template-module.md) | `skills/templates/module.md` |
| [40-template-specification.md](40-template-specification.md) | `skills/templates/specification.md` |
| [40-template-architecture.md](40-template-architecture.md) | `skills/templates/architecture.md` |
| [40-template-database.md](40-template-database.md) | `skills/templates/database.md` |
| [40-template-api.md](40-template-api.md) | `skills/templates/api.md` |
| [40-template-business-rule.md](40-template-business-rule.md) | `skills/templates/business-rule.md` |
| [40-template-sequence.md](40-template-sequence.md) | `skills/templates/sequence.md` |
| [40-template-system-overview.md](40-template-system-overview.md) | `skills/templates/system-overview.md` |
| [40-template-glossary.md](40-template-glossary.md) | `skills/templates/glossary.md` |

## 範例（examples/）

| 中文檔案 | 對應原檔 |
|----------|----------|
| [50-examples-README.md](50-examples-README.md) | `examples/README.md` |
| [51-example-cobol-README.md](51-example-cobol-README.md) | `examples/cobol/README.md` |
| [51-example-cobol-notes.md](51-example-cobol-notes.md) | `examples/cobol/notes.md` |
| [52-example-dotnet-README.md](52-example-dotnet-README.md) | `examples/dotnet/README.md` |
| [52-example-dotnet-notes.md](52-example-dotnet-notes.md) | `examples/dotnet/notes.md` |
| [53-example-nodejs-README.md](53-example-nodejs-README.md) | `examples/nodejs/README.md`（原檔為空） |
| [53-example-nodejs-notes.md](53-example-nodejs-notes.md) | `examples/nodejs/notes.md` |
| [54-example-spring-boot-README.md](54-example-spring-boot-README.md) | `examples/spring-boot/README.md` |
| [54-example-spring-boot-notes.md](54-example-spring-boot-notes.md) | `examples/spring-boot/notes.md` |
| [55-example-websphere-README.md](55-example-websphere-README.md) | `examples/websphere/README.md` |
| [55-example-websphere-notes.md](55-example-websphere-notes.md) | `examples/websphere/notes.md` |

---

## 翻譯處理原則

- **技術識別字保留原文**：檔案路徑、類別名稱、註解（`@Entity`）、
  YAML 前置資料的鍵值與值、程式碼與虛擬碼區塊內容、產出物路徑
  （`docs/modules/transactions/`）一律不譯，以免與實際執行行為脫節。
- **規範用語對照**：SHALL → 「應」、SHALL NOT → 「不得」、
  MUST → 「必須」、FORBIDDEN → 「禁止」、CRITICAL → 「關鍵」。
- **章節標題已中文化**，但結構層級與原檔完全一致。
- **修正原檔亂碼**：原檔中的 `??` 是編碼損壞的符號，
  中文版依上下文還原為流程箭頭 `→` 與檢查框 `☐`。
