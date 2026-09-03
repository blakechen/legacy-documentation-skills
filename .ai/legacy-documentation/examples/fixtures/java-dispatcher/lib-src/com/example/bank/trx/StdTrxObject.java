package com.example.bank.trx;

/** Framework base class. Ships in a jar; no source in the application tree. */
public abstract class StdTrxObject {
    public abstract void execute(Object req, Object res);
}
