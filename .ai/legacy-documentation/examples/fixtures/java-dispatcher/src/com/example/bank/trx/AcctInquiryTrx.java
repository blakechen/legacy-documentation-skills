package com.example.bank.trx;

import com.example.bank.db.AcctDbObj;

public class AcctInquiryTrx extends BaseInquiryTrx {

    private AcctDbObj acct = new AcctDbObj();

    protected void query() {
        String acctNo = getParam("ACCTNO");
        if (acctNo == null || acctNo.length() != 12) {
            this.errorCode = "E0001";
            return;
        }
        acct.setKey(acctNo);
        if (!acct.select()) {
            this.errorCode = "E0002";
        }
    }

    public String getParam(String key) {
        return key;
    }
}
