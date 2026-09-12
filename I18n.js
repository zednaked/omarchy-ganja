.pragma library

// Todo o texto que aparece na tela, nos dois idiomas.
//
// Antes disto a interface era portugues com os dados em ingles: o rodape dizia
// "w rega  ·  n alimenta" e o painel ao lado dizia "difficulty Easy   yield
// High". Nenhum dos dois estava errado sozinho; juntos liam como tradução pela
// metade, que e pior que qualquer das duas escolhas inteiras.
//
// Regras que isto segue:
//
// 1. **A chave nunca e o texto.** `t()` devolve a propria chave quando ela nao
//    existe em nenhum dos dois idiomas - uma string faltando aparece na tela
//    como `msg.watered` e alguem conserta. Devolver vazio esconderia.
//
// 2. **O ingles aqui e o do Ganja-TUI, onde o TUI tem a palavra.** Os nomes de
//    estagio (`stage.*`) sao `GrowthStage::display_name` de src/domain/plant.rs
//    e os nomes de modo visual (`mode.*`) sao `VisualMode::name` de
//    src/ui/visual_mode.rs, caractere por caractere. Eles moravam em Art.js e
//    em Palette.js, que sao portes de art.rs e colors.rs - ou seja, no arquivo
//    errado. Estao aqui porque aqui e onde texto mora, e continuam batendo com
//    a origem.
//
// 3. **O que o save guarda e o id, nunca o rotulo.** `windowMode` e "full", o
//    visual e "Zen", o estagio e "PreFlower". Gravar "médio" no save faria o
//    arquivo trocar de forma junto com o idioma, e um save escrito em
//    portugues nao abriria em ingles.
//
// 4. **Dado do strain se traduz por campo, nao por palavra.** "Medium" e
//    dificuldade media e rendimento medio, e as duas palavras sao diferentes em
//    portugues. Um dicionario plano de palavra para palavra erra o genero em
//    metade dos casos; `term(lang, campo, valor)` nao tem como errar.

var LANGS = ["en", "pt"]

function langName(lang) { return lang === "pt" ? "português" : "English" }

function nextLang(lang) { return lang === "pt" ? "en" : "pt" }

function known(lang) { return LANGS.indexOf(lang) >= 0 }

// O idioma que o sistema pede, para a primeira carga - quem instalou o plugin
// numa maquina em pt_BR nao deveria ter que descobrir a tecla `l` para ler a
// propria lingua. Depois disso manda o save: a escolha explicita vale mais que
// a variavel de ambiente.
function fromLocale(name) {
  return String(name || "").toLowerCase().indexOf("pt") === 0 ? "pt" : "en"
}

