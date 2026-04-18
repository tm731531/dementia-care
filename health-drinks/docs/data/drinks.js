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
  }
];
