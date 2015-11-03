breed[cats cat]
breed[mice mouse]
turtles-own [energia poisoned] ;;poisoned -> variável booleana que permite saber se a turtle ingeriu queijo envenenado (ratos) ou um rato que estivesse envenenado (gatos)
mice-own [gato-avistado tipo] ;;gato-avistado -> variável booleana de ajuda na comunicação entre ratos

globals [filhos-cats filhos-mice] ;;por uma questão de ter todos os dados em conta, variáveis que guardam o numero total de mice e cats que já foram criados no decorrer da simulação

to setup
  if numero-exp > 10 [user-message ("Número de experiências (10) atingido") stop]
  ca
  if experiencia = "Original" [set percent-cheese 0 set percent-traps 0 set init-energia 0] ;;VALORES OBRIGATORIOS
  if experiencia = "Caça-Fuga" [set percent-cheese 0 set percent-traps 0 set init-energia 0] ;;VALORES OBRIGATORIOS
  export-init
  setup-patches
  setup-cheese ;;queijo
  setup-traps ;;armadilhas
  setup-agents
  reset-ticks
end

to setup-patches
  ask patches[
    let x 28
    let y 48
    if pycor mod 2 = 0
    [set x 48 set y 28]
    ifelse pxcor mod 2 = 0
    [set pcolor x]
    [set pcolor y]
  ]
end

to setup-agents
  create-mice N-mice
  [
    set shape "mouse side"
    set color 4
    ;setxy random-pxcor random-pycor !!! comentado para poder aplicar um metodo que evita colocar em cima de queijo e/ou armadilhas
    let x one-of patches with [pcolor != yellow AND pcolor != red AND pcolor != orange]
    move-to x
    ;move-to patch-here ;;centrar os ratos na patch em que se encontram
    set gato-avistado false
    ;;escolher um dos dois 'friendly' ou 'loner'
    ;;friendly mice -> ratos que tentam andar em grupos
    ;;loner mice -> ratos que evitam grupos
    set tipo one-of ["friendly" "loner"]
  ]

  create-cats N-cats
  [
    set shape "cat"
    set color black
    let x one-of patches with [not any? mice-here and not any? mice-on neighbors and not any? cats-here AND pcolor != yellow AND pcolor != red AND pcolor != orange]
    setxy [pxcor] of x [pycor] of x
    set heading one-of [0 90 180 270]
  ]
  ask turtles
  [
    set energia init-energia
    set poisoned false ;;colocar booleana de se a turtle está envenenada ou não a FALSE
  ]
end

to setup-cheese
  ask patches with [pcolor != yellow AND pcolor != red AND pcolor != orange AND [pcolor] of neighbors != yellow] ;;tentar que os vizinhos nao sejam queijo também
  [
    if percent-cheese > random 100
    [
      ifelse Poisoned-Cheese = true
      [;; 10% POISONED CHEESE
        ifelse random 100 < 10 [set pcolor orange] [set pcolor yellow]
      ]
      [;;NORMAL CHEESE
        set pcolor yellow
      ]
    ]
  ]
end

to setup-traps
  ask patches with [pcolor != red AND pcolor != yellow  AND pcolor != orange AND [pcolor] of neighbors != red] ;;tentar que os vizinhos nao sejam armadilhas também
  [
    if percent-traps > random 100
    [
      set pcolor red
    ]
  ]
end

to go
  move-mice
  move-cats
  lunch-time
  starvation
  if Breeding-Allowed = true [reproduce]
  if count patches with [pcolor = yellow OR pcolor = orange] < (26 * 26) * (percent-cheese / 100 ) / 3 [setup-cheese] ;;repor queijo assim que este chegue a 1/3 da quantidade original

  tick
  if count mice = 0 OR ticks = it-max [export-final set numero-exp numero-exp + 1 stop] ;;terminar a exportação dos dados
end



