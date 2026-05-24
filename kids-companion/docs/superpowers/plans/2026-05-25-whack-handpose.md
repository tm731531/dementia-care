# 打地鼠改用 TF.js Hand Pose 體感偵測 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把打地鼠體感偵測從純 JS pixel-diff(迭代 5 輪失敗)換成 self-host TF.js Hand Pose Detection,用食指尖座標 + 速度向量做精準打擊判定。

**Architecture:** 下載 TF.js + Hand Pose model 到 `kids-companion/vendor/`(自家域名 = 仍符合 0 CDN 精神)。`startWhackMotion` 載入 model 後跑 `requestAnimationFrame` loop,每幀 `estimateHands(video)` 取 21 個關節,用食指尖(landmark 8)位置 vs 洞口 bounding rect + dy 速度判定打擊。Cap at 15 FPS 防行動裝置卡頓。

**Tech Stack:** `@tensorflow/tfjs` 4.22.0、`@tensorflow-models/hand-pose-detection` 2.0.1、`runtime: 'tfjs'` + `modelType: 'lite'` + `maxHands: 1`。

**Reference docs:**
- Research: `kids-companion/docs/superpowers/specs/2026-05-24-whack-detection-research.md`(B/C 比較)
- Tech specs: 文件最末「附錄 A」(從 /tmp/tfjs-hand-research.md 複製進來)

**Single file under modification:** `kids-companion/index.html`
**New directory:** `kids-companion/vendor/`(5.3 MB,首次部署)

---

## 任務拆分總覽

| Task | 內容 | 預估 | 結束時可? |
|---|---|---|---|
| 1 | 建 vendor/ + curl 下載 TF.js + model 檔 | 20 min | 4 個檔案 lokal,可 verify |
| 2 | HTML 加 `<script>` 引用 + loading overlay 樣式 | 15 min | F12 看 `tf` + `handPoseDetection` global 存在 |
| 3 | 寫 loadWhackHandModel() 含 warm-up | 30 min | console 跑可成功載入 + warm |
| 4 | 整合 startWhackMotion:選 motion → loading → 進遊戲 | 25 min | 體感模式 button → 看 loading → 看 video + LIVE |
| 5 | startWhackHandLoop:取代 pixel-diff loop(指尖 + 速度 + hit) | 60 min | **完整可玩,揮指尖打 mole** |
| 6 | stopWhackGame:dispose model + reset state | 15 min | 退出鏡頭燈滅 + 模型釋放 |
| 7 | Fallback:載入失敗 / 不支援裝置 → tap mode | 25 min | 老平板自動退手指 |
| 8 | Brain audit + 4 ages × 2 modes 驗收 + commit | 30 min | ship-ready |

**總工時:~3.5 小時**(含驗收),比研究文件原估的 6-7 小時樂觀,因為技術細節已查清楚。

---

## Task 1: 建 vendor/ 目錄 + 下載所有檔案

**Files:**
- Create: `kids-companion/vendor/tf.min.js` (~1.47 MB)
- Create: `kids-companion/vendor/hand-pose-detection.min.js` (~25 KB)
- Create: `kids-companion/vendor/models/detector-lite/model.json` (~8 KB)
- Create: `kids-companion/vendor/models/detector-lite/group1-shard1of1.bin` (~1.87 MB)
- Create: `kids-companion/vendor/models/landmark-lite/model.json` (~80 KB)
- Create: `kids-companion/vendor/models/landmark-lite/group1-shard1of1.bin` (~1.93 MB)

### Steps

- [ ] **Step 1.1: 建立目錄結構**

```bash
cd /home/tom/Desktop/dementia-care/kids-companion
mkdir -p vendor/models/detector-lite vendor/models/landmark-lite
```

- [ ] **Step 1.2: 下載 TF.js core bundle**

```bash
curl -L https://unpkg.com/@tensorflow/tfjs@4.22.0/dist/tf.min.js \
     -o vendor/tf.min.js
ls -lh vendor/tf.min.js
# 預期:約 1.4-1.5 MB
```

- [ ] **Step 1.3: 下載 Hand Pose Detection bundle**

```bash
curl -L "https://unpkg.com/@tensorflow-models/hand-pose-detection@2.0.1/dist/hand-pose-detection.min.js" \
     -o vendor/hand-pose-detection.min.js
ls -lh vendor/hand-pose-detection.min.js
# 預期:約 25 KB
```

- [ ] **Step 1.4: 下載 Detector Lite model**

```bash
curl -L "https://tfhub.dev/mediapipe/tfjs-model/handpose_3d/detector/lite/1/model.json?tfjs-format=file" \
     -o vendor/models/detector-lite/model.json

curl -L "https://tfhub.dev/mediapipe/tfjs-model/handpose_3d/detector/lite/1/group1-shard1of1.bin?tfjs-format=file" \
     -o vendor/models/detector-lite/group1-shard1of1.bin

ls -lh vendor/models/detector-lite/
# 預期:model.json ~8 KB, .bin ~1.87 MB
```

- [ ] **Step 1.5: 下載 Landmark Lite model**

