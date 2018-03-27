
PORTO_ESCRITA   EQU FFFEh
PORTO_CONTROLO  EQU FFFCh
LCD_CONTROLO    EQU FFF4h
LCD_ASCII       EQU FFF5h
IO	            EQU FFFEh
NL	            EQU	000Ah
SP_INICIAL      EQU FDFFh
MASCARA	        EQU 8016h				; 1000 0000 0001 0110b
INT_MASK_ADDR   EQU FFFAh
INT_MASK        EQU 1000010001111110b
UN_CONTAGEM     EQU FFF6h
CON_CONTAGEM    EQU FFF7h               ; porto controlo contagem
IO_LEDS         EQU FFF8h
SETE_SEG0       EQU FFF0h
SETE_SEG1       EQU FFF1h


; Tabela de interrupcoes

ORIG FE0Fh
INT_T WORD INT_TEMPORIZADOR             ; rotina de instrucao executada apos 500ms

ORIG FE01h
INT_1 WORD INT_L1
INT_2 WORD INT_L2
INT_3 WORD INT_L3
INT_4 WORD INT_L4
INT_5 WORD INT_L5
INT_6 WORD INT_L6

ORIG FE0Ah
INT_A WORD INT_LA

ORIG 8000h 

random_seed	  WORD 0				    ; chave para gerar o numero aleatorio
ganhou_str	  STR  '                GANHOU&'
fim_str	  	  STR  '                Fim do Jogo&'
resultado_str STR  'Resultado&'
jogada_str    STR  'Jogada&'
cardinal_str  STR  ' ## &'
num2		  STR  '1', '2', '3', '4', '5', '6', '7', '8', '9'
tracos_str	  STR  '---------------------------------------&'
iniciar_IA    STR  '                Carregue no botao IA para iniciar&'
recomecar_IA  STR  '                Carregue em IA para recomecar&'
var_resultado WORD 0					       ; resultado ou seja os x,o,-
submetido	  WORD 0					       ; jogada submetida pelo jogador
codigo_secret WORD 0					       ; codigo random 
jog_actual	  WORD Ch					       ; jogada actual
highscore_str STR  'High Score: &'
var_highscore WORD 13
cursor_texto  TAB  1
jogo_em_curso TAB  1                            ; 0 se jogo acabou ou 1 se jogo esta a decorrer

ORIG 0000h

MOV R7, FFFFh
MOV M[PORTO_CONTROLO], R7
MOV R7, SP_INICIAL
MOV SP, R7
MOV R7, INT_MASK
MOV M[INT_MASK_ADDR], R7
PUSH R6									        ; serve so para a pilha ficar bem 
MOV R6, iniciar_IA					            ; e para reutilizar a funcao escreve_IA
CALL string
POP R6
JMP fim


;####################################################################################################
; 			Esta parte do codigo e' a funcao principal que chama as outras funcoes                  ;
;####################################################################################################

Inicio: 			MOV R7, 1                    
                    MOV M[jogo_em_curso], R7    ; variavel que indica se o jogo esta a decorrer ou nao
                    CALL randomgen
                    CALL tabela
volta:              CALL submete_jogada	
                    CALL salto
                    CALL organiza_res
                    CALL output
					MOV R3, M[var_resultado]
                    CMP R3, 0492h
                    MOV R3, R0
                    JMP.Z ganhou	            ; se R3 for 0492h entao acertou pois esse e o codigo para 4 'x'
					MOV R4, M[jog_actual]
                    CMP R4, Ch		            ; 12 jogadas
                    MOV R4, R0
                    JMP.NZ volta	            ; se ainda nao jogou 12 vezes e tambem nao ganhou volta a jogar
                    JMP.Z fim_do_jogo           ; se jogou 12 vezes e nao acertou perdeu
                    

;####################################################################################################
; 			Esta parte do codigo serve para fabricar um numero aleatorio. 							;
; 			Esse numero aleatorio vai ser o que o jogador esta a tentar adivinhar					;
;####################################################################################################
		
randomgen:      	PUSH R1
                    PUSH R3
                    PUSH R4
                    PUSH R5
					PUSH R6
					MOV R1, M[random_seed]
                    TEST R1,0001h		; gerador de numero aletorio       AND R2,0001h		 se number for par faz-se rotate right
                    BR.Z zero			; se for impar faz-se xor com mascara e depois rotate right
                    XOR R1, MASCARA		
