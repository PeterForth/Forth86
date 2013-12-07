: BACKSPACE SPC 8 EMIT SPC 8 EMIT ;

{ KEY
T XOR AX, AX
NT INT 0x16
NT XOR AH, AH
NT FPUSH AX }

{ CLEAR-STRING-BUFFER
T MOV DI, STRBUF
NT MOV BX, 128
NT XOR AX, AX

N CLEARSTART:
NT STOSB
NT DEC BX
NT OR BX, BX
NT JNZ CLEARSTART }

{ PREPARE-STRING-BUFFER
T MOV DI, STRBUF
NT MOV SI, DI
NT MOV BX, 128

N PREPARESTART:
NT LODSB
NT OR AL, AL
NT JZ ENDPREPARE
NT CMP AL, ' '
NT JNZ CASCADE1
NT XOR AL, AL

N CASCADE1:
NT CMP AL, 13
NT JNZ CASCADE2
NT XOR AL, AL

N CASCADE2:
NT CMP AL, 10
NT JNZ PREPARENEXT
NT XOR AL, AL

N PREPARENEXT:
NT STOSB
NT DEC BX
NT OR BX, BX
NT JNZ PREPARESTART

N ENDPREPARE: }

{ STR<<
T MOV AX, STRBUF
NT MOV [STR_DAT], AX }

: STR< &STR 1-! ;

: STR-WRITE STR C! &STR @ 1 + &STR ! ;

: RESET-STRING-BUFFER CLEAR-STRING-BUFFER STR<< ;

{ SENTENCE
T FWORD RESET-STRING-BUFFER

N STARTSENTENCE:
NT FWORD KEY
NT FWORD DUP
NT FWORD DUP
NT FWORD DUP
NT FPOP AX
NT CMP AX, 8
NT JNZ SENTENCECONTINUE
NT FWORD STR
NT FPOP AX
NT CMP AX, STRBUF
NT JNZ BACKSPACERESUME
NT FWORD DROP
NT FWORD DROP
NT FWORD DROP
NT JMP STARTSENTENCE

N BACKSPACERESUME:
NT FWORD EMIT
NT FWORD BACKSPACE
NT FWORD DROP
NT FWORD DROP
NT MOV AX, 0
NT FPUSH AX
NT FWORD STR<
NT FWORD STR-WRITE
NT FWORD STR<
NT JMP STARTSENTENCE

N SENTENCECONTINUE:
NT FWORD EMIT
NT FWORD STR-WRITE
NT FPOP AX
NT CMP AL, 13
NT JNZ STARTSENTENCE
NT MOV AX, 10
NT FPUSH AX
NT FWORD EMIT }

{ TESTKEY
N KEYSTART:
NT FWORD SENTENCE
NT MOV AX, STRBUF
NT FPUSH AX
NT FWORD PREPARE-STRING-BUFFER
NT FWORD WRITE
NT JMP KEYSTART }

{ SHIFT-STRING-BUFFER
T FWORD PREPARE-STRING-BUFFER
NT MOV SI, STRBUF+1
NT MOV DI, STRBUF
NT MOV CX, 127
NT MOV BX, 127
NT MOV DX, 0

N SHIFTSTART:
NT LODSB
NT STOSB
NT DEC CX
NT OR CX, CX
NT JNZ SHIFTSTART
NT MOV AL, byte [STRBUF]
NT OR AL, AL
NT JNZ SHIFTRESUME
NT MOV BX, 2
NT INC DX
NT CMP DX, 2
NT JE ENDSHIFT

N SHIFTRESUME:
NT DEC BX
NT OR BX, BX
NT JZ ENDSHIFT
NT MOV SI, STRBUF+1
NT MOV DI, STRBUF
NT MOV CX, 127
NT JMP SHIFTSTART

N ENDSHIFT: }

