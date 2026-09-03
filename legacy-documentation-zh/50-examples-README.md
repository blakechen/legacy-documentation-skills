# 範例（Examples）

這個目錄裡有兩種東西，它們的職責不同。

---

## `fixtures/` — 可執行的 golden case

小而完整、可執行的原始碼樹，旁邊附上預期的工具輸出。

    sh tools/selftest.sh

會對 `fixtures/java-dispatcher` 執行整條工具鏈，
並與 `fixtures/java-dispatcher/expected/` 比對。共 24 項檢查，
其中三項「必須失敗或封鎖」：一份看似合理但錯誤的文件、
一個少了某個類別的 factbase、以及一個與掃描結果不一致的 oracle。

工具變更若改動了那些檔案，在它們被刻意更新之前，都視為迴歸。

### `fixtures/java-dispatcher`

一個微型舊系統，刻意重現了
`shared/enumeration-first.md` 與
`shared/custom-framework-recognition.md` 中記載的四種抽取失敗：

| 陷阱 | 它會破壞什麼 |
|---|---|
| 基底類別在 jar 裡，不在原始碼樹中 | 「先讀基底類別」的策略 |
| 遞移繼承 | `grep "extends StdTrxObject"` |
| 反射註冊 | 掃描 dispatcher 找類別名稱 |
| 死碼 | 對每個單元投入同等份量的文件 |

它同時帶有一個複製貼上家族，讓原型分群有東西可找；
也帶有兩份單元文件 —— 一份正確、一份看似合理但是錯的 ——
用來證明深度檢查不只會通過，也會拒絕。

---

## `cobol/`、`dotnet/`、`nodejs/`、`spring-boot/`、`websphere/` — 敘述性範例

描述對該類系統執行時應該長什麼樣子：
技術摘要、預期文件、驗證註記。

儲存庫原始碼刻意不納入。

這些是給人建立方向感用的。它們「不是」迴歸測試：
沒有任何東西檢查它們，也不可能檢查。
只有 `fixtures/` 帶有可由程式比對的預期輸出。

---

## 新增 fixture

一個 fixture 要能重現「真的發生過的失敗」，才有存在的價值。

1. 把能重現該失敗的最小原始碼樹放進 `fixtures/<name>/`。
2. 把工具應該產出的結果記錄在 `fixtures/<name>/expected/`。
3. 把檢查加進 `tools/selftest.sh`。
4. 在該 fixture 的 README 中寫下它重現的是哪一種失敗。

一個沒有重現任何失敗的 fixture，是展示，不是測試。
