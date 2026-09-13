import QtQuick
import Quickshell
import Quickshell.Io

// Prova que uma gravacao RECUSADA nao passa em silencio.
//
//   test/stage.sh refused.qml frouxo
//
// O `frouxo` do stage.sh deixa o `~/.local/share` do HOME temporario gravavel
// pelo grupo, que e exatamente o que o save.py recusa desde a quarta rodada da
// revisao (issue #6530). Antes disto o plugin continuava jogando e nunca mais
// gravava: nada coletava o stderr do helper e o `onExited` ignorava o codigo de
// saida. Perder o save calado e pior que o problema que a recusa resolve.
//
// Este teste e separado do state.qml de proposito: ele precisa de um HOME
// preparado errado ANTES do Quickshell subir, e o state.qml precisa de um certo.
ShellRoot {
  id: root

  property int checked: 0
  property int failed: 0

  function ok(what, cond) {
    root.checked++
    if (cond) console.warn("OK:     " + what)
    else { root.failed++; console.warn("FALHOU: " + what) }
  }

  Connections {
    target: Grow
    function onLoadedChanged() { if (Grow.loaded) root.run() }
  }
  Component.onCompleted: if (Grow.loaded) root.run()

  // A carga ja tenta gravar (save vazio -> planta nova -> save). Esperar o
  // Process do writer sair e o unico jeito: o codigo de saida so existe la.
  Timer {
    id: depois
    interval: 2500
    onTriggered: {
      root.ok("gravacao recusada acende o aviso", Grow.saveError !== "")
      root.ok("e o aviso diz por que (" + Grow.saveError + ")",
              /grupo|outros|save\.py/.test(Grow.saveError))
      root.ok("a sala tem frase para isso, nos dois idiomas",
              Grow.t("room.saveFailed") !== "room.saveFailed")
      console.warn(root.failed === 0
        ? "OK: " + root.checked + " verificacoes de gravacao recusada"
        : "FALHOU: " + root.failed + " de " + root.checked)
      Qt.exit(root.failed === 0 ? 0 : 1)
    }
  }

  function run() {
    Grow.save()
    depois.start()
  }
}
