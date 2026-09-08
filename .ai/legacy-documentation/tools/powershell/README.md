# 工具 —— PowerShell

本函式庫中屬於「決定性」的那一半，為 PowerShell 7 而寫。
`tools/shell/` 是同一套工具的 POSIX `sh` + `awk` 版本；
兩者產出逐位元組相同的 factbase，任選其一即可。見 `tools/README.md`。

只需要 PowerShell 7 與 .NET，別無其他。不需安裝模組、沒有建置步驟、
不需要網路。`javap`、`javac` 與 `jar` 在存在時會被使用，
缺席時則如實回報，而不是繞過去。

這裡的每一項工具，回答的都是「語言模型閱讀原始碼時會答得看似合理、
但有時是錯的」那類問題。見 `shared/fact-layer.md`。

---

## Layer 1 —— 事實

| 工具 | 功能 |
|---|---|
| `lib/mask.ps1` | 遮蔽註解與常值。以 dot-source 載入，絕不直接執行。 |
| `factbase/extract_java.ps1` | 掃描器：在遮蔽後的原始碼上維護框架堆疊。原始碼樹 -> `docs/facts/*.psv` |
| `factbase/hierarchy.ps1` | 名稱解析與遞移閉包。 |
| `factbase/resolve_calls.ps1` | 呼叫點 -> 目標型別（在無歧義時）。 |
| `factbase/build_factbase.ps1` | 執行上述兩者；寫出 `supertype.psv`、`ancestor.psv`、`calls-resolved.psv` |
| `factbase/verify_bytecode.ps1` | 獨立判準：`javap` 對照 factbase |
| `verification_tier.ps1` | 記錄本次執行的驗證實際上有多強 |

## Layer 2 —— 結構

| 工具 | 功能 |
|---|---|
| `factbase/enumerate.ps1` | factbase -> 三份列舉主清單 |
| `factbase/prioritize.ps1` | 可達性 + git 變更頻率 + 使用量 -> `priority.txt` |
| `factbase/archetypes.ps1` | clone 分群 -> `archetypes.txt` |
| `factbase/domain_variables.ps1` | DB 欄位、輸入欄位、組態鍵 |
| `reflexion/reflexion.ps1` | 某個人的模組地圖對照呼叫圖 |

## 驗證

| 工具 | 功能 |
|---|---|
| `verify/depth_checks.ps1` | 逐單元執行四項深度檢查 -> `depth-report.md` |
| `verify/staleness.ps1` | 把文件綁定到原始碼版本；支援增量重跑 |
| `chartest/gen_skeletons.ps1` | 已記錄的分支 -> 可執行的測試骨架 |

## 自我測試

    pwsh tools/powershell/selftest.ps1

對 `examples/fixtures/java-dispatcher` 執行整條工具鏈，並與 `expected/` 比對
—— 與 shell 那一半比對的是同一批檔案。共 24 項檢查，
其中三項「必須」失敗或被阻斷：一份看似合理但錯誤的文件、
一個從 factbase 中缺席的類別，以及一個與掃描不一致的判準。
若某項工具變更改動了預期輸出，在那些檔案被刻意更新之前，一律視為迴歸。

---

## factbase

與 shell 那一半完全相同，逐位元組一致。純文字、以管線符號分隔，
一行一筆記錄，無標題列。可 grep、可 diff，也可在 pull request 中審閱。
欄位清單見 `tools/shell/README.md`。

用 `Import-Csv` 查詢它，不需要你自己做任何解析：

    # 任意深度下 StdTrxObject 的所有子類別
    Import-Csv docs/facts/ancestor.psv -Delimiter '|' -Header type,ancestor,depth |
        Where-Object { $_.ancestor -ceq 'EXTERNAL:StdTrxObject' } |
        Select-Object type, depth

    # 決策點超過 10 個的公開方法
    $h = 'type,name,path,line,endLine,ctor,public,abstract,inAnon,' +
         'if,for,while,case,catch,and,or,ternary,total,mods'
    Import-Csv docs/facts/methods.psv -Delimiter '|' -Header $h.Split(',') |
        Where-Object { $_.public -eq 1 -and [int]$_.total -gt 10 } |
        Select-Object type, name, total

---

## 順序

    extract_java.ps1  ->  build_factbase.ps1  ->  verify_bytecode.ps1
                                                   ->  verification_tier.ps1
                                                 ->  enumerate.ps1
                                                   ->  prioritize.ps1
                                                   ->  archetypes.ps1
                                                   ->  domain_variables.ps1
                                                 ->  reflexion.ps1

    （撰寫文件）

    ->  depth_checks.ps1  ->  staleness.ps1 -Record
    ->  gen_skeletons.ps1

---

