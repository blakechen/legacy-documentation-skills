package com.example.bank.trx;

/** Intermediate base. Subclasses of this are NOT found by a direct
 *  "extends StdTrxObject" grep -- that is the point of this fixture. */
public abstract class BaseInquiryTrx extends StdTrxObject {

    protected String errorCode;

    public void execute(Object req, Object res) {
        prepare(req);
        query();
        render(res);
    }

    protected abstract void query();

    protected void prepare(Object req) {
        this.errorCode = null;
    }

    protected void render(Object res) {
        // no branching
    }
}