zero:        		ROR R1, 1h
dividir:        	ROL R5, 3h
                    MOV R6, R1          ; os digitos hexa so podem estar entre 1,6
                    AND R6, Fh				
                    ROR R1, 4h
                    MOV R4, 6h
                    DIV R6, R4
                    INC R4  			; pois o resto vai de 0 a 5 e nos queremos de 1 a 6
                    ADD R5, R4
                    INC R3
                    CMP R3, 4h
                    BR.NZ dividir
                    MOV M[codigo_secret], R5
                    POP R6
                    POP R5
                    POP R4
					POP R3
					POP R1
                    RET
                    
;####################################################################################################
;       Esta parte do codigo e' a funcao principal de tabela, que escreve a tabela inicial          ;                 
;####################################################################################################

tabela:				CALL espaco
                    CALL espaco
                    CALL espaco
                    CALL espaco
                    CALL tracos			
                    CALL mudar_de_linha
                    CALL espaco
                    CALL espaco
                    CALL espaco
                    CALL espaco
                    CALL traco_vertical
                    CALL Cardinal
                    CALL traco_vertical
                    CALL espaco
                    CALL escreve_jogada				
                    CALL espaco
                    CALL traco_vertical
                    CALL espaco
                    CALL escreve_resultado			
                    CALL espaco
                    CALL traco_vertical
                    CALL mudar_de_linha
                    CALL espaco
                    CALL espaco
                    CALL espaco
                    CALL espaco
                    CALL tracos
                    RET
                    
espaco:	            PUSH R6
                    PUSH R7
esp_loop:           CALL inc_cursor             ; funcao para escrever espacos mudando o valor de R6
                    INC R6                      ; para mais ou menos espacos
                    CMP R6, 4
                    BR.NZ esp_loop
                    POP R7
                    POP R6
                    RET
                    
tracos:	            PUSH R6
                    MOV R6, tracos_str
                    CALL string
                    POP R6		
                    RET
                    
mudar_de_linha:     PUSH R7
                    MOV R7, M[cursor_texto]
                    AND R7, FF00h
                    ADD R7, 0100h
                    MOV M[cursor_texto], R7
                    MOV M[PORTO_CONTROLO], R7
                    POP R7
                    RET
                    
traco_vertical:     PUSH R7
                    MOV R7,'|'			; funcao para escrever '|'
                    MOV M[PORTO_ESCRITA],R7
                    CALL inc_cursor
                    POP R7
                    RET
                
Cardinal:	        PUSH R6
                    MOV R6, cardinal_str
                    CALL string
                    POP R6
                    RET		
		
escreve_jogada:	    PUSH R6                     ; escreve a palavra jogada na janela de texto
                    MOV R6, jogada_str		
                    CALL string
                    POP R6
                    RET
		
escreve_resultado:	PUSH R6
                    MOV R6, resultado_str		; escreve o a palavra resultado na janela de texto
                    CALL string					
                    POP R6
                    RET
                    
;####################################################################################################
; 	             Esta parte do codigo escreve as strings que estao em memoria                       ;                 
;####################################################################################################

string:		        PUSH R7                 ; recebe no R6 o endereco de uma string e escreve-a ate
                    PUSH R6                 ; encontrar o carater &
str_loop:	        MOV R7, M[R6]
                    CMP R7, '&'
                    BR.NZ cont
                    POP R6
                    POP R7
                    RET
cont:		        MOV M[PORTO_ESCRITA], R7
                    INC R6
                    CALL inc_cursor
                    BR str_loop
                
;####################################################################################################
; 	       Esta parte do codigo serve para incrementar o a posicao do cursor da janela de texto     ;                 
;####################################################################################################

inc_cursor:         PUSH R7
                    MOV R7, M[cursor_texto]
                    INC R7
                    MOV M[cursor_texto], R7
                    MOV M[PORTO_CONTROLO], R7
                    POP R7
                    RET

;####################################################################################################
; 			Esta parte do codigo serve para esperar pela jogada do utilizador.       				;
; 			ou seja esperar no maximo 8 segundos pela jogada do utilizador, desligando				;
; 			um LED a cada 500ms e se o jogador nao jogar nesse tempo perde o jogo.   				;
;####################################################################################################