```bash
curl -L "https://tfhub.dev/mediapipe/tfjs-model/handpose_3d/landmark/lite/1/model.json?tfjs-format=file" \
     -o vendor/models/landmark-lite/model.json

curl -L "https://tfhub.dev/mediapipe/tfjs-model/handpose_3d/landmark/lite/1/group1-shard1of1.bin?tfjs-format=file" \
     -o vendor/models/landmark-lite/group1-shard1of1.bin

ls -lh vendor/models/landmark-lite/
# 預期:model.json ~80 KB, .bin ~1.93 MB
```

- [ ] **Step 1.6: 驗證檔案完整**

```bash
find vendor -type f | xargs ls -lh
du -sh vendor/
# 預期:全部 6 個檔案存在,總共約 5.3 MB

# Sanity check JSON 不是 redirect HTML
head -c 100 vendor/models/detector-lite/model.json
# 預期看到 {"format":"graph-model"... 不是 <html
head -c 100 vendor/models/landmark-lite/model.json
# 預期看到 {"format":"graph-model"... 不是 <html
```

如果 model.json 是 HTML 內容代表 redirect 失敗,需 curl `-L` 跟去最終 URL。

- [ ] **Step 1.7: Commit**

```bash
cd /home/tom/Desktop/dementia-care
git add kids-companion/vendor/
git commit -m "$(cat <<'EOF'
feat(kids-companion): vendor/ TF.js + Hand Pose Detection model files

Self-host @tensorflow/tfjs@4.22.0 + @tensorflow-models/hand-pose-detection@2.0.1
+ MediaPipe Hands Lite 兩個 sub-model (detector + landmark)。
總 vendor/ ≈ 5.3 MB(全部從 unpkg / tfhub 一次下載)。

為什麼自家域名 ≠ 違反 0 CDN:
CLAUDE.md 禁的是「第三方 CDN」(fonts.googleapis.com / cdnjs 等),
原因是訪客瀏覽器會洩漏 IP/UA 給第三方。我們的 vendor/ 是 GitHub Pages
同源,訪客不會跟 Google 講話,符合 COPPA/GDPR-K 精神。

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: HTML 加 `<script>` 引用 + loading overlay

**Files:**
- Modify: `kids-companion/index.html` — 加 `<script>` 標籤 + 加 loading overlay HTML + 加 loading CSS

### Steps

- [ ] **Step 2.1: 找到 HTML `<body>` 開始位置**

```bash
cd /home/tom/Desktop/dementia-care/kids-companion
grep -n "<body" index.html | head -3
```

- [ ] **Step 2.2: 在 `</body>` 之前加 `<script>` 引用**

`grep -n "</body>" index.html` 找到 body 結束位置。在 `</body>` **之前** 插入:

```html
<!-- TF.js + Hand Pose Detection (self-host vendor/) -->
<script src="vendor/tf.min.js"></script>
<script src="vendor/hand-pose-detection.min.js"></script>
```

注意位置:必須在使用 `tf` 和 `handPoseDetection` 的程式碼**之前**(也就是放在主 `<script>` 區塊**之前**)。如果主 script 區塊在 `<body>` 末尾,插在它前面。

- [ ] **Step 2.3: 在 `#SECTION:PAGE-WHACK-MOLE` 加 loading overlay 元素**

`grep -n '#SECTION:PAGE-WHACK-MOLE' index.html`

在 `<!-- ❌ 結束按鈕 -->` 之**前** 加:

```html
  <!-- TF.js Hand Pose 載入 overlay(首次 motion 模式才會顯示) -->
  <div class="whack-loading-overlay" id="whack-loading" style="display:none">
    <div class="whack-loading-card">
      <div class="whack-loading-spinner">🤖</div>
      <div class="whack-loading-text" id="whack-loading-text">準備手部偵測…</div>
      <div class="whack-loading-progress" id="whack-loading-progress">下載 0%</div>
      <div class="whack-loading-hint">第一次需要 5-10 秒下載,之後會自動快取</div>
    </div>
  </div>
```

- [ ] **Step 2.4: 加 loading overlay CSS**

`grep -n "#END:WHACK-STYLES" index.html` 找到位置。在 `/* <!-- #END:WHACK-STYLES --> */` **之前**插入:

```css
/* v8 載入 overlay(TF.js model 下載/初始化中) */
.whack-loading-overlay {
  position: absolute;
  inset: 0;
  background: rgba(255,248,240,0.97);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 30;
}
.whack-loading-card {
  background: #fff;
  border-radius: 20px;
  padding: 32px 28px;
  max-width: 320px;
  width: 90%;
  text-align: center;
  box-shadow: 0 10px 30px rgba(0,0,0,0.15);
}
.whack-loading-spinner {
  font-size: 64px;
  animation: whackLoadingSpin 2s linear infinite;
}
@keyframes whackLoadingSpin {
  from { transform: rotate(0deg); }
  to   { transform: rotate(360deg); }
}
.whack-loading-text {
  font-size: 22px;
  font-weight: bold;
  color: #E8724A;
  margin: 16px 0 8px;
}
.whack-loading-progress {
  font-size: 16px;
  color: #888;
  margin-bottom: 12px;
}
.whack-loading-hint {
  font-size: 13px;
  color: #aaa;
  line-height: 1.5;
}
```

- [ ] **Step 2.5: 驗證**

