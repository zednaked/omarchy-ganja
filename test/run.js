#!/usr/bin/env node
// Roda Art.js fora do QML.
//
// Serve para tres coisas:
//   node test/run.js check     confere o LCG de 64 bits contra BigInt do Node
//   node test/run.js gen       (re)grava test/frames/<seed>-<dia>.txt
//   node test/run.js diff      compara o que Art.js produz hoje com as fixtures
//   node test/run.js show S D  imprime um frame no terminal
//
// O `check` existe porque o motor do QML nao tem BigInt e a aritmetica de 64
// bits de Art.js e feita a mao: aqui, onde BigInt existe, da para provar que a
// conta a mao acerta. O `diff` vigia regressao nossa; a conferencia contra o
// Ganja-TUI de verdade e outro passo, descrito em test/README.md.

const fs = require("fs")
const path = require("path")

const DIR = path.join(__dirname, "..")
const FRAMES = path.join(__dirname, "frames")

function loadJs(file) {
  const src = fs.readFileSync(path.join(DIR, file), "utf8")
    .split("\n")
    .filter(l => !/^\s*\.(pragma|import)\b/.test(l))   // diretivas de QML nao sao JS
    .join("\n")
  const mod = {}
  new Function("exports", src + "\n;" + exportsOf(src))(mod)
  return mod
}

function exportsOf(src) {
  const names = []
  const re = /^function\s+([A-Za-z_$][\w$]*)/gm
  let m
  while ((m = re.exec(src)) !== null) names.push(m[1])
  const vars = /^var\s+([A-Za-z_$][\w$]*)\s*=/gm
  while ((m = vars.exec(src)) !== null) names.push(m[1])
  return names.map(n => `exports.${n} = ${n};`).join("\n")
}

const Art = loadJs("Art.js")

// ---- fixtures ---------------------------------------------------------------
// Oito seeds e oito dias, um por estagio e um por transicao. Os dias seguem os
// limiares de Plant::calculate_stage: 1-10 seedling, 11-40 veg, 41-48 preflower,
// 49-85 flowering, 86+ pronta.
const SEEDS = [
  "0000000000000001",
  "00000000deadbeef",
  "123456789abcdef0",
  "ffffffffffffffff",
  "0f1e2d3c4b5a6978",
  "a5a5a5a5a5a5a5a5",
  "00000000000f4240",
  "7fffffffffffffff"
]
const DAYS = [1, 5, 15, 30, 46, 53, 70, 90]

function stageFor(day) {
  if (day <= 10) return "Seedling"
  if (day <= 40) return "Vegetative"
  if (day <= 48) return "PreFlower"
  if (day <= 85) return "Flowering"
  return "ReadyToHarvest"
}

// Frame 0 sempre: a fixture compara estrutura, nao animacao. Os caracteres
// animados (tronco, flor) sao escolhidos por `frame % n` e um frame fixo torna
// o arquivo estavel sem esconder nada - a estrutura nao depende do frame.
function frameFor(seedHex, day) {
  return Art.plantAscii(stageFor(day), day, Art.u64FromHex(seedHex), 0)
}

function cmdGen() {
  fs.mkdirSync(FRAMES, { recursive: true })
  let n = 0
  for (const s of SEEDS) for (const d of DAYS) {
    const lines = frameFor(s, d)
    assertShape(lines, s, d)
    fs.writeFileSync(path.join(FRAMES, `${s}-${d}.txt`), lines.join("\n") + "\n")
    n++
  }
  console.log(`gravadas ${n} fixtures em test/frames/`)
}

function assertShape(lines, s, d) {
  if (lines.length !== 28) throw new Error(`${s}-${d}: ${lines.length} linhas, esperado 28`)
  for (const l of lines)
    if (l.length !== 70) throw new Error(`${s}-${d}: linha de ${l.length} chars, esperado 70`)
}

