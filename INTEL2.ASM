	
	
	.model		small
	.stack
	
CR		equ		0dh	;Primeiro byte encontrado no final de uma linha em arquivos de texto.
LF		equ		0ah	;Segundo byte encontrado no final de uma linha em arquivos de texto.
	
	.data
	
	;Variáveis dos arquivos.
NameDados 		db	"DADOS.TXT", 0
HandleDados		dw	0

NameExp			db	"EXP.TXT", 0
HandleExp		dw	0

NameOut			db	"RESULT.TXT", 0
HandleOut		dw	0

	;Strings das mensagens.
MsgSucesso		db	"Arquivo 'RESULT.TXT' gerado com sucesso.", CR, LF, 0
MsgErroCreate	db	"Erro na criação do arquivo.", CR, LF, 0
MsgErroOpen		db	"Erro na abertura do arquivo.", CR, LF, 0
MsgErroRead		db	"Erro na leitura do arquivo.", CR, LF, 0
MsgErroWrite	db	"Erro na escrita do arquivo.", CR, LF, 0
msgErroReadExp	db	"Caracter invalido em EXP.TXT.", CR, LF, 0
msgErroColuna	db	"Numero invalido de Colunas", CR, LF, 0
msgErroDados	db	"Caracter invalido em DADOS.TXT.", CR, LF, 0
msgErroCalculo	db	"Erro no calculo dos resultados", CR, LF, 0
msgErroNColuna	db	"Numero de colunas nao corresponde", CR, LF, 0

	;Vetores que armazenam os valores dos arquivos.
vetorLinha		dw	20	DUP(?)
vetorResultados	dw	100	DUP(?)
vetorExpComAst	db	100	DUP(-1)
vetorOp1		dw	100	DUP(-1)
vetorOp2		dw	100	DUP(-1)
vetorTipoOp1	db	100	DUP(-1)	;0 = constante, 1 = coluna, 2 = resultado.
vetorTipoOp2	db	100	DUP(-1)
vetorOperacao	db	100	DUP(-1)	;1 = +, 2 = -, 3 = *, 4 = /, 5 = %, 6 = &, 7 = |, 8 = ^.
vetorIdExpFazer	db	100	DUP(0)	;Tem '1' na posição dos vetores que serão calculados.
vetorListaExp	db	100	DUP(-1)	;Tem os 'ids' das expressões a fazer na linha.

	;Variáveis que armazenam valores dos arquivos.
nColunasDados	db	0

	;Variáveis de controle dos arquivos.
FileHandle		dw 	0
FileBuffer		db	0
flagEOF			db	0
flagEOFDados	db 	0
bufferWriteByte1	db	0
bufferWriteByte2	db	0

	;Flags de leitura de EXP.TXT.
flagExpTemAst	db	0
flagExpLendoOp	db	0

	;Flags de leitura de DADOS.TXT
FlagDadoAtualNeg	db	0

	;Variáveis do controle de leitura.
IdExpAtual		dw	0
OperExpAtual	db	-1
cursorLista		dw	0
cursorVetLinha	dw	0
cursorExpComAst	dw	-1

	;Variáveis auxiliares de leitura.
bufferTipoOp	db	0
ExpCalcAux1		db	0
ExpCalcAux2		dw	0
ColCalcAux1		db	0
ColCalcAux2		dw	0
DadosCalcAux1	db	0
DadosCalcAux2	dw	0
linha1ResAux1	db	0
countNColunas	db	0

	;Variáveis de controle de escrita
countExpAFazer	db	0
valorASerEscrito	dw	0
flagWriteResultadoNeg	db	0
asciiBuffer 	db 6 dup (0)

	;Variáveis auxiliares de cálculo.
countExpFeitas	db	0
ExpSendoFeita	db	-1
cursorExpAtual	db	0

ExpFazendoOp1	dw	0
ExpFazendoOp1Ti	db	0
ExpFazendoOp2	dw	0
ExpFazendoOp2Ti	db	0
ExpFazendoOper	db	0
FlagWriteExpFazendo	db	0


	.code
	.startup
	
	;Criação do arquivo de resultado:
	
	lea dx, NameOut
	call fcreate
	mov ax, FileHandle	
	mov HandleOut, ax	;Salvando handle do arquivo criado em "HandleOut".
	
	
	;Abertura dos arquivos "DADOS.TXT" e "EXP.TXT".
	
	lea dx, NameDados
	call fopen
	mov ax, FileHandle
	mov HandleDados, ax
	
	lea dx, NameExp
	call fopen
	mov ax, FileHandle
	mov HandleExp, ax
	
	
	;Main do programa.
	
	call readExp	;Chama função que lê EXP.TXT
	
	call quantasExp	;Chama função que conta quantas expressões tem em EXP.TXT
	
	call readColuna	;Lê quantas colunas são informadas em DADOS.TXT
	
	call linha1Res	;Escreve a primeira linha de RESULT.TXT
	
	
