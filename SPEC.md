# zed.ganja — plugin de Omarchy shell baseado no Ganja-TUI

Uma planta que cresce na sua barra. O mesmo grow do `Ganja-TUI`, o mesmo save,
a mesma arte ASCII, dentro do shell do Omarchy em vez de dentro de um terminal.

Referências locais (já clonadas):

    ~/Projetos/Ganja-TUI          # a origem — Rust + ratatui, MIT, do autor
    ~/Projetos/omarchy-guest      # onde o plugin vai morar e como se instala
    ~/Projetos/omarchy-guest/plugins/zed.quadro   # o plugin-modelo, ler antes

---

## 1. Decisões já cravadas

Estas não são para rediscutir. Estão aqui com o porquê para que a implementação
não as desfaça por acidente.

**QML puro, sem Rust, sem processo residente.** O plugin não executa
`ganjatui`, não parseia TUI e não embute binário. A simulação é pequena
(`domain/plant.rs` 252 linhas + `domain/genetics.rs` 124 + `ascii/art.rs` 617) e
inteiramente determinística. Portar é traduzir, não reinventar. Isso é o que
permite prometer "ultra leve": o custo do plugin fechado é uma variável em
memória.

**Save próprio, formato compatível.**
`~/.local/share/omarchy-guest/ganja/save.json`, com os mesmos campos do save do
TUI, de modo que importar ou exportar uma planta seja uma cópia de arquivo.

Compartilhar o arquivo era mais bonito e está descartado por um motivo duro: o
TUI avança pelo relógio de parede e o plugin não (seção 4b). Com um save só, uma
sessão de TUI queimaria a planta da barra, ou o plugin teria que mentir sobre o
tempo do TUI. Dois relógios diferentes não cabem no mesmo arquivo.

**Fidelidade visual é requisito, não aspiração.** O ASCII sai de
`render_plant_structure`, que garante 70 colunas × 28 linhas sempre. A porta
QML tem que produzir a mesma matriz de caracteres para a mesma seed e o mesmo
dia. Ver seção 6.

**Widget de barra segue o tema do Omarchy. Overlay segue a paleta do Ganja.**
Essa é a linha, e ela não é arbitrária: um ícone com cor própria no meio da
barra quebra a barra, e uma planta repintada com o accent do tema deixa de ser
a planta. Barra usa `bar.barForeground` e `Color.accent`, como o `zed.quadro`.
Overlay usa os RGB literais de `src/ui/colors.rs`.

**Sem timer quando o overlay está fechado.** Igual ao `zed.quadro`: a metade
pesada dorme. A barra precisa saber só o estágio e se há alerta, e isso é
aritmética sobre `last_tick`, sem IO.

---

## 2. Onde mora

    ~/Projetos/omarchy-guest/plugins/zed.ganja/
      manifest.json      # schemaVersion 1, kinds ["bar-widget","overlay"]
      qmldir             # singleton Grow 1.0 Grow.qml
      Grow.qml           # singleton: estado, save, relógio, simulação
      BarWidget.qml      # a metade que fica acordada
      Ganja.qml          # o overlay: as janelas, as teclas, o IPC
      Room.qml           # o que se vê por dentro, igual nas duas janelas
      Art.js             # porta de ascii/art.rs (gerador procedural)
      Palette.js         # porta de ui/colors.rs (4 paletas × 4 modos visuais)
      I18n.js            # todo o texto de tela, nos dois idiomas, ver seção 14
      Strains.js         # gerado de strains.json, ver seção 7

Instala junto com o resto por `omarchy-guest install`, que copia (não
symlinka) para `~/.config/omarchy/`. Não inventar mecanismo de instalação novo.

---

## 3. O contrato com o save

Formato: os mesmos campos da serialização serde de `App` (`src/app.rs`), em
arquivo próprio do plugin. Campos que importam:

| Campo | Uso no plugin |
|---|---|
| `plant.total_hours_elapsed` | relógio do grow, em horas de jogo |
| `plant.days_alive` | `total_hours_elapsed / 24` |
| `plant.water_level`, `nutrient_level` | 0–100, drenam com o tempo |
| `plant.genetics` | strain, split indica/sativa, THC/CBD, floração |
| `plant.care_history` | horas em faixa ótima, eventos de estresse |
| `plant.seed` (uuid/u64) | **determina a estrutura da planta inteira** |
| `visual_mode` | Normal / Zen / Rainbow / Matrix |
| `last_tick` | RFC3339 UTC, base do cálculo de tempo decorrido |

