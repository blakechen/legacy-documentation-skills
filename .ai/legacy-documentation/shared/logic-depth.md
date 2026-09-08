# 邏輯深度原則

## 目標

確保每個主要單元的文件解釋程式「如何」運作，而不只是它「碰到了哪些」產出物。

---

## 規則

對「每一個」主要單元（交易類別、controller、批次工作），以及該單元的「每一個」公開方法，
文件「應當」包含全部四項深度要素：

1. Processing Flow —— 逐步編號的敘事

2. Pseudocode —— 以與語言無關的方式重述該方法

3. Key Source Excerpts —— 附檔案路徑與行號的原始碼引文

4. Field Mapping —— 從輸入欄位到變數，再到資料庫欄位或訊息欄位

一張事實表格（方法名稱加上一行說明）「不」滿足本規則。

> 上列四個小節標題、以及本文件中標為「字面句」的句子，
> 都會被 `tools/shell/verify/depth_checks.sh` 逐字比對，
> 因此在產生的文件中一律維持英文原文，不得翻譯。

---

## 1. Processing Flow

編號步驟。每個方法至少 3 個步驟。

若某個方法確實沒有任何分支，寫下這句字面句：

`Method body contains no branching logic; it only <observed action>.`

每個步驟「應當」至少陳述下列其中一項：

- 它讀了什麼（請求參數、session 屬性、資料庫資料列、組態鍵）

- 它檢查了什麼（條件本身，以及成立與不成立時各自會發生什麼）

- 它呼叫了什麼（class.method、SQL 敘述、外部系統）

- 它寫了什麼（資料庫欄位、session 屬性、輸出欄位、log）

- 它接下來去哪裡（下一個狀態、JSP、轉導、例外）

永遠要寫出分支的結果。絕不要只寫一個光禿禿的動詞。

不良

```
1. 驗證輸入。
```

良好

```
1. 讀取請求參數 TRSFAMT 並解析為 BigDecimal。
2. 若 TRSFAMT 大於自 LIMIT_CTL.DAILY_MAX 讀出的每日上限，設定錯誤碼 E0031
   並回傳 prompt 狀態；否則繼續執行步驟 3。
3. 以解析後的金額與自 session 讀出的帳號呼叫 TransferService.execute。
```

---

## 2. Pseudocode

每個方法一個 fenced 區塊。

與語言無關。不出現 Java、COBOL 或框架 API 名稱。

使用 READ / WRITE / IF / ELSE / FOR EACH / CALL / RETURN。
（這些關鍵字由工具比對，維持英文。）

虛擬碼「應當」涵蓋原始碼中出現的每一個分支。

虛擬碼「不得」引入原始碼中不存在的邏輯。

---

## 3. Key Source Excerpts

對每一個關鍵決策、計算與 SQL 敘述引用原始碼。

格式

`path/to/File.java:120-128`

```java
<逐字的原始碼行>
```

凡是含有分支、計算或 SQL 敘述的方法，至少要有一段摘錄。

三者皆無的方法，則記下這句字面句：

`No critical logic; no excerpt required.`

摘錄「應當」逐字照抄。絕不在程式碼區塊內改寫。

摘錄「應當」簡短，通常少於 30 行。引用的是那個決策，不是整個檔案。

---

## 4. Field Mapping

| Input Field | Source | Intermediate | Transformation | Target | Target Kind |
|-------------|--------|--------------|----------------|--------|-------------|

Target Kind 為下列其中之一

DB column

external message field

session attribute

output page field

log

若該方法沒有搬動任何資料，寫下這一列

`| None | - | - | - | - | - |`

---

## 適用範圍

`docs/modules/transactions/<Class>.md`

負責者：module-analysis。四項要素全備。

`docs/specifications/transactions/<Class>.md`

負責者：specification-generation。Processing Flow、Pseudocode 與 Field Mapping 沿用；
原始碼摘錄則以指向模組文件的參照取代。