INT_TEMPORIZADOR:   SHR R7, 1
                    BR.Z acabou_tempo
                    MOV M[UN_CONTAGEM], R3
                    MOV M[CON_CONTAGEM], R5
acabou_tempo:       RTI

INT_L1:             ROL R2, 3
                    ADD R2, 1
                    INC R6
                    RTI
                
INT_L2:             ROL R2, 3
                    ADD R2, 2
                    INC R6
                    RTI
                    
INT_L3:             ROL R2, 3
                    ADD R2, 3
                    INC R6
                    RTI
                    
INT_L4:             ROL R2, 3
                    ADD R2, 4
                    INC R6
                    RTI
                    
INT_L5:             ROL R2, 3
                    ADD R2, 5
                    INC R6
                    RTI
                    
INT_L6:             ROL R2, 3
                    ADD R2, 6
                    INC R6
                    RTI
                    
submete_jogada:     PUSH R1
					PUSH R2
					PUSH R3
					PUSH R5
					PUSH R6
					PUSH R7
                    MOV R5, 1
                    MOV R3, 5
                    MOV R7, FFFFh
                    MOV M[UN_CONTAGEM], R3
                    MOV M[CON_CONTAGEM], R5
                    ENI

Ciclo_LEDS:         MOV M[IO_LEDS], R7
					CMP R7, R0
					JMP.Z zero_tempo
                    CMP R6, 4
                    BR.Z retorno_el
                    BR Ciclo_LEDS
    
retorno_el:			MOV M[submetido], R2
					POP R7
					POP R6
					POP R5
					POP R3
					POP R2
					POP R1
					RET
	
zero_tempo:			POP R7
					POP R6
					POP R5
					POP R3
					POP R2
					POP R1
					JMP fim_do_jogo
					
;####################################################################################################
; 			Esta parte do codigo serve para comparar o codigo que o jogador inseriu					;
; 			         e o codigo que foi fabricado no random generator.								;
; 			Pega nos 2 codigos que estao nas variaveis codigo_secret e submetido e 					;
; 			   devolve o resultado e aumenta em um a jogada em que estamos.							;
;####################################################################################################
    
salto:      		DSI
                    PUSH R1             
                    PUSH R2
					PUSH R3
                    PUSH R4				
                    PUSH R5				
                    PUSH R6				
                    PUSH R7				
					MOV R1, M[codigo_secret]
					MOV R2, M[submetido]
                    MOV	R4, 5           ; contador para fazer 4 vezes loop
                    
testarX:        	DEC R4         		
                    CMP R4,R0
                    JMP.Z arranjar_R1	; se R4 chegar a zero entao passar para a fase seguinte, testarO
                    MOV R7, R1
                    MOV R6, R2
                    AND R7, 0007h    
                    AND R6, 0007h	    ; ficar com o digito menos significativo para os comparar     
                    ROR R1, 3	
                    ROR R2, 3			; fazer rotate do digito hexa para no loop asseguir se comparar o proximo digito
                    CMP R6,R7
                    BR.NZ testarX		; se nao forem iguais fazer loop novamente
                    AND R1, 1FFFh		
                    AND R2, 1FFFh  		; se forem iguais por ambos = 0 para na proxima etapa nao os comparar outra vez e dar 'o'
                    ADD R3, 2			; adicionar R3 2, pois escolhemos 2 para representar um 'x' 'x' -> 2
                    ROR R3, 3     		; colocar 2 na casa mais significativa
                    JMP testarX			; fazer loop novamente
                    
arranjar_R1:		ROR R1, 4			; como tem 16 bits e nos so rodamos 12 
testarO:            ROR R2, 4
e_zero:				INC R4
                    CMP R4, 5
                    BR.Z jogada         ; fazer o loop 4 vezes
                    MOV R7, R1			; este loop vai percorrendo R1
                    AND R7, 0007h		; se os 3 bits forem iguais a zero quer dizer que ja foi
                    ROR R1, 3			; igual a um digito de R2 e deve-se saltar
                    CMP R7, R0
                    BR.Z e_zero
                    MOV R5, 5h