to move-mice
  ;;novo comportamento
  ask mice
  [
    ifelse experiencia = "Original"
    [;;ORIGINAL
      let x one-of neighbors
      move-to x
    ]
    [;;ELSE
      ifelse experiencia = "Caça-Fuga"
      [;;CAÇA-FUGA
        ;;se a variavel gato-avistado estiver a 'true'
        ;;tentar mover-se para uma patch diferente de onde possa estar o rato que comunicou
        ;;ou entao, deixar á sorte e mover-se para um dos neighbors
        if gato-avistado = true [move-to one-of neighbors with [not any? mice-here]]
        ;;se o rato estiver perto de um gato, tentar comunicar a qualquer rato proximo (se existente) para se afastar
        if any? cats-on neighbors [if any? mice-on neighbors [ask mice-on neighbors [set gato-avistado true] ask patch-here [set pcolor red]]]
        ;;começar por verificar se há algum gato na vizinhança e fugir para o lado oposto
        ifelse (is-patch? patch-left-and-ahead 45 1 AND any? cats-on patch-left-and-ahead 45 1) OR (is-patch? patch-ahead 1 AND any? cats-on patch-ahead 1) OR (is-patch? patch-right-and-ahead 45 1 AND any? cats-on patch-right-and-ahead 45 1) [ifelse is-patch? patch-ahead (-1) [fd (-1)] [move-to one-of neighbors with [not any? cats-here]]]
        [;;ELSE FRENTE
          ifelse (is-patch? patch-left-and-ahead 135 1 AND any? cats-on patch-left-and-ahead 135 1) OR (is-patch? patch-ahead (-1) AND any? cats-on patch-ahead (-1)) OR (is-patch? patch-right-and-ahead 135 1 AND any? cats-on patch-right-and-ahead 135 1) [ifelse is-patch? patch-ahead 1 [fd 1] [move-to one-of neighbors with [not any? cats-here]]]
          [;;ELSE TRÁS
            ifelse is-patch? patch-left-and-ahead 90 1 AND any? cats-on patch-left-and-ahead 90 1 [ifelse is-patch? patch-right-and-ahead 90 1 [move-to patch-right-and-ahead 90 1] [move-to one-of neighbors with [not any? cats-here]]]
            [;;ELSE ESQUERDA
              ifelse is-patch? patch-right-and-ahead 90 1 AND any? cats-on patch-right-and-ahead 90 1 [ifelse is-patch? patch-left-and-ahead 90 1 [move-to patch-left-and-ahead 90 1] [move-to one-of neighbors with [not any? cats-here]]]
              [;;ELSE DIREITA
                ;;caso nenhum gato tenha sido avistado
                ;;dependendo de 'tipo' do rato, tentar ou enquadrar num grupo, ou afastar-se de outros ratos
                  ifelse any? mice-on neighbors
                  [;;há ratos nos neighbors
                    let vizinhos mice-on neighbors
                    ifelse tipo = "friendly" AND [tipo] of one-of vizinhos = "friendly" AND random 100 < 25 ;;só acontece 25% das vezes, para evitar que os ratos andem eternamente a seguir-se um ao outro
                    [;;se existirem ratos friendly
                      let y one-of vizinhos with [tipo = "friendly"]
                      ;;para nao violar a regra de os ratos nao terem direçao definida, guardar a heading original
                      let x [heading] of self
                      face y ;;virar-se para o friendly
                      fd 1 ;;andar uma casa nessa direção
                      set heading x ;;retornar á direção original
                      move-to one-of neighbors ;;mover-se para um dos neighbors para nao ficarem 2 ratos diretamente sobrepostos
                    ]
                    [;;LONER OU NAO ESTÁ NOS 25% DE PROBABILIDADE DE SEGUIR
                      move-to one-of neighbors with [not any? mice-here]
                    ]
                  ]
                  [;;ELSE -> nao há vizinhos
                    move-to one-of neighbors
                  ]

              ]
            ]
          ]
        ]
      ]
      [;;ELSE
        if experiencia = "Caça-Fuga and Cheese-Traps"
        [;;CAÇA-FUGA AND CHEESE-TRAPS
         ;;se nao fosse a primeira verificação, as turtles nunca cairiam numa armadilha
         if [pcolor] of patch-here = red [reset-color die]
         if [poisoned] of self = true [set color 54]
        ;;prioridade ---> procurar queijo
        ifelse any? neighbors with [pcolor = yellow OR pcolor = orange]
        [
          move-to one-of neighbors with [pcolor = yellow OR pcolor = orange] ;;permite dar o factor aleatório de o rato, entre queijo bom e queijo envenenado, escolher o envenenado por nao conseguir distinguir qual é qual
        ]
        [;;ELSE -> nao há comida
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;;CÓDIGO ABAIXO DESTE PONTO, COPIADO DE "CAÇA-FUGA";;
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;;se a variavel gato-avistado estiver a 'true'
        ;;tentar mover-se para uma patch diferente de onde possa estar o rato que comunicou
        ;;ou entao, deixar á sorte e mover-se para um dos neighbors
        if gato-avistado = true [move-to one-of neighbors with [not any? mice-here] set energia energia - 1] ;;dado que fez um movimento de fuga, descontar-lhe 1 ponto de energia
        ;;se o rato estiver perto de um gato, tentar comunicar a qualquer rato proximo (se existente) para se afastar
        if any? cats-on neighbors [if any? mice-on neighbors [ask mice-on neighbors [set gato-avistado true]]]
        ;;começar por verificar se há algum gato na vizinhança e fugir para o lado oposto
        ifelse (is-patch? patch-left-and-ahead 45 1 AND any? cats-on patch-left-and-ahead 45 1) OR (is-patch? patch-ahead 1 AND any? cats-on patch-ahead 1) OR (is-patch? patch-right-and-ahead 45 1 AND any? cats-on patch-right-and-ahead 45 1) [ifelse is-patch? patch-ahead (-1) [fd (-1)] [move-to one-of neighbors with [not any? cats-here AND pcolor != red AND pcolor != yellow AND pcolor != orange]]]
        [;;ELSE FRENTE
          ifelse (is-patch? patch-left-and-ahead 135 1 AND any? cats-on patch-left-and-ahead 135 1) OR (is-patch? patch-ahead (-1) AND any? cats-on patch-ahead (-1)) OR (is-patch? patch-right-and-ahead 135 1 AND any? cats-on patch-right-and-ahead 135 1) [ifelse is-patch? patch-ahead 1 [fd 1] [move-to one-of neighbors with [not any? cats-here AND pcolor != red AND pcolor != yellow AND pcolor != orange]]]
          [;;ELSE TRÁS
            ifelse is-patch? patch-left-and-ahead 90 1 AND any? cats-on patch-left-and-ahead 90 1 [ifelse is-patch? patch-right-and-ahead 90 1 [move-to patch-right-and-ahead 90 1] [move-to one-of neighbors with [not any? cats-here AND pcolor != red AND pcolor != yellow AND pcolor != orange]]]
            [;;ELSE ESQUERDA
              ifelse is-patch? patch-right-and-ahead 90 1 AND any? cats-on patch-right-and-ahead 90 1 [ifelse is-patch? patch-left-and-ahead 90 1 [move-to patch-left-and-ahead 90 1] [move-to one-of neighbors with [not any? cats-here AND pcolor != red AND pcolor != yellow AND pcolor != orange]]]
              [;;ELSE DIREITA
                ;;caso nenhum gato tenha sido avistado
                ;;dependendo de 'tipo' do rato, tentar ou enquadrar num grupo, ou afastar-se de outros ratos
                  ifelse any? mice-on neighbors
                  [;;há ratos nos neighbors
                    let vizinhos mice-on neighbors
                    ifelse tipo = "friendly" AND [tipo] of one-of vizinhos = "friendly" AND random 100 < 25 ;;só acontece 25% das vezes, para evitar que os ratos andem eternamente a seguir-se um ao outro
                    [;;se existirem ratos friendly
                      let y one-of vizinhos with [tipo = "friendly"]
                      ;;para nao violar a regra de os ratos nao terem direçao definida, guardar a heading original
                      let x [heading] of self
                      face y ;;virar-se para o friendly
                      fd 1 ;;andar uma casa nessa direção
                      set heading x ;;retornar á direção original
                      move-to one-of neighbors with [pcolor != red AND pcolor != yellow AND pcolor != orange] ;;mover-se para um dos neighbors para nao ficarem 2 ratos diretamente sobrepostos
                    ]
                    [;;LONER OU NAO ESTÁ NOS 25% DE PROBABILIDADE DE SEGUIR
                      move-to one-of neighbors with [not any? mice-here AND pcolor != red AND pcolor != yellow AND pcolor != orange]
                    ]
                  ]
                  [;;ELSE -> nao há vizinhos
                    move-to one-of neighbors with [pcolor != red AND pcolor != yellow AND pcolor != orange]
                  ]

              ]
            ]
          ]
        ]
        ]
        ];;FIM CAÇA-FUGA AND CHEESE-TRAPS
      ]
    ]
    move-to patch-here ;;centrar na patch

    ;;verificar cheese
     if [pcolor] of patch-here = yellow
    [
      set energia energia + 50
      ;;retornar á cor original
      reset-color

    ]
    if [pcolor] of patch-here = orange
    [
      set energia energia + 50 ;;alimenta á mesma
      set poisoned true ;;fica envenenado
      ;;retornar á cor original
      reset-color
    ]
    set energia energia - 1 ;;retirar energia após um movimento
    ;;verificar se está envenenado e retirar 10 pontos de energia
    if poisoned = true [set energia energia - 10]
    if gato-avistado = true [set gato-avistado false] ;;caso gato-avistado tenha o valor 'true', colocar a 'false' após um movimento completo
  ]
