# 列舉優先原則

## 目標

在產生任何文件之前，先建立目標產出物的完整清冊。

---

## 規則

每個會產生「逐項文件」的 Skill「應當」

1. 先列舉目標類型的「所有」項目。

2. 記錄每個項目的位置與證據。

3. 然後走訪「每一個」項目以產生其文件。

4. 絕不在抽樣幾個項目之後就停止。

---

## 範例

### 交易類別

列舉每一個繼承交易基底類別，或被 dispatcher 參照的類別。

每個交易類別產生一份文件。

### 資料庫物件

列舉每一個繼承 DB 物件基底類別的類別。

每個 DB 物件產生一筆資料表條目。

### Servlet

列舉每一個繼承 HttpServlet 或在組態中被對應的類別。

---

## 反模式

掃描少數代表性檔案後就一般化，是「被禁止」的。

在前 3 到 5 個發現之後就停止，是「被禁止」的。

以單一摘要取代逐項文件，是「被禁止」的。

---

## 列舉是一次查詢，不是一次搜尋

主清單是由 `tools/shell/factbase/enumerate.sh` 從 `fact-extraction` Skill
所建立的 factbase 產生。見 shared/fact-layer.md。

Skill「不得」以 grep `extends <Base>` 的方式建立列舉。

文字搜尋做不到、但列舉必須做到的三件事：

### 遞移繼承

`A extends B`、`B extends StdTrxObject`。搜尋 `extends StdTrxObject`
只會回傳 B，而漏掉 A。factbase 儲存了階層的遞移閉包，
因此 A 會在深度 2 被找到。列舉報告會記錄每一筆條目的深度；
任何深度 > 1 的條目，都是文字搜尋會漏掉的條目。

### 外部基底類別

當基底類別隨 jar 一起出貨時，沒有原始碼可讀。閉包仍然成立：
未解析的父型別會成為一個 `EXTERNAL:<SimpleName>` 節點，
而其下的每一個類別依然會被列舉。

### 反射註冊

`Class.forName(prefix + code)` 在原始碼文字中並未指名任何類別。
列舉會把字串常值與型別表比對，並記錄哪些條目是以此方式找到的，
以及哪些常值根本沒有指到任何已知類別。
指不到任何東西的常值本身就是一項發現：
可能是掃描根目錄之外的類別，也可能是失效的註冊。

---

## 驗證

數量必須由「獨立」來源確認，而不是由第二次搜尋確認。

    tools/shell/factbase/verify_bytecode.sh

會以 `javap` 讀取編譯後的 class 與 jar，並將每個類別的真實父型別與 factbase 比對。
兩者不共用任何程式碼，且讀取的輸入來源不同。

用不同的正規表示式再跑一次類似的搜尋，並不是獨立驗證。
那是同一種方法把同一個錯誤犯了兩次。

若不存在任何編譯產出物，判準會記錄 `UNAVAILABLE`，
而列舉報告「應當」聲明該結果僅立基於詞法抽取。
該次執行「不得」使用「verified（已驗證）」一詞。那屬於層級 B。

若列舉根本無法以查詢方式取得 —— 在此環境中無法執行任何指令 ——
該次執行屬於層級 C。列舉是靠閱讀產生的，
而報告「應當」附上 shared/verification-tiers.md 中的揭露聲明，
指明閱讀無法檢查的三件事：遞移繼承、樹外基底類別，以及反射註冊。
在本函式庫自己的 fixture 上，單純的文字搜尋只找得到 6 個交易類別中的 3 個。

---

## 強制輸出產出物

列舉「必須」產生持久化的檔案（而不只是記憶中的知識）：

- `docs/enumeration/transaction-classes.txt`
- `docs/enumeration/db-object-classes.txt`
- `docs/enumeration/servlet-classes.txt`

格式：

- `transaction-classes.txt` — `ClassName|relative/path/to/File.java`
- `servlet-classes.txt` — `ClassName|relative/path/to/File.java`
- `db-object-classes.txt` — `ClassName|relative/path/to/File.java|TargetTable`

當目標資料表無法判定時，寫 `UNKNOWN`。絕不省略該欄位。

這些檔案由 `artifact-enumeration` Skill 擁有。

本檔案是所有下游 Skill 的**關卡**。在列舉檔存在且行數不為零之前，
任何下游 Skill 都不得開始。

---

## 經驗教訓

### 問題：辨識出了列舉，卻沒有持久化

實務上，AI 可能在分析過程中得出數量（例如「約 467 個交易類別」），
卻沒有把可被機器讀取的主清單持久化。下游 Skill 於是沒有權威來源可供走訪。

**修正**：列舉步驟「必須」把檔案寫到磁碟。驗證條件＝檔案存在「且」行數 > 0。

### 問題：以概略計數取代確切清單

用 `grep -c` 之類的方式取得一個數字，「不是」列舉。
列舉需要的是實際的類別名稱與路徑清單。

**修正**：永遠輸出 `ClassName|Path` 配對，而不只是一個數字。

### 問題：單趟完成的假設

對大型程式碼庫（400 個以上的產出物）而言，單一 AI 上下文視窗可能無法在一趟之內
完成所有項目的列舉與文件撰寫。

**修正**：列舉與文件撰寫是分開的步驟。列舉先完成。
文件撰寫可以分批跨多趟進行，並以列舉檔為依據。