nextR2:		        DEC R5              ; esta funcao vai percorrer R2 e comparar 
                    CMP R5, R0          ; com o R1, se R2 = R1 entao R3 + 0001 que e' 
                    BR.Z testarO	    ; codigo para 'o'
                    MOV R6, R2			; testarO e' como se fosse um for de R1
                    AND R6, 7h			; e dentro desse for esta' o nextR2 que e' o for do R2
                    CMP R6, R0          ; se digito de R2 = 0 entao fazemos skip pois ja teve 'x' ou 'o'
                    BR.Z nao_bola
                    CMP R6, R7
                    BR.Z e_bola			; se for bola entao poe os dois a zero e codigo bola no R3
					JMP nao_bola	    ; se nao rodar 3 bits
e_bola:             AND R1, 1FFFh		
                    AND R2, FFF8h
                    ADD R3, 0001h		; codigo para a bola -> 0001 = 'o'
                    ROR R3, 3
					MOV R7, R0 			; para nao dar mais uma bola
nao_bola:			ROR R2, 3
                    JMP nextR2
jogada:     		MOV M[var_resultado], R3  ; incrementar a jogada e escreve-la nos 7 segmentos
					MOV R4, M[jog_actual]
					INC R4
					MOV M[jog_actual], R4
					CALL sete_segmentos
					POP R7
                    POP R6
                    POP R5
                    POP R4
					POP R3
                    POP R2
                    POP R1
                    RET
    
;####################################################################################################
; 			Esta parte do codigo serve para imprimir para os displays de sete segmentos             ;
;                                           em decimal                                              ;
;####################################################################################################

sete_segmentos:     PUSH R4
                    PUSH R5
                    CMP R4, 10
                    BR.NN jog_maior_que_9    
                    MOV M[SETE_SEG0], R4    ; se nao for maior que dez submeter a jogada na 1 casa
                    BR ret_sete_seg         ; do 7 segmentos
jog_maior_que_9:    MOV R5, 1               ; Se for maior que dez obrigatoriamente escrever na 2 
                    MOV M[SETE_SEG1], R5    ; casa 1 e comparamos com 11 e escrevemos o resto consoante a comparacao
                    CMP R4, 11
                    BR.Z jog_onze
                    BR.P jog_doze
                    MOV R5, R0
                    MOV M[SETE_SEG0], R5
                    BR ret_sete_seg
jog_onze:           MOV R5, 1
                    MOV M[SETE_SEG0], R5
                    BR ret_sete_seg
jog_doze:           MOV R5, 2
                    MOV M[SETE_SEG0], R5
ret_sete_seg:       POP R5
                    POP R4
                    RET
                    
;####################################################################################################
; 			Esta parte do codigo organiza o resultado para imprimir para a janela de texto          ;
;                          primeiro os x depois as o's e em ultimo os x.                            ;
;####################################################################################################

rodar:	         	ROR R3, 3              ; roda o resultado ate' este ficar organizado nos 12 bits inferiores
                    INC R6
                    CMP R6, 4			    
                    BR.NZ foi_zero	   
                    BR rodou_tudo_ou_zero
                    

organiza_res:       PUSH R6
                    PUSH R7
					PUSH R3
					MOV R3, M[var_resultado]
					CMP R3, R0
					BR.Z rodou_tudo_ou_zero ; se nao acertou nada entao acabar retornar
                    ROR R3, 4               ; os primeiros quatro bits sao 0000 logo fazemos rotate
foi_zero:	        MOV R7, R3
                    AND R7, 7h
                    CMP R7, R0
                    BR.Z rodar  		
					MOV M[var_resultado], R3
rodou_tudo_ou_zero: POP R3
                    POP	R7
                    POP R6
                    RET
                    
;####################################################################################################
; 	                 Esta parte do codigo e' a funcao principal de output                           ;
;                Escreve todo o output menos a janela inicial e as mensagens finais                 ;
;####################################################################################################

