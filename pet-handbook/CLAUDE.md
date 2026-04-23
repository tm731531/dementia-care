# pet-handbook — 寵物手冊

## 專案簡介
一本**家中寵物生活手冊**,按物種分類(貓、狗、兔、鳥、魚、烏龜),每個物種下有多個 topics 涵蓋親訓、飼料、醫療、訓練等主題。

**核心定位:家中寵物也是一種療法**。寵物陪伴對失智長輩、小孩、照顧者自己都有療癒意義 —— 這跟 repo 的 mission「讓整個家忙起來」完全對齊。

跟 `garden-handbook` 平行,兩個都是 repo 的療法載體:
- `garden-handbook` → 植物(可食 + 觀葉)
- `pet-handbook` → 寵物(目前以貓為主,陸續擴充)

## 資料來源
Tom 多年整理的 HackMD 筆記,整合成手冊格式。目前貓的部分來自:
- [訓貓](https://hackmd.io/@2GrxaqznSJKLrhmXwCaeug/By9hkAg4s)
- [飼料](https://hackmd.io/@2GrxaqznSJKLrhmXwCaeug/H1NWv0lVi)
- [我家的貓](https://hackmd.io/@2GrxaqznSJKLrhmXwCaeug/ryCmhpJNj)

其他物種資料待補。

## 技術架構
- **單一檔案**:`index.html`(所有內容都在裡面)
- **純前端**:HTML + Vanilla CSS + 原生 JS,複用 garden-handbook 的 page system pattern
- **離線可用**
- **🔴 零外部 CDN 依賴**
- **狀態**:localStorage key `petHandbookState`
- **Favicon**:SVG inline emoji(🐾)

## 內容結構

**Category(物種)→ Topic(主題)→ Sections(內容)**,跟 garden-handbook 同一 pattern(植物類別 → 植物 → sections)。

### Categories(tab bar,按物種)
- 🐱 貓(目前有 6 個 topics)
- 🐶 狗(待擴充)
- 🐰 兔(待擴充)
- 🐦 鳥(待擴充)
- 🐠 魚(待擴充)
- 🐢 烏龜(待擴充)

### 核心 knowledge section:失智照護 × 寵物選擇指南

放在 `page-knowledge` 頂部(預設展開)。包含:
- 寵物作為一種療法的核心觀念(感官陪伴、時間感、情緒調節)
- 不同物種在失智 context 的適配度 matrix(輕度/中度/重度)
- 選擇原則
- 已有寵物時的家庭應對
- 寵物陪伴的具體做法

這是 pet-handbook 跟純寵物 how-to 手冊的**差異化核心**。

### Topic Schema(flexible)
每個 topic 包含:
- `meta`:適用情境、難度、時間尺度、所需物品等
- `sections`:chunks of content,每個 section 是 `html`(未來可用 `byLevel` 對應年齡階段)

## 與 garden-handbook 的差異
- **Categories = 物種**(不是主題分類)
- **沒有失智 3 級 byLevel 機制**(但 schema 保留,未來可接「幼體/成體/老年」)
- **沒有「實測」vs「通識」標註**
- **不包含個別寵物的私人紀錄**(妹妹/小胖胖那些留在 Tom 私人 HackMD)

## 目前 entries(全在 🐱 貓 category)
- 🤝 親訓新貓
- 👥 多貓介紹 SOP
- 🍲 飼料挑選原則
- 🌾 貓草種植
- 💉 疫苗接種時程
- ❄️ 冬天保暖

## 未來 entries(待擴充)

### 貓(繼續擴充)
- 剪指甲、抱貓訓練
- 罐頭評比
- 結紮、驅蟲、健檢時程
- 安全居家環境

### 狗
- 基礎訓練(坐下、握手、等等)
- 社會化 SOP
- 散步禮儀
- 飼料選擇(貓狗需求不同)

### 其他物種
- 兔子:環境設定、飲食禁忌、咬人行為矯正
- 鳥類:鳥籠設置、放飛訓練
- 觀賞魚:水族設定、水質管理

## 設計原則
- 繁體中文
- 紫色主題(跟 garden-handbook 綠色、dementia 橘色區別)
- Emoji 全用 Unicode 10 以下(避免某些系統顯示空框)
- 可列印
- 零外部 CDN

## 開發指引
- 所有內容放 `index.html`
- 加新 topic:在 JS 的 `TOPICS` array push 一個 entry,設定對的 `category`(cat/dog/rabbit/bird/fish/turtle)
- 加新 category(新物種):在 `CATEGORIES` push + 對應 topics
- 發佈前 grep:`grep -n -E 'https?://[^"]*\.(com|net|org|io)' index.html | grep -v 'tomting\|github\|data:\|hackmd'`

## 踩過的坑
- 原本叫 `cat-handbook`,寫完 6 個貓 topics 才意識到 scope 太窄 — 家中寵物不只貓。重命名為 `pet-handbook`,categories 從「主題分類」改成「物種分類」,貓的 6 個 topics 全移到 🐱 貓 category 下。Learning:**新 handbook 第一步先決定是一層分類還是多層分類,不要先寫內容**。

## Domain Brain
- `~/.claude/projects/-home-tom/memory/brain/design-principles.md`(通用設計規則)

## 檔案結構
```
pet-handbook/
  CLAUDE.md          # 本檔案
  AGENTS.md          # Agent 團隊設定
  README.md          # 使用說明
  index.html         # 手冊主體(所有內容)
  docs/
    superpowers/
      plans/
        2026-04-23-current-state.md
```

## 部署
- GitHub Pages: `https://tm731531.github.io/dementia-care/pet-handbook/`
- 純靜態
