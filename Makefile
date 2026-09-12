# zed.ganja
#
#   make strains   regera Strains.js a partir do strains.json do Ganja-TUI
#   make check     confere o LCG de 64 bits contra BigInt (precisa de node)
#   make frames    regrava as fixtures de test/frames/
#   make diff      compara a saida de hoje com as fixtures
#   make verify    confere as fixtures dentro do motor de JS do QML
#   make state     roda o Grow.qml de verdade e confere o que ele guarda
#   make hostile   joga FIFO, symlink, hardlink e save gigante contra o save.py
#   make detached  confere que a gravacao de saida roda com ambiente fechado
#   make glyphs    confere os sete icones da barra contra a fonte instalada
#   make test      check + diff + verify
#
# GANJA_TUI aponta para o clone do repo de origem. Nada aqui roda em tempo de
# execucao: Strains.js e dado estatico e entra no git ja gerado.

GANJA_TUI ?= $(HOME)/Projetos/Ganja-TUI
STRAINS_JSON := $(GANJA_TUI)/strains.json

.PHONY: strains check frames diff verify state hostile detached glyphs test

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

# Os cenarios que a revisao de seguranca do marketplace apontou na issue #6530,
# inclusive o symlink no MEIO do caminho, que foi o ultimo a ser fechado.
# Cada caso roda em HOME temporario proprio, como os outros testes.
hostile:
	@python3 test/hostile.py

# A gravacao de saida e a unica que acontece sozinha, e ela e um lancamento
# DESTACADO - que herda o ambiente do shell a menos que alguem peca o contrario.
# Este teste roda o qs com LD_PRELOAD, LD_AUDIT e PYTHONPATH sujos e exige que o
# filho nao veja nenhum dos tres. Terceiro achado da revisao de seguranca
# (issue #6530).
detached:
	@out=$$(mktemp) && GANJA_TEST_OUT=$$out test/stage.sh detached.qml >/dev/null 2>&1; \
	  python3 -c "import ast,sys; \
	    amb=dict(ast.literal_eval(open('$$out').read() or '[]')); \
	    sujas=[k for k in ('LD_PRELOAD','LD_AUDIT','LD_LIBRARY_PATH','PYTHONPATH','GANJA_VAZAMENTO') if k in amb]; \
	    print('FALHOU: o filho destacado herdou', sujas) if sujas else None; \
	    print('FALHOU: o filho nem rodou') if not amb else None; \
	    print('OK: gravacao de saida com ambiente fechado (' + str(len(amb)) + ' variaveis: ' + ', '.join(sorted(amb)) + ')') if amb and not sujas else None; \
	    sys.exit(1 if (sujas or not amb) else 0)"; \
	  rc=$$?; rm -f $$out; exit $$rc

glyphs:
	@python3 test/glyphs.py

test: check diff verify state hostile detached glyphs