output:         	PUSH R7 
                    PUSH R6
                    PUSH R3
                    CALL mudar_de_linha	; Escreve R2, a jogada em que estamos e o numero da jogada
                    CALL espaco
                    CALL espaco
                    CALL espaco
                    CALL espaco
                    CALL traco_vertical
                    CALL inc_cursor
                    CALL nr_jogada
                    CALL inc_cursor
                    CALL traco_vertical
                    PUSH R6
                    MOV R6, -1
                    CALL espaco
                    POP R6
                    CALL print_jogada
                    PUSH R6		
                    MOV R6, -1
                    CALL espaco
                    POP R6
                    CALL traco_vertical
                    PUSH R6
                    MOV R6, -3			; os MOV R6 sao so para fazer mais espacos para a tabela ficar direita
                    CALL espaco
                    POP R6
                
                
;####################################################################################################
; 	     Esta parte do codigo escreve o resultado da jogada e e' uma continuacao do output          ;                 
;####################################################################################################
                    
					MOV R3, M[var_resultado]
print_res:      	MOV R7, R3			; funcao ao todo escreve os 'x' 'o'	ou '-'
                    AND R7, 7h			; compara o primeiro digito de R3 com F ou 1
                    ROR R3, 3			; se for 2 escreve 'x' se for 1 escreve 'o'
                    INC R6				; se nao for ambos escreve '-'
                    CMP R6, 5			; faz o loop 4 vezes
                    JMP.Z acabar
                    CMP R7, 2h
                    BR.NZ bola
                    CALL sitio_certo
                    JMP print_res
bola:       		CMP R7, 1
                    BR.NZ errado
                    CALL sitio_errado
                    JMP print_res
errado:          	CALL nada_certo
                    JMP print_res
acabar:     		MOV R6, -2			; funcao que acaba de escrever a tabela
                    CALL espaco			; e retorna a funcao volta para a instrucao CALL output
                    CALL traco_vertical
                    MOV R6, R0
                    MOV R7, R0
                    POP R3
                    POP R6
                    POP R7
                    RET
                    
sitio_certo:	    PUSH R7
                    MOV R7, 'x'
                    MOV M[PORTO_ESCRITA],R7
                    CALL inc_cursor
                    POP R7
                    RET
                    
sitio_errado:	    PUSH R7
                    MOV R7, 'o'
                    MOV M[PORTO_ESCRITA],R7
                    CALL inc_cursor
                    POP R7
                    RET
                    
nada_certo:		    PUSH R7
                    MOV R7, '-'
                    MOV M[PORTO_ESCRITA], R7
                    CALL inc_cursor
                    POP R7
                    RET
                    
;####################################################################################################
; 	                 Esta parte do codigo escreve a jogada em que estamos                           ;                 
;####################################################################################################

nr_jogada:      	PUSH R7
					PUSH R4
					PUSH R3
					MOV R4, M[jog_actual]
					MOV R3, 10
					DIV R4,R3
					ADD R4, 30h
					ADD R3, 30h
					MOV M[PORTO_ESCRITA], R4
					CALL inc_cursor
					MOV M[PORTO_ESCRITA], R3
					CALL inc_cursor
                    POP R3
                    POP R4
                    POP R7
                    RET

;####################################################################################################
; 	               Esta parte do codigo escreve a jogada submetida pelo jogador                     ;                 
;####################################################################################################
				
                    

print_jogada:	    PUSH R2
                    PUSH R6
                    PUSH R7
                    MOV R2, M[submetido]
					ROL R2, 4			; os 4 maiores bits sao 0, para tira-los
print_loop: 		ROL R2, 3			; poe o digito mais significativo no menos 
                    MOV R7, R2			; pois queremos escrever o numero na ordem correta
                    AND R7, 0007h	
                    ADD R7, 30h			; adicionar 30 porque e' o ASCII de 0
                    MOV M[PORTO_ESCRITA], R7
                    CALL inc_cursor
                    INC R6			
                    CMP R6, 4			; fazer 4 vezes
                    BR.NZ print_loop			
                    POP R7
                    POP R6
                    POP R2
                    RET
        
;####################################################################################################
; 	Esta parte do codigo sao apena funcoes de output, que escrevem algo ou chama a funcao string    ;                 
;####################################################################################################
		
ganhou:             DSI
					PUSH R6
                    CALL mudar_de_linha
                    MOV R6, R0
                    CALL espaco
                    CALL espaco
                    CALL espaco
                    CALL espaco
                    CALL tracos
                    CALL mudar_de_linha
                    MOV R6, ganhou_str
                    CALL string
                    CALL High_Score
                    POP R6
                    PUSH R6                     ; pois a salta_ganhou faz POP de R6
                    JMP salta_ganhou    
    
