import QtQuick
import Quickshell
import Quickshell.Io

// Roda o Grow.qml de verdade, fora do shell, e confere o que ele guarda.
//
//   HOME=$(mktemp -d) qs -p test/state.qml
//
// O HOME falso nao e detalhe: `Grow.dir` sai de `Quickshell.env("HOME")`, e um
// teste que rodasse com o HOME de verdade escreveria na planta de quem esta
// testando. O `make state` cuida disso.
//
// O que se verifica aqui e a metade que nao aparece em frame nenhum: parar
// mesmo para o relogio, e o save leva de volta o idioma, a parada e o tamanho
// de janela - inclusive os ids em portugues que existiam antes do idioma virar
// opcao.
ShellRoot {
  id: root

  property int checked: 0
  property int failed: 0

  function ok(what, cond) {
    root.checked++
    if (cond) console.warn("OK:     " + what)
    else { root.failed++; console.warn("FALHOU: " + what) }
  }

  function eq(what, got, want) {
    root.ok(what + " (" + got + ")", String(got) === String(want))
  }

  // O idioma inteiro depende de uma coisa que nao e obvia: uma binding que
  // chama `Grow.t()` tem que RE-AVALIAR quando `Grow.lang` muda. O QML captura
  // as propriedades lidas durante a avaliacao, mesmo dentro de uma funcao que
  // mora em outro arquivo - mas se isso nao valesse, a falha apareceria como
  // uma tela em duas linguas, sem erro nenhum no log. E a unica coisa aqui que
  // precisa de uma binding de verdade para ser verificada.
  Item {
    id: sonda
    property string rotulo: Grow.t("m.water")
    property string estagio: Grow.stageLabel
  }

  // O singleton le o save num Process, ou seja de forma assincrona: nada pode
  // ser conferido antes de `loaded`. Esperar por um sinal e o unico jeito
  // honesto - um Timer com um numero chutado passa na maquina de quem escreveu
  // e falha na de quem clona.
  Connections {
    target: Grow
    function onLoadedChanged() { if (Grow.loaded) root.run() }
  }
  Component.onCompleted: if (Grow.loaded) root.run()

  function run() {
    var G = Grow

    // ---- comeca andando, com planta nova -----------------------------------
    root.ok("save vazio nasce com planta", G.plant !== null)
    root.eq("nasce andando", G.paused, false)
    root.eq("idioma sai do locale", G.lang, /^pt/i.test(String(Qt.locale().name)) ? "pt" : "en")

    // ---- parar para o relogio ----------------------------------------------
    var horasAntes = G.plant.total_hours_elapsed
    G.setPaused(true)
    root.eq("parou", G.paused, true)
    G.tick()                      // o tick que o Timer nao vai mais disparar
    root.eq("parada, o tick nao anda", G.plant.total_hours_elapsed, horasAntes)
    root.eq("parada, nada de alerta", G.alerting, false)

    // ---- os dois rapidos nao convivem com a parada -------------------------
    G.toggleTurbo()
    root.eq("turbo despara", G.paused, false)
    root.eq("turbo ligou", G.turbo, true)

    // O turbo e preferencia: vai para o save e volta dele. Isto foi decidido ao
    // contrario primeiro - ver o comentario dele no Grow.qml.
    root.eq("snapshot leva o turbo", G.snapshot().turbo, true)
    G.turbo = false
    G.adopt({ current_plant: G.plant, turbo: true }, true)
    root.eq("adopt traz o turbo", G.turbo, true)

    G.setPaused(true)
    root.eq("parar desliga o turbo", G.turbo, false)
    // Um save que diga as duas coisas nao pode acordar nas duas: parada manda.
    G.adopt({ current_plant: G.plant, turbo: true, paused: true }, true)
    root.eq("parada manda sobre o turbo", G.turbo, false)
    root.eq("e continua parada", G.paused, true)
    G.setPaused(false)

    // ---- retomar anda de novo ----------------------------------------------
    G.setPaused(false)
    G.lastTickMs = Date.now() - 60000
    G.tick()
    root.ok("retomada, o tick anda", G.plant.total_hours_elapsed > horasAntes)

    // ---- idioma --------------------------------------------------------------
    G.setLang("pt")
    root.eq("estagio em portugues", G.stageLabel, "Muda")
    root.eq("binding traduz junto", sonda.rotulo, "água")
    root.eq("binding do estagio traduz junto", sonda.estagio, "Muda")
    G.setLang("en")
    root.eq("estagio em ingles", G.stageLabel, "Seedling")
    root.eq("binding volta para o ingles", sonda.rotulo, "water")
    root.eq("idioma desconhecido nao entra", G.setLang("de"), "en")

    // ---- ids de janela, novos e antigos ------------------------------------
    root.eq("id novo", G.setWindowMode("medium"), "medium")
    root.eq("id antigo vira novo", G.setWindowMode("pequeno"), "small")
    root.eq("id invalido nao muda nada", G.setWindowMode("enorme"), "small")
    root.eq("ciclo", G.cycleWindowMode(), "window")

    // ---- o caminho antigo do save ------------------------------------------
    // O plugin morou dentro do omarchy-guest e guardava a planta em
    // ~/.local/share/omarchy-guest/ganja. Quem instalar a versao publicada tem
    // que reencontrar a propria planta, e nao uma muda nova.
    root.eq("caminho novo", String(G.saveFile).indexOf("/.local/share/zed.ganja/") > 0, true)
    root.eq("caminho antigo continua conhecido",
      String(G.legacySaveFile).indexOf("/omarchy-guest/ganja/") > 0, true)

    // ---- o ritmo e preferencia, e ganha do manifest ------------------------
    G.timeScale = 40            // o que o manifest teria posto
    root.eq("sem escolha, vale o manifest", G.scale, 40)
    root.eq("escolha ganha", G.setScale(400), 400)
    root.eq("fora de faixa nao entra (0)", G.setScale(0), 400)
    root.eq("fora de faixa nao entra (acima do TUI)", G.setScale(200000), 400)
    root.eq("snapshot leva o ritmo", G.snapshot().time_scale, 400)

    // ---- o acumulado nao morre com o teto da lista -------------------------
    // Um save sem `lifetime` e um save de antes disto existir: o acumulado
    // nasce somando a lista que esta la, que e a unica conta honesta possivel.
    G.adopt({
      current_plant: G.plant,
      total_harvests: 2,
      harvest_history: [
        { strain_name: "A", weight_grams: 10, quality_score: 80, thc_percent: 20,
          cbd_percent: 0.2, harvest_day: 96, completed_at: "2026-09-01T10:00:00Z" },
        { strain_name: "B", weight_grams: 30, quality_score: 90, thc_percent: 22,
          cbd_percent: 0.4, harvest_day: 96, completed_at: "2026-09-02T10:00:00Z" }
      ]
    }, true)
    root.eq("acumulado semeado da lista: gramas", G.lifetime.grams, 40)
    root.eq("acumulado semeado: recorde", G.lifetime.best_grams, 30)
    root.eq("acumulado semeado: strain do recorde", G.lifetime.best_grams_strain, "B")
    root.eq("acumulado semeado: melhor qualidade", G.lifetime.best_quality, 90)
    root.eq("acumulado semeado: primeira colheita",
      G.lifetime.first_at, "2026-09-01T10:00:00Z")

    // E uma colheita nova soma em cima, sem depender da lista.
    var antes = G.lifetime.grams
    G.creditLifetime(G.lifetime, { strain_name: "C", weight_grams: 5, quality_score: 50,
      thc_percent: 1, cbd_percent: 0, completed_at: "2026-09-03T10:00:00Z" })
    root.eq("colheita nova soma", G.lifetime.grams, antes + 5)
    root.eq("recorde nao cai por colheita pequena", G.lifetime.best_grams, 30)
    root.eq("primeira colheita nao muda", G.lifetime.first_at, "2026-09-01T10:00:00Z")

    // ---- o save leva tudo isso de volta ------------------------------------
    G.setLang("pt")
    G.setWindowMode("large")
    G.setPaused(true)
    var snap = G.snapshot()
    root.eq("snapshot: idioma", snap.language, "pt")
    root.eq("snapshot: parada", snap.paused, true)
    root.eq("snapshot: janela", snap.window_mode, "large")

    // Adotar e o caminho de volta: e o que acontece quando o shell sobe ou
    // quando outra sessao escreveu.
    G.setLang("en"); G.setPaused(false); G.setWindowMode("full")
    G.adopt(JSON.parse(JSON.stringify(snap)), true)
    root.eq("adopt: idioma", G.lang, "pt")
    root.eq("adopt: parada", G.paused, true)
    root.eq("adopt: janela", G.windowMode, "large")

    // Um save de antes destes campos existirem: nao pode virar erro, e o
    // default tem que ser o de uma planta que anda.
    var velho = JSON.parse(JSON.stringify(snap))
    delete velho.language; delete velho.paused
    velho.window_mode = "cheio"
    G.adopt(velho, true)
    root.eq("save antigo: andando", G.paused, false)
    root.eq("save antigo: janela em portugues", G.windowMode, "full")

    console.warn(root.failed === 0
      ? "OK: " + root.checked + " verificacoes de estado"
      : "FALHOU: " + root.failed + " de " + root.checked)
    Qt.exit(root.failed === 0 ? 0 : 1)
  }
}