```bash
# 三個 script tag 存在
grep -c 'src="vendor/tf.min.js"' index.html             # = 1
grep -c 'src="vendor/hand-pose-detection.min.js"' index.html  # = 1
# Loading overlay 存在
grep -c 'id="whack-loading"' index.html                 # = 1
grep -c 'whack-loading-overlay' index.html              # ≥ 2(HTML + CSS)

# 在瀏覽器 console:
# 開 index.html(從 file:// 不行,需 local server):
# python3 -m http.server 8000
# 開 http://localhost:8000/kids-companion/
# F12 console:
#   typeof tf                  → "object"
#   typeof handPoseDetection   → "object"
#   handPoseDetection.SupportedModels.MediaPipeHands  → 字串
```

- [ ] **Step 2.6: Commit**

```bash
cd /home/tom/Desktop/dementia-care
git add kids-companion/index.html
git commit -m "$(cat <<'EOF'
feat(kids-companion): 打地鼠 HTML 加 TF.js script 引用 + loading overlay UI

兩個 <script> 在 </body> 前載入 self-host TF.js + Hand Pose Detection。
page-whack-mole 加 .whack-loading-overlay(尚未 wire JS,下個 task 接)。
CSS 加 spinner 動畫 + 載入卡片樣式。

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: 寫 loadWhackHandModel() 含 warm-up

**Files:**
- Modify: `kids-companion/index.html` — 在 `#SECTION:WHACK-LOGIC` 內加 model 載入函式

### Steps

- [ ] **Step 3.1: 找到 WHACK-LOGIC 區塊起點**

```bash
grep -n "// <!-- #SECTION:WHACK-LOGIC -->" index.html
```

- [ ] **Step 3.2: 在 WHACK-LOGIC 區塊頂部加 model state + 載入函式**

在 `var WHACK_CONFIG = {` 那行**之前**插入:

```js
// v8 Hand Pose Detection model state(單例,跨遊戲場次共用)
var whackHandModel = null;
var whackHandModelLoading = null;  // Promise,避免重複載入

// 載入 model + warm-up(第一次 inference 需要 GPU shader compile,~1-3s)
// 回傳 Promise<detector>。重複呼叫直接拿 cache。
function loadWhackHandModel() {
  if (whackHandModel) return Promise.resolve(whackHandModel);
  if (whackHandModelLoading) return whackHandModelLoading;

  var loadingText = document.getElementById('whack-loading-text');
  var progressText = document.getElementById('whack-loading-progress');
  var isEn = (APP.language === 'en');

  function setText(t) { if (loadingText) loadingText.textContent = t; }
  function setProgress(p) { if (progressText) progressText.textContent = p; }

  whackHandModelLoading = (async function() {
    try {
      setText(isEn ? 'Loading TF.js…' : '載入 TF.js…');
      setProgress(isEn ? '20%' : '進度 20%');
      // 等 tfjs ready(WebGL backend init 等)
      await tf.ready();
      // 強制 webgl backend(行動裝置最快)
      try { await tf.setBackend('webgl'); } catch (e) { /* fallback ok */ }

      setText(isEn ? 'Loading hand model…' : '載入手部模型…');
      setProgress(isEn ? '50%' : '進度 50%');

      var detector = await handPoseDetection.createDetector(
        handPoseDetection.SupportedModels.MediaPipeHands,
        {
          runtime: 'tfjs',
          modelType: 'lite',
          maxHands: 1,
          detectorModelUrl: 'vendor/models/detector-lite/model.json',
          landmarkModelUrl: 'vendor/models/landmark-lite/model.json'
        }
      );

      setText(isEn ? 'Warming up…' : '暖機中…');
      setProgress(isEn ? '90%' : '進度 90%');

      // Warm-up:跑一次空 inference 預編 GPU shader,避免遊戲第一幀卡 1-3s
      var dummyCanvas = document.createElement('canvas');
      dummyCanvas.width = 192;
      dummyCanvas.height = 192;
      await detector.estimateHands(dummyCanvas);

      setText(isEn ? 'Ready!' : '準備好!');
      setProgress(isEn ? '100%' : '進度 100%');

      whackHandModel = detector;
      return detector;
    } catch (err) {
      console.error('loadWhackHandModel failed:', err);
      whackHandModelLoading = null;  // 允許重試
      throw err;
    }
  })();

  return whackHandModelLoading;
}
```

- [ ] **Step 3.3: 驗證 JS 不爆 syntax**

```bash
node -e "const fs=require('fs');const c=fs.readFileSync('index.html','utf8');const m=c.match(/<script>([\\s\\S]*?)<\\/script>/);try{new Function(m[1]);console.log('✅ OK');}catch(e){console.error('❌',e.message);process.exit(1);}"
# 預期:✅ OK

grep -c "function loadWhackHandModel" index.html  # = 1
grep -c "createDetector" index.html               # = 1
grep -c "estimateHands" index.html                # = 1(後續 task 還會多)
```

- [ ] **Step 3.4: 手動測 console 載入**

```bash
python3 -m http.server 8000 &
SERVER_PID=$!
echo "Server pid $SERVER_PID, open http://localhost:8000/kids-companion/"
```

在 F12 console:

```js
// 進打地鼠 page(任何方式)
await loadWhackHandModel()
// 預期:5-10 秒後回傳 detector 物件,不報錯
// 若 model.json 找不到會看到 404 errors
```

殺 server:`kill $SERVER_PID`

- [ ] **Step 3.5: Commit**

