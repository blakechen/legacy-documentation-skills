package com.example.bank.db;

public class LoanDbObj extends StdDbObject {

    public LoanDbObj() {
        setTargetTable("LOAN_MST");
        addField("LOANNO", 10);
        addField("BALANCE", 15);
        addField("STATUS", 1);
    }

    public void debit(Object amount) {
        update();
    }
}
