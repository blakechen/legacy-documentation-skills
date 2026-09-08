# 交易規格

> 本模板對 `docs/modules/transactions/` 與
> `docs/specifications/transactions/` 底下的每一個檔案都是「必要」的。
>
> 深度要求：見 `shared/logic-depth.md`。
>
> Processing Detail 章節為空的文件即為「不完整」。
>
> 下列標題會被 `tools/shell/verify/depth_checks.sh` 與
> `tools/shell/chartest/gen_skeletons.awk` 逐字比對，
> 因此一律維持英文原文，不得翻譯：
> `### Method:`、Processing Flow、Pseudocode、Key Source Excerpts、
> Field Mapping、Branches and Conditions。

---

## 交易類別

---

## 進入 URL

---

## 路由參數

| 參數 | 值 |
|------|----|

---

## 用途

---

## State Methods（索引）

每個公開方法一列。本表僅為索引。

每一列「必須」在下方 Processing Detail 中有一個對應的 `### Method:` 小節。

| 方法 | 用途（一行） | 進入條件 | 下一個狀態／輸出 |
|------|--------------|----------|------------------|

---

## 端到端處理流程

以編號敘述描述本交易一次完整執行的過程，
從進入 URL 經過每一個狀態方法，直到最終頁面或轉導。

指名每一次狀態轉換，以及造成該轉換的條件。

---

## Processing Detail

State Methods 索引中列出的每個方法一個小節。

四項深度要素全部強制。見 `shared/logic-depth.md`。

### Method: `methodName`

**Signature**: `<visibility> <returnType> methodName(<params>)`

**Source**: `path/to/Class.java:<startLine>-<endLine>`

**Invoked when**: 到達此方法的狀態值、路由參數或呼叫者

#### Processing Flow

1. 它讀什麼、檢查什麼、呼叫什麼、寫什麼，或接下來去哪裡。

2. ...

3. ...

#### Pseudocode

```text
BEGIN methodName
  READ ...
  IF <condition> THEN
    ...
    RETURN <state>
  END IF
  CALL ...
  WRITE ...
  RETURN <state>
END
```

#### Key Source Excerpts

`path/to/Class.java:120-128`

```java
逐字照抄的原始碼行
```

說明：以一到兩句話講清楚這段決定了什麼或計算了什麼。

#### Field Mapping

| Input Field | Source | Intermediate | Transformation | Target | Target Kind |
|-------------|--------|--------------|----------------|--------|-------------|

#### Branches and Conditions

| # | Condition | When True | When False | Evidence |
|---|-----------|-----------|------------|----------|

#### 本方法中的資料庫存取

| # | 資料表 | 操作 | 鍵／Where | 讀取欄位 | 寫入欄位 | 證據 |
|---|--------|------|-----------|----------|----------|------|

#### 外部呼叫

| 目標 | 協定 | 請求欄位 | 回應欄位 | 失敗時 | 證據 |
|------|------|----------|----------|--------|------|

#### 錯誤路徑

| 觸發條件 | 偵測方式 | 處理方式 | 使用者可見的結果 | 證據 |
|----------|----------|----------|------------------|------|

#### 本方法所施行的業務規則

| BR-ID | 施行於（步驟 #） |
|-------|------------------|

---

以下章節是整筆交易的彙總，跨所有方法做總結。
它們絕不取代上方逐方法的細節。

---

## 輸入欄位

| 欄位 | 型別 | 驗證 | 必填 |
|------|------|------|------|

---

## 業務規則

| 規則 ID | 說明 |
|---------|------|

---

## 資料庫存取

| 資料表 | 操作 | 條件 |
|--------|------|------|

---

## 外部系統呼叫

| 系統 | 協定 | 用途 |
|------|------|------|

---

## 輸出頁面

| 狀態 | JSP／轉導 |
|------|-----------|

---

## 錯誤處理

| 錯誤 | 處理者 | 輸出 |
|------|--------|------|

---

## 安全

---

## 相關循序圖

---

## 相關業務規則

---

## 證據