end

to move-cats
  ask cats[
    ifelse experiencia = "Original"
    [;;ORIGINAL
      let y one-of (patch-set patch-right-and-ahead 90 1
                     patch-right-and-ahead -90 1
                     patch-right-and-ahead 45 1
                     patch-right-and-ahead -45 1
                     patch-ahead 1
                     patch-ahead 2)
      move-to y
      if random 100 < 25
      [set heading one-of [0 90 180 270]]
    ]
    [;;ELSE
      ifelse experiencia = "Caça-Fuga"
      [;;CAÇA-FUGA
        ;;adicionar o extra "em falta" no código original -> se vir um rato em patch-ahead 2, "saltar" para cima deste
        ;;para dar um factor aleatório e nao sempre 100% certo
        ;;dar uma probabilidade de 50% a cada um dos seguintes acontecimentos:
        ;;  -metade das vezes apenas anda 1 casa, ficando assim nos neighbors do rato, fazendo com que este morra
        ;;  -a outra metade simular uma tentativa de captura falhada, e saltar as 2 casa diretamente para cima do rato (o que nao o fará morrer nessa mesma iteração) dando assim, uma minuscula probabilidade de por alguma razao, o rato na iteração seguinte escapar
        ifelse is-patch? patch-ahead 2 AND any? mice-on patch-ahead 2
        [;;existe algum rato na patch-ahead 2
          ifelse random 100 < 50
          [;;acerta o salto
            fd 1
          ]
          [;;falha o salto -> fica em cima do rato
            fd 2  set energia energia - 1 ;;descontar pela casa extra movida
          ]
        ]
        [;;ELSE
         ;;movimento copiado de "Original"
          let y one-of (patch-set patch-right-and-ahead 90 1
                        patch-right-and-ahead -90 1
                        patch-right-and-ahead 45 1
                        patch-right-and-ahead -45 1
                        patch-ahead 1
                        patch-ahead 2)
          move-to y
          if random 100 < 25
          [set heading one-of [0 90 180 270]]
        ]
      ]
      [;;ELSE
        if experiencia = "Caça-Fuga and Cheese-Traps"
        [;;CAÇA-FUGA AND CHEESE-TRAPS
          ;;se nao fosse a primeira verificação, as turtles seriam descontadas por estar numa armadilha
          if [pcolor] of patch-here = red [set energia (energia * 0.8) reset-color] ;;retirar 20% da sua energia
          if [poisoned] of self = true [set color 54]
          ;;;CÓDIGO ABAIXO RETIRADO DE "CAÇA-FUGA"
        ifelse is-patch? patch-ahead 2 AND any? mice-on patch-ahead 2
        [;;existe algum rato na patch-ahead 2
          ifelse random 100 < 50
          [;;acerta o salto
            fd 1
          ]
          [;;falha o salto -> fica em cima do rato
            fd 2  set energia energia - 1 ;;descontar pela casa extra movida
          ]
        ]
        [;;ELSE
         ;;movimento copiado de "Original" (modificado para nao cair em armadilhas)
          let y (patch-set patch-right-and-ahead 90 1
                        patch-right-and-ahead -90 1
                        patch-right-and-ahead 45 1
                        patch-right-and-ahead -45 1
                        patch-ahead 1
                        patch-ahead 2)
          move-to one-of y with [pcolor != red]
          if random 100 < 25
          [set heading one-of [0 90 180 270]]
        ]
        ];;FIM CAÇA-FUGA AND CHEESE-TRAPS
      ]

    ]
    move-to patch-here ;;centrar na patch
    set energia energia - 1
    ;;verificar se está envenenado e retirar 10 pontos de energia
    if poisoned = true [set energia energia - 10]
  ]
