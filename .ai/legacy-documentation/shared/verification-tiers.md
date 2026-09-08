# 驗證層級

## 目標

讓一次執行的驗證強度變得明確，使得在沒有驗證的情況下產出的文件，
不會被誤認為是通過驗證的文件。

---

## 問題所在

本函式庫的關卡都是指令。在一個什麼都無法執行的環境裡，
每一道關卡都會無聲地從「檢查」退化成「宣稱」，
而輸出看起來卻與完整驗證過的執行一模一樣。

那比完全沒有驗證更糟：一份讀起來像是已驗證的報告，會被相信。

---

## 各層級

| 層級 | 條件 | 該次執行可以宣稱什麼 |
|---|---|---|
| **A** | 已建立 factbase「且」bytecode 判準回報 `VERIFIED` | 「Consistent with source; meaning not verified」 |
| **B** | 已建立 factbase，判準回報 `UNAVAILABLE` | 「Consistent with source as read lexically; not independently verified」 |
| **C** | 在此環境中無法執行指令 | 「VERIFICATION: NONE」 |

判準狀態為 `FAILED` 時不構成任何層級。它會「阻斷」流水線。

---

## 宣告層級

層級在 Phase 1 之前確立一次，並持久化：

`docs/verification-tier.txt`

    tier|<A|B|C>
    reason|<one line>
    factbase|<PRESENT|ABSENT>
    oracle|<VERIFIED|UNAVAILABLE|NOT RUN>
    depth_checks|<RUN|NOT RUN>
    staleness|<RUN|NOT RUN>
    declared|<date>

在層級 A 與 B 之下，此檔由 `tools/shell/verification_tier.sh` 寫出。
在層級 C 之下，由分析師手寫，且 `reason` 那一行要指明具體限制
（沒有 shell、無法執行檔案、唯讀沙箱）。

每一份產生的文件「應當」在其中繼資料區塊中載明層級：

    Verification tier: B

沒有層級這一行的文件，一律視為層級 C。

---

## 層級 C：仍然適用的部分

本函式庫中屬於「方法」而非「量測」的一切：

- `shared/enumeration-first.md` —— 先列舉再撰寫文件；絕不抽樣
- `shared/iterative-depth.md` —— 在系統的主要單元層級撰寫文件
- `shared/logic-depth.md` —— 每個方法的四項深度要素
- `shared/business-rule-criteria.md` —— 領域變數判定測試
- `shared/archetypes.md` —— 代表單元加上差異文件
- `shared/prioritization.md` —— 以可達性、變更頻率與使用量決定順序
- `shared/reflexion-model.md` —— 假說地圖及其三種結果
- `shared/evidence-rules.md` —— 引用規則

這些才是本函式庫的實質內容。它們都不需要任何程式。

---

## 層級 C：「不」適用的部分

下列各項「不得」被宣稱、陳述或暗示：

- 列舉是完整的
- 任何形式的深度完備率，包括「大約」
- 任何摘錄曾對照其原始碼檢查過
- 任何數量已經過驗證
- 文件與現行原始碼保持同步
- 對本次執行所產生的任何產出物使用 **verified**、**confirmed**、
  **exhaustive**、**complete** 或 **100%** 等字眼

---

## 層級 C：強制揭露

在層級 C 之下產出的每一份索引、報告與摘要，「應當」以下列文字開頭：

    VERIFICATION: NONE
    This run could not execute the verification tools. Counts, coverage and
    depth are unverified claims, not measurements.

列舉報告「應當」額外聲明：

    The enumeration was produced by reading. It has NOT been checked for:
    - transitive inheritance (a class reached only through an intermediate
      base class)
    - subclasses of a base class that ships outside the source tree
    - classes registered by reflection, named only in a string literal
    Any of these may be missing, and this run cannot say which.

落差分析「不得」回報深度完備率。它改為回報：

    Depth-Complete Rate: NOT MEASURED (Tier C)
    Units with a document: N of M
    Units whose document was checked against source: 0

---

## 層級 C：信心度上限

在層級 C 之下產生的任何發現，都不得帶有 **High** 信心度。

`shared/confidence-scoring.md` 中的 High 是由 factbase 中的事實
或經判準確認的事實推導而來。層級 C 兩者皆無，
因此足以支撐 High 的證據依定義就是缺席的。

上限為 Medium。Unknown 依然可用，也依然是較好的選擇。

---

## 升級

層級 C 的執行不是白費工。當同一個儲存庫日後在可執行指令的環境中被分析時：

1. 建立 factbase 並執行判準。
2. 將層級 C 的列舉與查詢得出的列舉相比較。其差異就是
   「靠閱讀會漏掉多少」的直接量測結果，且「應當」記錄下來。
3. 對既有文件執行深度檢查。失敗的重新產生。
4. 為每一份文件重新蓋上新的層級戳記。

第 2 步本身就值得做。那是本函式庫唯一能了解
「在真實系統上，閱讀與解析之間的落差究竟有多大」的方式。

---

## 反模式

產出層級 C 的文件卻省略揭露聲明，是「被禁止」的。

在層級 C 之下估算深度完備率，是「被禁止」的。
對一項量測的估算不是量測；那正是本函式庫為了防止而生的失敗模式，
只是穿上了解方的措辭。