```bash
git add kids-companion/index.html
git commit -m "$(cat <<'EOF'
feat(kids-companion): 打地鼠 loadWhackHandModel() 含 warm-up

新增 whackHandModel + whackHandModelLoading 單例 state。
loadWhackHandModel() 走:
  tf.ready() → setBackend('webgl') → createDetector(self-host URLs)
  → 空 192x192 canvas warm-up(預編 GPU shader)
全程更新 loading overlay 文字 + 百分比。
回傳 Promise<detector>,重複呼叫拿 cache。

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: 整合 startWhackMotion(model 等待 → 進遊戲)

**Files:**
- Modify: `kids-companion/index.html` — 改寫 `startWhackMotion` 函式,在開鏡頭之前先載 model

### Steps

- [ ] **Step 4.1: 定位現有 startWhackMotion**

```bash
grep -n "function startWhackMotion" index.html
```

- [ ] **Step 4.2: 替換整個 startWhackMotion 函式**

找到 `function startWhackMotion() {` 開始到對應 `}` 結束,整段替換成:

```js
function startWhackMotion() {
  var isEn = (APP.language === 'en');

  // 1. feature detect
  if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
    alert(isEn ? 'Camera not supported, switching to tap mode.' : '裝置不支援相機,切換成手指模式。');
    APP.whackMode = 'tap';
    whackState.mode = 'tap';
    saveState();
    startWhackPlay();
    return;
  }

  // 2. 顯示 loading overlay(model 載入中)
  document.getElementById('whack-loading').style.display = 'flex';

  // 3. 並行:載 model + 開鏡頭(同時跑,以最慢者為準)
  Promise.all([
    loadWhackHandModel(),
    navigator.mediaDevices.getUserMedia({ video: { width: 640, height: 480, facingMode: 'user' } })
  ]).then(function(results) {
    var model = results[0];
    var stream = results[1];

    whackState.videoStream = stream;
    var video = document.getElementById('whack-video');
    video.srcObject = stream;
    video.style.display = 'block';
    whackState.videoEl = video;

    document.getElementById('whack-live').style.display = 'flex';

    video.onloadedmetadata = function() {
      video.play().then(function() {
        // 關 loading,進遊戲
        document.getElementById('whack-loading').style.display = 'none';
        startWhackPlay();
        startWhackHandLoop();  // task 5 實作的新 loop
      }).catch(function() {
        // autoplay 被擋 → fallback tap
        document.getElementById('whack-loading').style.display = 'none';
        APP.whackMode = 'tap';
        whackState.mode = 'tap';
        saveState();
        startWhackPlay();
      });
    };
  }).catch(function(err) {
    console.warn('Motion mode setup failed:', err);
    document.getElementById('whack-loading').style.display = 'none';
    var msg;
    if (err && err.name && err.name.indexOf('Permission') === 0) {
      msg = isEn ? 'Camera denied — tap to play instead?' : '相機被拒絕,改用手指點?';
    } else {
      msg = isEn ? 'Hand detection failed to load — tap to play?' : '手部偵測載入失敗,改用手指點?';
    }
    alert(msg);
    APP.whackMode = 'tap';
    whackState.mode = 'tap';
    saveState();
    startWhackPlay();
  });
}

// task 5 之前的暫時 stub
function startWhackHandLoop() {
  // task 5 補完
}
```

- [ ] **Step 4.3: 同步移除舊的 startWhackDiffLoop 呼叫**

舊 `startWhackMotion` 內呼叫了 `startWhackDiffLoop()`。新版本改成 `startWhackHandLoop()`。確認沒漏:

```bash
grep -n "startWhackDiffLoop\|startWhackHandLoop" index.html
# 預期:startWhackDiffLoop 應該還有舊定義(下個 task 才刪)
#       startWhackHandLoop 至少 1 個 stub 定義 + 1 個呼叫
```

- [ ] **Step 4.4: 瀏覽器手動測**

```bash
python3 -m http.server 8000 &
```

- 開 http://localhost:8000/kids-companion/
- 進打地鼠 → 選「📷 用相機體感玩」
- **預期路徑**:
  1. Modal 消失
  2. 中央出現 🤖 旋轉 spinner + 「載入 TF.js…」→「載入手部模型…」→「暖機中…」
  3. 同時瀏覽器跳相機權限 → 允許
  4. ~5-10 秒後 loading 消失,看到自己的 mirror video + LIVE 紅點
  5. 地鼠開始冒出(目前 hit 還無效,task 5 才接)

DevTools console **無 error**(可能會有 TF.js 載入的 info log,可忽略)。

- [ ] **Step 4.5: Commit**

```bash
git add kids-companion/index.html
git commit -m "$(cat <<'EOF'
feat(kids-companion): startWhackMotion 並行載 hand model + 鏡頭

並行 Promise.all([loadModel, getUserMedia]):以最慢者為準。
loading overlay 在 promise 期間顯示 spinner + 進度文字。
model load 失敗 / 相機拒絕 → alert + fallback tap mode。
startWhackHandLoop() 為 task 5 stub。

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: startWhackHandLoop:取代 pixel-diff loop

**Files:**
- Modify: `kids-companion/index.html` — 替換 task 4 的 `startWhackHandLoop` stub 成完整實作 + 移除舊的 `startWhackDiffLoop`

### Steps

