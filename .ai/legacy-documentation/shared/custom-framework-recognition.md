# 自製框架辨識

## 目標

老舊系統經常使用自製或專有框架，而非知名框架（Spring、Jakarta EE）。
各 Skill「應當」辨識並記錄這些模式。

---

## 偵測規則

### 自製 Dispatcher 模式

若有單一 Servlet 接收所有請求，並依據某個參數（例如 `trx`、`action`、`command`）路由到交易類別：

- 指出 dispatcher 類別。

- 指出路由參數。

- 指出交易基底類別。

- 列舉「所有」已註冊或被參照的交易類別。

### 自製 ORM 模式

若資料庫存取使用的是帶有程式化欄位定義的基底類別（例如 `addField()`、`setTargetTable()`）而非 annotation：

- 指出 DB 物件基底類別。

- 列舉「所有」子類別。

- 從 `setTargetTable()` 取出資料表名稱。

- 從 `addField()` 呼叫取出欄位定義。

- 由程式碼重建 schema。

### 自製組態模式

若組態是從自訂路徑載入（例如 `ConfigManager.load("/usr/hncb/config/init")`）：

- 指出組態載入器。

- 列舉「所有」properties 檔案。

- 將 properties 檔案對應到使用它們的模組。

---

## 證據

在記錄自製框架時，永遠要記下：

- 基底類別名稱

- 探索模式（子類別是如何被找出來的）

- 註冊機制

- 組態來源

---

## 反模式

在自製框架確實存在時回報「未偵測到框架」，是「錯誤」的。

因為框架不是知名框架就略過分析，是「被禁止」的。

---

## 經驗教訓

### 問題：偵測到自製框架，卻沒有拿來驅動列舉

AI 正確地辨識出 `TrxDispatcher` + `TrxFactory` + `StdTrxObject` 是一套自製框架，
卻沒有用這項資訊去驅動一次完整的列舉，而是給了大約的數量後就繼續往下走。

**修正**：一旦偵測到自製框架，「下一個」強制步驟是：
1. 將偵測結果寫入 `docs/enumeration/framework-detection.md`
2. 以基底類別名稱（例如 `StdTrxObject`）作為 grep 樣式，產出完整的列舉檔
3. 在列舉檔寫出之前，「不得」進入 Phase 2

### 問題：基底類別位於外部 jar

當基底類別（`StdTrxObject`）不在原始碼樹中（而在外部 jar 裡）時，AI 無法讀到它的原始碼。
這「不能」成為略過子類別列舉的藉口。

**修正**：在整個原始碼樹中搜尋 `extends [BaseClassName]`。
列舉並不需要基底類別的原始碼，只需要子類別中的 `extends` 關鍵字。
