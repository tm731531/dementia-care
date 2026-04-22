# {{PROJECT_NAME}} — 開發指引

> 新專案 scaffold 模板。複製過去後：
> 1. 用實際內容取代所有 `{{VAR}}` 佔位
> 2. 刪除不適用的章節（例如純前端專案就刪 Python 相關）
> 3. 把這段說明刪掉

## 專案簡介
{{一句話說這個工具做什麼、給誰用、為什麼存在}}

## 技術架構
- **單一檔案** / **Python** / **其他** → 勾一個
- **純前端** / **前端 + REST API** / **Python daemon** → 勾一個
- **狀態**：localStorage key `{{APP_KEY}}` / 檔案 / 資料庫
- **Favicon**：SVG inline emoji（{{EMOJI}}）

## 全域狀態結構（若適用）
```javascript
const APP = {
  // 列出主要欄位
}
```

## 核心功能
1. {{功能 1}}
2. {{功能 2}}
3. {{功能 3}}

## 設計原則
- {{使用者是誰 → 對應的設計約束}}
- {{離線？外部 API？什麼必須保留/避免}}
- 所有文字繁體中文（除非有特殊理由）
- **🔴 零外部 CDN 依賴**:不得用 Google Fonts / CDN / 外部 script。字型靠系統 fallback 或 base64 inline。詳見 `../CLAUDE.md` 共用原則。

## 開發指引
- {{單檔 / 多檔規範}}
- {{新功能要同步更新哪些檔案}}
- {{改完驗證步驟}}

## 踩過的坑（隨時間累積）
目前沒有。遇到坑 → 修完寫進來 + 同步寫進對應 Brain file。

## Domain Brain
從 `~/.claude/projects/-home-tom/memory/brain/` 選：
- `design-principles.md`（必讀）
- {{其他依技術棧挑}}

## 檔案結構
```
{{PROJECT_NAME}}/
  CLAUDE.md          # 本檔案
  AGENTS.md          # Agent 團隊設定
  README.md          # 使用說明
  index.html         # 應用主體（若 HTML app）
  docs/
    superpowers/
      specs/         # 設計討論
      plans/         # 實作計畫
```

## 部署
- GitHub Pages: `https://tm731531.github.io/dementia-care/{{PROJECT_NAME}}/`
- {{或其他部署方式}}