- [ ] **Step 5.1: 找 startWhackHandLoop stub 跟 startWhackDiffLoop 完整定義**

```bash
grep -n "function startWhackHandLoop\|function startWhackDiffLoop" index.html
```

- [ ] **Step 5.2: 整段替換 startWhackHandLoop stub 成正式版**

替換 `function startWhackHandLoop() {` 跟它的 `}` 為:

```js
// v8:取代 pixel-diff loop,用 TF.js Hand Pose 21 個關節 + 速度向量做精準判定
function startWhackHandLoop() {
  if (!whackHandModel) {
    console.warn('startWhackHandLoop: model not loaded');
    return;
  }

  var lastInferenceMs = 0;
  var INFERENCE_INTERVAL_MS = 66;  // ~15 FPS cap(行動裝置友善)
  var inferring = false;            // 防 reentry

  // 上一幀指尖位置(歸一化 0..1 相對於 video frame)
  var lastTipX = null;
  var lastTipY = null;
  var lastTipTime = 0;

  function loop(timestamp) {
    if (!whackState.active || whackState.mode !== 'motion') return;
    whackState.diffRafId = requestAnimationFrame(loop);

    if (timestamp - lastInferenceMs < INFERENCE_INTERVAL_MS) return;
    if (inferring) return;
    if (whackState.videoEl.readyState < 2) return;

    lastInferenceMs = timestamp;
    inferring = true;

    whackHandModel.estimateHands(whackState.videoEl, { flipHorizontal: true })
      .then(function(hands) {
        inferring = false;
        if (!whackState.active) return;

        if (hands.length === 0) {
          // 沒手 → 清掉上一幀,重新累計
          lastTipX = null;
          lastTipY = null;
          return;
        }

        var hand = hands[0];
        var tip = hand.keypoints[8];  // index_finger_tip(食指尖)

        // 歸一化到 0..1(用 videoWidth / videoHeight)
        var videoW = whackState.videoEl.videoWidth || 640;
        var videoH = whackState.videoEl.videoHeight || 480;
        var tipX = tip.x / videoW;
        var tipY = tip.y / videoH;

        // 計算速度向量(歸一化 / 秒)
        var dx = 0, dy = 0, speed = 0;
        var now = performance.now();
        if (lastTipX !== null && lastTipY !== null) {
          var dt = (now - lastTipTime) / 1000;
          if (dt > 0 && dt < 0.5) {  // ignore stale data
            dx = (tipX - lastTipX) / dt;  // /sec
            dy = (tipY - lastTipY) / dt;
            speed = Math.sqrt(dx*dx + dy*dy);
          }
        }
        lastTipX = tipX;
        lastTipY = tipY;
        lastTipTime = now;

        // 打擊判定條件:
        // (1) 不在全域 cooldown 內
        // (2) dy > 0(往下移動,Y 軸向下為正)
        // (3) speed > 閾值(忽略靜止飄移)
        // (4) 指尖座標落在某個 active 洞口 bbox 內 + 該洞 active 且不在 cell cooldown
        if (Date.now() < whackState.globalCooldownUntil) return;

        var DOWN_VELOCITY_THRESHOLD = 0.4;  // /sec(歸一化座標 ≈ 螢幕高的 40%/sec)
        var MIN_SPEED = 0.2;
        if (dy <= DOWN_VELOCITY_THRESHOLD) return;  // 沒下行就忽略(放寬:橫掃也算 dy 為正)
        if (speed < MIN_SPEED) return;

        // 將指尖視口座標(0..1 of video)對應到螢幕座標
        // video object-fit:contain 已映射為相同 0..1 of visible area
        // 但 video 元素的螢幕 bounding rect 才是真的 hit 區域
        var videoRect = whackState.videoEl.getBoundingClientRect();
        // 注意:Task 4 設了 flipHorizontal:true 給 estimateHands,
        // 所以 tip.x 已經是 mirror 後的座標(跟使用者看到的對齊)
        var tipScreenX = videoRect.left + tipX * videoRect.width;
        var tipScreenY = videoRect.top + tipY * videoRect.height;

        // 找包含指尖的洞
        for (var i = 0; i < whackState.holes.length; i++) {
          var hole = whackState.holes[i];
          if (!hole.active) continue;
          if (Date.now() < hole.cooldownUntil) continue;

          var rect = hole.el.getBoundingClientRect();
          // bbox + 10% 緩衝(指尖落在洞外側 10% 也算中,提升手感)
          var pad = rect.width * 0.10;
          if (tipScreenX >= rect.left - pad && tipScreenX <= rect.right + pad &&
              tipScreenY >= rect.top - pad  && tipScreenY <= rect.bottom + pad) {
            onWhackHit(i);
            break;
          }
        }
      })
      .catch(function(err) {
        inferring = false;
        console.warn('estimateHands error:', err);
      });
  }
  requestAnimationFrame(loop);
}
```

- [ ] **Step 5.3: 移除舊的 startWhackDiffLoop(整段刪)**

```bash
# 找邊界
grep -n "^function startWhackDiffLoop\|^// pixel-diff loop" index.html
```

把整段 `function startWhackDiffLoop() {` 到對應 `}` 整段刪除(整個 pixel-diff 邏輯不再需要)。