**Leitura:** uma vez, na carga do shell, via `Process` + `cat`, igual ao
`Board.qml`. Não ficar relendo.

**Escrita:** só quando o usuário age (regar, nutrir, colher, trocar modo
visual) e ao descarregar. Sempre atômica: escrever em `save.json.tmp` no mesmo
diretório e `mv`. Nunca escrever por cima direto — o TUI pode estar aberto.

**Duas instâncias do shell:** não tentar resolver com lock. Reler o save quando
o overlay abrir e, se for mais novo que o da memória, adotar o do disco. Última
escrita vence.

---

## 4. O relógio — e um problema que precisa de decisão

`src/app.rs:104`:

    let hours_elapsed = (elapsed_seconds / 3600.0) * 130000.0;

São 36,1 horas de jogo por segundo real. O ciclo inteiro são 2160 horas
(90 dias), ou seja **o grow completo dura 60 segundos**.

Isso está certo para um TUI que você abre, olha crescer e fecha. Está errado
para uma planta que mora na sua barra: ela colheria sozinha a cada minuto e o
widget viraria ruído piscando.

Fator para um ciclo completo em tempo real:

| Ciclo dura | Fator |
|---|---|
| 60 s (TUI hoje) | 130000 |
| 1 dia | 90 |
| 1 semana | 12,86 |
| 1 mês | 3 |

**Implementar como `timeScale` no `manifest.json`, default 12,86** (um grow por
semana). O save continua compatível: `total_hours_elapsed` é acumulado em horas
de jogo, e só a taxa de conversão muda. Abrir o TUI depois continua funcionando
— acelera, só isso.

### 4b. O tempo só corre com o shell rodando

Decidido em 11/09/2026, e é o requisito que decidiu o formato do save.

**O relógio do plugin é tempo de sessão, não relógio de parede.** Máquina
desligada, planta parada. Você volta na segunda e ela está onde você deixou na
sexta, não morta de sede.

Implementação: acumular tempo por tick enquanto o shell roda, e **nunca** usar
`Utc::now() - last_tick` para recuperar o intervalo em que o plugin não existia.
`last_tick` é gravado só para detectar save mais novo, não para avançar nada.
Esta é a única divergência deliberada em relação ao `update.rs` do TUI.

Consequência no fator: com uso de ~8 h por dia, uma semana de calendário são
~56 h de sessão. **`timeScale` default 40** (2160 ÷ 56 ≈ 38,6, arredondado).
Quem usa a máquina o dia inteiro vê um ciclo mais curto, e isso está certo — a
planta acompanha quem está lá.

### O ciclo não termina

Colheu, planta outra, automaticamente. Não existe tela de "sua planta está
pronta, o que deseja fazer": o `auto_harvest` do TUI aqui é o comportamento
único, não uma opção.

O que **não** pode se perder é o histórico. Cada colheita grava strain, dia,
peso, qualidade e os eventos de estresse (`src/domain/harvest.rs`), e o overlay
tem uma aba com as anteriores. É o que transforma "uma planta bonita" em algo
que acumula: a décima colheita tem dez histórias atrás dela.

Limite de 100 colheitas no arquivo, descartando as mais antigas. Um save que
cresce para sempre é um vazamento com outro nome.

### O propósito é contemplativo, tipo cbonsai

Decidido em 11/09/2026. Isto não é um jogo de gerenciamento, é uma planta que a
pessoa acompanha. O valor está em **ver o desenvolvimento**, e desenvolvimento
que termina em um minuto não é desenvolvimento, é animação.

**Do cbonsai vem só o ritmo, nunca a planta.** Isto é cannabis, os 35 strains e
a genética do `Ganja-TUI`, e continua sendo em qualquer decisão futura. Nada de
bonsai, nada de gerador de árvore genérica, nada de "modo planta alternativa".
A referência é de comportamento: algo que fica no canto da tela e cresce devagar.

Daí o default de uma semana: tempo suficiente para que abrir a barra na
quarta-feira mostre uma planta diferente da de segunda. Água e nutrientes
existem para dar consequência ao abandono, não para virar tarefa diária.

### 4c. O turbo é preferência, e fica salvo — decidido em 12/09/2026