end

;;modificado para se ajustar á experiencia com energia
to lunch-time
  ask mice[
    if any? cats-on neighbors
    [
      let gato one-of cats-on neighbors ;;se houver varios gatos nos neighbors, um aleatório será o que vai receber a energia por ter comido o rato e ficar envenenado se o rato estivesse também
      let en_self [energia] of self
      set en_self (en_self / 2) ;;o gato que comeu o rato apenas receberá metade da energia que este tinha
      ifelse [poisoned] of self = true
      [;;ENVENENADO
        ask gato [set energia energia + en_self set poisoned true] ;;atribuir ao gato metade da energia da sua vitima e envenená-lo
      ]
      [;;NAO ENVENENADO
        ask gato [set energia energia + en_self] ;;atribuir ao gato metade da energia da sua vitima
      ]
      die
    ]
  ]
end

;;morrer á fome (energia <= 0)
to starvation
  ask turtles[
    if energia <= 0 AND init-energia != 0 [die]
  ]
end

;;código para verficar as patches em volta e determinar a cor original
;;após uma armadilha ter sido ativada ou queijo ter sido comido
to reset-color
  ask patch-here
  [
    let x 28
    let y 48
    if pycor mod 2 = 0
    [set x 48 set y 28]
    ifelse pxcor mod 2 = 0
    [set pcolor x]
    [set pcolor y]
  ]
