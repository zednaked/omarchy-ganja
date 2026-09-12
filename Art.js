.pragma library

// Porta de src/ascii/art.rs do Ganja-TUI.
//
// Isto e uma traducao, nao uma reimplementacao. Cada funcao aqui corresponde a
// uma funcao de la, na mesma ordem, com os mesmos numeros magicos - inclusive os
// que parecem errados (ver `foliage`, que so pinta o quadrante superior
// esquerdo porque sobrou da versao 35x14 da arte). Mudar qualquer um deles muda
// a planta, e a planta e o produto.
//
// Duas coisas exigem cuidado e sao a razao de metade do codigo abaixo:
//
// 1. `SimpleRng` e um LCG de 64 bits. O motor de JS do QML (V4) **nao tem
//    BigInt** - nem o literal `1n` (erro de sintaxe: o parse do arquivo inteiro
//    falha) nem a funcao `BigInt()` (ReferenceError). Conferido nesta maquina,
//    Qt 6.11. Entao o estado de 64 bits e mantido em quatro limbs de 16 bits e a
//    multiplicacao e feita a mao. `Number` sozinho nao serve: lo * 1103515245
//    passa de 2^53 e perde bits baixos em silencio, que e exatamente o tipo de
//    divergencia que so aparece na quinquagesima planta.
//
// 2. O Rust calcula em `f32` e o JS em `f64`. Onde o resultado vira inteiro
//    (`as u32`, `.ceil()`) ou cruza um limiar (`> 0.5`, `> 0.6`), um bit de
//    diferenca muda um caractere. Por isso todo passo aritmetico que era f32 la
//    passa por `f32()` aqui - Math.fround, arredondamento para precisao simples.

function f32(x) { return Math.fround(x) }

// ---- u64 em quatro limbs de 16 bits ----------------------------------------
// [l0, l1, l2, l3], l0 = bits 0-15. Little-endian, como a maquina.

function u64FromHex(hex) {
  var h = String(hex).replace(/[^0-9a-fA-F]/g, "")
  if (h.length > 16) h = h.substring(h.length - 16)   // u128 as u64: 64 bits baixos
  while (h.length < 16) h = "0" + h
  return [
    parseInt(h.substring(12, 16), 16),
    parseInt(h.substring(8, 12), 16),
    parseInt(h.substring(4, 8), 16),
    parseInt(h.substring(0, 4), 16)
  ]
}

function u64ToHex(s) {
  var out = ""
  for (var i = 3; i >= 0; i--) {
    var p = s[i].toString(16)
    while (p.length < 4) p = "0" + p
    out += p
  }
  return out
}

// Divisao inteira por um divisor pequeno (<= 65535), como u64 / d.
// Devolve { q: limbs, r: resto }. Usada pelas variantes de cor, que em
// growing.rs sao `seed % 6`, `(seed / 6) % 4` e `(seed / 24) % 3`.
function u64DivModSmall(s, d) {
  var q = [0, 0, 0, 0]
  var rem = 0
  for (var i = 3; i >= 0; i--) {
    var cur = rem * 65536 + s[i]
    q[i] = Math.floor(cur / d)
    rem = cur % d
  }
  return { q: q, r: rem }
}

function u64ModSmall(s, d) { return u64DivModSmall(s, d).r }

// ---- SimpleRng --------------------------------------------------------------
// impl SimpleRng { fn new(seed) { state: seed.wrapping_add(1) }
//                  fn next()   { state = state * 1103515245 + 12345;
//                                (state / 65536) % 32768 } }
//
// 1103515245 = 0x41C64E6D -> m0 = 0x4E6D, m1 = 0x41C6.
var RNG_M0 = 0x4E6D
var RNG_M1 = 0x41C6

function SimpleRng(seedLimbs) {
  this.s = [seedLimbs[0], seedLimbs[1], seedLimbs[2], seedLimbs[3]]
  // wrapping_add(1)
  var c = this.s[0] + 1
  this.s[0] = c % 65536; c = Math.floor(c / 65536)
  c += this.s[1]; this.s[1] = c % 65536; c = Math.floor(c / 65536)
  c += this.s[2]; this.s[2] = c % 65536; c = Math.floor(c / 65536)
  c += this.s[3]; this.s[3] = c % 65536
}