function cmdDiff() {
  let bad = 0, ok = 0
  for (const s of SEEDS) for (const d of DAYS) {
    const file = path.join(FRAMES, `${s}-${d}.txt`)
    if (!fs.existsSync(file)) { console.log(`FALTA  ${s}-${d}`); bad++; continue }
    const want = fs.readFileSync(file, "utf8").replace(/\n$/, "").split("\n")
    const got = frameFor(s, d)
    assertShape(got, s, d)
    let diffs = 0
    for (let i = 0; i < 28; i++)
      for (let c = 0; c < 70; c++)
        if (want[i][c] !== got[i][c]) diffs++
    if (diffs) { console.log(`DIFERE ${s}-${d}: ${diffs} caracteres`); bad++ }
    else ok++
  }
  console.log(bad ? `${ok} iguais, ${bad} com diferenca` : `${ok} frames iguais as fixtures`)
  process.exit(bad ? 1 : 0)
}

// ---- conferencia do RNG -----------------------------------------------------

function refRng(seedHex, count) {
  const M = 1103515245n, A = 12345n, MASK = (1n << 64n) - 1n
  let s = (BigInt("0x" + seedHex) + 1n) & MASK
  const out = []
  for (let i = 0; i < count; i++) {
    s = (s * M + A) & MASK
    out.push(Number((s / 65536n) % 32768n))
  }
  return out
}

function cmdCheck() {
  const seeds = SEEDS.concat([
    "ffffffffffffffff", "fffffffffffffffe", "8000000000000000",
    "0000000100000000", "ffff0000ffff0000", "0123456789abcdef"
  ])
  let bad = 0
  for (const s of seeds) {
    const want = refRng(s, 4000)
    const rng = new Art.SimpleRng(Art.u64FromHex(s))
    for (let i = 0; i < want.length; i++) {
      const got = rng.next()
      if (got !== want[i]) {
        console.log(`RNG DIVERGE seed=${s} passo=${i}: esperado ${want[i]}, obtido ${got}`)
        bad++
        break
      }
    }
  }

  // As variantes de cor de growing.rs sao divisoes de 64 bits: seed % 6,
  // (seed / 6) % 4, (seed / 24) % 3. Conferir tambem.
  for (const s of seeds) {
    const v = BigInt("0x" + s)
    const limbs = Art.u64FromHex(s)
    const pairs = [
      [Number(v % 6n), Art.u64ModSmall(limbs, 6)],
      [Number((v / 6n) % 4n), Art.u64ModSmall(Art.u64DivModSmall(limbs, 6).q, 4)],
      [Number((v / 24n) % 3n), Art.u64ModSmall(Art.u64DivModSmall(limbs, 24).q, 3)]
    ]
    for (const [want, got] of pairs)
      if (want !== got) { console.log(`DIV DIVERGE seed=${s}: ${want} != ${got}`); bad++ }
  }

  if (bad) { console.log(`${bad} divergencias`); process.exit(1) }
  console.log(`LCG e divisoes de 64 bits conferem com BigInt em ${seeds.length} seeds (4000 passos cada)`)
}

function cmdShow(seedHex, day, frame) {
  const lines = Art.plantAscii(stageFor(day), day, Art.u64FromHex(seedHex), frame | 0)
  console.log(`seed ${seedHex} · dia ${day} · ${stageFor(day)} · frame ${frame | 0}`)
  console.log("+" + "-".repeat(70) + "+")
  for (const l of lines) console.log("|" + l + "|")
  console.log("+" + "-".repeat(70) + "+")
}

const cmd = process.argv[2] || "diff"
if (cmd === "gen") cmdGen()
else if (cmd === "diff") cmdDiff()
else if (cmd === "check") cmdCheck()
else if (cmd === "show") cmdShow(process.argv[3] || SEEDS[1], parseInt(process.argv[4] || "53", 10), process.argv[5] || 0)
else { console.error("uso: run.js [check|gen|diff|show SEED DIA [FRAME]]"); process.exit(2) }