callReadLinhaD:			;Loop principal, chama função que lê uma linha de DADOS.TXT,
	call readLinhaD		;depois chama função que calcula e escreve os dados calculados.
	cmp flagEOFDados, 1	;Se função de leitura de DADOS.TXT detecta que chegou no fim do arquivo,
	je ultimaLinha		;chama função de cálculo e escrita uma última vez antes de encerrar.
	
	call calcWriteL
	jmp callReadLinhaD

ultimaLinha:
	call calcWriteL
	
	lea bx, MsgSucesso
	call printf_s
	
	.exit 0
	
	
	
	;Funções padrão para manipulação de arquivos:
	
	fcreate		proc	near	;Cria arquivo.
		mov ah, 3ch				;Entra: dx = String com nome do arquivo.
		mov cx, 0				;Retorna: CF = 0 se ok, ax handle.
		int 21h
		jnc retfcreate	;Se flag carry = 1, erro na criação.
		lea bx, MsgErroCreate
		call printf_s	;Chama printf_s com código de erro de criação e encerra programa.
		.exit 1
		
	retfcreate:
		mov FileHandle, ax	;Se criado com sucesso, move ax (filehandle) para variável FileHandle.
		ret
	fcreate		endp
	
	
	
	fopen	proc	near	;Abre arquivo.
		mov		al,0		;Entra: dx = String com nome do arquivo.
		mov		ah,3dh		;Retorna: CF = 0 se ok, ax = handle.
		int		21h
		jnc retfopen	;Se flag carry = 1, erro na abertura.
		lea bx, MsgErroOpen
		call printf_s	;Chama printf_s com código de erro de abertura e encerra programa.
		.exit 1
		
	retfopen:	
		mov		FileHandle, ax	;Se aberto com sucesso, move ax (filehandle) para variável FileHandle.
		ret
	fopen	endp
	
	
	
	fclose	proc	near	;Fecha um arquivo.
		mov		ah,3eh
		int		21h
		ret
	fclose	endp
	
	
	
	fread	proc	near	;Lê um 1 byte de um arquivo e o armazena em "FileBuffer".
		push	cx			;Entra: bx =  handle, cx = número de bytes a serem lidos, dx = end. buffer.
		mov		ah,3fh		;Retorna: CF = 0 se ok, ax = número de bytes lidos, flagEOF = 1 se fim,
		mov		cx,1		;FileBuffer = byte lido.
		lea		dx,FileBuffer
		int		21h
		jnc fread1
		lea bx, MsgErroRead
		call printf_s
		.exit 1
		
	fread1:
		cmp ax, 0
		je freadEOF	;Testa EOF.
		pop cx
		ret
		
	freadEOF:
		mov flagEOF, 1	;Altera flag EOF.
		
		pop cx
		ret
	fread	endp
	
	
	
	fwrite		proc	near	;Escreve um byte em um arquivo.
		push cx					;Entra: bx = handle, cx = número de bytes a serem escritos,
		mov ah,40h				;dx = endereço do dado a ser escrito (bufferEscrita).
		mov cx,1				;Retorna: CF = 0 se ok, ax = número de bytes escritos.
		int 21h
		jnc retfwrite
		lea bx, MsgErroWrite
		call printf_s
		.exit 1
		
	retfwrite:
		pop cx
		ret
	fwrite		endp
	
	
	
	; Funções para funcionamento do programa:
	
	printf_s	proc	near	;Escreve uma string localizada em [bx].
		mov		dl,[bx]
		cmp		dl,0
		je		ps_1

		push	bx
		mov		ah,2
		int		21H
		pop		bx

		inc		bx		
		jmp		printf_s
			
	ps_1:
		ret
	printf_s	endp


	
	readExp		proc	near	;Lê o arquivo EXP.TXT e armazena os dados nos vetores.
	
inicioLinhaReadExp:
		mov bx, HandleExp	;Lê um byte de EXP.TXT.
		call fread
		mov al, FileBuffer
		cmp flagEOF, 1
		je fimFileExp
		
linhaReadExpComp1:
		cmp al, '('
		je inicioLinhaReadExp	;Se for parênteses, lê próximo.
		cmp al, ')'
		je inicioLinhaReadExp
		cmp al, '*'
		je linhaExpTemAst	;Se for *, expressão deve ser marcada.
		cmp al, '='
		je linhaReadExpPosIgual	;Se for '=', terminar leitura de identificador.
		cmp al, '0'
		jb erroReadExp	;Se for numérico, deve ser calculada para decimal.
		cmp al, '9'
		ja erroReadExp	;Se não for identificada, erro na formatação de EXP.TXT.
		jmp linhaExpCalcId
		
