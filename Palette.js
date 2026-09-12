.pragma library

// Porta de src/ui/colors.rs do Ganja-TUI - as quatro paletas de truecolor, com
// os RGB literais de la.
//
// O Basic16Palette nao veio junto de proposito: ele existe no TUI para
// terminais sem truecolor, e aqui nao ha terminal. O overlay desenha em RGB
// sempre.
//
// Tres cores do TUI eram nomes de ANSI (`Color::Green` no caule de muda,
// `Color::DarkGray` na germinacao, `Color::Yellow` nos primeiros calices) e
// nome de ANSI nao tem RGB: quem decide e o terminal. Aqui viraram valores
// fixos escolhidos dentro da propria paleta do Ganja - ver ANSI, no fim.
//
// Uma divergencia deliberada em relacao ao TUI: o modo Rainbow cicla o matiz
// por frame. No Rust isso e um TODO e o matiz esta parado. A SPEC pede o ciclo,
// e sem ele o modo e so "cores diferentes", nao psicodelico.

// ---- utilitarios ------------------------------------------------------------

function byte(x) { return Math.min(255, Math.max(0, Math.trunc(x))) }

function hex(rgb) {
  var s = "#"
  for (var i = 0; i < 3; i++) {
    var p = byte(rgb[i]).toString(16)
    s += (p.length < 2 ? "0" : "") + p
  }
  return s
}

// fn hsv_to_rgb(h, s, v)
function hsvToRgb(h, s, v) {
  var c = v * s
  var hp = (h % 360.0) / 60.0
  var x = c * (1.0 - Math.abs((hp % 2.0) - 1.0))
  var m = v - c
  var r, g, b
  if (hp < 1.0) { r = c; g = x; b = 0.0 }
  else if (hp < 2.0) { r = x; g = c; b = 0.0 }
  else if (hp < 3.0) { r = 0.0; g = c; b = x }
  else if (hp < 4.0) { r = 0.0; g = x; b = c }
  else if (hp < 5.0) { r = x; g = 0.0; b = c }
  else { r = c; g = 0.0; b = x }
  return [(r + m) * 255.0, (g + m) * 255.0, (b + m) * 255.0]
}

// fn apply_breathing(color, factor)
function applyBreathing(rgb, factor) {
  return [Math.min(255.0, rgb[0] * factor),
          Math.min(255.0, rgb[1] * factor),
          Math.min(255.0, rgb[2] * factor)]
}

// Velocidade da respiracao por modo (growing.rs). Zen respira devagar de
// proposito; Rainbow acelera.
function breathSpeed(mode) {
  switch (mode) {
  case "Zen": return 0.02
  case "Rainbow": return 0.08
  case "Matrix": return 0.06
  default: return 0.05
  }
}

// Quanto o matiz anda por frame no Rainbow.
var RAINBOW_DRIFT = 2.0
function drift(frame) { return (RAINBOW_DRIFT * frame) % 360.0 }

// ---- Normal (TrueColorPalette) ---------------------------------------------

var FLOWERS_NORMAL = [
  // variante 0 - roxo profundo (indica)
  { Early: [180, 120, 200], Developing: [140, 80, 180], Peak: [120, 40, 160], Harvest: [100, 20, 140] },
  // variante 1 - laranja/vermelho (sativa)
  { Early: [255, 180, 100], Developing: [255, 140, 60], Peak: [240, 100, 40], Harvest: [220, 60, 20] },
  // variante 2 - dourado
  { Early: [255, 255, 150], Developing: [255, 220, 100], Peak: [240, 200, 60], Harvest: [220, 180, 40] },
  // variante 3 - rosa/magenta
  { Early: [255, 200, 220], Developing: [255, 150, 200], Peak: [240, 100, 180], Harvest: [220, 60, 160] },
  // variante 4 - azul/teal (raro)
  { Early: [150, 220, 230], Developing: [100, 200, 220], Peak: [60, 180, 200], Harvest: [40, 160, 180] },
  // variante 5 - branco/creme (muito THC, congelada de tricomas)
  { Early: [240, 240, 220], Developing: [255, 255, 240], Peak: [255, 255, 255], Harvest: [240, 240, 255] }
]

var FOLIAGE_NORMAL = [
  [60, 140, 60],    // verde floresta
  [80, 180, 80],    // verde vivo
  [100, 200, 100],  // verde limao
  [40, 120, 70]     // verde escuro
]

var TRUNK_NORMAL = [
  [139, 90, 60],   // madeira clara
  [101, 67, 33],   // madeira media
  [70, 50, 30]     // madeira escura
]

// ---- fachada por modo -------------------------------------------------------

