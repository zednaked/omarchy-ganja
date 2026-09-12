import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

// A metade que fica acordada: um glifo por estagio e um ponto quando ha o que
// fazer.
//
// O icone e um glifo, nao a planta. A arte tem 70 colunas por 28 linhas e nao
// cabe numa barra; reduzida a tres caracteres ela deixa de ser a arte e vira
// um rabisco. Sete glifos contam a mesma historia no espaco que existe.
//
// Cor vem do tema do Omarchy, nao da paleta do Ganja. Um icone com cor propria
// no meio da barra quebra a barra - a barra e uma linha de simbolos do mesmo
// tom, e o que sai do tom le-se como erro, nao como enfase. A planta pintada
// com as cores dela esta do outro lado do clique.
Panel {
  id: root

  moduleName: "zed.ganja"
  ipcTarget: "zed.ganja.widget"

  readonly property color foreground: bar ? bar.barForeground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property bool alerting: Grow.alerting

  // Um glifo por estagio. Os codigos saem da tabela de nomes do arquivo da
  // fonte que a barra usa, e nao de um catalogo na internet: os codepoints do
  // conjunto Material mudam entre versoes do Nerd Fonts, e a primeira versao
  // disto pos um logo de open source no lugar da muda e uma camera de seguranca
  // no lugar da folha - sem erro nenhum, porque o glifo existia.
  readonly property string glyph: {
    switch (Grow.stage) {
    case "Seed": return "󰹣"          // md-seed-outline
    case "Germination": return "󰹢"   // md-seed
    case "Seedling": return "󰹧"      // md-sprout-outline
    case "Vegetative": return "󰹦"    // md-sprout
    case "PreFlower": return "󰌪"     // md-leaf
    case "Flowering": return "󰞦"     // md-cannabis
    default: return "󰆐"              // md-content-cut: hora de cortar
    }
  }

  // Parada, o glifo nao e o do estagio, e o icone apaga.
  //
  // Apagar nao e trocar de cor. A regra da barra e que o icone segue o tema, e
  // um icone vermelho no meio de uma fileira de simbolos do mesmo tom le-se
  // como erro do sistema, nao como "o usuario desligou isto". O que a barra tem
  // para dizer desligado e o que qualquer icone desabilitado dela diz -
  // opacidade - e opacidade sozinha seria ambigua, entao vem com outro desenho.
  //
  // O desenho e `md-sleep`, e nao `md-pause`: o widget de midia do proprio
  // shell ja usa md-pause para "a musica esta pausada", e dois pauses na mesma
  // barra querendo dizer coisas diferentes e pior que nenhum. E o estagio nao
  // esta mudando enquanto ela dorme - mostrar o glifo do estagio seria gastar o
  // lugar com a informacao que nao muda, no lugar da unica que importa.
  readonly property string pausedGlyph: "󰒲"    // md-sleep
  readonly property real dim: Grow.paused ? 0.4 : 1

  readonly property int barSlot: Style.bar.iconFont + Style.space(12)
  readonly property real openPanelIndicatorWidth: Style.bar.iconFont
  readonly property real openPanelIndicatorHeight: Style.bar.iconFont
  implicitWidth: bar && bar.vertical ? (bar ? bar.barSize : Style.bar.sizeHorizontal) : barSlot
  implicitHeight: bar && bar.vertical ? barSlot : (bar ? bar.barSize : Style.bar.sizeHorizontal)

  // O clique direito rega, e acao sem resposta visivel parece que nao
  // aconteceu. O flash e curto de proposito: e um recibo, nao uma animacao.
  property real flashAmount: 0
  SequentialAnimation {
    id: flash
    NumberAnimation { target: root; property: "flashAmount"; to: 1; duration: 90 }
    NumberAnimation { target: root; property: "flashAmount"; to: 0; duration: 420; easing.type: Easing.OutQuad }
  }

  Connections {
    target: Grow
    function onWatered() { flash.restart() }
    // Parar e retomar tambem piscam. O icone troca de desenho e de opacidade,
    // mas o olho estava no ponteiro e nao no icone: sem o pisco, a mudanca
    // acontece fora do campo de visao de quem acabou de clicar.
    function onPausedChanged() { flash.restart() }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    slotSize: root.barSlot
    opticalSize: Style.bar.iconFont
    // A linha e sempre a mesma - strain, estagio, dia - e o que muda e o
    // sufixo, que responde "e tem algo a fazer?". Parada, a resposta e outra
    // pergunta: o estado vem primeiro e junto com ele como sair dele, porque um
    // plugin parado que nao diz como retomar e um plugin quebrado.
    tooltipText: {
      if (!Grow.loaded) return "Ganja"
      var line = Grow.tf("bar.line", Grow.strainName, Grow.stageLabel, Grow.day)
      var suffix = Grow.paused ? Grow.t("bar.paused")
        : Grow.ready ? Grow.t("bar.ready")
        : Grow.autoCare ? Grow.t("bar.auto")
        : Grow.thirsty ? Grow.tf("bar.thirsty", Math.round(Grow.water))
        : Grow.hungry ? Grow.tf("bar.hungry", Math.round(Grow.nutrients))
        : ""
      return suffix === "" ? line : line + "  ·  " + suffix
    }

    iconComponent: Component {
      Item {
        // A opacidade de "parado" fica aqui, e nao no Text: la ela multiplicaria
        // o flash, e o flash e uma animacao de 90 ms que uma transicao de 180
        // amassaria. Aqui ela e uma camada por cima - e o ponto de alerta, que
        // parado nao acende, vem junto de graca.
        opacity: root.dim
        Behavior on opacity { NumberAnimation { duration: 180 } }

        Text {
          anchors.centerIn: parent
          text: Grow.paused ? root.pausedGlyph : root.glyph
          font.family: root.fontFamily
          font.pixelSize: Style.bar.iconFont
          renderType: Text.NativeRendering
          color: root.foreground
          opacity: 1 - root.flashAmount * 0.7
          scale: 1 + root.flashAmount * 0.18
        }

        // O aviso e um ponto, nao um numero. Ou tem coisa a fazer - colher,
        // regar, alimentar - ou nao tem; quanto de agua falta esta no tooltip,
        // e um badge com numero na barra vira ruido que se aprende a ignorar.
        Rectangle {
          visible: root.alerting
          width: 6; height: 6; radius: 3
          color: Color.accent
          anchors { right: parent.right; top: parent.top; rightMargin: -1; topMargin: -1 }

          SequentialAnimation on opacity {
            running: root.alerting
            loops: Animation.Infinite
            NumberAnimation { from: 1; to: 0.35; duration: 1400; easing.type: Easing.InOutQuad }
            NumberAnimation { from: 0.35; to: 1; duration: 1400; easing.type: Easing.InOutQuad }
          }
        }
      }
    }

    // Tres botoes, e o direito trocou de funcao.
    //
    //   esquerdo   abre a sala
    //   direito    para / retoma a simulacao
    //   meio       rega
    //
    // Regar era o direito e saiu de la porque parar e a decisao mais
    // consequente que existe do lado da barra: e a unica que muda o que o
    // plugin custa, e a unica cujo resultado dura depois de fechar a sessao.
    // Regar tem tecla (`w`), IPC e o botao dentro da sala; parar so tem a barra.
    //
    // O clique do meio nao e lugar que se descobre sozinho, e esta bem: quem
    // nao descobre rega pelo `w` ou pelo IPC e nao perdeu nada. Um atalho de
    // conveniencia pode ser escondido; o que nao pode e um estado escondido, e
    // por isso o estado ficou com o botao que todo mundo tenta.
    onPressed: function (b) {
      if (b === Qt.RightButton) Grow.togglePause()
      else if (b === Qt.MiddleButton) Grow.pour(40)
      else Grow.open = !Grow.open
    }
  }
}
