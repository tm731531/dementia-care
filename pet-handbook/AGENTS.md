# pet-handbook — Agent Team Configuration

> 繼承母層規則:`../AGENTS.md`。這份只列本專案特有的內容。
> **pet-handbook 是 content-heavy 靜態資源**,不需複雜 agent team。

## Project-Specific Perspective Inventory

| Perspective | Risk | Scope | Score | Notes |
|--|--|--|--|--|
| 👨‍👩‍👧 新寵物奴(讀者) | 3 | 3 | 9 | 第一次養、壓力高、凌晨查資料 |
| 🐾 寵物本身(間接受眾) | 3 | 2 | 6 | 錯誤做法會永久傷害親訓關係 |
| 🧑‍⚕️ 獸醫角度 | 2 | 2 | 4 | 醫療內容要正確,不能誤導 |
| Writer | 2 | 2 | 4 | 每個 topic 結構一致、連貫 |

## Agents

| Agent | Model | Memory | Primary Perspectives | Priority |
|--|--|--|--|--|
| writer | sonnet | 0.6 GB | 新寵物奴、寵物本身 | P1 |
| reviewer | sonnet | 0.6 GB | 獸醫、writer | P2 |

總計 1.2 GB。單人專案,大幅擴充時才啟動 agent 協作。

## Project-Specific Rules

### 醫療資訊不取代獸醫
疫苗時程、常見症狀可以寫,但**不做獸醫急診建議**(執照範圍)。所有醫療相關內容要註明「仍需獸醫確認」。

### 親訓方法要嚴守
訓貓筆記是「不推薦強迫式」的態度。任何 entry 都不能暗示「抓起來就親了」這類做法,會傷害貓也違背 handbook 立場。

### 不推銷、不商業化
飼料品牌紀錄是 Tom 自己實測的評比,不是 affiliate。不加購物連結。

### 不公開 Tom 家個別寵物資料
妹妹、小胖胖這兩隻貓的詳細紀錄(體重、費用、日期)留在 Tom 的 HackMD 私人筆記。handbook 內容是**通用 knowledge**,不是個人日誌。

## Re-Evaluation Triggers
- 有獸醫貢獻者加入 → 把獸醫 perspective 升級為專屬 agent
- 超過 10 個 topics → 可能要加 schema validator
- 有讀者 PR 加新飼料評比 → 加 reviewer 檢查 affiliate/商業內容
