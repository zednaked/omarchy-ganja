import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons
import "Art.js" as Art
import "I18n.js" as I18n
import "Palette.js" as Palette

// A growing room: a planta ao centro, os medidores embaixo, o strain a direita.
//
// Esta metade dorme. Fechada, nada aqui desenha, mede ou anima - o Timer de
// animacao so corre enquanto a janela esta visivel, e o estado inteiro mora em
// Grow.qml, que custa um timer de sessenta segundos.
//
// A paleta daqui e a do Ganja-TUI, com os RGB literais de src/ui/colors.rs, e
// nao a do tema do Omarchy. A regra e a mesma que rege o icone da barra, so que
// ao contrario: uma planta repintada com o accent do tema deixa de ser a
// planta. O tema manda na barra; aqui manda o Ganja.
Item {
  id: root

  property var shell: null
  property var manifest: null

  property bool opened: Grow.open

  // A fonte do shell, nao uma familia escolhida aqui. A primeira versao do
  // zed.quadro nomeou "IBM Plex Mono", a maquina nao tinha, tudo caiu para o
  // fallback em silencio, e a tipografia que eu achava ter escolhido nunca
  // aconteceu. Tem que ser monoespacada: 70x28 so fecha com avanco fixo.
  readonly property string mono: Style.fontFamily

  property int frame: 0
  property string status: ""
  property bool showHarvests: false

  // ---- configuracao vinda do manifest -------------------------------------
  // O singleton nao recebe o manifest (o shell so injeta em quem e entrada de
  // plugin); o overlay recebe e repassa. Ele e keepLoaded, entao isto acontece
  // na carga do shell, antes do primeiro tick que importa.
  onManifestChanged: {
    if (!manifest) return
    if (typeof manifest.timeScale === "number" && manifest.timeScale > 0)
      Grow.timeScale = manifest.timeScale
    if (typeof manifest.careScale === "number" && manifest.careScale > 0)
      Grow.careScale = manifest.careScale
    if (typeof manifest.turboScale === "number" && manifest.turboScale > 0)
      Grow.turboScale = manifest.turboScale
  }

  function flash(msg) { root.status = msg; statusTimer.restart() }
  Timer { id: statusTimer; interval: 2400; onTriggered: root.status = "" }

  // ---- animacao ------------------------------------------------------------
  // Dez quadros por segundo. As animacoes da arte sao ciclos de 2, 3, 4, 8 e 12
  // quadros e a respiracao e um seno lento: passar disso gasta GPU para mostrar
  // a mesma coisa. O TUI roda a 20 - la o mesmo timer tambem le o teclado.
  //
  // Parada, tambem nao corre. Se o relogio esta desligado, os dez quadros por
  // segundo estariam animando a respiracao e o matiz de uma planta que nao vai
  // a lugar nenhum - trinta milissegundos de CPU por quadro para redesenhar o
  // mesmo estado, que e exatamente o custo que o `p` promete zerar. A sala
  // continua aberta e legivel; ela e uma foto, e diz que e.
  Timer {
    running: root.opened && !Grow.paused
    interval: 100
    repeat: true
    onTriggered: {
      root.frame++
      if (Grow.fast) Grow.fastStep(0.1)
    }
  }

  onOpenedChanged: {
    if (root.opened) {
      root.showHarvests = false
      Grow.reread()          // outra sessao pode ter escrito; quem vai olhar pergunta
      Grow.publish()
    } else {
      // Fechar desliga a demonstracao, e so ela. A demonstracao simula sobre
      // uma copia: atras de uma janela fechada ela gastaria CPU para animar uma
      // planta que ninguem ve e que sera jogada fora de qualquer forma.
      //
      // O turbo fica ligado, porque ele e uma preferencia e nao um modo de
      // olhar - ver a linha longa no Grow.qml. Ele continua sendo o ritmo do
      // TUI e continua avisado em vermelho no cabecalho.
      Grow.stopFast()
    }
  }

  // ---- cores do quadro atual ----------------------------------------------

  readonly property var seedLimbs: Art.u64FromHex(Grow.seedHex)
  readonly property int flowerVariant: Art.u64ModSmall(root.seedLimbs, 6)
  readonly property int foliageVariant: Art.u64ModSmall(Art.u64DivModSmall(root.seedLimbs, 6).q, 4)
  readonly property int trunkVariant: Art.u64ModSmall(Art.u64DivModSmall(root.seedLimbs, 24).q, 3)

  function paletteColors(f) {
    var mode = Grow.visualMode
    var stage = Grow.stage
    var day = Grow.day
    var intens = Palette.flowerIntensities(stage, day)
    var breath = 0.875 + Math.sin(f * Palette.breathSpeed(mode)) * 0.125
    var hp = Palette.healthPercent(Grow.health)

    return {
      foliage: Palette.applyBreathing(Palette.foliageColor(mode, root.foliageVariant, hp, Grow.water, f), breath),
      flower1: Palette.applyBreathing(Palette.flowerColor(mode, root.flowerVariant, intens[0], stage, f), breath),
      flower2: Palette.applyBreathing(Palette.flowerColor(mode, root.flowerVariant, intens[1], stage, f), breath),
      flower3: Palette.applyBreathing(Palette.flowerColor(mode, root.flowerVariant, intens[2], stage, f), breath),
      trunk: Palette.trunkColor(mode, root.trunkVariant, day, f),
      soil: Palette.soilColor(mode, Grow.water, f)
    }
  }

  readonly property color waterColor: Palette.hex(Palette.waterColor(Grow.visualMode, Grow.water, root.frame))
  readonly property color npkColor: Palette.hex(Palette.nutrientColor(Grow.visualMode, Grow.nutrients, root.frame))

  readonly property color inkBright: "#e4e8e2"
  readonly property color ink: "#a8b0a6"
  readonly property color inkDim: "#6d756c"
  readonly property color rule: "#2a322a"

  // ---- IPC -----------------------------------------------------------------
  //
  // O que o IPC DEVOLVE segue o idioma escolhido, e o que ele ACEITA nao. Quem
  // digita `omarchy-shell ganja status` esta lendo, e ler na lingua que se
  // escolheu e o pedido inteiro desta versao; quem escreve `ganja window medium`
  // esta programando, e um comando que muda de nome junto com uma preferencia de
  // leitura e um script que quebra quando alguem aperta `l`.
  IpcHandler {
    target: "ganja"
    function toggle(): string { Grow.open = !Grow.open; return Grow.open ? "open" : "closed" }
    function open(): string { Grow.open = true; return "ok" }
    function close(): string { Grow.open = false; return "ok" }
    function water(): string { Grow.pour(40); return "" + Math.round(Grow.water) + "%" }
    function feed(): string { Grow.feed(40); return "" + Math.round(Grow.nutrients) + "%" }
    function harvest(): string {
      return Grow.harvestNow() ? Grow.t("ipc.harvested") : Grow.t("ipc.notReady")
    }
    function mode(): string { Grow.cycleVisualMode(); return I18n.mode(Grow.lang, Grow.visualMode) }
    function auto(): string {
      return Grow.toggleAutoCare() ? Grow.t("ipc.on") : Grow.t("ipc.off")
    }
    function turbo(): string {
      if (Grow.fast) Grow.stopFast()
      return Grow.toggleTurbo() ? Grow.t("ipc.turboOn") : Grow.t("ipc.off")
    }
    // Para e retoma de fora da sessao grafica - e o que um `omarchy-guest` de
    // manutencao, um hook de bateria fraca ou um Makefile chamariam.
    function pause(): string {
      return Grow.togglePause() ? Grow.t("ipc.paused") : Grow.t("ipc.running")
    }
    function stop(): string { Grow.setPaused(true); return Grow.t("ipc.paused") }
    function start(): string { Grow.setPaused(false); return Grow.t("ipc.running") }
    function window(mode: string): string {
      if (mode === "") { root.cycleWindowMode(); return Grow.windowMode }
      if (Grow.canonWindowMode(mode) === "")
        return Grow.tf("ipc.sizes", Grow.windowModes.join(", "))
      return Grow.setWindowMode(mode)
    }
    // O ritmo, em horas de jogo por hora real. Sem argumento, responde o atual.
    function scale(value: string): string {
      if (value === "") return "" + Grow.scale + "x"
      var n = Grow.setScale(value)
      // 2304 h = os 96 dias que a planta leva da muda a colheita automatica.
      // A virgula decimal segue o idioma, como todo numero aqui.
      return "" + n + "x  ·  " + Grow.tf("ipc.cycle", Grow.num(2304 / n))
    }
    function lang(code: string): string {
      if (code === "") return Grow.cycleLang()
      if (!I18n.known(code)) return Grow.tf("ipc.languages", I18n.LANGS.join(", "))
      return Grow.setLang(code)
    }
    function status(): string {
      return Grow.tf("ipc.status", Grow.strainName, Grow.stageLabel, Grow.day,
        Math.round(Grow.water), Math.round(Grow.nutrients))
        + (Grow.paused ? " · " + Grow.t("ipc.paused") : "")
    }
  }

  // ---- tamanho e tipo de janela -------------------------------------------
  //
  // Cinco modos, e o ultimo e de outra especie. Os quatro primeiros sao uma
  // camada do layer-shell sobre a tela: em `full` ela e a tela, nos outros e
  // um cartao centralizado sobre um fundo escurecido, que fecha ao clicar fora.
  // `window` e uma janela de verdade, que o Hyprland arruma junto com as
  // outras - da para deixar a planta lado a lado com o que voce esta fazendo em
  // vez de ter que abrir e fechar.
  //
  // O modo mora no Grow e vai para o save: e uma preferencia, e preferencia que
  // volta ao padrao a cada boot nao e preferencia.
  // A lista e os ids moram no Grow, junto com o resto do que vai para o save. O
  // rotulo na tela e traduzido; o id, nunca.
  readonly property var windowModes: Grow.windowModes
  readonly property string windowMode: Grow.windowMode
  readonly property bool windowed: root.windowMode === "window"

  function cycleWindowMode() {
    Grow.cycleWindowMode()
    root.flash(Grow.tf("msg.window", I18n.windowMode(Grow.lang, Grow.windowMode)))
  }

  // Proporcao da tela, com teto absoluto. So a proporcao deixa o modo "small"
  // grande demais num monitor 4K; so o absoluto o deixa maior que a tela num
  // notebook.
  function cardWidth(w) {
    switch (root.windowMode) {
    case "large":  return Math.round(Math.min(1280, w * 0.86))
    case "medium": return Math.round(Math.min(980, w * 0.72))
    case "small":  return Math.round(Math.min(720, w * 0.58))
    default:       return w
    }
  }
  function cardHeight(h) {
    switch (root.windowMode) {
    case "large":  return Math.round(Math.min(880, h * 0.88))
    case "medium": return Math.round(Math.min(660, h * 0.76))
    case "small":  return Math.round(Math.min(450, h * 0.58))
    default:       return h
    }
  }

  // ---- teclas --------------------------------------------------------------
  // Uma funcao so, chamada pelas duas janelas. Duas copias da mesma tabela de
  // teclas e a forma mais barata de fazer um atalho existir num modo e nao no
  // outro sem ninguem perceber.
  function handleKey(e) {
    switch (e.key) {
    case Qt.Key_Escape:
    case Qt.Key_Q:
      Grow.open = false; e.accepted = true; break
    case Qt.Key_W:
      Grow.pour(40); root.flash(Grow.tf("msg.watered", Math.round(Grow.water))); e.accepted = true; break
    case Qt.Key_N:
      Grow.feed(40); root.flash(Grow.tf("msg.fed", Math.round(Grow.nutrients))); e.accepted = true; break
    case Qt.Key_V:
      Grow.cycleVisualMode(); root.flash(I18n.mode(Grow.lang, Grow.visualMode)); e.accepted = true; break
    case Qt.Key_A:
      root.flash(Grow.toggleAutoCare() ? Grow.t("msg.autoOn") : Grow.t("msg.autoOff"))
      e.accepted = true; break
    case Qt.Key_T:
      root.cycleWindowMode(); e.accepted = true; break
    case Qt.Key_H:
      root.flash(Grow.harvestNow() ? Grow.t("msg.harvested") : Grow.t("msg.notReady"))
      e.accepted = true; break
    case Qt.Key_Tab:
      root.showHarvests = !root.showHarvests; e.accepted = true; break
    case Qt.Key_P:
      // A mesma tecla nos dois sentidos: a sala diz em que estado ela esta e o
      // `p` alterna. Duas teclas para parar e retomar seriam duas chances de
      // apertar a errada por uma coisa que so tem dois estados.
      root.flash(Grow.togglePause() ? Grow.t("msg.paused") : Grow.t("msg.resumed"))
      e.accepted = true; break
    case Qt.Key_L:
      // `l` de language/lingua - a unica letra que serve de mnemonico nos dois
      // idiomas, que e exatamente o que uma tecla de idioma precisa ser. E o
      // recado dela vem NA LINGUA NOVA: e a confirmacao de que trocou.
      Grow.cycleLang(); root.flash(Grow.t("msg.lang")); e.accepted = true; break
    case Qt.Key_F:
      // Dois modos rapidos, e eles sao coisas diferentes de verdade - por isso
      // duas teclas em vez de uma com tres estados.
      //
      //   f        demonstracao: 130000x em cima de uma COPIA. Nada disso
      //            aconteceu; desligar devolve a planta onde ela estava.
      //   Shift+F  turbo: 130000x na planta DE VERDADE. Escreve no save, as
      //            colheitas contam, o tempo queimado nao volta.
      //
      // Os dois sao liga/desliga. Segurar a tecla, que era como a demonstracao
      // funcionava, e ruim justamente para o que ela serve: olhar.
      if (e.isAutoRepeat) { e.accepted = true; break }
      if (e.modifiers & Qt.ShiftModifier) {
        if (Grow.fast) Grow.stopFast()      // os dois ao mesmo tempo nao fazem sentido
        root.flash(Grow.toggleTurbo() ? Grow.t("msg.turboOn") : Grow.t("msg.turboOff"))
      } else {
        if (Grow.turbo) Grow.toggleTurbo()
        if (Grow.fast) { Grow.stopFast(); root.flash(Grow.t("msg.demoOff")) }
        else { Grow.startFast(); root.flash(Grow.t("msg.demoOn")) }
      }
      e.accepted = true; break
    }
  }

  // ---- camada sobre a tela -------------------------------------------------
  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: win
      required property var modelData
      screen: modelData

      // So no monitor com foco. A mesma planta desenhada em duas telas sao dois
      // canvas disputando um tamanho de area, e o segundo esta errado por
      // construcao.
      readonly property bool isTarget: {
        var f = Hyprland.focusedMonitor
        var want = f ? String(f.name || "") : ""
        if (want === "") return true
        return String(modelData.name || "") === want
      }

      visible: root.opened && isTarget && !root.windowed
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "zed-ganja"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
      anchors { top: true; right: true; bottom: true; left: true }

      FocusScope {
        anchors.fill: parent
        focus: true

        Keys.onPressed: function (e) { root.handleKey(e) }

        // O escurecido atras do cartao. Em `full` ele nao aparece - a sala ja
        // cobre tudo - e clicar fora nao teria "fora" nenhum para acertar.
        Rectangle {
          anchors.fill: parent
          visible: root.windowMode !== "full"
          color: Qt.rgba(0, 0, 0, 0.45)
          MouseArea {
            anchors.fill: parent
            onClicked: Grow.open = false
          }
        }

        Room {
          anchors.centerIn: parent
          width: root.cardWidth(parent.width)
          height: root.cardHeight(parent.height)
          ui: root
          active: win.isTarget && root.opened
          framed: root.windowMode !== "full"

          // Sem isto o clique na sala atravessa para o MouseArea do fundo e
          // fecha a janela que a pessoa acabou de abrir.
          MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }
        }
      }
    }
  }

  // ---- janela de verdade ---------------------------------------------------
  // Uma toplevel comum: o compositor arruma, redimensiona e fecha como faz com
  // qualquer aplicativo. E o modo para deixar a planta aberta num canto do
  // workspace em vez de abrir e fechar.
  FloatingWindow {
    id: floating
    visible: root.opened && root.windowed
    title: Grow.loaded
      ? "Ganja · " + Grow.tf("bar.line", Grow.strainName, Grow.stageLabel, Grow.day)
      : "Ganja"
    color: "transparent"

    implicitWidth: 980
    implicitHeight: 660
    minimumSize: Qt.size(420, 320)

    onClosed: Grow.open = false

    FocusScope {
      anchors.fill: parent
      focus: true

      Keys.onPressed: function (e) { root.handleKey(e) }

      Room {
        anchors.fill: parent
        ui: root
        active: root.opened && root.windowed
        framed: false
      }
    }
  }


  // ---- dados derivados -----------------------------------------------------

  function strainField(key) {
    var p = Grow.viewPlant
    var s = p && p.genetics ? p.genetics.strain_info : null
    return s && s[key] !== undefined ? String(s[key]) : ""
  }

  readonly property var strainRows: {
    var p = Grow.viewPlant
    if (!p || !p.genetics) return []
    var g = p.genetics
    var s = g.strain_info
    // O dado do strain vem de strains.json, em ingles, e passa por `term()` por
    // campo: "Medium" e dificuldade media e rendimento medio, e as duas
    // palavras sao diferentes em portugues.
    var rows = [
      { label: Grow.t("s.genetics"), value: s ? s.genetics : "—" },
      { label: Grow.t("s.cannabinoids"),
        value: Grow.tf("s.cannabinoidsValue", Grow.num(g.thc_percent), Grow.num(g.cbd_percent)) }
    ]
    if (s) {
      rows.push({ label: Grow.t("s.growing"),
        value: Grow.tf("s.growingValue", Grow.term("difficulty", s.difficulty),
          Grow.term("yield", s.yield_potential)) })
      rows.push({ label: Grow.t("s.flowering"),
        value: Grow.tf("s.floweringValue", s.flowering_time, Grow.term("height", s.height),
          Grow.term("phenotype", s.phenotype)) })
      rows.push({ label: Grow.t("s.terpenes"), value: Grow.terms("terpene", s.dominant_terpenes) })
      rows.push({ label: Grow.t("s.aroma"), value: Grow.terms("aroma", s.aroma) })
      rows.push({ label: Grow.t("s.effects"), value: Grow.terms("effect", s.effects) })
    }
    rows.push({ label: Grow.t("s.resilience"),
      value: Grow.tf("s.resilienceValue", Math.round(g.resilience * 100), Grow.num(g.growth_rate, 2)) })
    rows.push({ label: Grow.t("s.seed"), value: Grow.seedHex })
    return rows
  }

  // Progresso ate o proximo estagio, com os mesmos limiares de growing.rs.
  readonly property var nextStage: {
    var d = Grow.day
    var target, name
    switch (Grow.stage) {
    case "Seedling": target = 11; name = Grow.t("next.vegetative"); break
    case "Vegetative": target = 41; name = Grow.t("next.preflower"); break
    case "PreFlower": target = 49; name = Grow.t("next.flowering"); break
    case "Flowering": target = 86; name = Grow.t("next.harvest"); break
    case "ReadyToHarvest":
      return { name: Grow.t("next.ready"), percent: 100, left: Grow.t("next.cut") }
    default: target = 11; name = Grow.t("next.vegetative")
    }
    return {
      name: name,
      percent: Math.min(d / target * 100, 100),
      left: Math.max(target - d, 0) + "d"
    }
  }

  readonly property var healthGauge: {
    var label = I18n.health(Grow.lang, Grow.health)
    switch (Grow.health) {
    case "Excellent": return { percent: 100, label: label, color: Palette.hex(Palette.ANSI.gaugeGreen) }
    case "Good": return { percent: 75, label: label, color: Palette.hex(Palette.ANSI.gaugeGreen) }
    case "Fair": return { percent: 50, label: label, color: Palette.hex(Palette.ANSI.gaugeYellow) }
    case "Poor": return { percent: 25, label: label, color: Palette.hex(Palette.ANSI.gaugeLightRed) }
    default: return { percent: 10, label: label, color: Palette.hex(Palette.ANSI.gaugeRed) }
    }
  }

  readonly property var harvestRows: {
    var out = []
    var h = Grow.harvests
    for (var i = h.length - 1; i >= 0; i--) {
      var r = JSON.parse(JSON.stringify(h[i]))
      r.n = i + 1 + Math.max(Grow.totalHarvests - h.length, 0)
      var d = new Date(r.completed_at)
      // O formato de data e uma string traduzida como qualquer outra: "dd/MM"
      // em portugues, "MM/dd" em ingles. Deixar um dos dois fixo faria metade
      // das colheitas parecerem do mes errado.
      r.when = isNaN(d.getTime()) ? "" : Qt.formatDateTime(d, Grow.t("h.dateFormat"))
      out.push(r)
    }
    return out
  }

  // Os totais saem do acumulado vitalicio, e nao da lista.
  //
  // Somar a lista era o que estava aqui, e a soma mentia assim que o teto de 100
  // cortava a primeira colheita: a mesma frase dizia "143 colheitas" (contador
  // vitalicio) e "2867 g no total" (as 100 que sobraram no arquivo). Duas
  // unidades diferentes na mesma linha, e a errada era a que impressionava.
  readonly property var totals: {
    var lt = Grow.lifetime
    var n = Grow.totalHarvests
    if (!lt || n === 0) return { weight: 0, quality: 0, thc: 0, cbd: 0, records: false }
    return {
      weight: lt.grams,
      quality: lt.quality_sum / n,
      thc: lt.thc_sum / n,
      cbd: lt.cbd_sum / n,
      bestGrams: lt.best_grams, bestGramsStrain: lt.best_grams_strain,
      bestQuality: lt.best_quality, bestQualityStrain: lt.best_quality_strain,
      firstAt: lt.first_at,
      records: lt.best_grams > 0
    }
  }

  // "desde 12/09" - a data da primeira colheita, que e a idade do grow todo.
  readonly property string firstHarvestWhen: {
    var at = root.totals.firstAt
    if (!at) return ""
    var d = new Date(at)
    return isNaN(d.getTime()) ? "" : Qt.formatDateTime(d, Grow.t("h.dateFormat"))
  }
}
