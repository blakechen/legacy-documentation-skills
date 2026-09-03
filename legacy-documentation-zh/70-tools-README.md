# 工具（Tools）

本技能組中「確定性」的那一半。

POSIX shell 與 awk。不需安裝直譯器、沒有相依套件、沒有建置步驟、不需要網路。
`javap`、`javac` 與 `jar` 在存在時會被使用，不存在時會被「回報」，而不是繞過。

這裡的每一件事，都是在回答一個「語言模型讀原始碼會答得很合理、
但有時候是錯的」問題。見 `shared/fact-layer.md`。

---

## Layer 1 — 事實

| 工具 | 作用 |
|---|---|
| `lib/mask.awk` | 註解與常值遮蔽。函式庫，與其他 awk 程式一起載入。 |
| `factbase/extract_java.awk` | 掃描器：在遮蔽後的原始碼上維護框架堆疊。 |
| `factbase/extract_java.sh` | 原始碼樹 → `docs/facts/*.psv` |
| `factbase/hierarchy.awk` | 名稱解析與遞移閉包。 |
| `factbase/resolve_calls.awk` | 呼叫點 → 目標型別（僅在無歧義時）。 |
| `factbase/build_factbase.sh` | 執行上述兩者，寫出 `supertype.psv`、`ancestor.psv`、`calls-resolved.psv` |
| `factbase/verify_bytecode.sh` | 獨立 oracle：`javap` 對照 factbase |

## Layer 2 — 結構

| 工具 | 作用 |
|---|---|
| `factbase/enumerate.sh` | Factbase → 三份列舉主清單 |
| `factbase/prioritize.sh` | 可達性 + git 變更頻率 + 使用量 → `priority.txt` |
| `factbase/archetypes.sh` + `.awk` | Clone 分群 → `archetypes.txt` |
| `factbase/domain_variables.sh` | DB 欄位、輸入欄位、組態鍵 |
| `reflexion/reflexion.sh` | 人的模組圖 對照 呼叫圖 |

## 驗證

| 工具 | 作用 |
|---|---|
| `verify/depth_checks.awk` | 對單一份文件執行四項深度檢查 |
| `verify/depth_checks.sh` | 逐單元執行 → `depth-report.md` |
| `verify/staleness.sh` | 把文件綁定到原始碼版本；支援增量重跑 |
| `chartest/gen_skeletons.sh` + `.awk` | 已記錄的分支 → 可執行的測試骨架 |

## 自我測試

    sh tools/selftest.sh

對 `examples/fixtures/java-dispatcher` 執行整條工具鏈，並與 `expected/` 比對。
共 20 項檢查，其中兩項「必須失敗」：
一份看似合理但錯誤的文件，以及一個少了某個類別的 factbase。
工具變更若改動預期輸出，在那些檔案被刻意更新之前，都視為迴歸。

---

## Factbase 格式

純管線分隔文字，一行一筆記錄，無標頭列。
可以 grep、可以 diff，也可以在 pull request 中審閱。

| 檔案 | 欄位 |
|---|---|
| `files.psv` | path, package, lines |
| `hashes.psv` | path, sha256 |
| `types.psv` | fqn, simple, kind, owner, path, line, bodyStart, bodyEnd, modifiers, package, extends, implements, imports |
| `methods.psv` | type, name, path, line, endLine, ctor, public, abstract, inAnon, if, for, while, case, catch, and, or, ternary, total, modifiers |
| `calls.psv` | fromType, fromMethod, receiver, callee, kind, path, line |
| `calls-resolved.psv` | 同上，再加上已解析的目標型別 |
| `literals.psv` | path, line, value |
| `supertype.psv` | child, parent, parentRaw, relation, resolution |
| `ancestor.psv` | type, ancestor, depth —— 遞移閉包 |
| `resolution.psv` | 解析方式, 筆數 |
| `manifest.psv` | key, value |

常值中的 `|` 會寫成 `&#124;`。

用手邊已有的工具查詢它：

    # 任何深度下 StdTrxObject 的所有子類別
    awk -F'|' '$2 == "EXTERNAL:StdTrxObject" { print $1, $3 }' docs/facts/ancestor.psv

    # 判斷點超過 10 個的 public 方法
    awk -F'|' '$7 == 1 && $18 > 10 { print $1 "." $2, $18 }' docs/facts/methods.psv

---

## 執行順序

    extract_java.sh  ->  build_factbase.sh  ->  verify_bytecode.sh
                                            ->  enumerate.sh
                                                  ->  prioritize.sh
                                                  ->  archetypes.sh
                                                  ->  domain_variables.sh
                                            ->  reflexion.sh

    （撰寫文件）

    ->  depth_checks.sh  ->  staleness.sh --record
    ->  gen_skeletons.sh

---

## 實例

    REPO=/path/to/legacy-app

    sh tools/factbase/extract_java.sh --repo $REPO \
        --out $REPO/docs/facts --source-root src/main/java
    sh tools/factbase/build_factbase.sh --facts $REPO/docs/facts
    sh tools/factbase/verify_bytecode.sh --repo $REPO \
        --facts $REPO/docs/facts \
        --out $REPO/docs/facts/bytecode-verification.md

    sh tools/factbase/enumerate.sh \
        --facts $REPO/docs/facts --out $REPO/docs/enumeration
    sh tools/factbase/prioritize.sh --repo $REPO \
        --facts $REPO/docs/facts --enumeration $REPO/docs/enumeration
    sh tools/factbase/archetypes.sh --repo $REPO \
        --facts $REPO/docs/facts --enumeration $REPO/docs/enumeration

接著撰寫文件，然後：

    sh tools/verify/depth_checks.sh --repo $REPO \
        --facts $REPO/docs/facts \
        --docs $REPO/docs/modules/transactions \
        --enumeration $REPO/docs/enumeration \
        --out $REPO/docs/gap-analysis/depth-report.md

---

## 可攜性

以 POSIX `sh` 與 POSIX `awk` 撰寫。
已在 macOS 上實測：BSD awk、BSD sed、bash 3.2。
「尚未」在 GNU awk 或 busybox awk 上執行過 —— 兩者之間有差異的語法都被刻意避開了，
但那是設計上的主張，不是測試結果。
在依賴它之前，請先在目標平台上執行 `sh tools/selftest.sh`。

刻意避開：`gensub`、`asort`、regex `RS`、`length(array)`、
GNU 專屬的 `sed -i`、正規表示式中的 `\s` 與 `\d`、以及 process substitution。

`sha256` 在不同系統上有三種寫法；`lib/common.sh` 依序嘗試
`shasum`、`sha256sum` 與 `openssl`，最後退回 `cksum`，
並且會明確標示它是 `cksum`，以免有人誤以為那是密碼學雜湊。

---

## 限制

`extract_java.awk` 是在遮蔽後的原始碼上執行的詞法掃描器。
它不解析泛型、多載或型別。
它把無法解析的部分標記出來而不是猜測，
而 bytecode oracle 之所以存在，正是因為
「單靠詞法掃描器不該被信任來做列舉」。

Text block（`""" ... """`）不會被遮蔽。舊系統的程式碼早於這項語法。

目前只支援 Java。
新增語言需要新的 Layer 1 抽取器，輸出相同格式的記錄。
Layer 1 以上完全不變。

當某語言沒有抽取器時，`shared/confidence-scoring.md`
禁止把關於該語言程式碼的發現回報為 High 信心。
