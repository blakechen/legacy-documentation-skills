# 管線（Pipeline）

階段 0

事實抽取（Fact Extraction）

↓

Bytecode Oracle（獨立驗證）

即 shared/fact-layer.md 的 Layer 1 與 Layer 2。確定性。不經過模型。

---

階段 1

清冊（Inventory）

↓

技術探索（Technology Discovery）

↓

架構探索 + 自訂框架偵測

---

階段 1.5

成品列舉（從 factbase 查詢，而非搜尋）

交易類別列舉（遞移閉包 + 反射）

↓

資料庫物件類別列舉

↓

Servlet 列舉

↓

優先序排定（可達性 + 變更頻率 + 執行期使用量）

↓

原型分群（收斂複製貼上家族）

---

階段 1.6

Reflexion 檢查

以人對系統的模型，對照 factbase 檢驗。

divergence 與 absence 在進入階段 2 之前解決。

---

階段 2

模組分析（逐模組 + 逐單元，依優先序）

↓

資料庫分析（來自資料庫物件列舉）

↓

介面分析

---

階段 3

領域變數推導

↓

業務規則抽取（逐單元，套用領域變數判定）

↓

時序探索（逐單元）

---

階段 4

逐單元規格產生

↓

系統規格產生

↓

Characterization 測試產生

↓

差異分析（先過期檢查，再深度檢查，兩者皆由工具執行）