function flowerColor(mode, variant, intensity, stage, frame) {
  if (mode === "Rainbow") {
    var hue = (variant * 60.0 + drift(frame)) % 360.0
    var sv = intensity === "Early" ? [0.5, 0.7]
           : intensity === "Developing" ? [0.7, 0.9] : [1.0, 1.0]
    return hsvToRgb(hue, sv[0], sv[1])
  }
  if (mode === "Zen") {
    switch (intensity) {
    case "Early": return [200, 200, 220]
    case "Developing": return [220, 200, 210]
    case "Peak": return [230, 220, 210]
    default: return [240, 230, 220]
    }
  }
  if (mode === "Matrix") {
    switch (intensity) {
    case "Early": return [0, 180, 0]
    case "Developing": return [0, 220, 0]
    case "Peak": return [0, 255, 0]
    default: return [100, 255, 100]
    }
  }
  return FLOWERS_NORMAL[variant % 6][intensity].slice()
}

function foliageColor(mode, variant, health, water, frame) {
  if (mode === "Rainbow") {
    var hue = (120.0 + variant * 90.0 + drift(frame)) % 360.0
    return hsvToRgb(hue, 0.6, 0.8)
  }
  if (mode === "Zen") {
    if (health > 70.0) return [140, 160, 140]
    if (health > 40.0) return [160, 170, 150]
    return [180, 180, 170]
  }
  if (mode === "Matrix") return [0, byte(120.0 + (health / 100.0) * 135.0), 0]

  var base = FOLIAGE_NORMAL[variant % 4]
  var r = base[0], g = base[1], b = base[2]

  if (health < 40.0) { r = 120; g = 100; b = 60 }            // critica: marrom
  else if (health < 60.0) { g = byte(g * 0.7); r = byte(Math.min(r * 1.3, 255.0)) }
  else if (health < 80.0) { g = byte(g * 0.8) }

  if (water < 30.0) {                                         // seca: dessatura
    var avg = byte((r + g + b) / 3)
    r = byte(r * 0.6 + avg * 0.4)
    g = byte(g * 0.6 + avg * 0.4)
    b = byte(b * 0.6 + avg * 0.4)
  } else if (water > 80.0) {
    r = byte(Math.min(r * 1.1, 255.0))
    g = byte(Math.min(g * 1.1, 255.0))
    b = byte(Math.min(b * 1.1, 255.0))
  }
  return [r, g, b]
}

function trunkColor(mode, variant, ageDays, frame) {
  if (mode === "Rainbow") {
    var hue = (30.0 + variant * 120.0 + drift(frame)) % 360.0
    return hsvToRgb(hue, 0.5, 0.6)
  }
  if (mode === "Zen") return [160, 140, 120]
  if (mode === "Matrix") return [0, 60 + Math.trunc(Math.min(ageDays, 90) / 3), 0]

  var base = TRUNK_NORMAL[variant % 3]
  var r = base[0], g = base[1], b = base[2]
  if (ageDays <= 20) { g = byte(Math.min(g * 1.3, 255.0)); b = byte(b * 0.9) }
  else if (ageDays <= 50) { r = byte(Math.min(r + 10.0, 255.0)); g = byte(Math.max(g - 10.0, 0.0)) }
  else { r = byte(Math.min(r + 20.0, 255.0)); g = byte(Math.max(g - 20.0, 0.0)) }
  return [r, g, b]
}

function soilColor(mode, moisture, frame) {
  if (mode === "Rainbow") return hsvToRgb((30.0 + drift(frame)) % 360.0, 0.5, 0.2 + (moisture / 100.0 * 0.4))
  if (mode === "Zen") return moisture > 60.0 ? [130, 120, 110] : [180, 170, 150]
  if (mode === "Matrix") return [0, byte(20.0 + moisture * 0.5), 0]
  if (moisture > 70.0) return [80, 60, 40]
  if (moisture > 40.0) return [120, 90, 60]
  return [160, 130, 90]
}

function waterColor(mode, level, frame) {
  var t
  if (mode === "Rainbow") return hsvToRgb(180.0 + (level / 100.0 * 60.0), 0.8, 0.9)
  if (mode === "Zen") {
    t = Math.min(Math.max(level / 100.0, 0.0), 1.0)
    return [180.0 + 40.0 * t, 200.0 + 30.0 * t, 220.0 + 20.0 * t]
  }
  if (mode === "Matrix") return [0, byte(100.0 + level * 1.55), 0]

  var l = Math.min(Math.max(level, 0.0), 100.0)
  if (l < 20.0) { t = l / 20.0; return [255, 60.0 * t, 0] }
  if (l < 40.0) { t = (l - 20.0) / 20.0; return [255, 60.0 + 195.0 * t, 0] }
  if (l < 60.0) { t = (l - 40.0) / 20.0; return [255.0 * (1.0 - t), 255, 255.0 * t] }
  t = (l - 60.0) / 40.0
  return [0, 255.0 * (1.0 - t * 0.7), 255]
}

function nutrientColor(mode, level, frame) {
  var t
  if (mode === "Rainbow") return hsvToRgb(60.0 + (level / 100.0 * 60.0), 0.7, 0.9)
  if (mode === "Zen") {
    t = Math.min(Math.max(level / 100.0, 0.0), 1.0)
    return [180.0 - 40.0 * t, 200.0 - 20.0 * t, 160.0 - 20.0 * t]
  }
  if (mode === "Matrix") return [50, byte(150.0 + level * 1.05), 0]

  var l = Math.min(Math.max(level, 0.0), 100.0)
  if (l < 30.0) { t = l / 30.0; return [255, 120.0 * t, 0] }
  if (l < 50.0) { t = (l - 30.0) / 20.0; return [255, 120.0 + 135.0 * t, 0] }
  if (l < 75.0) { t = (l - 50.0) / 25.0; return [255.0 * (1.0 - t * 0.5), 255, 100.0 * t] }
  t = (l - 75.0) / 25.0
  return [127.0 * (1.0 - t), 255, 100.0 + 55.0 * t]
}

