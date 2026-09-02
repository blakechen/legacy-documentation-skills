# 列舉優先原則（Enumeration-First Principle）

## 目標

在產生任何文件之前，先建立一份目標產出物的完整清冊。

---

## 規則

每個會產生「逐項文件」的 Skill 都應

1. 首先列舉目標類型的「所有」項目。

2. 記錄每個項目的位置與證據。

3. 接著逐一走過「每一個」項目來產生其文件。

4. 絕不在抽樣幾個項目後就停止。

---

## 範例

### 交易類別

列舉每一個繼承自交易基底類別、或被 dispatcher 引用的類別。

每個交易類別產生一份文件。

### 資料庫物件

列舉每一個繼承自資料庫物件基底類別的類別。

每個資料庫物件產生一筆資料表條目。

### Servlet

列舉每一個繼承 HttpServlet、或在組態中被對應（mapping）的類別。

---

## 反面模式（Anti-Pattern）

只掃描少數代表性檔案就一般化，是「禁止」的。

在找到前 3-5 個結果後就停止，是「禁止」的。

以單一份摘要取代逐項文件，是「禁止」的。

---

## 驗證

列舉清單的數量必須與該產出物類型的實際檔案數量相符。

若兩者不符，重新掃描。

---

## 必要輸出產出物

列舉「必須」產出一個持久化的檔案（不能只是留在記憶中的認知）：

- `docs/enumeration/transaction-classes.txt`
- `docs/enumeration/db-object-classes.txt`
- `docs/enumeration/servlet-classes.txt`

格式：

- `transaction-classes.txt` — `ClassName|relative/path/to/File.java`
- `servlet-classes.txt` — `ClassName|relative/path/to/File.java`
- `db-object-classes.txt` — `ClassName|relative/path/to/File.java|TargetTable`

無法判定目標資料表時寫 `UNKNOWN`，不得省略該欄位。

這些檔案由 `artifact-enumeration` Skill 負責產生。

這個檔案是所有下游 Skill 的**關卡**。
在列舉檔案存在且數量非零之前，任何下游 Skill 都不得開始。

---

## 經驗教訓

### 問題：已辨識出列舉結果，卻沒有持久化

實務上，AI 可能在分析過程中辨識出數量（例如「約 467 個交易類別」），
卻沒有把可供機器讀取的主清單寫成檔案。
下游 Skill 因此沒有權威來源可供逐項迭代。

**修正**：列舉步驟「必須」把檔案寫到磁碟。驗證方式＝檔案存在「且」行數 > 0。

### 問題：以概略數量取代精確清單

使用 `grep -c` 之類的方式取得數量「不算」列舉。列舉需要的是實際的類別名稱與路徑清單。

**修正**：一律輸出 `ClassName|Path` 配對，而不只是一個數字。

### 問題：假設能一次做完

對大型程式碼庫（400 個以上的產出物），單一個 AI 上下文視窗可能無法在一回合內完成列舉與所有文件。

**修正**：列舉與文件產出是兩個分開的步驟。列舉先完成。
文件產出可以跨多個回合分批進行，並以列舉檔案為依據。
