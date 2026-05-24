# 打地鼠體感方向偵測 — 失敗演算法事後分析

> 目的:記錄我從 v7.2 → v7.3 為什麼改演算法,讓未來踩同樣坑的人(包含我自己)能直接讀到結論,不用再重新推導一次。

## TL;DR

v7.2 用「**diff pixel 的 Y 重心**」判斷方向 — **錯**。因為 diff 的中心剛好夾在「手原本位置」和「手新位置」中間,往下往上都是中間,根本沒方向性。

v7.3 改用「**對比物體(手)在當前幀的 Y 重心**」 — 對。手在哪,重心就在哪。下一幀比一下,真的能算出 dy。

## 問題定義

使用者反映:打完地鼠手往上收的時候,**收手動作經過上面那格如果有地鼠也會被當成打中**。希望「上往下才算打擊,下往上不算」。

技術上要在純 JS pixel-diff loop 裡多加方向判斷(零外部 lib,符合 monorepo 規則)。

## v7.2(錯)— Diff pixel 的 Y 重心

### 怎麼做

```js
// 對每個 cell:
var changed = 0;
var changedSumY = 0;
for (each pixel in cell) {
  if (|gNow - gPrev| > threshold) {
    changed++;
    changedSumY += y;
  }
}
var centroidY = changedSumY / changed;
// 跟上一幀比 dy = centroidY - lastCentroidY
```

直覺上看起來:手在哪,diff 就在哪;手往下動,diff Y 重心往下移。對吧?

### 為什麼錯

手往下揮的時候,**有兩塊區域有 diff**:
- **A 區(手原本位置,上方)**:上幀有手,這幀沒了 → pixel 變亮(或變暗)→ |diff| > threshold ✓
- **B 區(手現在位置,下方)**:上幀沒手,這幀有了 → pixel 變了 → |diff| > threshold ✓

```
上幀 (t-1)            這幀 (t)              Diff
┌─────────┐          ┌─────────┐          ┌─────────┐
│   ✋    │          │         │          │  A區    │ ← 變了
│         │    →     │         │    =     │         │
│         │          │   ✋    │          │  B區    │ ← 變了
└─────────┘          └─────────┘          └─────────┘
```

diff 的 Y 重心 = (A 區 Y + B 區 Y) / 2 = **中間值**。

手往上揮也一樣:
```
上幀                  這幀                  Diff
┌─────────┐          ┌─────────┐          ┌─────────┐
│         │          │   ✋    │          │  上A    │ ← 變了
│         │    →     │         │    =     │         │
│   ✋    │          │         │          │  下B    │ ← 變了
└─────────┘          └─────────┘          └─────────┘
```

diff Y 重心一樣是 (上 A + 下 B) / 2 = **中間值**。

**結論:diff centroid 對稱於運動方向的中點,完全沒方向性**。dy 永遠在 0 附近,判定不出來。

### 為什麼以為對

容易混淆「diff 的 centroid」跟「物體的 centroid」。前者是「**哪邊在變化**」,後者是「**物體現在在哪**」。對單方向運動而言,變化發生在物體前後兩端,所以變化 centroid 是中點,跟物體當前位置不一樣。

## v7.3(對)— 對比物體當前幀的 Y 重心

### 怎麼做

**追蹤「手在當前幀的位置」**,不是「diff」。

```js
// Pass 1:算當前幀 cell 平均亮度
var sumNow = 0;
for (each pixel in cell) sumNow += gNow;
var mean = sumNow / total;

// Pass 2:每個 pixel 用 |gNow - mean| 當權重,算 weighted Y
var weightedY = 0;
var weightSum = 0;
for (each pixel in cell) {
  var w = |gNow - mean|;     // 跟平均差越多 = 越「醒目」= 手在那
  weightedY += w * y;
  weightSum += w;
}
var centroidY = weightedY / weightSum;

// 比上一幀
var dy = centroidY - hole.lastCentroidY;
var isUpward = dy <= -Y_DELTA_THRESHOLD;  // 明顯往上 → 不算打擊
```

### 為什麼這個對

`|gNow - mean|` 把**偏離平均色**的像素標出來。手跟背景對比強(無論手亮 bg 暗,還是反過來),手所在區的 |dev| 大,重心自然落在手上。

```
這幀:手在中間
┌─────────┐
│   ░░    │  ← bg pixels: |gNow - mean| 小
│   ✋    │  ← 手 pixels: |gNow - mean| 大 → 重心拉到這
│   ░░    │  ← bg pixels: |gNow - mean| 小
└─────────┘
```

下一幀手往下移:
```
┌─────────┐
│   ░░    │
│   ░░    │
│   ✋    │  ← 重心拉到下面
└─────────┘
```

`dy = currCentroidY - lastCentroidY > 0` → 確實是往下。

往上揮就 dy < 0,被 `isUpward` 攔下來。

### 為什麼用 mean 不用固定值(如 128)

亮度會被環境光影響。下午陽光下整個畫面平均亮度可能 200,陰天可能 80。固定用 128 當基準會在極端光線下把整個畫面都當成「偏離」,centroid 變雜訊。

用當前幀的平均 mean 當基準是自適應的 — 不論環境光多亮多暗,「偏離 mean 越多」永遠抓得到對比物體。

### 效能

兩遍 cell pixels 看似翻倍,實際:
- Cell 32×120 = 3,840 pixels
- 5 cells × 30fps × 2 pass = 1.15M ops/sec
- 現代手機 / 平板 idle clock 10-100M ops/sec 等級

