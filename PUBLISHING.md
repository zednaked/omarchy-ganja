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
| repositório **público** no GitHub | ⬜ criar `github.com/zednaked/omarchy-ganja` |
| `manifest.json` na raiz do repo | ✅ (a raiz do repo **é** a pasta do plugin) |
| README na raiz, com instruções de instalação **e de remoção** | ✅ `README.md` |
| arquivo de licença na raiz, documentando dependências externas | ✅ `LICENSE` (MIT) e não há dependências |
| `author`, `license`, `description` no manifest | ✅ |
| `version` ≤ 64 caracteres | ✅ `1.1.0` |
| instalação e remoção limpas | ✅ é cópia de pasta; o save fica fora dela |
| imagem de preview (opcional, ≤ 50 MB e ≤ 40 megapixels) | ⬜ `preview.png` — ver seção 5 |

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
- **Tags** — de uma a três, da lista: `ai`, `bar`, `education`, `games`,
  `hyprland`, `kids`, `launcher`, `media`, `power-management`, `quickshell`,
  `security`, `system`, `workspaces`. **Sugestão: `bar`, `games`,
  `quickshell`.**
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
plugin roda `sh -c` para quatro coisas, todas locais e todas sobre o próprio
diretório de save — `cat` para ler, `mkdir -p` + `mv` para gravar de forma
atômica, e um `find -delete` de `.tmp` velho. Nenhuma delas toca em nada fora de
`~/.local/share/zed.ganja/`.

## 5. O que falta antes de submeter

1. **Criar o repo público** `github.com/zednaked/omarchy-ganja` e dar `push`.
   O commit inicial já está feito aqui.
2. **`preview.png`** — uma captura do overlay aberto, que é o que vende o
   plugin. Vale a growing room em `medium` com a planta em floração, o painel do
   strain à direita e os medidores embaixo. O ícone da barra não serve de
   preview: é um glifo de 16 px.
3. **Um `LICENSE` no Ganja-TUI também.** O repo de origem declara MIT no
   `Cargo.toml` e no README, mas não tem o arquivo. Como a submissão pede
   "licença e dependências documentadas" e este plugin é porte daquele código, a
   procedência fica mais fácil de verificar com o arquivo lá.
4. **Decidir o que acontece com a cópia dentro do `omarchy-guest`.** Hoje existem
   duas: `~/Projetos/omarchy-guest/plugins/zed.ganja/` e este repo. Duas cópias
   do mesmo QML divergem — é questão de semanas. As saídas, em ordem de
   preferência:
   - remover a pasta do `omarchy-guest` e instalar pelo
     `omarchy plugin add https://github.com/zednaked/omarchy-ganja` (o `install`
     do guest deixa de ter o que copiar, e a atualização passa a ser
     `omarchy plugin update zed.ganja`);
   - manter no guest como submódulo de git apontando para este repo;
   - manter as duas à mão, que é a que não se sustenta.
5. **Rodar `make test` na máquina** (precisa de `node`, `qs` e
   `python-fonttools`) e, se houver uma com `cargo`, fechar o `diff` contra o
   Ganja-TUI de verdade — é o único item da fidelidade que ainda é declarado e
   não comprovado. Ver `test/README.md`.

## 6. Coisas que **não** são exigidas, e por que ficam como estão

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
  gráfica (`make check`, `make diff`, `make glyphs`); `make verify` e
  `make state` precisam de Quickshell e ficam para a máquina de quem desenvolve.
