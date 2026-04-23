# garden-handbook — Agent Team Configuration

> 繼承母層規則:`../AGENTS.md`。這份只列本專案特有的內容。
> **handbook 是 content-heavy 靜態資源**,不像 app 那樣需要複雜 agent team。以下是 minimal setup。

## Project-Specific Perspective Inventory

| Perspective | Risk | Scope | Score | Notes |
|--|--|--|--|--|
| 👨‍👩‍👧 照護者(新手讀者) | 3 | 3 | 9 | 凌晨三點 Google 撞到這,需要快速看懂、快速行動 |
| 🧓 失智長輩(間接受眾) | 2 | 2 | 4 | 不會直接讀,但每個 entry 的設計決策要考慮「讓她能參與」|
| 🧒 小孩(間接受眾) | 1 | 2 | 2 | 有些植物可設計成「小孩看得到、會一起玩」的活動 |
| 🧑‍🌾 植物領域專家 | 2 | 2 | 4 | 確保種植知識正確,避免誤導新手 |
| Writer/Implementer | 2 | 2 | 4 | 每個 entry 的結構一致性、HTML 有效性 |

## Agents

| Agent | Model | Memory | Primary Perspectives | Priority |
|--|--|--|--|--|
| writer | sonnet | 0.6 GB | 照護者、小孩、植物專家 | P1 |
| reviewer | sonnet | 0.6 GB | 失智長輩、領域專家 | P2 |

總計 1.2 GB。單人專案,通常 Tom 自己寫。

### 平行 subagent 模式(驗證過,2026-04-23)

大量擴充(一次加 5+ 個 plants)時:
- 寫一份 SPEC.md 給所有 subagent 共讀
- 派 N 個 `general-purpose` agent(sonnet, 各 ~0.6GB)平行寫
- 每個 agent 寫到 `/tmp/plant-entries/new-<id>.js`
- Python 腳本批次整合

本輪實測:單日擴充 17 個 plants,比逐個寫省 ~80% 時間。
memory footprint:9 agents × 0.6GB = 5.4GB,16GB 機器無壓力。

## Project-Specific Rules

### 事實正確性優先
每個植物的種植知識(等待時間、光需求、採收方式)必須**基於實測或可信來源**。新手照著做失敗會破壞 repo 的信任。Tom 家實測過的優先寫,其他植物從可信園藝書/政府農業推廣網站引用。

### 失智照護 notes 不得省略
本手冊的差異化價值在「失智照護應用 Notes」這個 section。即使某植物看起來跟失智照護無關(例如觀賞性強的香草),也要寫出「這個植物對失智長輩的意義是什麼、或為什麼不適合」。

### 不推銷、不商業化
不放購物連結、不收 affiliate、不收錄商業產品評價。這個 handbook 的底線是「公開、免費、無廣告」,跟 repo 其他部分一致。

## Re-Evaluation Triggers
- 新增 entry 超過 5 個 → 考慮增加 schema validator agent
- 有貢獻者 PR 時 → 加 review agent,重點看失智照護 notes 的品質
- 有失智領域的專業回饋(OT、醫師) → 把 domain expert 升級為專屬 agent
