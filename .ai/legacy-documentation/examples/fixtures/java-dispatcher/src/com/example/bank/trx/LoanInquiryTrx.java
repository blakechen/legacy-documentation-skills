package com.example.bank.trx;

import com.example.bank.db.LoanDbObj;

public class LoanInquiryTrx extends BaseInquiryTrx {

    private LoanDbObj rec = new LoanDbObj();

    protected void query() {
        String keyValue = getParam("LOANNO");
        if (keyValue == null || keyValue.length() != 10) {
            this.errorCode = "E0021";
            return;
        }
        rec.setKey(keyValue);
        if (!rec.select()) {
            this.errorCode = "E0022";
        }
    }

    public String getParam(String key) {
        return key;
    }
}
