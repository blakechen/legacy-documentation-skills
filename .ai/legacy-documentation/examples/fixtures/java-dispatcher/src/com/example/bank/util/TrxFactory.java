package com.example.bank.util;

import com.example.bank.trx.StdTrxObject;

/** Reflection-based registry. Class names are never written literally. */
public class TrxFactory {

    private static final String PREFIX = "com.example.bank.trx.";

    public static StdTrxObject create(String code) {
        String cls = PREFIX + map(code);
        try {
            return (StdTrxObject) Class.forName(cls).newInstance();
        } catch (Exception e) {
            return null;
        }
    }

    private static String map(String code) {
        if ("T100".equals(code)) {
            return "TransferTrx";
        } else if ("Q200".equals(code)) {
            return "AcctInquiryTrx";
        } else if ("Q210".equals(code)) {
            return "CardInquiryTrx";
        } else if ("Q220".equals(code)) {
            return "LoanInquiryTrx";
        }
        return "UnknownTrx";
    }
}
