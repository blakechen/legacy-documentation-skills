# 範例

這裡放了兩種東西，各自負責不同的工作。

---

## `fixtures/` —— 可執行的黃金案例

小而完整、可實際執行的原始碼樹，旁邊附上預期的工具輸出。

    sh tools/shell/selftest.sh

會對 `fixtures/java-dispatcher` 執行整條工具鏈，
並把結果與 `fixtures/java-dispatcher/expected/` 做 diff。
共 24 項檢查，其中三項「必須」失敗或被阻斷：
一份看似合理但錯誤的文件、一個從 factbase 中缺席的類別，
以及一個與掃描不一致的判準。

若對工具的變更改動了那些檔案，在預期檔案被刻意更新之前，一律視為迴歸。

### `fixtures/java-dispatcher`

一個微型的老舊系統，刻意重現 `shared/enumeration-first.md` 與
`shared/custom-framework-recognition.md` 中記錄的四種抽取失敗：

| 陷阱 | 它會破壞什麼 |
|---|---|
| 基底類別在 jar 裡，不在原始碼樹中 | 一開始就去讀基底類別的策略 |
| 遞移繼承 | `grep "extends StdTrxObject"` |
| 反射註冊 | 靠掃描 dispatcher 找類別名稱 |
| 死碼 | 對所有單元一視同仁地撰寫文件 |

它還帶有一個複製貼上家族，讓原型分群有東西可找；
以及兩份單元文件 —— 一份正確、一份看似合理但錯誤 ——
以證明深度檢查不只會接受，也會拒絕。

---

## `cobol/`、`dotnet/`、`nodejs/`、`spring-boot/`、`websphere/` —— 敘述型範例

描述對該類系統執行一次分析後，結果應該長什麼樣子：
技術摘要、預期文件、驗證備註。

儲存庫原始碼刻意排除在外。

這些是用來建立方向感的。它們「不是」迴歸測試：
沒有東西會檢查它們，也沒有東西能檢查。
只有 `fixtures/` 帶有可供程式比對的預期輸出。

---

## 新增 fixture

一個 fixture 之所以有存在價值，是因為它重現了一次真正發生過的失敗。

1. 把能重現該失敗的最小原始碼樹放進 `fixtures/<name>/`。
2. 把工具「應該」產出的結果記錄在 `fixtures/<name>/expected/`。
3. 把檢查加進 `tools/shell/selftest.sh`。
4. 在該 fixture 的 README 中寫下它重現的是哪一種失敗。

沒有重現任何失敗的 fixture，只是一場示範，不是測試。