end

;;print com line break
to print-lb [#string]
  file-print #string
end

;;print sem line break
to print-nlb [#string]
  file-type #string
end

;;imprimir o cabeçalho
to print-header
  if experiencia = "Original"
  [
    if primeiro-teste = true ;;TESTE INICIAL
    [
      print-lb ";"
      print-nlb "EXPERIENCIA" print-nlb ";" print-nlb experiencia print-nlb ";" print-nlb ";" print-nlb ";" print-nlb "OBJECTIVO" print-nlb ";" print-nlb it-max print-nlb " Iteraçoes" print-lb ";"
      print-lb ";"
      print-nlb ";" print-nlb ";" print-nlb "Exp 1;;;" print-nlb "Exp 2;;;" print-nlb "Exp 3;;;" print-nlb "Exp 4;;;" print-nlb "Exp 5;;;" print-nlb "Exp 6;;;" print-nlb "Exp 7;;;" print-nlb "Exp 8;;;" print-nlb "Exp 9;;;" print-nlb "Exp 10;;;"
      print-lb ";"
      print-nlb "Numero de Cats" print-nlb ";" print-nlb "Numero de Mice" print-nlb ";" print-nlb "Ticks;Mice;Cats;" print-nlb "Ticks;Mice;Cats;" print-nlb "Ticks;Mice;Cats;" print-nlb "Ticks;Mice;Cats;" print-nlb "Ticks;Mice;Cats;" print-nlb "Ticks;Mice;Cats;" print-nlb "Ticks;Mice;Cats;" print-nlb "Ticks;Mice;Cats;" print-nlb "Ticks;Mice;Cats;" print-nlb "Ticks;Mice;Cats;"
      print-lb ""
    ]
  ]
  if experiencia = "Caça-Fuga"
  [
    if primeiro-teste = true ;;TESTE INICIAL
    [
      print-lb ";" print-lb ";" print-lb ";"
      print-nlb "EXPERIENCIA" print-nlb ";" print-nlb experiencia print-nlb ";" print-nlb ";" print-nlb ";" print-nlb "OBJECTIVO" print-nlb ";" print-nlb it-max print-nlb " Iteraçoes" print-lb ";"
      print-lb ";"
      print-nlb ";" print-nlb ";" print-nlb "Exp 1;;;" print-nlb "Exp 2;;;" print-nlb "Exp 3;;;" print-nlb "Exp 4;;;" print-nlb "Exp 5;;;" print-nlb "Exp 6;;;" print-nlb "Exp 7;;;" print-nlb "Exp 8;;;" print-nlb "Exp 9;;;" print-nlb "Exp 10;;;"
      print-lb ";"
      print-nlb "Numero de Cats" print-nlb ";" print-nlb "Numero de Mice" print-nlb ";" print-nlb "Ticks;Mice;Cats;" print-nlb "Ticks;Mice;Cats;" print-nlb "Ticks;Mice;Cats;" print-nlb "Ticks;Mice;Cats;" print-nlb "Ticks;Mice;Cats;" print-nlb "Ticks;Mice;Cats;" print-nlb "Ticks;Mice;Cats;" print-nlb "Ticks;Mice;Cats;" print-nlb "Ticks;Mice;Cats;" print-nlb "Ticks;Mice;Cats;"
      print-lb ""
    ]
  ]
  if experiencia = "Caça-Fuga and Cheese-Traps"
  [
    if primeiro-teste = true ;;TESTE INICIAL
    [
      print-lb ";" print-lb ";" print-lb ";"
      print-nlb "EXPERIENCIA" print-nlb ";" print-nlb experiencia print-nlb ";" print-nlb ";" print-nlb ";" print-nlb "OBJECTIVO" print-nlb ";" print-nlb it-max print-nlb " Iteraçoes" print-lb ";"
      ifelse Poisoned-Cheese = true [print-nlb ";" print-lb "Poisoned Cheese (10%);"] [print-lb ";"]
      print-nlb ";" print-nlb ";;;;" print-nlb "Exp 1;;;" print-nlb "Exp 2;;;" print-nlb "Exp 3;;;" print-nlb "Exp 4;;;" print-nlb "Exp 5;;;" print-nlb "Exp 6;;;" print-nlb "Exp 7;;;" print-nlb "Exp 8;;;" print-nlb "Exp 9;;;" print-nlb "Exp 10;;;"
      print-lb ";"
      print-nlb "Energia Inicial;" print-nlb "Numero de Cats" print-nlb ";" print-nlb "Numero de Mice" print-nlb ";" print-nlb "Cheese;" print-nlb "Traps;" print-nlb "Ticks;Mice;Cats;" print-nlb "Ticks;Mice;Cats;" print-nlb "Ticks;Mice;Cats;" print-nlb "Ticks;Mice;Cats;" print-nlb "Ticks;Mice;Cats;" print-nlb "Ticks;Mice;Cats;" print-nlb "Ticks;Mice;Cats;" print-nlb "Ticks;Mice;Cats;" print-nlb "Ticks;Mice;Cats;" print-nlb "Ticks;Mice;Cats;"
      print-lb ""
    ]
  ]
end

to export-init
    let fname ""
    ifelse numero-exp = 1 [set fname user-new-file file-open fname print-header] [set fname user-file file-open fname]
end

to export-final
  ifelse experiencia = "Original" OR experiencia = "Caça-Fuga"
  [
    ifelse numero-exp = 1
    [;;THEN
      print-nlb N-cats print-nlb ";" print-nlb N-mice print-nlb ";" print-nlb ticks print-nlb ";" print-nlb (count mice) print-nlb ";" print-nlb (count cats) print-nlb ";"
    ]
    [;;ELSE
      print-nlb ticks print-nlb ";" print-nlb (count mice) print-nlb ";" print-nlb (count cats) print-nlb ";"
    ]
    if numero-exp = 10 [print-lb ""]
    fclose
  ]
  [;;ELSE
    ifelse numero-exp = 1
    [;;THEN
      print-nlb init-energia print-nlb ";" print-nlb N-cats print-nlb ";" print-nlb N-mice print-nlb ";" print-nlb percent-cheese print-nlb "%;" print-nlb percent-traps print-nlb "%;" print-nlb ticks print-nlb ";" print-nlb (count mice) print-nlb ";" print-nlb (count cats) print-nlb ";"
    ]
    [;;ELSE
      print-nlb ticks print-nlb ";" print-nlb (count mice) print-nlb ";" print-nlb (count cats) print-nlb ";"
    ]
    if numero-exp = 10 [print-lb ""]
    fclose
  ]
end

;;fechar o ultimo ficheiro aberto, quando desejado
to fclose
  file-close
end

to reproduce
  ask mice[
    let x one-of [1 2 3 4]
   if energia > 200 [
    set energia energia / (x + 1) ;;divide pela quantidade de ratos que nasceram com a adição do pai
    if random 100 < 15 [
      hatch x
      set filhos-mice filhos-mice + x
    ]
   ]
  ]

  ask cats[
    let y one-of [1 2]
    if energia > 250 [
     set energia energia / (y + 1) ;;divide pela quantidade de ratos que nasceram com a adição do pai
     if random 100 < 5[
      hatch y
      set filhos-cats filhos-cats + y
     ]
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
603
22
1153
593
13
13
20.0
1
10
1
1
1
0
0
0
1
-13
13
-13
13
0
0
1
ticks
30.0

BUTTON
40
22
161
55
NIL
setup\n\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
400
59
572
92
N-mice
N-mice
0
10
10
1
1
NIL
HORIZONTAL

SLIDER
399
103
571
136
N-cats
N-cats
0
5
5
1
1
NIL
HORIZONTAL

BUTTON
228
23
291
56
NIL
Go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
453
327
510
372
NIL
ticks
17
1
11

MONITOR
406
418
477
471
Cats Left
count cats
17
1
13

MONITOR
482
418
554
471
Mice Left
count mice
17
1
13

PLOT
1167
24
1829
591
Tempo de vida - Mice
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -955883 true "" "plot count mice"
"pen-1" 1.0 0 -7500403 true "" "plot count cats"

SLIDER
18
238
190
271
percent-cheese
percent-cheese
0
10
5
1
1
NIL
HORIZONTAL

MONITOR
195
230
282
283
Cheese left
count patches with [pcolor = yellow]
17
1
13

SLIDER
19
330
191
363
percent-traps
percent-traps
0
10
5
1
1
NIL
HORIZONTAL

MONITOR
196
322
264
375
Traps left
count patches with [pcolor = red]
17
1
13

SLIDER
403
267
575
300
init-energia
init-energia
0
150
100
1
1
NIL
HORIZONTAL

CHOOSER
37
638
281
683
experiencia
experiencia
"Original" "Caça-Fuga" "Caça-Fuga and Cheese-Traps"
2

SLIDER
38
686
210
719
numero-exp
numero-exp
1
10
1
1
1
NIL
HORIZONTAL

TEXTBOX
40
609
190
643
Output das Experiências
14
0.0
1

SWITCH
217
686
367
719
primeiro-teste
primeiro-teste
1
1
-1000

SLIDER
18
62
190
95
it-max
it-max
100
1000
500
1
1
NIL
HORIZONTAL

SWITCH
20
406
190
439
Poisoned-Cheese
Poisoned-Cheese
0
1
-1000

MONITOR
195
398
276
451
Poison left
count patches with [pcolor = orange]
17
1
13

SWITCH
13
519
190
552
Breeding-Allowed
Breeding-Allowed
0
1
-1000

MONITOR
196
480
296
533
Cats hatched
filhos-cats
17
1
13

MONITOR
196
536
296
589
Mice hatched
filhos-mice
17
1
13

MONITOR
397
483
469
528
Loner Mice
count mice with [tipo = \"loner\"]
17
1
11

MONITOR
477
483
562
528
Friendly Mice
count mice with [tipo = \"friendly\"]
17
1
11

TEXTBOX
217
190
367
208
Opções das Experiências
13
0.0
1

TEXTBOX
347
24
497
42
Variáveis Básicas
13
0.0
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

cat
false
0
Line -7500403 true 285 240 210 240
Line -7500403 true 195 300 165 255
Line -7500403 true 15 240 90 240
Line -7500403 true 285 285 195 240
Line -7500403 true 105 300 135 255
Line -16777216 false 150 270 150 285
Line -16777216 false 15 75 15 120
Polygon -7500403 true true 300 15 285 30 255 30 225 75 195 60 255 15
Polygon -7500403 true true 285 135 210 135 180 150 180 45 285 90
Polygon -7500403 true true 120 45 120 210 180 210 180 45
Polygon -7500403 true true 180 195 165 300 240 285 255 225 285 195
Polygon -7500403 true true 180 225 195 285 165 300 150 300 150 255 165 225
Polygon -7500403 true true 195 195 195 165 225 150 255 135 285 135 285 195
Polygon -7500403 true true 15 135 90 135 120 150 120 45 15 90
Polygon -7500403 true true 120 195 135 300 60 285 45 225 15 195
Polygon -7500403 true true 120 225 105 285 135 300 150 300 150 255 135 225
Polygon -7500403 true true 105 195 105 165 75 150 45 135 15 135 15 195
Polygon -7500403 true true 285 120 270 90 285 15 300 15
Line -7500403 true 15 285 105 240
Polygon -7500403 true true 15 120 30 90 15 15 0 15
Polygon -7500403 true true 0 15 15 30 45 30 75 75 105 60 45 15
Line -16777216 false 164 262 209 262
Line -16777216 false 223 231 208 261
Line -16777216 false 136 262 91 262
Line -16777216 false 77 231 92 261

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

mouse side
false
0
Polygon -7500403 true true 38 162 24 165 19 174 22 192 47 213 90 225 135 230 161 240 178 262 150 246 117 238 73 232 36 220 11 196 7 171 15 153 37 146 46 145
Polygon -7500403 true true 289 142 271 165 237 164 217 185 235 192 254 192 259 199 245 200 248 203 226 199 200 194 155 195 122 185 84 187 91 195 82 192 83 201 72 190 67 199 62 185 46 183 36 165 40 134 57 115 74 106 60 109 90 97 112 94 92 93 130 86 154 88 134 81 183 90 197 94 183 86 212 95 211 88 224 83 235 88 248 97 246 90 257 107 255 97 270 120
Polygon -16777216 true false 234 100 220 96 210 100 214 111 228 116 239 115
Circle -16777216 true false 246 117 20
Line -7500403 true 270 153 282 174
Line -7500403 true 272 153 255 173
Line -7500403 true 269 156 268 177

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