{ TRANSFER-STRING
N FPOP DI
NT FPOP SI

N TRANSFERSTART:
NT LODSB
NT STOSB
NT OR AL, AL
NT JNZ TRANSFERSTART }

{ DUMP
T MOV SI, STACK

N DUMPSTART:
NT LODSW
NT PUSH SI
NT FPUSH AX
NT FWORD .
NT FWORD SPC
NT POP SI
NT CMP SI, BP
NT JL DUMPSTART
NT FWORD NEWLINE }

{ ERROR
NT MOV AX, ERRORSTR
NT FPUSH AX
NT FWORD WRITE
NT NEXT
N ERRORSTR: db "ERROR",0 }

{ NUMBER
T FWORD DUP
NT FWORD STRLEN
NT FPOP AX
NT CMP AX, 4
NT JNZ NOTNUMBER
N %include "NUMBER.asm"

N NOTNUMBER:
NT FWORD ERROR }

{ LIST-WORDS
T FWORD LAST
NT FWORD @
NT FPOP SI
NT LODSW
NT MOV [LISTSAVE], AX

N LISTSTART:
NT MOV AX, [LISTSAVE]
NT OR AX, AX
NT JZ ENDLIST
NT ADD AX, 2
NT FPUSH AX
NT FWORD WRITE
NT FWORD SPC
NT MOV BX, [LISTSAVE]
NT MOV AX, [BX]
NT MOV [LISTSAVE], AX
NT JMP LISTSTART

N ENDLIST:
NT NEXT

N LISTSAVE: DW 0 }

{ FIX
T FPUSH AX }

: TRY-NUMBER STR NUMBER ;
: WORD SHIFT-STRING-BUFFER STR ;
: ' WORD FIND >CFA ;
: , HERE! ;
: B, HEREC! ;
: CREATE LAST @ , HERE 2 - LAST ! WORD HERE TRANSFER-STRING STR STRLEN HERE + 1 + &HERE ! ;
: RETURNVAL 203 ;
: WRITERET RETURNVAL B, ;
: WRITEPUSH PUSHVAL B, ;
: CALLVAL 154 ;
: WRITECALL 154 B, ;
: PUSHWORD WRITEPUSH ' , ;
: CALLWORD WRITECALL ' , 0 , ;
: LAST? LAST @ 2 + WRITE ;

{ WRITEFIX
T MOV AX, FIXNAME
NT FPUSH AX
NT FWORD FIND
NT FWORD >CFA
NT FWORD WRITECALL
NT FWORD ,
NT XOR AX, AX
NT FPUSH AX
NT FWORD ,
NT NEXT
N FIXNAME: db "FIX", 0 } 

{ PROMPT
T MOV AX, PROMPTSTR
NT FPUSH AX
NT FWORD WRITE
NT NEXT
N PROMPTSTR: db "FORTH> ",0 }

{ OK
T MOV AX, OKSTR
NT FPUSH AX
NT FWORD WRITE
NT NEXT
N OKSTR: db " OK. ",0 }

: READ PROMPT RESET-STRING-BUFFER SENTENCE STR<< PREPARE-STRING-BUFFER ;



{ REPL
N REPLSTART:
NT FWORD READ

N REPLLOOP:
NT FWORD STR<<
NT FWORD PREPARE-STRING-BUFFER
NT FWORD STR
NT FWORD FIND
NT FWORD DUP
NT FPOP AX
NT OR AX, AX
NT JZ TRYEND
NT MOV AX, [LAST]
NT OR AX, AX

NT FWORD >CFA
NT MOV AX, [STATEVAL]
NT OR AX, AX
NT JNZ COMPILEWORD
NT FWORD EXEC
NT FWORD SHIFT-STRING-BUFFER
NT JMP REPLLOOP

N COMPILEWORD:
NT MOV AL, byte [STRBUF]
NT CMP AL, '$'
NT JNZ COMPILEWORDNEXT
NT FWORD EXEC
NT FWORD SHIFT-STRING-BUFFER
NT JMP REPLLOOP

N COMPILEWORDNEXT:
NT CMP AL, ']'
NT JNZ COMPILEWORDFINISH
NT FWORD ]
NT FWORD DROP
NT FWORD SHIFT-STRING-BUFFER
NT JMP REPLLOOP