也順手刪除已不用的 state field:
- `whackState.prevFrame` 用不到了
- `WHACK_TUNING` 內的 `THRESHOLD_PIXEL` / `THRESHOLD_CELL` / `EDGE_BOOST` / `Y_DELTA_THRESHOLD` / `MIN_RATIO_FOR_DIRECTION` 都可砍(留 `COOLDOWN_MS`, `GLOBAL_LIFT_COOLDOWN_MS`, `CANVAS_W`, `CANVAS_H`, `DEBUG_OVERLAY`)
- `hole.lastCentroidY` / `hole.lastRatio` 用不到(showMole 重置邏輯也跟著移)

實際刪除 grep + read 後再 Edit。**保守起見**:可以保留 fields 但不用,程式碼乾淨度退讓給「不要動太多 surface area」。如果要保守:只刪 `startWhackDiffLoop` 函式,fields 就留著(死碼 OK)。

- [ ] **Step 5.4: 移除 canvas 元素的使用(可保留 DOM,反正 display:none)**

`whack-canvas` 元素還留在 DOM(從 Task 2 的 HTML)但不再有引用。可不動。

- [ ] **Step 5.5: 瀏覽器完整測**

```bash
python3 -m http.server 8000 &
```

- 進大班(9 隻 maxSim 4)
- 選體感模式
- 等載入完(~5-10 秒首次,之後快)
- 用食指指向地鼠 → 往下揮 → **應該打中**

DevTools console 看不到 error。如果想看判定細節,加 `console.log` 進 estimateHands().then():

```js
console.log('tip:', tipX.toFixed(2), tipY.toFixed(2), 'speed:', speed.toFixed(2), 'dy:', dy.toFixed(2));
```

- [ ] **Step 5.6: Commit**

