#!/usr/bin/env python3
"""Os cenarios hostis do save.py, incluindo os que a revisao de seguranca pediu.

    python3 test/hostile.py

Nao e teste do formato do save - disso cuidam `make state` e `make diff`. E o
teste de que o disco em estado errado nao vira leitura errada, escrita fora do
lugar, nem espera infinita:

  FIFO no lugar do save            nao pode bloquear nem devolver nada
  symlink no lugar do save         nao pode ser lido nem escrito atraves
  symlink NO MEIO do caminho       nao pode ser seguido (era o achado final)
  hardlink para fora               nao pode ser lido (st_nlink != 1)
  save maior que o teto            recusado inteiro, nao truncado
  temporario plantado              nao pode ser reutilizado
  diretorio de outro dono          nao da para testar sem root; esta no codigo

Cada caso roda num $HOME temporario proprio - um teste que mexesse no HOME de
verdade escreveria na planta de quem esta testando.
"""

import os
import shutil
import stat
import subprocess
import sys
import tempfile
import time

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HELPER = os.path.join(RAIZ, "save.py")
REL = ".local/share/zed.ganja"
JSON = '{"current_plant":{"strain_name":"Purple Kush"},"total_harvests":7}'

ok = 0
mau = 0


def passou(msg):
    global ok
    ok += 1
    print("OK:     %s" % msg)


def falhou(msg):
    global mau
    mau += 1
    print("FALHOU: %s" % msg)


def verifica(desc, esperado, obtido):
    if esperado == obtido:
        passou("%s (%r)" % (desc, obtido if len(str(obtido)) < 60 else str(obtido)[:57] + "..."))
    else:
        falhou("%s: esperado %r, obtido %r" % (desc, esperado, obtido))


def roda(home, *args, entrada=None, prazo=20):
    """Chama o helper como o plugin chama: interpretador isolado, ambiente limpo."""
    return subprocess.run(
        [sys.executable, "-I", HELPER] + list(args),
        input=entrada.encode() if entrada is not None else None,
        capture_output=True,
        timeout=prazo,
        env={"HOME": home, "PATH": "/usr/bin:/bin"},
    )


class Palco:
    """Um $HOME temporario, com o diretorio de dados ja criado."""

    def __enter__(self):
        self.home = tempfile.mkdtemp()
        self.dados = os.path.join(self.home, REL)
        os.makedirs(self.dados, 0o700, exist_ok=True)
        return self

    def __exit__(self, *_):
        shutil.rmtree(self.home, ignore_errors=True)

    def save(self):
        return os.path.join(self.dados, "save.json")

    def grava(self, conteudo=JSON):
        return roda(self.home, "write", REL, entrada=conteudo)

    def le(self, legado=""):
        args = ["read", REL] + ([legado] if legado else [])
        return roda(self.home, *args)


# ---- o caminho normal, primeiro: sem isto o resto nao significa nada --------
with Palco() as p:
    p.grava()
    verifica("grava e le de volta", JSON, p.le().stdout.decode())
    st = os.stat(p.save())
    verifica("modo do save e 600", 0o600, stat.S_IMODE(st.st_mode))
    verifica("um unico link", 1, st.st_nlink)
    verifica("nao sobrou temporario", [], [f for f in os.listdir(p.dados) if f != "save.json"])

# ---- FIFO no lugar do save --------------------------------------------------
# Abrir FIFO para leitura bloqueia ate alguem abrir para escrita. O helper abre
# com O_NONBLOCK e rejeita no fstat por nao ser arquivo regular.
with Palco() as p:
    os.mkfifo(p.save())
    inicio = time.time()
    r = p.le()
    gastou = time.time() - inicio
    verifica("FIFO nao devolve nada", b"", r.stdout)
    if gastou < 5:
        passou("FIFO nao bloqueia (%.1fs)" % gastou)
    else:
        falhou("FIFO bloqueou %.1fs" % gastou)

# ---- symlink no lugar do save ----------------------------------------------
with Palco() as p:
    fora = os.path.join(p.home, "segredo.txt")
    with open(fora, "w") as f:
        f.write("conteudo que nao e nosso")
    os.symlink(fora, p.save())

    verifica("symlink nao e lido", b"", p.le().stdout)

    p.grava()
    with open(fora) as f:
        verifica("gravar nao escreveu atraves do symlink", "conteudo que nao e nosso", f.read())
    verifica("o save publicado nao e link", False, os.path.islink(p.save()))
    verifica("e tem o nosso conteudo", JSON, p.le().stdout.decode())

