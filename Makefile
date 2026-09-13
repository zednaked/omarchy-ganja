# zed.ganja
#
#   make strains   regera Strains.js a partir do strains.json do Ganja-TUI
#   make check     confere o LCG de 64 bits contra BigInt (precisa de node)
#   make frames    regrava as fixtures de test/frames/
#   make diff      compara a saida de hoje com as fixtures
#   make verify    confere as fixtures dentro do motor de JS do QML
#   make state     roda o Grow.qml de verdade e confere o que ele guarda
#   make dev       poe a arvore de trabalho na barra (sem push) e reinicia o shell
#   make dev-off   devolve o clone instalado ao que esta publicado
#   make hostile   joga FIFO, symlink, hardlink e save gigante contra o save.py
#   make refused   prova que uma gravacao recusada aparece na sala, e nao some
#   make glyphs    confere os sete icones da barra contra a fonte instalada
#   make test      check + diff + verify
#
# GANJA_TUI aponta para o clone do repo de origem. Nada aqui roda em tempo de
# execucao: Strains.js e dado estatico e entra no git ja gerado.

GANJA_TUI ?= $(HOME)/Projetos/Ganja-TUI
STRAINS_JSON := $(GANJA_TUI)/strains.json

.PHONY: strains check frames diff verify state refused hostile glyphs test dev dev-off dev-status

Strains.js: $(STRAINS_JSON) Makefile
	@printf '.pragma library\n\n' > $@
	@printf '// GERADO por `make strains` a partir de strains.json do Ganja-TUI.\n' >> $@
	@printf '// Nao editar a mao: a proxima geracao apaga a edicao.\n' >> $@
	@printf '//\n' >> $@
	@printf '// Sao dados estaticos - os 35 strains com genetica real. Ler o JSON em\n' >> $@
	@printf '// tempo de execucao custaria um processo e um parse a cada planta nova,\n' >> $@
	@printf '// por um arquivo que so muda quando alguem edita o repo de origem.\n\n' >> $@
	@printf 'var STRAINS = ' >> $@
	@jq '.' $(STRAINS_JSON) >> $@
	@printf '\n\nfunction count() { return STRAINS.length }\n' >> $@
	@printf 'function byIndex(i) { return STRAINS[((i %% STRAINS.length) + STRAINS.length) %% STRAINS.length] }\n' >> $@
	@printf 'function byName(name) {\n' >> $@
	@printf '  for (var i = 0; i < STRAINS.length; i++)\n' >> $@
	@printf '    if (STRAINS[i].name === name) return STRAINS[i]\n' >> $@
	@printf '  return null\n}\n' >> $@
	@echo "Strains.js: $$(jq 'length' $(STRAINS_JSON)) strains"

strains: Strains.js

# ---- rodar a arvore de trabalho na maquina, sem empurrar nada ---------------
#
# O Omarchy instala o plugin como um CLONE deste repo. Enquanto a submissao ao
# marketplace estiver aberta, o HEAD publico tem que continuar igual ao commit
# validado - entao testar na barra nao pode depender de `git push` + `omarchy
# plugin update`. O `make dev` copia por cima do clone os arquivos que vao
# instalados, inclusive o que ainda nao foi commitado, e reinicia o shell.
#
# O `make dev-off` devolve o clone ao que esta publicado. Vale rodar antes de
# `omarchy plugin update`: com o diretorio sujo o update nao tem como avancar.
PLUGIN_DIR ?= $(HOME)/.config/omarchy/plugins/zed.ganja
SHIP = $(wildcard *.qml) $(wildcard *.js) $(wildcard *.py) qmldir manifest.json preview.png

dev:
	@test -d "$(PLUGIN_DIR)/.git" || { echo "nao ha clone em $(PLUGIN_DIR)"; exit 1; }
	@cp -f $(SHIP) "$(PLUGIN_DIR)/"
	@echo "dev: $(PLUGIN_DIR) esta com a arvore de trabalho ($$(git rev-parse --short HEAD), $$(git status --porcelain | wc -l) arquivo(s) sujo(s) aqui)"
	@omarchy-restart-shell

dev-off:
	@git -C "$(PLUGIN_DIR)" checkout -- .
	@git -C "$(PLUGIN_DIR)" clean -fdq
	@echo "dev-off: de volta a $$(git -C "$(PLUGIN_DIR)" log --oneline -1)"
	@omarchy-restart-shell

# O que esta rodando na barra agora, em relacao ao que esta aqui.
dev-status:
	@echo "instalado: $$(git -C "$(PLUGIN_DIR)" log --oneline -1)"
	@echo "sujo la:   $$(git -C "$(PLUGIN_DIR)" status --porcelain | wc -l) arquivo(s)"
	@echo "aqui:      $$(git log --oneline -1)"

check:
	@node test/run.js check

frames:
	@node test/run.js gen

diff:
	@node test/run.js diff

# Os dois testes de QML rodam numa copia temporaria da pasta do plugin, com um
# HOME temporario. O porque esta em test/stage.sh - e um dos dois motivos e que
# o validador oficial recusa symlink dentro da pasta do plugin.
verify:
	@test/stage.sh verify.qml

state:
	@test/stage.sh state.qml

# A gravacao recusada pelo save.py tem que APARECER: este roda o plugin de
# verdade com o ~/.local/share do HOME temporario gravavel pelo grupo, que e o
# que o helper recusa, e confere que o aviso acende em vez de sumir.
refused:
	@test/stage.sh refused.qml frouxo

# Os cenarios que a revisao de seguranca do marketplace apontou na issue #6530,
# inclusive o symlink no MEIO do caminho, que foi o ultimo a ser fechado.
# Cada caso roda em HOME temporario proprio, como os outros testes.
hostile:
	@python3 test/hostile.py

glyphs:
	@python3 test/glyphs.py

test: check diff verify state refused hostile glyphs