function backgroundTint(mode, stage) {
  if (mode === "Rainbow") return [15, 10, 20]
  if (mode === "Zen") return [10, 12, 10]
  if (mode === "Matrix") return [0, 5, 0]
  switch (stage) {
  case "Seed":
  case "Germination":
  case "Seedling": return [5, 10, 5]
  case "Vegetative": return [10, 20, 10]
  case "PreFlower": return [20, 20, 5]
  case "Flowering": return [15, 5, 20]
  default: return [25, 20, 5]
  }
}

// O nome do modo visual esta em I18n.js, nos dois idiomas - o ingles de la e
// `VisualMode::name` de src/ui/visual_mode.rs, que nunca foi deste arquivo.
// Aqui ficam as cores, que sao de colors.rs.

function nextMode(mode) {
  switch (mode) {
  case "Normal": return "Zen"
  case "Zen": return "Rainbow"
  case "Rainbow": return "Matrix"
  default: return "Normal"
  }
}

// ---- os nomes de ANSI que o TUI usava --------------------------------------
// Nome de cor ANSI nao carrega RGB: quem escolhe e o terminal, e por isso a
// mesma planta muda de tom entre dois temas. Aqui tem que haver um numero. Os
// tres primeiros sao os que tocam a planta e foram escolhidos dentro da paleta
// do proprio Ganja; o resto e dos medidores.
var ANSI = {
  green: [80, 180, 80],        // Color::Green - caule de muda (= foliage variante 1)
  darkGray: [90, 90, 90],      // Color::DarkGray - germinacao
  yellow: [255, 220, 100],     // Color::Yellow - primeiros calices (= flor dourada)

  // A cor de "sem estilo". No TUI o caractere que nao cai em nenhum ramo do
  // match sai como Span::raw, ou seja no primeiro plano padrao do terminal - e
  // aparece. Na arte isso e o `.`, que e um quadro do pulsar dos botoes e dois
  // dos doze quadros da floracao. Sem esta cor os botoes somem por um sexto do
  // tempo e a planta pisca sem motivo aparente.
  defaultFg: [168, 176, 166],

  gaugeGreen: [76, 201, 108],
  gaugeYellow: [224, 194, 74],
  gaugeRed: [224, 90, 79],
  gaugeLightRed: [240, 121, 110],
  gaugeCyan: [76, 201, 214],
  gaugeMagenta: [199, 125, 216],
  gaugeBlue: [108, 156, 232]
}

// ---- colorizacao caractere a caractere --------------------------------------
// A tabela de growing.rs: cada caractere da arte vira uma cor conforme o que
// ele representa. Devolve null para "sem cor" (espaco e o resto).
function charColor(ch, stage, colors) {
  switch (ch) {
  case "|": case "!": case "I": case "║":
    return colors.trunk
  case "/": case "\\": case "_": case "=":
    if (stage === "Seed" || stage === "Germination") return ANSI.darkGray
    if (stage === "Seedling") return ANSI.green
    return colors.foliage
  case "*":
    if (stage === "Flowering") return colors.flower1
    if (stage === "ReadyToHarvest") return colors.flower3
    return colors.foliage
  case "o":
    if (stage === "PreFlower") return ANSI.yellow
    if (stage === "Flowering") return colors.flower1
    if (stage === "ReadyToHarvest") return colors.flower3
    return colors.foliage
  case "O":
    if (stage === "Flowering") return colors.flower2
    if (stage === "ReadyToHarvest") return colors.flower3
    return colors.foliage
  case "@": case "#":
    if (stage === "Flowering") return colors.flower2
    if (stage === "ReadyToHarvest") return colors.flower3
    return colors.foliage
  case ":":
    return colors.foliage
  case "~":
    return colors.soil
  case " ":
    return null
  default:
    return ANSI.defaultFg
  }
}

// As intensidades de flor por dia (growing.rs): 49-60 cedo, 61-70 em
// desenvolvimento, 71-85 pico, 86+ colheita.
function flowerIntensities(stage, day) {
  if (stage === "Flowering") {
    if (day < 61) return ["Early", "Early", "Developing"]
    if (day < 71) return ["Developing", "Developing", "Peak"]
    return ["Peak", "Peak", "Peak"]
  }
  if (stage === "ReadyToHarvest") return ["Harvest", "Harvest", "Harvest"]
  return ["Early", "Early", "Early"]
}

function healthPercent(health) {
  switch (health) {
  case "Excellent": return 100.0
  case "Good": return 80.0
  case "Fair": return 60.0
  case "Poor": return 40.0
  default: return 20.0
  }
}