Esta seção revisa o que está escrito abaixo: que o turbo não vai para o save e
se desliga ao fechar a sala.

O argumento de lá — um ritmo que queima um ciclo por minuto é coisa que se faz
olhando, e se sobrevivesse à janela fechada a planta iria embora sem ninguém ver
— estava certo sobre o risco e **errado sobre de quem é a escolha**. Quem roda
em turbo por padrão tinha que religar em toda sessão, e um ajuste que volta ao
padrão sozinho não é ajuste: é uma pergunta repetida.

Então: `turbo` vai para o save, sobrevive a fechar a sala e a reiniciar o shell,
e `paused` manda sobre ele (os dois nunca são verdade ao mesmo tempo). O risco
continua avisado em vermelho no cabeçalho e passou a estar **documentado em vez
de impedido**: com a sala fechada, o turbo colhe mais ou menos a cada minuto, e
o histórico de 100 colheitas roda inteiro em menos de duas horas.

A demonstração (`f`) continua fora do save, e não por precaução: ela é definida
como "nada disto conta" e roda sobre uma cópia que o desligar joga fora. Gravar
seria gravar a intenção de simular um descartável no próximo boot, que não é
estado que alguém possa restaurar.

A regra geral que sai daqui, e que vale para o resto: **tudo o que o usuário
muda fica salvo.** Idioma, cores, tamanho de janela, automático, parada, turbo.
As exceções precisam de um motivo que não seja "é arriscado" — a demonstração
tem (não é estado), e a aba de colheitas tem (não é ajuste, é onde a pessoa
estava olhando, e a planta é o motivo da janela existir).

### 4d. O ritmo é preferência do usuário, não número do manifest — 12/09/2026

O `timeScale` 40 da seção 4b continua sendo o **default publicado**, e continua
com o argumento inteiro: uma planta que se acompanha, não uma que se assiste.

O que mudou é que ele deixou de ser a única palavra. `ganja scale <n>` grava o
ritmo no save, e o save ganha do manifest. A implementação usa dois campos
(`timeScale`, do manifest, e `userScale`, do save) com precedência explícita, e
não um sobrescrevendo o outro, porque a ordem de carga não é garantida: o
manifest chega pelo `Ganja.qml` e o save chega por um `Process` assíncrono.

A alternativa era trocar o 40 por 400 no `manifest.json`, e ela está descartada
por um motivo que vale para qualquer plugin publicado: **o gosto do autor não é
o default de quem instala.** O autor roda rápido; o default continua sendo o
ritmo contemplativo, e quem quiser o dele tem um comando.

### 4e. O acumulado das colheitas não expira — 12/09/2026

O teto de 100 colheitas da seção 4 continua (um save que cresce para sempre é um
vazamento com outro nome). Mas com o turbo salvo e ritmos rápidos disponíveis,
esse teto virou uma perda real: a 130000x sai uma colheita a cada ~64 s, e as
100 rodam inteiras em 1h46. Duas horas apagariam todo o passado da planta — que
é justamente o que a seção 4 diz ser o valor do plugin.

Então o histórico passou a ser duas coisas:

- **`harvest_history`**, as 100 últimas em detalhe, como antes;
- **`lifetime`**, seis números que nunca morrem: gramas somadas, somas de
  qualidade e canabinoides (divididas pelo contador vitalício para dar médias),
  recorde de peso e melhor qualidade com os strains que os fizeram, e a data da
  primeira colheita.

Isso também consertou uma linha que já mentia: o resumo somava a lista para
dizer "g no total" ao lado de um contador vitalício de colheitas — duas unidades
diferentes na mesma frase, e a errada era a que impressionava.

Save antigo sem `lifetime`: o acumulado nasce **somando a lista que está lá**.
Para quem nunca passou de 100 o número sai exato; para quem passou, nasce menor
que a verdade, e isso é melhor que nascer zero.

**E o 130000x não some — vira botão.** Segurar `f` no overlay roda no fator
original e a planta cresce na sua frente, do broto à colheita, em 60 segundos.
É o modo demonstração, e é o que se grava para mostrar o plugin aos outros.
Ao soltar, volta ao ritmo lento sem alterar o estado: o modo rápido **simula em
cima de uma cópia**, nunca escreve no save.

Consequência a documentar no README do plugin: abrir o TUI por um minuto
consome um ciclo inteiro da planta da barra. É comportamento, não bug, mas
precisa estar escrito.

---

