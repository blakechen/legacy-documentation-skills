# 管線（Pipeline）

階段 1

清冊盤點（Inventory）

↓

技術探索（Technology Discovery）

↓

架構探索（Architecture Discovery）＋ 自訂框架偵測

---

階段 1.5

交易類別列舉（Transaction Class Enumeration）

↓

資料庫物件類別列舉（DB Object Class Enumeration）

↓

Servlet 列舉（Servlet Enumeration）

---

階段 2

模組分析（每個模組 ＋ 每筆交易）

↓

資料庫分析（依據資料庫物件列舉結果）

↓

介接分析（Interface Analysis）

---

階段 3

業務規則萃取（每個交易類別）

↓

循序探索（每個交易類別）

---

階段 4

逐交易規格產生（Per-Transaction Specification Generation）

↓

系統規格產生（System Specification Generation）

↓

落差分析（Gap Analysis）
