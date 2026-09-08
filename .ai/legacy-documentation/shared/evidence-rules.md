# 證據規則

## 目標

確保任何 Skill 產出的每一個結論，都有可查證的證據支撐。

---

## 原則

證據永遠優先於推論。

「未知」優於「臆測」。

絕不捏造資訊。

每一句重要陳述都應可追溯。

---

## 可接受的證據

### 原始碼

- Class
- Interface
- Method
- Package
- Namespace
- Annotation

### 組態

- application.yml
- application.properties
- XML
- JSON
- YAML
- 環境變數

### 建置

- pom.xml
- build.gradle
- package.json
- Dockerfile

### 資料庫

- SQL
- DDL
- Stored Procedure
- Trigger
- Constraint

### 整合

- REST Endpoint
- SOAP WSDL
- MQ 組態
- Kafka 組態
- 排程器

---

## 證據格式

來源

位置

產出物

行號範圍

Factbase commit

信心度

### 版本鎖定

行號引用只對某一個版本的檔案為真。請記錄版本。

每一份產生的文件「應當」在其中繼資料區塊中載明

    Factbase commit: <sha>

而逐單元的原始碼雜湊值，「應當」在該單元通過深度檢查之後，
由 `tools/shell/verify/staleness.sh --record` 記錄下來。

見 shared/incremental-update.md。沒有這些，就無法分辨
一個有效引用與一個已經腐化的引用。

---

## 缺少證據

若找不到證據

輸出

Unknown

不要推測。

---

## 引用規則

每一句關於行為的斷言「應當」附上引用，否則「應當」寫成 Unknown。

    <斷言>   需要   path/to/File.java:<line>-<line>
                    或列舉中的一張資料表
                    或推導清單中的一個領域變數
                    或一個組態鍵及其檔案

沒有引用的斷言不是低信心度的斷言。它根本不是斷言；它是 Unknown。

### 為什麼這條規則取代了禁用詞清單

本規則的早期版本禁止模糊措辭：「看起來」、「大概」、「應該」。
被瞄準的是那些詞，但問題不在那裡。

把沒有依據之主張中的模糊措辭拿掉，並不會讓那個主張獲得依據，
只會讓它讀起來很確定，而那更糟：
讀者失去了唯一能看出作者其實沒把握的訊號。

模糊措辭是症狀。引用要求處理的是病因。

因此：

- 有引用的斷言不需要模糊措辭；直接寫清楚
- 沒有引用的斷言寫成 Unknown，並說明缺了什麼
- 若證據可以支持多種解讀，就把各種解讀寫出來，
  並分別引用支撐各自的證據

絕不要寫「開發者的意圖是」。意圖不是可觀察的產出物。

---

## 可追溯性

每一份產生的文件都應包含

證據

來源產出物

參照