## 5. O widget de barra

Espelhar `zed.quadro/BarWidget.qml` na estrutura: `Panel`, `BarIconButton`,
`moduleName: "zed.ganja"`, `ipcTarget: "zed.ganja.widget"`, `defaultSection`
`"right"`.

**Ícone:** um glifo por estágio, não a planta inteira — 70×28 não cabe na barra
e reduzir a arte a 3 caracteres a descaracteriza. Seed/Germination/Seedling/
Vegetative/PreFlower/Flowering/ReadyToHarvest, sete glifos, todos na cor da
barra.

**Alerta:** ponto pulsante, exatamente como o quadro faz, e pelo mesmo
argumento — ou tem coisa a fazer, ou não tem. Acende quando:

- a planta está pronta para colher, ou
- `water_level < 20` ou `nutrient_level < 20` (as mesmas faixas de
  `water_color`/`nutrient_color`, que já viram vermelho aí)

**Tooltip:** strain, estágio, dia. Uma linha. `"Purple Kush · Flowering · dia 61"`.

**Clique:** esquerdo abre o overlay. Direito rega. O direito é atalho de
conveniência e precisa de feedback — um flash no ícone, porque ação sem
resposta visível parece que não aconteceu.

**Timer:** um, de 60 s, fazendo aritmética pura sobre `last_tick`. Nenhum IO.
A 60 s e `timeScale` 90, cada tick avança 1,5 h de jogo — resolução de sobra
para um ícone.

---

## 6. O overlay — e o teste de fidelidade

O overlay é a growing room: a planta ao centro, gauges de água e nutrientes,
stats do strain. Ler `src/ui/growing.rs` e `src/ui/stats.rs` para a composição
e as bordas animadas (`get_border_decoration`, `get_water_drops`,
`get_nutrient_sparkles`).

**Fonte:** `Style.fontFamily` do shell, como o `zed.quadro` faz — e pelo motivo
que está escrito lá: a primeira versão do quadro nomeou uma fonte que a máquina
não tinha e a tipografia escolhida nunca aconteceu. Tem que ser monoespaçada e
tem que ter altura de linha fixa, senão 70×28 desalinha.

**A porta do ASCII é o risco do projeto inteiro.** `render_plant_structure`
tem caminhos para tronco, bifurcações, galhos com curvatura, folhagem por
densidade, flores por intensidade, e quatro conjuntos de caractere de tronco
animados por estágio. Portar isso "no olho" produz uma planta parecida, e
parecida não é o pedido.

**Como verificar, sem instalar Rust:** o teste é caractere a caractere e não
precisa de compilador se a comparação for feita contra saída gravada.

1. Gerar no plugin, para um conjunto fixo de seeds (ex.: 8) e dias
   (1, 5, 15, 30, 46, 53, 70, 90), a matriz 70×28.
2. Guardar como fixtures em `test/frames/<seed>-<day>.txt`.
3. Quando houver uma máquina com `cargo`, rodar o TUI com as mesmas seeds e
   comparar com `diff`. Divergência de um caractere é falha.

Enquanto o passo 3 não acontece, o README do plugin diz que a fidelidade é
**declarada e não verificada**. Não afirmar 100% antes do diff.

**`SimpleRng`:** o gerador em `art.rs` é próprio. Portar exatamente, com a
mesma aritmética de inteiros — em JS isso significa `Math.imul` e `>>> 0` nos
pontos certos, porque overflow de u64 em `Number` silenciosamente diverge.
Esta é a fonte mais provável de "a planta ficou diferente".

**Modos visuais:** os quatro (`Normal`, `Zen`, `Rainbow`, `Matrix`) ficam, e o
`v` cicla, igual ao TUI. `Rainbow` faz ciclo HSV por frame; `Zen` respira
devagar. São parte do estilo, não enfeite.

**Teclas:** manter as do TUI onde fizer sentido — `v` cicla visual, `a` alterna
auto-harvest, `h` colhe, `q`/Esc fecha. Regar e nutrir precisam de tecla
própria (não existem no TUI, que rega sozinho); usar `w` e `n`.

---

## 7. Strains

`strains.json` tem os 35 strains com genética real. Gerar `Strains.js` a partir
dele num passo de build simples (um `jq` no Makefile), não copiar à mão e não
ler o JSON em runtime. São dados estáticos.

---

## 8. Custo — o que roda quando

