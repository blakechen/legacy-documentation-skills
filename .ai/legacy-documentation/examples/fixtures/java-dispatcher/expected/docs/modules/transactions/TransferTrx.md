# 交易規格

## 交易類別

`com.example.bank.trx.TransferTrx`

## 進入 URL

經由 `TrxDispatcherServlet` 以 `TRXCODE=T100` 進入。

## 路由參數

| 參數 | 值 |
|------|----|
| TRXCODE | T100 |

## 用途

在把請求的轉帳金額與客戶的每日上限比對之後，
從客戶帳戶扣款。

## State Methods（索引）

| 方法 | 用途（一行） | 進入條件 | 下一個狀態／輸出 |
|------|--------------|----------|------------------|
| `execute` | 驗證金額並對帳戶扣款 | 由 TRXCODE=T100 分派 | 錯誤碼 E0031／E0032，或一筆扣款 |

## 端到端處理流程

1. `TrxDispatcherServlet.doPost` 讀取 TRXCODE，並向 `TrxFactory.create` 索取該單元。
2. `TrxFactory.create` 把 T100 對應到 `TransferTrx`，並依名稱將其實例化。
3. `TransferTrx.execute` 執行上限檢查與扣款。

## Processing Detail

### Method: `execute`

**Signature**: `public void execute(Object req, Object res)`

**Source**: `src/com/example/bank/trx/TransferTrx.java:12-26`

**Invoked when**: dispatcher 解析出 TRXCODE=T100 時。

#### Processing Flow

1. 讀取請求欄位 TRSFAMT，並將它解析成十進位數值 `amount`。
2. 讀取請求欄位 CUSTID，將它設為 LIMIT_CTL 的鍵並選取該資料列。
3. 若 `amount` 大於 LIMIT_CTL.DAILY_MAX，記錄錯誤碼 E0031 並返回；否則繼續執行步驟 4。
4. 若 `amount` 為零或負數，記錄錯誤碼 E0032 並返回；否則繼續執行步驟 5。
5. 讀取請求欄位 ACCTNO，將它設為 ACCT_MST 的鍵，並依 `amount` 對該帳戶扣款。

#### Pseudocode

```text
BEGIN execute
  READ TRSFAMT FROM request INTO amount
  READ CUSTID FROM request INTO limitKey
  READ row FROM LIMIT_CTL USING limitKey
  IF amount > LIMIT_CTL.DAILY_MAX THEN
    WRITE error E0031
    RETURN
  END IF
  IF amount <= 0 THEN
    WRITE error E0032
    RETURN
  END IF
  READ ACCTNO FROM request INTO acctKey
  CALL debit ON ACCT_MST USING acctKey AND amount
END
```

#### Key Source Excerpts

`src/com/example/bank/trx/TransferTrx.java:16-19`

```java
        if (amount.compareTo(limit.getDailyMax()) > 0) {
            fail("E0031");
            return;
        }
```

說明：這是每日上限的檢查；未通過即以 E0031 結束本筆交易。

#### Field Mapping

| Input Field | Source | Intermediate | Transformation | Target | Target Kind |
|-------------|--------|--------------|----------------|--------|-------------|
| TRSFAMT | request | amount | 解析為十進位數 | ACCT_MST.BALANCE | DB column |
| CUSTID | request | limit | 以鍵查詢 | LIMIT_CTL.CUST_ID | DB column |
| ACCTNO | request | acct | 以鍵查詢 | ACCT_MST.ACCT_NO | DB column |

#### Branches and Conditions

| # | Condition | When True | When False | Evidence |
|---|-----------|-----------|------------|----------|
| 1 | amount > DAILY_MAX | E0031, return | continue | TransferTrx.java:16 |
| 2 | amount <= 0 | E0032, return | continue | TransferTrx.java:20 |

#### 本方法中的資料庫存取

| # | 資料表 | 操作 | 鍵／Where | 讀取欄位 | 寫入欄位 | 證據 |
|---|--------|------|-----------|----------|----------|------|
| 1 | LIMIT_CTL | SELECT | CUST_ID | DAILY_MAX | - | TransferTrx.java:14-15 |
| 2 | ACCT_MST | UPDATE | ACCT_NO | BALANCE | BALANCE | TransferTrx.java:24-25 |
