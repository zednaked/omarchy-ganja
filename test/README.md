# test/

A arte é o produto. Uma planta "parecida" com a do Ganja-TUI não é o pedido,
então a conferência é caractere a caractere.

```
frames/<seed>-<dia>.txt    8 seeds × 8 dias, 28 linhas de 70 caracteres, frame 0
run.js                     o harness de Node
verify.qml                 o harness do motor de JS do QML
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

## O que ainda não foi feito

**O `diff` contra o Ganja-TUI de verdade.** Nenhuma das três camadas acima
compara com o Rust: elas comparam o plugin com ele mesmo em dois motores. A
referência continua sendo `src/ascii/art.rs`, lido e traduzido à mão.

Numa máquina com `cargo`:

1. Instrumentar o Ganja-TUI para despejar `get_plant_ascii(stage, day, seed, 0)`
   para as 8 seeds de `run.js` e os dias `1, 5, 15, 30, 46, 53, 70, 90`.
   As seeds entram por `plant.id` — `seed = plant.id.as_u128() as u64`, ou seja
   os 16 últimos dígitos hexadecimais do uuid.
2. `diff -u frames/<seed>-<dia>.txt <saída do TUI>`.
3. Divergência de um caractere é falha.

Enquanto isso não acontecer, o README do plugin diz — e tem que continuar
dizendo — que a fidelidade é **declarada e não verificada**.
