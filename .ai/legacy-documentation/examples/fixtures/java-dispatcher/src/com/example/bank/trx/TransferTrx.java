package com.example.bank.trx;

import com.example.bank.db.AcctDbObj;
import com.example.bank.db.LimitDbObj;
import java.math.BigDecimal;

public class TransferTrx extends StdTrxObject {

    private AcctDbObj acct = new AcctDbObj();
    private LimitDbObj limit = new LimitDbObj();

    public void execute(Object req, Object res) {
        BigDecimal amount = new BigDecimal(param(req, "TRSFAMT"));
        limit.setKey(param(req, "CUSTID"));
        limit.select();
        if (amount.compareTo(limit.getDailyMax()) > 0) {
            fail("E0031");
            return;
        }
        if (amount.signum() <= 0) {
            fail("E0032");
            return;
        }
        acct.setKey(param(req, "ACCTNO"));
        acct.debit(amount);
    }

    private String param(Object req, String key) {
        return key;
    }

    private void fail(String code) {
        System.out.println(code);
    }
}
