# 工具

本函式庫中屬於「決定性」的那一半，提供兩種實作。

| 目錄 | 執行環境 | 進入點 |
|---|---|---|
| `shell/` | POSIX `sh` + `awk` | `sh tools/shell/selftest.sh` |
| `powershell/` | PowerShell 7 | `pwsh tools/powershell/selftest.ps1` |

挑你的平台上原本就有的那一個。兩者都不需要安裝套件、
不需要建置步驟，也不需要網路。`javap`、`javac` 與 `jar`
在存在時會被使用，缺席時則如實回報，而不是繞過去。

這裡的每一項工具，回答的都是「語言模型閱讀原始碼時會答得看似合理、
但有時是錯的」那類問題。見 `shared/fact-layer.md`。

---

## 兩者是同一套工具

同樣的工具、同樣的檔名、同樣的記錄格式、同樣的結束碼。
PowerShell 那一半是移植，不是重新實作：
對 `examples/fixtures/java-dispatcher` 這個 fixture 而言，
每一個產生的 `.psv` 與 `.txt` 檔在兩者之間都是**逐位元組相同**的，
而兩邊的 selftest 也執行同樣的 24 項檢查。

這件事之所以重要，是因為 factbase 會被提交與 diff。
一個同時有 Windows 與 macOS 機器的團隊，可以用任一半對同一個儲存庫執行，
並得到同一個檔案，因此重跑不會出現由作業系統造成的 diff。

只有兩件事不同，而且兩者都是明說的，不是藏起來的：

* 產生的報告會指名寫出它的工具，
  因此 `enumeration-report.md` 會寫 `enumerate.sh` 或 `enumerate.ps1`；
* 命令列遵循各語言的慣例 —— shell 那一半是 `--facts <dir>`，
  PowerShell 那一半是 `-Facts <dir>`。

## 哪個檔案對哪個

| Shell | PowerShell |
|---|---|
| `lib/common.sh` | `lib/common.ps1` |
| `lib/mask.awk` | `lib/mask.ps1` |
| `factbase/extract_java.sh` + `.awk` | `factbase/extract_java.ps1` |
| `factbase/hierarchy.awk` | `factbase/hierarchy.ps1` |
| `factbase/resolve_calls.awk` | `factbase/resolve_calls.ps1` |
| `factbase/build_factbase.sh` | `factbase/build_factbase.ps1` |
| `factbase/verify_bytecode.sh` | `factbase/verify_bytecode.ps1` |
| `factbase/enumerate.sh` | `factbase/enumerate.ps1` |
| `factbase/prioritize.sh` | `factbase/prioritize.ps1` |
| `factbase/archetypes.sh` + `.awk` | `factbase/archetypes.ps1` |
| `factbase/domain_variables.sh` | `factbase/domain_variables.ps1` |
| `verify/depth_checks.sh` + `.awk` | `verify/depth_checks.ps1` |
| `verify/staleness.sh` | `verify/staleness.ps1` |
| `chartest/gen_skeletons.sh` + `.awk` | `chartest/gen_skeletons.ps1` |
| `reflexion/reflexion.sh` | `reflexion/reflexion.ps1` |
| `verification_tier.sh` | `verification_tier.ps1` |
| `selftest.sh` | `selftest.ps1` |

凡是 shell 那一半把工具拆成「驅動程式 + awk 程式」之處，
PowerShell 那一半都是單一檔案：PowerShell 沒有 `awk -f a -f b` 的對應寫法，
而兩個檔案之間若只隔著一次函式呼叫，那樣的結構不值得保留。

## 修改工具

只改其中一半並不算完成，另一半也必須做同樣的修改，
因為上面的承諾就是兩者一致。請跑兩邊的 selftest：

    sh   tools/shell/selftest.sh
    pwsh tools/powershell/selftest.ps1

兩者都必須回報 `passed: 24   failed: 0`。
若某項變更改動了 `examples/fixtures/java-dispatcher/expected/` 中的預期輸出，
在那些檔案被刻意更新之前，一律視為迴歸。
