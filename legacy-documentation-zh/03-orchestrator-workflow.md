# 工作流程（Workflow）

## 階段 1

程式碼庫探索

清冊盤點

技術

架構

自訂框架偵測

驗證

---

## 階段 1.5

產出物列舉（關鍵）

Skill：artifact-enumeration

列舉「所有」交易／動作類別

列舉「所有」資料庫物件類別

列舉「所有」servlet

建立主清單

驗證

### 關卡檢查（由經驗教訓新增）

以下輸出檔案必須實際存在於磁碟上，才可繼續：

- `docs/enumeration/transaction-classes.txt`
- `docs/enumeration/db-object-classes.txt`
- `docs/enumeration/servlet-classes.txt`

每個檔案必須包含 `ClassName|Path` 條目（不能只有數量）。

db-object-classes.txt 多帶第三個欄位：`ClassName|Path|TargetTable`。

若關卡未通過 → 停止。不得進入階段 2。

---

## 階段 2

結構分析

模組

逐交易類別分析

資料庫（依據資料庫物件列舉結果）

介接

驗證

---

## 階段 3

行為分析

業務規則（每個交易類別）

循序圖（每個交易類別）

驗證

---

## 階段 4

文件產出

逐交易規格

系統規格

落差分析

驗證

---

發生以下情況時立即停止

清冊盤點失敗

或

無法確立架構

或

交易類別列舉結果為零。