erroReadExp:
		lea bx, msgErroReadExp	;Chamada da função print com a mensagem de erro e encerramento.
		call printf_s
		.exit 1
		
linhaExpTemAst:
	mov flagExpTemAst, 1	;Liga flag "flagExpTemAst".
	jmp inicioLinhaReadExp
	
linhaExpCalcId:	;Calcula o valor dos bytes em ASCII lidos e converte para decimal.
	sub ax, '0'
	mov ExpCalcAux1, al
	mov ax, ExpCalcAux2
	mov bx, 10
	mul bx
	adc al, ExpCalcAux1
	mov ExpCalcAux2, ax	;ExpCalcAux2 terá o decimal calculado no final.
	jmp inicioLinhaReadExp
	
	
	
linhaReadExpPosIgual:
	mov ax, ExpCalcAux2	;Move o valor do identificador calculado para variável "IdExpAtual".
	mov IdExpAtual, ax
	lea si, vetorIdExpFazer
	add si, IdExpAtual
	mov [si], 1
	lea si, vetorListaExp
	add si, cursorLista
	mov [si], ax
	inc cursorLista
	lea si, vetorExpComAst
	add si, IdExpAtual
	mov al, flagExpTemAst
	mov [si], al
	mov flagExpTemAst, 0
	mov ExpCalcAux1, 0	;Zera variáveis auxiliares do cálculo de identificador.
	mov ExpCalcAux2, 0
	
	

;Início da leitura do arquivo EXP.TXT após o sinal de '='.	
	
inicioReadExpPosIgual:
	mov bx, HandleExp	;Lê um byte de EXP.TXT.
	call fread
	mov al, FileBuffer
	cmp flagEOF, 1
	je fimFileExp
	
linhaReadExpPosIgualComp1:	;Comparação do byte lido com caracteres esperados.
	cmp al, '['
	je	ReadExpPosIgualFlagColuna
	cmp al, '('
	je ReadExpPosIgualFlagResultado
	cmp al, '+'
	je ReadExpPosIgualOperadorAdd
	cmp al, '-'
	je ReadExpPosIgualOperadorSub
	cmp al, '*'
	je ReadExpPosIgualOperadorMult
	cmp al, '/'
	je ReadExpPosIgualOperadorDiv
	cmp al, '%'
	je ReadExpPosIgualOperadorResto
	cmp al, '&'
	je ReadExpPosIgualOperadorAND
	cmp al, '|'
	je ReadExpPosIgualOperadorOR
	cmp al, '^'
	je ReadExpPosIgualOperadorXOR
	cmp al, ']'
	je inicioReadExpPosIgual
	cmp al, ')'
	je inicioReadExpPosIgual
	cmp al, CR
	je salvaOpNoVetor
	cmp al, LF
	je fimLinhaExp
	cmp al, '0'
	jb erroReadExp
	cmp al, '9'
	ja erroReadExp		;Chegando ao final da comparação, se caracter não for reconhecido, erro e encerramento.
	jmp linhaExpCalcOp
	
	
	
ReadExpPosIgualFlagColuna:	;Se ler '[', salva no vetorTipoOp1 (ou 2) que o op1 (ou 2) é coluna.
	cmp flagExpLendoOp, 0
	je ReadExpPosIgualFlagColunaOp1
	jmp ReadExpPosIgualFlagColunaOp2

ReadExpPosIgualFlagColunaOp1:
	lea si, vetorTipoOp1
	add si, IdExpAtual
	mov al, 1
	mov [si], al
	jmp inicioReadExpPosIgual

ReadExpPosIgualFlagColunaOp2:
	lea si, vetorTipoOp2
	add si, IdExpAtual
	mov al, 1
	mov [si], al
	jmp inicioReadExpPosIgual
	
	
ReadExpPosIgualFlagResultado:	;Se ler '(', salva no vetorTipoOp1 (ou 2) que o op1 (ou 2) é resultado.
	cmp flagExpLendoOp, 0
	je ReadExpPosIgualFlagResultadoOp1
	jmp ReadExpPosIgualFlagResultadoOp2

ReadExpPosIgualFlagResultadoOp1:
	lea si, vetorTipoOp1
	add si, IdExpAtual
	mov al, 2
	mov [si], al
	jmp inicioReadExpPosIgual

ReadExpPosIgualFlagResultadoOp2:
	lea si, vetorTipoOp2
	add si, IdExpAtual
	mov al, 2
	mov [si], al
	jmp inicioReadExpPosIgual
	
	
	
