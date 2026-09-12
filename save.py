# O unico lugar deste plugin que toca o disco.
#
# Invocado sempre como `/usr/bin/python3 -I save.py <modo> <caminhos relativos>`,
# com ambiente limpo (o Process do Quickshell usa `clearEnvironment`) e sem bit
# de execucao: um plugin de QML que ganha um executavel muda de categoria na
# revisao de seguranca, um arquivo de texto passado ao interpretador nao.
#
# ---------------------------------------------------------------------------
# Por que Python, e nao shell
#
# A versao anterior disto era um `save.sh` que checava com `[ -f ]`, `[ -O ]`,
# `[ ! -L ]` e depois usava `head`, `mktemp`, `sync` e `mv`. A revisao de
# seguranca do marketplace (issue #6530) aceitou que aquilo corrigia os
# problemas de citacao, de limite e de nome previsivel, e bloqueou no que
# sobrava - com razao:
#
#   "Directory checks and file checks are separate from the later head, mktemp,
#    sync, mv, and cleanup path resolutions. An accepted directory/file
#    component can be exchanged between check and use; a timeout limits duration
#    but does not prevent reading from or publishing into the substituted
#    location. mktemp protects only the unpredictable leaf. It does not pin the
#    parent directory identity through write/fsync/rename."
#
# Isso e a corrida entre checar e usar, e ela nao tem remedio em shell: cada
# comando resolve o caminho de novo, do zero, e nenhum deles aceita um descritor
# em vez de um nome. O `sh` nao alcanca `openat`, `renameat` nem `O_NOFOLLOW`.
#
# O Python alcanca. `os.open(..., dir_fd=)` e `openat`, `os.rename(...,
# src_dir_fd=, dst_dir_fd=)` e `renameat`, `os.stat(..., dir_fd=,
# follow_symlinks=False)` e `fstatat` com AT_SYMLINK_NOFOLLOW, e `O_NOFOLLOW`
# esta em `os`. Entao a identidade do diretorio deixa de ser um nome que se
# resolve tres vezes e passa a ser um DESCRITOR aberto uma vez, validado por
# `fstat`, e mantido aberto pela leitura, pela gravacao, pelo fsync, pelo
# rename e pela limpeza.
#
# O que isto garante, e que a versao em shell nao garantia:
#
#   - cada componente do caminho e aberto com O_NOFOLLOW|O_DIRECTORY a partir de
#     um descritor do anterior, comecando no $HOME. Trocar qualquer componente
#     por um symlink no meio do caminho faz a abertura FALHAR, nao seguir;
#   - o arquivo e aberto com O_NOFOLLOW relativo aquele descritor, e validado
#     por `fstat` NO PROPRIO DESCRITOR (regular, nosso, um unico link, dentro do
#     teto). Nao existe janela entre validar e ler: e o mesmo fd;
#   - a gravacao cria o temporario com O_CREAT|O_EXCL|O_NOFOLLOW naquele
#     descritor, escreve, faz fsync, e publica com `renameat` no MESMO
#     descritor, seguido de fsync do diretorio. O caminho do pai nao e
#     re-resolvido em nenhum dos passos.
#
# O resto das defesas continua: teto de bytes, prazo por SIGALRM, e o
# interpretador em modo isolado (`-I`, que ignora PYTHON*, o site do usuario e
# o diretorio do script no sys.path).
#
# Dependencia: python3. O proprio Omarchy usa python3 nos scripts dele, entao
# isto nao acrescenta nada a maquina de quem instala - mas esta dito no README.
# ---------------------------------------------------------------------------

import os
import signal
import stat
import sys

# Um save com as 100 colheitas que o formato guarda tem ~12 KB. Um mebibyte e
# quarenta vezes a folga do pior caso legitimo; acima disso o arquivo nao e
# nosso, e o certo e recusar em vez de truncar - JSON truncado pareceria save
# corrompido e faria o plugin comecar de novo, que e perder a planta.
MAX = 1 << 20