# ---- symlink NO MEIO do caminho --------------------------------------------
# Este era o achado final da revisao: O_NOFOLLOW protege o ultimo componente, e
# a descida componente por componente e o que protege os do meio.
with Palco() as p:
    fora = os.path.join(p.home, "fora")
    os.makedirs(fora, exist_ok=True)
    shutil.rmtree(os.path.join(p.home, ".local/share/zed.ganja"))
    # troca `share` por um link: o caminho ainda "existe" para quem resolve nome
    shutil.rmtree(os.path.join(p.home, ".local/share"))
    os.symlink(fora, os.path.join(p.home, ".local/share"))

    r = p.grava()
    verifica("componente-symlink recusa a gravacao", 1, r.returncode)
    verifica("e nada foi criado do outro lado", [], os.listdir(fora))
    verifica("leitura tambem nao segue", b"", p.le().stdout)

# ---- hardlink para um arquivo de fora --------------------------------------
# Um hardlink nao e symlink e passaria por qualquer cheque de link: o que o pega
# e st_nlink != 1.
with Palco() as p:
    fora = os.path.join(p.home, "alvo.json")
    with open(fora, "w") as f:
        f.write(JSON)
    os.link(fora, p.save())
    verifica("hardlink nao e lido", b"", p.le().stdout)

# ---- save maior que o teto -------------------------------------------------
with Palco() as p:
    with open(p.save(), "wb") as f:
        f.write(b"{" + b"0" * (2 << 20))
    verifica("save gigante e recusado", b"", p.le().stdout)

# ---- gravacao gigante ------------------------------------------------------
with Palco() as p:
    r = p.grava("x" * ((1 << 20) + 10))
    verifica("gravacao acima do teto e recusada", 1, r.returncode)
    verifica("e nao deixou save pela metade", False, os.path.exists(p.save()))

# ---- temporario plantado ---------------------------------------------------
with Palco() as p:
    fora = os.path.join(p.home, "segredo2.txt")
    with open(fora, "w") as f:
        f.write("intacto")
    os.symlink(fora, os.path.join(p.dados, "save.json.deadbeef.tmp"))
    p.grava()
    with open(fora) as f:
        verifica("temporario plantado nao foi usado", "intacto", f.read())
    verifica("gravou mesmo assim", JSON, p.le().stdout.decode())

# ---- limpeza de temporario velho -------------------------------------------
with Palco() as p:
    p.grava()
    velho = os.path.join(p.dados, "save.json.velho.tmp")
    agora = os.path.join(p.dados, "save.json.agora.tmp")
    for caminho in (velho, agora):
        with open(caminho, "w") as f:
            f.write("x")
    antigo = time.time() - 3600
    os.utime(velho, (antigo, antigo))
    p.le()
    verifica("temporario velho e apagado", False, os.path.exists(velho))
    verifica("temporario de agora sobrevive", True, os.path.exists(agora))
    verifica("e o save continua la", JSON, p.le().stdout.decode())

# ---- writenow, o caminho da descarga do shell ------------------------------
with Palco() as p:
    roda(p.home, "writenow", REL, JSON)
    verifica("writenow grava", JSON, p.le().stdout.decode())

# ---- migracao do caminho antigo -------------------------------------------
with Palco() as p:
    rel_legado = ".local/share/omarchy-guest/ganja/save.json"
    legado = os.path.join(p.home, rel_legado)
    os.makedirs(os.path.dirname(legado), 0o700, exist_ok=True)
    with open(legado, "w") as f:
        f.write(JSON)
    verifica("sem save novo, le o antigo com a marca",
             "#legacy\n" + JSON, p.le(rel_legado).stdout.decode())
    p.grava()
    verifica("com save novo, o antigo e ignorado", JSON, p.le(rel_legado).stdout.decode())

# ---- HOME ausente ou estranho ----------------------------------------------
r = subprocess.run([sys.executable, "-I", HELPER, "read", REL],
                   capture_output=True, env={"PATH": "/usr/bin:/bin"}, timeout=20)
verifica("sem HOME, recusa", 1, r.returncode)

r = roda("relativo/nao/absoluto", "read", REL)
verifica("HOME relativo, recusa", 1, r.returncode)

# ---- modo desconhecido -----------------------------------------------------
with Palco() as p:
    verifica("modo desconhecido sai diferente de zero", 1, roda(p.home, "xablau", REL).returncode)

print()
if mau:
    print("FALHOU: %d de %d" % (mau, ok + mau))
    sys.exit(1)
print("OK: %d verificacoes hostis de save.py" % ok)