;####################################################################################################
; 	   Esta parte do codigo serve para escrever o highscore no LCD quando ganha, em decimal         ;                 
;####################################################################################################
                    
High_Score:         PUSH R5
                    PUSH R6
                    PUSH R7
                    MOV R7, M[jog_actual]       
                    CMP R7, M[var_highscore]
                    JMP.P    Fim_Highscore      ; se nao foi highscore entao nao imprimimos por cima
                    MOV R6, 8020h
					MOV M[LCD_CONTROLO], R6
                    MOV R6, 8000h
                    MOV M[LCD_CONTROLO], R6
                    MOV R7, highscore_str
Ciclo_LCD:          MOV R5, M[R7]               ; Escreve a string highscore
                    CMP R5, 26h
                    BR.Z escreve_highscore
                    MOV M[LCD_ASCII], R5
                    INC R6
                    MOV M[LCD_CONTROLO], R6
                    INC R7
                    BR Ciclo_LCD
                    
escreve_highscore:  MOV R7, M[jog_actual]       ; Escreve o numero do highscore
                    MOV M[var_highscore], R7
                    MOV R5, 10
                    DIV R7, R5
                    ADD R7, 30h
                    ADD R5, 30h
                    MOV M[LCD_ASCII], R7
                    INC R6
                    MOV M[LCD_CONTROLO], R6
                    MOV M[LCD_ASCII], R5
Fim_Highscore:      POP R7
                    POP R6
                    POP R5
                    RET
                    
;####################################################################################################
; 	             Esta parte do codigo escreve a string fim de jogo e carregue IA                    ;                 
;####################################################################################################

fim_do_jogo:		DSI
					PUSH R6
                    CALL mudar_de_linha
                    MOV R6, R0
                    CALL espaco
                    CALL espaco
                    CALL espaco
                    CALL espaco
                    CALL tracos
salta_ganhou:       CALL mudar_de_linha         ; salta ganho e' para nao estragar a tabela em caso de vitoria
                    MOV R6, fim_str
                    CALL string
					CALL mudar_de_linha
escreve_IA:			MOV R6, recomecar_IA
					CALL string
					MOV M[jogo_em_curso], R0
                    POP R6
                    JMP fim

;####################################################################################################
; 			Esta parte do codigo serve para a interrupcao no botao IA.                              ;
;             Este botao faz reset as variaveis, registos e ao ecran                                ;
;####################################################################################################	

INT_LA:				MOV R1, M[jogo_em_curso]
                    CMP R1, R0
                    BR.NZ faz_nada                  ; se o jogo estiver a decorrer a interrupcao nao faz nada
					BR interrupcao_IA
faz_nada:			RTI
    
interrupcao_IA:     DSI
                    MOV M[jog_actual], R0
					MOV M[SETE_SEG0], R0
					MOV M[SETE_SEG1], R0
					CALL limpar_ecran
					MOV R7, FFFFh
                    MOV M[PORTO_CONTROLO], R7
                    MOV M[cursor_texto], R0
                    MOV R7, SP_INICIAL
                    MOV SP, R7
					MOV R1, R0
					MOV R2, R0
					MOV R5, R0
					MOV R6, R0
					JMP Inicio
    
limpar_ecran:       PUSH R5
                    PUSH R6
                    PUSH R7
                    MOV R5, 20h                      ; codigo ascii do espaco
                    MOV R6, -1                       ; linhas
ciclo_linhas:       MOV R7, -1                       ; colunas
                    INC R6
                    CMP R6, 24
                    BR.Z ret_limpar_ecran
ciclo_colunas:      INC R7 
                    CMP R7, 79
                    CALL.Z mudar_de_linha
                    CMP R7, 79
                    BR.Z ciclo_linhas
                    MOV M[PORTO_ESCRITA], R5
                    CALL inc_cursor
                    BR ciclo_colunas

ret_limpar_ecran:   POP R7
                    POP R6
                    POP R5
                    RET
					
;####################################################################################################

fim:                ENI                    ; loop enquanto o jogador nao pressiona o botao IA
					INC	R1
					MOV M[random_seed], R1
					BR fim