ReadExpPosIgualOperadorAdd:	;Identifica operação, e salva código da operação no "vetorOperacao".
	lea si, vetorOperacao	;Depois pula para salvamento do operador calculado no "vetorOp1" (ou 2).
	add si, IdExpAtual
	mov al, 1
	mov [si], al
	jmp salvaOpNoVetor

ReadExpPosIgualOperadorSub:
	lea si, vetorOperacao
	add si, IdExpAtual
	mov al, 2
	mov [si], al
	jmp salvaOpNoVetor

ReadExpPosIgualOperadorMult:
	lea si, vetorOperacao
	add si, IdExpAtual
	mov al, 3
	mov [si], al
	jmp salvaOpNoVetor

ReadExpPosIgualOperadorDiv:
	lea si, vetorOperacao
	add si, IdExpAtual
	mov al, 4
	mov [si], al
	jmp salvaOpNoVetor

ReadExpPosIgualOperadorResto:
	lea si, vetorOperacao
	add si, IdExpAtual
	mov al, 5
	mov [si], al
	jmp salvaOpNoVetor

ReadExpPosIgualOperadorAND:
	lea si, vetorOperacao
	add si, IdExpAtual
	mov al, 6
	mov [si], al
	jmp salvaOpNoVetor

ReadExpPosIgualOperadorOR:
	lea si, vetorOperacao
	add si, IdExpAtual
	mov al, 7
	mov [si], al
	jmp salvaOpNoVetor

ReadExpPosIgualOperadorXOR:
	lea si, vetorOperacao
	add si, IdExpAtual
	mov al, 8
	mov [si], al
	jmp salvaOpNoVetor
	
	
	
linhaExpCalcOp:	;Calcula o valor dos bytes em ASCII lidos e converte para decimal.
	sub al, '0'
	mov ExpCalcAux1, al
	mov ax, ExpCalcAux2
	mov bx, 10
	mul bx
	adc al, ExpCalcAux1
	mov ExpCalcAux2, ax	;ExpCalcAux2 terá o decimal calculado no final.
	jmp inicioReadExpPosIgual
	


salvaOpNoVetor: ;Salva operador calculado em um dos vetores de operadores, na posição "IdExpAtual".
	cmp flagExpLendoOp, 0	;Testa se é op 1 ou op 2.
	je salvaOp1NoVetor
	jmp salvaOp2NoVetor
	
salvaOp1NoVetor:		;Se for op 1, salva no vetor, zera variáveis auxiliares e muda flag para indicar
	mov ax, ExpCalcAux2	;que próximo valor calculado será o op2.
	lea si, vetorOp1
	mov bx, IdExpAtual
	shl bx, 1
	add si, bx
	mov [si], ax
	
	lea si, vetorTipoOp1
	add si, IdExpAtual
	mov al, [si]
	cmp al, 1
	je salvaOp1NoVetor2
	cmp al, 2
	je salvaOp1NoVetor2
	mov al, 0
	mov [si], al
	
salvaOp1NoVetor2:
	mov ExpCalcAux1, 0
	mov ExpCalcAux2, 0
	
	mov flagExpLendoOp, 1
	
	jmp inicioReadExpPosIgual

salvaOp2NoVetor:		;Se for op 2, salva no vetor, zera variáveis auxiliares e muda flag para valor original.
	mov ax, ExpCalcAux2
	lea si, vetorOp2
	mov bx, IdExpAtual
	shl bx, 1
	add si, bx
	mov [si], ax
	
	lea si, vetorTipoOp2
	add si, IdExpAtual
	mov al, [si]
	cmp al, 1
	je salvaOp2NoVetor2
	cmp al, 2
	je salvaOp2NoVetor2
	mov al, 0
	mov [si], al
	
salvaOp2NoVetor2:
	mov ExpCalcAux1, 0	;Zera variáveis auxiliares e flags.
	mov ExpCalcAux2, 0
	
	mov flagExpLendoOp, 0
	
	cmp flagEOF, 1	;Testa se EOF, se sim, pula para fora da função.
	je fimFileExp1
	jmp inicioReadExpPosIgual

fimLinhaExp:
	mov ExpCalcAux1, 0	;Final da linha de EXP.TXT, zera variáveis auxiliares.
	mov ExpCalcAux2, 0
	jmp inicioLinhaReadExp
	
fimFileExp:				;Se chega no fim do arquivo, salva o último valor lido no vetor antes de sair.
	jmp salvaOp2NoVetor

