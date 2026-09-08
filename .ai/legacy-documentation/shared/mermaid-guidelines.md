# Mermaid 指引

## 目標

產生一致的 Mermaid 圖表。

---

## 支援的圖表類型

flowchart

sequenceDiagram

erDiagram

classDiagram

stateDiagram

---

## 規則

只產生已驗證的關聯。

不要憑空造出節點。

使用原始的元件名稱。

避免裝飾性樣式。

保持圖表可讀。

---

## Flowchart

用於

架構

模組關聯

---

## Sequence Diagram

使用

僅限已驗證的互動。

納入參與者（actor）。

適當時顯示 activation。

---

## ER Diagram

使用已驗證的實體。

未知的基數（cardinality）是可以接受的。

不要推測關聯。

---

## 驗證

產生的 Mermaid 必須能成功繪製。
