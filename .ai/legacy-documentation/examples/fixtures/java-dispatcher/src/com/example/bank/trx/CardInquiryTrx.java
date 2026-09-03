package com.example.bank.trx;

import com.example.bank.db.CardDbObj;

public class CardInquiryTrx extends BaseInquiryTrx {

    private CardDbObj rec = new CardDbObj();

    protected void query() {
        String keyValue = getParam("CARDNO");
        if (keyValue == null || keyValue.length() != 16) {
            this.errorCode = "E0011";
            return;
        }
        rec.setKey(keyValue);
        if (!rec.select()) {
            this.errorCode = "E0012";
        }
    }

    public String getParam(String key) {
        return key;
    }
}