Isto é o critério de aceite do "ultra leve". Se algum item crescer, o plugin
falhou no próprio propósito.

| Estado | Custo |
|---|---|
| Shell carregado, overlay fechado | 1 Timer de 60 s, aritmética pura, 0 IO |
| Overlay aberto | render de 70×28 células + animação por frame |
| Ação do usuário | 1 escrita atômica de JSON |
| Boot do shell | 1 `cat` do save |

Nenhum `inotifywait` aqui — ao contrário do quadro, ninguém escreve no save
pelas costas exceto o próprio TUI, e para isso já existe a releitura ao abrir.

---

## 9. Fora de escopo

- Múltiplas plantas / grow room com vários vasos.
- Notificação de sistema quando a planta está pronta. O ponto na barra basta.
- Qualquer coisa que exija o binário Rust instalado.
- Mexer no `Ganja-TUI`. O repo de origem não é tocado por este projeto.

---

## 10. Ordem de implementação

1. `Grow.qml` — ler o save, expor estágio/água/nutrientes, o Timer de 60 s.
2. `BarWidget.qml` — ícone, alerta, tooltip. Já é útil sozinho.
3. `Palette.js` — as quatro paletas, valores literais de `colors.rs`.
4. `Art.js` — `SimpleRng`, `PlantStructure`, `render_plant_structure`.
5. `Ganja.qml` — overlay, gauges, stats, teclas, aba de colheitas.
6. Fixtures de frame e o `diff` contra o TUI.

O passo 2 entrega valor antes do passo 4 existir. Se o projeto parar no meio,
para num lugar que funciona.

---

## 11. Perguntas abertas (para o Thiago)

1. ~~`timeScale` default~~ — resolvido: uma semana, propósito contemplativo.
2. ~~Save compartilhado~~ — resolvido pelo requisito do tempo de sessão: save
   próprio, formato compatível.
3. ~~Repo público ou privado~~ — resolvido em 11/09/2026: **constrói primeiro
   dentro do `omarchy-guest`**, e a publicação (omarchyplugins.com ou repo
   próprio) se decide depois, com a coisa funcionando na frente.

   A ordem não custa nada: um plugin que já nasce em `plugins/zed.ganja/` sai de
   lá por cópia de pasta no dia em que a decisão for tomada. Não há dívida
   técnica em adiar isso, só em adiar o contrário.

---

## 12. Medido em 11/09/2026, com o plugin rodando

Primeira medição real, no shell do Thiago (12 plugins carregados, 65 min de vida):

| | |
|---|---|
| Overlay **fechado** | indistinguível do ruído — o desenho todo está atrás de `opened` |
| Overlay **aberto** | 22–40% de um núcleo, contínuo |
| Taxa | 10 quadros por segundo |
| **Custo por quadro** | **~30 ms de CPU** |

**O conceito está certo e a implementação do quadro não.** 30 ms para desenhar
70×28 caracteres é caro em uma ordem de grandeza. A causa provável é regerar a
matriz inteira a cada quadro, quando o que muda entre quadros é o caractere do
tronco, a cor e a respiração.

**Otimização pendente:** guardar a matriz de caracteres entre quadros e refazê-la
só quando o dia avança. Alvo: ~3 ms por quadro. O teste de fidelidade existente
(64 frames) é o que garante que a otimização não muda a planta — rodar `make
test` antes e depois, e exigir os mesmos 64 arquivos idênticos.

**Não é urgente.** Não vaza, não cresce, e só existe enquanto alguém olha.

---

## 13. Parar a simulação — decidido em 12/09/2026

O pedido é poder deixar o plugin **gastando zero**, e a promessa "ultra leve"
tinha um piso que não era zero: um Timer de 60 s é barato, mas existe, e com o
overlay aberto são 10 quadros por segundo a ~30 ms cada (seção 12).

**`paused`, e parada quer dizer parada:**

| | |
|---|---|
| o Timer de 60 s | não corre (`running: loaded && !paused`) |
| o timer de animação do overlay | não corre — aberto, a sala é uma foto |
| o ponto de alerta | não acende, e portanto não pulsa |
| IO | nenhum, exceto a escrita da própria mudança de estado |

**Onde se aperta: clique direito no ícone da barra**, e `p` dentro da sala.
Regar, que era o clique direito, vai para o clique do meio. A troca não é
gratuita e o motivo é de hierarquia: parar é a única ação do lado da barra que
muda o que o plugin custa e a única cujo efeito sobrevive à sessão. Regar tem
tecla, IPC e o clique do meio; parar precisa do botão que todo mundo tenta.

