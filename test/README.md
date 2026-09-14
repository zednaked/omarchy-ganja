# test/

A arte é o produto. Uma planta "parecida" com a do Ganja-TUI não é o pedido,
então a conferência é caractere a caractere.

```
frames/<seed>-<dia>.txt    8 seeds × 8 dias, 28 linhas de 70 caracteres, frame 0
run.js                     o harness de Node
verify.qml                 o harness do motor de JS do QML
bench.qml                  onde vai o tempo de um quadro (`make bench`)
Art.js                     symlink para ../Art.js
```

O symlink existe porque o Quickshell recusa `import "../Art.js"`: um import que
sai da raiz da configuração vira `qrc:/qs-blackhole` e o shell não carrega.

## As três camadas

```sh
make check              # 1
make diff               # 2
qs -p test/verify.qml   # 3
```

**1. A aritmética de 64 bits contra o `BigInt` do Node.** `SimpleRng` é um LCG
de 64 bits e o motor do QML não tem `BigInt` (nem o literal `1n`, que é erro de
sintaxe, nem a função). Art.js faz a multiplicação à mão em quatro limbs de 16
bits; aqui, onde `BigInt` existe, dá para provar que a conta à mão acerta — 14
seeds, 4000 passos cada, mais as divisões que produzem as variantes de cor.

**2. A saída de hoje contra as fixtures.** Vigia regressão nossa: qualquer
mexida em `Art.js` que mude um caractere aparece aqui.

**3. As fixtures contra o motor do QML.** As fixtures nascem do Node; o plugin
roda no V4. Os dois executam o mesmo arquivo, mas nada obriga o `Math.fround` e
a aritmética de limbs a se comportarem igual nos dois. Esta camada prova que
sim.

Para regravar as fixtures depois de uma mudança intencional:

```sh
make frames
```

## A quarta camada: contra o Rust

**O `diff` contra o Ganja-TUI de verdade** — feito em 14/09/2026. As três camadas
acima comparam o plugin com ele mesmo em dois motores; nenhuma compara com
`src/ascii/art.rs`, que é a referência. Esta compara.

O lado Rust ganhou `examples/dump_frames.rs` (commit `d8e4164` no
[Ganja-TUI](https://github.com/zednaked/Ganja-TUI)), que despeja
`get_plant_ascii(stage, day, seed, 0)` para as mesmas 8 seeds e os mesmos 8 dias,
no formato destas fixtures. O crate não tem `lib.rs`, então o exemplo monta
`domain` e `ascii` com `#[path]` a partir dos arquivos que o jogo usa — é código
de produção compilado ali dentro, não cópia.

```sh
cd ../Ganja-TUI
cargo run --release --example dump_frames -- /tmp/frames-rust
diff -r /tmp/frames-rust ../omarchy-ganja/test/frames
```

Resultado da primeira rodada: **64 de 64 idênticos, caractere a caractere** —
incluindo as quatro transições de estágio (dias 46, 53, 70, 90) e a seed
`ffffffffffffffff`, que é onde o LCG de 64 bits feito à mão em quatro limbs teria
mais chance de divergir.

As seeds e os dias estão escritos nos dois lados, e é assim de propósito: se um
mudar, o `diff` não roda por engano com listas diferentes — ele acusa o arquivo
que falta.


## bench.qml — onde vai o tempo de um quadro

Não é teste: não passa nem reprova, imprime a conta. Existe porque a seção 12 do
`SPEC.md` atribuía os ~30 ms por quadro a "regerar a matriz inteira a cada
quadro", e isso precisava ser medido em vez de suposto.

```sh
make bench
```

Ele desenha a planta num Canvas de verdade, dentro do V4, e cronometra cada parte
separadamente: gerar a matriz, decidir a cor de cada célula, o preâmbulo
(`ctx.reset()` mais os dois `measureText`), pintar um `fillText` por caractere, e
pintar um `fillText` por trecho contíguo de mesma cor.

Medido em 14/09/2026: gerar custa **0,42 ms** e pintar caractere a caractere
custa **4,19 ms** — a geração é 8% do custo do desenho, e a causa que estava
escrita no SPEC estava errada por três ordens de grandeza. O JavaScript inteiro
soma ~4,9 ms dos ~30; o resto está fora dele, na rasterização do Canvas.

O modo por trecho está no bench e **não** está no `Room.qml`: ele derruba o
desenho para 1,78 ms, mas são 2,4 ms de ~30, e não consegui provar que os pixels
saem idênticos — o Canvas mede `M` em 8,0 px e `MMMMMMMMMM` em 84,0, então o
avanço dentro de uma string não é a largura do glifo solto, e uma fonte com
ligaduras funde `//` quando os caracteres chegam juntos. As fixtures não veem
isso: elas são texto. Enquanto não houver essa prova, a arte não muda.
