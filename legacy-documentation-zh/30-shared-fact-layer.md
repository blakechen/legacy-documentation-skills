# 事實層原則（Fact Layer Principle）

## 目標

把「可由機器確定的事實」與「需要判斷的詮釋」分開，
並且讓 AI 只負責後者。

---

## 三層架構

### Layer 1 — 事實層

由原始碼、編譯產物與版本控制中確定性地抽取。

由程式產生。完全不經過模型。

內容

- 宣告的型別、其父型別、所在檔案與行號範圍
- 宣告的方法、修飾詞、程式碼範圍、判斷點數量
- 呼叫點、字串常值、import、套件結構
- 檔案內容雜湊值，以及掃描時所在的 commit

工具：`tools/factbase/extract_java.py` 接著 `tools/factbase/build_factbase.py`。

輸出：`docs/facts/*.jsonl` 與 `docs/facts/factbase.sqlite`。

### Layer 2 — 結構層

由程式從 Layer 1 推導。同樣不經過模型。

內容

- 型別階層的遞移閉包（transitive closure）
- 呼叫圖與由進入點出發的可達性
- 複製貼上叢集
- 變更頻率
- 對照人所提出之假設的 reflexion 映射

工具：`enumerate.py`、`prioritize.py`、`archetypes.py`、
`domain_variables.py`、`reflexion.py`。

### Layer 3 — 概念層

唯一屬於 AI 的一層。

內容

- 一個單元在業務上的用途
- 一個晦澀名稱的意義
- 一個條件背後的業務規則
- 一段處理流程的敘述

每一句 Layer 3 的陳述都應引用一項 Layer 1 的事實：
含行號範圍的路徑、列舉清單中的資料表名稱、或推導出的領域變數。

---

## 規則

當一項事實可由剖析器確定時，Skill 不得改以「閱讀」來確定它。

具體而言，Skill 不得

- 靠讀檔來計算產出物數量
- 靠 grep `extends` 來判定類別階層
- 在沒有 factbase 的情況下宣稱某方法有 N 個分支
- 在沒有列舉條目佐證的情況下宣稱某個資料表名稱

---

## 理由

語言模型閱讀原始碼會產生「看似合理」的事實。
看似合理不等於正確，而且這種失誤是無聲的：
輸出中沒有任何線索能區分「它真的讀到的類別」與「它以為存在的類別」。

剖析器產生的事實比較少，但它出錯的方式是可見且可重現的。
兩者不一致時，以剖析器為準。

---

## 事實層「不」做什麼

它不理解這個系統。

`extract_java.py` 是詞法掃描器，不是編譯器。
它記錄實際寫出來的內容，透過 import 與套件範圍解析名稱，
並把無法解析的部分標記為 `EXTERNAL:` 或 `UNKNOWN`。
它已知的限制列在該模組的 docstring，並且應被複述於列舉報告中。

這正是 Layer 1 需要一個 oracle 的原因。

---

## Oracle（外部真值來源）

`tools/factbase/verify_bytecode.py` 以 `javap` 讀取編譯後的 class 與 jar，
比對每個類別的真實父型別與 factbase 的紀錄。

詞法掃描器與 oracle 不共用任何程式碼，讀取的輸入也不同。
兩者一致，才構成證據。

「換一個正規表示式再搜尋一次」不是證據，
那只是同一種方法把同一個錯誤犯兩次。

若不存在編譯產物，oracle 會記錄 `Status: UNAVAILABLE`，
且列舉報告應載明本次列舉僅依賴詞法抽取，
不得以「已驗證」描述之。

---

## 執行順序

事實層在架構探索消費它之前執行，也在任何列舉檔案寫出之前執行。

在 `docs/facts/factbase.sqlite` 存在之前，任何產生文件的 Skill 都不得執行。

---

## 語言

Layer 1 與語言相關；Layer 2、Layer 3 與語言無關。

`extract_java.py` 涵蓋 Java；就其設計而言，
Kotlin 與 Scala 的多數宣告語法不在其範圍內。
新增語言需要新的 Layer 1 抽取器，輸出相同的 JSONL 記錄。
Layer 1 以上完全不變。

若某語言沒有對應的抽取器，此事實應被記錄，
且該語言相關的發現其信心水準應為 Low，不得為 High。
