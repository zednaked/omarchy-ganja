# Publicar no marketplace de plugins do Omarchy

Levantado em 12/09/2026 a partir de <https://plugins.omarchy.org/publish.html>,
<https://plugins.omarchy.org/develop.html>, do `SUBMISSION.md` e do `SECURITY.md`
de <https://github.com/omacom/omarchy-plugin-marketplace>, e do próprio
validador instalado na máquina (`omarchy plugin validate`, que é um espelho dos
checks do `PluginRegistry.qml` — ler o script é a fonte mais confiável das
duas).

O diretório do marketplace tem dois endereços para a mesma coisa:
`omarchyplugins.com` redireciona (301) para `plugins.omarchy.org`.

---

## Onde isto está — 13/09/2026

| | |
|---|---|
| repo | <https://github.com/zednaked/omarchy-ganja>, público |
| versão | **1.2.4**, release `v1.2.0` no GitHub |
| submissão | issue [#6530](https://github.com/omacom/omarchy-plugin-marketplace/issues/6530), aberta, labels `submission, validated, needs-fixes` |
| validação automática | ✅ no `a574648` — "Ready for listing review"; a re-disparar no commit desta rodada |
| baseline de segurança | ✅ `passed` no `a574648`, sem achados e sem capacidades; idem |
| revisão humana | **quatro** rodadas com `HANCORE-linux` (COLLABORATOR), todas respondidas — seção 3b |
| falta | a decisão de mantenedor: o label `approved-and-verified`, que só eles aplicam |

**A regra que congela o repo até lá:** o HEAD tem que continuar igual ao commit
validado. Se empurrar qualquer coisa, edite o corpo da issue para re-disparar as
duas checagens — senão o site marca "Update unverified", que é o snapshot
verificado ficar para trás do código observado.

O que continua em aberto e não depende deles: o `diff` contra o Ganja-TUI de
verdade (precisa de `cargo`) e a otimização dos 30 ms por quadro. Seção 6.

---

## 1. O que o validador exige — **passando**

`omarchy plugin validate .` sai com 0 e sem uma linha de reclamação. O que ele
confere, item por item, e onde este plugin atende:

| check do validador | aqui |
|---|---|
| `manifest.json` na raiz, JSON válido | ✅ |
| `schemaVersion` exatamente o número `1` | ✅ |
| campos `id`, `name`, `version`, `kinds`, `entryPoints` | ✅ |
| `id` casando `^[A-Za-z0-9][A-Za-z0-9._-]*$`, sem `..` | ✅ `zed.ganja` |
| `id` fora do namespace reservado `omarchy.*` | ✅ |
| `kinds` array não vazio | ✅ `["bar-widget", "overlay"]` |
| `entryPoints` objeto, caminhos relativos seguros, arquivos existindo | ✅ |
| um `entryPoints` para cada kind que precisa (`barWidget`, `overlay`) | ✅ |
| `barWidget.defaultSection` ∈ left/center/right | ✅ `right` |
| **nenhum symlink dentro da pasta** (o `.git` é ignorado) | ✅ — ver abaixo |

**O symlink foi o único que reprovava.** `test/` tinha `Art.js`, `Grow.qml`,
`I18n.js` e `Strains.js` apontando para a raiz, porque um teste de QML precisa
estar no mesmo diretório do que testa. O validador recusa:

    omarchy-plugin-validate: symlinks are not allowed inside a plugin folder

Resolvido em `test/stage.sh`: os testes de QML rodam numa **cópia** temporária da
pasta do plugin, com um `$HOME` temporário. Não é só contornar a regra — passou
a testar uma cópia do que vai instalado, que é o que o instalador faz, e sem
risco de escrever na planta de quem está testando.

## 2. O que o marketplace exige além disso

| requisito | aqui |
|---|---|
| repositório **público** no GitHub | ✅ <https://github.com/zednaked/omarchy-ganja> |
| `manifest.json` na raiz do repo | ✅ (a raiz do repo **é** a pasta do plugin) |
| README na raiz, com instruções de instalação **e de remoção** | ✅ `README.md` — a seção "Remove" existe porque a checklist exige, e a primeira versão só tinha instalação |
| arquivo de licença na raiz, documentando dependências externas | ✅ `LICENSE` (MIT) e não há dependências |
| `author`, `license`, `description` no manifest | ✅ |
| `version` ≤ 64 caracteres | ✅ `1.2.0` |
| instalação e remoção limpas | ✅ é cópia de pasta; o save fica fora dela |
| imagem de preview (opcional, ≤ 50 MB e ≤ 40 megapixels) | ✅ `preview.png`, 1440×810, 190 KB — a sala em `full`, em inglês |

Formatos aceitos de preview: `.png`, `.jpg`, `.jpeg`, `.webp`, `.avif`.

## 3. O formulário de submissão

É uma issue no repo do marketplace, por template. O título **tem que** começar
com `[Plugin]:` e os cabeçalhos não podem ser reordenados nem removidos — isso
reprova automaticamente, antes de qualquer humano ler.

Campos, e o que preencher:

- **Repository URL** — `https://github.com/zednaked/omarchy-ganja`, sem barra no
  fim e sem caminho depois.
- **Category** — uma da lista: `Appearance`, `Desktop`, `Developer Tools`,
  `Hardware`, `Kids`, `Productivity`, `System`, `Widgets`, `Other`.
  **Sugestão: `Widgets`** — é um widget de barra com um overlay, e é isso que a
  pessoa está procurando quando acha o plugin. `Desktop` seria a segunda opção.
  (Cuidado: a grafia tem que casar exatamente.)
- **Tags** — de uma a três (mais de três reprova), da lista exata do template:
  `AI`, `Bar`, `Education`, `Games`, `Hyprland`, `Kids`, `Launcher`, `Media`,
  `Power management`, `Quickshell`, `Security`, `System`, `Workspaces`.
  **Sugestão: `Bar`, `Games`, `Quickshell`.**
- **Suggest a missing tag** — opcional. Nada a pedir.
- **Maintainer notes** — vale dizer três coisas, porque são exatamente as que um
  revisor procuraria: (1) é QML puro, sem binário e sem rede; (2) é porte do
  Ganja-TUI **do mesmo autor**, MIT, e o repo de origem é
  `github.com/zednaked/Ganja-TUI`; (3) escreve num único arquivo,
  `~/.local/share/zed.ganja/save.json`, e em nada mais.
- **Submission checklist** — cinco confirmações, todas obrigatórias:
  repo público com instruções de instalação e remoção; licença e dependências
  documentadas; propriedade do código e permissão sobre a imagem de preview; o
  plugin não sobrescreve configuração do usuário sem consentimento; e o
  entendimento de que *"approval is for listing and is not a security review"*.

Todas as cinco são verdade aqui. A quarta merece nota: o plugin **não** escreve
em `shell.json` nem em nada do usuário — quem o coloca na barra é o
`omarchy plugin enable` ou a mão de quem instalou.

Depois da issue: um scan automático no commit exato, e uma decisão explícita de
mantenedor (`approved-and-verified`) antes de publicar. Atualização é o mesmo
caminho: o snapshot listado continua valendo até o novo SHA passar.

## 3b. A revisão humana pediu mudança — e estava certa

Em 12/09/2026, `HANCORE-linux` (COLLABORATOR no repo do marketplace, revisa as
submissões dos outros) bloqueou a revisão com dois achados no `Grow.qml`. A
baseline automática tinha passado; isto é a revisão humana, que olha outra coisa.

O que ele apontou, e por que estava certo:

1. **Caminho interpolado em código de shell, e leitura sem limite.** O comando
   era montado concatenando o caminho dentro do texto do `sh -c`, e o
   `StdioCollector { waitForEnd: true }` guardava o arquivo inteiro sem teto de
   bytes nem prazo. Um `save.json` gigante enche a memória do processo do shell
   — que é o processo onde a barra inteira mora — e um FIFO no lugar do arquivo
   deixa o `cat` esperando para sempre.
2. **`.tmp` de nome previsível.** `save.json.$$.tmp` com `cat >` é alvo de
   symlink pré-posicionado: quem consegue criar arquivo no diretório faz a
   gravação sair em outro lugar. O caminho da descarga do shell repetia o erro.

A primeira resposta foi um `save.sh` endurecido: caminhos como argumentos,
`clearEnvironment`, teto de 1 MiB, `timeout`, cheques de não-symlink + arquivo
regular + dono, `mktemp` com O_EXCL, `sync` e `mv`. Eu escrevi na resposta que
abertura relativa a descritor com `O_NOFOLLOW` "não dava neste stack".

**Ele voltou, aceitou as correções e bloqueou justamente nisso** — e estava
certo nas duas vezes:

> Directory checks and file checks are separate from the later `head`, `mktemp`,
> `sync`, `mv`, and cleanup path resolutions. An accepted directory/file
> component can be exchanged between check and use; a timeout limits duration but
> does not prevent reading from or publishing into the substituted location.
> `mktemp` protects only the unpredictable leaf.

Em shell, cada comando resolve o caminho do zero: checar com `[ -f ]` e depois
usar `head`/`mv` são duas resoluções com uma janela no meio, e nenhum comando do
`sh` aceita descritor em vez de nome. O que estava errado na minha resposta não
era o diagnóstico, era o "não dá": **o `sh` não alcança `openat`, mas o Python
alcança.**

O remédio final é o `save.py`, e a garantia mudou de natureza: o caminho deixou
de ser um nome resolvido três vezes e passou a ser um **descritor** aberto uma
vez e mantido.

- descida componente por componente a partir de um fd do `$HOME`, cada passo com
  `openat(O_DIRECTORY | O_NOFOLLOW)` — symlink em qualquer ponto faz falhar, e
  não seguir (o `O_NOFOLLOW` de um `open` só protege o último componente, e era
  isso que faltava);
- arquivo validado **no fd de onde vai ser lido**: regular, nosso, `st_nlink == 1`
  (pega hardlink, que nenhum cheque de symlink pegaria), dentro do teto;
- gravação com `O_CREAT | O_EXCL | O_NOFOLLOW` relativo àquele fd, `fsync`,
  `renameat` no **mesmo** fd dos dois lados, `fsync` do diretório;
- teto de 1 MiB, `SIGALRM` em cinco segundos, `python3 -I` (ignora `PYTHON*`, o
  site do usuário e o diretório do script).

Custo: o plugin passou a depender de `python3`. É a única dependência de tempo
de execução além do Omarchy, e os scripts do próprio Omarchy já usam python3 —
está declarado nos dois READMEs.

`make hostile` (46 verificações hoje) é o teste dos cenários dele, inclusive os dois
que fecharam a última rodada: **symlink no meio do caminho** e **hardlink**.

A lição que vale registrar: "não dá neste stack" é uma afirmação sobre o que eu
sei, não sobre o que existe. Custou uma rodada de revisão.

### Terceira rodada: o caminho que roda sozinho

Ele aceitou o `save.py` para leitor e escritor e bloqueou no único lançamento
que sobrava fora da regra:

> `Component.onDestruction` calls `Quickshell.execDetached([...])`. Unlike the
> three `Process` objects, that detached launch does not apply
> `clearEnvironment`. Python isolated mode suppresses Python-specific
> path/site variables, but it does not sanitize loader/runtime variables before
> `/usr/bin/python3` starts.

Certo de novo, e é o achado mais fino dos três: a gravação de saída é a **única
que acontece sozinha**, e era a única que rodava sob o ambiente que estivesse
lá. O `-I` não ajuda porque o loader age antes do Python existir.

O `Quickshell.execDetached` tem duas formas, e só uma aceita ambiente: a de
lista herda tudo, a que recebe um `processContext` (tipo de valor do
`Quickshell.Io`, com `clearEnvironment` e `environment`) não. Medido antes e
depois, com `LD_PRELOAD` sujo no pai: **236 variáveis herdadas** virando
**3** (`HOME`, `LC_CTYPE`, `PATH`).

Detalhe de QML que custou uma tentativa: passar um objeto JS literal para
`execDetached` **não** converte para `processContext` ("Could not convert
argument 0"). Tem que existir uma propriedade declarada do tipo
(`property processContext ctx`) e o objeto ser atribuído a ela primeiro.

**E aí o conserto virou remoção.** Antes de responder, fui verificar se aquela
descarga de saída chegava a executar. Não chegava — medido de duas formas, com o
save apagado logo antes:

| experimento | o save voltou? |
|---|---|
| `qs -p …` + `Qt.exit(0)` | não |
| `Quickshell.reload()` | não |

O `Component.onDestruction` de um Singleton do Quickshell não roda no
encerramento do processo nem na recarga. Ou seja: o plugin prometia "grava ao
descarregar" desde o primeiro dia e nunca gravou, e o revisor estava analisando
um caminho que não executa — a pior categoria de código em revisão de segurança,
porque ninguém consegue testá-lo nem exercitá-lo.

Então a resposta final não foi endurecer: foi **remover**. Sai o
`Component.onDestruction`, sai o `execDetached` (o plugin não faz mais nenhum
lançamento destacado), sai o modo `writenow` do helper — que existia só para
aquele caminho e passava o save inteiro por argumento, visível no `ps` de
qualquer usuário da máquina.

No lugar da promessa falsa entrou uma garantia real: **gravar ao fechar a
sala**. O pior caso de um encerramento abrupto passou de "até dez minutos" para
"o que aconteceu desde que você fechou a janela".

### Quarta rodada: dono não é permissão

Com o `save.py` aceito na leitura, na gravação e na publicação, o que sobrou foi
o modo dos diretórios:

> `save.py:75-82` validates directory type and owner but never rejects group- or
> world-writable modes. `walk()` therefore accepts an existing user-owned
> writable-by-others component (including the final state directory) and then
> trusts that directory for `save.json` reads, replacement, and cleanup.

Procedente, e é o ponto cego de quem confere identidade: toda a defesa do
`save.py` prova **qual** diretório é aquele, e nenhuma linha perguntava **quem
mais pode escrever nele**. Um `~/.local/share` em 775 não precisa de symlink, de
corrida nem de hardlink — outra conta cria o `save.json` ali dentro e o helper
abre o fd certo, do diretório certo, com o conteúdo dela.

O conserto tem dois lados, e a diferença entre eles importa:

- **os componentes do meio** (`$HOME`, `.local`, `.local/share`) são recusados se
  tiverem `S_IWGRP` ou `S_IWOTH` — o teste entra no mesmo `fstat` que já conferia
  o dono, então não custa syscall nova nem abre janela. Apertar o modo deles
  seria decidir pelos outros: são diretórios de todo mundo, não do plugin;
- **o diretório de estado do plugin** é apertado para 700 com `fchmod` no
  descritor já validado, **antes** de qualquer leitura. Recusar ali seria pior
  que o problema: a leitura voltaria vazia, a planta começaria do zero e a
  gravação seguinte apagaria o save bom. Consertar mantém a planta e fecha o
  diretório no mesmo movimento.

O que o conserto **não** faz, e está dito no código: não desfaz o que outra conta
já tenha escrito ali antes. O que pega isso continua sendo o cheque do arquivo no
fd (dono e `st_nlink == 1`).

`make hostile` foi de 29 para 46 verificações. As novas: componente gravável por
grupo e por outros (recusa na leitura e na gravação, com o save intacto depois),
`$HOME` gravável por outros, diretório do plugin em 770 e em 777 (lê e sai em
700), e criação sob `umask 000` — que prova que o `0o700` do `mkdir` não depende
do umask de quem chama, já que o umask só tira bits.

O próprio `Palco` do teste passou a fixar o modo de cada componente: `makedirs`
só aplica o modo pedido na folha, e os do meio sairiam do umask da máquina — com
`umask 002` o teste reprovaria por causa do ambiente, e não do helper.

## 4. A baseline de segurança

O scan é estático (até 1000 arquivos, 8 MiB) e procura cinco padrões que
reprovam:

| padrão | aqui |
|---|---|
| `curl-pipe-shell` — download executado direto no shell | não existe: o plugin não acessa rede |
| `cargo-git-unpinned` — `cargo install --git` sem `--rev` completo | não existe: não há Rust nem build |
| `remote-git-execution-unpinned` | não existe |
| `sudoers-dangerous-passwordless-command` | não existe: nenhum `sudo`, nenhum `pkexec` |
| `privileged-process-control-from-shared-temp` — PID de `/tmp` para `sudo` | não existe |

E sete padrões que não reprovam mas pedem aprovação manual: `installer`,
`package-manager`, `remote-build`, `privilege`, `bundled-executable-binary`,
`service-management`, `sudoers-modification`. **Nenhum se aplica** — não há
instalador, nem pacote, nem binário, nem unidade de systemd.

Um plugin sem achados e sem capacidades de revisão recebe `passed`
automaticamente depois da aprovação. Este deve ser esse caso.

O que o scan **vai** ver e é bom que esteja explicado no código (e está): o
plugin lança `/usr/bin/python3 -I save.py`, sempre com `clearEnvironment` e
`{PATH, HOME}`, para ler, gravar e limpar temporário — três `Process`
supervisionados, nenhum lançamento destacado, e nada fora de
`~/.local/share/zed.ganja/`. Não há mais `sh` nenhum no plugin desde a segunda
rodada da revisão.

## 5. Submetido em 12/09/2026

**Issue: <https://github.com/omacom/omarchy-plugin-marketplace/issues/6530>**
(`[Plugin]: Ganja`, categoria Widgets, tags Bar/Games/Quickshell.)

**Atualizar o commit validado é editar a issue.** A validação e a baseline são
presas a um commit exato, e a primeira rodada olhou o `0a54942`. O workflow deles
(`route-issue-automation.yml`) roda em `issues: [opened, edited, reopened,
labeled, unlabeled]`, então editar o corpo da issue re-dispara as duas no HEAD
atual — sem abrir issue nova, e sem mexer no que o mantenedor já leu. O
formulário `[Verify]:` é para **listagens que já existem**, não para uma
submissão aberta: ele serve para promover um commit novo de um plugin já
publicado.

Cuidado ao editar: os cabeçalhos `###` têm que continuar na mesma ordem e as
cinco caixas marcadas. Cabeçalho faltando ou reordenado reprova antes de
qualquer humano ler. O corpo segue
o formato gerado pelo próprio template — os cabeçalhos `###` na ordem, os cinco
itens da checklist marcados — porque é assim que as submissões que passam se
parecem; conferi em duas issues abertas (#6525 e #6526, ambas com os labels
`submission, validated`) antes de escrever a nossa. Labels não dão para aplicar
de fora: quem não é colaborador do repo não tem permissão, e a automação deles
que rotula.

Feito antes de submeter, e por quê:

- `preview.png` — a sala em `full`, em inglês, sem ponteiro do mouse (o card do
  marketplace é lido em inglês).
- **`LICENSE` no Ganja-TUI** — o repo de origem declarava MIT no `Cargo.toml` e
  no README e não tinha o arquivo. A submissão pede "licença e dependências
  documentadas", e a procedência de um porte se verifica em um passo com o
  arquivo lá.
- **A cópia dentro do `omarchy-guest` saiu.** Eram duas cópias do mesmo QML, e a
  que alguém edita nunca é a que está instalada. O `plugins/zed.ganja/` foi
  removido de lá (com uma nota no README do guest apontando para cá), e a
  instalação da máquina passou a ser gerenciada por git:
  `omarchy plugin add https://github.com/zednaked/omarchy-ganja`. `omarchy
  plugin update zed.ganja` responde "up to date", e a planta sobreviveu à troca
  — o save nunca morou dentro da pasta do plugin.

## 6. O que continua em aberto

**O `diff` contra o Ganja-TUI de verdade.** Precisa de uma máquina com `cargo`,
rodando o TUI com as mesmas 8 seeds e os mesmos 8 dias e comparando com
`test/frames/`. Enquanto isso não acontecer, a fidelidade é declarada e não
comprovada — e o README diz isso com essas palavras. Ver `test/README.md`.

**A otimização do quadro.** 30 ms de CPU para desenhar 70×28 caracteres é caro
em uma ordem de grandeza; a causa provável é regerar a matriz inteira a cada
quadro. As 64 fixtures são o que garante que a otimização não muda a planta.
Não é urgente: só existe enquanto alguém olha, e agora o `p` zera até isso.

## 7. Coisas que **não** são exigidas, e por que ficam como estão

- **O `id` em DNS invertido.** A documentação sugere
  `io.github.<usuário>.<plugin>`, mas o validador só exige o formato e a saída do
  namespace `omarchy.*`, e o marketplace já lista `bobbynicholas.omaland`,
  `jankeesvw.downloads` e `ssupt.audio-control`. `zed.ganja` fica: é o prefixo
  dos outros plugins do mesmo autor, é o nome da pasta instalada, do
  `moduleName`, do `ipcTarget` e do diretório do save — trocar agora custaria uma
  migração em cinco lugares para ganhar nada.
- **README em inglês e em português.** O marketplace pede um README na raiz, e
  não pede idioma. O `README.md` é em inglês porque é a vitrine; o
  `README.pt-BR.md` é o longo, com os porquês, e o `SPEC.md` é o registro das
  decisões.
- **CI.** Não é exigido. `.github/workflows/test.yml` roda o que roda sem sessão
  gráfica (`make check`, `make diff`, `make glyphs`) mais os mesmos checks de
  manifest que o `omarchy plugin validate` faz, já que ele não existe no runner;
  `make verify` e `make state` precisam de Quickshell e ficam para a máquina de
  quem desenvolve. O primeiro run reprovou e valeu a pena: `fc-match` numa
  máquina sem Nerd Font devolve a DejaVu Sans em vez de dizer "não tenho", e o
  teste de glifos acusava os oito como ausentes. Agora ele reconhece a fonte
  errada e se declara pulado.