完全感受不到差異。

## 跟「真正的方案」比較

| 方案 | 體積 | 準確度 | 適合場景 | 為什麼我們不用 |
|---|---|---|---|---|
| **MediaPipe Hands** | ~10 MB WASM + model | ★★★★★(關節級) | AR 手勢、手語 | **違反 0 CDN 規則**;載入慢;殺雞用牛刀 |
| **TensorFlow.js PoseNet** | ~12 MB + model | ★★★★(全身關節) | 體感遊戲 | 同上 + 對「揮手」這種粗動作 overkill |
| **OpenCV.js Optical Flow**(Lucas-Kanade) | ~8 MB WASM | ★★★★(光流向量) | 移動物追蹤 | 同上 + 我們只要 1D 方向不需 2D 向量 |
| **OpenCV.js frame differencing** | ~8 MB | ★★(同我們) | — | 我們手寫等同效果不用 8 MB |
| **Three-frame differencing(自寫)** | 0(同一個 JS) | ★★★(可分方向) | 簡單方向偵測 | 要存 3 幀記憶體較重;v7.3 更輕 |
| **v7.3 contrast-weighted centroid**(我們選) | 0 | ★★★ | **打地鼠這種「方向感」夠用** | **就是我們** |

### MediaPipe Hands 為什麼這麼準

MediaPipe 跑兩個 model:**Palm Detection** 找手在哪、**Hand Landmark** 在那塊定位 21 個關節點(指尖、指根、手腕等)。可以精確算出指尖位置、揮動軌跡、甚至「比讚」「OK」等手勢。

跟我們的差異是「**位置 + 結構**」vs「**位置**」。對「揮手打地鼠」這種**只需要知道大致方向**的場景,結構資訊用不到 — 你不需要知道哪根手指先抵達地鼠,只需要知道有東西從上往下移動就好。

### Optical Flow (Lucas-Kanade) 為什麼也是 overkill

LK 跑一個假設:相鄰像素在很短時間內有相同位移。它解一個 2x2 矩陣得到 (vx, vy) — **每個像素點的向量**。對需要精確軌跡(機器人避障、AR 物件追蹤)是強大工具。

但我們只需要回答**「這個 cell 裡的物體往哪移?」**這個一維問題。LK 算了一堆 vx 我們根本不會用,還要解矩陣。

### Three-frame differencing 為什麼也不需要

經典方法:存 t-2、t-1、t 三幀。`diff(t-1, t-2)` 知道前一個運動方向,`diff(t, t-1)` 知道現在運動方向。可以從變化序列推方向。

但對 cell 內單一物體運動,**對比物體的 centroid 本身就帶位置資訊**,根本不需要存第三幀。記憶體佔用少一半 + 演算法簡單。

## 教訓

### 1. 「直覺」常常會錯,要先在腦中跑一遍 N=2 的 case

我寫 v7.2 的時候自我感覺良好。實際畫一下「上幀 + 這幀 + diff」的圖,30 秒就會發現對稱性問題。**演算法寫之前先在腦中模擬最簡單的例子**,90% 的 bug 在這階段就會被攔下來。

### 2. 「diff」跟「state」是兩個東西,別搞混

- **Diff** = 變化發生在哪 → 對運動是雙端對稱的
- **State** = 物體現在在哪 → 對運動是單端,跟著物體走

要追位置 → 用 state。要偵測「有沒有動」→ 用 diff。要追方向 → 用 state 的時序變化。

### 3. 跨 lighting 的 weight 函數要自適應

`|g - 128|` 看似簡單,但下午跟晚上算出來重心會偏向不同 pixel 群(陰影 / 高光)。用 `|g - mean|`(當幀平均)就自然校正。**寫 image processing 的常識,但容易忘**。

### 4. 純 JS pixel manipulation 跑得比想像快

不要動不動就去找 lib。32×120 pixel cell 兩遍是 ~7,680 reads 一幀,RAF 30fps 是 ~230K reads/sec。**比 MediaPipe load 一次 model 還便宜**。對「玩具級」遊戲足夠了。

## 結論

v7.3 不是最先進的,但是**用最少 code 達到「上下方向能分」的最低必要工具**。如果未來想升級到「分辨揮拳 vs 揮掌 vs 滑過」這種細的,再考慮上 MediaPipe。在那之前,contrast-weighted centroid 是 0 dependency 的甜蜜點。

---

## 後續調參點

如果還是不夠靈 / 太靈,在 console 打:
- `WHACK_TUNING.Y_DELTA_THRESHOLD = 4`(原 6)— 更敏感的方向判定
- `WHACK_TUNING.Y_DELTA_THRESHOLD = 10` — 更嚴格,要明顯上揮才忽略
- `WHACK_TUNING.DEBUG_OVERLAY = true` — 每洞顯示 diff% + ↓↑· 方向箭頭

## 程式碼位置

`kids-companion/index.html`,搜尋 `#SECTION:WHACK-LOGIC` → `startWhackDiffLoop()`。

## Commit 紀錄

- v7.2 (失敗):`57614a9 feat(kids-companion): 體感 v7.2 — 揮手方向偵測,只往下算打擊`
- v7.3 (修正):`6ca5902 fix(kids-companion): 體感 v7.3 — 改用對比物體 Y 重心追方向(diff centroid 沒方向性)`
