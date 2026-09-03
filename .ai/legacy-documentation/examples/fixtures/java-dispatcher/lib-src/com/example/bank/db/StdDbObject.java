package com.example.bank.db;

/** Framework persistence base. Programmatic field definitions, no annotations. */
public abstract class StdDbObject {
    private String table;
    protected void setTargetTable(String name) { this.table = name; }
    protected void addField(String name, int length) { }
    public void setKey(String key) { }
    public boolean select() { return true; }
    public void update() { }
}