// state * M + 12345, mod 2^64. Cada produto parcial cabe em 2^32; as somas
// parciais ficam abaixo de 2^34, muito abaixo do limite exato de 2^53.
SimpleRng.prototype.next = function () {
  var a0 = this.s[0], a1 = this.s[1], a2 = this.s[2], a3 = this.s[3]

  var p0 = a0 * RNG_M0
  var p1 = a0 * RNG_M1 + a1 * RNG_M0
  var p2 = a1 * RNG_M1 + a2 * RNG_M0
  var p3 = a2 * RNG_M1 + a3 * RNG_M0
  // a3 * RNG_M1 cairia no limb 4: descartado pelo mod 2^64, como o wrapping_mul.

  var c = p0 + 12345
  var r0 = c % 65536; c = Math.floor(c / 65536)
  c += p1; var r1 = c % 65536; c = Math.floor(c / 65536)
  c += p2; var r2 = c % 65536; c = Math.floor(c / 65536)
  c += p3; var r3 = c % 65536

  this.s[0] = r0; this.s[1] = r1; this.s[2] = r2; this.s[3] = r3

  // (state / 65536) % 32768 -> bits 16..30, que e o limb 1 sem o bit alto.
  return r1 % 32768
}

// ---- estagios ---------------------------------------------------------------

var STAGES = ["Seed", "Germination", "Seedling", "Vegetative", "PreFlower", "Flowering", "ReadyToHarvest"]

// O rotulo do estagio nao mora mais aqui: virou texto de tela, e texto de tela
// mora em I18n.js, nos dois idiomas. As frases em ingles de la continuam sendo
// `GrowthStage::display_name` de src/domain/plant.rs, caractere por caractere -
// e este arquivo e porte de art.rs, que nunca foi o lugar de uma string de
// plant.rs.

// ---- PlantStructure ---------------------------------------------------------

var PHENO_TALL = 0, PHENO_BUSHY = 1, PHENO_BALANCED = 2

// Cache por seed, como o lazy_static PLANT_CACHE do Rust. Gerar de novo custa
// algumas centenas de multiplicacoes de 64 bits e acontece a cada frame se
// ninguem guardar.
var _cache = {}

function structureFor(seedLimbs) {
  var key = u64ToHex(seedLimbs)
  var hit = _cache[key]
  if (hit) return hit
  var made = generateStructure(seedLimbs)
  _cache[key] = made
  return made
}

