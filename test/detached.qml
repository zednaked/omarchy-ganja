import QtQuick
import Quickshell
import Quickshell.Io

// A gravacao de saida roda mesmo com ambiente fechado?
//
//   LD_PRELOAD=... GANJA_TEST_OUT=<arquivo> qs -p detached.qml
//
// O `make detached` cuida disso; o teste e rodado com LD_PRELOAD e outras
// variaveis no ambiente do PROPRIO qs, e verifica que o filho destacado nao as
// enxerga.
//
// Por que existe: a descarga de saida ("Component.onDestruction") e a unica
// gravacao que acontece sozinha, e ela usa `Quickshell.execDetached`. A forma
// de lista desse metodo HERDA o ambiente do shell inteiro - foi o terceiro
// achado da revisao de seguranca do marketplace (issue #6530). Os tres
// `Process` limpavam o ambiente; esse nao. E o `-I` do Python nao cobre isso:
// ele suprime PYTHONPATH e o site do usuario, mas quem age antes do Python
// existir e o loader, e LD_PRELOAD/LD_AUDIT passam por baixo dele.
//
// O teste chama `Grow.detachedContext()`, que e a MESMA funcao que a descarga
// usa para montar o contexto - uma copia aqui poderia ficar verde enquanto o
// codigo de verdade regredia.
ShellRoot {
  id: root

  readonly property string saida: Quickshell.env("GANJA_TEST_OUT")

  // Despeja o ambiente que o filho realmente recebeu.
  readonly property var sonda: ["/usr/bin/python3", "-I", "-c",
    "import os,sys; open(sys.argv[1],'w').write(repr(sorted(os.environ.items())))"]

  property processContext ctx

  Component.onCompleted: {
    if (root.saida === "") {
      console.warn("FALHOU: GANJA_TEST_OUT nao definido")
      Qt.exit(1)
    }
    root.ctx = Grow.detachedContext(root.sonda.concat([root.saida]))
    Quickshell.execDetached(root.ctx)
  }

  // O filho e destacado: nao ha sinal de termino para esperar. Um segundo e
  // muito mais do que um `python3 -c` de uma linha precisa.
  Timer {
    running: true
    interval: 1000
    onTriggered: Qt.exit(0)
  }
}
