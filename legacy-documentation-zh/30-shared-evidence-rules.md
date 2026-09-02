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

行號（選填）

信心度

---

## 缺少證據時

若找不到證據

輸出

Unknown（未知）

不要推測。

---

## 禁止事項

絕不寫

「這大概是……」

「看起來像是……」

「這應該會……」

「開發者的用意是……」

一律改為

「Unknown（未知）」

---

## 可追溯性

每一份產生的文件都應包含

證據

來源產出物

引用