N COMPILEWORDFINISH:
NT FWORD WRITECALL
NT FWORD ,
NT XOR AX, AX
NT FPUSH AX
NT FWORD ,
NT FWORD SHIFT-STRING-BUFFER
NT JMP REPLLOOP

N TRYEND:
NT FWORD DROP
NT FWORD STR<<
NT FWORD STR
NT FWORD STRLEN
NT FPOP AX
NT OR AX, AX
NT JZ REPLEND
NT JMP TRYNUMBER

N TRYNUMBER:
NT MOV AX, BP
NT FPUSH AX
NT FWORD M>
NT FWORD STR
NT FWORD NUMBER
NT FWORD >M
NT FPOP AX
NT CMP AX, BP
NT JZ REPLEND
NT MOV AX, [STATEVAL]
NT OR AX, AX
NT JZ TRYNUMNEXT
NT FWORD WRITEPUSH
NT FWORD ,
NT FWORD WRITEFIX

N TRYNUMNEXT:
NT FWORD SHIFT-STRING-BUFFER
NT JMP REPLLOOP

N REPLEND:
NT FWORD OK
NT FWORD NEWLINE
NT JMP REPLSTART 

N ERRORLEVEL: dw 0
N STRNAME: db "FIX",0 }


{ EVAL
N REPLLOOP1:
NT FWORD STR<<
NT FWORD PREPARE-STRING-BUFFER
NT FWORD STR
NT FWORD FIND
NT FWORD DUP
NT FPOP AX
NT OR AX, AX
NT JZ TRYEND1
NT MOV AX, [LAST]
NT OR AX, AX

NT FWORD >CFA
NT MOV AX, [STATEVAL]
NT OR AX, AX
NT JNZ COMPILEWORD1
NT FWORD EXEC
NT FWORD SHIFT-STRING-BUFFER
NT JMP REPLLOOP1

N COMPILEWORD1:
NT MOV AL, byte [STRBUF]
NT CMP AL, '$'
NT JNZ COMPILEWORDNEXT1
NT FWORD EXEC
NT FWORD SHIFT-STRING-BUFFER
NT JMP REPLLOOP1

N COMPILEWORDNEXT1:
NT CMP AL, ']'
NT JNZ COMPILEWORDFINISH1
NT FWORD ]
NT FWORD DROP
NT FWORD SHIFT-STRING-BUFFER
NT JMP REPLLOOP1

N COMPILEWORDFINISH1:
NT FWORD WRITECALL
NT FWORD ,
NT XOR AX, AX
NT FPUSH AX
NT FWORD ,
NT FWORD SHIFT-STRING-BUFFER
NT JMP REPLLOOP1

N TRYEND1:
NT FWORD DROP
NT FWORD STR<<
NT FWORD STR
NT FWORD STRLEN
NT FPOP AX
NT OR AX, AX
NT JZ REPLEND1
NT JMP TRYNUMBER1

N TRYNUMBER1:
NT MOV AX, BP
NT FPUSH AX
NT FWORD M>
NT FWORD STR
NT FWORD NUMBER
NT FWORD >M
NT FPOP AX
NT CMP AX, BP
NT JZ REPLEND1
NT MOV AX, [STATEVAL]
NT OR AX, AX
NT JZ TRYNUMNEXT1
NT FWORD WRITEPUSH
NT FWORD ,
NT FWORD WRITEFIX

N TRYNUMNEXT1:
NT FWORD SHIFT-STRING-BUFFER
NT JMP REPLLOOP1

N REPLEND1:
NT FWORD OK
NT FWORD NEWLINE
NT NEXT }
