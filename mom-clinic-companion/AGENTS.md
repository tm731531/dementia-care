# mom-clinic-companion — Agent Team Configuration

> 繼承母層規則：`../AGENTS.md`。只列專案特有 perspectives。

## Project-Specific Perspective Inventory

| Perspective | Risk | Scope | Score | Notes |
|--|--|--|--|--|
| User（Tom 本人）| 3 | 3 | 9 | 回診前 5 分鐘用，一指操作 |
| PM（資料閉環）| 3 | 3 | 9 | 這是整個 repo 的核心應用，不能斷 |
| Tester | 3 | 2 | 6 | 離線策略 + 規則引擎準度要驗 |
| Implementer (HTML/CSS/JS) | 2 | 2 | 4 | 單檔 |
| Architect | 3 | 2 | 6 | 離線 cache + 雙環境切換（local/prod）|
| Security | 3 | 2 | 6 | iDempiere token + 醫療資料 |
| Domain expert（失智症狀）| 3 | 3 | 9 | 13 類症狀關鍵字 + 排除詞 |
| Domain expert（iDempiere）| 2 | 2 | 4 | REST API + CORS + token |

## Agents

| Agent | Model | Memory | Primary | Folded | Priority |
|--|--|--|--|--|--|
| architect | opus | 1.0 GB | Architect, Security | PM | Security > Arch > PM |
| domain-medical | opus | 1.0 GB | Domain(症狀), Tester | User | Domain > Tester > User |
| idempiere-impl | sonnet | 0.6 GB | Impl, Domain(iDempiere) | - | Impl > Domain |

總計 2.6 GB。

## Project-Specific Rules

### 寧缺勿錯（醫療資料）
規則引擎偵測不到異常時，顯示「這個月沒有明顯異常，你可以跟醫生分享平穩狀況」，
**禁止**編造異常。漏報比誤報好——醫生會自己問。

### 13 類症狀關鍵字必有 exclude
新增關鍵字時，同步加 exclude 避免誤抓：
```js
'拒食': { include: ['不吃','拒絕'], exclude: ['吃不完','吃太多'] }
```
沒加 exclude 的新類別直接拒絕 commit。

### 離線 cache 必須新舊並存
網路斷線時讀 localStorage cache，顯示「離線版本，最後同步 XX:XX」。
**不得**只在網路連線時才能用——診間常常收訊差。

### 雙環境切換
```js
const API_BASE = location.hostname.startsWith('localhost')
  ? 'http://localhost:8080'      // SuperUser/System
  : 'https://idempiere.tomting.com'  // Tom/Tom
```
改 API endpoint 時兩邊都要測。

### iDempiere schema 變動同步
若 `Z_momSystem` 欄位改了，這個 app + whiteboard-ocr-bot 同時要改。
改一個忘了改另一個 → 資料閉環斷掉。

## Re-Evaluation Triggers
- iDempiere 升級版本 → CORS filter path 重驗
- 新增症狀類別 → domain-medical agent 必須審 include/exclude 對
- 醫生問「還有什麼沒看到？」→ 規則引擎加一層
