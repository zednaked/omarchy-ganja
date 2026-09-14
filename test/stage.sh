#!/usr/bin/env bash
# Monta uma copia da pasta do plugin num diretorio temporario e roda um teste de
# QML dentro dela.
#
#   test/stage.sh verify.qml
#   test/stage.sh state.qml
#
# Existe porque duas coisas se cruzam:
#
# 1. Um teste de QML precisa estar no MESMO diretorio que o que ele testa. Um
#    `import "Art.js"` resolve ao lado do arquivo, e o singleton `Grow` so e
#    visivel de dentro do diretorio que tem o qmldir que o declara - de fora,
#    `import ".."` da "ReferenceError: Grow is not defined", tanto qualificado
#    quanto nao.
#
# 2. O validador oficial recusa symlink dentro da pasta do plugin:
#    "omarchy-plugin-validate: symlinks are not allowed inside a plugin folder".
#    A primeira versao destes testes resolvia (1) com symlinks em test/, e isso
#    reprovava o plugin inteiro na validacao - sem tocar em nenhum arquivo que
#    vai para a barra.
#
# Copiar resolve as duas, e de quebra deixa o teste rodando em cima de uma copia
# do que vai instalado, que e exatamente o que o `omarchy-guest install` faz.
#
# O HOME tambem e temporario: `Grow.dir` sai de `Quickshell.env("HOME")` e o
# teste escreve um save. Sem isso ele mexeria na planta de quem esta testando.
set -euo pipefail

arquivo=${1:?uso: test/stage.sh <arquivo.qml>}
# O segundo argumento e o estado do disco em que o teste roda. `frouxo` deixa o
# ~/.local/share gravavel pelo grupo: e o que o save.py recusa, e o unico jeito
# de provar do lado do QML que a recusa aparece na tela em vez de sumir.
disco=${2:-normal}
raiz=$(cd "$(dirname "$0")/.." && pwd)

palco=$(mktemp -d)
trap 'rm -rf "$palco"' EXIT
mkdir -p "$palco/plugin" "$palco/home"

cp "$raiz"/*.qml "$raiz"/*.js "$raiz"/*.py "$raiz"/qmldir "$palco/plugin/"
if [ "$disco" = frouxo ]; then
  mkdir -p "$palco/home/.local/share"
  chmod 0775 "$palco/home/.local/share"
fi
cp "$raiz/test/$arquivo" "$palco/plugin/"
[ -d "$raiz/test/frames" ] && cp -r "$raiz/test/frames" "$palco/plugin/"

HOME="$palco/home" QT_FORCE_STDERR_LOGGING=1 \
  qs -p "$palco/plugin/$arquivo" 2>&1 \
  | grep -E "OK:|FALHOU|DIFERE|FIXTURE|ms$|^  [A-E] |media de|hoje |trecho" || true