**Como se vê: glifo diferente e o ícone apagado** — `md-sleep` no lugar do glifo
do estágio, a 40% de opacidade. **Não** é cor própria, e isso segue a linha da
seção 1: cor própria no meio da barra lê-se como erro do sistema, não como
escolha do usuário. O desenho é `md-sleep` e não `md-pause` porque o widget de
mídia do shell já usa o de pausa para dizer outra coisa na mesma barra.

**Vai para o save**, ao contrário do turbo e da demonstração (seção 4b). Os dois
rápidos se desligam sozinhos porque queimam a planta sem ninguém ver; a parada
não gasta e não perde nada, e quem desligou o relógio quer encontrá-lo desligado
amanhã. Ligar turbo ou demonstração retoma primeiro: 130000x atrás de um relógio
parado não faria nada, e "não fez nada" se lê como defeito.

Isto só é indolor porque o relógio já era de sessão e não de parede: parar não
cria uma dívida de tempo para pagar depois.

---

## 14. Os dois idiomas — decidido em 12/09/2026

A interface era portuguesa com os dados em inglês: o rodapé dizia "w rega · n
alimenta" e o painel ao lado dizia "difficulty Easy   yield High". Nenhum dos
dois estava errado sozinho; juntos liam como tradução pela metade.

**`I18n.js`: uma tabela, duas línguas, e todo texto de tela passa por ela.**
Barra, sala, recados e retornos de IPC. A chave que falta aparece na tela como
ela mesma (`msg.watered`), porque devolver vazio esconderia.

**A escolha é do usuário, não do sistema:** `l` alterna, o primeiro valor vem do
locale, e a escolha vai para o save como qualquer preferência.

Quatro regras que isto segue, e que a implementação não deve desfazer:

1. **O save guarda o id, nunca o rótulo.** `window_mode: "medium"`,
   `visual_mode: "Zen"`. Por isso os ids de janela, que eram em português,
   passaram a ser em inglês — com os antigos aceitos na leitura. Um arquivo que
   trocasse de forma junto com o idioma não abriria na outra língua.
2. **O que o IPC devolve segue o idioma; o que ele aceita, não.** Quem lê
   `status` está lendo; quem escreve `window medium` está programando, e um
   comando que muda de nome com uma preferência de leitura é um script que
   quebra quando alguém aperta `l`.
3. **O inglês é o do Ganja-TUI onde o TUI tem a palavra** — `stage.*` é
   `GrowthStage::display_name`, `mode.*` é `VisualMode::name`, caractere por
   caractere. Foi por isso que essas duas funções saíram de `Art.js` e de
   `Palette.js`, que são portes de `art.rs` e `colors.rs`.
4. **O dado do strain se traduz por campo, não por palavra.** "Medium" é
   dificuldade *média* e rendimento *médio*: um dicionário plano erraria o
   gênero em metade dos casos. São 8 terpenos, 30 aromas, 11 efeitos e 12 termos
   de enum — finito e conferido.

Localizar é mais que traduzir: o formato de data e a vírgula decimal também
trocam (`18,5%` / `18.5%`). Nome de strain nunca se traduz.

O que **não** foi feito: o README do plugin continua só em português, e a
interface tem duas línguas e não N. Um `.ts` do Qt com `qsTr()` seria o caminho
para a terceira, e não há terceira pedida.

---

## 15. Publicação — decidido em 12/09/2026

A seção 11.3 adiava: construir dentro do `omarchy-guest` e decidir depois. Está
decidido e feito — **repo próprio**, `github.com/zednaked/omarchy-ganja`,
submetido ao marketplace oficial em 12/09/2026 (issue #6530). O caminho inteiro,
com o que o validador e a baseline de segurança exigem, está em
`PUBLISHING.md`.

A cópia dentro do `omarchy-guest` saiu no mesmo dia, e isso revisa a decisão da
seção 11.3: ela dizia que adiar não custava nada porque sair dali era uma cópia
de pasta. Era verdade, mas o que custa é **manter** as duas — duas cópias do
mesmo QML divergem, e a que alguém edita nunca é a que está instalada. A
instalação na máquina passou a ser `omarchy plugin add` + `omarchy plugin
update`.

