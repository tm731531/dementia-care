const DRINKS = [
  {
    id: "fresenius-beisuyi-fiber",
    name: "倍速益含纖營養補充配方(原味)",
    brand: "費森尤斯卡比 Fresenius Kabi",
    volume_ml: 200,
    image: "images/FreseniusKabi 費森尤斯卡比倍速益含纖營養補充配方_原味.jpg",
    categories: ["醫療營養品"],
    nutrients: {
      "熱量(kcal)": 200, "蛋白質(g)": 10, "脂肪(g)": 7.8, "飽和脂肪(g)": 0.6,
      "反式脂肪(g)": 0, "膽固醇(mg)": 0, "碳水化合物(g)": 23.3, "糖(g)": 3.3,
      "膳食纖維(g)": 1.5, "鈉(mg)": 60, "鉀(mg)": 160, "鈣(mg)": 205,
      "磷(mg)": 120, "鎂(mg)": 16, "鐵(mg)": 2.5, "鋅(mg)": 1.6,
      "維生素C(mg)": 18.8, "維生素D(mcg)": 2.5
    }
  },
  {
    id: "abbott-glucerna-sr-original",
    name: "葡勝納SR(原味)",
    brand: "亞培 Abbott",
    volume_ml: 200,
    image: "images/亞培 葡勝納SR(原味).jpg",
    categories: ["醫療營養品"],
    nutrients: {
      "熱量(kcal)": 96, "蛋白質(g)": 4.7, "脂肪(g)": 3.4,
      "碳水化合物(g)": 11.7, "膳食纖維(g)": 1.2
    }
  },
  {
    id: "abbott-glucerna-select-vanilla",
    name: "葡勝納菁選(香草)",
    brand: "亞培 Abbott",
    volume_ml: 200,
    image: "images/亞培葡勝納菁選糖尿病配方葡勝納SR.jpg",
    categories: ["醫療營養品"],
    nutrients: {
      "熱量(kcal)": 96, "蛋白質(g)": 4.6, "脂肪(g)": 3.4, "飽和脂肪(g)": 0.35,
      "反式脂肪(g)": 0, "碳水化合物(g)": 12.3, "糖(g)": 2.7,
      "膳食纖維(g)": 1.2, "鈉(mg)": 89
    }
  },
  {
    id: "fresenius-diben-cappuccino",
    name: "倍速定Diben(卡布奇諾)",
    brand: "費森尤斯卡比 Fresenius Kabi",
    volume_ml: 200,
    image: "images/【倍速定】糖尿病專用配方 (卡布奇諾).jpg",
    categories: ["醫療營養品"],
    nutrients: {
      "熱量(kcal)": 149, "蛋白質(g)": 7.9, "脂肪(g)": 5.6, "飽和脂肪(g)": 1.5,
      "反式脂肪(g)": 0
    }
  },
  {
    id: "fresenius-beisuyi-highcal-original",
    name: "倍速益高鈣(原味無糖)",
    brand: "費森尤斯卡比 Fresenius Kabi",
    volume_ml: 200,
    image: "images/倍速益.jpg",
    categories: ["醫療營養品"],
    nutrients: {
      "熱量(kcal)": 100, "蛋白質(g)": 6, "脂肪(g)": 4.4, "飽和脂肪(g)": 0.9,
      "反式脂肪(g)": 0, "碳水化合物(g)": 9.2, "糖(g)": 0,
      "鈉(mg)": 125, "鈣(mg)": 250, "維生素D(mcg)": 3.8
    }
  },
  {
    id: "kuangchuan-vitamin-milk",
    name: "富維他牛乳",
    brand: "光泉",
    volume_ml: 200,
    image: "images/光泉富維他牛乳.jpg",
    categories: ["牛乳"],
    nutrients: {
      "熱量(kcal)": 39.7, "蛋白質(g)": 1.9, "脂肪(g)": 0.5, "飽和脂肪(g)": 0.2,
      "反式脂肪(g)": 0, "碳水化合物(g)": 6.9, "糖(g)": 6.1,
      "鈉(mg)": 47, "維生素C(mg)": 15, "維生素D(mcg)": 0.9
    }
  },
  {
    id: "yongxin-almond-milk",
    name: "用心杏仁奶",
    brand: "用心",
    volume_ml: 200,
    image: "images/用心杏仁奶利樂包.jpeg",
    categories: ["植物奶"],
    nutrients: {
      "熱量(kcal)": 54, "蛋白質(g)": 1.3, "脂肪(g)": 3.3, "飽和脂肪(g)": 0.2,
      "反式脂肪(g)": 0, "碳水化合物(g)": 4.8, "糖(g)": 3.1, "鈉(mg)": 30
    }
  },
  {
    id: "ikitchen-fish-sauce",
    name: "美味大師魚露",
    brand: "愛廚房",
    volume_ml: 200,
    image: "images/愛廚房~美味大師魚露.webp",
    categories: ["調味料"],
    nutrients: {
      "熱量(kcal)": 59.6, "蛋白質(g)": 7.3, "脂肪(g)": 0, "飽和脂肪(g)": 0,
      "反式脂肪(g)": 0, "碳水化合物(g)": 7.6, "糖(g)": 7.6, "鈉(mg)": 10639
    }
  },
  {
    id: "oilseed-taiwan-peanut-oil",
    name: "100%臺灣九號花生油",
    brand: "油籽學堂",
    volume_ml: 200,
    image: "images/油籽學堂-100％臺灣黑麻油.jpg",
    categories: ["食用油"],
    nutrients: {
      "熱量(kcal)": 828, "蛋白質(g)": 0, "脂肪(g)": 92, "飽和脂肪(g)": 12,
      "反式脂肪(g)": 0, "碳水化合物(g)": 0, "糖(g)": 0, "鈉(mg)": 0
    }
  },
  {
    id: "quaker-chicken-essence-original",
    name: "原味水解雞精",
    brand: "桂格 Quaker",
    volume_ml: 68,
    image: "images/桂格原味水解雞精.jpg",
    categories: ["雞精"],
    nutrients: {
      "熱量(kcal)": 22.8, "蛋白質(g)": 5.7, "脂肪(g)": 0, "飽和脂肪(g)": 0,
      "反式脂肪(g)": 0, "膽固醇(mg)": 0, "碳水化合物(g)": 0, "糖(g)": 0,
      "鈉(mg)": 66, "鉀(mg)": 158, "支鏈胺基酸BCAA(mg)": 374
    }
  },
  {
    id: "abbott-pediasure-vanilla",
    name: "小安素均衡完整營養配方(香草)",
    brand: "亞培 Abbott",
    volume_ml: 225,
    image: "images/亞培小安素PediaSure香草.jpg",
    categories: ["嬰幼兒配方"],
    nutrients: {
      "熱量(kcal)": 226, "蛋白質(g)": 6.7, "脂肪(g)": 8.8, "飽和脂肪(g)": 2.0,
      "反式脂肪(g)": 0, "碳水化合物(g)": 30.5, "糖(g)": 8.7, "膳食纖維(g)": 0.7,
      "鈉(mg)": 225, "鉀(mg)": 189, "鎂(mg)": 44.6, "鐵(mg)": 3.15,
      "維生素A(mcgRE)": 86, "維生素D(mcg)": 4.5, "維生素E(mg)": 3.5,
      "維生素K1(mcg)": 17.3, "維生素K2(mcg)": 13.3,
      "菸鹼素(mgNE)": 3.37, "葉酸(mcg)": 67.6, "生物素(mcg)": 1.57
    }
  },
  {
    id: "wyeth-s26-gold",
    name: "S-26金愛兒樂",
    brand: "惠氏 Wyeth",
    volume_ml: 100,
    image: "images/惠氏S-26金愛兒樂.jpg",
    categories: ["嬰幼兒配方"],
    nutrients: {
      "熱量(kcal)": 66, "蛋白質(g)": 1.3, "脂肪(g)": 3.6, "飽和脂肪(g)": 1.4,
      "反式脂肪(g)": 0, "亞麻油酸(mg)": 520, "α-次亞麻油酸(mg)": 49.5,
      "碳水化合物(g)": 7.4, "糖(g)": 6.9, "膳食纖維(g)": 0.5,
      "鈉(mg)": 17, "鉀(mg)": 65, "鈣(mg)": 37, "磷(mg)": 22, "鎂(mg)": 5.3, "鐵(mg)": 0.6,
      "維生素A(mcgRE)": 66, "維生素D(mcg)": 7.2, "維生素E(mg)": 0.72,
      "維生素B1(mg)": 0.1, "維生素B2(mg)": 0.11, "維生素B6(mg)": 0.055,
      "維生素B12(mcg)": 0.14, "維生素C(mg)": 9.2,
      "菸鹼素(mgNE)": 0.5, "泛酸(mg)": 0.35, "生物素(mcg)": 2.0,
      "肌醇(mg)": 16, "左旋肉鹼(mg)": 4.5
    }
  },
  {
    id: "abbott-ensure-hmb-original",
    name: "原味安素HMB均衡營養升級配方",
    brand: "亞培 Abbott",
    volume_ml: 237,
    image: "images/亞培安素HMB.jpg",
    categories: ["醫療營養品"],
    nutrients: {
      "熱量(kcal)": 262, "蛋白質(g)": 10.5, "脂肪(g)": 8.5, "飽和脂肪(g)": 2.1,
      "反式脂肪(g)": 0, "碳水化合物(g)": 35.2, "糖(g)": 1.4, "膳食纖維(g)": 0,
      "必需胺基酸EAA(g)": 4.5, "支鏈胺基酸BCAA(g)": 2.1,
      "中鏈脂肪酸MCT(mg)": 1375, "Omega-3(mg)": 264, "Omega-6(mg)": 2133,
      "鈉(mg)": 223, "鈣(mg)": 301,
      "維生素A(mcgRE)": 301, "維生素E(mg)": 15.6, "維生素K(mcg)": 40,
      "維生素C(mg)": 54,
      "維生素B1(mg)": 0.50, "維生素B2(mg)": 0.50, "維生素B6(mg)": 0.71,
      "維生素B12(mcg)": 1.80,
      "菸鹼素(mgNE)": 5.93, "膽素(mg)": 121, "泛酸(mg)": 10.9,
      "葉酸(mcg)": 79, "生物素(mcg)": 10.9,
      "HMB(mg)": 607
    }
  },
  {
    id: "abbott-glucerna-powder-vanilla",
    name: "葡勝納粉狀配方(香草)",
    brand: "亞培 Abbott",
    volume_ml: 237,
    image: "images/亞培葡勝納粉狀香草.jpg",
    categories: ["醫療營養品"],
    nutrients: {
      "熱量(kcal)": 226, "蛋白質(g)": 10.2, "脂肪(g)": 8.7, "飽和脂肪(g)": 1.1,
      "反式脂肪(g)": 0, "碳水化合物(g)": 30, "糖(g)": 5.6,
      "非水溶性膳食纖維(g)": 3.9, "水溶性膳食纖維(g)": 0.5,
      "必需胺基酸EAA(g)": 4.3, "支鏈胺基酸BCAA(g)": 2.1,
      "鈉(mg)": 264, "鉀(mg)": 223, "鈣(mg)": 59.4,
      "維生素A(mcgRE)": 166, "維生素D(mcg)": 6.51, "維生素K(mcg)": 19.8,
      "維生素B1(mg)": 0.41, "維生素B2(mg)": 0.48, "維生素B6(mg)": 0.63,
      "維生素B12(mcg)": 0.82,
      "菸鹼素(mgNE)": 4.79, "泛酸(mg)": 1.93, "葉酸(mcg)": 81, "生物素(mcg)": 9.4,
      "牛磺酸(mg)": 17.2
    }
  },
  {
    id: "quaker-complete-original",
    name: "完膳營養素(原味即飲)",
    brand: "桂格 Quaker",
    volume_ml: 237,
    image: "images/桂格完膳營養素即飲.jpg",
    categories: ["醫療營養品"],
    nutrients: {
      "熱量(kcal)": 235, "蛋白質(g)": 12, "脂肪(g)": 9, "飽和脂肪(g)": 2,
      "反式脂肪(g)": 0, "膽固醇(mg)": 0, "碳水化合物(g)": 28.9, "糖(g)": 5.9,
      "膳食纖維(g)": 5,
      "鈉(mg)": 161, "鈣(mg)": 94.8,
      "維生素E(mg)": 3.8,
      "支鏈胺基酸BCAA(mg)": 2370, "牛磺酸(mg)": 28.4
    }
  },
  {
    id: "quaker-complete-diabetes",
    name: "完膳營養素(糖尿病適用)",
    brand: "桂格 Quaker",
    volume_ml: 237,
    image: "images/桂格完膳營養素糖尿病.jpg",
    categories: ["醫療營養品"],
    nutrients: {
      "熱量(kcal)": 250, "蛋白質(g)": 12, "脂肪(g)": 9.4, "飽和脂肪(g)": 2.1,
      "反式脂肪(g)": 0, "膽固醇(mg)": 33, "碳水化合物(g)": 32, "糖(g)": 1.8,
      "乳糖(g)": 0.9, "膳食纖維(g)": 5.3,
      "中鏈脂肪酸MCT(mg)": 5580, "必需胺基酸EAA(mg)": 5880, "支鏈胺基酸BCAA(mg)": 2220,
      "鈉(mg)": 265, "鉀(mg)": 360, "鈣(mg)": 312, "磷(mg)": 260,
      "鎂(mg)": 87.6, "鐵(mg)": 3.75, "鋅(mg)": 3.75,
      "碘(mcg)": 60, "硒(mcg)": 13, "氯(mg)": 285,
      "銅(mg)": 0.4, "鉻(mcg)": 100, "錳(mg)": 0.7, "鉬(mcg)": 20,
      "維生素A(mcgRE)": 228, "維生素D(mcg)": 3.75, "維生素E(mg)": 5.5,
      "維生素K(mcg)": 30, "維生素C(mg)": 30,
      "維生素B1(mg)": 0.33, "維生素B2(mg)": 0.40, "維生素B6(mg)": 0.48,
      "維生素B12(mcg)": 0.6,
      "菸鹼素(mgNE)": 4.8, "膽素(mg)": 113, "泛酸(mg)": 1.3,
      "葉酸(mcg)": 100, "生物素(mcg)": 7.5,
      "牛磺酸(mg)": 23, "左旋肉鹼(mg)": 23
    }
  },
  {
    id: "redcow-agei-diabetes",
    name: "愛基均衡及糖尿病配方營養素",
    brand: "紅牛 Red Cow",
    volume_ml: 237,
    image: "images/紅牛愛基均衡糖尿病配方.jpg",
    categories: ["醫療營養品"],
    nutrients: {
      "熱量(kcal)": 251, "蛋白質(g)": 11.5, "脂肪(g)": 9, "飽和脂肪(g)": 1.7,
      "反式脂肪(g)": 0, "碳水化合物(g)": 33.2, "糖(g)": 12.4, "膳食纖維(g)": 4.3,
      "鈉(mg)": 217, "鉀(mg)": 347, "鈣(mg)": 68, "鐵(mg)": 4.3,
      "維生素A(mcgRE)": 174, "維生素E(mg)": 7.8, "維生素K(mcg)": 31,
      "維生素C(mg)": 30,
      "維生素B1(mg)": 0.4, "維生素B2(mg)": 0.4, "維生素B6(mg)": 0.4,
      "維生素B12(mcg)": 0.4,
      "菸鹼素(mgNE)": 3.2, "葉酸(mcg)": 118, "生物素(mcg)": 9.9
    }
  },
  {
    id: "protison-whey-original",
    name: "補體素優蛋白(原味)",
    brand: "補體素 Protison / SMAD",
    volume_ml: 225,
    image: "images/補體素Protison優蛋白.jpg",
    categories: ["高蛋白補充品"],
    nutrients: {
      "熱量(kcal)": 88.6, "蛋白質(g)": 13, "脂肪(g)": 0.8, "飽和脂肪(g)": 0.6,
      "反式脂肪(g)": 0, "碳水化合物(g)": 7.4, "糖(g)": 6.3,
      "鈉(mg)": 60,
      "維生素A(mcgRE)": 165, "維生素D(mcg)": 15.0, "維生素E(mg)": 6.2,
      "維生素C(mg)": 13.0
    }
  },
  {
    id: "redcow-gold-protein",
    name: "康健黃金蛋白高鈣營養配方",
    brand: "紅牛 Red Cow",
    volume_ml: 200,
    image: "images/紅牛康健黃金蛋白.jpg",
    categories: ["高蛋白補充品"],
    nutrients: {
      "熱量(kcal)": 151, "蛋白質(g)": 17.8, "脂肪(g)": 2.2, "飽和脂肪(g)": 1.3,
      "反式脂肪(g)": 0, "碳水化合物(g)": 16, "糖(g)": 8.8, "膳食纖維(g)": 1.8,
      "鈉(mg)": 76, "鉀(mg)": 293, "鈣(mg)": 672, "磷(mg)": 213, "鎂(mg)": 29,
      "碘(mcg)": 8,
      "維生素A(mcgRE)": 44, "維生素D3(mcg)": 0.6, "維生素E(mg)": 1.0,
      "維生素K1(mcg)": 7.2, "維生素C(mg)": 13.6,
      "維生素B1(mg)": 0.2, "維生素B2(mg)": 0.5, "維生素B6(mg)": 0.6,
      "維生素B12(mcg)": 1.1,
      "菸鹼素(mgNE)": 1.5, "泛酸(mg)": 3.1, "葉酸(mcg)": 41, "生物素(mcg)": 25,
      "乳清蛋白(g)": 14, "葡萄糖胺鹽酸鹽(mg)": 646, "鳳梨酵素(mg)": 10
    }
  },
  {
    id: "sentosa-nutri-supplement",
    name: "三多補体健營養補充食品",
    brand: "三多 SENTOSA",
    volume_ml: 225,
    image: "images/三多補体健SENTOSA.jpg",
    categories: ["高蛋白補充品"],
    nutrients: {
      "熱量(kcal)": 97, "蛋白質(g)": 15.1, "脂肪(g)": 0.8, "飽和脂肪(g)": 0.5,
      "反式脂肪(g)": 0, "碳水化合物(g)": 7.4, "糖(g)": 4.8,
      "鈉(mg)": 55, "鉀(mg)": 169, "鈣(mg)": 263, "磷(mg)": 145, "鎂(mg)": 17,
      "維生素A(mcgRE)": 200, "維生素D(mcg)": 2.5, "維生素E(mg)": 3.7,
      "維生素C(mg)": 25,
      "維生素B1(mg)": 0.5, "維生素B2(mg)": 0.5, "維生素B6(mg)": 0.5,
      "維生素B12(mcg)": 1.3,
      "菸鹼素(mgNE)": 7.5, "泛酸(mg)": 1.8, "葉酸(mcg)": 135, "生物素(mcg)": 12,
      "麩醯胺酸(mg)": 2500
    }
  },
  {
    id: "abbott-ensure-ex-220",
    name: "安素EX即飲配方(原味)",
    brand: "亞培 Abbott",
    volume_ml: 220,
    image: null,
    categories: ["醫療營養品"],
    nutrients: {
      "熱量(kcal)": 150, "蛋白質(g)": 9.1, "脂肪(g)": 4.8, "飽和脂肪(g)": 0.6,
      "反式脂肪(g)": 0, "碳水化合物(g)": 17.8, "糖(g)": 5.4,
      "膳食纖維(g)": 1.5, "鈉(mg)": 140, "鉀(mg)": 320, "鈣(mg)": 175,
      "磷(mg)": 160, "鎂(mg)": 42, "鋅(mg)": 1.8, "鐵(mg)": 2.1,
      "維生素C(mg)": 16, "維生素D(mcg)": 2.7
    }
  }
];
