{ &HERE
NT MOV AX, HEAP_DAT
NT FPUSH AX }

{ &STR
NT MOV AX, STR_DAT
NT FPUSH AX }

{ @
NT FPOP BX
NT MOV AX, [BX]
NT FPUSH AX }

{ !
NT FPOP BX
NT FPOP AX
NT MOV [BX], AX }

: STR &STR @ ;
: HERE &HERE @ ;

{ C@
T FPOP BX
NT XOR AX, AX
NT MOV AL, byte [BX]
NT FPUSH AX }

{ C!
T FPOP BX
NT FPOP AX
NT MOV byte [BX], AL }

{ &M
T MOV AX, MIR_DAT
NT FPUSH AX }

: M &M @ ;

{ JMP
T FPOP AX
NT JMP AX }

{ ZJMP
T FPOP AX
NT FPOP BX
NT OR BX, BX
NT JNZ END_ZJMP
NT JMP AX
N END_ZJMP: }
