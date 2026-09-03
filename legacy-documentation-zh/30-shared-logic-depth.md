# 邏輯深度原則（Logic Depth Principle）

## 目標

確保每個主要單元的文件說明程式「如何」運作，而不只是它「碰到」哪些產出物。

---

## 規則

針對「每一個」主要單元（交易類別、controller、批次工作），
以及該單元的「每一個」public method，文件都應包含以下四項深度要素：

1. 處理流程（Processing Flow）－ 編號的逐步敘述

2. 虛擬碼（Pseudocode）－ 語言中立的邏輯重述

3. 關鍵原始碼引用（Key Source Excerpts）－ 附檔案路徑與行號的程式碼引用

4. 欄位對應（Field Mapping）－ 輸入欄位 → 變數 → 資料庫欄位或電文欄位

一張事實表格（方法名稱加上一行描述）「不」滿足本規則。

---

## 1. 處理流程

採用編號步驟。每個方法至少 3 個步驟。

若某個方法確實沒有任何分支，就寫下這句固定文字：

`Method body contains no branching logic; it only <observed action>.`

每個步驟至少要說明下列其中一項：

- 它讀取什麼（request 參數、session 屬性、資料庫資料列、組態鍵值）

- 它檢查什麼（條件本身，以及成立與不成立時各自會發生什麼）

- 它呼叫什麼（class.method、SQL 敘述、外部系統）

- 它寫入什麼（資料庫欄位、session 屬性、輸出欄位、log）

- 它接下來去哪裡（下一個狀態、JSP、轉導、例外）

一律寫出分支的結果。絕不只寫一個空泛的動詞。

不良範例

```
1. Validates the input.
```

良好範例

```
1. Reads request parameter TRSFAMT and parses it to BigDecimal.
2. If TRSFAMT > the daily limit read from LIMIT_CTL.DAILY_MAX, sets error code E0031
   and returns state prompt; otherwise continues to step 3.
3. Calls TransferService.execute with the parsed amount and the account read from session.
```

---

## 2. 虛擬碼

每個方法一個圍欄式程式碼區塊。

語言中立。不出現 Java、COBOL 或框架的 API 名稱。

使用 READ／WRITE／IF／ELSE／FOR EACH／CALL／RETURN。

虛擬碼應涵蓋原始碼中存在的「每一個」分支。

虛擬碼不得引入原始碼中沒有的邏輯。

---

## 3. 關鍵原始碼引用

針對每一個關鍵判斷、計算與 SQL 敘述，都要引用原始碼。

格式

`path/to/File.java:120-128`

```java
<逐字的原始碼行>
```

凡是包含分支、計算或 SQL 敘述的方法，至少要有一段引用。

三者皆無的方法，寫下這句固定文字：

`No critical logic; no excerpt required.`

引用必須逐字照錄。絕不在程式碼區塊內改寫。

引用應精簡，通常在 30 行以內。引用的是「那個判斷」，不是整個檔案。

---

## 4. 欄位對應

| Input Field | Source | Intermediate | Transformation | Target | Target Kind |
|-------------|--------|--------------|----------------|--------|-------------|

Target Kind 限定為下列其中之一

DB column（資料庫欄位）

external message field（外部電文欄位）

session attribute（session 屬性）

output page field（輸出頁面欄位）

log

若該方法沒有搬移任何資料，寫入單一列

`| None | - | - | - | - | - |`

---

## 適用範圍

`docs/modules/transactions/<Class>.md`

擁有者：module-analysis。四項要素全部都要有。

`docs/specifications/transactions/<Class>.md`

由 specification-generation 負責。處理流程、虛擬碼與欄位對應要往下承接。
原始碼引用則改為指向模組文件的參照。

---

## 反面模式（Anti-Pattern）

用一列表格帶過一個方法，是「禁止」的。

寫「handles the transfer logic」卻不指名欄位、條件與目標，是「禁止」的。

因為單元數量太多而省略深度，是「禁止」的。應改用分批處理。

為了讓文件短一點而降低深度，是「禁止」的。篇幅長不是缺陷。

---

## 深度完備的定義（Definition of Depth-Complete）

一份單元文件在「全部」滿足下列條件時，才算深度完備。

1. State Methods 索引中列出的每一個 public method，都有對應的 `### Method: <name>` 子章節。

2. `### Method:` 子章節的數量，等於原始碼類別中宣告的 public method 數量。

3. 每個方法子章節都有至少 3 個編號步驟的處理流程，或那句「無分支方法」的固定文字。

4. 每個方法子章節都有非空的虛擬碼圍欄區塊。

5. 每個方法子章節都有至少一段附 `path:line-line` 的原始碼引用，
   或那句「無關鍵邏輯」的固定文字。

6. 每個方法子章節都有至少一列的欄位對應表格（允許 None 那一列）。

未達深度完備的單元「不計入」已完成，無論其檔案是否存在。

---

## 驗證

深度完備由程式判定，不是靠閱讀。

    python3 tools/verify/run_depth_checks.py \
        --repo <repo> --db <repo>/docs/facts/factbase.sqlite \
        --docs <repo>/docs/modules/transactions \
        --enumeration <repo>/docs/enumeration \
        --out <repo>/docs/gap-analysis/depth-report.md

四項檢查，說明於 shared/mechanical-verification.md：

| 檢查 | 判定內容 |
|---|---|
| structure | 上述六項條件，方法清單取自 factbase |
| excerpts | 每段引文與其標示行號逐位元組相符 |
| branches | 虛擬碼分支數與原始碼判斷點數一致 |
| fields | 每個對應欄位存在於方法中；每個資料表都已被列舉 |

深度完備率 = 深度完備單元數 / 列舉檔案行數。

唯有比率為 100% 且工具 exit 0 時，管線才算完成。

沒有執行工具就宣稱的比率，不是比率。

### 通過「不」代表什麼

這些檢查判定的是「與所引用之原始碼的一致性」，
不判定業務意義是否正確。
一份文件可以通過每一項檢查，卻仍以錯誤的用途
描述一個被正確引用的方法。

通過的執行結果應報告為「與原始碼一致；意義未驗證」。

### 差異文件

多成員原型的成員，以差異文件對照其代表單元撰寫。
見 shared/archetypes.md。
其完成條件是差異表與自身 Field Mapping 的完整性，
而不是重述四項元素。


## 經驗教訓

### 問題：涵蓋率有關卡，深度沒有關卡

列舉優先與迭代深度讓管線確實做到每個類別一個檔案，
但每個檔案都只是一組事實表格。讀者無法理解程式究竟做了什麼。
唯一的完成檢查就只有「檔案存不存在」。

**修正**：完成與否是用上面的「深度完備定義」來衡量，不是用檔案數量。
落差分析會逐單元回報深度不合格的項目。

### 問題：為了廣度而犧牲深度

面對 400 個以上的單元時，AI 把每份文件都寫短，
而不是「少做幾個單元、但每個都做完整」。

**修正**：分批。六份深度完備的文件，勝過 458 份淺薄的文件。
把剩餘單元記錄在 `docs/gap-analysis/progress.md`。
