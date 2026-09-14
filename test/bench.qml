import QtQuick
import Quickshell
import "Art.js" as Art
import "Palette.js" as Palette

// Onde vao os ~30 ms por quadro da secao 12 do SPEC.
//
//   test/stage.sh bench.qml
//
// A secao 12 mediu o custo TOTAL do quadro por consumo de CPU (22-40% de um
// nucleo a 10 quadros por segundo) e atribuiu a causa a "regerar a matriz
// inteira a cada quadro". Este bench separa as partes e mede cada uma dentro do
// motor que importa, o V4, com o Canvas de verdade.
//
// Quatro medidas por quadro:
//
//   A  gerar   - Art.plantAscii, que e a matriz de 70x28
//   B  decidir - o mesmo laco, chamando Palette.charColor por celula, sem pintar
//   C  pintar  - um fillText por caractere, que e o que Room.qml faz hoje
//   D  pintar  - um fillText por TRECHO contiguo de mesma cor
//
// C e D desenham exatamente os mesmos pixels: a diferenca e so quantas chamadas
// de texto o Canvas recebe.
ShellRoot {
  id: root

  property int rodadas: 0
  property int alvo: 40
  property real somaA: 0
  property real somaB: 0
  property real somaC: 0
  property real somaD: 0
  property real somaE: 0

  property var seedLimbs: {
    var hex = "123456789abcdef0"
    var l = []
    for (var i = 0; i < 4; i++) l.push(parseInt(hex.substr(i * 4, 4), 16))
    return l
  }

  function cores(f) {
    var mode = "natural"
    var breath = 0.875 + Math.sin(f * Palette.breathSpeed(mode)) * 0.125
    var intens = Palette.flowerIntensities("Flowering", 53)
    return {
      foliage: Palette.applyBreathing(Palette.foliageColor(mode, 0, 100, 60, f), breath),
      flower1: Palette.applyBreathing(Palette.flowerColor(mode, 0, intens[0], "Flowering", f), breath),
      flower2: Palette.applyBreathing(Palette.flowerColor(mode, 0, intens[1], "Flowering", f), breath),
      flower3: Palette.applyBreathing(Palette.flowerColor(mode, 0, intens[2], "Flowering", f), breath),
      trunk: Palette.trunkColor(mode, 0, 53, f),
      soil: Palette.soilColor(mode, 60, f)
    }
  }

  FloatingWindow {
    id: janela
    implicitWidth: 900
    implicitHeight: 460
    visible: true

    Canvas {
      id: tela
      anchors.fill: parent
      renderStrategy: Canvas.Immediate
      renderTarget: Canvas.Image

      onPaint: {
        var ctx = getContext("2d")
        var f = root.rodadas

        // E - o preambulo que Room.qml executa a cada quadro: limpar a tela e
        // medir a fonte duas vezes, uma delas em corpo 100.
        var tE = Date.now()
        ctx.reset()
        ctx.font = "100px monospace"
        var aferido = ctx.measureText("MMMMMMMMMM").width / 1000
        ctx.font = "12px monospace"
        var cw = ctx.measureText("MMMMMMMMMM").width / 10
        var lh = 15
        root.somaE += (Date.now() - tE)

        // A - gerar
        var t0 = Date.now()
        var lines = Art.plantAscii("Flowering", 53, root.seedLimbs, f)
        var t1 = Date.now()

        // B - decidir a cor de cada celula, sem pintar
        var cols = root.cores(f)
        var sink = 0
        for (var r = 0; r < 28; r++) {
          var line = lines[r]
          for (var c = 0; c < 70; c++) {
            var ch = line.charAt(c)
            if (ch === " ") continue
            var col = Palette.charColor(ch, "Flowering", cols)
            if (col !== null) sink++
          }
        }
        var t2 = Date.now()

        // C - um fillText por caractere (o que Room.qml faz hoje)
        ctx.textBaseline = "alphabetic"
        ctx.textAlign = "left"
        var last = null
        for (r = 0; r < 28; r++) {
          line = lines[r]
          var y = 20 + r * lh
          for (c = 0; c < 70; c++) {
            ch = line.charAt(c)
            if (ch === " ") continue
            col = Palette.charColor(ch, "Flowering", cols)
            if (col === null) continue
            if (col !== last) { ctx.fillStyle = Palette.hex(col); last = col }
            ctx.fillText(ch, 10 + c * cw, y)
          }
        }
        var t3 = Date.now()

        // D - um fillText por trecho contiguo de mesma cor
        ctx.reset()
        ctx.font = "12px monospace"
        ctx.textBaseline = "alphabetic"
        ctx.textAlign = "left"
        for (r = 0; r < 28; r++) {
          line = lines[r]
          y = 20 + r * lh
          var trecho = ""
          var trechoCol = null
          var trechoX = 0
          for (c = 0; c < 70; c++) {
            ch = line.charAt(c)
            col = (ch === " ") ? null : Palette.charColor(ch, "Flowering", cols)
            if (col !== trechoCol || col === null) {
              if (trecho.length > 0 && trechoCol !== null) {
                ctx.fillStyle = Palette.hex(trechoCol)
                ctx.fillText(trecho, 10 + trechoX * cw, y)
              }
              trecho = ""
              trechoCol = col
              trechoX = c
            }
            if (col !== null) trecho += ch
          }
          if (trecho.length > 0 && trechoCol !== null) {
            ctx.fillStyle = Palette.hex(trechoCol)
            ctx.fillText(trecho, 10 + trechoX * cw, y)
          }
        }
        var t4 = Date.now()

        if (root.rodadas <= 3) root.somaE = 0
        if (root.rodadas > 3) {   // as primeiras aquecem o motor
          root.somaA += (t1 - t0)
          root.somaB += (t2 - t1)
          root.somaC += (t3 - t2)
          root.somaD += (t4 - t3)
        }
        root.rodadas++
      }
    }

    Timer {
      interval: 16
      running: root.rodadas < root.alvo
      repeat: true
      onTriggered: tela.requestPaint()
    }

    Timer {
      interval: 100
      running: root.rodadas >= root.alvo
      repeat: false
      onTriggered: {
        var n = root.alvo - 4
        console.log("")
        console.log("por quadro, media de " + n + " quadros (Canvas de verdade, motor V4):")
        console.log("  A gerar   a matriz 70x28      " + (root.somaA / n).toFixed(2) + " ms")
        console.log("  B decidir a cor por celula    " + (root.somaB / n).toFixed(2) + " ms")
        console.log("  C pintar  por CARACTERE       " + (root.somaC / n).toFixed(2) + " ms")
        console.log("  D pintar  por TRECHO de cor   " + (root.somaD / n).toFixed(2) + " ms")
        console.log("  E reset + measureText x2      " + (root.somaE / n).toFixed(2) + " ms")
        console.log("")
        console.log("  hoje  (E + A + C) = " + ((root.somaE + root.somaA + root.somaC) / n).toFixed(2) + " ms")
        console.log("  trecho(E + A + D) = " + ((root.somaE + root.somaA + root.somaD) / n).toFixed(2) + " ms")
        console.log("")
        Qt.quit()
      }
    }
  }
}
