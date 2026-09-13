# zed.ganja

Uma planta de cannabis que cresce na sua barra.

O mesmo grow do [Ganja-TUI](https://github.com/zednaked/Ganja-TUI) — os 35 strains
com genética real, a mesma arte ASCII procedural de 70×28, o mesmo formato de
save — dentro do shell do Omarchy, em QML puro. Sem binário, sem processo
residente, sem Rust instalado. Fechada, a planta inteira custa **um Timer de 60
segundos** fazendo aritmética sobre números que já estão na memória.

Na barra: um glifo por estágio e um ponto que acende quando há o que fazer.
Clique esquerdo abre a growing room; **clique direito para e retoma a
simulação**; clique do meio rega.

Interface em **português ou inglês**, com a tecla `l` — e o padrão vem do locale
da máquina.

---

## Instalar

```sh
omarchy-guest install        # copia plugins/ para ~/.config/omarchy/plugins/
```

Depois, uma linha em `~/.config/omarchy/shell.json`, dentro de
`bar.layout.left`, `center` ou `right`:

```jsonc
{ "id": "zed.ganja" }
```

Ou, sem editar nada à mão:

```sh
omarchy-shell shell putBarWidget zed.ganja '{"section":"right"}'
```

O plugin só carrega se o id aparecer no `shell.json` — é assim que o
`PluginRegistry` decide o que está habilitado. Depois, **reinicie o shell**:

```sh
omarchy-restart-shell
```

Isso não é opcional nem é cerimônia: o Omarchy sobe o Quickshell com
`QS_DISABLE_FILE_WATCHER=1` de propósito, e nem `rescanPlugins` nem
`Qt.clearComponentCache()` trocam um QML de plugin já compilado. Enquanto não
reiniciar, uma edição no plugin não aparece — e não dá erro nenhum, o que é
pior. A planta nasce sozinha na primeira carga.

O save fica em `~/.local/share/zed.ganja/save.json`.

**Vindo da versão que morava dentro do `omarchy-guest`?** O save antigo
(`~/.local/share/omarchy-guest/ganja/save.json`) é lido uma vez, na primeira
carga, e migrado para o caminho novo — com a planta, as colheitas, o idioma e
tudo o mais. O arquivo antigo fica intacto: voltar também é só voltar.

O caminho mudou porque um plugin publicado por conta própria guardando dados com
o nome de outro projeto no caminho está errado; mudar sem levar a planta de quem
já tinha uma seria pior.

---

## Desinstalar

```sh
omarchy plugin remove zed.ganja
omarchy-restart-shell
```

Isso tira o plugin de `~/.config/omarchy/plugins/` e o id dele do layout da barra
no `shell.json`. Nada mais seu é tocado.

A planta **não** sai junto, de propósito: o save é a única coisa aqui que levou
tempo para existir, e desinstalar um plugin não é a mesma frase que "jogue a
planta fora". Para apagar ela também:

```sh
rm -rf ~/.local/share/zed.ganja
```

---

## Teclas

Dentro do overlay:

| tecla | o que faz |
|---|---|
| `w` | rega (+40, parando no topo da faixa ótima) |
| `n` | alimenta, NPK (+40, idem) |
| `a` | **modo automático**: a planta se cuida sozinha |
| `p` | **para/retoma a simulação** — parada, o plugin custa zero |
| `l` | idioma: português ⇄ inglês |
| `t` | tamanho da janela: full → large → medium → small → window |
| `h` | colhe, se estiver pronta |
| `v` | cicla as cores: Normal → Zen → Rainbow → Matrix |
| `f` | liga/desliga a **demonstração**: 130000x numa cópia |
| `Shift+F` | liga/desliga o **turbo**: 130000x na planta de verdade |
| `Tab` | abre/fecha a aba de colheitas |
| `q` / `Esc` | fecha |

Na barra, três botões:

| clique | o que faz |
|---|---|
| esquerdo | abre e fecha a growing room |
| **direito** | **para e retoma a simulação** |
| meio | rega |

Todos os três piscam o ícone, porque ação sem resposta visível parece que não
aconteceu. Regar era o clique direito e saiu de lá: parar é a decisão mais
consequente que existe do lado da barra — é a única que muda o que o plugin
custa e a única que dura depois de fechar a sessão. Regar continua tendo tecla,
IPC e o clique do meio.

Por IPC, para scripts e agentes:

```sh
omarchy-shell ganja toggle
omarchy-shell ganja water
omarchy-shell ganja feed
omarchy-shell ganja harvest
omarchy-shell ganja mode
omarchy-shell ganja auto
omarchy-shell ganja turbo
omarchy-shell ganja pause           # alterna; stop e start forçam um lado
omarchy-shell ganja lang pt         # ou en, ou "" para alternar
omarchy-shell ganja scale 400       # o ritmo, ou "" para só consultar
omarchy-shell ganja window medium   # ou "" para ciclar
omarchy-shell ganja status     # "Purple Kush · Floração · dia 61 · água 68% · npk 72%"
```

O que o IPC **devolve** segue o idioma escolhido; o que ele **aceita** não.
`ganja window medium` é o mesmo comando em qualquer idioma — um comando que
mudasse de nome junto com uma preferência de leitura é um script que quebra
quando alguém aperta `l`. Os ids antigos em português (`cheio`, `grande`,
`medio`, `pequeno`, `janela`) continuam sendo aceitos.

### Parar a simulação

`p`, ou o clique direito na barra. Parada:

- o `Timer` de 60 s **não corre** — não é um timer barato, é timer nenhum;
- o overlay não pede quadro: aberto, ele é uma foto, e diz que é;
- o ponto de alerta não pulsa (nada está piorando, então nada tem pressa);
- o ícone da barra troca o glifo do estágio por `󰒲` e **apaga** para 40%.

Apagar não é trocar de cor, e isso é de propósito: a regra da barra é que o
ícone segue o tema, e um ícone vermelho no meio de uma fileira de símbolos do
mesmo tom lê-se como erro do sistema, não como "o usuário desligou isto". O
desenho é `md-sleep` e não `md-pause` porque o widget de mídia do próprio shell
já usa o de pausa para outra coisa.

**Isto vai para o save**, como todo o resto que você mexe aqui: quem desligou o
relógio quer encontrá-lo desligado amanhã. Ligar qualquer um dos dois ritmos
rápidos retoma primeiro, porque um ritmo de 130000x atrás de um relógio parado
não teria efeito nenhum e a leitura óbvia disso é que o turbo quebrou.

O tempo aqui já é de sessão e não de parede (máquina desligada, planta parada),
então parar não tem preço nenhum a pagar depois: a planta não acorda com sede
nem morta, ela acorda exatamente onde foi deixada.

### Idioma

`l` alterna português e inglês, e a interface **inteira** troca: rodapé, painel
do strain, medidores, aba de colheitas, tooltip da barra, recados, retornos do
IPC, o formato de data e até a vírgula decimal (`18,5%` em português, `18.5%` em
inglês).

O dado do strain troca junto — `difficulty Easy` vira `dificuldade fácil`,
`Earthy, Sweet, Grape` vira `terroso, doce, uva`. A tradução é **por campo** e
não por palavra: "Medium" é dificuldade *média* e rendimento *médio*, e um
dicionário plano de palavra para palavra erraria o gênero em metade dos casos.

O primeiro idioma vem do locale (`LANG=pt_BR…` → português); daí em diante manda
a escolha, que vai para o save. O que o save guarda é sempre o **id** e nunca o
rótulo — `"window_mode": "medium"`, `"visual_mode": "Zen"` — senão o arquivo
trocaria de forma junto com o idioma e um save escrito em português não abriria
em inglês.

Nomes de strain nunca se traduzem: Purple Kush é Purple Kush.

### Modo automático

`a` liga o auto-cuidado do TUI, com os limiares e os valores exatos dele
(`src/app.rs:128`): água abaixo de 40 volta com +50, NPK abaixo de 50 volta com
+40. Com ele ligado a planta nunca passa fome nem sede, o ponto de alerta na
barra só acende para a colheita, e o cabeçalho mostra `AUTO`.

É o modo "só quero ver crescer". Desligado — que é o padrão — regar é a única
coisa que você faz, e é o que dá consequência ao abandono.

### Tamanho e tipo de janela

`t` cicla cinco modos, e o último é de outra espécie:

| modo | o que é |
|---|---|
| `full` | a tela inteira (padrão) |
| `large` | um cartão de até 1280×880, centralizado |
| `medium` | até 980×660 |
| `small` | até 720×450 — some o painel do strain e sobram água, NPK e a colheita |
| `window` | uma **janela de verdade**, que o Hyprland arruma junto com as outras |

Nos quatro primeiros a sala é uma camada sobre a tela e clicar fora fecha. No
`window` é uma toplevel comum: dá para deixar a planta num canto do workspace,
lado a lado com o que você está fazendo, em vez de abrir e fechar.

O modo escolhido vai para o save — preferência que volta ao padrão a cada boot
não é preferência. Isso vale para tudo o que você mexe aqui: idioma, cores,
tamanho de janela, automático, parada, turbo e o ritmo (`ganja scale`). As duas exceções são a
demonstração (que não pode, ver abaixo) e a aba de colheitas, que não é ajuste e
sim onde você estava olhando — a planta é o motivo da janela existir, então abrir
a sala mostra a planta.

Nos tamanhos menores a sala corta o que é leitura e mantém o que é
acompanhamento: primeiro sai o painel do strain, depois as linhas de medidor que
menos mudam. A planta nunca sai.

### Os dois modos rápidos

O fator original do Ganja-TUI — 130000x, o ciclo inteiro de 90 dias em 60
segundos — está aqui de duas formas, e elas são coisas diferentes. Por isso duas
teclas, e as duas são liga/desliga:

| | `f` — demonstração | `Shift+F` — turbo |
|---|---|---|
| roda em | uma **cópia** | a planta **de verdade** |
| escreve no save | nunca | sim |
| as colheitas contam | não | sim |
| ao desligar | a planta volta onde estava | fica onde chegou |
| fica salvo | não, e não pode | **sim** |
| sobrevive a fechar a sala | não | **sim** |
| cor no cabeçalho | âmbar | vermelho |

A demonstração é o que se grava para mostrar o plugin a alguém: do broto à
colheita na sua frente, e nada daquilo aconteceu. Deixada ligada, ela colhe e
replanta em loop — uma espécie de protetor de tela.

O turbo é para quando você quer chegar lá. É o TUI inteiro: o mesmo ritmo, as
mesmas consequências.

**A demonstração desliga sozinha quando a sala fecha; o turbo não.**

A demonstração simula sobre uma cópia: atrás de uma janela fechada ela gastaria
CPU para animar uma planta que ninguém vê e que vai ser jogada fora de qualquer
forma. E ela não pode ser salva, pela própria definição — gravar "nada disto
conta" seria gravar a intenção de simular um descartável no próximo boot.

O turbo fica, e vai para o save. Isto foi decidido ao contrário primeiro, com o
argumento de que um ritmo que queima um ciclo por minuto é coisa que se faz
olhando. O argumento estava certo sobre o risco e errado sobre de quem é a
escolha: quem roda em turbo por padrão tinha que religar em toda sessão, e um
ajuste que volta ao padrão sozinho não é ajuste, é uma pergunta repetida.

O risco continua avisado — cabeçalho vermelho com `·· TURBO 130000x ··` sempre
que está ligado — e agora está documentado em vez de impedido: com a sala
fechada, o turbo colhe a planta mais ou menos a cada minuto, então o histórico
de 100 colheitas roda inteiro em menos de duas horas.

---

## O relógio

O TUI roda a 130000x — o ciclo inteiro de 90 dias em 60 segundos. Isso está
certo para algo que você abre, olha crescer e fecha; numa barra significaria uma
colheita por minuto e um ícone piscando sem parar.

O **padrão publicado é `timeScale` 40**: um ciclo completo em ~57 horas de
sessão, ou seja **cerca de uma semana** de uso normal. Abrir a barra na quarta
mostra uma planta diferente da de segunda, que é o ponto inteiro de acompanhar
uma planta.

**Mas o ritmo é seu, e fica salvo:**

```sh
omarchy-shell ganja scale 400     # um ciclo por dia de trabalho
omarchy-shell ganja scale ""      # quanto está agora?
```

| ciclo dura | ritmo |
|---|---|
| 64 s | 130000 — isto é o turbo, e ele avisa em vermelho |
| ~1,2 h de sessão | 2000 |
| ~5,8 h ≈ um dia de trabalho | 400 |
| ~57 h ≈ uma semana (padrão publicado) | 40 |
| ~9 dias de sessão | 10 |

A sua escolha ganha do `manifest.json` e mora no save, então o padrão do plugin
continua sendo o que é para quem instala: uma planta que se acompanha, não uma
que se assiste.

`turboScale` no mesmo arquivo é o fator do `Shift+F`, e o padrão é o 130000 do
TUI.

**O tempo só corre com o shell rodando.** Máquina desligada, planta parada. Você
volta na segunda e ela está onde você deixou na sexta, não morta de sede. O
campo `last_tick` do save existe só para detectar um save mais novo — nunca para
avançar o relógio.

Água e NPK drenam a `careScale` (0,2 no padrão) da taxa do TUI. Com isso um vaso
cheio dura cerca de um dia de sessão: existe para dar consequência ao abandono,
não para virar tarefa diária.

---

## O ciclo não termina

Colheu, planta outra, automaticamente — dez dias depois de ficar pronta, como o
`auto_harvest` do TUI, só que aqui é o comportamento e não uma opção. `h` colhe
antes, se você não quiser esperar.

O que não se perde é o histórico. `Tab` abre, e ele são duas coisas:

- **o acumulado, que não expira** — quantas colheitas, quantos gramas no total,
  qualidade e canabinoides médios, o seu recorde de peso e a sua melhor
  qualidade (com o strain que fez), e a data da primeira;
- **as 100 últimas em detalhe** — strain, dia, peso, qualidade, THC/CBD e
  quantos sustos a planta levou.

O arquivo guarda 100 registros porque um save que cresce para sempre é um
vazamento com outro nome. O acumulado é separado, seis números atualizados em
cada colheita, e é ele que torna um ritmo rápido seguro: em turbo, as 100
rodam inteiras em menos de duas horas, e nada do que elas somaram se perde. É o
que separa uma planta bonita de algo que acumula — a décima colheita tem dez
histórias atrás dela, e a centésima ainda sabe da primeira.

---

## O save, e o TUI

Formato: os mesmos campos da serialização serde de `App` (`src/app.rs` do
Ganja-TUI), em arquivo próprio. Levar uma planta de um lado para o outro é uma
cópia de arquivo:

```sh
cp ~/.local/share/zed.ganja/save.json ~/.local/share/ganjatui/save.json
```

Toda leitura e toda escrita passam pelo `save.py`, o único lugar deste plugin
que toca o disco, chamado como `/usr/bin/python3 -I save.py <modo> <caminhos>`
com ambiente limpo. Os caminhos chegam como **argumentos** e são **relativos ao
`$HOME`** — o helper não aceita caminho absoluto.

O que ele garante, e como:

- **o caminho é descritor, não nome.** Partindo de um fd validado no `$HOME`,
  ele desce um componente por vez com `openat(O_DIRECTORY | O_NOFOLLOW)`. Um
  symlink trocado em qualquer ponto da corrente faz a abertura **falhar** em vez
  de seguir. Esse fd é mantido pela leitura, pela gravação, pelo fsync, pelo
  rename e pela limpeza — nada é re-resolvido desde a raiz depois disso;
- **nenhum diretório do caminho pode ser gravável por grupo ou por outros.**
  Identidade e dono não bastam: quem pode escrever num diretório troca o arquivo
  de dentro dele sem ser dono de nada, e o descritor seria o fd certo, do
  diretório certo, com o save de outra pessoa. O modo entra na validação de cada
  componente, no mesmo `fstat` que confere o dono. O diretório de estado do
  plugin — o único que ele cria — é apertado para 700 em vez de recusado:
  recusar a leitura faria a planta começar do zero e a gravação seguinte apagaria
  o save bom;
- **o arquivo é validado no fd de onde vai ser lido** — `fstat` diz que é
  arquivo regular (descarta FIFO, socket e dispositivo), que é nosso, que tem
  exatamente um link (então hardlink para arquivo de outro é recusado) e que
  cabe no teto de 1 MiB. Não há janela entre checar e usar: é o mesmo descritor;
- **a gravação publica sem re-resolver o pai.** O temporário é um nome aleatório
  criado com `O_CREAT | O_EXCL | O_NOFOLLOW` relativo àquele fd, modo 600;
  depois `fsync`, depois `renameat` no **mesmo** fd dos dois lados, depois
  `fsync` do diretório;
- **limitado e com prazo:** 1 MiB na leitura e na escrita, `SIGALRM` em cinco
  segundos, e `-I` para o interpretador ignorar `PYTHON*`, o site do usuário e o
  diretório do próprio script;
- **recusa aparece.** O código de saída e o stderr do helper são lidos em toda
  chamada: gravação recusada acende uma linha vermelha na sala ("não está
  gravando no disco") até uma gravação dar certo, e toda recusa vai para o log.
  Isto existe porque os cheques acima *recusam* — um `~/.local/share` gravável
  por outros passou a parar o save, e parada que ninguém conta custa a planta
  em silêncio;
- **ambiente fechado em todo caminho que existe.** Os três `Process` usam
  `clearEnvironment` com `PATH` e `HOME` e mais nada. Não há um quarto caminho:
  o plugin não faz lançamento destacado nenhum (ver abaixo), então nada roda
  fora dessa regra.

Essa forma saiu da revisão de segurança do marketplace
([#6530](https://github.com/omacom/omarchy-plugin-marketplace/issues/6530)), em
duas rodadas. A primeira versão interpolava caminho em código de shell e lia sem
limite — arquivo gigante, ou FIFO no lugar do save, esgotava ou travava o
processo onde a barra inteira mora — e usava um `save.json.$$.tmp` previsível
que um symlink pré-posicionado redirecionava. A segunda era um helper de shell
endurecido, e o revisor estava certo em bloquear também: em shell cada comando
re-resolve o caminho, então `[ -f ]` seguido de `head`/`mv` são duas resoluções
com uma janela no meio, e o `sh` não alcança `openat`, `renameat` nem
`O_NOFOLLOW`. O Python alcança. `make hostile` joga tudo de volta: FIFO, symlink
na folha, symlink no meio do caminho, hardlink, save gigante, temporário
plantado, diretório gravável por grupo ou por outros no meio do caminho, e modo
frouxo no diretório do próprio plugin.

**É por isso que o plugin precisa de `python3`** — a única dependência de tempo
de execução além do próprio Omarchy, e que os scripts do Omarchy já têm.

**Não existe gravação ao descarregar, e existia uma linha aqui dizendo que
sim.** O `Component.onDestruction` montava o snapshot e gravava com um
lançamento destacado — e nunca rodou. Medido de duas formas, com o save apagado
logo antes: saída do processo por `Qt.exit`, e `Quickshell.reload()`. O arquivo
não voltou em nenhuma das duas. Ou seja, a promessa era falsa desde o primeiro
dia, e o código era um caminho de execução que ninguém podia revisar nem testar
— e era o único lançamento destacado do plugin, que a revisão de segurança
apontou por herdar o ambiente. Foi removido, e não endurecido.

O que garante o save é o que sempre garantiu de fato: gravação em toda ação do
usuário, na virada de estágio, **ao fechar a sala**, e no máximo a cada dez
minutos. O pior caso de um encerramento abrupto são os minutos desde a última
dessas quatro.

Abrir o overlay relê o save: se o do disco for mais novo, ele
ganha. Última escrita vence, sem lock — e é por isso que não existe tecla de
releitura: o único caso que ela cobriria é o arquivo mudar com a sala já aberta,
e fechar e abrir faz o mesmo.

**Atenção, e isto é comportamento e não bug:** abrir o `ganjatui` por um minuto
com o save copiado consome um ciclo inteiro da planta. O TUI roda a 130000x e
não sabe que a planta dele mora numa barra. É exatamente o que o `Shift+F` faz
aqui — a diferença é que ali você não escolheu.

---

## Fidelidade

A arte é uma porta de `src/ascii/art.rs`, linha por linha, com os mesmos números
mágicos — inclusive os que parecem errados (o bloco de folhagem só pinta o
quadrante superior esquerdo porque sobrou da versão 35×14 da arte; está portado
como está lá, de propósito).

Duas coisas exigiram cuidado, e são a parte do projeto que podia ter saído
silenciosamente errada:

**O gerador de números.** `SimpleRng` é um LCG de 64 bits, e o motor de JS do
QML (V4, Qt 6.11) **não tem BigInt** — nem o literal `1n`, que é erro de
sintaxe e derruba o parse do arquivo inteiro, nem a função `BigInt()`, que é
`ReferenceError`. O estado de 64 bits é mantido em quatro limbs de 16 bits com a
multiplicação feita à mão. `Number` sozinho não serve: `lo * 1103515245` passa
de 2^53 e perde bits baixos em silêncio.

**A precisão.** O Rust calcula em `f32` e o JS em `f64`. Onde o resultado vira
inteiro (`as u32`, `.ceil()`) ou cruza um limiar (`> 0.5`), um bit muda um
caractere. Todo passo que era f32 lá passa por `Math.fround` aqui.

### O que está verificado, e o que não está

```sh
make test      # tudo
make check     # o LCG e as divisões de 64 bits contra o BigInt do Node
make diff      # a saída de hoje contra as fixtures de test/frames/
make verify    # as fixtures contra o motor de JS do QML
make state     # o Grow.qml de verdade: parada, idioma e o que o save leva
make refused   # gravação recusada acende o aviso em vez de sumir
make hostile   # FIFO, symlink, symlink no meio, hardlink, modo frouxo, save gigante
make glyphs    # os oito ícones da barra contra a fonte instalada
```

- **Verificado:** a aritmética de 64 bits feita à mão bate com `BigInt` em 14
  seeds × 4000 passos; o motor do QML produz os 64 frames de referência
  caractere por caractere idênticos aos do Node; os oito glifos da barra são os
  desenhos certos na fonte instalada — `make glyphs` existe porque a primeira
  versão pôs um logo de open source no lugar da muda, sem erro nenhum; e o
  `Grow.qml` de verdade passa por 55 verificações de estado (`make state`),
  incluindo a de que uma binding que chama `Grow.t()` re-avalia quando o idioma
  muda — sem isso a tela ficaria em duas línguas e nada apareceria no log.
- **Não verificado:** o `diff` contra o **Ganja-TUI de verdade**. Isso precisa de
  uma máquina com `cargo`, rodando o TUI com as mesmas 8 seeds e os mesmos 8
  dias e comparando com `test/frames/`. Enquanto esse passo não acontecer, a
  fidelidade aqui é **declarada, não comprovada**. Ver `test/README.md`.

---

## Divergências deliberadas

Seis, todas descendo da mesma decisão: isto mora numa barra, não numa janela
que você abre por um minuto. Estão marcadas com `DIVERGE` no código.

1. **O relógio é de sessão, não de parede.** `Utc::now() - last_tick` nunca é
   usado para recuperar o intervalo em que o plugin não existia.
2. **`days_alive` tem piso 1.** O TUI calcula `total_hours / 24`, o que dá dia 0
   no começo — e `calculate_stage(0)` cai no ramo `_`, "pronta para colher". Lá
   isso dura meio segundo; a 40x duraria 36 minutos, com um broto anunciando
   colheita.
3. **O auto-cuidado não vem ligado.** No TUI a planta se rega sozinha porque a
   ideia é assistir; aqui regar é o que você faz, e uma planta que se rega
   sozinha faz do `w` um botão que não liga nada. O comportamento do TUI
   continua inteiro atrás do `a`, com os mesmos limiares.
4. **Colher é o comportamento, não uma opção.** Por isso não existe a tecla `a`
   do TUI: não há auto-harvest para alternar.
5. **O Rainbow cicla o matiz por frame.** No Rust isso é um TODO e o matiz está
   parado; sem o ciclo o modo é só "cores diferentes", não psicodélico.
6. **A planta nasce no dia 5, e regar para no topo da faixa ótima.** O tronco só
   existe a partir de `day * growth_rate >= 1`, então os dias 1 a 4 são um vaso
   com terra e nada mais — três segundos no TUI, três horas aqui, e justo as
   três primeiras depois de instalar. E `calculate_health` chama de crítica a
   planta com água acima de 95: no TUI o auto-cuidado nunca chega lá, aqui dois
   cliques chegariam, e um botão que pune quem o aperta está errado.

Uma coisa a mais que o TUI não tem: as três cores que lá eram nomes de ANSI
(`Color::Green` no caule de muda, `Color::DarkGray`, `Color::Yellow` nos
primeiros cálices) precisaram virar RGB, porque nome de ANSI não carrega cor —
quem decide é o terminal. Estão em `Palette.js`, escolhidas dentro da própria
paleta do Ganja.

---

## Custo

| estado | custo |
|---|---|
| shell carregado, overlay fechado | 1 Timer de 60 s, aritmética pura, 0 IO |
| **parada** (`p`, ou clique direito na barra) | **nada**: nenhum timer, nenhuma animação, nenhum IO |
| overlay aberto | 10 quadros/s: 70×28 células + a animação |
| overlay aberto e parada | 1 repintura por ação, e mais nada |
| ação do usuário | 1 escrita atômica de JSON |
| boot do shell | 1 `cat` do save |
| a cada 10 min, na virada de estágio, ou ao fechar a sala | 1 escrita atômica de JSON |

A última linha é um acréscimo à SPEC, que pedia escrita só em ação do usuário.
Sem ela, um shell que reinicia sem descarregar direito perde as horas
acumuladas — que é o único bem que esta planta tem.

Não há `inotifywait` aqui, ao contrário do `zed.quadro`: ninguém escreve no save
pelas costas exceto o próprio TUI, e para isso já existe a releitura ao abrir.

---

## Arquivos

```
manifest.json    schemaVersion 1, kinds bar-widget + overlay, timeScale, careScale
qmldir           singleton Grow + Room (assim que existe qmldir, ele é a lista)
Grow.qml         estado, save, relógio, simulação  (a metade acordada)
BarWidget.qml    o glifo, o alerta, o tooltip
Ganja.qml        as janelas, as teclas, o IPC
Room.qml         o que se vê por dentro, igual nas duas janelas
Art.js           porta de ascii/art.rs - SimpleRng, PlantStructure, render
Palette.js       porta de ui/colors.rs - as quatro paletas
I18n.js          todo o texto de tela, nos dois idiomas, e o vocabulário do strain
save.py          o único código que toca o disco - preso a fd, limitado, atômico
Strains.js       gerado de strains.json por `make strains`
test/            fixtures de frame, o harness de Node, o de QML e o de estado
```

`Strains.js` é gerado, não editado à mão:

```sh
make strains GANJA_TUI=~/Projetos/Ganja-TUI
```

---

MIT, como o Ganja-TUI. A planta é do ZeD; a barra é do Omarchy.
