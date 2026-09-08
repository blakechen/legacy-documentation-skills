# 反思模型（Reflexion Model）

## 目標

以「某個人對系統的信念」檢驗還原出來的架構，並回報兩者不一致之處。

Murphy、Notkin 與 Sullivan，*Software Reflexion Models*，FSE 1995。

---

## 問題所在

本函式庫中的每個 Skill 都是由下而上運作：讀程式碼，然後建立一幅圖像。
由下而上的還原無從察覺自己「從未找到的東西」，
也無從察覺「找到的東西並不是這個系統存在的目的」。

現場總有人知道這個系統在做什麼。那份知識是本流水線中
唯一獨立於程式碼之外的輸入，而在此之前，流水線沒有地方安置它。

---

## 方法

### 1. 陳述假說

一位懂這個系統的人 —— 維運人員、業務分析師，或資深開發者 ——
在「閱讀還原出的文件之前」寫下一份模組地圖。

十到十五個模組。三十分鐘。

`docs/architecture/hypothesis-map.txt`

    module Web          Front controller, routing, request entry
    module Inquiry      Read-only enquiries
    module Transfer     Money movement
    module Persistence  Database access

    map ^com\.example\.bank\.web\.   -> Web
    map InquiryTrx$                   -> Inquiry
    map ^com\.example\.bank\.db\.     -> Persistence

    edge Web -> Inquiry
    edge Web -> Transfer
    edge Inquiry -> Persistence

對應規則是針對完整型別名稱的正規表示式，依檔案順序求值；先match者勝出。

### 2. 計算

`tools/shell/reflexion/reflexion.sh` 會把每個型別對應到某個模組，
並比較「預期的邊」與 factbase 中「實際存在的邊」。

### 3. 讀出三種結果

**Convergence（收斂）** —— 預期存在，實際也存在。確認了該信念。
最不有趣的結果。

**Divergence（分歧）** —— 實際存在，但不在預期中。一段沒人寫下來的關聯。
它要嘛是關於這個系統的未記錄事實，要嘛是一項缺陷：
分層違規、抄捷徑，或殘留物。

**Absence（缺席）** —— 預期存在，實際卻沒有。要嘛是信念錯了，
要嘛是這段關聯走的是掃描看不見的路徑：
排程器、佇列、stored procedure，或檔案投遞。

**Unmapped types（未對應型別）** —— 沒有符合任何規則。這不是中性的結果。
要嘛是模型漏了一個模組，要嘛是該型別根本不屬於模型所描述的系統。
兩者都值得知道。

---

## 規則

反思檢查「應當」在列舉之後、規格產生之前執行。

每一項分歧與每一項缺席，「應當」在
`docs/architecture/reflexion-report.md` 中以下列其中一種方式解決

- 修正假說地圖，並說明原因
- 在落差分析中記錄成一項發現，並說明原因
- 陳述掃描的限制，並指名它看不見的機制

未解決的分歧是關於這個系統的未決問題，而不是可以忽略的工具錯誤。

---

## 為什麼這能抓到抽取錯誤

假說是根據抽取器所沒有的知識寫成的。
當分析師確信存在的某個模組對應不到任何東西時，
最可能的原因不是分析師錯了，而是列舉漏掉了一整族類別。

這是本函式庫中唯一能找出「流水線從未去找的東西」的檢查。

---

## 反模式

以套件結構產生假說地圖來取代由人撰寫，是「被禁止」的。

從程式碼推導出來的地圖不可能與程式碼不一致。
拿這種地圖去跑工具，會產出一份乾淨卻毫無意義的報告，
而這份乾淨的報告比沒有報告更糟，因為它會被相信。
