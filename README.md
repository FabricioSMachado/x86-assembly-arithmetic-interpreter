# x86-assembly-arithmetic-interpreter
Projeto em Assembly x86 (16-bit, modo real, DOS, interrupções INT 21h) que lê dados de dois arquivos de .txt e escreve um novo arquivo de texto com resultados de operações aritméticas descritas. Desenvolvido para disciplina de Arquitetura e Organização de Computadores 1.

O projeto utiliza o emulador "DOSBox" para simulação do ambiente MS-DOS e o montador "MASM" para a montagem à partir do arquivo fonte.
Estão incluídos no repositório os arquivos gerados pelo montador e os arquivos de texto utilizados para teste da aplicação, arquivos estes que seguem o padrão requisitado pela especificação do trabalho proposto.

Foi também utilizado o "CodeView" dentro do ambiente do DOSBox para teste e depuração do código fonte, software esse que permite a vizualização dos registradores e dos endereços de memórias utilizados.

Este projeto foi desenvolvido como trabalho acadêmico, e também serviu para exercitar uma básica programação de baixo nível, incluíndo manipulação direta de arquivos com syscall, registradores e memória.
