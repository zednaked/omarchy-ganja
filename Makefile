# zed.ganja
#
#   make strains   regera Strains.js a partir do strains.json do Ganja-TUI
#   make check     confere o LCG de 64 bits contra BigInt (precisa de node)
#   make frames    regrava as fixtures de test/frames/
#   make diff      compara a saida de hoje com as fixtures
#   make verify    confere as fixtures dentro do motor de JS do QML
#   make state     roda o Grow.qml de verdade e confere o que ele guarda
#   make glyphs    confere os sete icones da barra contra a fonte instalada
#   make test      check + diff + verify
#
# GANJA_TUI aponta para o clone do repo de origem. Nada aqui roda em tempo de
# execucao: Strains.js e dado estatico e entra no git ja gerado.

GANJA_TUI ?= $(HOME)/Projetos/Ganja-TUI
STRAINS_JSON := $(GANJA_TUI)/strains.json

.PHONY: strains check frames diff verify state glyphs test

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

glyphs:
	@python3 test/glyphs.py

test: check diff verify state glyphs
