# Fixture：java-dispatcher

一個微型的老舊系統，刻意重現 `shared/enumeration-first.md` 與
`shared/custom-framework-recognition.md` 中記錄的四種抽取失敗。

| 陷阱 | 位置 | 它會破壞什麼 |
|---|---|---|
| 基底類別位於 jar 中，不在原始碼樹裡 | `lib-src/` 中的 `StdTrxObject`、`StdDbObject` | 「先讀基底類別」的策略 |
| 遞移繼承 | `AcctInquiryTrx` → `BaseInquiryTrx` → `StdTrxObject` | `grep "extends StdTrxObject"` 會漏掉它 |
| 反射註冊 | `TrxFactory.create` 以前綴組出類別名稱 | 掃描 dispatcher 參照找不到任何類別名稱 |
| 死碼 | `LegacyFxTrx` 沒有在任何地方註冊 | 對 100% 的單元一視同仁地撰寫文件 |

## 預期事實

`expected/` 存放本儲存庫的工具必須重現的列舉結果。
`tools/shell/selftest.sh` 會重新產生事實，並與 `expected/` 做 diff。
它同時檢查工具是否具備「拒絕」的能力：
一份看似合理但錯誤的單元文件，以及一個缺了某個類別的 factbase。
若對抽取器的變更改動了這些檔案，在預期檔案被刻意更新之前，一律視為迴歸。

## 目錄配置

    lib-src/   框架與 servlet API 的樁程式；會被編譯成一個 jar
    src/       受分析的應用程式
    expected/  黃金列舉輸出

> `expected/` 底下的兩份 `TransferTrx.md` 是機器驗證用的測試資料。
> 敘述文字已改為中文，但下列內容維持原樣，因為工具會逐字比對它們：
> `### Method:`、Processing Flow、Pseudocode、Key Source Excerpts、
> Field Mapping、Branches and Conditions 這幾個標題；`java` 區塊的引文
> （必須與原始碼逐位元組相同）；虛擬碼；Field Mapping 與
> Branches and Conditions 兩張表的欄位值 —— 其中 Condition 欄
> 會被 `gen_skeletons.awk` 轉成測試方法名稱。