fimFileExp1:
	mov flagEOF, 0
	ret
	
	readExp		endp
	
	
	
	readColuna	proc	near	;Lê a informação do número de colunas de "DADOS.TXT".
	
	readColuna1:
		mov bx, HandleDados	;Lê o primeiro byte de 'DADOS.TXT'.
		call fread
		mov al, FileBuffer
	
		cmp al, CR
		je salvaColuna
		cmp al, '0'
		jb erroReadColuna
		cmp al, '9'
		ja erroReadColuna
		
		sub al, '0'
		mov ColCalcAux1, al
		mov ax, ColCalcAux2
		mov bx, 10
		mul bx
		adc al, ColCalcAux1
		mov ColCalcAux2, ax	;ColCalcAux2 terá o decimal calculado no final.
		jmp readColuna1
	
	salvaColuna:
		mov ax, ColCalcAux2
		mov nColunasDados, al
		cmp nColunasDados, 0
		jb erroReadColuna
		cmp nColunasDados, 20
		ja erroReadColuna
			
		mov ah, 42h				;Move o ponteiro de leitura do arquivo em 1 byte, para
		mov al, 1				;que a função de leitura das linhas comece na segunda linha.
		mov bx, HandleDados
		mov cx, 0
		mov dx, 1
		int 21h
		jmp retReadColuna
		
	erroReadColuna:
		lea bx, msgErroColuna	;Chamada da função print com a mensagem de erro e encerramento.
		call printf_s
		.exit 1
		
	retReadColuna:
		ret
	
	readColuna	endp
	
	
	
	readLinhaD	proc	near	;Lê uma linha do arquivo e armazena em 'vetorLinha'.
	
		mov cursorVetLinha, 0
		mov countNColunas, 0
	
	readLinhaD1:	;Loop de leitura da DADOS.TXT.
		mov bx, HandleDados
		call fread
		mov al, FileBuffer
		cmp flagEOF, 1
		je salvaDadoNoVetorLinha
		
	compLinhaDados1:	;Identificação do byte lido.
		cmp al, ';'
		je salvaDadoNoVetorLinha
		cmp al, CR
		je salvaDadoNoVetorLinha
		cmp al, LF
		je retReadLinhaD
		cmp al, '-'
		je ligarFlagDadoAtualNeg
		cmp al, '0'
		jb erroDados
		cmp al, '9'
		ja erroDados
		jmp calcDados
		
	erroDados:	;Erro, se byte lido não for reconhecido.
		lea bx, msgErroDados
		call printf_s
		.exit 1
	
	ligarFlagDadoAtualNeg:	;Corrige byte lido se for negativo.
		mov FlagDadoAtualNeg, 1
		jmp readLinhaD1
		
	calcDados:	;Converte de ASCII para decimal.
		sub al, '0'
		mov DadosCalcAux1, al
		mov ax, DadosCalcAux2
		mov bx, 10
		mul bx
		adc al, DadosCalcAux1
		mov DadosCalcAux2, ax	;ColCalcAux2 terá o decimal calculado no final.
		jmp readLinhaD1
	
	salvaDadoNoVetorLinha:	;Salva o decimal no vetorLinha.
		add countNColunas, 1
		cmp FlagDadoAtualNeg, 1
		je salvaDadoNegNoVetorLinha
	
		mov ax, DadosCalcAux2
		lea si, vetorLinha
		add si, cursorVetLinha
		mov [si], ax
		add cursorVetLinha, 2
		mov DadosCalcAux1, 0
		mov DadosCalcAux2, 0
		cmp flagEOF, 1
		je fimDados
		jmp readLinhaD1
		
	salvaDadoNegNoVetorLinha:	;Se for negativo, dá 'neg' no valor antes de salvar.
		mov ax, DadosCalcAux2
		neg ax
		lea si, vetorLinha
		add si, cursorVetLinha
		mov [si], ax
		add cursorVetLinha, 2
		mov FlagDadoAtualNeg, 0
		mov DadosCalcAux1, 0
		mov DadosCalcAux2, 0
		cmp flagEOF, 1
		je fimDados
		jmp readLinhaD1
		
	fimDados:
		mov flagEOF, 0
		mov flagEOFDados, 1
	retReadLinhaD:
		mov al, countNColunas
		cmp al, nColunasDados
		je retReadLinhaD2
		lea bx, msgErroNColuna
		call printf_s
		.exit 1
		
	retReadLinhaD2:
		mov cursorVetLinha, 0
		ret
	readLinhaD 	endp
	
	
	
	linha1Res	proc	near	;Escreve os dados da primeira linha do arquivo "RESULT.TXT".
	
		mov cursorExpComAst, -1	;Garante que cursor comece em -1.
		
	inicioLinha1Res:	;Loop que lê vetorExpComAst e detecta em quais índices tem '*'.
		add cursorExpComAst, 1
		cmp cursorExpComAst, 100
		jge retLinha1Res
		lea si, vetorExpComAst
		add si, cursorExpComAst
		mov al, [si]
		cmp al, 1
		je achouExpComAst
		jmp inicioLinha1Res
		
	achouExpComAst:	;Se acha '1', converte em ASCII e escreve em 'RESULT.TXT'.
		mov ax, cursorExpComAst
		cmp al, 10
		jb ExpComAstUmaCasa
		jmp ExpComAstDuasCasas
	
	ExpComAstUmaCasa:
		add al, '0'
		mov bufferWriteByte1, al
		mov bx, HandleOut
		lea dx, bufferWriteByte1
		call fwrite
		jmp writePontoVirgula
		
	ExpComAstDuasCasas:
		mov ah, 0
		mov bl, 10
		div bl
		mov bufferWriteByte1, al
		mov bufferWriteByte2, ah
		add bufferWriteByte1, '0'
		add bufferWriteByte2, '0'
		
		mov bx, HandleOut
		lea dx, bufferWriteByte1
		call fwrite
		
		mov bx, HandleOut
		lea dx, bufferWriteByte2
		call fwrite
		
		jmp writePontoVirgula
		
		
	writePontoVirgula:	;Escreve ';' entre os elementos.
		mov al, ';'
		mov bufferWriteByte1, al
		mov bx, HandleOut
		lea dx, bufferWriteByte1
		call fwrite
		jmp inicioLinha1Res
		
		
	retLinha1Res:		;Antes de retornar, corrige cursor do arquivo,
		mov ah, 42h		;apagando último ';' e colocando cursor na segunda linha.
		mov al, 1
		mov bx, HandleOut
		mov cx, -1
		mov dx, -1
		int 21h
		
		mov al, CR
		mov bufferWriteByte1, al
		mov bx, HandleOut
		lea dx, bufferWriteByte1
		call fwrite
		
		mov al, LF
		mov bufferWriteByte1, al
		mov bx, HandleOut
		lea dx, bufferWriteByte1
		call fwrite
		ret
	
	linha1Res	endp
	
	
	
	quantasExp	proc	near	;Coloca o número de expressões a serem calculadas em "countExpAFazer".
	
	mov countExpAFazer, 0
	lea si, vetorListaExp
	
	inicioLoopQuantasExp:	;Loop que conta quantas elementos '1' tem no vetor.
		mov al, [si]		;'1' significa que expressão de 'id' igual ao índice deve ser feita.
		add si, 1
		cmp al, -1
		je retQuantasExp
		add countExpAFazer, 1
		jmp inicioLoopQuantasExp
		
	retQuantasExp:
		sub countExpAFazer, 1
		ret
	quantasExp	endp
	
	
	
	calcWriteL	proc	near	;Faz os cálculos e escreve no arquivo resultado.
		
		mov countExpFeitas, 0
		mov cursorExpAtual, 0
		
	inicioGetExpSendoFeita:		;Pega qual exp será feita.
		mov al, countExpAFazer
		cmp al, countExpFeitas
		je feitasTodasExpLinha
		lea si, vetorListaExp
		mov al, cursorExpAtual
		mov ah, 0
		add si, ax
		mov al, [si]
		mov ExpSendoFeita, al
		add cursorExpAtual, 1
		jmp inicioGetValoresExpSendoFeita
		
		
	inicioGetValoresExpSendoFeita:	;ExpSendoFeita é índice.
		lea si, vetorOp1		;Pega os valores da expressão nos vetores e armazena em variáveis
		mov bl, ExpSendoFeita	;para o cálculo.
		mov bh, 0
		shl bx, 1
		add si, bx
		mov ax, [si]
		mov ExpFazendoOp1, ax
		
		lea si, vetorOp2
		mov bl, ExpSendoFeita
		mov bh, 0
		shl bx, 1
		add si, bx
		mov ax, [si]
		mov ExpFazendoOp2, ax
		
		lea si, vetorTipoOp1
		mov bl, ExpSendoFeita
		mov bh, 0
		add si, bx
		mov al, [si]
		mov ExpFazendoOp1Ti, al
		
		lea si, vetorTipoOp2
		mov bl, ExpSendoFeita
		mov bh, 0
		add si, bx
		mov al, [si]
		mov ExpFazendoOp2Ti, al
		
		lea si, vetorOperacao
		mov bl, ExpSendoFeita
		mov bh, 0
		add si, bx
		mov al, [si]
		mov ExpFazendoOper, al
		
		
		lea si, vetorExpComAst
		mov bl, ExpSendoFeita
		mov bh, 0
		add si, bx
		mov al, [si]
		cmp al, 1
		jne inicioConverteOpsTipo
		mov FlagWriteExpFazendo, 1
		
		
		
	inicioConverteOpsTipo:	;'ExpFazendoOp1' e '2' serão convertidos de acordo com seu tipo.
		cmp ExpFazendoOp1Ti, 0
		je fimConverteOp1
		cmp ExpFazendoOp1Ti, 1
		je converteOp1Coluna
		cmp ExpFazendoOp1Ti, 2
		je converteOp1Resultado
		lea bx, msgErroCalculo
		call printf_s
		.exit 1
		
	converteOp1Coluna:	;Se tipo do op1 for coluna, converte em valor da coluna de dados.
		lea si, vetorLinha
		mov bx, ExpFazendoOp1
		shl bx, 1
		add si, bx
		mov ax, [si]
		mov ExpFazendoOp1, ax
		jmp fimConverteOp1
		
	converteOp1Resultado:	;Se tipo do op1 for resultado, converte em valor do vetor de resultados.
		lea si, vetorResultados
		mov bx, ExpFazendoOp1
		shl bx, 1
		add si, bx
		mov ax, [si]
		mov ExpFazendoOp1, ax
		jmp fimConverteOp1
		
	fimConverteOp1:	
		
	inicioConverteOp2:	;Converte igualmente op2.
		cmp ExpFazendoOp2Ti, 0
		je fimConverteOp2
		cmp ExpFazendoOp2Ti, 1
		je converteOp2Coluna
		cmp ExpFazendoOp2Ti, 2
		je converteOp2Resultado
		lea bx, msgErroCalculo
		call printf_s
		.exit 1
		
	converteOp2Coluna:
		lea si, vetorLinha
		mov bx, ExpFazendoOp2
		shl bx, 1
		add si, bx
		mov ax, [si]
		mov ExpFazendoOp2, ax
		jmp fimConverteOp2
		
	converteOp2Resultado:
		lea si, vetorResultados
		mov bx, ExpFazendoOp2
		shl bx, 1
		add si, bx
		mov ax, [si]
		mov ExpFazendoOp2, ax
		jmp fimConverteOp2
		
		
	fimConverteOp2:
	
	inicioCompOperacaoExpFazendo:	;Testa qual operação será feita.
		lea si, vetorOperacao
		mov bl, ExpSendoFeita
		mov bh, 0
		add si, bx
		mov al, [si]
		cmp al, 1
		je operacaoSendoFeitaADD
		cmp al, 2
		je operacaoSendoFeitaSUB
		cmp al, 3
		je operacaoSendoFeitaMULT
		cmp al, 4
		je operacaoSendoFeitaDIV
		cmp al, 5
		je operacaoSendoFeitaRESTO
		cmp al, 6
		je operacaoSendoFeitaAND
		cmp al, 7
		je operacaoSendoFeitaOR
		cmp al, 8
		je operacaoSendoFeitaXOR
		lea bx, msgErroCalculo
		call printf_s
		.exit 1
		
		
	inicioOperacaoExpFazendo:	;Faz operação, com operadores corrigidos ao tipo de operador e
								;salva resultado em 'vetorResultados'.
		
	operacaoSendoFeitaADD:
		mov ax, ExpFazendoOp1
		add ax, ExpFazendoOp2
		lea si, vetorResultados
		mov bl, ExpSendoFeita
		shl bx, 1
		add si, bx
		mov [si], ax
		jmp fimOperacaoExpFazendo
		
	
	operacaoSendoFeitaSUB:
		mov ax, ExpFazendoOp1
		sub ax, ExpFazendoOp2
		lea si, vetorResultados
		mov bl, ExpSendoFeita
		shl bx, 1
		add si, bx
		mov [si], ax
		jmp fimOperacaoExpFazendo
	
	operacaoSendoFeitaMULT:
		mov ax, ExpFazendoOp1
		mov bx, ExpFazendoOp2
		imul bx
		lea si, vetorResultados
		mov bl, ExpSendoFeita
		shl bx, 1
		add si, bx
		mov [si], ax
		jmp fimOperacaoExpFazendo
		
	
	operacaoSendoFeitaDIV:
		mov ax, ExpFazendoOp1
		cwd
		mov bx, ExpFazendoOp2
		idiv bx
		lea si, vetorResultados
		mov bl, ExpSendoFeita
		shl bx, 1
		add si, bx
		mov [si], ax
		jmp fimOperacaoExpFazendo
	
	operacaoSendoFeitaRESTO:
		mov ax, ExpFazendoOp1
		cwd
		mov bx, ExpFazendoOp2
		idiv bx
		lea si, vetorResultados
		mov bl, ExpSendoFeita
		shl bx, 1
		add si, bx
		mov [si], dx
		jmp fimOperacaoExpFazendo
	
	operacaoSendoFeitaAND:
		mov ax, ExpFazendoOp1
		mov bx, ExpFazendoOp2
		and ax, bx
		lea si, vetorResultados
		mov bl, ExpSendoFeita
		shl bx, 1
		add si, bx
		mov [si], ax
		jmp fimOperacaoExpFazendo
	
	operacaoSendoFeitaOR:
		mov ax, ExpFazendoOp1
		mov bx, ExpFazendoOp2
		or ax, bx
		lea si, vetorResultados
		mov bl, ExpSendoFeita
		shl bx, 1
		add si, bx
		mov [si], ax
		jmp fimOperacaoExpFazendo
	
	operacaoSendoFeitaXOR:
		mov ax, ExpFazendoOp1
		mov bx, ExpFazendoOp2
		xor ax, bx
		lea si, vetorResultados
		mov bl, ExpSendoFeita
		shl bx, 1
		add si, bx
		mov [si], ax
		jmp fimOperacaoExpFazendo
		
	fimOperacaoExpFazendo:	;Testa se expressão atual deve ser escrita.
		add countExpFeitas, 1
		cmp FlagWriteExpFazendo, 1	;Se sim, pula para escrita, se não, passa para próxima exp.
		jne inicioGetExpSendoFeita
		
	inicioWriteResultadoExpComAst:
		call writeResultadoEmResult
		mov FlagWriteExpFazendo, 0
		jmp inicioGetExpSendoFeita
		
	feitasTodasExpLinha:	;Final das expressões na linha atual.
		mov ah, 42h			;Apaga último ';' e escreve CR e LF para pular para próxima linha.
		mov al, 1
		mov bx, HandleOut
		mov cx, -1
		mov dx, -1
		int 21h
	
		mov al, CR
		mov bufferWriteByte1, al
		mov bx, HandleOut
		lea dx, bufferWriteByte1
		call fwrite
	
		mov al, LF
		mov bufferWriteByte1, al
		mov bx, HandleOut
		lea dx, bufferWriteByte1
		call fwrite
		
	retCalcWriteL:
		ret
	calcWriteL	endp
	
	
	
	writeResultadoEmResult	proc	near	;Função chamada quando exp tem '*'.
		lea si, vetorResultados
		mov bl, ExpSendoFeita
		shl bx, 1
		add si, bx
		mov ax, [si]
		mov valorASerEscrito, ax	;Coloca em 'valorASerEscrito' o resultado de exp com '*'.
		cmp valorASerEscrito, 0
		jl writeResultadoFlagNeg	;Testa se resultado é negativo e ativa flag.
		jmp writeResultadoDecToAscii
		
	writeResultadoFlagNeg:
		mov flagWriteResultadoNeg, 1
		jmp writeResultadoDecToAscii
		
	writeResultadoDecToAscii:	;Se valor é negativo, escreve '-' antes de valor, e dá 'neg' no mesmo.
		cmp flagWriteResultadoNeg, 1
		jne writeResultadoDecToAscii2
		mov ax, valorASerEscrito
		neg ax
		mov valorASerEscrito, ax
		mov ax, 0
		mov al, '-'
		mov bufferWriteByte1, al
		mov bx, HandleOut
		lea dx, bufferWriteByte1
		call fwrite
		mov flagWriteResultadoNeg, 0
		
	writeResultadoDecToAscii2:	;Chama função de conversão de decimal para ASCII para escrita.
		mov ax, valorASerEscrito
		mov bx, HandleOut
		call convEscreveNumero
		
		mov al, ';'	;Escreve ';' entre os elementos.
		mov bufferWriteByte1, al
		mov bx, HandleOut
		lea dx, bufferWriteByte1
		call fwrite
	
	
	retWriteResultadoEmResult:
		ret
	writeResultadoEmResult	endp
	
	
	
	convEscreveNumero proc near	;Converte decimal em ASCII para escrita em "RESULT.TXT".
    cmp ax, 0	;Testa se valorASerEscrito = 0, se sim, escreve '0' direto.
    jne loopConversao
    mov al, '0'
    mov bufferWriteByte1, al
    lea dx, bufferWriteByte1
    call fwrite
    ret

loopConversao:
    push ax	;Senão, salva ax na pilha
    mov si, offset asciiBuffer + 5

converteDigito:
    mov dx, 0       ;Converte cada dígito em ASCII e armazena em asciiBuffer para escrita.
    mov cx, 10
    div cx  
    add dl, '0' 
    dec si
    mov [si], dl
    cmp ax, 0	;Quando ax = 0, fim da conversão.
    jne converteDigito

escreveDigitos:	;Escreve cada byte de asciiBuffer.
    cmp si, offset asciiBuffer + 5	;Testa se chegou no fim do buffer.
    je fimConvEscreve	;Se sim, pula para final, senão, escreve byte em RESULT.TXT.
    mov al, [si]
    mov bufferWriteByte1, al
    lea dx, bufferWriteByte1
    call fwrite
    inc si
    jmp escreveDigitos

fimConvEscreve:
    pop ax
    ret

convEscreveNumero endp
	
	
	
	end