# O unico lugar deste plugin que toca o disco.
#
# Nao tem shebang e nao tem bit de execucao de proposito: e sempre invocado como
# `/bin/sh save.sh <modo> <args>`, nunca executado direto. Um plugin de QML que
# ganha um binario executavel muda de categoria na revisao de seguranca; um
# script de texto chamado pelo interpretador nao.
#
# ---------------------------------------------------------------------------
# Por que ele existe
#
# A primeira versao montava o comando concatenando caminhos DENTRO do texto do
# shell ("cat \"" + dir + "/save.json\"") e coletava a saida inteira sem limite
# de bytes nem de tempo. A revisao de seguranca do marketplace (issue #6530)
# apontou as duas coisas, com razao:
#
#   1. caminho interpolado em codigo de shell e uma superficie de citacao que
#      nao precisa existir - aqui os caminhos chegam como ARGUMENTOS ($1, $2), e
#      o texto do script e constante;
#   2. leitura sem limite: um save.json de cinco gigabytes enche a memoria do
#      shell inteiro (o processo e compartilhado com a barra), e um FIFO no lugar
#      do arquivo faz o `cat` esperar para sempre;
#   3. `.tmp` de nome previsivel (`save.json.$$.tmp`) com `cat >` e alvo para um
#      symlink pre-posicionado: quem consegue criar arquivo no diretorio faz a
#      gravacao sair em outro lugar.
#
# O que este arquivo faz a respeito, na ordem em que a revisao pediu:
#
#   bounded          MAX bytes na leitura e na escrita, com `head -c`
#   deadline         `timeout` em toda operacao que pode bloquear
#   closed env       PATH fixo aqui, e `clearEnvironment` no Process que chama
#   temp aleatorio   `mktemp`, que cria com O_EXCL e modo 600
#   validado         nao-symlink, arquivo regular, dono somos nos, cabe no teto
#   atomico          `mv -f`, que substitui o link em vez de escrever atraves
#   fsync            `sync <arquivo>` antes do `mv`
#
# O que NAO esta aqui, e nao da para estar: abertura relativa a descritor com
# O_NOFOLLOW. Isso e chamada de sistema, e nem o sh nem o QML alcancam. O que
# substitui e o par "cheque imediatamente antes do uso" + "toda operacao com
# prazo": uma corrida ganha entre o cheque e o uso nao passa de cinco segundos
# perdidos, e o vetor de escrita pre-posicionada deixou de existir porque o nome
# do temporario agora e aleatorio e criado com exclusividade.
# ---------------------------------------------------------------------------

set -u

PATH=/usr/bin:/bin
export PATH
unset IFS CDPATH ENV BASH_ENV

# Um save com as 100 colheitas que o formato guarda tem ~12 KB. Um megabyte e
# quarenta vezes a folga do pior caso legitimo e um limite que nenhuma planta
# alcanca; acima disso o arquivo nao e nosso, e o certo e recusar em vez de
# truncar (JSON truncado pareceria save corrompido e faria o plugin comecar de
# novo, que e justamente perder a planta).
MAX=1048576

# `timeout` e do coreutils e existe em qualquer Arch, que e onde o Omarchy roda.
# Se faltar, a operacao roda sem prazo em vez de nao rodar: o teto de bytes
# continua valendo, e ficar sem save e pior que ficar sem deadline.
TIMEOUT=""
if command -v timeout >/dev/null 2>&1; then TIMEOUT=timeout; fi

bounded() {
  if [ -n "$TIMEOUT" ]; then "$TIMEOUT" -k 1 5 "$@"; else "$@"; fi
}

# Diretorio utilizavel: existe, e diretorio, nao e symlink e e nosso.
#
# O `-O` ("dono e o uid efetivo") e o cheque que importa: um diretorio de outro
# usuario no caminho do nosso save significa que alguem esta no meio, e nao ha
# gravacao segura possivel ali.
dir_ok() {
  [ -d "$1" ] || return 1
  [ ! -L "$1" ] || return 1
  [ -O "$1" ] || return 1
  return 0
}

