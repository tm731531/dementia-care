# care-record-app — 開發指引

## 專案簡介
給**其他照顧者家庭**用的離線照護紀錄 App（Flutter，iOS + Android）。用**講的**記事件筆記
（手機端 whisper.cpp 離線轉字）+ **點選** 12 個結構項目，資料只存本機、零雲端，回診前匯出
ZIP 或單檔 HTML/PDF 給醫生看。是 `whiteboard-ocr-bot`（Tom 自用 Telegram bot）的**家庭獨立版**，
但不寫 iDempiere、不碰雲端、不需要任何 API key。

> **完整設計依據見** `docs/superpowers/specs/2026-07-23-family-app-design.md`
> （含 OCR 61-67% 實測、語音 small 模型實測等真實數字）。

## 這個 sub-project 的例外身分
- **不是** monorepo 的「單檔 HTML / 0 build」那類。這是 **Flutter 原生 App、有 build、要上架商店**。
  跟 `whiteboard-ocr-bot`（Python 例外）一樣，是 monorepo 內的技術例外。
- index.html landing 只放一張**介紹卡片**（連到 App 介紹 / 商店 / 單檔 HTML landing），
  App 本體不由 GitHub Pages 部署。
- 2026-07-23：Tom 明確 override `../CLAUDE.md` 規則 1（直接開、不先寫 blog）。

## 技術架構
- **Flutter**（單一 codebase → iOS + Android）
- **離線語音轉文字**：`whisper.cpp`，small 模型（量化後約 180MB），bundle 進 App、零網路
- **相機**：`camera` plugin（底層 CameraX / AVFoundation）
- **本機儲存**：加密的本地 DB（SQLite/類似）+ 照片附件，落地加密
- **零雲端 / 零帳號後端 / 零 API key**

## 核心功能
1. 事件筆記用**語音**輸入（離線轉字 + 可微調），一天可多筆、帶時間戳 + 作者標記
2. 12 個結構項目**點選**（睡眠/三餐/排泄…）→ 驅動趨勢圖
3. 白板照片**選配**存證
4. 匯出 **ZIP**（資料 + 照片）→ 使用者自選管道傳（LINE/USB…）→ 對方匯入合併
5. 產**單檔 HTML/PDF** 給醫生（趨勢圖 + 乾淨筆記 + 照片），任何裝置免裝 App 直接開
6. **生物辨識鎖**（臉/指紋）+ 背景自動上鎖，無密碼可打/可忘

## 設計原則（硬約束，來自 spec §2）
- **零雲端 / 只存本機**（避台灣特種個資責任 §6；讓 Tom 不在使用迴圈 → 零人情負擔）
- **消滅打字**（語音 + 點選，不用鍵盤）
- **醫生看文字非照片**（醫生沒空一張張翻照片）
- **現場零摩擦**（不在現場 KEY 密碼、不每筆手動搬檔、換手機零設定）
- **不做手寫 OCR**（實測 61-67% 且錯在臨床關鍵詞，違反寧缺勿錯）
- 所有 UI 文字繁體中文
- 低視力對比：米白底深字（#222 on #f5f5f5）/ 字級 ≥ 24px（見母層 CLAUDE.md 白內障 frame）

## 開發指引
- 改完至少跑一次真機/模擬器 smoke test，確認語音轉字 + 匯出/匯入 + 解鎖三條主線可跑
- whisper 模型大小若調整，同步更新 spec §5 + README
- 動到合併邏輯，先回讀 spec §4.5（union + 新者勝 + 作者標記）

## 踩過的坑（隨時間累積）
目前沒有。遇到坑 → 修完寫進來 + 同步寫進對應 Brain file。

## Domain Brain（動工前讀）
從 `~/.claude/projects/-home-tom/memory/brain/` 選：
- `design-principles.md`（必讀）
- `flutter-app-development.md`（Flutter 主技術棧）
- `dementia-care-field-delivery.md`（低視力 / 現場交付）
- `python-llm-integration.md` / `llm-conversation-grounding.md`（語音轉字後若做結構抽取）

## Domain Skill
- `flutter-web-canvaskit-e2e`（Flutter 驅動 / E2E 驗證模式，供 smoke test 參考）

## 檔案結構
```
care-record-app/
  CLAUDE.md          # 本檔案
  AGENTS.md          # Agent 團隊設定
  README.md          # 使用說明
  docs/superpowers/
    specs/           # 設計 spec（權威設計依據）
    plans/           # 實作計畫
  （Flutter 專案結構待 writing-plans 後建立：lib/ ios/ android/ pubspec.yaml …）
```

## 部署
- App 本體：App Store + Play Store（自載）
- index landing 卡片：`https://tm731531.github.io/dementia-care/`（母層 index.html 一張卡）
