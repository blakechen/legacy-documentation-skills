# 工具 —— POSIX shell

本函式庫中屬於「決定性」的那一半，為 POSIX `sh` 與 `awk` 而寫。
`tools/powershell/` 是同一套工具的 PowerShell 7 版本；
兩者產出逐位元組相同的 factbase，任選其一即可。見 `tools/README.md`。

不需安裝直譯器、沒有相依套件、沒有建置步驟、不需要網路。
`javap`、`javac` 與 `jar` 在存在時會被使用，
缺席時則如實回報，而不是繞過去。

這裡的每一項工具，回答的都是「語言模型閱讀原始碼時會答得看似合理、
但有時是錯的」那類問題。見 `shared/fact-layer.md`。

---

## Layer 1 —— 事實

| 工具 | 功能 |
|---|---|
| `lib/mask.awk` | 遮蔽註解與常值。函式庫，與其他 awk 程式一起載入。 |
| `factbase/extract_java.awk` | 掃描器：在遮蔽後的原始碼上維護框架堆疊。 |
| `factbase/extract_java.sh` | 原始碼樹 → `docs/facts/*.psv` |
| `factbase/hierarchy.awk` | 名稱解析與遞移閉包。 |
| `factbase/resolve_calls.awk` | 呼叫點 → 目標型別（在無歧義時）。 |
| `factbase/build_factbase.sh` | 執行上述兩者；寫出 `supertype.psv`、`ancestor.psv`、`calls-resolved.psv` |
| `factbase/verify_bytecode.sh` | 獨立判準：`javap` 對照 factbase |
| `verification_tier.sh` | 記錄本次執行的驗證實際上有多強 |

## Layer 2 —— 結構

| 工具 | 功能 |
|---|---|
| `factbase/enumerate.sh` | factbase → 三份列舉主清單 |
| `factbase/prioritize.sh` | 可達性 + git 變更頻率 + 使用量 → `priority.txt` |
| `factbase/archetypes.sh` + `.awk` | clone 分群 → `archetypes.txt` |
| `factbase/domain_variables.sh` | DB 欄位、輸入欄位、組態鍵 |
| `reflexion/reflexion.sh` | 某個人的模組地圖對照呼叫圖 |

## 驗證

| 工具 | 功能 |
|---|---|
| `verify/depth_checks.awk` | 對單一份文件執行四項深度檢查 |
| `verify/depth_checks.sh` | 逐單元執行它們 → `depth-report.md` |
| `verify/staleness.sh` | 把文件綁定到原始碼版本；支援增量重跑 |
| `chartest/gen_skeletons.sh` + `.awk` | 已記錄的分支 → 可執行的測試骨架 |

## 自我測試

    sh tools/shell/selftest.sh

對 `examples/fixtures/java-dispatcher` 執行整條工具鏈，並與 `expected/` 比對。
共 24 項檢查，其中三項「必須」失敗或被阻斷：
一份看似合理但錯誤的文件、一個從 factbase 中缺席的類別，
以及一個與掃描不一致的判準。
若某項工具變更改動了預期輸出，在那些檔案被刻意更新之前，一律視為迴歸。

---

## factbase

純文字、以管線符號分隔，一行一筆記錄，無標題列。
可 grep、可 diff，也可在 pull request 中審閱。

| 檔案 | 欄位 |
|---|---|
| `files.psv` | path, package, lines |
| `hashes.psv` | path, sha256 |
| `types.psv` | fqn, simple, kind, owner, path, line, bodyStart, bodyEnd, modifiers, package, extends, implements, imports |
| `methods.psv` | type, name, path, line, endLine, ctor, public, abstract, inAnon, if, for, while, case, catch, and, or, ternary, total, modifiers |
| `calls.psv` | fromType, fromMethod, receiver, callee, kind, path, line |
| `calls-resolved.psv` | 上述欄位再加上已解析的目標型別 |
| `literals.psv` | path, line, value |
| `supertype.psv` | child, parent, parentRaw, relation, resolution |
| `ancestor.psv` | type, ancestor, depth —— 遞移閉包 |
| `resolution.psv` | resolution kind, count |
| `manifest.psv` | key, value |

