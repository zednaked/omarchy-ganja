.pragma library

// GERADO por `make strains` a partir de strains.json do Ganja-TUI.
// Nao editar a mao: a proxima geracao apaga a edicao.
//
// Sao dados estaticos - os 35 strains com genetica real. Ler o JSON em
// tempo de execucao custaria um processo e um parse a cada planta nova,
// por um arquivo que so muda quando alguem edita o repo de origem.

var STRAINS = [
  {
    "name": "Purple Kush",
    "type": "Indica",
    "genetics": "Hindu Kush x Purple Afghani",
    "thc_min": 18.0,
    "thc_max": 27.0,
    "cbd_min": 0.1,
    "cbd_max": 0.3,
    "flowering_time": 56,
    "difficulty": "Easy",
    "yield_potential": "High",
    "dominant_terpenes": [
      "Myrcene",
      "Caryophyllene",
      "Pinene"
    ],
    "aroma": [
      "Earthy",
      "Sweet",
      "Grape"
    ],
    "effects": [
      "Relaxing",
      "Sleepy",
      "Euphoric"
    ],
    "height": "Short",
    "phenotype": "Bushy"
  },
  {
    "name": "Sour Diesel",
    "type": "Sativa",
    "genetics": "Chemdawg 91 x Super Skunk",
    "thc_min": 20.0,
    "thc_max": 26.0,
    "cbd_min": 0.1,
    "cbd_max": 0.2,
    "flowering_time": 70,
    "difficulty": "Medium",
    "yield_potential": "Medium",
    "dominant_terpenes": [
      "Caryophyllene",
      "Limonene",
      "Myrcene"
    ],
    "aroma": [
      "Diesel",
      "Pungent",
      "Citrus"
    ],
    "effects": [
      "Energetic",
      "Creative",
      "Uplifting"
    ],
    "height": "Tall",
    "phenotype": "Tall"
  },
  {
    "name": "Blue Dream",
    "type": "Hybrid",
    "genetics": "Blueberry x Haze",
    "thc_min": 17.0,
    "thc_max": 24.0,
    "cbd_min": 0.1,
    "cbd_max": 0.2,
    "flowering_time": 63,
    "difficulty": "Easy",
    "yield_potential": "High",
    "dominant_terpenes": [
      "Myrcene",
      "Pinene",
      "Caryophyllene"
    ],
    "aroma": [
      "Blueberry",
      "Sweet",
      "Herbal"
    ],
    "effects": [
      "Balanced",
      "Creative",
      "Relaxed"
    ],
    "height": "Medium",
    "phenotype": "Balanced"
  },
  {
    "name": "Northern Lights",
    "type": "Indica",
    "genetics": "Afghani x Thai",
    "thc_min": 16.0,
    "thc_max": 21.0,
    "cbd_min": 0.1,
    "cbd_max": 0.3,
    "flowering_time": 49,
    "difficulty": "Easy",
    "yield_potential": "Medium",
    "dominant_terpenes": [
      "Myrcene",
      "Caryophyllene",
      "Limonene"
    ],
    "aroma": [
      "Sweet",
      "Earthy",
      "Pine"
    ],
    "effects": [
      "Relaxing",
      "Happy",
      "Sleepy"
    ],
    "height": "Short",
    "phenotype": "Bushy"
  },
  {
    "name": "Jack Herer",
    "type": "Sativa",
    "genetics": "Haze x Red Skunk",
    "thc_min": 18.0,
    "thc_max": 24.0,
    "cbd_min": 0.1,
    "cbd_max": 0.2,
    "flowering_time": 63,
    "difficulty": "Medium",
    "yield_potential": "Medium",
    "dominant_terpenes": [
      "Terpinolene",
      "Caryophyllene",
      "Pinene"
    ],
    "aroma": [
      "Spicy",
      "Pine",
      "Earthy"
    ],
    "effects": [
      "Energetic",
      "Creative",
      "Focused"
    ],
    "height": "Tall",
    "phenotype": "Tall"
  },
  {
    "name": "White Widow",
    "type": "Hybrid",
    "genetics": "Brazilian x South Indian",
    "thc_min": 18.0,
    "thc_max": 25.0,
    "cbd_min": 0.1,
    "cbd_max": 0.2,
    "flowering_time": 60,
    "difficulty": "Easy",
    "yield_potential": "High",
    "dominant_terpenes": [
      "Myrcene",
      "Caryophyllene",
      "Limonene"
    ],
    "aroma": [
      "Earthy",
      "Woody",
      "Floral"
    ],
    "effects": [
      "Euphoric",
      "Energetic",
      "Happy"
    ],
    "height": "Medium",
    "phenotype": "Balanced"
  },
  {
    "name": "OG Kush",
    "type": "Hybrid",
    "genetics": "Chemdawg x Hindu Kush",
    "thc_min": 20.0,
    "thc_max": 27.0,
    "cbd_min": 0.1,
    "cbd_max": 0.3,
    "flowering_time": 56,
    "difficulty": "Hard",
    "yield_potential": "Medium",
    "dominant_terpenes": [
      "Myrcene",
      "Limonene",
      "Caryophyllene"
    ],
    "aroma": [
      "Earthy",
      "Pine",
      "Woody"
    ],
    "effects": [
      "Relaxed",
      "Happy",
      "Euphoric"
    ],
    "height": "Short",
    "phenotype": "Bushy"
  },
  {
    "name": "Amnesia Haze",
    "type": "Sativa",
    "genetics": "Haze x Afghan",
    "thc_min": 20.0,
    "thc_max": 25.0,
    "cbd_min": 0.1,
    "cbd_max": 0.2,
    "flowering_time": 70,
    "difficulty": "Hard",
    "yield_potential": "High",
    "dominant_terpenes": [
      "Terpinolene",
      "Caryophyllene",
      "Myrcene"
    ],
    "aroma": [
      "Citrus",
      "Earthy",
      "Spicy"
    ],
    "effects": [
      "Uplifting",
      "Creative",
      "Energetic"
    ],
    "height": "Tall",
    "phenotype": "Tall"
  },
  {
    "name": "Granddaddy Purple",
    "type": "Indica",
    "genetics": "Purple Urkle x Big Bud",
    "thc_min": 17.0,
    "thc_max": 23.0,
    "cbd_min": 0.1,
    "cbd_max": 0.7,
    "flowering_time": 60,
    "difficulty": "Easy",
    "yield_potential": "High",
    "dominant_terpenes": [
      "Myrcene",
      "Pinene",
      "Caryophyllene"
    ],
    "aroma": [
      "Grape",
      "Berry",
      "Sweet"
    ],
    "effects": [
      "Relaxing",
      "Sleepy",
      "Euphoric"
    ],
    "height": "Short",
    "phenotype": "Bushy"
  },
  {
    "name": "Green Crack",
    "type": "Sativa",
    "genetics": "Skunk #1 x Afghani",
    "thc_min": 15.0,
    "thc_max": 25.0,
    "cbd_min": 0.1,
    "cbd_max": 0.2,
    "flowering_time": 53,
    "difficulty": "Medium",
    "yield_potential": "Medium",
    "dominant_terpenes": [
      "Myrcene",
      "Caryophyllene",
      "Pinene"
    ],
    "aroma": [
      "Citrus",
      "Earthy",
      "Sweet"
    ],
    "effects": [
      "Energetic",
      "Focused",
      "Happy"
    ],
    "height": "Medium",
    "phenotype": "Balanced"
  },
  {
    "name": "Gorilla Glue #4",
    "type": "Hybrid",
    "genetics": "Chem's Sister x Sour Dubb x Chocolate Diesel",
    "thc_min": 25.0,
    "thc_max": 30.0,
    "cbd_min": 0.1,
    "cbd_max": 0.1,
    "flowering_time": 56,
    "difficulty": "Medium",
    "yield_potential": "High",
    "dominant_terpenes": [
      "Caryophyllene",
      "Myrcene",
      "Limonene"
    ],
    "aroma": [
      "Earthy",
      "Pungent",
      "Pine"
    ],
    "effects": [
      "Relaxing",
      "Euphoric",
      "Happy"
    ],
    "height": "Medium",
    "phenotype": "Balanced"
  },
  {
    "name": "Girl Scout Cookies",
    "type": "Hybrid",
    "genetics": "Durban Poison x OG Kush",
    "thc_min": 20.0,
    "thc_max": 28.0,
    "cbd_min": 0.1,
    "cbd_max": 0.2,
    "flowering_time": 60,
    "difficulty": "Hard",
    "yield_potential": "Medium",
    "dominant_terpenes": [
      "Caryophyllene",
      "Limonene",
      "Humulene"
    ],
    "aroma": [
      "Sweet",
      "Earthy",
      "Mint"
    ],
    "effects": [
      "Relaxed",
      "Happy",
      "Euphoric"
    ],
    "height": "Short",
    "phenotype": "Bushy"
  },
  {
    "name": "AK-47",
    "type": "Hybrid",
    "genetics": "Colombian x Mexican x Thai x Afghani",
    "thc_min": 16.0,
    "thc_max": 20.0,
    "cbd_min": 0.5,
    "cbd_max": 1.5,
    "flowering_time": 56,
    "difficulty": "Easy",
    "yield_potential": "Medium",
    "dominant_terpenes": [
      "Terpinolene",
      "Caryophyllene",
      "Myrcene"
    ],
    "aroma": [
      "Earthy",
      "Sour",
      "Floral"
    ],
    "effects": [
      "Relaxed",
      "Creative",
      "Happy"
    ],
    "height": "Medium",
    "phenotype": "Balanced"
  },
  {
    "name": "Pineapple Express",
    "type": "Hybrid",
    "genetics": "Trainwreck x Hawaiian",
    "thc_min": 19.0,
    "thc_max": 25.0,
    "cbd_min": 0.1,
    "cbd_max": 0.2,
    "flowering_time": 60,
    "difficulty": "Medium",
    "yield_potential": "High",
    "dominant_terpenes": [
      "Caryophyllene",
      "Limonene",
      "Ocimene"
    ],
    "aroma": [
      "Tropical",
      "Pineapple",
      "Cedar"
    ],
    "effects": [
      "Happy",
      "Energetic",
      "Uplifting"
    ],
    "height": "Medium",
    "phenotype": "Balanced"
  },
  {
    "name": "Strawberry Cough",
    "type": "Sativa",
    "genetics": "Strawberry Fields x Haze",
    "thc_min": 15.0,
    "thc_max": 20.0,
    "cbd_min": 0.1,
    "cbd_max": 0.2,
    "flowering_time": 63,
    "difficulty": "Easy",
    "yield_potential": "Medium",
    "dominant_terpenes": [
      "Myrcene",
      "Pinene",
      "Caryophyllene"
    ],
    "aroma": [
      "Strawberry",
      "Sweet",
      "Earthy"
    ],
    "effects": [
      "Uplifting",
      "Creative",
      "Happy"
    ],
    "height": "Tall",
    "phenotype": "Tall"
  },
  {
    "name": "Gelato",
    "type": "Hybrid",
    "genetics": "Sunset Sherbet x Thin Mint GSC",
    "thc_min": 20.0,
    "thc_max": 26.0,
    "cbd_min": 0.1,
    "cbd_max": 0.2,
    "flowering_time": 56,
    "difficulty": "Medium",
    "yield_potential": "Medium",
    "dominant_terpenes": [
      "Caryophyllene",
      "Limonene",
      "Humulene"
    ],
    "aroma": [
      "Sweet",
      "Citrus",
      "Lavender"
    ],
    "effects": [
      "Euphoric",
      "Relaxed",
      "Creative"
    ],
    "height": "Short",
    "phenotype": "Bushy"
  },
  {
    "name": "Zkittlez",
    "type": "Indica",
    "genetics": "Grape Ape x Grapefruit",
    "thc_min": 15.0,
    "thc_max": 23.0,
    "cbd_min": 0.1,
    "cbd_max": 0.5,
    "flowering_time": 56,
    "difficulty": "Easy",
    "yield_potential": "High",
    "dominant_terpenes": [
      "Caryophyllene",
      "Linalool",
      "Humulene"
    ],
    "aroma": [
      "Fruity",
      "Grape",
      "Sweet"
    ],
    "effects": [
      "Relaxing",
      "Happy",
      "Focused"
    ],
    "height": "Short",
    "phenotype": "Bushy"
  },
  {
    "name": "Durban Poison",
    "type": "Sativa",
    "genetics": "South African Landrace",
    "thc_min": 15.0,
    "thc_max": 25.0,
    "cbd_min": 0.1,
    "cbd_max": 0.1,
    "flowering_time": 63,
    "difficulty": "Easy",
    "yield_potential": "High",
    "dominant_terpenes": [
      "Terpinolene",
      "Myrcene",
      "Ocimene"
    ],
    "aroma": [
      "Sweet",
      "Earthy",
      "Pine"
    ],
    "effects": [
      "Energetic",
      "Uplifting",
      "Creative"
    ],
    "height": "Tall",
    "phenotype": "Tall"
  },
  {
    "name": "Wedding Cake",
    "type": "Hybrid",
    "genetics": "Cherry Pie x Girl Scout Cookies",
    "thc_min": 21.0,
    "thc_max": 27.0,
    "cbd_min": 0.1,
    "cbd_max": 0.3,
    "flowering_time": 60,
    "difficulty": "Medium",
    "yield_potential": "Medium",
    "dominant_terpenes": [
      "Limonene",
      "Caryophyllene",
      "Myrcene"
    ],
    "aroma": [
      "Sweet",
      "Vanilla",
      "Earthy"
    ],
    "effects": [
      "Relaxed",
      "Happy",
      "Euphoric"
    ],
    "height": "Medium",
    "phenotype": "Balanced"
  },
  {
    "name": "Critical Mass",
    "type": "Indica",
    "genetics": "Afghani x Skunk #1",
    "thc_min": 19.0,
    "thc_max": 22.0,
    "cbd_min": 0.3,
    "cbd_max": 5.0,
    "flowering_time": 56,
    "difficulty": "Easy",
    "yield_potential": "Very High",
    "dominant_terpenes": [
      "Myrcene",
      "Pinene",
      "Caryophyllene"
    ],
    "aroma": [
      "Sweet",
      "Earthy",
      "Citrus"
    ],
    "effects": [
      "Relaxing",
      "Sleepy",
      "Happy"
    ],
    "height": "Short",
    "phenotype": "Bushy"
  },
  {
    "name": "Trainwreck",
    "type": "Sativa",
    "genetics": "Mexican x Thai x Afghani",
    "thc_min": 18.0,
    "thc_max": 25.0,
    "cbd_min": 0.1,
    "cbd_max": 0.2,
    "flowering_time": 63,
    "difficulty": "Medium",
    "yield_potential": "High",
    "dominant_terpenes": [
      "Terpinolene",
      "Myrcene",
      "Limonene"
    ],
    "aroma": [
      "Lemon",
      "Pine",
      "Spicy"
    ],
    "effects": [
      "Euphoric",
      "Creative",
      "Happy"
    ],
    "height": "Tall",
    "phenotype": "Tall"
  },
  {
    "name": "Runtz",
    "type": "Hybrid",
    "genetics": "Zkittlez x Gelato",
    "thc_min": 19.0,
    "thc_max": 29.0,
    "cbd_min": 0.1,
    "cbd_max": 0.2,
    "flowering_time": 63,
    "difficulty": "Hard",
    "yield_potential": "Medium",
    "dominant_terpenes": [
      "Caryophyllene",
      "Limonene",
      "Linalool"
    ],
    "aroma": [
      "Fruity",
      "Candy",
      "Tropical"
    ],
    "effects": [
      "Euphoric",
      "Relaxed",
      "Uplifting"
    ],
    "height": "Medium",
    "phenotype": "Balanced"
  },
  {
    "name": "Bubba Kush",
    "type": "Indica",
    "genetics": "OG Kush x Afghani",
    "thc_min": 14.0,
    "thc_max": 22.0,
    "cbd_min": 0.1,
    "cbd_max": 0.5,
    "flowering_time": 56,
    "difficulty": "Easy",
    "yield_potential": "Medium",
    "dominant_terpenes": [
      "Myrcene",
      "Limonene",
      "Caryophyllene"
    ],
    "aroma": [
      "Earthy",
      "Sweet",
      "Hash"
    ],
    "effects": [
      "Relaxing",
      "Sleepy",
      "Happy"
    ],
    "height": "Short",
    "phenotype": "Bushy"
  },
  {
    "name": "Super Lemon Haze",
    "type": "Sativa",
    "genetics": "Lemon Skunk x Super Silver Haze",
    "thc_min": 16.0,
    "thc_max": 25.0,
    "cbd_min": 0.1,
    "cbd_max": 0.2,
    "flowering_time": 70,
    "difficulty": "Medium",
    "yield_potential": "High",
    "dominant_terpenes": [
      "Terpinolene",
      "Caryophyllene",
      "Myrcene"
    ],
    "aroma": [
      "Lemon",
      "Citrus",
      "Sweet"
    ],
    "effects": [
      "Energetic",
      "Uplifting",
      "Creative"
    ],
    "height": "Tall",
    "phenotype": "Tall"
  },
  {
    "name": "Do-Si-Dos",
    "type": "Indica",
    "genetics": "Girl Scout Cookies x Face Off OG",
    "thc_min": 22.0,
    "thc_max": 30.0,
    "cbd_min": 0.1,
    "cbd_max": 0.2,
    "flowering_time": 63,
    "difficulty": "Medium",
    "yield_potential": "Medium",
    "dominant_terpenes": [
      "Limonene",
      "Caryophyllene",
      "Linalool"
    ],
    "aroma": [
      "Earthy",
      "Floral",
      "Lime"
    ],
    "effects": [
      "Relaxing",
      "Euphoric",
      "Sleepy"
    ],
    "height": "Short",
    "phenotype": "Bushy"
  },
  {
    "name": "Tangie",
    "type": "Sativa",
    "genetics": "California Orange x Skunk #1",
    "thc_min": 19.0,
    "thc_max": 22.0,
    "cbd_min": 0.1,
    "cbd_max": 0.1,
    "flowering_time": 63,
    "difficulty": "Medium",
    "yield_potential": "Medium",
    "dominant_terpenes": [
      "Terpinolene",
      "Myrcene",
      "Ocimene"
    ],
    "aroma": [
      "Citrus",
      "Orange",
      "Sweet"
    ],
    "effects": [
      "Uplifting",
      "Creative",
      "Energetic"
    ],
    "height": "Tall",
    "phenotype": "Tall"
  },
  {
    "name": "Sherbet",
    "type": "Hybrid",
    "genetics": "Girl Scout Cookies x Pink Panties",
    "thc_min": 18.0,
    "thc_max": 24.0,
    "cbd_min": 0.1,
    "cbd_max": 0.3,
    "flowering_time": 56,
    "difficulty": "Medium",
    "yield_potential": "Medium",
    "dominant_terpenes": [
      "Caryophyllene",
      "Limonene",
      "Linalool"
    ],
    "aroma": [
      "Sweet",
      "Berry",
      "Citrus"
    ],
    "effects": [
      "Relaxed",
      "Happy",
      "Euphoric"
    ],
    "height": "Medium",
    "phenotype": "Balanced"
  },
  {
    "name": "Chemdawg",
    "type": "Hybrid",
    "genetics": "Unknown (Thai x Nepalese)",
    "thc_min": 15.0,
    "thc_max": 20.0,
    "cbd_min": 0.1,
    "cbd_max": 0.2,
    "flowering_time": 63,
    "difficulty": "Hard",
    "yield_potential": "Medium",
    "dominant_terpenes": [
      "Myrcene",
      "Limonene",
      "Caryophyllene"
    ],
    "aroma": [
      "Diesel",
      "Pungent",
      "Earthy"
    ],
    "effects": [
      "Euphoric",
      "Relaxed",
      "Creative"
    ],
    "height": "Medium",
    "phenotype": "Balanced"
  },
  {
    "name": "Skywalker OG",
    "type": "Indica",
    "genetics": "Skywalker x OG Kush",
    "thc_min": 20.0,
    "thc_max": 26.0,
    "cbd_min": 0.1,
    "cbd_max": 0.3,
    "flowering_time": 63,
    "difficulty": "Medium",
    "yield_potential": "High",
    "dominant_terpenes": [
      "Myrcene",
      "Caryophyllene",
      "Limonene"
    ],
    "aroma": [
      "Earthy",
      "Spicy",
      "Diesel"
    ],
    "effects": [
      "Relaxing",
      "Sleepy",
      "Euphoric"
    ],
    "height": "Short",
    "phenotype": "Bushy"
  },
  {
    "name": "Maui Wowie",
    "type": "Sativa",
    "genetics": "Hawaiian Landrace",
    "thc_min": 13.0,
    "thc_max": 19.0,
    "cbd_min": 0.1,
    "cbd_max": 0.2,
    "flowering_time": 63,
    "difficulty": "Easy",
    "yield_potential": "Medium",
    "dominant_terpenes": [
      "Myrcene",
      "Pinene",
      "Caryophyllene"
    ],
    "aroma": [
      "Tropical",
      "Pineapple",
      "Citrus"
    ],
    "effects": [
      "Uplifting",
      "Energetic",
      "Creative"
    ],
    "height": "Tall",
    "phenotype": "Tall"
  },
  {
    "name": "Purple Punch",
    "type": "Indica",
    "genetics": "Larry OG x Granddaddy Purple",
    "thc_min": 18.0,
    "thc_max": 25.0,
    "cbd_min": 0.1,
    "cbd_max": 0.5,
    "flowering_time": 56,
    "difficulty": "Easy",
    "yield_potential": "High",
    "dominant_terpenes": [
      "Caryophyllene",
      "Pinene",
      "Limonene"
    ],
    "aroma": [
      "Grape",
      "Blueberry",
      "Vanilla"
    ],
    "effects": [
      "Relaxing",
      "Sleepy",
      "Happy"
    ],
    "height": "Short",
    "phenotype": "Bushy"
  },
  {
    "name": "Acapulco Gold",
    "type": "Sativa",
    "genetics": "Mexican Landrace",
    "thc_min": 15.0,
    "thc_max": 24.0,
    "cbd_min": 0.1,
    "cbd_max": 0.1,
    "flowering_time": 70,
    "difficulty": "Hard",
    "yield_potential": "Medium",
    "dominant_terpenes": [
      "Caryophyllene",
      "Myrcene",
      "Pinene"
    ],
    "aroma": [
      "Earthy",
      "Sweet",
      "Toffee"
    ],
    "effects": [
      "Euphoric",
      "Energetic",
      "Creative"
    ],
    "height": "Tall",
    "phenotype": "Tall"
  },
  {
    "name": "Bruce Banner",
    "type": "Hybrid",
    "genetics": "OG Kush x Strawberry Diesel",
    "thc_min": 24.0,
    "thc_max": 29.0,
    "cbd_min": 0.1,
    "cbd_max": 0.2,
    "flowering_time": 60,
    "difficulty": "Medium",
    "yield_potential": "High",
    "dominant_terpenes": [
      "Myrcene",
      "Caryophyllene",
      "Limonene"
    ],
    "aroma": [
      "Diesel",
      "Sweet",
      "Earthy"
    ],
    "effects": [
      "Euphoric",
      "Relaxed",
      "Happy"
    ],
    "height": "Medium",
    "phenotype": "Balanced"
  },
  {
    "name": "LA Confidential",
    "type": "Indica",
    "genetics": "OG LA Affie x Afghani",
    "thc_min": 16.0,
    "thc_max": 20.0,
    "cbd_min": 0.1,
    "cbd_max": 0.5,
    "flowering_time": 56,
    "difficulty": "Easy",
    "yield_potential": "Medium",
    "dominant_terpenes": [
      "Myrcene",
      "Pinene",
      "Caryophyllene"
    ],
    "aroma": [
      "Pine",
      "Earthy",
      "Skunk"
    ],
    "effects": [
      "Relaxing",
      "Sleepy",
      "Happy"
    ],
    "height": "Short",
    "phenotype": "Bushy"
  },
  {
    "name": "Harlequin",
    "type": "Sativa",
    "genetics": "Colombian Gold x Thai x Swiss",
    "thc_min": 7.0,
    "thc_max": 15.0,
    "cbd_min": 8.0,
    "cbd_max": 16.0,
    "flowering_time": 63,
    "difficulty": "Medium",
    "yield_potential": "Medium",
    "dominant_terpenes": [
      "Myrcene",
      "Pinene",
      "Caryophyllene"
    ],
    "aroma": [
      "Earthy",
      "Mango",
      "Spicy"
    ],
    "effects": [
      "Relaxed",
      "Clear-headed",
      "Focused"
    ],
    "height": "Tall",
    "phenotype": "Tall"
  }
]


function count() { return STRAINS.length }
function byIndex(i) { return STRAINS[((i % STRAINS.length) + STRAINS.length) % STRAINS.length] }
function byName(name) {
  for (var i = 0; i < STRAINS.length; i++)
    if (STRAINS[i].name === name) return STRAINS[i]
  return null
}
