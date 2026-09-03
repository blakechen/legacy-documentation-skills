package com.example.bank.db;

public class AcctDbObj extends StdDbObject {

    public AcctDbObj() {
        setTargetTable("ACCT_MST");
        addField("ACCT_NO", 12);
        addField("BALANCE", 15);
        addField("STATUS", 1);
    }

    public void debit(Object amount) {
        update();
    }
}
