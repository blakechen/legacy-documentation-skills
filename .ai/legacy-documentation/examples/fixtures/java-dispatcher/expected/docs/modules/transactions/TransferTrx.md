# Transaction Specification

## Transaction Class

`com.example.bank.trx.TransferTrx`

## Entry URL

Reached through `TrxDispatcherServlet` with `TRXCODE=T100`.

## Routing Parameters

| Parameter | Value |
|-----------|-------|
| TRXCODE | T100 |

## Purpose

Debits a customer account by a requested transfer amount after checking the
amount against the customer's daily limit.

## State Methods (Index)

| Method | Purpose (one line) | Entry Condition | Next State / Output |
|--------|--------------------|-----------------|---------------------|
| `execute` | Validate the amount and debit the account | Dispatched on TRXCODE=T100 | Error code E0031/E0032, or a debit |

## End-to-End Processing Flow

1. `TrxDispatcherServlet.doPost` reads TRXCODE and asks `TrxFactory.create` for the unit.
2. `TrxFactory.create` maps T100 to `TransferTrx` and instantiates it by name.
3. `TransferTrx.execute` runs the limit checks and the debit.

## Processing Detail

### Method: `execute`

**Signature**: `public void execute(Object req, Object res)`

**Source**: `src/com/example/bank/trx/TransferTrx.java:12-26`

**Invoked when**: the dispatcher resolves TRXCODE=T100.

#### Processing Flow

1. Reads request field TRSFAMT and parses it into `amount` as a decimal value.
2. Reads request field CUSTID, sets it as the key of LIMIT_CTL and selects the row.
3. If `amount` is greater than LIMIT_CTL.DAILY_MAX, records error code E0031 and returns; otherwise continues to step 4.
4. If `amount` is zero or negative, records error code E0032 and returns; otherwise continues to step 5.
5. Reads request field ACCTNO, sets it as the key of ACCT_MST and debits the account by `amount`.

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

Explanation: the daily-limit test; failing it ends the transaction with E0031.

#### Field Mapping

| Input Field | Source | Intermediate | Transformation | Target | Target Kind |
|-------------|--------|--------------|----------------|--------|-------------|
| TRSFAMT | request | amount | parsed to decimal | ACCT_MST.BALANCE | DB column |
| CUSTID | request | limit | key lookup | LIMIT_CTL.CUST_ID | DB column |
| ACCTNO | request | acct | key lookup | ACCT_MST.ACCT_NO | DB column |

#### Branches and Conditions

| # | Condition | When True | When False | Evidence |
|---|-----------|-----------|------------|----------|
| 1 | amount > DAILY_MAX | E0031, return | continue | TransferTrx.java:16 |
| 2 | amount <= 0 | E0032, return | continue | TransferTrx.java:20 |

#### Database Access In This Method

| # | Table | Operation | Key / Where | Columns Read | Columns Written | Evidence |
|---|-------|-----------|-------------|--------------|-----------------|----------|
| 1 | LIMIT_CTL | SELECT | CUST_ID | DAILY_MAX | - | TransferTrx.java:14-15 |
| 2 | ACCT_MST | UPDATE | ACCT_NO | BALANCE | BALANCE | TransferTrx.java:24-25 |
