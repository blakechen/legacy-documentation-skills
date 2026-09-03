# 工具（Tools）

本技能組中「確定性」的那一半。

只使用 Python 3 標準函式庫。無建置步驟、無相依套件、無網路。
`javap` 與 `javac` 在存在時會被使用，不存在時會被「回報」，而不是繞過。

這裡的每一件事，都是在回答一個「語言模型讀原始碼會答得很合理、
但有時候是錯的」問題。見 `shared/fact-layer.md`。

---

## Layer 1 — 事實

| 工具 | 作用 |
|---|---|
| `factbase/javalex.py` | Java 詞法掃描器。函式庫，非 CLI。 |
| `factbase/extract_java.py` | 原始碼樹 → `docs/facts/*.jsonl` |
| `factbase/build_factbase.py` | JSONL → SQLite、名稱解析、遞移閉包 |
| `factbase/verify_bytecode.py` | 獨立 oracle：`javap` 對照 factbase |

## Layer 2 — 結構

| 工具 | 作用 |
|---|---|
| `factbase/enumerate.py` | Factbase → 三份列舉主清單 |
| `factbase/prioritize.py` | 可達性 + git 變更頻率 + 使用量 → `priority.txt` |
| `factbase/archetypes.py` | Clone 分群 → `archetypes.txt` |
| `factbase/domain_variables.py` | DB 欄位、輸入欄位、組態鍵 |
| `reflexion/reflexion.py` | 人的模組圖 對照 呼叫圖 |

## 驗證

| 工具 | 作用 |
|---|---|
| `verify/depthlib.py` | Markdown 與 factbase 解析。函式庫。 |
| `verify/run_depth_checks.py` | 四項深度檢查 → `depth-report.md` |
| `verify/staleness.py` | 把文件綁定到原始碼版本；支援增量重跑 |
| `chartest/gen_skeletons.py` | 已記錄的分支 → 可執行的測試骨架 |

## 自我測試

    sh tools/selftest.sh

對 `examples/fixtures/java-dispatcher` 執行整條工具鏈，
並與 `expected/` 比對。共 18 項檢查。
工具變更若改動預期輸出，在那些檔案被刻意更新之前，都視為迴歸。

---

## 執行順序

    extract_java.py  ->  build_factbase.py  ->  verify_bytecode.py
                                            ->  enumerate.py
                                                  ->  prioritize.py
                                                  ->  archetypes.py
                                                  ->  domain_variables.py
                                            ->  reflexion.py

    （撰寫文件）

    ->  run_depth_checks.py  ->  staleness.py --record
    ->  gen_skeletons.py

---

## 實例

    REPO=/path/to/legacy-app

    python3 tools/factbase/extract_java.py --repo $REPO \
        --out $REPO/docs/facts --source-root src/main/java
    python3 tools/factbase/build_factbase.py --facts $REPO/docs/facts \
        --db $REPO/docs/facts/factbase.sqlite
    python3 tools/factbase/verify_bytecode.py --repo $REPO \
        --db $REPO/docs/facts/factbase.sqlite \
        --out $REPO/docs/facts/bytecode-verification.md

    python3 tools/factbase/enumerate.py \
        --db $REPO/docs/facts/factbase.sqlite --out $REPO/docs/enumeration
    python3 tools/factbase/prioritize.py --repo $REPO \
        --db $REPO/docs/facts/factbase.sqlite --enumeration $REPO/docs/enumeration
    python3 tools/factbase/archetypes.py --repo $REPO \
        --db $REPO/docs/facts/factbase.sqlite --enumeration $REPO/docs/enumeration

接著撰寫文件，然後：

    python3 tools/verify/run_depth_checks.py --repo $REPO \
        --db $REPO/docs/facts/factbase.sqlite \
        --docs $REPO/docs/modules/transactions \
        --enumeration $REPO/docs/enumeration \
        --out $REPO/docs/gap-analysis/depth-report.md

---

## 限制

`extract_java.py` 是詞法掃描器。
它不解析泛型、多載或型別。
它把無法解析的部分標記出來而不是猜測，
而 bytecode oracle 之所以存在，正是因為
「單靠詞法掃描器不該被信任來做列舉」。

目前只支援 Java。
新增語言需要新的 Layer 1 抽取器，輸出相同的 JSONL 記錄。
Layer 1 以上完全不變。

當某語言沒有抽取器時，`shared/confidence-scoring.md`
禁止把關於該語言程式碼的發現回報為 High 信心。
