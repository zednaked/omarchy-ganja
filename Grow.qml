pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "Art.js" as Art
import "I18n.js" as I18n
import "Strains.js" as Strains

// O estado da planta: o save, o relogio e a simulacao.
//
// Esta e a metade que fica acordada. Fechado o overlay, o custo do plugin
// inteiro e um Timer de 60 s fazendo aritmetica sobre numeros que ja estao na
// memoria - nenhum processo, nenhum arquivo, nenhum parse. O `cat` do save
// acontece uma vez, na carga do shell, e uma vez a mais toda vez que o overlay
// abre (para adotar um save mais novo que outra sessao tenha escrito).
//
// A simulacao e a de src/app.rs do Ganja-TUI, traduzida. As divergencias
// deliberadas estao marcadas com DIVERGE e explicadas onde acontecem; sao
// quatro, e todas descem da mesma decisao: isto mora numa barra, nao numa
// janela que voce abre por um minuto.
Singleton {
  id: root

  // ---- configuracao --------------------------------------------------------
  // Escritas por Ganja.qml a partir do manifest (e, se houver, das settings da
  // barra). Os defaults aqui sao os mesmos do manifest, para o caso de o
  // overlay ainda nao ter carregado quando o primeiro tick acontecer.

  // Horas de jogo por hora real. O TUI usa 130000 (ciclo completo em 60 s), o
  // que numa barra significaria uma colheita por minuto. 40 da um ciclo de 90
  // dias em ~54 h de sessao - uma semana de uso normal.
  property real timeScale: 40

  // O ritmo escolhido por quem usa, que ganha do manifest. Zero significa "nao
  // escolhi nada, use o do manifest".
  //
  // Existe como preferencia salva em vez de um numero novo no manifest porque
  // as duas coisas sao diferentes: o manifest e o default PUBLICADO, e uma
  // semana por ciclo e uma decisao de projeto com argumento (SPEC 4b, o ritmo
  // contemplativo). Que o autor goste de rapido nao e motivo para mudar o que
  // chega na maquina dos outros - e motivo para o ritmo ser ajustavel.
  //
  // E separado de `timeScale` em vez de sobrescreve-lo por causa da ordem de
  // carga: o manifest chega pelo Ganja.qml e o save chega por um Process
  // assincrono, e qualquer um dos dois pode ser o ultimo. Com dois campos e uma
  // precedencia explicita, a ordem deixa de importar.
  property real userScale: 0
  readonly property real scale: root.userScale > 0 ? root.userScale : root.timeScale

  // Limites: abaixo de 1 a planta praticamente nao anda e o usuario acha que
  // quebrou; acima do fator do TUI nao existe motivo nenhum, porque ali o turbo
  // ja e o mesmo ritmo e diz que e.
  function setScale(v) {
    var n = Number(v)
    if (!isFinite(n) || n < 1 || n > root.turboScale) return root.scale
    root.userScale = n
    root.lastTickMs = Date.now()   // o passo seguinte nao cobre o intervalo antigo
    root.save()
    return root.scale
  }

  // O fator original do Ganja-TUI. La ele nao e um modo, e o unico ritmo: o
  // ciclo de 90 dias em 60 segundos.
  property real turboScale: 130000

  // Quanto a agua e o NPK drenam, em relacao ao TUI. La a planta se rega
  // sozinha e o dreno so serve de animacao; aqui quem rega e voce, e 1.0 por
  // hora de jogo esvaziaria o vaso a cada duas horas e meia de sessao.
  property real careScale: 0.2

  // Os caminhos sao RELATIVOS ao $HOME, e e nessa forma que o helper os recebe:
  // ele desce componente por componente a partir de um descritor do $HOME, com
  // O_NOFOLLOW em cada passo, e nunca aceita um caminho absoluto. As duas
  // propriedades absolutas abaixo existem so para o que mostra caminho na tela
  // e para os testes.
  readonly property string relDir: ".local/share/zed.ganja"
  readonly property string relLegacy: ".local/share/omarchy-guest/ganja/save.json"

  readonly property string dir: Quickshell.env("HOME") + "/" + root.relDir
  readonly property string saveFile: root.dir + "/save.json"

  // Onde o save morava enquanto o plugin era uma pasta dentro do omarchy-guest.
  // E lido uma vez, na carga, e so se o novo nao existir; nunca e escrito.
  //
  // Um plugin publicado por conta propria guardando dados com o nome de outro
  // projeto no caminho esta errado - mas trocar o caminho sem levar a planta de
  // quem ja tinha uma seria pior, porque o unico bem dela e o tempo acumulado.
  // Adotado o save antigo, a primeira gravacao cai no lugar novo e o antigo fica
  // onde esta, intacto: se alguem voltar para a versao de dentro do guest, a
  // planta dele ainda esta la.
  readonly property string legacySaveFile: Quickshell.env("HOME") + "/" + root.relLegacy

  // O unico lugar que toca o disco e o save.py ao lado deste arquivo, sempre
  // chamado como `/usr/bin/python3 -I save.py <modo> <caminhos relativos>`.
  //
  // Isto era um `save.sh` e virou Python por exigencia da revisao de seguranca
  // do marketplace (issue #6530), e a exigencia estava certa: em shell, cada
  // comando resolve o caminho de novo, entao checar com `[ -f ]` e depois usar
  // `head`/`mv` sao duas resolucoes diferentes, e o que foi checado pode ser
  // trocado no meio. O `sh` nao alcanca `openat`, `renameat` nem `O_NOFOLLOW`;
  // o Python alcanca, e a identidade do diretorio passa a ser um descritor
  // aberto uma vez e mantido pela leitura, pela gravacao, pelo fsync e pelo
  // rename. As garantias, uma por uma, estao no cabecalho do save.py.
  //
  // `-I` e o modo isolado: ignora PYTHON*, o site do usuario e o diretorio do
  // script no sys.path.
  readonly property string helper: String(Qt.resolvedUrl("save.py")).replace("file://", "")

  // Ambiente fechado: o filho nao herda nada do shell da barra. O HOME vai
  // porque e a raiz de confianca do helper - e o unico caminho que ele abre por
  // nome, e todo o resto desce de um descritor dele.
  readonly property var helperEnv: ({
    "PATH": "/usr/bin:/bin",
    "HOME": Quickshell.env("HOME")
  })

  // O mesmo ambiente fechado para o lancamento DESTACADO da descarga de saida.
  //
  // `Quickshell.execDetached(["prog", ...])` - a forma de lista - herda o
  // ambiente do shell inteiro, e foi o terceiro achado da revisao de seguranca
  // do marketplace (issue #6530): os tres `Process` limpavam o ambiente e esse
  // nao, entao a unica gravacao que acontece automaticamente (ao descarregar)
  // rodava sob o que estivesse no ambiente. O `-I` do Python nao ajuda ai: ele
  // suprime PYTHONPATH e o site do usuario, mas quem age antes do Python
  // comecar e o LOADER, e LD_PRELOAD/LD_AUDIT nao passam por ele.
  //
  // A sobrecarga com `processContext` aceita `clearEnvironment`, e e por isso
  // que o contexto e montado aqui e nao na chamada: assim o teste
  // (test/detached.qml) constroi o ambiente pelo MESMO codigo que a descarga
  // usa, em vez de por uma copia que pode divergir.
  function detachedContext(cmd) {
    return ({
      command: cmd,
      clearEnvironment: true,
      environment: root.helperEnv
    })
  }

  property processContext shutdownContext

  // ---- estado --------------------------------------------------------------

  // A planta, no formato do serde de src/domain/plant.rs. E a fonte da verdade;
  // as propriedades abaixo sao um espelho para o QML, porque mexer num campo de
  // um `var` nao emite sinal nenhum e a barra nunca saberia.
  property var plant: null
  property var harvests: []
  property int totalHarvests: 0

  // O que nunca morre.
  //
  // `harvests` guarda as 100 ultimas e descarta as mais velhas - um save que
  // cresce para sempre e um vazamento com outro nome. Com o turbo ligado, que
  // colhe a cada ~64 s, essas 100 rodam inteiras em uma hora e quarenta: sem
  // isto aqui, duas horas de turbo apagariam todo o passado da planta, que e
  // justamente o que o plugin diz valer ("a decima colheita tem dez historias
  // atras dela").
  //
  // Entao a lista detalhada continua sendo as 100 ultimas, e o acumulado -
  // gramas, medias, recordes, desde quando - fica aqui e nao depende dela.
  // Custa seis numeros no save em vez de um arquivo que cresce.
  property var lifetime: root.newLifetime()

  function newLifetime() {
    return {
      grams: 0,
      quality_sum: 0, thc_sum: 0, cbd_sum: 0,   // divididos por totalHarvests
      best_grams: 0, best_grams_strain: "",
      best_quality: 0, best_quality_strain: "",
      first_at: "", last_at: ""
    }
  }

  // Uma colheita entra no acumulado. Separado do `harvestPlant` porque a
  // migracao de um save antigo chama isto em laco, sobre a lista que existe.
  function creditLifetime(lt, r) {
    lt.grams += r.weight_grams
    lt.quality_sum += r.quality_score
    lt.thc_sum += r.thc_percent
    lt.cbd_sum += r.cbd_percent
    if (r.weight_grams > lt.best_grams) {
      lt.best_grams = r.weight_grams
      lt.best_grams_strain = r.strain_name
    }
    if (r.quality_score > lt.best_quality) {
      lt.best_quality = r.quality_score
      lt.best_quality_strain = r.strain_name
    }
    if (lt.first_at === "") lt.first_at = r.completed_at
    lt.last_at = r.completed_at
    return lt
  }
  property string visualMode: "Normal"
  property string lastTick: ""

  property bool loaded: false
  property bool open: false          // o overlay segue isto, como no zed.quadro

  // ---- idioma --------------------------------------------------------------
  //
  // Vive aqui, e nao no overlay, pelo mesmo motivo do tamanho de janela: e
  // preferencia, e preferencia que volta ao padrao a cada boot nao e
  // preferencia. O primeiro valor vem do locale do sistema; dali em diante
  // manda o save.
  //
  // Todo texto da tela passa por `t()`. A barra chama, o overlay chama e o IPC
  // chama - tres arquivos, uma tabela, e nenhum lugar onde uma frase possa
  // ficar na lingua antiga sem ninguem notar.
  property string lang: I18n.fromLocale(Quickshell.env("LANG") || Qt.locale().name)

  function t(key) { return I18n.t(root.lang, key) }
  function tf(key, a, b, c, d, e) { return I18n.tf(root.lang, key, a, b, c, d, e) }
  function num(value, digits) { return I18n.num(root.lang, value, digits) }
  function term(field, value) { return I18n.term(root.lang, field, value) }
  function terms(field, list) { return I18n.terms(root.lang, field, list) }
  function plural(n, one, many) { return I18n.plural(root.lang, n, one, many) }

  function setLang(code) {
    if (!I18n.known(code) || code === root.lang) return root.lang
    root.lang = code
    root.save()
    return root.lang
  }

  function cycleLang() { return root.setLang(I18n.nextLang(root.lang)) }

  // ---- parada --------------------------------------------------------------
  //
  // Parada, o plugin nao custa nada: o Timer de 60 s nao corre, o overlay nao
  // pede quadro nenhum e o ponto de alerta nao pulsa. Nao e "pausa" no sentido
  // de esperar - e desligar o relogio e deixar a planta exatamente onde esta,
  // pelo tempo que a pessoa quiser.
  //
  // Isto VAI para o save, ao contrario do turbo e da demonstracao. Os dois
  // rapidos se desligam sozinhos porque deixados ligados queimam a planta sem
  // ninguem ver; a parada e o oposto: ela nao gasta nada e nao perde nada, e
  // quem desligou o relogio quer encontra-lo desligado amanha.
  property bool paused: false

  function setPaused(v) {
    if (v === root.paused) return root.paused
    root.paused = v
    if (v) {
      // Um ritmo de 130000x atras de um relogio parado seria uma contradicao
      // que so apareceria na conta do CPU.
      root.stopFast()
      root.turbo = false
    }
    // Sem isto o primeiro tick depois de retomar cobriria o intervalo inteiro
    // em que a planta estava parada - que e justamente o que parar evita. O
    // limite de dois intervalos do `tick` reduz o estrago, nao o elimina.
    root.lastTickMs = Date.now()
    root.save()
    return root.paused
  }

  function togglePause() { return root.setPaused(!root.paused) }

  // Modo automatico: a planta se cuida sozinha, com os mesmos limiares do TUI.
  // Desligado por padrao - ver DIVERGE 3 - e ligado com `a` no overlay.
  property bool autoCare: false

  // Turbo: a planta DE VERDADE rodando no fator do TUI. Escreve no save, as
  // colheitas contam, e o que acontecer aqui aconteceu.
  //
  // **Vai para o save, e sobrevive a fechar a sala e a reiniciar o shell.**
  //
  // Isto foi decidido ao contrario primeiro, e o argumento de la era: um ritmo
  // que queima um ciclo por minuto e coisa que se faz olhando, e se sobrevivesse
  // a janela fechada a planta iria embora sem ninguem ver. O argumento estava
  // certo sobre o risco e errado sobre de quem e a escolha. Quem roda em turbo
  // por padrao - e e o caso do autor - tinha que religar em toda sessao, e um
  // ajuste que volta ao padrao sozinho nao e ajuste, e uma pergunta repetida.
  //
  // O risco continua existindo e continua avisado: cabecalho vermelho com
  // "·· TURBO 130000x ··" sempre que esta ligado. E o que ele custa esta
  // documentado no README: com a sala fechada, uma colheita por minuto, e o
  // historico (que guarda 100) roda inteiro em uma hora e quarenta.
  property bool turbo: false

  function toggleTurbo() {
    // Ligar um ritmo rapido com o relogio parado nao teria efeito nenhum, e a
    // leitura obvia de "nao aconteceu nada" e que o turbo esta quebrado.
    if (!root.turbo && root.paused) root.setPaused(false)
    root.turbo = !root.turbo
    root.lastTickMs = Date.now()   // sem isto o primeiro passo cobre o intervalo inteiro
    root.save()                    // nos dois sentidos: e preferencia agora
    return root.turbo
  }

  // Tamanho e tipo da janela do overlay: full, large, medium, small, window.
  // Mora aqui, e nao no overlay, porque tem que sobreviver ao save como
  // qualquer outra preferencia.
  //
  // O id e em ingles e nao muda com o idioma - o rotulo na tela e que se
  // traduz. Um save que gravasse "médio" trocaria de forma junto com a lingua,
  // e um arquivo escrito em portugues nao abriria em ingles. Os ids antigos
  // (cheio, grande, ...) continuam sendo aceitos: ver `canonWindowMode`.
  property string windowMode: "full"

  // espelho para a UI
  property string stage: "Seedling"
  // Este nao e espelho: e derivado do estagio E do idioma, e um espelho
  // atualizado pelo `publish()` ficaria na lingua antiga ate o proximo tick.
  readonly property string stageLabel: I18n.stage(root.lang, root.stage)
  property string strainName: ""
  property int day: 1
  property real water: 60
  property real nutrients: 60
  property string health: "Excellent"
  property real temperature: 24
  property real humidity: 60
  property real rootDevelopment: 10
  property real canopyDensity: 5
  property real co2: 80
  property real lightAbsorption: 50
  property string seedHex: "0000000000000000"

  readonly property bool ready: root.stage === "ReadyToHarvest"
  readonly property bool thirsty: root.water < 20
  readonly property bool hungry: root.nutrients < 20
  // No modo automatico o ponto so acende para a colheita: avisar de sede uma
  // planta que se rega sozinha e pedir uma acao que nao existe.
  //
  // Parada, o ponto nao acende de jeito nenhum. Nada esta piorando - a agua nao
  // baixa, o dia nao passa, a colheita nao vai embora - e um ponto pulsando
  // pediria pressa por uma planta congelada. Alem disso e a ultima animacao que
  // sobrava acordada: sem ela, parada e parada.
  readonly property bool alerting: !root.paused
    && (root.ready || (!root.autoCare && (root.thirsty || root.hungry)))

  signal watered()
  signal fed()
  signal harvested(var result)

  // ---- modo demonstracao ---------------------------------------------------
  // Segurar `f` no overlay roda no fator original do TUI. Simula em cima de uma
  // copia: o save nao ve nada disso, e soltar a tecla devolve a planta onde ela
  // estava. E o que se grava para mostrar o plugin a alguem.
  property var fastPlant: null
  readonly property bool fast: root.fastPlant !== null
  readonly property var viewPlant: root.fastPlant !== null ? root.fastPlant : root.plant

  function startFast() {
    if (!root.plant) return
    if (root.paused) root.setPaused(false)
    root.fastPlant = JSON.parse(JSON.stringify(root.plant))
  }
  function stopFast() { root.fastPlant = null; root.publish() }
  function fastStep(seconds) {
    if (!root.fastPlant) return
    root.advance(root.fastPlant, (seconds / 3600.0) * 130000.0, true)
    root.publish()
  }

  // ---- relogio -------------------------------------------------------------

  property double lastTickMs: 0
  property double lastSaveMs: 0

  // Um timer, 60 s, aritmetica pura. A 40x cada tick avanca 0,67 hora de jogo -
  // resolucao de sobra para um icone que mostra estagio e um ponto de alerta.
  // No turbo o mesmo timer bate a cada 100 ms. Nao e capricho: a 130000x, um
  // tique de sessenta segundos avancaria 2160 horas de jogo - o ciclo inteiro
  // de uma vez, sem nada para ver. A 100 ms sao 3,6 horas por passo, que e o
  // ciclo completo em 60 segundos, exatamente como o TUI.
  // Parada, o Timer nao corre. E a diferenca entre "quase nada" e nada: um
  // Timer de 60 s e barato, mas nao e zero, e a promessa do `p` e zero.
  Timer {
    interval: root.turbo ? 100 : 60000
    running: root.loaded && !root.paused
    repeat: true
    triggeredOnStart: false
    onTriggered: root.tick()
  }

  function tick() {
    if (!root.plant) return
    var now = Date.now()
    // DIVERGE 1 (SPEC 4b): o relogio e de sessao, nao de parede. O delta e
    // medido de verdade para o tick nao ficar devendo quando o sistema atrasa o
    // timer, mas e limitado a dois intervalos: se a maquina dormiu tres dias, a
    // planta dormiu junto. `last_tick` do save NUNCA e usado para avancar nada.
    var step = root.turbo ? 100 : 60000
    var delta = root.lastTickMs > 0 ? Math.min(now - root.lastTickMs, step * 2) : step
    root.lastTickMs = now

    var beforeStage = root.plant.stage
    var scale = root.turbo ? root.turboScale : root.scale
    root.advance(root.plant, (delta / 1000.0 / 3600.0) * scale, false)
    root.publish()

    // Grava quando o estagio vira (e um marco que doi perder) e, fora isso, no
    // maximo uma vez a cada dez minutos. A SPEC pede escrita so em acao do
    // usuario; sem isto um shell que reinicia sem descarregar direito perde as
    // horas acumuladas, que e o unico bem que esta planta tem.
    // No turbo o estagio vira a cada poucos segundos; gravar em cada virada
    // seriam cinco escritas por minuto para um estado que muda de novo em
    // seguida. O que interessa gravar la e o fim: `toggleTurbo` grava ao
    // desligar, e a regra dos dez minutos continua valendo para os dois.
    if (!root.turbo && root.plant.stage !== beforeStage) root.save()
    else if (now - root.lastSaveMs > 600000) root.save()
  }

  // ---- simulacao -----------------------------------------------------------
  // Porta de App::update_time (src/app.rs:100).

  function advance(p, hours, isFast) {
    if (!p || hours <= 0) return

    p.total_hours_elapsed += hours

    // DIVERGE 2: o TUI faz `days_alive = total_hours / 24`, o que da dia 0 no
    // comeco - e `calculate_stage(0)` cai no ramo `_`, ou seja "pronta para
    // colher". La isso dura meio segundo e ninguem ve. A 40x duraria 36
    // minutos, com um broto anunciando colheita. O piso e 1, que e o mesmo
    // valor com que Plant::new_random nasce.
    p.days_alive = Math.max(1, Math.floor(p.total_hours_elapsed / 24.0))

    var waterDrain = p.stage === "Vegetative" ? 1.0 : (p.stage === "Flowering" ? 0.8 : 0.5)
    p.water_level = Math.max(p.water_level - waterDrain * root.careScale * hours, 0.0)

    var nutrientDrain = p.stage === "Vegetative" ? 0.8 : (p.stage === "Flowering" ? 1.0 : 0.4)
    p.nutrient_level = Math.max(p.nutrient_level - nutrientDrain * root.careScale * hours, 0.0)

    // DIVERGE 3: o auto-cuidado do TUI nao esta ligado por padrao. La a planta
    // se cuida sozinha porque a ideia e assistir; aqui regar e a unica coisa que
    // voce faz, e uma planta que se rega sozinha faz do `w` um botao que nao
    // liga nada.
    //
    // Mas continua existindo, com os limiares e os valores exatos de
    // src/app.rs:128, atras do `a`: quem quer so olhar a planta crescer liga o
    // modo automatico e nunca mais pensa em agua. Note que o teto do TUI e
    // generoso mas nunca afoga - 40+50 e 50+40 param antes dos 95 que
    // `calculate_health` considera critico.
    if (root.autoCare) {
      if (p.water_level < 40.0) p.water_level = Math.min(p.water_level + 50.0, 100.0)
      if (p.nutrient_level < 50.0) p.nutrient_level = Math.min(p.nutrient_level + 40.0, 100.0)
    }

    p.co2_level = Math.min(80.0 + p.canopy_density * 0.2, 100.0)

    var lightBase = (p.stage === "Vegetative") ? 60.0
      : (p.stage === "PreFlower") ? 75.0
      : (p.stage === "Flowering" || p.stage === "ReadyToHarvest") ? 85.0 : 40.0
    p.light_absorption = Math.min(lightBase + p.canopy_density * 0.1, 100.0)

    var tempVariation = Math.sin(p.days_alive * 0.7) * 2.0
    p.temperature = Math.min(Math.max(24.0 + tempVariation, 20.0), 28.0)

    p.humidity = Math.min(50.0 + p.water_level * 0.2, 80.0)
    p.root_development = Math.min(p.days_alive / 90.0 * 100.0, 100.0)

    var canopyBase
    switch (p.stage) {
    case "Seed": case "Germination": canopyBase = 5.0; break
    case "Seedling": canopyBase = 15.0 * p.genetics.growth_rate; break
    case "Vegetative": canopyBase = (40.0 + p.days_alive * 0.8) * p.genetics.growth_rate; break
    case "PreFlower": canopyBase = (60.0 + p.days_alive * 0.6) * p.genetics.growth_rate; break
    default: canopyBase = (80.0 + p.days_alive * 0.2) * p.genetics.growth_rate
    }
    p.canopy_density = Math.min(canopyBase, 100.0)

    p.stage = root.stageFor(p.days_alive)

    if (p.days_alive >= 45 && p.light_cycle === "Veg18_6") p.light_cycle = "Flower12_12"

    p.health = root.healthFor(p.water_level, p.nutrient_level)

    // Resiliencia genetica amortece o efeito de saude ruim no crescimento.
    var hm
    switch (p.health) {
    case "Excellent": case "Good": hm = 1.0; break
    case "Fair": hm = 0.85 + p.genetics.resilience * 0.15; break
    case "Poor": hm = 0.65 + p.genetics.resilience * 0.35; break
    default: hm = 0.4 + p.genetics.resilience * 0.6
    }
    p.canopy_density *= hm

    var ch = p.care_history
    if (p.water_level >= 40.0 && p.water_level <= 80.0) ch.total_optimal_water_hours += hours
    if (p.nutrient_level >= 50.0 && p.nutrient_level <= 80.0) ch.total_optimal_nutrient_hours += hours
    ch.total_hours += hours

    if (p.water_level < 20.0) root.stress(p, "LowWater", "Moderate")
    if (p.water_level > 90.0) root.stress(p, "HighWater", "Moderate")
    if (p.nutrient_level < 30.0) root.stress(p, "LowNutrients", "Moderate")
    if (p.nutrient_level > 90.0) root.stress(p, "NutrientBurn", "Severe")

    // DIVERGE 4 (SPEC 4): o ciclo nao termina. O `auto_harvest` do TUI e o
    // comportamento unico, nao uma opcao - colheu, planta outra. O que se
    // guarda e o historico.
    if (p.stage === "ReadyToHarvest" && p.days_alive >= 96) root.harvestPlant(p, isFast)
  }

  function stageFor(days) {
    if (days <= 10) return "Seedling"
    if (days <= 40) return "Vegetative"
    if (days <= 48) return "PreFlower"
    if (days <= 85) return "Flowering"
    return "ReadyToHarvest"
  }

  function healthFor(w, n) {
    var wOpt = w >= 40.0 && w <= 80.0
    var nOpt = n >= 50.0 && n <= 80.0
    if (w < 10.0 || w > 95.0 || n < 20.0 || n > 95.0) return "Critical"
    if (!wOpt && !nOpt) return "Poor"
    if (!wOpt || !nOpt) return "Fair"
    if (w >= 50.0 && w <= 70.0 && n >= 60.0 && n <= 75.0) return "Excellent"
    return "Good"
  }

  // has_recent_stress: so registra se nao houve evento da mesma causa nos
  // ultimos cinco dias, olhando os dez ultimos eventos.
  function stress(p, cause, severity) {
    var ev = p.care_history.stress_events
    var from = Math.max(ev.length - 10, 0)
    var floorDay = Math.max(p.days_alive - 5, 0)
    for (var i = ev.length - 1; i >= from; i--)
      if (ev[i].cause === cause && ev[i].day >= floorDay) return
    ev.push({ day: p.days_alive, severity: severity, cause: cause })
  }

  // ---- acoes ---------------------------------------------------------------

  // Regar enche ate o TOPO DA FAIXA OTIMA, nao ate 100.
  //
  // `calculate_health` chama de critica a planta com agua acima de 95 - afogar
  // e tao ruim quanto secar. No TUI isso nunca acontece porque o auto-cuidado
  // so rega abaixo de 40 e soma 50, entao a agua nunca passa de ~90. Aqui quem
  // rega e voce, e dois cliques levariam a 100: a acao obvia, feita duas vezes,
  // deixaria a planta em estado critico sem avisar nada. Um botao que pune quem
  // o aperta esta errado, nao o usuario.
  //
  // O piso preserva um nivel mais alto que ja exista (um save vindo do TUI, por
  // exemplo): regar nunca tira agua.
  readonly property real waterCeiling: 70    // faixa excelente: 50-70
  readonly property real nutrientCeiling: 75 // faixa excelente: 60-75

  function pour(amount) {
    if (!root.plant || root.fast) return
    root.plant.water_level = Math.max(root.plant.water_level,
      Math.min(root.plant.water_level + amount, root.waterCeiling))
    root.plant.health = root.healthFor(root.plant.water_level, root.plant.nutrient_level)
    root.publish(); root.save(); root.watered()
  }

  function feed(amount) {
    if (!root.plant || root.fast) return
    root.plant.nutrient_level = Math.max(root.plant.nutrient_level,
      Math.min(root.plant.nutrient_level + amount, root.nutrientCeiling))
    root.plant.health = root.healthFor(root.plant.water_level, root.plant.nutrient_level)
    root.publish(); root.save(); root.fed()
  }

  function harvestNow() {
    if (!root.plant || root.fast) return false
    if (root.plant.stage !== "ReadyToHarvest") return false
    root.harvestPlant(root.plant, false)
    root.publish(); root.save()
    return true
  }

  function toggleAutoCare() {
    root.autoCare = !root.autoCare
    if (root.autoCare && root.plant) {
      // Ligar o automatico age na hora: esperar o proximo tick para socorrer
      // uma planta em estado critico seria uma espera sem motivo.
      root.advance(root.plant, 0.0001, false)
      root.publish()
    }
    root.save()
    return root.autoCare
  }

  // Os ids em portugues eram os unicos que existiam antes do idioma virar
  // opcao. Aceita-los aqui e o que faz um save antigo (e um script antigo)
  // continuar valendo sem migracao nenhuma.
  readonly property var windowModes: ["full", "large", "medium", "small", "window"]
  readonly property var legacyWindowModes: ({
    "cheio": "full", "grande": "large", "medio": "medium",
    "pequeno": "small", "janela": "window"
  })

  function canonWindowMode(mode) {
    var m = String(mode || "")
    if (root.windowModes.indexOf(m) >= 0) return m
    return root.legacyWindowModes[m] || ""
  }

  function setWindowMode(mode) {
    var m = root.canonWindowMode(mode)
    if (m === "" || m === root.windowMode) return root.windowMode
    root.windowMode = m
    root.save()
    return root.windowMode
  }

  function cycleWindowMode() {
    var i = root.windowModes.indexOf(root.windowMode)
    return root.setWindowMode(root.windowModes[(i + 1) % root.windowModes.length])
  }

  function cycleVisualMode() {
    switch (root.visualMode) {
    case "Normal": root.visualMode = "Zen"; break
    case "Zen": root.visualMode = "Rainbow"; break
    case "Rainbow": root.visualMode = "Matrix"; break
    default: root.visualMode = "Normal"
    }
    root.save()
  }

  // ---- colheita ------------------------------------------------------------
  // HarvestResult::from_plant (src/domain/harvest.rs) + replantio.

  function harvestPlant(p, isFast) {
    var ch = p.care_history
    var waterPct = ch.total_hours === 0 ? 100.0 : (ch.total_optimal_water_hours / ch.total_hours) * 100.0
    var nutrientPct = ch.total_hours === 0 ? 100.0 : (ch.total_optimal_nutrient_hours / ch.total_hours) * 100.0
    var careQuality = Math.max((waterPct + nutrientPct) / 200.0, 0.7)
    var stressPenalty = Math.min(ch.stress_events.length * 0.02, 0.3)

    var quality = Math.min(Math.max(careQuality * 100.0 * (1.0 - stressPenalty), 0.0), 100.0)
    var mult = 0.7 + (quality / 100.0) * 0.3

    var result = {
      strain_name: p.strain_name,
      harvest_day: p.days_alive,
      completed_at: new Date().toISOString(),
      weight_grams: p.genetics.yield_potential * careQuality * (1.0 - stressPenalty),
      quality_score: quality,
      thc_percent: p.genetics.thc_percent * mult,
      cbd_percent: p.genetics.cbd_percent * mult,
      // Extras do plugin: o que a aba de colheitas mostra e o TUI nao guarda.
      // Campos a mais nao incomodam o serde do Rust (ele ignora o que nao
      // conhece), entao o arquivo continua sendo o mesmo formato.
      stress_events: ch.stress_events.length,
      seed: root.seedOf(p)
    }

    var fresh = root.newPlant()

    if (isFast) {
      // Demonstracao: o resultado nao entra no historico nem no save. A copia
      // replanta para que segurar `f` mostre o ciclo inteiro, e nao so o fim.
      for (var k in fresh) p[k] = fresh[k]
      return
    }

    // O acumulado primeiro: ele e o que sobrevive ao teto da lista.
    var lt = root.lifetime ? JSON.parse(JSON.stringify(root.lifetime)) : root.newLifetime()
    root.lifetime = root.creditLifetime(lt, result)

    var list = root.harvests.slice()
    list.push(result)
    // Cem colheitas e o teto. Um save que cresce para sempre e um vazamento com
    // outro nome; a decima colheita ja tem dez historias atras dela.
    while (list.length > 100) list.shift()
    root.harvests = list
    root.totalHarvests += 1
    root.plant = fresh
    root.harvested(result)
  }

  // ---- planta nova ---------------------------------------------------------
  // Plant::new_random + Genetics::random.

  function rand(min, max) { return min + Math.random() * (max - min) }

  function uuid() {
    var h = "0123456789abcdef"
    var s = ""
    for (var i = 0; i < 32; i++) {
      var d
      if (i === 12) d = 4                                     // versao 4
      else if (i === 16) d = 8 + Math.floor(Math.random() * 4) // variante
      else d = Math.floor(Math.random() * 16)
      s += h.charAt(d)
      if (i === 7 || i === 11 || i === 15 || i === 19) s += "-"
    }
    return s
  }

  function newPlant() {
    var strain = Strains.STRAINS[Math.floor(Math.random() * Strains.STRAINS.length)]

    var yieldBase = strain.yield_potential === "High" ? root.rand(100, 150)
      : strain.yield_potential === "Medium" ? root.rand(70, 110)
      : strain.yield_potential === "Low" ? root.rand(50, 80) : root.rand(50, 150)

    var resilience = strain.difficulty === "Easy" ? root.rand(0.7, 1.0)
      : strain.difficulty === "Medium" ? root.rand(0.4, 0.7)
      : strain.difficulty === "Hard" ? root.rand(0.0, 0.4) : root.rand(0.0, 1.0)

    var quality = (strain.type === "Sativa" || strain.type === "Indica") ? root.rand(80, 100)
      : strain.type === "Hybrid" ? root.rand(85, 100) : root.rand(70, 100)

    return {
      id: root.uuid(),
      strain_name: strain.name,
      stage: "Seedling",
      planted_at: new Date().toISOString(),
      // DIVERGE 5: a planta nasce no dia 5, nao no dia 1.
      //
      // O tronco so aparece quando `day * growth_rate >= 1`, e growth_rate e
      // 0,22 a 0,25 - ou seja, dos dias 1 ao 4 a arte e um vaso com terra e mais
      // nada. No TUI isso dura tres segundos e ninguem chega a ver. A 40x dura
      // tres horas, e sao justamente as tres primeiras horas depois de instalar
      // o plugin: o overlay estreia com uma caixa vazia e parece quebrado.
      days_alive: 5,
      total_hours_elapsed: 5 * 24.0,
      water_level: 60.0,
      nutrient_level: 60.0,
      light_cycle: "Veg18_6",
      health: "Excellent",
      genetics: {
        yield_potential: yieldBase,
        growth_rate: root.rand(0.9, 1.1),
        resilience: resilience,
        quality_ceiling: quality,
        strain_info: JSON.parse(JSON.stringify(strain)),
        thc_percent: root.rand(strain.thc_min, strain.thc_max),
        cbd_percent: root.rand(strain.cbd_min, strain.cbd_max)
      },
      care_history: {
        total_hours: 0.0,
        total_optimal_water_hours: 0.0,
        total_optimal_nutrient_hours: 0.0,
        water_optimal_percentage: 100.0,
        nutrient_optimal_percentage: 100.0,
        light_cycle_correct: true,
        stress_events: []
      },
      co2_level: 80.0,
      light_absorption: 50.0,
      temperature: 24.0,
      humidity: 60.0,
      root_development: 10.0,
      canopy_density: 5.0
    }
  }

  // O seed da arte e `plant.id.as_u128() as u64` (growing.rs:105): os 64 bits
  // baixos do uuid, ou seja os 16 ultimos digitos hexadecimais.
  function seedOf(p) {
    if (!p || !p.id) return "0000000000000000"
    var h = String(p.id).replace(/[^0-9a-fA-F]/g, "")
    while (h.length < 16) h = "0" + h
    return h.substring(h.length - 16).toLowerCase()
  }

  // ---- espelho para a UI ---------------------------------------------------

  function publish() {
    var p = root.viewPlant
    if (!p) return
    root.stage = p.stage
    root.strainName = p.strain_name
    root.day = p.days_alive
    root.water = p.water_level
    root.nutrients = p.nutrient_level
    root.health = p.health
    root.temperature = p.temperature
    root.humidity = p.humidity
    root.rootDevelopment = p.root_development
    root.canopyDensity = p.canopy_density
    root.co2 = p.co2_level
    root.lightAbsorption = p.light_absorption
    root.seedHex = root.seedOf(p)
  }

  // ---- persistencia --------------------------------------------------------
  // Formato: os mesmos campos da serializacao serde de App (src/app.rs), em
  // arquivo proprio. Copiar este save por cima do ~/.local/share/ganjatui/
  // save.json leva a planta para o TUI e vice-versa.

  function snapshot() {
    return {
      current_plant: root.plant,
      harvest_history: root.harvests,
      last_tick: new Date().toISOString(),
      total_harvests: root.totalHarvests,
      // No TUI isto e uma opcao; aqui e o comportamento, e gravar true mantem
      // os dois lados de acordo se alguem abrir o save no TUI.
      auto_harvest: true,
      visual_mode: root.visualMode,
      // Campos so do plugin. O serde do Rust ignora o que nao conhece, entao o
      // arquivo continua sendo o mesmo formato do TUI.
      auto_care: root.autoCare,
      window_mode: root.windowMode,
      language: root.lang,
      // O turbo e preferencia como qualquer outra. A demonstracao (`fast`) nao
      // esta aqui e nao pode estar: ela e definida como "nada disto conta" e
      // roda sobre uma copia que o desligar joga fora - gravar seria gravar a
      // intencao de simular um descartavel no proximo boot.
      turbo: root.turbo,
      time_scale: root.userScale,
      lifetime: root.lifetime,
      // `paused` fica de fora do que o TUI entende de proposito: la o relogio e
      // de parede e nao existe "parado". Levar o save para o TUI com a planta
      // parada nao a deixa parada - o TUI vai andar, como sempre andou.
      paused: root.paused
    }
  }

  // O acumulado de um save que nao tinha acumulado.
  //
  // Somar a lista que esta ali e a unica conta honesta possivel: quem colheu 39
  // vezes com o teto de 100 tem as 39 no arquivo, e o acumulado sai exato. Para
  // quem passou das 100 o numero nasce menor que a verdade, e isso e melhor que
  // nascer zero - e a partir dali cresce certo, que e o ponto.
  function adoptLifetime(data) {
    if (data.lifetime && typeof data.lifetime === "object") {
      var lt = root.newLifetime()
      for (var k in lt)
        if (data.lifetime[k] !== undefined) lt[k] = data.lifetime[k]
      return lt
    }
    var seed = root.newLifetime()
    var list = Array.isArray(data.harvest_history) ? data.harvest_history : []
    for (var i = 0; i < list.length; i++) {
      var r = list[i]
      if (r && typeof r.weight_grams === "number") root.creditLifetime(seed, r)
    }
    return seed
  }

  function adopt(data, fromDisk) {
    if (!data || !data.current_plant) return false
    root.plant = data.current_plant
    root.harvests = Array.isArray(data.harvest_history) ? data.harvest_history : []
    root.totalHarvests = data.total_harvests || 0
    root.userScale = Number(data.time_scale) > 0 ? Number(data.time_scale) : 0
    root.lifetime = root.adoptLifetime(data)
    root.visualMode = data.visual_mode || "Normal"
    root.autoCare = data.auto_care === true
    root.windowMode = root.canonWindowMode(data.window_mode) || "full"
    root.paused = data.paused === true
    // Parada manda: os dois nunca sao verdade ao mesmo tempo (`setPaused`
    // desliga o turbo), e um save costurado a mao poderia dizer que sao.
    root.turbo = data.turbo === true && !root.paused
    // Save sem idioma e save de antes desta opcao existir (ou vindo do TUI):
    // fica o que o locale pediu, que e o default do proprio `lang`.
    if (I18n.known(data.language)) root.lang = data.language
    root.lastTick = data.last_tick || ""

    // Saves antigos (ou do TUI) podem nao ter tudo. Preencher em vez de quebrar.
    var p = root.plant
    if (p.total_hours_elapsed === undefined) p.total_hours_elapsed = (p.days_alive || 1) * 24
    if (p.days_alive === undefined) p.days_alive = Math.max(1, Math.floor(p.total_hours_elapsed / 24))
    if (!p.care_history) p.care_history = root.newPlant().care_history
    if (!p.care_history.stress_events) p.care_history.stress_events = []
    if (p.care_history.total_hours === undefined) p.care_history.total_hours = 0
    if (p.care_history.total_optimal_water_hours === undefined) p.care_history.total_optimal_water_hours = 0
    if (p.care_history.total_optimal_nutrient_hours === undefined) p.care_history.total_optimal_nutrient_hours = 0
    if (!p.stage) p.stage = root.stageFor(p.days_alive)
    if (!p.health) p.health = root.healthFor(p.water_level, p.nutrient_level)

    root.publish()
    return true
  }

  Process {
    id: reader
    running: true
    // O `#legacy` na frente diz de qual dos dois arquivos veio o JSON. Sem essa
    // marca, a unica forma de saber seria um segundo processo perguntando ao
    // disco - e um boot que grava sempre, para o caso de ter migrado, cobraria
    // de todo mundo uma escrita que interessa a uma pessoa uma vez na vida.
    command: ["/usr/bin/python3", "-I", root.helper, "read", root.relDir, root.relLegacy]
    clearEnvironment: true
    environment: root.helperEnv
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var raw = String(text).trim()
        var migrated = false
        if (raw.indexOf("#legacy") === 0) {
          migrated = true
          raw = raw.substring(raw.indexOf("\n") + 1).trim()
        }
        var ok = false
        if (raw !== "") {
          try { ok = root.adopt(JSON.parse(raw), true) }
          catch (e) { console.warn("zed.ganja: save ilegivel, comecando de novo:", e) }
        }
        if (!ok) {
          root.plant = root.newPlant()
          root.publish()
          root.save()
        } else if (migrated) {
          // A migracao tem que sobreviver ao proximo boot: sem esta gravacao, o
          // save novo so apareceria na primeira acao do usuario, e ate la todo
          // boot releria o antigo e perderia o que aconteceu no anterior.
          root.save()
        }
        root.lastTickMs = Date.now()
        root.loaded = true
      }
    }
  }

  // Releitura ao abrir o overlay. Duas instancias do shell nao se resolvem com
  // lock: quem escreveu por ultimo ganha, e a unica hora em que vale a pena
  // perguntar ao disco e quando alguem vai olhar.
  //
  // Nao existe tecla para isto, e existia: o `r` saiu porque abrir a sala ja
  // rele. A unica coisa que ele cobria era o save mudar COM a sala aberta - o
  // TUI rodando ao lado, ou outra instancia do shell gravando - e para isso
  // fechar e abrir faz o mesmo, sem gastar uma letra na linha de atalhos nem uma
  // linha na tabela de teclas do README.
  Process {
    id: rereader
    // Sem o caminho antigo: migrar e coisa de uma vez, na carga.
    command: ["/usr/bin/python3", "-I", root.helper, "read", root.relDir]
    clearEnvironment: true
    environment: root.helperEnv
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var raw = String(text).trim()
        if (raw === "") return
        try {
          var data = JSON.parse(raw)
          var theirs = Date.parse(data.last_tick || "")
          var ours = Date.parse(root.lastTick || "")
          if (isFinite(theirs) && (!isFinite(ours) || theirs > ours)) root.adopt(data, true)
        } catch (e) { /* save sendo escrito neste instante; o mv resolve */ }
      }
    }
  }

  function reread() { if (!rereader.running) rereader.running = true }

  // Escrita atomica: o conteudo vai por stdin para um `.tmp` no mesmo
  // diretorio e so entao um `mv`. Escrever por cima do arquivo direto deixa uma
  // janela em que o TUI (ou a outra instancia do shell) le um JSON pela metade.
  property string pending: ""
  property bool dirty: false

  Process {
    id: writer
    stdinEnabled: true
    // O temporario tem nome aleatorio e e criado com O_CREAT|O_EXCL|O_NOFOLLOW
    // relativo ao descritor do diretorio - o `save.json.$$.tmp` de antes era
    // previsivel, e um symlink pre-posicionado ali fazia a gravacao sair em
    // outro lugar. O nome aleatorio tambem resolve o que o PID resolvia: duas
    // instancias do shell nunca escolhem o mesmo arquivo.
    command: ["/usr/bin/python3", "-I", root.helper, "write", root.relDir]
    clearEnvironment: true
    environment: root.helperEnv
    onStarted: {
      writer.write(root.pending)
      // Isto e o que fecha o stdin, e por isso `flush()` reabre antes de cada
      // rodada: atribuir `false` ao que ja e `false` nao e transicao, nao emite
      // nada e o pipe fica aberto. A segunda gravacao entao chega inteira ao
      // `.tmp`, o `cat` nunca ve o EOF, o `mv` nunca roda, e o save para no
      // tempo - com o arquivo certo em disco, com o nome errado.
      writer.stdinEnabled = false
    }
    onExited: {
      if (root.dirty) { root.dirty = false; root.flush() }
    }
  }

  function flush() {
    writer.stdinEnabled = true
    writer.running = true
  }

  function save() {
    if (root.fast) return          // a demonstracao nunca escreve
    if (!root.plant) return
    var snap = root.snapshot()
    root.lastTick = snap.last_tick
    root.pending = JSON.stringify(snap)
    root.lastSaveMs = Date.now()
    // Uma escrita em voo: marca e deixa o onExited pegar. Chamar de novo agora
    // abortaria o `cat` no meio.
    if (writer.running) root.dirty = true
    else root.flush()
  }

  Component.onDestruction: {
    if (root.loaded && root.plant && !root.fast) {
      // Sincrono de proposito: o processo esta indo embora e um Process
      // assincrono nao sobrevive para escrever.
      // `writenow` em vez de `write` porque processo destacado nao tem stdin
      // para receber o conteudo; ele vai como argumento. O resto - o descritor
      // preso, os cheques, o fsync, o renameat - e exatamente o mesmo caminho do
      // escritor normal, porque duplicar a gravacao e como um dos dois lados
      // fica para tras.
      var snap = JSON.stringify(root.snapshot())
      root.shutdownContext = root.detachedContext(
        ["/usr/bin/python3", "-I", root.helper, "writenow", root.relDir, snap])
      Quickshell.execDetached(root.shutdownContext)
    }
  }
}
