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
  if count patches with [pcolor = yellow OR pcolor = orange] < (26 * 26) * 0.1 / 3 [setup-cheese]
  
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
      print-nlb ";" print-nlb ";" print-nlb "Exp 1;;" print-nlb "Exp 2;;" print-nlb "Exp 3;;" print-nlb "Exp 4;;" print-nlb "Exp 5;;" print-nlb "Exp 6;;" print-nlb "Exp 7;;" print-nlb "Exp 8;;" print-nlb "Exp 9;;" print-nlb "Exp 10;;"
      print-lb ";"
      print-nlb "Numero de Cats" print-nlb ";" print-nlb "Numero de Mice" print-nlb ";" print-nlb "Ticks; Mice;" print-nlb "Ticks; Mice;" print-nlb "Ticks; Mice;" print-nlb "Ticks; Mice;" print-nlb "Ticks; Mice;" print-nlb "Ticks; Mice;" print-nlb "Ticks; Mice;" print-nlb "Ticks; Mice;" print-nlb "Ticks; Mice;" print-nlb "Ticks; Mice;"
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
      print-nlb ";" print-nlb ";" print-nlb "Exp 1;;" print-nlb "Exp 2;;" print-nlb "Exp 3;;" print-nlb "Exp 4;;" print-nlb "Exp 5;;" print-nlb "Exp 6;;" print-nlb "Exp 7;;" print-nlb "Exp 8;;" print-nlb "Exp 9;;" print-nlb "Exp 10;;"
      print-lb ";"
      print-nlb "Numero de Cats" print-nlb ";" print-nlb "Numero de Mice" print-nlb ";" print-nlb "Ticks; Mice;" print-nlb "Ticks; Mice;" print-nlb "Ticks; Mice;" print-nlb "Ticks; Mice;" print-nlb "Ticks; Mice;" print-nlb "Ticks; Mice;" print-nlb "Ticks; Mice;" print-nlb "Ticks; Mice;" print-nlb "Ticks; Mice;" print-nlb "Ticks; Mice;"
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
      print-nlb ";" print-nlb ";;;;" print-nlb "Exp 1;;" print-nlb "Exp 2;;" print-nlb "Exp 3;;" print-nlb "Exp 4;;" print-nlb "Exp 5;;" print-nlb "Exp 6;;" print-nlb "Exp 7;;" print-nlb "Exp 8;;" print-nlb "Exp 9;;" print-nlb "Exp 10;;"
      print-lb ";"
      print-nlb "Energia Inicial;" print-nlb "Numero de Cats" print-nlb ";" print-nlb "Numero de Mice" print-nlb ";" print-nlb "Cheese;" print-nlb "Traps;" print-nlb "Ticks; Mice;" print-nlb "Ticks; Mice;" print-nlb "Ticks; Mice;" print-nlb "Ticks; Mice;" print-nlb "Ticks; Mice;" print-nlb "Ticks; Mice;" print-nlb "Ticks; Mice;" print-nlb "Ticks; Mice;" print-nlb "Ticks; Mice;" print-nlb "Ticks; Mice;"
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
      print-nlb N-cats print-nlb ";" print-nlb N-mice print-nlb ";" print-nlb ticks print-nlb ";" print-nlb (count mice) print-nlb ";"
    ]
    [;;ELSE
      print-nlb ticks print-nlb ";" print-nlb (count mice) print-nlb ";"
    ]
    if numero-exp = 10 [print-lb ""]
    fclose
  ]
  [;;ELSE
    ifelse numero-exp = 1
    [;;THEN
      print-nlb init-energia print-nlb ";" print-nlb N-cats print-nlb ";" print-nlb N-mice print-nlb ";" print-nlb percent-cheese print-nlb "%;" print-nlb percent-traps print-nlb "%;" print-nlb ticks print-nlb ";" print-nlb (count mice) print-nlb ";"
    ]
    [;;ELSE
      print-nlb ticks print-nlb ";" print-nlb (count mice) print-nlb ";"
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
   if energia > 200 [
    set energia energia / 2
    if random 100 < 15 [
      let x one-of [1 2 3 4]
      hatch x 
      set filhos-mice filhos-mice + x
    ]
   ] 
  ]
  
  ask cats[
    if energia > 250 [
     set energia energia / 2 
     if random 100 < 5[
      let y one-of [1 2]
      hatch y 
      set filhos-cats filhos-cats + y
     ]
    ] 
  ]
end