# Prazo para a operacao inteira. Se estourar, o processo morre sem saida: ler
# nada e melhor que esperar para sempre, e e isso que fecha o caso do FIFO.
DEADLINE = 5

SAVE = "save.json"
TMP_PREFIX = SAVE + "."          # nunca casa com o proprio SAVE
STALE_SECONDS = 300


class Refused(Exception):
    """O disco nao esta no estado que prometemos; nao se grava nem se le."""


def die(msg):
    sys.stderr.write("zed.ganja/save.py: %s\n" % msg)
    sys.exit(1)


def own_dir_fd(fd):
    """Valida um descritor de diretorio pelo proprio descritor, nao pelo nome."""
    st = os.fstat(fd)
    if not stat.S_ISDIR(st.st_mode):
        raise Refused("nao e diretorio")
    if st.st_uid != os.geteuid():
        raise Refused("diretorio de outro usuario")
    return st


def walk(root_fd, parts, create=False):
    """Desce componente por componente com openat + O_NOFOLLOW.

    Devolve um descritor do ultimo diretorio. Um symlink em QUALQUER componente
    faz `os.open` levantar OSError (ELOOP) em vez de seguir - e e por isso que a
    descida e feita passo a passo, e nao com um `os.open` do caminho inteiro:
    O_NOFOLLOW so protege o ultimo componente.
    """
    fd = root_fd
    opened = []
    try:
        for part in parts:
            if part in ("", ".", ".."):
                raise Refused("componente de caminho invalido: %r" % part)
            if create:
                try:
                    os.mkdir(part, 0o700, dir_fd=fd)
                except FileExistsError:
                    pass
            nxt = os.open(part, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW | os.O_CLOEXEC,
                          dir_fd=fd)
            opened.append(nxt)
            own_dir_fd(nxt)
            fd = nxt
        return fd, opened
    except Exception:
        for x in opened:
            os.close(x)
        raise


def home_fd():
    home = os.environ.get("HOME", "")
    if not home or not home.startswith("/"):
        raise Refused("HOME ausente ou relativo")
    # O $HOME e a raiz de confianca: e o unico caminho que abrimos por nome, e
    # ele vem do ambiente que o proprio shell da barra montou.
    fd = os.open(home, os.O_RDONLY | os.O_DIRECTORY | os.O_CLOEXEC)
    try:
        own_dir_fd(fd)
    except Exception:
        os.close(fd)
        raise
    return fd


def read_at(dir_fd, name):
    """Le um arquivo pelo descritor do diretorio, sem seguir link nenhum."""
    # O_NONBLOCK importa por causa do FIFO: abrir um FIFO para leitura bloqueia
    # ate alguem abrir para escrita. Com O_NONBLOCK a abertura volta na hora, e
    # o `fstat` abaixo rejeita por nao ser arquivo regular.
    fd = os.open(name, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK | os.O_CLOEXEC,
                 dir_fd=dir_fd)
    try:
        st = os.fstat(fd)
        if not stat.S_ISREG(st.st_mode):
            raise Refused("%s nao e arquivo regular" % name)
        if st.st_uid != os.geteuid():
            raise Refused("%s e de outro usuario" % name)
        if st.st_nlink != 1:
            raise Refused("%s tem %d links" % (name, st.st_nlink))
        if st.st_size > MAX:
            raise Refused("%s tem %d bytes, acima do teto de %d" % (name, st.st_size, MAX))

        # O teto tambem e aplicado na leitura, e nao so no `fstat`: entre um e
        # outro o arquivo pode crescer, e quem manda e o que cabe na memoria.
        pedacos = []
        faltam = MAX
        while faltam > 0:
            b = os.read(fd, min(65536, faltam))
            if not b:
                break
            pedacos.append(b)
            faltam -= len(b)
        return b"".join(pedacos)
    finally:
        os.close(fd)


