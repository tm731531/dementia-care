# 工程師做完專案就丟上 GitHub？你少做了這些事

身為一個寫 code 的人，我以前的工作流程大概是這樣：

1. 有個想法
2. 熬夜把它做出來
3. `git push origin main`
4. 收工，去睡覺

然後呢？然後就沒有然後了。

專案靜靜地躺在 GitHub 上，星星數停在個位數（其中兩個是我自己的帳號和我女朋友被我拜託按的），偶爾有個路過的陌生人開了個 issue 問「這還有在維護嗎？」——沒有，但我不好意思說。

直到最近我做了一個小專案，花了一些時間研究「做完之後該做什麼」，才發現原來我們工程師漏掉的東西，比寫的 code 還多。

---

## META Tags 不是裝飾品

先來個靈魂拷問：你的 `index.html` 的 `<head>` 裡面有什麼？

我猜大概是這樣：

```html
<head>
  <meta charset="UTF-8">
  <title>My Cool Project</title>
</head>
```

恭喜，你的網站在搜尋引擎眼中跟一張白紙差不多。

Google 爬蟲來到你的頁面，看到一個 title，然後......就沒了。它不知道你這個頁面在幹嘛、給誰用、解決什麼問題。它只好自己猜，而搜尋引擎猜東西的能力，大概跟我猜女朋友今天為什麼不開心一樣爛。

最低限度，你應該加上這些：

```html
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>你的專案名稱 — 一句話說明它是什麼</title>
  <meta name="description" content="用 50-160 字描述你的專案做什麼、給誰用">
  <meta name="keywords" content="關鍵字1, 關鍵字2, 關鍵字3">

  <!-- Open Graph：社群分享預覽 -->
  <meta property="og:title" content="專案名稱">
  <meta property="og:description" content="專案描述">
  <meta property="og:image" content="https://your-username.github.io/your-repo/preview.png">
  <meta property="og:url" content="https://your-username.github.io/your-repo/">
  <meta property="og:type" content="website">

  <!-- Schema.org JSON-LD：結構化資料 -->
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebApplication",
    "name": "你的專案名稱",
    "description": "專案描述",
    "url": "https://your-username.github.io/your-repo/",
    "author": {
      "@type": "Person",
      "name": "Your Name"
    },
    "applicationCategory": "UtilityApplication",
    "operatingSystem": "Web Browser"
  }
  </script>
</head>
```

我知道你在想什麼：「這也太多了吧，我只是做個 side project 耶。」

對，我也這樣想過。但你花了 40 小時寫 code，多花 20 分鐘把 meta tags 補齊，投報率其實很高。

---

## SEO 和 AEO 的差別

大家都聽過 SEO（Search Engine Optimization），就是讓 Google 找到你的東西。但 2025 年以後，有另一個東西叫 AEO —— Answer Engine Optimization。

差別在哪？

- **SEO** 是讓使用者搜尋「台灣失智症照護工具」的時候，你的網站出現在搜尋結果裡。
- **AEO** 是讓使用者問 ChatGPT 或 Perplexity「有沒有推薦的失智症照護互動工具？」的時候，AI 直接把你的專案資訊抽出來回答。

關鍵差異：傳統 SEO 靠的是關鍵字密度、反向連結、網站權重這些。AEO 靠的是**結構化資料**。

上面那段 `Schema.org JSON-LD` 就是結構化資料。它用一種機器能直接理解的格式，告訴 AI「這個網站是什麼類型、做什麼用、誰做的」。AI 搜尋引擎不需要去「理解」你的網頁內容，它直接讀這段結構化的 JSON 就好。

這就像是你寫了一份完美的文件，但沒寫 API 文件一樣。人類看得懂，但機器不知道怎麼呼叫你。Schema.org 就是你給搜尋引擎寫的 API 文件。

---

## GitHub Topics 是免費的曝光

這個我真的覺得很虧，因為我用了 GitHub 這麼久，從來沒認真設定過。

