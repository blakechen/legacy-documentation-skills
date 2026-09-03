package com.example.bank.db;

public class CardDbObj extends StdDbObject {

    public CardDbObj() {
        setTargetTable("CARD_MST");
        addField("CARDNO", 16);
        addField("BALANCE", 15);
        addField("STATUS", 1);
    }

    public void debit(Object amount) {
        update();
    }
}
