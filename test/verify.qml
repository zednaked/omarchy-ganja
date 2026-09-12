import QtQuick
import Quickshell
import Quickshell.Io
import "Art.js" as Art

// Roda Art.js dentro do motor de JS do QML e compara, caractere a caractere,
// com as fixtures de test/frames/ - que foram geradas pelo Node.
//
//   qs -p test/verify.qml
//
// Isto nao e cerimonia. Os dois motores executam o mesmo arquivo, mas Art.js
// depende de duas coisas que nao sao obrigadas a coincidir entre eles: a
// aritmetica de 64 bits feita a mao (o V4 do QML nao tem BigInt) e o
// arredondamento de precisao simples do Math.fround, que e o que mantem os
// limiares de `.ceil()` e `> 0.5` caindo do mesmo lado que no f32 do Rust. Um
// bit de diferenca em qualquer um dos dois muda um caractere da planta.
//
// A conferencia contra o Ganja-TUI de verdade e outro passo - test/README.md.
ShellRoot {
  id: root

  property var seeds: [
    "0000000000000001", "00000000deadbeef", "123456789abcdef0", "ffffffffffffffff",
    "0f1e2d3c4b5a6978", "a5a5a5a5a5a5a5a5", "00000000000f4240", "7fffffffffffffff"
  ]
  property var days: [1, 5, 15, 30, 46, 53, 70, 90]

  property int checked: 0
  property int failed: 0
  property int pending: 0

  function stageFor(day) {
    if (day <= 10) return "Seedling"
    if (day <= 40) return "Vegetative"
    if (day <= 48) return "PreFlower"
    if (day <= 85) return "Flowering"
    return "ReadyToHarvest"
  }

  Component {
    id: readerComponent
    Process {
      property string seed: ""
      property int day: 0
      stdout: StdioCollector {
        waitForEnd: true
        onStreamFinished: root.compare(seed, day, String(text))
      }
    }
  }

  function compare(seed, day, raw) {
    var want = raw.replace(/\n$/, "").split("\n")
    var got = Art.plantAscii(root.stageFor(day), day, Art.u64FromHex(seed), 0)
    var bad = 0

    if (want.length !== 28) {
      console.warn("FIXTURE FALTANDO ou torta: " + seed + "-" + day)
      root.failed++
    } else {
      for (var r = 0; r < 28; r++) {
        if (got[r].length !== 70) { bad = 999; break }
        for (var c = 0; c < 70; c++)
          if (want[r].charAt(c) !== got[r].charAt(c)) bad++
      }
      if (bad > 0) {
        console.warn("DIFERE " + seed + "-" + day + ": " + bad + " caracteres")
        root.failed++
      }
    }

    root.checked++
    root.pending--
    if (root.pending === 0) {
      if (root.failed === 0)
        console.warn("OK: " + root.checked + " frames identicos as fixtures do Node "
          + "(LCG de 64 bits e arredondamento f32 batem nos dois motores)")
      else
        console.warn("FALHOU: " + root.failed + " de " + root.checked)
      Qt.exit(root.failed === 0 ? 0 : 1)
    }
  }

  Component.onCompleted: {
    var dir = Qt.resolvedUrl("frames").toString().replace("file://", "")
    for (var i = 0; i < seeds.length; i++) {
      for (var j = 0; j < days.length; j++) {
        var p = readerComponent.createObject(root, { seed: seeds[i], day: days[j] })
        p.command = ["cat", dir + "/" + seeds[i] + "-" + days[j] + ".txt"]
        root.pending++
        p.running = true
      }
    }
  }
}