var STRINGS = {

  // ---- ingles --------------------------------------------------------------
  en: {
    // estagios - GrowthStage::display_name (src/domain/plant.rs:22)
    "stage.Seed": "Seed",
    "stage.Germination": "Germination",
    "stage.Seedling": "Seedling",
    "stage.Vegetative": "Vegetative",
    "stage.PreFlower": "Pre-Flower",
    "stage.Flowering": "Flowering",
    "stage.ReadyToHarvest": "Ready to Harvest",

    // modos visuais - VisualMode::name (src/ui/visual_mode.rs:28)
    "mode.Normal": "Normal",
    "mode.Zen": "Zen Garden",
    "mode.Rainbow": "Rainbow",
    "mode.Matrix": "Matrix",

    // tamanhos de janela
    "win.full": "full",
    "win.large": "large",
    "win.medium": "medium",
    "win.small": "small",
    "win.window": "window",

    // barra
    "bar.line": "{0} · {1} · day {2}",
    "bar.paused": "paused · right-click to resume",
    "bar.ready": "ready to harvest",
    "bar.auto": "automatic",
    "bar.thirsty": "thirsty ({0}%)",
    "bar.hungry": "out of NPK ({0}%)",

    // cabecalho e estado
    "room.day": "day {0}",
    "room.auto": "AUTO",
    "room.turboTag": "·· TURBO 130000x ··",
    "room.demoTag": "·· demo 130000x ··",
    "room.pausedTag": "·· STOPPED ··",
    "room.demoMeaning": "none of this counts",
    "room.pausedMeaning": "frozen · p starts it again",
    "room.readyStatus": "ready to harvest · h",
    "room.autoStatus": "automatic · the plant looks after itself",

    // titulos de bloco
    "room.plant": "[ plant ]",
    "room.strain": "[ strain ]",

    // medidores
    "m.water": "water",
    "m.npk": "npk",
    "m.next": "→ {0}",
    "m.temperature": "temperature",
    "m.humidity": "humidity",
    "m.rootCanopy": "root / canopy",
    "m.rootCanopyValue": "R{0} / C{1}",
    "m.health": "health",

    // proximo estagio
    "next.vegetative": "vegetative",
    "next.preflower": "pre-flower",
    "next.flowering": "flowering",
    "next.harvest": "harvest",
    "next.ready": "ready",
    "next.cut": "cut it",

    // saude
    "health.Excellent": "excellent ★",
    "health.Good": "good",
    "health.Fair": "fair",
    "health.Poor": "poor ⚠",
    "health.Critical": "critical ⚠⚠",

    // painel do strain
    "s.genetics": "genetics",
    "s.cannabinoids": "cannabinoids",
    "s.cannabinoidsValue": "THC {0}%   CBD {1}%",
    "s.growing": "growing",
    "s.growingValue": "difficulty {0}   yield {1}",
    "s.flowering": "flowering",
    "s.floweringValue": "{0} days   ·   height {1}   ·   {2}",
    "s.terpenes": "terpenes",
    "s.aroma": "aroma",
    "s.effects": "effects",
    "s.resilience": "resilience",
    "s.resilienceValue": "{0}%   ·   growth {1}x",
    "s.seed": "seed",

    // aba de colheitas
    "h.none": "no harvests yet",
    "h.countOne": "{0} harvest",
    "h.countMany": "{0} harvests",
    "h.totals": "{0} g in total  ·  average quality {1}%  ·  THC {2}%  CBD {3}%",
    "h.empty": "The plant harvests itself ten days after it is ready, and replants on the spot.\n"
      + "What stays is this list: strain, day, weight, quality and how many scares the plant took.\n\n"
      + "It is what separates a pretty plant from something that accumulates - the tenth harvest\n"
      + "has ten stories behind it.",
    "h.dateFormat": "MM/dd HH:mm",
    "h.day": "day {0}  ·  {1}",
    "h.grams": "{0} g",
    "h.quality": "{0}% quality",
    "h.cannabinoids": "THC {0}%  CBD {1}%",
    "h.records": "record {0} g ({1})  ·  best quality {2}% ({3})",
    "h.since": "since {0}",
    "h.showingLast": "the {0} most recent, of {1}",
    "h.noStress": "no scares",
    "h.stressOne": "{0} scare",
    "h.stressMany": "{0} scares",

    // rodape
    "f.harvests": "tab goes back to the plant  ·  esc closes",
    "f.hints": "w water  ·  n feed  ·  a automatic  ·  h harvest  ·  v colors  ·  t size  ·  "
      + "p stop  ·  l idioma  ·  f demo  ·  shift+f TURBO  ·  tab harvests  ·  esc close",
    "f.hintsShort": "w water · n feed · a auto · v colors · t size · p stop · l idioma · f demo · tab · esc",
    "f.credit": "ZeD's Ganja-TUI, ported to the Omarchy shell",
    "f.creditShort": "ZeD's Ganja-TUI",

    // recados
    "msg.watered": "watered · {0}%",
    "msg.fed": "fed · {0}%",
    "msg.autoOn": "automatic on · the plant looks after itself",
    "msg.autoOff": "automatic off · it is on you now",
    "msg.harvested": "harvested - a new seedling is in the pot",
    "msg.notReady": "not ready yet",
    "msg.window": "window: {0}",
    "msg.turboOn": "TURBO · 130000x on the real plant",
    "msg.turboOff": "turbo off · back to the slow rhythm",
    "msg.demoOn": "demo · 130000x on a copy",
    "msg.demoOff": "demo off",
    "msg.paused": "stopped · the plant is frozen and the plugin costs nothing",
    "msg.resumed": "running · the clock is moving again",
    "msg.lang": "language: English",

    // IPC
    "ipc.status": "{0} · {1} · day {2} · water {3}% · npk {4}%",
    "ipc.harvested": "harvested",
    "ipc.notReady": "not ready yet",
    "ipc.on": "on",
    "ipc.off": "off",
    "ipc.turboOn": "on · 130000x on the plant",
    "ipc.paused": "stopped",
    "ipc.running": "running",
    "ipc.cycle": "a full cycle in {0} h of session",
    "ipc.sizes": "sizes: {0}",
    "ipc.languages": "languages: {0}"
  },

  // ---- portugues -----------------------------------------------------------
  pt: {
    "stage.Seed": "Semente",
    "stage.Germination": "Germinação",
    "stage.Seedling": "Muda",
    "stage.Vegetative": "Vegetativo",
    "stage.PreFlower": "Pré-flor",
    "stage.Flowering": "Floração",
    "stage.ReadyToHarvest": "Pronta para colher",

    "mode.Normal": "Normal",
    "mode.Zen": "Jardim Zen",
    "mode.Rainbow": "Arco-íris",
    "mode.Matrix": "Matrix",

    "win.full": "cheio",
    "win.large": "grande",
    "win.medium": "médio",
    "win.small": "pequeno",
    "win.window": "janela",

    "bar.line": "{0} · {1} · dia {2}",
    "bar.paused": "parada · clique direito retoma",
    "bar.ready": "pronta para colher",
    "bar.auto": "automático",
    "bar.thirsty": "com sede ({0}%)",
    "bar.hungry": "sem NPK ({0}%)",

    "room.day": "dia {0}",
    "room.auto": "AUTO",
    "room.turboTag": "·· TURBO 130000x ··",
    "room.demoTag": "·· demonstração 130000x ··",
    "room.pausedTag": "·· PARADA ··",
    "room.demoMeaning": "nada disto conta",
    "room.pausedMeaning": "congelada · p faz voltar a andar",
    "room.readyStatus": "pronta para colher · h",
    "room.autoStatus": "automático · a planta se cuida",

    "room.plant": "[ planta ]",
    "room.strain": "[ strain ]",

    "m.water": "água",
    "m.npk": "npk",
    "m.next": "→ {0}",
    "m.temperature": "temperatura",
    "m.humidity": "umidade",
    "m.rootCanopy": "raiz / copa",
    "m.rootCanopyValue": "R{0} / C{1}",
    "m.health": "saúde",

    "next.vegetative": "vegetativo",
    "next.preflower": "pré-flor",
    "next.flowering": "floração",
    "next.harvest": "colheita",
    "next.ready": "pronta",
    "next.cut": "colher",

    "health.Excellent": "excelente ★",
    "health.Good": "boa",
    "health.Fair": "razoável",
    "health.Poor": "ruim ⚠",
    "health.Critical": "crítica ⚠⚠",

    "s.genetics": "genética",
    "s.cannabinoids": "canabinoides",
    "s.cannabinoidsValue": "THC {0}%   CBD {1}%",
    "s.growing": "cultivo",
    "s.growingValue": "dificuldade {0}   rendimento {1}",
    "s.flowering": "floração",
    "s.floweringValue": "{0} dias   ·   porte {1}   ·   {2}",
    "s.terpenes": "terpenos",
    "s.aroma": "aroma",
    "s.effects": "efeitos",
    "s.resilience": "resiliência",
    "s.resilienceValue": "{0}%   ·   crescimento {1}x",
    "s.seed": "seed",

    "h.none": "nenhuma colheita ainda",
    "h.countOne": "{0} colheita",
    "h.countMany": "{0} colheitas",
    "h.totals": "{0} g no total  ·  qualidade média {1}%  ·  THC {2}%  CBD {3}%",
    "h.empty": "A planta colhe sozinha dez dias depois de ficar pronta, e replanta na hora.\n"
      + "O que fica é esta lista: strain, dia, peso, qualidade e quantos sustos a planta levou.\n\n"
      + "É o que separa uma planta bonita de uma coisa que acumula - a décima colheita\n"
      + "tem dez histórias atrás dela.",
    "h.dateFormat": "dd/MM HH:mm",
    "h.day": "dia {0}  ·  {1}",
    "h.grams": "{0} g",
    "h.quality": "{0}% qualidade",
    "h.cannabinoids": "THC {0}%  CBD {1}%",
    "h.records": "recorde {0} g ({1})  ·  melhor qualidade {2}% ({3})",
    "h.since": "desde {0}",
    "h.showingLast": "as {0} mais recentes, de {1}",
    "h.noStress": "sem sustos",
    "h.stressOne": "{0} susto",
    "h.stressMany": "{0} sustos",

    "f.harvests": "tab volta para a planta  ·  esc fecha",
    "f.hints": "w rega  ·  n alimenta  ·  a automático  ·  h colhe  ·  v cores  ·  t tamanho  ·  "
      + "p para  ·  l language  ·  f demonstração  ·  shift+f TURBO  ·  tab colheitas  ·  esc fecha",
    "f.hintsShort": "w rega · n alimenta · a auto · v cores · t tamanho · p para · l language · f demo · tab · esc",
    "f.credit": "Ganja-TUI de ZeD, portado para o shell do Omarchy",
    "f.creditShort": "Ganja-TUI de ZeD",

    "msg.watered": "regada · {0}%",
    "msg.fed": "alimentada · {0}%",
    "msg.autoOn": "automático ligado · a planta se cuida sozinha",
    "msg.autoOff": "automático desligado · agora é com você",
    "msg.harvested": "colhida - muda nova plantada",
    "msg.notReady": "ainda não está pronta",
    "msg.window": "janela: {0}",
    "msg.turboOn": "TURBO · 130000x na planta de verdade",
    "msg.turboOff": "turbo desligado · de volta ao ritmo lento",
    "msg.demoOn": "demonstração · 130000x numa cópia",
    "msg.demoOff": "demonstração desligada",
    "msg.paused": "parada · a planta congelou e o plugin não custa nada",
    "msg.resumed": "andando · o relógio voltou a correr",
    "msg.lang": "idioma: português",

    "ipc.status": "{0} · {1} · dia {2} · água {3}% · npk {4}%",
    "ipc.harvested": "colhida",
    "ipc.notReady": "ainda não está pronta",
    "ipc.on": "ligado",
    "ipc.off": "desligado",
    "ipc.turboOn": "ligado · 130000x na planta",
    "ipc.paused": "parada",
    "ipc.running": "andando",
    "ipc.cycle": "um ciclo completo em {0} h de sessão",
    "ipc.sizes": "tamanhos: {0}",
    "ipc.languages": "idiomas: {0}"
  }
}