function generateStructure(seedLimbs) {
  var rng = new SimpleRng(seedLimbs)

  var phenotype = rng.next() % 3   // 0 Tall, 1 Bushy, _ Balanced

  var branchDensity, foliageDensity, maxHeight, growthRate
  if (phenotype === PHENO_TALL) {
    branchDensity = f32(0.6); foliageDensity = f32(0.4)
    maxHeight = 20 + (rng.next() % 5); growthRate = f32(0.25)
  } else if (phenotype === PHENO_BUSHY) {
    branchDensity = f32(1.0); foliageDensity = f32(0.9)
    maxHeight = 12 + (rng.next() % 5); growthRate = f32(0.22)
  } else {
    branchDensity = f32(0.8); foliageDensity = f32(0.7)
    maxHeight = 16 + (rng.next() % 5); growthRate = f32(0.23)
  }

  var numPrimary
  if (phenotype === PHENO_TALL) numPrimary = 15 + (rng.next() % 10)
  else if (phenotype === PHENO_BUSHY) numPrimary = 25 + (rng.next() % 15)
  else numPrimary = 20 + (rng.next() % 12)

  var branches = []
  var i

  for (i = 0; i < numPrimary; i++) {
    var level
    if (phenotype === PHENO_TALL) level = 1 + (rng.next() % (maxHeight - 1))
    else level = 2 + (rng.next() % Math.max(maxHeight - 2, 1))

    var daysPerLevel = phenotype === PHENO_TALL ? f32(1.2)
      : (phenotype === PHENO_BUSHY ? f32(0.8) : f32(1.0))

    var levelDay = 4 + Math.trunc(f32((maxHeight - level) * daysPerLevel))
    var growthStartDay = levelDay + (rng.next() % 3)

    var direction = (rng.next() % 2 === 0) ? -1 : 1

    var maxLength
    if (phenotype === PHENO_TALL) maxLength = 6 + (rng.next() % 8)
    else if (phenotype === PHENO_BUSHY) maxLength = 8 + (rng.next() % 6)
    else maxLength = 6 + (rng.next() % 8)

    var thickness
    if (phenotype === PHENO_TALL) thickness = 1
    else if (phenotype === PHENO_BUSHY) thickness = (rng.next() % 2 === 0) ? 2 : 1
    else thickness = (rng.next() % 3 === 0) ? 2 : 1

    var curve = 0
    if (rng.next() % 3 === 0) curve = (rng.next() % 2 === 0) ? -1 : 1

    var canBifurcate = (rng.next() % 3 === 0)
    var bifurcationDay = canBifurcate ? growthStartDay + 8 + (rng.next() % 8) : 999

    branches.push({
      level: level, direction: direction, growthStartDay: growthStartDay,
      maxLength: maxLength, thickness: thickness, isSecondary: false,
      parentIndex: -1, curve: curve,
      canBifurcate: canBifurcate, bifurcationDay: bifurcationDay
    })
  }

  var numSecondary
  if (phenotype === PHENO_TALL) numSecondary = Math.trunc(f32(numPrimary * f32(0.5)))
  else if (phenotype === PHENO_BUSHY) numSecondary = Math.trunc(f32(numPrimary * f32(0.8)))
  else numSecondary = Math.trunc(f32(numPrimary * f32(0.6)))

  var primaryCount = branches.length
  for (i = 0; i < numSecondary; i++) {
    var parentIdx = rng.next() % primaryCount
    var parent = branches[parentIdx]

    var sGrowthStart = parent.growthStartDay + 5 + (rng.next() % 5)
    var levelOffset = (rng.next() % 3) - 1
    var sLevel = Math.min(Math.max(parent.level + levelOffset, 1), maxHeight - 1)
    var sDirection = (rng.next() % 3 === 0) ? parent.direction : -parent.direction
    var sMaxLength = 4 + (rng.next() % 6)

    var sCurve = 0
    if (rng.next() % 2 === 0) sCurve = (rng.next() % 2 === 0) ? -1 : 1

    var sCanBifurcate = (rng.next() % 5 === 0)
    var sBifurcationDay = sCanBifurcate ? sGrowthStart + 10 + (rng.next() % 8) : 999

    branches.push({
      level: sLevel, direction: sDirection, growthStartDay: sGrowthStart,
      maxLength: sMaxLength, thickness: 1, isSecondary: true,
      parentIndex: parentIdx, curve: sCurve,
      canBifurcate: sCanBifurcate, bifurcationDay: sBifurcationDay
    })
  }

  var trunkSplits = []
  var numSplits
  if (phenotype === PHENO_TALL) numSplits = (rng.next() % 3 === 0) ? 1 : 0
  else if (phenotype === PHENO_BUSHY) numSplits = (rng.next() % 2 === 0) ? 1 : 2
  else numSplits = (rng.next() % 4 === 0) ? 1 : 0

  for (i = 0; i < numSplits; i++) {
    trunkSplits.push({
      splitDay: 20 + (rng.next() % 30),
      splitLevel: 4 + (rng.next() % 4),
      angle: (rng.next() % 5) - 2
    })
  }

  return {
    branches: branches,
    seed: seedLimbs.slice(),
    phenotype: phenotype,
    branchDensity: branchDensity,
    foliageDensity: foliageDensity,
    trunkSplits: trunkSplits,
    maxHeight: maxHeight,
    growthRate: growthRate
  }
}

