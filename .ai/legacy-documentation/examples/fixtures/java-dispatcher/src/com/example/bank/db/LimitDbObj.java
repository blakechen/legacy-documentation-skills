package com.example.bank.db;

import java.math.BigDecimal;

public class LimitDbObj extends StdDbObject {

    public LimitDbObj() {
        setTargetTable("LIMIT_CTL");
        addField("CUST_ID", 10);
        addField("DAILY_MAX", 15);
    }

    public BigDecimal getDailyMax() {
        return new BigDecimal("1000000");
    }
}