// ---- vocabulario dos dados do strain ---------------------------------------
//
// Por campo, e nao por palavra: "Medium" e dificuldade **média** e rendimento
// **médio**. Em ingles a tabela nao existe - o dado de strains.json ja esta na
// lingua dele, e inventar uma traducao de ingles para ingles so criaria uma
// chance de divergir da origem.
var VOCAB = {
  pt: {
    type: { "Indica": "Indica", "Sativa": "Sativa", "Hybrid": "Híbrida" },

    difficulty: { "Easy": "fácil", "Medium": "média", "Hard": "difícil" },

    yield: { "Low": "baixo", "Medium": "médio", "High": "alto", "Very High": "muito alto" },

    // "porte" e masculino: porte baixo, porte médio, porte alto.
    height: { "Short": "baixo", "Medium": "médio", "Tall": "alto", "Balanced": "equilibrado" },

    // o fenotipo concorda com "planta": arbustiva, alta, equilibrada.
    phenotype: { "Bushy": "arbustiva", "Tall": "alta", "Short": "baixa", "Balanced": "equilibrada" },

    terpene: {
      "Myrcene": "mirceno", "Caryophyllene": "cariofileno", "Limonene": "limoneno",
      "Linalool": "linalol", "Pinene": "pineno", "Ocimene": "ocimeno",
      "Terpinolene": "terpinoleno", "Humulene": "humuleno"
    },

    aroma: {
      "Berry": "frutas vermelhas", "Blueberry": "mirtilo", "Candy": "bala",
      "Cedar": "cedro", "Citrus": "cítrico", "Diesel": "diesel", "Earthy": "terroso",
      "Floral": "floral", "Fruity": "frutado", "Grape": "uva", "Hash": "hash",
      "Herbal": "herbal", "Lavender": "lavanda", "Lemon": "limão", "Lime": "lima",
      "Mango": "manga", "Mint": "menta", "Orange": "laranja", "Pine": "pinho",
      "Pineapple": "abacaxi", "Pungent": "pungente", "Skunk": "skunk", "Sour": "ácido",
      "Spicy": "picante", "Strawberry": "morango", "Sweet": "doce", "Toffee": "caramelo",
      "Tropical": "tropical", "Vanilla": "baunilha", "Woody": "amadeirado"
    },

    effect: {
      "Balanced": "equilibrado", "Clear-headed": "lúcido", "Creative": "criativo",
      "Energetic": "energético", "Euphoric": "eufórico", "Focused": "focado",
      "Happy": "alegre", "Relaxed": "relaxado", "Relaxing": "relaxante",
      "Sleepy": "sonolento", "Uplifting": "estimulante"
    }
  }
}