```bash
git add kids-companion/index.html
git commit -m "$(cat <<'EOF'
feat(kids-companion): startWhackHandLoop — 用食指尖 + 速度向量取代 pixel-diff

Pixel-diff 演算法 5 次迭代失敗(2026-05-24 postmortem 已記錄)。
換成 TF.js Hand Pose:每幀拿 21 關節,用 keypoints[8](食指尖)位置 +
速度向量 dy 判定打擊:

  if dy > DOWN_VELOCITY_THRESHOLD (0.4 /sec)
     AND speed > MIN_SPEED (0.2 /sec)
     AND globalCooldown expired
     AND 指尖落在某個 active 洞的 bbox(+10% 緩衝)
  then onWhackHit(holeIdx)

INFERENCE_INTERVAL_MS = 66 限 ~15 FPS,降行動裝置壓力。
estimateHands 用 flipHorizontal:true 跟 video 顯示對齊。
hit zone 用 getBoundingClientRect 對應實際 DOM 洞口位置(精準)。

刪掉舊的 startWhackDiffLoop 函式(保留 canvas DOM 但 display:none)。
WHACK_TUNING 內 THRESHOLD_PIXEL / Y_DELTA_THRESHOLD 等舊 pixel-diff
constants 保留(死碼,下次清理)。

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: stopWhackGame 加 model + state cleanup

**Files:**
- Modify: `kids-companion/index.html`

### Steps

- [ ] **Step 6.1: 定位 stopWhackGame**

```bash
grep -n "function stopWhackGame" index.html
```

- [ ] **Step 6.2: 在 stopWhackGame 內加 model + RAF cleanup**

stopWhackGame 函式應該已有 spawnTimer / diffRafId / videoStream 的 stop。確認 `cancelAnimationFrame(whackState.diffRafId)` 還在(現在跑的是 hand loop 但 raf id 同樣存在這個 field 沿用)。

不需要 dispose model(model 是單例,跨遊戲共用,只要遊戲還在 tab 內就不釋放)。Stream / RAF 是每場次的。

如果 stopWhackGame 已正確處理 RAF + stream,**Task 6 大部分 no-op**。檢查邊界:

```bash
# 確認 stopWhackGame 內有這些
grep -A30 "function stopWhackGame" index.html | grep -E "cancelAnimationFrame|getTracks|srcObject"
# 預期 3 個都有
```

- [ ] **Step 6.3: 確認 navigateTo cleanup hook 還在**

```bash
grep -n "stopWhackGame()" index.html
# 預期至少 2 個地方:navigateTo() 開頭 + finishWhack 內(若有)
```

- [ ] **Step 6.4: 手動驗證**

開瀏覽器:
- 進體感模式(等載入完)
- 開 F12 → Application → Memory → 看 GPU memory 約幾 MB
- 點 ❌ 結束或 navigateTo 其他頁面
- **預期**:相機指示燈熄滅(stream stopped)
- 重新進體感:loading 跳過(model 已 cached,直接進遊戲)

- [ ] **Step 6.5: Commit(若有改動)**

```bash
git diff --stat kids-companion/index.html
# 若無改動,跳過 commit
# 若有微調:
git add kids-companion/index.html
git commit -m "chore(kids-companion): stopWhackGame cleanup 確認 + 文件補註"
```

---

## Task 7: Fallback — 載入失敗 / 不支援裝置 → tap mode

**Files:**
- Modify: `kids-companion/index.html` — 在 loadWhackHandModel 跟 startWhackMotion 加更明確 fallback

### Steps

- [ ] **Step 7.1: 為「載入超時」加 timer(避免無限等)**

定位 loadWhackHandModel 函式。在 `(async function() { try { ... }` 內,加 timeout 競賽:

把 `await tf.ready();` 那行改成:

```js
      // 5 秒 timeout 守門(model 載太久代表網路爛或裝置死)
      var TIMEOUT_MS = 30000;
      var timeoutPromise = new Promise(function(_, reject) {
        setTimeout(function() { reject(new Error('LOAD_TIMEOUT')); }, TIMEOUT_MS);
      });
      function withTimeout(p) { return Promise.race([p, timeoutPromise]); }

      await withTimeout(tf.ready());
```

並把後續 `await tf.setBackend('webgl')` / `await handPoseDetection.createDetector(...)` / `await detector.estimateHands(dummyCanvas)` 都包成 `await withTimeout(...)`。

(注意:timeoutPromise 是同個 reject 來源,multiple await 共用 OK)

- [ ] **Step 7.2: startWhackMotion 的 catch 補 LOAD_TIMEOUT 訊息**

定位 startWhackMotion 的 catch:

```js
}).catch(function(err) {
```

改成:

```js
}).catch(function(err) {
  console.warn('Motion mode setup failed:', err);
  document.getElementById('whack-loading').style.display = 'none';
  var msg;
  if (err && err.name && err.name.indexOf('Permission') === 0) {
    msg = isEn ? 'Camera denied — tap to play instead?' : '相機被拒絕,改用手指點?';
  } else if (err && err.message === 'LOAD_TIMEOUT') {
    msg = isEn ? 'Hand detection load timeout — tap to play?' : '手部偵測載入太久,改用手指點?';
  } else {
    msg = isEn ? 'Hand detection failed to load — tap to play?' : '手部偵測載入失敗,改用手指點?';
  }
  alert(msg);
  APP.whackMode = 'tap';
  whackState.mode = 'tap';
  saveState();
  startWhackPlay();
});
```

- [ ] **Step 7.3: 加「裝置不支援 WebGL」前置檢查**

在 loadWhackHandModel 函式**開頭**加:

```js
function loadWhackHandModel() {
  if (whackHandModel) return Promise.resolve(whackHandModel);
  if (whackHandModelLoading) return whackHandModelLoading;

  // v8:WebGL 不支援的裝置直接 reject(會 fallback 到 tap)
  if (typeof tf === 'undefined' || typeof handPoseDetection === 'undefined') {
    return Promise.reject(new Error('TFJS_NOT_LOADED'));
  }

  var loadingText = document.getElementById('whack-loading-text');
  // ... rest unchanged
```

- [ ] **Step 7.4: 測 fallback 路徑**

模擬 fallback:

```bash
# 模擬模型檔不存在
mv vendor/models/landmark-lite/model.json vendor/models/landmark-lite/model.json.bak
# 進體感 → 應該 30s 後出現「載入太久」alert → 自動切 tap
mv vendor/models/landmark-lite/model.json.bak vendor/models/landmark-lite/model.json
```

或 console 故意打:

```js
delete window.handPoseDetection;
// 進體感模式
// 預期立即:alert「手部偵測載入失敗」+ 切 tap
```

- [ ] **Step 7.5: Commit**

```bash
git add kids-companion/index.html
git commit -m "$(cat <<'EOF'
feat(kids-companion): 體感模式 fallback — 載入超時/失敗自動退 tap

3 個 fallback path:
1. tf / handPoseDetection global 不存在 → 立即 reject 'TFJS_NOT_LOADED'
2. 任何一步 (tf.ready / createDetector / warmup) 超過 30 秒 → 'LOAD_TIMEOUT'
3. 相機被拒絕 / 不支援 → 既有 Permission 處理

3 種情況都 alert 友善訊息 + 切 APP.whackMode='tap' + 進手指模式遊戲。
不會卡死在 loading 畫面。

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Brain audit + 4 ages × 2 modes 驗收 + commit

**Files:**
- 主要驗證,可能微調

### Steps

- [ ] **Step 8.1: 0 CDN 檢查(寬鬆解讀:第三方域名才算 CDN)**

```bash
cd /home/tom/Desktop/dementia-care/kids-companion
grep -n -E 'https?://[^"]*\.(com|net|org|io|co)/' index.html | grep -v 'github.io\|tomting.com\|data:\|schema.org'
# 預期:無第三方 CDN(vendor/ 是 relative path,不會出現)
```

- [ ] **Step 8.2: JS 語法 + 函式存在 audit**

```bash
node -e "const fs=require('fs');const c=fs.readFileSync('index.html','utf8');const m=c.match(/<script>([\\s\\S]*?)<\\/script>/);try{new Function(m[1]);console.log('✅ JS OK');}catch(e){console.error('❌',e.message);process.exit(1);}"

# 關鍵函式
for fn in loadWhackHandModel startWhackHandLoop startWhackMotion stopWhackGame; do
  count=$(grep -c "function $fn" index.html)
  [ "$count" = "1" ] && echo "✅ $fn" || echo "❌ $fn (found $count)"
done
```

- [ ] **Step 8.3: vendor 目錄完整性**

```bash
ls -lh vendor/tf.min.js vendor/hand-pose-detection.min.js
ls -lh vendor/models/detector-lite/* vendor/models/landmark-lite/*
du -sh vendor/
# 預期:6 個檔案,總共 ~5.3 MB
```

- [ ] **Step 8.4: 4 ageGroups × 2 modes 手動驗收**

啟動 local server:
```bash
python3 -m http.server 8000 &
```

開 http://localhost:8000/kids-companion/

對每個 ageGroup(設定切換):
1. **手指模式**:點地鼠 → +1 / 達標 / 慶祝 — 全程 OK
2. **體感模式**:
   - 首次:loading 5-10 秒 → 進遊戲
   - 之後:直接進(model cached)
   - 食指尖揮過地鼠 → 應該打中
   - 手抽回不誤觸(全域 cooldown 300ms 保護)
   - 達標 → 慶祝 → 完整

至少每個 ageGroup 跑通一次達標。

- [ ] **Step 8.5: 既有 14 個活動 random 抽 3 個回歸測**

切到「📚 語言」tab,點認中文字、英文字母、數數 — 三個都跑一回測試,**不應該有任何 regression**。

console 不應有 error。

- [ ] **Step 8.6: 平板實機測**

把 dev 分支推 GitHub Pages 後,用實際平板開:
- 安卓平板:Chrome
- iPad:Safari

驗收體感模式能用。若實機卡(< 5 FPS),調 `INFERENCE_INTERVAL_MS` 從 66 → 100(降到 10 FPS)。

- [ ] **Step 8.7: 寫 v8 changelog 補 postmortem doc**

在現有 `kids-companion/docs/superpowers/specs/2026-05-24-whack-motion-direction-postmortem.md` 末尾加:

```markdown

---

## 2026-05-25 補充:v7.x 全部廢棄,改 v8 用 TF.js Hand Pose

5 輪迭代後(v7.2-v7.6)決定全部廢棄純 JS pixel-diff 路線。
Web search 後確認業界沒人用「pixel-diff + 方向」這組合成功過,
全部用 MediaPipe / PoseNet。

v8 改用 self-host TF.js Hand Pose Detection(@4.22.0 + hand-pose-detection@2.0.1):
- vendor/ 5.3 MB(GitHub Pages 同源,符合 0 CDN 精神)
- 食指尖(landmark 8)座標 + dy 速度向量
- 行動裝置 ~15 FPS(INFERENCE_INTERVAL_MS = 66)

實作 plan:`docs/superpowers/plans/2026-05-25-whack-handpose.md`
研究:`docs/superpowers/specs/2026-05-24-whack-detection-research.md`

### 關鍵教訓
- 演算法迭代陷阱:同一條路死磕到底,業界資料早能告訴你「沒人這樣做成功」
- Tom 連續抱怨「不靈敏 / 太敏感 / 上揮也算」是 signal,不是噪音 — 該換路線而非繼續調參
```

- [ ] **Step 8.8: 推 dev 分支 + merge main + deploy**

```bash
cd /home/tom/Desktop/dementia-care
git add kids-companion/docs/superpowers/specs/2026-05-24-whack-motion-direction-postmortem.md
git commit -m "$(cat <<'EOF'
docs(kids-companion): postmortem 加 v8 補充 — pixel-diff 全部廢棄改 TF.js

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"

# 推 dev
git push origin dev

# Merge main + deploy
git stash push -m "WIP" ../whiteboard-ocr-bot/companion_call/scheduled_call.py ../whiteboard-ocr-bot/companion_call/tests/test_scheduled_call.py 2>/dev/null
git checkout main
git merge dev --no-edit
git push origin main
git checkout dev
git stash pop 2>/dev/null

# 等部署
until [ "$(gh api repos/tm731531/dementia-care/pages/builds/latest --jq '.commit' 2>/dev/null)" = "$(git rev-parse origin/main)" ] && [ "$(gh api repos/tm731531/dementia-care/pages/builds/latest --jq '.status' 2>/dev/null)" = "built" ]; do sleep 8; done
gh api repos/tm731531/dementia-care/pages/builds/latest --jq '{status,commit}'
```

預期 Pages build 時間會比平常長(額外 5.3 MB),但仍應 < 2 分鐘。

---

## Self-Review Notes

**Spec 覆蓋:**
- ✅ Self-host vendor/(Task 1)
- ✅ TF.js + Hand Pose model 載入(Task 1, 3)
- ✅ Loading UX(Task 2, 3)
- ✅ Async init + warm-up(Task 3)
- ✅ Hit detection by 食指尖 + 速度(Task 5)
- ✅ Fallback path(Task 7)
- ✅ Brain audit + 0 CDN(Task 8)
- ✅ 4 ages × 2 modes 驗收(Task 8)

**未涵蓋(YAGNI):**
- iPad Pro / iPad Air 實機數據(平板 deploy 時取得)
- TF.js 升版策略(暫不需要,版本已凍結 4.22.0)

**型別 / API 一致性:**
- `whackHandModel`:Detector 物件,跨 Task 3-7 引用
- `whackHandModelLoading`:Promise<Detector>,Task 3 設定 / Task 4 等待
- `whackState.diffRafId`:RAF id,Task 4 設定,Task 6 cancel(沿用既有 field 名)
- `WHACK_TUNING` 內 pixel-diff 舊 constants 標記廢棄但保留(Task 5 step 5.3 註解)

**Placeholder 掃描:** 無 TBD,所有 code block 完整。

---

**Plan 完成,儲存在 `kids-companion/docs/superpowers/plans/2026-05-25-whack-handpose.md`**