function trunkHeight(structure, day) {
  return Math.min(Math.trunc(f32(day * structure.growthRate)), structure.maxHeight)
}

function branchLength(branch, day) {
  if (day < branch.growthStartDay) return 0.0
  var daysGrowing = f32(day - branch.growthStartDay)
  var totalDays = f32(branch.maxLength * f32(3.0))
  var progress = Math.min(f32(daysGrowing / totalDays), 1.0)
  var e = f32(Math.exp(f32(f32(-8.0) * f32(progress - f32(0.5)))))
  var sigmoid = f32(f32(1.0) / f32(f32(1.0) + e))
  return f32(branch.maxLength * sigmoid)
}

function currentFoliageDensity(structure, day) {
  var progress = Math.min(f32(day / f32(90.0)), 1.0)
  return f32(structure.foliageDensity * progress)
}

// ---- render -----------------------------------------------------------------

function trunkCharFor(stage, frame) {
  switch (stage) {
  case "Seed":
  case "Germination":
  case "Seedling":
    return ["|", "!"][frame % 2]
  case "Vegetative":
    return ["|", "!", "I"][frame % 3]
  case "PreFlower":
  case "Flowering":
    return ["|", "!", "I", "║"][frame % 4]
  default:
    return ["I", "║"][frame % 2]
  }
}

// get_plant_ascii(): devolve 28 strings de exatamente 70 caracteres.
function plantAscii(stage, day, seedLimbs, frame) {
  var structure = structureFor(seedLimbs)
  switch (stage) {
  case "PreFlower":
    return renderPlantStructure(day, structure, frame, true, [".", "*", ".", " ", ".", "*", ".", " "][frame % 8], stage)
  case "Flowering":
    return renderPlantStructure(day, structure, frame, true, ["o", "o", "O", "O", "@", "@", "O", "O", "o", "o", ".", "."][frame % 12], stage)
  case "ReadyToHarvest":
    return renderPlantStructure(day, structure, frame, true, ["@", "#", "@", "*", "#", "@", "*", "#"][frame % 8], stage)
  default:
    return renderPlantStructure(day, structure, frame, false, "", stage)
  }
}

