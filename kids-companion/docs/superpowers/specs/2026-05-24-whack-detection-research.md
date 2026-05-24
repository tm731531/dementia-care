# 打擊偵測研究：打地鼠遊戲如何定義「打中」

> 研究日期：2026-05-24
> 目的：為 kids-companion 打地鼠 activity 的體感偵測找參考方向
> 問題背景：純 JS pixel-diff + Y centroid 迭代 5 次仍不穩，使用者抱怨「上往下才算」、「太遲鈍」、「又太敏感」

---

## 既有 App 怎麼做（各類型）

### 類型 1：純觸控 / 點擊（最主流）

幾乎所有 mobile 打地鼠遊戲都是純 tap 機制。Google Play 的 [Whack a Mole by Mark Hughes](https://play.google.com/store/apps/details?id=com.markhughestech.WhackaMole&hl=en_US)、[ANNKIE Whack A Mole (Walmart)](https://www.walmart.com/ip/AFMAT-Whack-Mole-Game-Toys-5-Year-Old-Boys-Hammer-Toy-Interactive-Educational-Toys-Early-Developmental-Toys-Kids-PK-Mode-2-Kids-Large-Size-Pounding-T/189804249) 等都屬此類。偵測邏輯極簡單：touch event 座標是否落在地鼠 bounding box 內。這個方向對我們沒參考價值，但它「永遠不會有誤觸問題」是值得記下的事實。

### 類型 2：相機 + 骨架追蹤（MediaPipe / PoseNet）

目前最成熟的相機體感方案。[Taras Skavinskyy 的 AI Gesture Whak-A-Mole（Medium，2024）](https://medium.com/@skavinskyy/making-an-ai-gesture-recognition-whak-a-mole-game-bb89b496c611) 使用 **MediaPipe Holistic** 追蹤手部 21 個 landmark，拿手腕/手掌座標跟地鼠位置算 Pythagorean distance，距離小於 threshold（0.1 歸一化座標）就算打中。這個實作的「打中」定義是**位置重疊**，不是揮動方向。

[GitHub: stevechanvii/WhackMole](https://github.com/stevechanvii/WhackMole) 則用 TensorFlow.js PoseNet，讓玩家舉手臂打不同欄位（arm up = 打第 1 欄，clap = 打中欄）—— 這是用**姿勢分類**而非揮動偵測。

這兩個專案的共同點：依賴外部 ML CDN（MediaPipe 或 TF.js），不能 inline 進單一 HTML。

### 類型 3：AR 空間追蹤

[App Store: Whack-A-Mole AR Video Games (id6475080174)](https://apps.apple.com/us/app/whack-a-mole-ar-video-games/id6475080174) 描述是「tap, swipe, and interact」，表示仍是觸控驅動，AR 只是提供視覺場景。

[AppGameKit AR Whack A Mole](https://appgamekit.com/showcase/game/ar-whack-a-mole) 和 Apple Vision Pro 上的實驗性版本則利用深度感測器做空間碰撞偵測 —— 這需要 ARKit / ARCore 硬體支援，瀏覽器無法複製。

GestureRhythm（[Medium, 2024](https://medium.com/antaeus-ar/gesturerhythm-ar-rhythm-game-with-real-time-hand-tracking-and-computer-vision-51faf1c83acd)）用 MediaPipe 追蹤 index finger 在 Z 軸（深度）的位移，設定「靜止位置」和「按下位置」兩個閾值，只有向前推才算有效。這是目前為止**最接近「方向約束」**的做法，且用的是相機而非觸控。

### 類型 4：陀螺儀 / 加速度計（手機當鎚子揮）

[GitHub: bsdocke/Whack-A-Mole（Android）](https://github.com/bsdocke/Whack-A-Mole) 使用加速度計讓玩家「實際揮動手機」砸地鼠。Nintendo Switch 上的 [Whack First! - Fight the Moles](https://www.nintendo.com/us/store/products/whack-first-fight-the-moles-switch/) 也有 Joy-Con motion control 版本。Joy-Con 使用 LSM6DS3 六軸 IMU，以 740Hz 輪詢加速度 + 陀螺儀，做到精準揮擊偵測。

Web 平台理論上有 `DeviceMotionEvent` API，但：(1) iOS 17+ 需要使用者明確授權，(2) 無法知道手在哪個地鼠上方，需要配合顯示座標才能知道打哪一隻。這個方向在純 web 有先天侷限。

---

## 物理鎚子玩具怎麼做

### 1. 桌面型電子玩具（最常見）：接觸式壓感開關

市面上最常見的兒童打地鼠玩具（Liberty Imports、TEMI、VATOS 等，均見 [Amazon](https://www.amazon.com/whack-mole-game-Toys-Games/s?k=whack+a+mole+game&rh=n:165793011)）的地鼠頭用的是機械式**接觸開關**（contact switch）。地鼠彈出時，鼠頭上方有一個可下壓的按鈕；用鎚子打中就觸發這個開關，MCU 接到訊號後計分並縮回地鼠。

偵測邏輯：**接觸 = 打中**，沒有方向概念，沒有速度概念。只要壓下去就算。

### 2. 街機版（Bob's Space Racers Whac-A-Mole）：Score Sensor + Solenoid

原版街機的「Coil Bed Assembly」包含 solenoid（讓地鼠彈起的電磁線圈）和 score sensor。根據 [ManualsLib 操作手冊](https://www.manualslib.com/manual/1820336/Bob-S-Space-Racers-Whac-A-Mole.html)，score sensor 屬於線路板整合感測，同樣是**機械接觸式**——鼠頭被打下去會壓到感測器。沒有方向或速度限制，力道只需超過機械阻力即可。

### 3. Joy-Con 類 IMU 方案（參考性最高）

Nintendo Switch Joy-Con 使用 6 軸 MEMS IMU，理論上可以偵測揮擊時的加速度 peak。根據 [SlashGear 報導](https://www.slashgear.com/1323858/nintendo-switch-controllers-track-movement/) 和 [Joy-Con 逆向工程紀錄（GitHub）](https://github.com/dekuNukem/Nintendo_Switch_Reverse_Engineering)，加速度計採樣率 740Hz，足以捕捉瞬間衝擊。偵測邏輯通常是：**加速度 magnitude 在短時間內超過閾值**（spike detection），代表發生了揮擊動作。不依賴方向，因為鎚子物理上只能往下打。

---

## Camera-Based 業界做法

### MediaPipe Hands（Landmark Tracking）

MediaPipe 可以追蹤手部 21 個 3D 座標點，每幀更新。常見的「打中」判斷方式有三種：

1. **位置重疊**：手腕或手掌座標進入地鼠 bounding box
2. **深度變化**（Z 軸）：手指向前推（depth 增加），用來模擬「插」或「按」的動作
3. **手勢分類**：MediaPipe 的 Gesture Recognizer 預訓練識別 `Closed_Fist`、`Open_Palm` 等姿勢，但無法直接識別「揮動中」這個瞬間狀態

MediaPipe 的 WASM 模型需要外部載入，[官方 GitHub issue](https://github.com/google-ai-edge/mediapipe/issues/5729) 顯示可以 self-host，但 wasm + 模型檔案合計通常 **5-10 MB 以上**，加上本身 9 MB 的 kids-companion HTML，inline 進單檔會讓整個檔案超過 15-20 MB，不現實。

### TensorFlow.js PoseNet / HandPose

[Beat Pose（charliegerard）](https://github.com/charliegerard/beat-pose) 是最著名的 PoseNet 體感遊戲案例，作者在 [DEV.to 文章](https://dev.to/devdevcharlie/playing-beat-saber-in-the-browser-with-body-movements-using-posenet-tensorflow-js-36km) 中坦承：打中判定只用 raycasting（空間重疊），沒有追蹤速度或方向，而且已知誤觸問題沒解決。[Fruit Ninja 仿作](https://dev.to/devdevcharlie/motion-controlled-fruit-ninja-game-using-three-js-tensorflow-js-18de) 也相同：`distance < 200` 就算碰到水果，作者自己說有時候沒打到也會觸發。

TF.js 模型檔案同樣需要外部載入，CDN 限制下不可行。

### 純 Optical Flow / Frame Diff（我們目前的方向）

[js-cam-motion（GitHub）](https://github.com/tjerkw/js-cam-motion) 和多篇 vanilla JS 教學（如 [CodersBlock](https://codersblock.com/blog/motion-detection-with-javascript/)、[HackerNoon](https://medium.com/hackernoon/motion-detection-in-javascript-2614adea9325)）都是 frame diff 派。核心限制：

- **捕捉 magnitude 容易，捕捉方向難**：只知道「這個區域有動」，不知道往哪個方向動
- Optical flow（如 Lucas-Kanade）可以提取角度和 magnitude，但計算量大，在 Canvas + JS 主線程跑會掉幀
- 環境光變化、鏡頭晃動都是噪音來源，沒有骨架追蹤的語義層隔離
- 手抽回時的 pixel diff 跟揮下去時完全對稱，純靠 centroid 位移方向也容易誤判（這正是我們踩到的坑）

---

## 「打中」的定義方式（業界 4-5 種整理）

### 方式 1：位置重疊（Position Overlap）

最普遍。手部代理點（wrist / palm center）進入地鼠的 bounding box 即視為打中。Beat Pose、Skavinskyy 的打地鼠都用這個。**優點**：實作簡單。**缺點**：手靜止停在地鼠上方也會持續觸發；手抽回也會再觸發一次。

### 方式 2：方向約束 + 位置重疊（Directional Position）

GestureRhythm 的做法：手部代理點 (a) 進入 hit zone **且** (b) 移動方向符合預設方向（向前 / 向下）。兩個條件都滿足才觸發。**優點**：直接解決「停留觸發」問題。**缺點**：方向判斷要靠每幀座標差，若 frame rate 不穩會有跳動。

### 方式 3：速度峰值偵測（Velocity Peak / Impact Moment）

加速度計方案（Joy-Con、手機揮動）的做法。記錄過去 N 幀的加速度，看到 magnitude 突然飆高（peak）就視為打擊瞬間。這模擬的是「用力打下去」的物理特性。**優點**：自然濾掉緩慢移動的手。**缺點**：需要 IMU 資料；純視覺方案要用 frame-to-frame 座標差模擬，但視覺位移≠力道，誤差大。

### 方式 4：狀態機（State Machine：Windup → Swing → Hit）

遊戲引擎 Unreal 社群討論（[Epic Forums](https://forums.unrealengine.com/t/system-design-hit-detection/337799)）、[Smashing Magazine 的瀏覽器 motion control 文章](https://www.smashingmagazine.com/2022/10/motion-controls-browser/)都提到：把揮擊拆成「準備期」→「下擊期」→「冷卻期」三個狀態，只有 Swing 狀態中且在 hit zone 才算打中。冷卻期拒絕所有打中訊號（對應手抽回的問題）。**優點**：邏輯清晰，可調參數多。**缺點**：需要可靠的「階段切換觸發點」，若用純 pixel-diff 判斷進入哪個狀態，等於問題往前移了一層。

### 方式 5：深度 Z 軸變化（Depth-Based Press）

GestureRhythm（MediaPipe Z 座標）或 VR 手控的做法：手往「螢幕方向」推進才算打中，往後拉忽略。**優點**：天然濾掉手抽回。**缺點**：需要 MediaPipe 的 3D landmark，單鏡頭前置攝影機的 Z 軸估算精度不穩，且需要 CDN。

---

## 「手抽回不誤觸」的業界解法

### 解法 A：Cooldown（最常見）

打中後強制進入一段「不接受任何輸入」的冷卻期（100-300ms）。Beat Pose、Skavinskyy 的版本都有類似邏輯（雖未明確標榜）。**簡單有效，但選錯冷卻時長會讓玩家打快了沒反應**。對兒童玩家而言，300ms 冷卻通常足夠且不會明顯感受到。

### 解法 B：Debouncing with Time Guard（Smashing Magazine 建議）

類似去抖動：進入「疑似打中」狀態後，要維持該狀態 N ms 才確認觸發；一旦離開狀態立刻取消計時。[Smashing Magazine 文章](https://www.smashingmagazine.com/2022/10/motion-controls-browser/) 用 60ms debounce 防止 pinch 手勢的誤觸。這個做法對「短暫位置重疊」效果好，但對揮動這種快速動作反而會漏掉（揮動可能只有 50-80ms 在 hit zone 內）。

### 解法 C：Two-Phase Sequence（上拉後才接受下揮）

強制要求在打中前先偵測到「手往上移」，再偵測「手往下移進入 hit zone」。這直接回應了「上往下才算才對」這個使用者需求。實作方式：用 centroid Y 座標，如果前 500ms 內有一個 Y 下降（往上）事件，才開啟 hit window 等待 Y 上升（往下）。**優點**：語義最正確。缺點：在純 pixel-diff 環境下，「手往上移」的偵測本身就需要穩定的 centroid 追蹤，回到原點問題。

### 解法 D：One-Direction Velocity Lock（只接受特定方向速度）

每幀計算手部代理點的 velocity vector。只有當向量的 Y 分量為正（座標系向下為正）且 magnitude 超過閾值時，才記錄為有效打擊。這類似方式 2 的升級版，用速度向量取代「是否在移動方向上」的二元判斷。GestureRhythm 用深度 Z 做類似的事。**對 pixel-diff 來說**：需要能追蹤一個穩定的「運動重心點」，而非整個畫面的 diff。只追蹤活躍像素的 centroid 是方向對的，但 centroid 在快速移動時容易跳動，需要加 low-pass filter（例如 EMA，指數移動平均）平滑。

### 解法 E：接受誤觸，不處理

Fruit Ninja 仿作的作者直接承認「有時沒打到也會觸發，不知道為什麼」。對某些 casual 遊戲，誤觸率 < 10% 是可接受的，用 UX 設計（地鼠加更大動畫回饋）讓使用者感覺「有打到」。**這是最省力的方向，但對有強烈「上往下才算」需求的使用者不適用。**

---

## 對我們專案的具體建議（權衡分析）

### 限制重申

- **0 CDN 強制**：MediaPipe、TF.js、任何外部 WASM 模型都不能用
- **單檔 HTML**：不能引用本地檔案路徑
- **純前端**：沒有 server 幫忙做 motion analysis
- **小朋友使用者**：動作誇張、不穩定、揮手幅度大但不精準

### 方案 A：純 pixel-diff 強化版（最輕量，但有天花板）

繼續沿用 pixel-diff，但加入以下改進：

1. **Motion zone masking**：只追蹤地鼠位置附近的區塊 diff（圓形 ROI），濾掉背景噪音
2. **Centroid EMA 平滑**：對活躍像素 centroid 做 exponential moving average（α ≈ 0.4），防止跳動
3. **Cooldown 硬性鎖定**：打中後 250ms 拒絕所有輸入，解決手抽回問題
4. **只偵測 Y 方向速度**：centroid Y 的幀間差值必須為正（向下）且超過閾值，才開放 hit window

這個方案不需要任何外部依賴。主要天花板是：不同使用者、不同光線環境、不同手機攝影機，pixel-diff 的 SNR 差距很大，threshold 很難通用。

### 方案 B：DeviceMotion API（如果玩家用手機）

如果玩家用手機（而非平板 + 外接攝影機），可以加入 `DeviceMotionEvent` 偵測。使用者實際揮動手機當鎚子，加速度 magnitude 超過閾值就算打。Hit zone 的對應（打哪隻）改用手機傾斜角（DeviceOrientation）判斷。這個方向**不依賴相機**，API 是 Web 標準，無 CDN 依賴。缺點是體驗設計完全不同（手機就是鎚子，而非拿手機看畫面）。

### 方案 C：最小可行 ML —— 只 inline TF.js Hand Pose WASM（激進但可行）

TF.js 的 hand-pose-detection 模型（MobileNetV2 backbone）gzip 後約 **3-4 MB**。加上 TF.js core（約 1.5 MB gzip），合計約 5 MB。kids-companion 目前 gzip 後約 6.6 MB，inline 後會到約 12 MB，仍在可接受範圍。**但這違反單檔 inline 精神**，且每次更新模型要重 inline。

更務實的折衷：**把 wasm 和模型放在同 repo 相對路徑下**（`/kids-companion/vendor/tfjs-hand/`），HTML 用 relative path 載入，CDN 規則指的是「外部 CDN 網域」，自家 GitHub Pages 路徑不算外部 CDN。這個詮釋需要 Tom 確認。

### 優先推薦：方案 A + Motion Zone Masking + 單向速度門檻

對照我們踩過的坑（Y centroid 不穩、上往下邏輯搖擺），最根本的問題是**追蹤的區域太大**。改成只追蹤地鼠所在的小圓形 ROI（半徑約地鼠高度的 1.5 倍），centroid 的 S/N 比會大幅提升。再加上向下速度閾值和 250ms cooldown，應該可以穩定很多。

這個方案的可驗證標準（符合 Inner-Loop Discipline #4）：用 `console.log` 輸出每幀的 ROI centroid Y 和 diff magnitude，錄製 10 次揮擊 + 10 次靜止手，看兩組數據是否有乾淨的分離帶。如果沒有，才考慮升級到方案 C 的 ML 路線。

---

# 結論 / 推薦方向

業界的打地鼠普遍不做「方向偵測」——要嘛是純觸控（不需要），要嘛是骨架追蹤（位置重疊就夠），要嘛是 IMU 硬體（加速度 spike 就夠）。我們試圖用純 pixel-diff 做「上往下才算」的方向約束，是一個業界幾乎沒人用這種組合的罕見需求，難度不是功能問題而是訊號品質問題。

**三個可落地的 next step，按優先順序：**

1. **先測 Motion Zone Masking 效果**：把 diff 計算限縮到地鼠 bounding box 附近的 ROI，用 `console.log` 驗證 centroid 穩定度。預計 3 小時內可以有結論。
2. **如果 #1 改善但仍不穩**：加入 EMA 平滑 + 250ms cooldown + 向下速度閾值，組合成完整的方案 A。
3. **如果 #1 沒改善，代表光線/攝影機噪音是根本障礙**：認真評估方案 C（self-host TF.js hand model 到 `/kids-companion/vendor/`），或者改用 DeviceMotion 做「搖手機當鎚子」的替代互動。

**不建議繼續 iterate 全畫面 pixel-diff 路線**，那個方向的天花板已在 5 次迭代中看清楚了。

---

*Sources:*
- [Making an AI Gesture Recognition Whak-A-Mole Game (Medium, 2024)](https://medium.com/@skavinskyy/making-an-ai-gesture-recognition-whak-a-mole-game-bb89b496c611)
- [GitHub: stevechanvii/WhackMole (TF.js PoseNet)](https://github.com/stevechanvii/WhackMole)
- [Playing Beat Saber in the browser with PoseNet (DEV.to)](https://dev.to/devdevcharlie/playing-beat-saber-in-the-browser-with-body-movements-using-posenet-tensorflow-js-36km)
- [Motion-controlled Fruit Ninja game (DEV.to)](https://dev.to/devdevcharlie/motion-controlled-fruit-ninja-game-using-three-js-tensorflow-js-18de)
- [GestureRhythm AR Rhythm Game (Medium, 2024)](https://medium.com/antaeus-ar/gesturerhythm-ar-rhythm-game-with-real-time-hand-tracking-and-computer-vision-51faf1c83acd)
- [Motion Controls in the Browser - Smashing Magazine (2022)](https://www.smashingmagazine.com/2022/10/motion-controls-browser/)
- [Best Gesture Recognition Libraries in JavaScript 2025](https://portalzine.de/best-gesture-recognition-libraries-in-javascript-2025/)
- [GitHub: tjerkw/js-cam-motion](https://github.com/tjerkw/js-cam-motion)
- [Motion Detection with JavaScript - Coder's Block](https://codersblock.com/blog/motion-detection-with-javascript/)
- [Hand Gesture Detection & Sequence Recognition (Medium)](https://weekiat-lim.medium.com/hand-gesture-detection-sequence-recognition-7f3215f88dde)
- [GitHub: bsdocke/Whack-A-Mole (Android accelerometer)](https://github.com/bsdocke/Whack-A-Mole)
- [Nintendo Switch Joy-Con motion tracking (SlashGear)](https://www.slashgear.com/1323858/nintendo-switch-controllers-track-movement/)
- [Joy-Con Reverse Engineering (GitHub)](https://github.com/dekuNukem/Nintendo_Switch_Reverse_Engineering)
- [Whack First! - Fight the Moles (Nintendo Switch)](https://www.nintendo.com/us/store/products/whack-first-fight-the-moles-switch/)
- [Bob's Space Racers Whac-A-Mole Manual (ManualsLib)](https://www.manualslib.com/manual/1820336/Bob-S-Space-Racers-Whac-A-Mole.html)
- [MediaPipe offline WASM issue (GitHub)](https://github.com/google-ai-edge/mediapipe/issues/5729)
- [ANNKIE / TEMI / other physical toys (Walmart / Amazon)](https://www.walmart.com/ip/AFMAT-Whack-Mole-Game-Toys-5-Year-Old-Boys-Hammer-Toy-Interactive-Educational-Toys-Early-Developmental-Toys-Kids-PK-Mode-2-Kids-Large-Size-Pounding-T/189804249)
- [Whack-A-Mole AR Video Games App Store](https://apps.apple.com/us/app/whack-a-mole-ar-video-games/id6475080174)
- [MediaPipe Gesture Recognizer Web Guide](https://ai.google.dev/edge/mediapipe/solutions/vision/gesture_recognizer/web_js)
- [System Design Hit Detection - Unreal Engine Forums](https://forums.unrealengine.com/t/system-design-hit-detection/337799)