# Arquivo legivel: nao e symlink, e regular (o que descarta FIFO, socket e
# dispositivo), e nosso, e cabe no teto.
file_ok() {
  [ ! -L "$1" ] || return 1
  [ -f "$1" ] || return 1
  [ -O "$1" ] || return 1
  n=$(bounded wc -c <"$1" 2>/dev/null) || return 1
  [ -n "$n" ] || return 1
  [ "$n" -le "$MAX" ] || return 1
  return 0
}

emit() { bounded head -c "$MAX" "$1"; }

modo=${1:-}

case "$modo" in

# read <dir> <save-antigo>
#
# Imprime o save, ou nada. O `#legacy` na frente diz que veio do caminho antigo
# (o plugin morava dentro do omarchy-guest), e e o que faz o chamador gravar no
# lugar novo uma vez so.
read)
  dir=${2:?}
  legado=${3:-}

  # Limpeza dos temporarios que sobraram de um shell morto no meio da gravacao.
  # O padrao nunca casa com `save.json` (tem o ponto depois), e o -mmin +5 evita
  # apagar o temporario de uma gravacao em curso de outra instancia.
  if dir_ok "$dir"; then
    bounded find "$dir" -maxdepth 1 -name 'save.json.*' -type f -mmin +5 -delete 2>/dev/null
  fi

  if dir_ok "$dir" && file_ok "$dir/save.json"; then
    emit "$dir/save.json"
  elif [ -n "$legado" ] && file_ok "$legado"; then
    printf '#legacy\n'
    emit "$legado"
  fi
  ;;

# write <dir>   - conteudo pelo stdin
# writenow <dir> <json>  - conteudo como argumento
#
# Os dois modos existem porque a gravacao de saida do shell ("Component.on
# Destruction") e um processo destacado, e processo destacado nao tem stdin para
# receber nada.
write | writenow)
  dir=${2:?}

  # `mkdir -p -m 700` so aplica o modo no que ele cria; o dir_ok depois cobre o
  # caso do diretorio ja existir com outro dono ou como symlink.
  mkdir -p -m 700 "$dir" 2>/dev/null || exit 1
  dir_ok "$dir" || exit 1

  # Aqui morre o achado do `.tmp` previsivel: mktemp cria com O_EXCL e nome
  # aleatorio, entao nao existe caminho que alguem possa pre-posicionar, e a
  # criacao falha em vez de escrever atraves de um symlink plantado.
  tmp=$(mktemp "$dir/save.json.XXXXXXXXXX" 2>/dev/null) || exit 1
  chmod 600 "$tmp" 2>/dev/null || true

  if [ "$modo" = write ]; then
    bounded head -c "$MAX" >"$tmp" || { rm -f "$tmp"; exit 1; }
  else
    json=${3:?}
    printf '%s' "$json" >"$tmp" || { rm -f "$tmp"; exit 1; }
  fi

  # Vazio significa que a gravacao falhou no meio, e um save.json de zero byte
  # vira "comecar de novo" na proxima carga - ou seja, perder a planta.
  [ -s "$tmp" ] || { rm -f "$tmp"; exit 1; }

  # Durabilidade antes da troca: sem isto o `mv` pode publicar um nome que
  # aponta para conteudo que ainda nao chegou ao disco.
  sync "$tmp" 2>/dev/null || true

  # `mv` renomeia: se `save.json` for um symlink, o link e substituido, nao
  # seguido. E a troca e atomica, que e o ponto do arquivo temporario.
  mv -f "$tmp" "$dir/save.json" || { rm -f "$tmp"; exit 1; }
  ;;

*)
  echo "save.sh: modo desconhecido: ${modo:-<nenhum>}" >&2
  exit 2
  ;;
esac