def write_at(dir_fd, data):
    """Grava e publica sem re-resolver o pai em nenhum passo."""
    if len(data) > MAX:
        raise Refused("conteudo de %d bytes, acima do teto de %d" % (len(data), MAX))
    if not data:
        raise Refused("conteudo vazio")

    # Nome imprevisivel E criacao exclusiva E sem seguir link: as tres coisas no
    # mesmo `openat`. Se existir qualquer coisa com esse nome, a criacao falha.
    tmp = TMP_PREFIX + os.urandom(8).hex() + ".tmp"
    fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW | os.O_CLOEXEC,
                 0o600, dir_fd=dir_fd)
    try:
        escrito = 0
        while escrito < len(data):
            escrito += os.write(fd, data[escrito:])
        os.fsync(fd)
    except Exception:
        os.close(fd)
        os.unlink(tmp, dir_fd=dir_fd)
        raise
    os.close(fd)

    try:
        # `renameat` nos dois lados, com o MESMO descritor: nem a origem nem o
        # destino passam por resolucao de caminho a partir da raiz.
        os.rename(tmp, SAVE, src_dir_fd=dir_fd, dst_dir_fd=dir_fd)
    except Exception:
        os.unlink(tmp, dir_fd=dir_fd)
        raise

    # Sem isto, o nome novo pode sobreviver a uma queda de energia apontando
    # para lugar nenhum.
    os.fsync(dir_fd)


def clean_stale(dir_fd, agora):
    """Apaga temporario de gravacao que morreu no meio, e so ele."""
    for name in os.listdir(dir_fd):
        if not name.startswith(TMP_PREFIX) or name == SAVE:
            continue
        try:
            st = os.stat(name, dir_fd=dir_fd, follow_symlinks=False)
            # Um temporario de agora pode ser de outra instancia gravando neste
            # instante; cinco minutos e o limite entre "em uso" e "sobrou".
            if agora - st.st_mtime > STALE_SECONDS:
                os.unlink(name, dir_fd=dir_fd)
        except OSError:
            pass


def split(rel):
    return [p for p in rel.split("/") if p != ""]


def main(argv):
    signal.alarm(DEADLINE)

    if len(argv) < 3:
        die("uso: save.py <read|write|writenow> <dir-relativo-ao-HOME> [...]")
    modo, rel = argv[1], argv[2]

    hfd = home_fd()
    try:
        if modo == "read":
            legado = argv[3] if len(argv) > 3 else ""

            # O diretorio pode nao existir ainda (primeira carga): isso nao e
            # erro, e "nao ha save".
            try:
                dfd, abertos = walk(hfd, split(rel))
            except (OSError, Refused):
                dfd, abertos = None, []

            if dfd is not None:
                try:
                    import time
                    clean_stale(dfd, time.time())
                    dados = read_at(dfd, SAVE)
                    sys.stdout.buffer.write(dados)
                    return 0
                except (OSError, Refused):
                    pass
                finally:
                    for x in abertos:
                        os.close(x)

            # Sem save novo: tenta o caminho antigo, de quando o plugin morava
            # dentro do omarchy-guest. A marca diz ao chamador para migrar.
            if legado:
                partes = split(legado)
                if len(partes) >= 2:
                    try:
                        lfd, labertos = walk(hfd, partes[:-1])
                    except (OSError, Refused):
                        return 0
                    try:
                        dados = read_at(lfd, partes[-1])
                        sys.stdout.buffer.write(b"#legacy\n")
                        sys.stdout.buffer.write(dados)
                    except (OSError, Refused):
                        pass
                    finally:
                        for x in labertos:
                            os.close(x)
            return 0

        if modo in ("write", "writenow"):
            if modo == "write":
                # Limitado na entrada tambem: stdin pode ser infinito.
                dados = sys.stdin.buffer.read(MAX + 1)
            else:
                if len(argv) < 4:
                    die("writenow precisa do conteudo como argumento")
                dados = argv[3].encode("utf-8")

            dfd, abertos = walk(hfd, split(rel), create=True)
            try:
                write_at(dfd, dados)
            finally:
                for x in abertos:
                    os.close(x)
            return 0

        die("modo desconhecido: %s" % modo)
    finally:
        os.close(hfd)


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv))
    except Refused as e:
        die(str(e))
    except OSError as e:
        die("erro de sistema: %s" % e)