function renderPlantStructure(day, structure, frame, showFlowers, flowerChar, stage) {
  var lines = []
  var r, c
  for (r = 0; r < 28; r++) {
    var row = new Array(70)
    for (c = 0; c < 70; c++) row[c] = " "
    lines.push(row)
  }

  var trunk = trunkCharFor(stage, frame)
  var center = 35
  var currentTrunkHeight = trunkHeight(structure, day)
  var trunkStartLevel = Math.max(27 - currentTrunkHeight, 0)

  var activeSplits = []
  var i
  for (i = 0; i < structure.trunkSplits.length; i++)
    if (structure.trunkSplits[i].splitDay <= day) activeSplits.push(structure.trunkSplits[i])

  var splitFound = false
  var splitLevelFound = 0

  for (var level = trunkStartLevel; level <= 27; level++) {
    var splitHere = null
    for (i = 0; i < activeSplits.length; i++)
      if (activeSplits[i].splitLevel === (27 - level)) { splitHere = activeSplits[i]; break }

    if (splitHere !== null) {
      if (!splitFound) {
        lines[level][center] = trunk

        var left = center - Math.abs(splitHere.angle)
        var right = center + Math.abs(splitHere.angle)

        if (left < 70 && level > 0) lines[level - 1][left] = splitHere.angle < 0 ? "\\" : "/"
        if (right < 70 && level > 0) lines[level - 1][right] = splitHere.angle > 0 ? "/" : "\\"

        if (level >= 2) {
          for (var up = level - 2; up >= trunkStartLevel; up--) {
            if (left < 70) lines[up][left] = trunk
            if (right < 70) lines[up][right] = trunk
          }
        }

        splitFound = true
        splitLevelFound = level
      }
    } else if (!splitFound || level > splitLevelFound) {
      lines[level][center] = trunk
    }
  }

  var foliageDensity = currentFoliageDensity(structure, day)

  for (var b = 0; b < structure.branches.length; b++) {
    var branch = structure.branches[b]
    if (branch.growthStartDay > day) continue          // visible_branches()

    var blevel = 27 - branch.level
    if (blevel >= 27) continue
    if (branch.level > currentTrunkHeight) continue

    var currentLength = branchLength(branch, day)
    if (currentLength < 0.5) continue
    var lengthInt = Math.ceil(currentLength)

    var isBifurcating = branch.canBifurcate && day >= branch.bifurcationDay

    for (i = 1; i <= lengthInt; i++) {
      var xPos = center + i * branch.direction
      var yPos = blevel

      if (branch.curve !== 0 && i > 2) {
        var curveAmount = Math.trunc((i - 2) / 2) * branch.curve
        yPos = Math.min(Math.max(yPos - curveAmount, 0), 27)
      }

      if (xPos < 0 || xPos >= 70 || yPos < 0 || yPos >= 28) break

      var ch
      if (i === lengthInt && showFlowers) {
        ch = flowerChar.length > 0 ? flowerChar.charAt(0) : "*"
      } else if (i === 1) {
        ch = branch.direction < 0 ? "\\" : "/"
      } else if (i === lengthInt) {
        if (foliageDensity > 0.6) ch = branch.direction < 0 ? "\\" : "/"
        else ch = branch.direction < 0 ? "/" : "\\"
      } else if (branch.curve !== 0 && i > 2) {
        ch = branch.curve > 0 ? "/" : "\\"
      } else {
        ch = branch.thickness === 2 ? "=" : (branch.thickness === 3 ? "#" : "_")
      }

      if (lines[yPos][xPos] === " ") lines[yPos][xPos] = ch
    }

    // Densidade de folhagem. O teste `< 34` e `< 14` e da versao 35x14 da arte:
    // na 70x28 ele so cobre o quadrante superior esquerdo. Esta portado como
    // esta la de proposito - a planta que o Ganja-TUI desenha e esta.
    if (foliageDensity > 0.5 && lengthInt >= 3 && blevel > 0) {
      for (var offset = 1; offset <= 2; offset++) {
        var fx = center + (lengthInt - offset) * branch.direction
        var fy = blevel - 1
        if (fx > 0 && fx < 34 && fy < 14) {
          if (lines[fy][fx] === " " && foliageDensity > 0.6)
            lines[fy][fx] = showFlowers ? (offset === 1 ? "*" : ".") : ":"
        }
      }
    }

    if (isBifurcating && lengthInt >= 3) {
      var splitPoint = Math.max(Math.trunc(lengthInt * 2 / 3), 2)
      var dirs = [-1, 1]
      for (var d = 0; d < 2; d++) {
        var subDir = dirs[d]
        for (i = 1; i <= 2; i++) {
          var baseX = center + splitPoint * branch.direction
          var sx = baseX + i * subDir
          var sy = blevel - Math.trunc(i / 2)
          if (sx >= 0 && sx < 70 && sy >= 0 && sy < 28) {
            var sch
            if (i === 2 && showFlowers) sch = flowerChar.length > 0 ? flowerChar.charAt(0) : "*"
            else sch = subDir < 0 ? "\\" : "/"
            if (lines[sy][sx] === " ") lines[sy][sx] = sch
          }
        }
      }
    }
  }

  // Linha de terra, por cima de tudo - inclusive da base do tronco, como no TUI.
  var soil = "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  for (i = 0; i < soil.length; i++) {
    var x = 16 + i
    if (x < 70) lines[27][x] = soil.charAt(i)
  }

  var out = []
  for (r = 0; r < 28; r++) out.push(lines[r].join(""))
  return out
}

// ---- decoracoes animadas ----------------------------------------------------

function borderDecoration(frame) { return ["~", "~", "-", "-"][frame % 4] }
function waterDrops(frame) { return [".", "o", ".", "O", ".", "o", ".", " "][frame % 8] }
function nutrientSparkles(frame) { return ["*", "+", "*", "x", "*", "+", "*", "X", "*", "x", "*", " "][frame % 12] }
