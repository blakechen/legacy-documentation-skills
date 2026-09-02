# 自訂框架辨識（Custom Framework Recognition）

## 目標

舊有系統經常使用自訂或專有框架，而非知名框架（Spring、Jakarta EE）。
各 Skill 應辨識並記錄這些模式。

---

## 偵測規則

### 自訂 Dispatcher 模式

若由單一個 Servlet 接收所有請求，並依據某個參數（例如 `trx`、`action`、`command`）路由到交易類別：

- 辨識出 dispatcher 類別。

- 辨識出路由參數。

- 辨識出交易基底類別。

- 列舉「所有」已註冊或被引用的交易類別。

### 自訂 ORM 模式

若資料庫存取是透過一個以程式化方式定義欄位的基底類別（例如 `addField()`、`setTargetTable()`），而非使用註解：

- 辨識出資料庫物件基底類別。

- 列舉「所有」子類別。

- 從 `setTargetTable()` 擷取資料表名稱。

- 從 `addField()` 呼叫中擷取欄位定義。

- 由程式碼重建資料庫綱要（schema）。

### 自訂組態模式

若組態是從自訂路徑載入（例如 `ConfigManager.load("/usr/hncb/config/init")`）：

- 辨識出組態載入器。

- 列舉「所有」properties 檔案。

- 將 properties 檔案對應到使用它們的模組。

---

## 證據

記錄自訂框架時，一律記下：

- 基底類別名稱

- 探索模式（如何找出子類別）

- 註冊機制

- 組態來源

---

## 反面模式（Anti-Pattern）

當自訂框架確實存在時，卻回報「未偵測到框架」，是「錯誤」的。

因為框架不是知名框架就跳過分析，是「禁止」的。

---

## 經驗教訓

### 問題：偵測到自訂框架，卻沒用它來驅動列舉

AI 正確辨識出 `TrxDispatcher` ＋ `TrxFactory` ＋ `StdTrxObject` 是一套自訂框架，
但後續卻沒有用這項資訊來驅動完整列舉，只給出概略數量就繼續往下走。

**修正**：偵測到自訂框架時，「下一個」必要步驟是：
1. 將偵測結果寫入 `docs/enumeration/framework-detection.md`
2. 以基底類別名稱（例如 `StdTrxObject`）作為 grep 樣式，產出完整的列舉檔案
3. 在列舉檔案寫出來之前，「不得」進入階段 2

### 問題：基底類別位於外部 jar 中

當基底類別（`StdTrxObject`）不在原始碼樹中（位於外部 jar），AI 無法讀取其原始碼。
這「不能」成為跳過子類別列舉的藉口。

**修正**：在整個原始碼樹中搜尋 `extends [BaseClassName]`。
列舉並不需要基底類別的原始碼，只需要子類別中的 `extends` 關鍵字。