常值中的 `|` 會寫成 `&#124;`。

用你手邊原本就有的工具查詢它：

    # 任意深度下 StdTrxObject 的所有子類別
    awk -F'|' '$2 == "EXTERNAL:StdTrxObject" { print $1, $3 }' docs/facts/ancestor.psv

    # 決策點超過 10 個的公開方法
    awk -F'|' '$7 == 1 && $18 > 10 { print $1 "." $2, $18 }' docs/facts/methods.psv

---

## 順序

    extract_java.sh  ->  build_factbase.sh  ->  verify_bytecode.sh
                                                  ->  verification_tier.sh
                                            ->  enumerate.sh
                                                  ->  prioritize.sh
                                                  ->  archetypes.sh
                                                  ->  domain_variables.sh
                                            ->  reflexion.sh

    （撰寫文件）

    ->  depth_checks.sh  ->  staleness.sh --record
    ->  gen_skeletons.sh

---

## 完整範例

    REPO=/path/to/legacy-app

    sh tools/shell/factbase/extract_java.sh --repo $REPO \
        --out $REPO/docs/facts --source-root src/main/java
    sh tools/shell/factbase/build_factbase.sh --facts $REPO/docs/facts
    sh tools/shell/factbase/verify_bytecode.sh --repo $REPO \
        --facts $REPO/docs/facts \
        --out $REPO/docs/facts/bytecode-verification.md

    sh tools/shell/verification_tier.sh --facts $REPO/docs/facts \
        --out $REPO/docs/verification-tier.txt

    sh tools/shell/factbase/enumerate.sh \
        --facts $REPO/docs/facts --out $REPO/docs/enumeration
    sh tools/shell/factbase/prioritize.sh --repo $REPO \
        --facts $REPO/docs/facts --enumeration $REPO/docs/enumeration
    sh tools/shell/factbase/archetypes.sh --repo $REPO \
        --facts $REPO/docs/facts --enumeration $REPO/docs/enumeration

接著撰寫文件，然後：

    sh tools/shell/verify/depth_checks.sh --repo $REPO \
        --facts $REPO/docs/facts \
        --docs $REPO/docs/modules/transactions \
        --enumeration $REPO/docs/enumeration \
        --out $REPO/docs/gap-analysis/depth-report.md

---

## 可移植性

為 POSIX `sh` 與 POSIX `awk` 而寫。已在 macOS 上實測：
BSD awk、BSD sed、bash 3.2。尚未在 GNU awk 或 busybox awk 下執行過 ——
兩者之間有差異的語法結構都被刻意避開，但那是一項設計宣稱，不是測試結果。
在你的目標平台上依賴它之前，請先執行 `sh tools/shell/selftest.sh`。

明確避開的項目：`gensub`、`asort`、以正規表示式作為 `RS`、
`length(array)`、僅 GNU 支援的 `sed -i`、
正規表示式中的 `\s` 與 `\d`，以及 process substitution。

`sha256` 在不同系統上有三種寫法；`lib/common.sh` 會依序嘗試
`shasum`、`sha256sum` 與 `openssl`，並在都沒有時退回 `cksum`，
且會如實標示，以免有人把它誤認為密碼學雜湊。

---

## 限制

`extract_java.awk` 是在遮蔽後的原始碼上運作的詞法掃描器。
它不解析泛型、多載或型別。它會把無法解析的東西標示出來，而不是猜測；
而 bytecode 判準之所以存在，正是因為「單靠詞法掃描器」不該被信任來做列舉。

Text block（`""" ... """`）不會被遮蔽。老舊程式碼早於這項語法。

目前只支援 Java。新增一種語言需要一個新的 Layer 1 抽取器，發出相同的記錄格式。
Layer 1 之上的一切都不需要改動。

若某語言沒有對應的抽取器，`shared/confidence-scoring.md`
禁止把關於該語言程式碼的發現回報為 High 信心度。