## 完整範例

    $REPO = 'C:\path\to\legacy-app'

    pwsh tools/powershell/factbase/extract_java.ps1 -Repo $REPO `
        -Out $REPO\docs\facts -SourceRoot src/main/java
    pwsh tools/powershell/factbase/build_factbase.ps1 -Facts $REPO\docs\facts
    pwsh tools/powershell/factbase/verify_bytecode.ps1 -Repo $REPO `
        -Facts $REPO\docs\facts `
        -Out $REPO\docs\facts\bytecode-verification.md

    pwsh tools/powershell/verification_tier.ps1 -Facts $REPO\docs\facts `
        -Out $REPO\docs\verification-tier.txt

    pwsh tools/powershell/factbase/enumerate.ps1 `
        -Facts $REPO\docs\facts -Out $REPO\docs\enumeration
    pwsh tools/powershell/factbase/prioritize.ps1 -Repo $REPO `
        -Facts $REPO\docs\facts -Enumeration $REPO\docs\enumeration
    pwsh tools/powershell/factbase/archetypes.ps1 -Repo $REPO `
        -Facts $REPO\docs\facts -Enumeration $REPO\docs\enumeration

接著撰寫文件，然後：

    pwsh tools/powershell/verify/depth_checks.ps1 -Repo $REPO `
        -Facts $REPO\docs\facts `
        -Docs $REPO\docs\modules\transactions `
        -Enumeration $REPO\docs\enumeration `
        -Out $REPO\docs\gap-analysis\depth-report.md

shell 那一半的每一個 `--option value`，在這裡都是 `-Option value`；
不帶引數的 shell 旗標（例如 `--record` 或 `--strict`）在這裡是 switch：
`-Record`、`-Strict`。shell 那一半可重複給多次的選項，在這裡接受陣列：
`-SourceRoot src/main/java, src/gen/java`。

---

## 可移植性

為 PowerShell 7 而寫，可在任何它能執行的平台上使用。
已在 macOS 上的 PowerShell 7.4 實測。「不」支援 Windows PowerShell 5.1：
本程式碼使用 PS7 的 class 語法、`[System.Comparison[string]]` 委派，
以及雖不用三元運算子、但仍是 PS7 形狀的管線寫法，
而且 5.1 還會改變檔案編碼。

有三項 PowerShell 預設行為會毀掉 factbase，這裡完全沒有使用它們。
在修改程式碼之前值得先知道：

* **行尾與編碼。** `Out-File` 與 `Set-Content` 會寫入平台的行尾字元，
  而 Windows PowerShell 還會加上 BOM。這裡的每一個檔案都由
  `Write-TextLines` 寫出，它在任何平台上都寫 LF 與不含 BOM 的 UTF-8。
  正是這一點，讓在 Windows 上建立的 factbase 能與在 macOS 上建立的乾淨 diff。
* **排序。** `Sort-Object` 以目前的文化設定比較字串。
  這裡的每一次排序都是 ordinal，也就是 `LC_ALL=C sort` 的行為，
  因此記錄順序不會取決於機器的地區設定。
* **正規表示式。** `-match`、`-replace` 與 `-eq` 預設「不」區分大小寫；
  awk 則不是這樣。凡是 awk 會區分大小寫進行的比較，
  在這裡都寫成 `-cmatch`、`-creplace` 或 `-ceq`。

另外兩項比較不明顯的：

* `.NET` 在 Windows 上回傳的是以反斜線分隔的路徑。
  記錄進 factbase 的每一個路徑都會轉換成正斜線，
  因為路徑是文件與報告用來比對的鍵。
* PowerShell 的逗號結合力比 `+` 強，因此 `@($a, $n + 1)` 會建出
  三個元素的陣列，而不是一組配對。陣列常值中的算術運算一律加上括號。

---

## 限制

與 shell 那一半相同的限制，理由也相同。

`extract_java.ps1` 是在遮蔽後的原始碼上運作的詞法掃描器。
它不解析泛型、多載或型別。它會把無法解析的東西標示出來，而不是猜測；
而 bytecode 判準之所以存在，正是因為「單靠詞法掃描器」不該被信任來做列舉。

Text block（`""" ... """`）不會被遮蔽。老舊程式碼早於這項語法。

目前只支援 Java。新增一種語言需要一個新的 Layer 1 抽取器，發出相同的記錄格式。
Layer 1 之上的一切都不需要改動。

與 shell 那一半有一項刻意的差異：讀取檔案時會去掉行尾的 CR，
因此在以 CRLF 行尾簽出的儲存庫上，摘錄仍然能夠比對成功。
awk 會保留該 CR 並回報不符。

速度是這次移植的代價。掃描器是在 PowerShell 中逐字元走訪遮蔽後的原始碼，
而不是在 awk 中；而 clone 分群在兩邊都與單元數量呈平方關係。
在大型原始碼樹上，shell 那一半較快；
但在沒有 awk 的 Windows 上，這一半是唯一的選擇。
