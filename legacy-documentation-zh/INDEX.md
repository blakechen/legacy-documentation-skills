# 舊系統文件產生技能組 — 繁體中文版

本目錄是 `.ai/legacy-documentation/` 的完整繁體中文譯本，
原本的巢狀結構已扁平化為單一目錄。

> **注意**：英文原檔仍是「實際運作」的版本。
> 本中文版供閱讀、審閱與交流使用；修改中文版不會影響 skill 的執行行為。
> 原始結構中有 12 個 `skill.md`、8 個 `README.md`、5 個 `notes.md` 同名，
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
| [09-skill-fact-extraction.md](09-skill-fact-extraction.md) | `skills/fact-extraction/skill.md` |
| [10-skill-inventory.md](10-skill-inventory.md) | `skills/inventory/skill.md` |
| [11-skill-technology-discovery.md](11-skill-technology-discovery.md) | `skills/technology-discovery/skill.md` |
| [12-skill-architecture-discovery.md](12-skill-architecture-discovery.md) | `skills/architecture-discovery/skill.md` |
| [12a-skill-artifact-enumeration.md](12a-skill-artifact-enumeration.md) | `skills/artifact-enumeration/skill.md` |
| [12b-skill-archetype-clustering.md](12b-skill-archetype-clustering.md) | `skills/archetype-clustering/skill.md` |
| [12c-skill-reflexion-check.md](12c-skill-reflexion-check.md) | `skills/reflexion-check/skill.md` |
| [13-skill-module-analysis.md](13-skill-module-analysis.md) | `skills/module-analysis/skill.md` |
| [14-skill-database-analysis.md](14-skill-database-analysis.md) | `skills/database-analysis/skill.md` |
| [15-skill-interface-analysis.md](15-skill-interface-analysis.md) | `skills/interface-analysis/skill.md` |
| [16-skill-business-rule-extraction.md](16-skill-business-rule-extraction.md) | `skills/business-rule-extraction/skill.md` |
| [17-skill-sequence-discovery.md](17-skill-sequence-discovery.md) | `skills/sequence-discovery/skill.md` |
| [18-skill-specification-generation.md](18-skill-specification-generation.md) | `skills/specification-generation/skill.md` |
| [19-skill-gap-analysis.md](19-skill-gap-analysis.md) | `skills/gap-analysis/skill.md` |

## 共用規則（shared/）

20 個共用規則現已全部掛載到 Skill 上（透過各 Skill 的 `shared:`
前置資料與「# 共用規則」章節）。其中 7 個為全體適用，
其餘依 Skill 性質選擇性掛載。

| 中文檔案 | 對應原檔 | 掛載範圍 |
|----------|----------|----------|
| [30-shared-fact-layer.md](30-shared-fact-layer.md) | `shared/fact-layer.md` | 全體 |
| [30-shared-mechanical-verification.md](30-shared-mechanical-verification.md) | `shared/mechanical-verification.md` | 全體 |
| [30-shared-verification-tiers.md](30-shared-verification-tiers.md) | `shared/verification-tiers.md` | 全體 |
| [30-shared-logic-depth.md](30-shared-logic-depth.md) | `shared/logic-depth.md` | 逐單元深度相關 Skill |
| [30-shared-business-rule-criteria.md](30-shared-business-rule-criteria.md) | `shared/business-rule-criteria.md` | 業務規則萃取 |
| [30-shared-prioritization.md](30-shared-prioritization.md) | `shared/prioritization.md` | 協調器、成品列舉 |
| [30-shared-archetypes.md](30-shared-archetypes.md) | `shared/archetypes.md` | 原型分群、模組分析 |
| [30-shared-reflexion-model.md](30-shared-reflexion-model.md) | `shared/reflexion-model.md` | Reflexion 檢查 |
| [30-shared-incremental-update.md](30-shared-incremental-update.md) | `shared/incremental-update.md` | 落差分析、協調器 |
| [30-shared-enumeration-first.md](30-shared-enumeration-first.md) | `shared/enumeration-first.md` | 產生逐單元文件的 Skill |
| [30-shared-iterative-depth.md](30-shared-iterative-depth.md) | `shared/iterative-depth.md` | 模組分析、業務規則萃取 |
| [30-shared-custom-framework-recognition.md](30-shared-custom-framework-recognition.md) | `shared/custom-framework-recognition.md` | 架構探索、成品列舉 |
| [30-shared-documentation-style.md](30-shared-documentation-style.md) | `shared/documentation-style.md` | 全體 |
| [30-shared-evidence-rules.md](30-shared-evidence-rules.md) | `shared/evidence-rules.md` | 全體 |
| [30-shared-output-schema.md](30-shared-output-schema.md) | `shared/output-schema.md` | 全體 |
| [30-shared-confidence-scoring.md](30-shared-confidence-scoring.md) | `shared/confidence-scoring.md` | 全體 |
| [30-shared-naming-conventions.md](30-shared-naming-conventions.md) | `shared/naming-conventions.md` | 全體 |
| [30-shared-markdown-style.md](30-shared-markdown-style.md) | `shared/markdown-style.md` | 全體 |
| [30-shared-mermaid-guidelines.md](30-shared-mermaid-guidelines.md) | `shared/mermaid-guidelines.md` | 產出圖表的 Skill |
| [30-shared-quality-checklist.md](30-shared-quality-checklist.md) | `shared/quality-checklist.md` | 全體 |

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

## 整合（integrations/）

| 中文檔案 | 對應原檔 |
|----------|----------|
| [60-integrations-README.md](60-integrations-README.md) | `integrations/README.md` |

## 工具（tools/）

| 中文檔案 | 對應原檔 |
|----------|----------|
| [70-tools-README.md](70-tools-README.md) | `tools/README.md` |

工具本身（shell 與 awk 程式、fixture、`selftest.sh`）不翻譯：
它們是可執行的程式碼，翻譯會使其與實際行為脫節。
程式碼中的註解維持英文。

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
  英文原檔的這 158 處亂碼現已一併修正，兩版本不再有此差異。
- **編號前綴**：`artifact-enumeration` 在管線中位於架構探索與模組分析之間，
  為避免既有 13–19 全部重新編號，採用 `12a-` 前綴以維持排序。
  同理，`archetype-clustering` 與 `reflexion-check` 採用 `12b-`、`12c-`；
  `fact-extraction` 在清冊盤點之前執行，採用 `09-`。
- **不翻譯的部分**：`tools/` 下的 shell 與 awk 程式碼、
  `examples/fixtures/` 下的 fixture 原始碼與預期輸出。
  這些是可執行的產出物，只有 `tools/README.md` 有中文版。
