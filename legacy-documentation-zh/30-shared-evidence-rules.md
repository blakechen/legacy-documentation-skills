# 證據規則（Evidence Rules）

## 目標

確保任何 Skill 產生的每一項結論，都有可驗證的證據支持。

---

## 原則

證據永遠優先於推論。

寫「未知」優於臆測。

絕不捏造資訊。

每一項重要陳述都應可追溯。

---

## 可接受的證據

### 原始碼

- 類別（Class）
- 介面（Interface）
- 方法（Method）
- 套件（Package）
- 命名空間（Namespace）
- 註解（Annotation）

### 組態設定

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
- 預存程序（Stored Procedure）
- 觸發器（Trigger）
- 限制條件（Constraint）

### 整合

- REST 端點
- SOAP WSDL
- MQ 組態
- Kafka 組態
- 排程器（Scheduler）

---

## 證據格式

來源

位置

產出物

行號範圍

Factbase commit

信心水準

### 版本綁定

行號引用只對某一個檔案版本為真。要記錄版本。

每一份產生的文件都應在其中繼資料區塊記錄

    Factbase commit: <sha>

且單元通過深度檢查後，應以
`tools/verify/staleness.sh --record` 記錄各單元的原始碼雜湊值。

見 shared/incremental-update.md。
沒有這個，就無法區分「有效的引用」與「已經腐爛的引用」。


## 缺少證據時

若找不到證據

輸出

Unknown（未知）

不要推測。

---

## 引用規則

每一句關於行為的斷言，都應附帶引用，否則應寫為 Unknown。

    <斷言>   需要   path/to/File.java:<行>-<行>
                    或列舉清單中的資料表
                    或推導清單中的領域變數
                    或帶有所在檔案的組態鍵

沒有引用的斷言不是「低信心的斷言」。
它不是斷言，它是 Unknown。

### 為什麼這取代了禁用詞清單

本規則的舊版禁用避險用語：「看起來」、「可能」、「應該」。
被針對的是「用詞」，而不是問題本身。

把避險用語從一個沒有佐證的主張中拿掉，
並不會讓那個主張變得有佐證，
只會讓它「讀起來很確定」——那更糟：
讀者失去了「作者其實沒把握」這唯一的訊號。

避險用語是症狀。引用要求處理的是病因。

所以：

- 有引用的斷言不需要避險語；直接寫清楚
- 沒有引用的斷言寫為 Unknown，並載明缺了什麼
- 當證據支持多種讀法時，列出各種讀法並分別引用其證據

絕不寫「開發者的本意是」。意圖不是可觀察的產出物。


## 可追溯性

每一份產生的文件都應包含

證據

來源產出物

引用