---

## 反模式

用一列表格總結一個方法，是「被禁止」的。

寫「處理轉帳邏輯」卻不指名欄位、條件與目標，是「被禁止」的。

因為單元數量龐大而省略深度，是「被禁止」的。請改用分批。

為了讓文件簡短而降低深度，是「被禁止」的。篇幅長不是缺陷。

---

## 深度完備的定義

當下列全部條件成立時，單元文件即為「深度完備（DEPTH-COMPLETE）」。

1. State Methods 索引中列出的每一個公開方法，都有對應的 `### Method: <name>` 小節。

2. `### Method:` 小節的數量等於原始碼類別中宣告的公開方法數量。

3. 每個方法小節都有一個至少 3 個編號步驟的 Processing Flow，或有那句明確的簡單方法字面句。

4. 每個方法小節都有一個非空的 Pseudocode fenced 區塊。

5. 每個方法小節都至少有一段帶 `path:line-line` 的原始碼摘錄，或有那句明確的無關鍵邏輯字面句。

6. 每個方法小節都有一張至少一列的 Field Mapping 表。允許使用 None 那一列。

未達深度完備的單元「不」計入已完成文件，無論其檔案是否存在。

---

## 驗證

深度完備由程式判定，而不是靠閱讀。

    sh tools/shell/verify/depth_checks.sh \
        --repo <repo> --facts <repo>/docs/facts \
        --docs <repo>/docs/modules/transactions \
        --enumeration <repo>/docs/enumeration \
        --out <repo>/docs/gap-analysis/depth-report.md

四項檢查，說明於 shared/mechanical-verification.md：

| 檢查 | 判定內容 |
|---|---|
| structure | 上述六項條件，方法清單取自 factbase |
| excerpts | 每個引用區塊與其所引之行完全逐位元組相同 |
| branches | 虛擬碼分支數與原始碼決策點數量一致 |
| fields | 每個對應欄位都存在於該方法中；每張資料表都已被列舉 |

深度完備率 ＝ 深度完備單元數 ÷ 列舉檔行數。

只有當該比率為 100%「且」工具以 0 結束時，流水線才算完成。

沒有實際執行工具就宣稱的比率，不是比率。

在層級 C 之下工具無法執行，因此沒有比率。請回報
`Depth-Complete Rate: NOT MEASURED (Tier C)`，以及兩個「確實」可知的數字：
有文件的單元數，以及文件曾對照原始碼檢查過的單元數（該數為零）。
估算比率是「被禁止」的。
見 shared/verification-tiers.md。

### 通過檢查不代表什麼

這些檢查判定的是「與所引原始碼一致」。它們不判定業務意義是否正確。
一份文件可以通過每一項檢查，卻仍在正確引用一個方法的同時，把它的用途講錯。

通過的執行結果應回報為「consistent with source; meaning not verified」。

### 差異文件

多成員原型中的成員，是以對照其代表單元的差異文件形式記錄。
見 shared/archetypes.md。它的完成判準是差異表的完整性
與它自己的 Field Mapping，而不是把四項要素全部重述一遍。

---

## 經驗教訓

### 問題：覆蓋率設了關卡，深度沒設關卡

列舉與逐步深化讓流水線為每個類別產出了一個檔案，
但每個檔案都只是一堆事實表格。讀者無法理解程式做了什麼。
唯一的完成檢查只有「檔案是否存在」。

**修正**：完成度以上述「深度完備的定義」衡量，而不是以檔案數量衡量。
落差分析會逐單元回報深度失敗項目。

### 問題：以深度換取廣度

面對 400 個以上的單元時，代理人把每一份文件都縮短，
而不是把較少的單元完整記錄下來。

**修正**：分批。六份深度完備的文件勝過 458 份淺薄的文件。
將剩餘單元記錄於 `docs/gap-analysis/progress.md`。
