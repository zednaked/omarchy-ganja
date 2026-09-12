#!/usr/bin/env python3
"""Confere os glifos da barra contra a tabela de nomes da fonte instalada.

    python3 test/glyphs.py [caminho-da-fonte]

Isto existe porque a primeira versao do BarWidget usou codepoints tirados de um
catalogo do Nerd Fonts na internet, e nesta maquina eles apontavam para outros
desenhos: a muda virou o logo do open source, a folha virou uma camera de
seguranca, e o estagio "germinacao" virou um cogumelo. Nada falhou - os glifos
existiam, so nao eram esses. Um icone errado na barra nao levanta excecao, nao
some do log e nao aparece em teste nenhum: alguem tem que olhar.

Os codepoints do conjunto Material mudam entre versoes do Nerd Fonts. A fonte
instalada e a fonte que a barra vai usar, entao e nela que a pergunta se faz.
"""

import subprocess
import sys

# estagio -> nome do glifo, como o BarWidget espera desenhar. "Paused" nao e
# estagio: e o glifo que substitui o do estagio quando a simulacao esta parada,
# e ele tem o mesmo risco dos outros - md-sleep existe em qualquer versao do
# Nerd Fonts, mas nem sempre no mesmo codepoint.
WANT = {
    "Paused": "md-sleep",
    "Seed": "md-seed_outline",
    "Germination": "md-seed",
    "Seedling": "md-sprout_outline",
    "Vegetative": "md-sprout",
    "PreFlower": "md-leaf",
    "Flowering": "md-cannabis",
    "ReadyToHarvest": "md-content_cut",
}


def barwidget_codepoints(path="BarWidget.qml"):
    """Le os codepoints que o BarWidget usa hoje, na ordem dos estagios."""
    import io
    import re

    out = {}
    for line in io.open(path, encoding="utf-8"):
        m = re.search(r'case "(\w+)": return "(.+?)"', line)
        if m:
            out[m.group(1)] = ord(m.group(2))
        m = re.search(r'default: return "(.+?)"', line)
        if m:
            out["ReadyToHarvest"] = ord(m.group(1))
        m = re.search(r'pausedGlyph: "(.+?)"', line)
        if m:
            out["Paused"] = ord(m.group(1))
    return out


def font_path():
    if len(sys.argv) > 1:
        return sys.argv[1]
    # A mesma pergunta que o fontconfig responde para a barra.
    out = subprocess.run(["fc-match", "-f", "%{file}", "JetBrainsMono Nerd Font"],
                         capture_output=True, text=True)
    return out.stdout.strip()


def main():
    try:
        from fontTools.ttLib import TTFont
    except ImportError:
        print("pulado: fontTools nao instalado (pacman -S python-fonttools)")
        return 0

    path = font_path()
    if not path:
        print("pulado: fc-match nao achou a fonte")
        return 0

    font = TTFont(path)
    cmap = font.getBestCmap()
    used = barwidget_codepoints()

    bad = 0
    for stage, want in WANT.items():
        cp = used.get(stage)
        if cp is None:
            print(f"FALTA   {stage}: BarWidget.qml nao tem glifo para este estagio")
            bad += 1
            continue
        got = cmap.get(cp)
        if got is None:
            print(f"AUSENTE {stage}: U+{cp:X} nao existe em {path}")
            bad += 1
        elif got != want:
            print(f"ERRADO  {stage}: U+{cp:X} e '{got}', esperado '{want}'")
            bad += 1

    if bad:
        print(f"{bad} glifos errados em {path}")
        return 1
    print(f"{len(WANT)} glifos conferem com a tabela de nomes de {path.split('/')[-1]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