// ---- as funcoes ------------------------------------------------------------

// A chave que falta aparece na tela como ela mesma. Uma string vazia seria
// silencio, e silencio nesta camada e exatamente o que nao se descobre.
function t(lang, key) {
  var table = STRINGS[lang] || STRINGS.en
  var s = table[key]
  if (s === undefined) s = STRINGS.en[key]
  return s === undefined ? key : s
}

function fmt(s, a, b, c, d, e) {
  var args = [a, b, c, d, e]
  return String(s).replace(/\{(\d)\}/g, function (m, i) {
    var v = args[Number(i)]
    return v === undefined || v === null ? "" : String(v)
  })
}

function tf(lang, key, a, b, c, d, e) { return fmt(t(lang, key), a, b, c, d, e) }

// Numero decimal com a virgula certa. Isto e a metade da localizacao que se
// esquece: "18.5%" numa interface em portugues e tao mesclado quanto
// "difficulty fácil".
function num(lang, value, digits) {
  var d = digits === undefined ? 1 : digits
  var s = Number(value).toFixed(d)
  return lang === "pt" ? s.replace(".", ",") : s
}

function stage(lang, name) { return t(lang, "stage." + name) }
function mode(lang, name) { return t(lang, "mode." + name) }
function health(lang, name) { return t(lang, "health." + name) }
function windowMode(lang, name) { return t(lang, "win." + name) }

function term(lang, field, value) {
  var byLang = VOCAB[lang]
  var table = byLang ? byLang[field] : null
  var out = table ? table[value] : undefined
  return out === undefined ? String(value === undefined || value === null ? "" : value) : out
}

function terms(lang, field, list) {
  if (!list || !list.length) return "—"
  var out = []
  for (var i = 0; i < list.length; i++) out.push(term(lang, field, list[i]))
  return out.join(", ")
}

// Plural de duas formas, que e o que estes dois idiomas pedem aqui.
function plural(lang, n, keyOne, keyMany) {
  return tf(lang, Math.abs(n) === 1 ? keyOne : keyMany, n)
}
