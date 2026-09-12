import QtQuick
import Quickshell
import qs.Commons
import "Art.js" as Art
import "I18n.js" as I18n
import "Palette.js" as Palette

// O conteudo da growing room, sem a janela em volta.
//
// Existe separado porque o overlay pode aparecer de duas formas: como camada
// sobre a tela (o PanelWindow do layer-shell, em cheio/grande/medio/pequeno) ou
// como janela de verdade, que o Hyprland arruma junto com as outras. O que se
// ve por dentro e o mesmo nos dois casos, e duplicar isso seria garantir que
// um dos dois ficaria para tras na proxima mudanca.
//
// `ui` e o Ganja.qml: dele vem o quadro da animacao, a paleta, o estado da
// aba e as funcoes derivadas. `active` diz se este exemplar e o que esta na
// tela - com dois monitores existem dois, e so um deve pedir repintura.
Item {
  id: room

  required property var ui
  property bool active: true

  // `framed` e a diferenca visual entre os modos: em cheio a sala e a tela
  // inteira e nao precisa de moldura; nos outros ela e um cartao sobre o que
  // estava ali antes, e um cartao sem borda nao se le como cartao.
  property bool framed: false

  // Em tamanho pequeno nao cabe tudo. O que sai primeiro e o painel do strain
  // (que e leitura, nao acompanhamento), depois as linhas de medidor que menos
  // mudam. A planta nunca sai: e ela o motivo da janela existir.
  readonly property bool wide: room.width >= 900
  readonly property bool tall: room.height >= 560
  readonly property bool veryTall: room.height >= 640
  readonly property int pad: room.width >= 900 ? 26 : 16
  // ---- medidor -------------------------------------------------------------
  // O Gauge do ratatui: um bloco com titulo na borda, a barra preenchida ate a
  // porcentagem e o rotulo centralizado por cima.
  component Meter: Item {
    id: meter
    property string title: ""
    property real value: 0          // 0-100
    property string label: ""
    property color fill: "#888888"
    implicitHeight: 44

    Rectangle {
      anchors.fill: parent
      color: "transparent"
      border.width: 1
      border.color: room.ui.rule
      radius: 2
    }

    Rectangle {
      anchors { left: parent.left; top: parent.top; leftMargin: 9; topMargin: -1 }
      width: titleText.implicitWidth + 8
      height: 2
      color: "#0b0d0b"
    }
    Text {
      id: titleText
      anchors { left: parent.left; leftMargin: 13; verticalCenter: parent.top }
      text: meter.title
      color: room.ui.inkDim
      font.family: room.ui.mono
      font.pixelSize: 11
    }

    Item {
      anchors { fill: parent; margins: 9; topMargin: 14 }

      Rectangle {
        anchors.fill: parent
        radius: 2
        color: Qt.rgba(1, 1, 1, 0.05)
      }
      Rectangle {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: parent.width * Math.min(Math.max(meter.value, 0), 100) / 100
        radius: 2
        color: meter.fill
        opacity: 0.85
        Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutQuad } }
      }
      // O rotulo fica centralizado na pista inteira e troca de cor onde a barra
      // passa por baixo dele, como o Gauge do ratatui faz com a inversao de
      // atributo. Uma cor so nao serve: clara some no cheio, escura some no
      // vazio, e o valor fica ilegivel exatamente na metade das vezes.
      Item {
        id: track
        anchors.fill: parent
        readonly property real fillW: parent.width * Math.min(Math.max(meter.value, 0), 100) / 100

        Item {
          width: track.fillW
          height: track.height
          clip: true
          Text {
            x: (track.width - implicitWidth) / 2
            y: (track.height - implicitHeight) / 2
            text: meter.label
            color: "#0b0d0b"
            font.family: room.ui.mono
            font.pixelSize: 11
            font.weight: Font.DemiBold
          }
        }
        Item {
          x: track.fillW
          width: track.width - track.fillW
          height: track.height
          clip: true
          Text {
            x: (track.width - implicitWidth) / 2 - parent.x
            y: (track.height - implicitHeight) / 2
            text: meter.label
            color: room.ui.ink
            font.family: room.ui.mono
            font.pixelSize: 11
            font.weight: Font.DemiBold
          }
        }
      }
    }
  }

  component Section: Item {
    id: sec
    property string title: ""
    default property alias content: inner.data

    // A altura sai do conteudo, e o conteudo mora num Item - que NAO calcula
    // tamanho implicito a partir dos filhos. `inner.implicitHeight` era zero, a
    // moldura fechava logo abaixo do titulo e o texto inteiro caia para fora
    // dela, ainda por cima cortado embaixo pelo clip do Flickable. Quem sabe o
    // tamanho real do que esta la dentro e `childrenRect`.
    implicitHeight: inner.height + 30

    Rectangle {
      anchors.fill: parent
      color: "transparent"
      border.width: 1
      border.color: room.ui.rule
      radius: 2
    }
    Rectangle {
      anchors { left: parent.left; top: parent.top; leftMargin: 9; topMargin: -1 }
      width: secTitle.implicitWidth + 8
      height: 2
      color: "#0b0d0b"
    }
    Text {
      id: secTitle
      anchors { left: parent.left; leftMargin: 13; verticalCenter: parent.top }
      text: sec.title
      color: room.ui.inkDim
      font.family: room.ui.mono
      font.pixelSize: 11
    }
    Item {
      id: inner
      // Sem `fill`: a altura precisa vir de baixo para cima, do conteudo para a
      // moldura. Ancorar no fundo faria o contrario e fecharia o laco.
      anchors {
        left: parent.left; right: parent.right; top: parent.top
        leftMargin: 14; rightMargin: 14; topMargin: 16
      }
      height: childrenRect.height
    }
  }

  clip: room.framed

  // Com dois monitores existem dois exemplares da sala e so um pede repintura.
  // Quando o foco troca, o que acabou de virar o da tela precisa pintar uma vez
  // por conta propria: se o relogio estiver parado, ninguem mais vai pedir.
  onActiveChanged: if (room.active) plantCanvas.requestPaint()

  // O fundo da sala. Em cheio e a tela; nos outros modos e um cartao, e o
  // arredondamento com a borda e o que faz o olho ler "janela" em vez de
  // "pedaco de tela escurecido".
  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(0.043, 0.051, 0.043, room.framed ? 0.995 : 0.99)
    radius: room.framed ? 10 : 0
    border.width: room.framed ? 1 : 0
    border.color: room.ui.rule
  }

  // ---- cabecalho ----
  Text {
    id: header
    anchors { top: parent.top; left: parent.left; topMargin: room.pad; leftMargin: room.pad + 4 }
    text: {
      var d = Art.borderDecoration(room.ui.frame)
      var speed = (room.ui.frame % 4 < 2) ? ">" : "<"
      var head = d + " GANJA  ·  " + Grow.tf("room.day", Grow.day) + "  ·  " + Grow.stageLabel
      if (room.wide) head += "  ·  " + I18n.mode(Grow.lang, Grow.visualMode)
      head += "  " + d + " " + speed
      if (Grow.autoCare) head += "   " + Grow.t("room.auto")
      // Parada vem antes dos dois rapidos porque ela desliga os dois: quem
      // manda no relogio aparece primeiro, e nao ha estado em que duas destas
      // tres etiquetas sejam verdade ao mesmo tempo.
      if (Grow.paused) head += "   " + Grow.t("room.pausedTag")
      else if (Grow.turbo) head += "   " + Grow.t("room.turboTag")
      else if (Grow.fast) head += "   " + Grow.t("room.demoTag")
      return head
    }
    // Tres cores para tres riscos, e o terceiro e risco nenhum: a demonstracao
    // e ambar porque nada do que ela faz conta, o turbo e vermelho porque tudo
    // conta, e a parada apaga para o tom do rodape - o cabecalho de uma sala
    // parada nao devia ser a coisa mais acesa da tela.
    color: Grow.paused ? room.ui.inkDim
         : Grow.turbo ? "#ff7b6e"
         : (Grow.fast ? "#ffd166" : room.ui.inkBright)
    font.family: room.ui.mono
    font.pixelSize: 13
    font.weight: Font.DemiBold
  }

  Text {
    anchors { top: header.top; right: parent.right; rightMargin: room.pad + 4 }
    visible: room.width >= 620
    // O cabecalho ja escreve "·· TURBO 130000x ··" e "·· demonstracao ··".
    // Repetir a palavra aqui gastava a unica linha que tem espaco para dizer o
    // que ela SIGNIFICA - que e a diferenca entre os dois modos e a unica coisa
    // que o jogador precisa saber quando olha para ca.
    text: room.ui.status !== "" ? room.ui.status
        : Grow.paused ? Grow.t("room.pausedMeaning")
        : Grow.turbo ? Grow.t("room.turboMeaning")
        : Grow.fast ? Grow.t("room.demoMeaning")
        : (Grow.ready ? Grow.t("room.readyStatus")
          : Grow.autoCare ? Grow.t("room.autoStatus") : Grow.strainName)
    // Parada, esta linha diz como sair - e a unica instrucao que a sala da sem
    // ninguem pedir, porque e o unico estado em que nada mais vai acontecer ate
    // alguem agir. E o ambar de "pronta para colher" sai: parada, a colheita
    // nao esta esperando, ela esta congelada junto.
    color: room.ui.status !== "" ? room.ui.inkBright
         : (Grow.ready && !Grow.paused ? "#ffd166" : room.ui.inkDim)
    font.family: room.ui.mono
    font.pixelSize: 12
  }

  Rectangle {
    id: topRule
    anchors { top: header.bottom; left: parent.left; right: parent.right; topMargin: 14 }
    height: 1
    color: room.ui.rule
  }

  // ---- corpo ----
  Item {
    id: body
    anchors {
      top: topRule.bottom; bottom: footer.top
      left: parent.left; right: parent.right
      margins: room.pad - 6
    }
    visible: !room.ui.showHarvests

    // coluna da direita: o strain
    Flickable {
      id: strainPane
      anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
      visible: room.wide
      width: room.wide ? Math.min(340, parent.width * 0.3) : 0
      contentWidth: width
      contentHeight: strainInfo.implicitHeight + 16
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      Section {
        id: strainInfo
        y: 8                      // espaco para o rotulo, que sobe acima da borda
        width: strainPane.width
        title: Grow.t("room.strain")

        Column {
          width: parent.width
          spacing: 7

          Text {
            text: Grow.strainName
            color: "#7fd6e0"
            font.family: room.ui.mono
            font.pixelSize: 15
            font.weight: Font.DemiBold
          }
          Text {
            text: Grow.term("type", room.ui.strainField("type"))
            color: "#e0c24a"
            font.family: room.ui.mono
            font.pixelSize: 12
          }
          Item { width: 1; height: 4 }

          Repeater {
            model: room.ui.strainRows
            delegate: Column {
              required property var modelData
              width: strainInfo.width - 28
              spacing: 2
              Text {
                text: modelData.label
                color: "#6fbf73"
                font.family: room.ui.mono
                font.pixelSize: 11
                font.weight: Font.DemiBold
              }
              Text {
                width: parent.width
                text: modelData.value
                color: room.ui.ink
                wrapMode: Text.WordWrap
                font.family: room.ui.mono
                font.pixelSize: 12
              }
              Item { width: 1; height: 5 }
            }
          }
        }
      }
    }

    // coluna da esquerda: planta e medidores
    Item {
      id: leftPane
      anchors {
        top: parent.top; bottom: parent.bottom
        left: parent.left
        right: room.wide ? strainPane.left : parent.right
        rightMargin: room.wide ? 18 : 0
      }

      // ---- a planta ----
      Rectangle {
        id: plantBox
        anchors { top: parent.top; left: parent.left; right: parent.right; bottom: meters.top; bottomMargin: 14 }
        color: Palette.hex(Palette.backgroundTint(Grow.visualMode, Grow.stage))
        border.width: 1
        border.color: room.ui.rule
        radius: 2
        // Sem `clip` aqui: o rotulo do bloco fica metade acima da borda
        // de cima, como no ratatui, e um clip na caixa corta a metade de
        // cima de "[ planta ]". Quem recorta e o Item de dentro.

        Rectangle {
          anchors { left: parent.left; top: parent.top; leftMargin: 9; topMargin: -1 }
          width: plantTitle.implicitWidth + 8; height: 2
          color: plantBox.color
        }
        Text {
          id: plantTitle
          anchors { left: parent.left; leftMargin: 13; verticalCenter: parent.top }
          text: Grow.t("room.plant")
          color: room.ui.inkDim
          font.family: room.ui.mono
          font.pixelSize: 11
        }

        // ---- a grade de 70x28 ----
        //
        // Duas regras, e as duas foram aprendidas apanhando:
        //
        // 1. Quem mede e o proprio contexto do canvas. `FontMetrics`,
        //    com a MESMA familia e o MESMO pixelSize, devolve outro
        //    numero: nesta maquina, para "monospace" a 9 px, a
        //    FontMetrics diz 11,16 de avanco e o canvas desenha 5,40 -
        //    a mesma fonte resolvida por dois caminhos diferentes.
        //    Posicionar por um e desenhar pelo outro faz a arte abrir
        //    como um leque: a linha de terra encolhe para metade da
        //    largura enquanto o tronco fica na coluna certa, longe dela.
        //    `ctx.measureText` e a unica medida que descreve o que vai
        //    aparecer na tela.
        //
        // 2. Cada caractere e desenhado na SUA celula, nao em blocos de
        //    mesma cor. Desenhar a corrida inteira deixa o espacamento
        //    por conta do avanco da fonte, e qualquer diferenca acumula
        //    ao longo da linha - trinta e oito tils saem 5% mais
        //    estreitos e a planta desalinha da terra. Custa algumas
        //    centenas de fillText por quadro, quase todos pulados por
        //    serem espaco, e em troca a grade fecha por construcao,
        //    mesmo que a fonte caia num fallback proporcional.
        Item {
          id: plantClip
          anchors { fill: parent; margins: 1 }
          clip: true

          Canvas {
            id: plantCanvas
            anchors.fill: parent
            renderStrategy: Canvas.Cooperative
            renderTarget: Canvas.Image

            // Proporcao do avanco, medida uma vez pelo proprio canvas
            // num tamanho de referencia. 0,6 e o palpite inicial, valido
            // para qualquer monoespacada, e sobrevive so ate o primeiro
            // quadro.
            property real advRatio: 0.6
            readonly property real lineRatio: 1.34

            readonly property int cellPx: Math.max(7, Math.min(40,
              Math.floor(Math.min((width - 24) / 70 / advRatio,
                                  (height - 22) / 28 / lineRatio))))

            function fontAt(px) { return px + "px \"" + room.ui.mono + "\"" }

            Connections {
              target: root
              function onFrameChanged() { if (room.active) plantCanvas.requestPaint() }
            }
            // Parada, `frame` nao anda, e um Canvas que so repinta por quadro
            // ficaria com o desenho velho - ou com nenhum, se a sala abriu ja
            // parada. Estas sao as outras portas por onde o desenho muda com o
            // relogio desligado: regar troca a cor da terra, e retomar volta a
            // ter quem peca quadro.
            Connections {
              target: Grow
              function onPausedChanged() { if (room.active) plantCanvas.requestPaint() }
              function onWatered() { if (room.active) plantCanvas.requestPaint() }
              function onFed() { if (room.active) plantCanvas.requestPaint() }
            }
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onCellPxChanged: requestPaint()

            onPaint: {
              var ctx = getContext("2d")
              ctx.reset()

              ctx.font = fontAt(100)
              var measured = ctx.measureText("MMMMMMMMMM").width / 1000
              if (measured > 0.2 && Math.abs(measured - advRatio) > 0.002) {
                advRatio = measured        // muda cellPx e repinta
                return
              }

              ctx.font = fontAt(cellPx)
              var cw = ctx.measureText("MMMMMMMMMM").width / 10
              if (cw <= 0) return
              var lh = cellPx * lineRatio

              var ox = Math.round((width - cw * 70) / 2)
              var oy = Math.round(height - lh * 28) - 6
              var base = lh * 0.78

              ctx.textBaseline = "alphabetic"
              ctx.textAlign = "left"

              var lines = Art.plantAscii(Grow.stage, Grow.day, room.ui.seedLimbs, room.ui.frame)
              var colors = room.ui.paletteColors(room.ui.frame)
              var last = null

              for (var r = 0; r < 28; r++) {
                var line = lines[r]
                var y = oy + r * lh + base
                for (var c = 0; c < 70; c++) {
                  var ch = line.charAt(c)
                  if (ch === " ") continue
                  var col = Palette.charColor(ch, Grow.stage, colors)
                  if (col === null) continue
                  if (col !== last) { ctx.fillStyle = Palette.hex(col); last = col }
                  ctx.fillText(ch, ox + c * cw, y)
                }
              }
            }
          }
        }
      }

      // ---- medidores ----
      Column {
        id: meters
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        spacing: 10

        Row {
          width: parent.width
          spacing: 10
          readonly property real cell: (width - 20) / 3

          Meter {
            width: parent.cell
            title: Grow.t("m.water") + Art.waterDrops(room.ui.frame)
            value: Grow.water
            label: Math.round(Grow.water) + "%"
            fill: room.ui.waterColor
          }
          Meter {
            width: parent.cell
            title: Grow.t("m.npk") + Art.nutrientSparkles(room.ui.frame)
            value: Grow.nutrients
            label: Math.round(Grow.nutrients) + "%"
            fill: room.ui.npkColor
          }
          Meter {
            width: parent.cell
            title: Grow.tf("m.next", room.ui.nextStage.name)
            value: room.ui.nextStage.percent
            label: room.ui.nextStage.left
            fill: Palette.hex(Palette.ANSI.gaugeCyan)
          }
        }

        // A segunda fileira sai quando falta altura: temperatura, umidade e
        // raiz/copa mudam devagar, e numa janela pequena o que tem que caber e
        // a planta.
        Row {
          visible: room.tall
          height: visible ? implicitHeight : 0
          width: parent.width
          spacing: 10
          readonly property real cell: (width - 20) / 3

          Meter {
            width: parent.cell
            title: Grow.t("m.temperature")
            value: Math.min(Math.max((Grow.temperature - 20) / 8 * 100, 0), 100)
            label: Grow.num(Grow.temperature) + "°C"
            fill: Palette.hex(Grow.temperature >= 20 && Grow.temperature <= 28
              ? Palette.ANSI.gaugeGreen : Palette.ANSI.gaugeYellow)
          }
          Meter {
            width: parent.cell
            title: Grow.t("m.humidity")
            value: Grow.humidity
            label: Math.round(Grow.humidity) + "%"
            fill: Palette.hex(Grow.humidity >= 50 && Grow.humidity <= 70
              ? Palette.ANSI.gaugeCyan
              : (Grow.humidity >= 40 && Grow.humidity <= 80 ? Palette.ANSI.gaugeYellow : Palette.ANSI.gaugeRed))
          }
          Meter {
            width: parent.cell
            title: Grow.t("m.rootCanopy")
            value: (Grow.rootDevelopment + Grow.canopyDensity) / 2
            label: Grow.tf("m.rootCanopyValue", Math.round(Grow.rootDevelopment),
              Math.round(Grow.canopyDensity))
            fill: Palette.hex(Grow.rootDevelopment >= 60 ? Palette.ANSI.gaugeGreen
              : (Grow.rootDevelopment >= 30 ? Palette.ANSI.gaugeYellow : Palette.ANSI.gaugeRed))
          }
        }

        Meter {
          visible: room.veryTall
          height: visible ? implicitHeight : 0
          width: parent.width
          title: Grow.t("m.health")
          value: room.ui.healthGauge.percent
          label: room.ui.healthGauge.label
          fill: room.ui.healthGauge.color
        }
      }
    }
  }

  // ---- aba de colheitas ----
  Flickable {
    id: harvestPane
    anchors {
      top: topRule.bottom; bottom: footer.top
      left: parent.left; right: parent.right
      margins: room.pad - 6
    }
    visible: room.ui.showHarvests
    contentWidth: width
    contentHeight: harvestCol.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: harvestCol
      width: Math.min(parent.width, 900)
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 14

      Text {
        text: Grow.totalHarvests === 0
          ? Grow.t("h.none")
          : Grow.plural(Grow.totalHarvests, "h.countOne", "h.countMany")
            + "  ·  " + Grow.tf("h.totals", Grow.num(room.ui.totals.weight),
              Math.round(room.ui.totals.quality), Grow.num(room.ui.totals.thc),
              Grow.num(room.ui.totals.cbd))
        color: room.ui.inkBright
        font.family: room.ui.mono
        font.pixelSize: 13
      }

      Text {
        visible: Grow.totalHarvests === 0
        width: parent.width
        text: Grow.t("h.empty")
        color: room.ui.inkDim
        wrapMode: Text.WordWrap
        font.family: room.ui.mono
        font.pixelSize: 12
        lineHeight: 1.5
        lineHeightMode: Text.ProportionalHeight
      }

      Repeater {
        model: room.ui.harvestRows
        delegate: Rectangle {
          required property var modelData
          required property int index
          width: harvestCol.width
          height: 58
          color: index % 2 === 0 ? Qt.rgba(1, 1, 1, 0.025) : "transparent"
          radius: 2

          Row {
            anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
            spacing: 16

            Text {
              anchors.verticalCenter: parent.verticalCenter
              width: 44
              horizontalAlignment: Text.AlignRight
              text: "#" + modelData.n
              color: room.ui.inkDim
              font.family: room.ui.mono
              font.pixelSize: 12
            }
            Column {
              anchors.verticalCenter: parent.verticalCenter
              width: 230
              spacing: 3
              Text {
                text: modelData.strain_name
                color: "#7fd6e0"
                font.family: room.ui.mono
                font.pixelSize: 13
                font.weight: Font.DemiBold
              }
              Text {
                text: Grow.tf("h.day", modelData.harvest_day, modelData.when)
                color: room.ui.inkDim
                font.family: room.ui.mono
                font.pixelSize: 11
              }
            }
            Text {
              anchors.verticalCenter: parent.verticalCenter
              width: 96
              text: Grow.tf("h.grams", Grow.num(modelData.weight_grams))
              color: "#6fbf73"
              font.family: room.ui.mono
              font.pixelSize: 13
              font.weight: Font.DemiBold
            }
            Text {
              anchors.verticalCenter: parent.verticalCenter
              width: 110
              text: Grow.tf("h.quality", Math.round(modelData.quality_score))
              color: modelData.quality_score >= 90 ? "#6fbf73"
                   : (modelData.quality_score >= 75 ? "#e0c24a" : "#e05a4f")
              font.family: room.ui.mono
              font.pixelSize: 12
            }
            Text {
              anchors.verticalCenter: parent.verticalCenter
              width: 150
              text: Grow.tf("h.cannabinoids", Grow.num(modelData.thc_percent),
                Grow.num(modelData.cbd_percent))
              color: room.ui.ink
              font.family: room.ui.mono
              font.pixelSize: 12
            }
            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: modelData.stress_events === undefined ? ""
                : (modelData.stress_events === 0 ? Grow.t("h.noStress")
                  : Grow.plural(modelData.stress_events, "h.stressOne", "h.stressMany"))
              color: modelData.stress_events ? "#e0c24a" : room.ui.inkDim
              font.family: room.ui.mono
              font.pixelSize: 11
            }
          }
        }
      }
    }
  }

  // ---- rodape ----
  //
  // Duas linhas, e nao duas pontas da mesma linha. Os atalhos ancorados a
  // esquerda e o credito ancorado a direita dividiam a MESMA faixa de 44 px:
  // na largura em que a linha de atalhos "roomy" quase preenche o rodape, os
  // dois se encontravam no meio e liam um por cima do outro. Ancora oposta nao
  // e layout - nada ali sabia da largura do vizinho.
  //
  // Agora o credito tem faixa propria em cima, e o rodape so cresce quando ele
  // aparece: sem credito a altura continua sendo os 44 px de antes.
  Item {
    id: footer
    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
    height: credito.visible ? 62 : 44

    Rectangle {
      anchors { left: parent.left; right: parent.right; top: parent.top }
      height: 1
      color: room.ui.rule
    }

    // A largura da linha inteira de atalhos, medida com a mesma fonte e o mesmo
    // tamanho com que ela vai ser desenhada. Um TextMetrics nao desenha nada e
    // nao ocupa lugar: e a pergunta "isto caberia?" feita a quem responde.
    TextMetrics {
      id: hintsFull
      font.family: room.ui.mono
      font.pixelSize: 11
      text: Grow.t("f.hints")
    }

    Text {
      // Presa embaixo, e nao no centro do rodape: quando o credito aparece a
      // faixa cresce para cima, e os atalhos nao se mexem.
      anchors { left: parent.left; bottom: parent.bottom; bottomMargin: 15; leftMargin: room.pad + 4 }
      // O rodape encolhe junto com a janela: uma linha de atalhos cortada no
      // meio nao ensina nada, so ocupa a altura que a planta queria.
      //
      // Qual das duas cabe quem decide e a medida do proprio texto, e nao um
      // limiar em pixels. O limiar era 1180 px porque a linha tinha cento e
      // cinquenta caracteres; com duas linguas ela tem dois comprimentos, e o
      // numero que servia para uma erra na outra por algumas letras - o
      // suficiente para cortar "esc fecha" no meio.
      text: room.ui.showHarvests
        ? Grow.t("f.harvests")
        : (hintsFull.width <= room.width - 2 * (room.pad + 4)
          ? hintsFull.text
          : Grow.t("f.hintsShort"))
      color: room.ui.inkDim
      font.family: room.ui.mono
      font.pixelSize: 11
    }

    Text {
      id: credito
      anchors { top: parent.top; right: parent.right; topMargin: 7; rightMargin: room.pad + 4 }
      // Sempre presente. Ele sumia abaixo de `roomy` (1180 px), e aquele limiar
      // nao era sobre ele: era para nao entrar por baixo da linha de atalhos,
      // problema que a faixa propria resolveu. Com faixa so dele, o unico que
      // disputa espaco e a largura da janela - e para isso o texto ENCOLHE, que
      // e o que a linha de atalhos aqui do lado ja faz.
      //
      // Os cortes sao a largura livre, nao a da janela: a 10 px o mono anda ~6
      // px por caractere, entao a forma inteira (48 caracteres) pede ~290 px e a
      // media (16) pede ~100. Com folga, 320 e 140.
      readonly property int livre: room.width - 2 * (room.pad + 4)
      text: livre >= 320 ? Grow.t("f.credit")
          : livre >= 140 ? Grow.t("f.creditShort")
          : "ZeD"
      color: room.ui.rule
      font.family: room.ui.mono
      font.pixelSize: 10
    }
  }
}
