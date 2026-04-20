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
      "鈉(mg)": 66, "鉀(mg)": 158
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
      "反式脂肪(g)": 0, "碳水化合物(g)": 30.5, "糖(g)": 8.7,
      "膳食纖維(g)": 0.7, "鈉(mg)": 225
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
      "反式脂肪(g)": 0, "碳水化合物(g)": 7.4, "糖(g)": 6.9,
      "膳食纖維(g)": 0.5, "鈉(mg)": 17
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
      "反式脂肪(g)": 0, "碳水化合物(g)": 35.2, "糖(g)": 1.4,
      "膳食纖維(g)": 0, "鈉(mg)": 223
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
      "膳食纖維(g)": 4.4, "鈉(mg)": 264
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
      "反式脂肪(g)": 0, "碳水化合物(g)": 28.9, "糖(g)": 5.9,
      "膳食纖維(g)": 5, "鈉(mg)": 161
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
      "反式脂肪(g)": 0, "碳水化合物(g)": 32, "糖(g)": 1.8,
      "膳食纖維(g)": 5.3, "鈉(mg)": 265
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
      "反式脂肪(g)": 0, "碳水化合物(g)": 33.2, "糖(g)": 12.4,
      "膳食纖維(g)": 4.3, "鈉(mg)": 217
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
      "反式脂肪(g)": 0, "碳水化合物(g)": 7.4, "糖(g)": 6.3, "鈉(mg)": 60
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
      "反式脂肪(g)": 0, "碳水化合物(g)": 16, "糖(g)": 8.8,
      "膳食纖維(g)": 1.8, "鈉(mg)": 76, "鈣(mg)": 672
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
      "鈉(mg)": 55, "鈣(mg)": 263
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
