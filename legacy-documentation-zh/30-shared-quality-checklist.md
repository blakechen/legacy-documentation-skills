# 全域品質檢查清單

每個 Skill 都應驗證：

- 已記錄證據
- 引用有效
- 無幻覺內容
- 無重複的發現
- 無未記錄的假設
- 缺少證據時已寫「Unknown（未知）」
- 術語一致
- Markdown 格式正確
- Mermaid 語法正確（若有）
- 已產生輸出檔案
- 可追溯性已保留

---

# 機械式關卡

「宣稱」不等於「驗證」。
以下每一道關卡都是一個具有結束狀態碼的指令，
擁有該關卡的 Skill 應「執行」它。見 shared/mechanical-verification.md。

| 關卡 | 指令 | 負責 Skill |
|---|---|---|
| 已建立 factbase | `tools/factbase/build_factbase.sh` | fact-extraction |
| 原始碼掃描已獨立檢查 | `tools/factbase/verify_bytecode.sh` | fact-extraction |
| 列舉由 factbase 推導 | `tools/factbase/enumerate.sh` | artifact-enumeration |
| 單元已依價值排序 | `tools/factbase/prioritize.sh` | artifact-enumeration |
| 已收斂 clone 家族 | `tools/factbase/archetypes.sh` | archetype-clustering |
| 已推導領域變數 | `tools/factbase/domain_variables.sh` | business-rule-extraction |
| 架構模型已受檢驗 | `tools/reflexion/reflexion.sh` | reflexion-check |
| 文件達到深度完備 | `tools/verify/depth_checks.sh` | gap-analysis |
| 文件符合現行原始碼 | `tools/verify/staleness.sh` | gap-analysis |

若某個 Skill 在沒有指令輸出的情況下回報關卡通過，即違反本檢查清單。

---

# 自我測試

工具本身有 fixture 覆蓋：

    sh tools/selftest.sh

工具變更若改動了
`examples/fixtures/java-dispatcher/expected/` 中的預期輸出，
在那些檔案被刻意更新之前，都視為迴歸。