你的 repo 頁面右上角有個 About 區塊，裡面可以寫 description 和加 topics。Topics 就像是 hashtag，GitHub 有專門的 [topic 搜尋頁面](https://github.com/topics/)，使用者可以透過 topic 找到相關專案。

你最多可以加 20 個 topics。免費的曝光，不用白不用。

用 CLI 設定很快：

```bash
# 設定 repo description
gh repo edit your-username/your-repo --description "你的專案一句話描述"

# 加上 topics（注意：GitHub Topics 只支援英文小寫）
gh repo edit your-username/your-repo --add-topic "dementia-care,elderly-care,cognitive-training,taiwan,web-app,html,javascript,open-source,healthcare,accessibility"
```

重點提醒：**GitHub Topics 只支援英文**。所以就算你的專案是中文的，topics 也要用英文寫。想想你的目標受眾會用什麼英文關鍵字搜尋，就加什麼。

---

## GitHub Pages 等於免費網站

如果你的 repo 裡有 `index.html`，恭喜你，你離擁有一個免費網站只差兩個步驟：

1. 去 repo 的 Settings > Pages
2. Source 選 `main` branch，資料夾選 `/ (root)`
3. 按 Save

完成。你的網站就是 `https://your-username.github.io/your-repo/`。

每次你 `git push`，GitHub Actions 會自動幫你部署。不用買主機、不用設定 DNS、不用搞 nginx 設定檔、不用 Docker。零成本。

更重要的是：**你前面寫的那些 meta tags 和 Schema.org 結構化資料，只有在一個可以被公開訪問的網站上才有意義。** GitHub repo 頁面不會被 Google 當成你的「網站」來索引那些 meta tags。開了 GitHub Pages，你的 SEO 和 AEO 才算正式上線。

---

## Google Search Console — 主動告訴 Google 你存在

很多人以為把網站放上去，Google 自然就會找到你。

理論上是的。實際上，一個沒有任何外部連結指向的小網站，Google 爬蟲可能好幾個月都不會路過。你的專案就這樣安安靜靜地存在於網路上，像深山裡的一間便利商店，開著燈但沒有路。

解法很簡單：去 [Google Search Console](https://search.google.com/search-console) 主動提交。

驗證方式最簡單的是 meta tag 驗證——Google 給你一段 meta tag，你貼到 `index.html` 的 `<head>` 裡：

```html
<meta name="google-site-verification" content="你的驗證碼">
```

然後在 Search Console 的「網址審查」功能裡，貼上你的 GitHub Pages URL，按「要求建立索引」。

我的經驗是提交後大概 2-3 天就會被 Google 索引。比起被動等待可能要等幾個月，這個 ROI 非常高。整個流程大概 10 分鐘。

---

## 打賞和贊助機制

「我做的是免費開源專案耶，談錢太俗了吧。」

我以前也這樣想。但後來我發現：願意付費支持你的人，跟你收不收費是兩回事。有些人就是覺得你做的東西有價值，想請你喝杯咖啡。你不給他管道，他想付都付不了。

幾個選項，各有優缺點：

**Ko-fi** — 國際通用的打賞平台，介面很乾淨。但台灣收款要透過 PayPal 或 Stripe，PayPal 的手續費偏高，Stripe 台灣的個人帳號支援也有限制。適合有國際受眾的專案。

**綠界 ECPay** — 台灣最方便的選擇，支援信用卡、ATM 轉帳、超商繳費，對台灣使用者來說付款門檻最低。缺點是設定流程比較繁瑣，可能需要聯繫客服才能搞定。但搞定之後就很順了。

**銀行轉帳 QR Code** — 最簡單直接的方式。產生你的銀行帳號 QR code，使用者用手機銀行掃一下就能轉帳。零手續費、零平台抽成。缺點是沒有平台幫你追蹤誰贊助了多少。

**GitHub Sponsors** — 在 repo 根目錄放一個 `.github/FUNDING.yml`，你的 repo 頁面就會自動出現一個 Sponsor 按鈕：

```yaml
# .github/FUNDING.yml
github: your-username
ko_fi: your-kofi-username
custom:
  - https://your-payment-link.example.com
```

這個檔案的設定非常簡單，但效果很好——那個 Sponsor 按鈕就放在 repo 頁面最顯眼的位置，每個路過的人都看得到。

重點是：**你不需要只選一個。** 你可以同時放 Ko-fi 給國際用戶、綠界給台灣用戶、銀行轉帳給懶得註冊任何平台的人。多一個管道就多一個機會。

---

## README 是你的門面

工程師寫 README 通常是這樣：

```markdown
# My Project

## Installation
npm install

## Usage
npm start
```

然後就沒了。

拜託，你的 README 是大多數人對你專案的第一印象（也可能是最後一印象）。它不只是技術文件，它是你的故事。

一個好的 README 應該包含：

1. **為什麼做這個** — 你遇到了什麼問題？什麼契機讓你動手做？這個故事比你想像的重要一百倍。「我阿嬤確診失智症，我想做一個讓她可以動動腦的小工具」比「這是一個認知訓練 Web App」有感染力多了。
2. **這是什麼、給誰用** — 用一般人聽得懂的話說明。
3. **怎麼用** — 截圖、GIF、或是 live demo 連結。
4. **技術細節** — 用了什麼技術、架構是什麼（這部分寫給工程師看的）。
5. **如何支持** — 打賞連結、或是告訴別人怎麼 contribute。

真實的故事比任何行銷文案都有效。人們不只是在用你的工具，他們是在參與你的故事。

---

## Social Preview 和 OG Tags

最後一個，也是最容易被忽略的：**分享預覽**。

當你把 repo 連結或網站連結貼到 LINE 群組、Facebook、Twitter 的時候，會出現什麼？

如果你什麼都沒設定，就是一個光禿禿的網址。沒有預覽圖、沒有描述、沒有標題。在訊息流裡面，它跟垃圾連結看起來一模一樣。

如果你有設定 OG tags（前面 meta tags 那段已經教過了）加上一張好看的預覽圖，分享出去就會有標題、描述、還有圖片。在 LINE 群組裡點擊率差個三五倍很正常。

GitHub repo 本身也可以設定 Social Preview：去 repo 的 Settings > Social Preview，上傳一張 1280x640 的圖。這樣別人在社群分享你的 repo 連結時，就會顯示這張圖。

你可以用 Canva、Figma 之類的工具花 5 分鐘做一張。不需要多精美，有總比沒有好太多了。

---

## 結論

回顧一下，做完 side project 之後你應該做的事：

1. 把 meta tags 補齊（description、OG tags、Schema.org JSON-LD）
2. 開 GitHub Pages，讓你的專案有一個公開網址
3. 去 Google Search Console 提交你的網址
4. 設定 GitHub Topics 和 About description
5. 放上打賞/贊助連結
6. 好好寫你的 README，說你的故事
7. 設定 Social Preview，讓分享出去有個樣子

這些事情全部加起來，大概花你一到兩個小時。

你已經花了幾十個小時甚至幾百個小時寫 code，多花兩個小時讓它被看見，很值得。

我以前一直覺得「好的東西自然會被發現」。但事實是，網路上好的東西太多了，大部分都沒被發現。被發現的那些，不一定是最好的，但一定是最容易被找到的。

我們工程師很擅長解決技術問題，但不太擅長「讓別人知道我們解決了什麼問題」。

這篇文章就是我學到這件事之後，寫給跟我一樣的人的。

希望你的下一個 side project，不再只是 GitHub 上的一個小點。
