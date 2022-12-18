STDIN     equ 0
STDOUT    equ 1
section .data
    WMsg db "Введите строку: "
    lenW equ $- WMsg
    EndMsg db "Everything works ok!"
    lenEnd equ $- EndMsg
    EndEnter db 0xa
    CaseWord db "Case"
    EqualWord db ":="
    EndWord db "end;"
    EndAnotherWord db "end"
    OfWord db "of"
    Yes db "yes"
    lenYes equ $- Yes
    No db "no"
    lenNo equ $- No
    del db " "
    Comma db ","
    lenComma equ $- Comma
    flag_fst dw 0
    NotFinishedError db "Команда не дописана. Ошибка!"
    lenNFE equ $- NotFinishedError
    CaseWaiting db "Проверка на команду Case. "
    lenCW equ $- CaseWaiting
    AssignmentWaiting db "Команда Case не получена. Проверка на присваивание."
    lenAW equ $- AssignmentWaiting
    VarMsg db "Переменная присваивания: "
    lenVM equ $- VarMsg
    NumbError db "Ошибка в числе."
    lenNE equ $- NumbError
    NumbMsg db "Число присваивания: "
    lenNM equ $- NumbMsg
    RightMsg db "Команда правильная."
    lenRM equ $- RightMsg
    VarCaseError db "Ошибка. В команде Case должна быть переменная."
    lenVCE equ $- VarCaseError
    CaseVarMsg db "Переменная-итератор Case: "
    lenCVM equ $- CaseVarMsg
    NumbCaseMsg db "Значения переменной в этой ветке Case: "
    lenNCM equ $- NumbCaseMsg
    VarError db "При присваивании слева должна быть переменная"
    lenVE equ $- VarError
    NotEnoughEndsError db "Неправильное количество end"
    lenNEEE equ $- NotEnoughEndsError
    OverWrittenError db "Что-то лишнее в команде. Ошибка!"
    lenOWE equ $- OverWrittenError

section .bss
	OutBuf resb 10
	lenOut equ $-OutBuf
	Row resb 255
	InpRow equ $-Row
	count resw 1
	symb resb 8
	count_of_end resw 1
	count_of_case resw 1
	arr_of_gramm times 100 resw 1
	len_arr_gramm resw 1

section .text
	%include "../lib64.asm"
	global _start

_start:
	mov [count_of_end], word 0
	mov [count_of_case], word 0
	
	cmp word [len_arr_gramm], 0
	jg nullArray
	
	mov [len_arr_gramm], word 0
	jmp input_str

nullArray:
	mov rsi, arr_of_gramm
	mov rcx, [len_arr_gramm]
	mov rbx, 0
	clr:
		mov word [arr_of_gramm + 2 * rbx], ''
		
		inc rbx
		cmp rbx, rcx
		jne clr
	
	mov [len_arr_gramm], word 0
	jmp input_str

input_str:		
	mov rax, STDOUT
	mov rdi, STDOUT
	mov rsi, WMsg
	mov rdx, lenW
	syscall

	mov rax, STDIN
	mov rdi, STDIN
	mov rsi, Row
	mov rdx, InpRow
	syscall

	mov rdi, Row
	mov rax, 0
	jmp str_to_words

str_to_words:
	movzx rsi, byte [rdi]

	cmp rsi, ' '
	je whatWord
	
	cmp rsi, 0xa
	je isEndExit

	mov [symb + rax], si          ; записываем число во временную переменную
	inc rdi
	inc rax
	jmp str_to_words

isEndExit:
	mov si, [EndAnotherWord]

	cmp si, [symb]
	je exit
	
	jmp notFinishedError

varError:
	push rdi
	push rax
	push rsi
	
	mov rax, STDOUT
	mov rdi, STDOUT
	mov rsi, VarError
	mov rdx, lenVE
	syscall
	
	call EnterOut
	
	pop rsi
	pop rax
	pop rdi
	
	jmp new

notFinishedError:
	push rdi
	push rax
	push rsi
	mov rax, STDOUT
	mov rdi, STDOUT
	mov rsi, NotFinishedError
	mov rdx, lenNFE
	syscall
	
	call EnterOut
	
	pop rsi
	pop rax
	pop rdi
	jmp new

EnterOut:
	mov rax, STDOUT        ; вывод
	mov rdi, STDOUT
	mov rsi, EndEnter
	mov rdx, 1
	syscall
	
	ret

whatWord:
	inc rdi
	
	call caseWaiting
	
	call isCase
	cmp rbx, 1
	je callCasePath
	 
	call assignmentWaiting
	
	call isVar
	cmp rbx, 1
	je isAssignmentCall
	
	jmp varError

assignmentWaiting:
	push rdi
	push rax
	push rsi
	
	mov rax, STDOUT
	mov rdi, STDOUT
	mov rsi, AssignmentWaiting
	mov rdx, lenAW
	syscall
	
	call EnterOut
	pop rsi
	pop rax
	pop rdi	
	ret

caseWaiting:
	push rdi
	push rax
	push rsi
	
	mov rax, STDOUT
	mov rdi, STDOUT
	mov rsi, CaseWaiting
	mov rdx, lenCW
	syscall
	
	call EnterOut
	pop rsi
	pop rax
	pop rdi	
	ret

printVar:
	push rdi
	push rax
	push rsi
	
	mov rdx, lenVM
	mov rax, STDOUT
	mov rdi, STDOUT
	mov rsi, VarMsg
	syscall
	
	mov rdx, rax
	mov rax, STDOUT
	mov rdi, STDOUT
	mov rsi, symb
	syscall
	
	pop rsi
	pop rax
	pop rdi	
	ret

isAssignmentCall:
	call printVar
	mov rax, 0
	jmp isAssignment

isAssignment:
	movzx rsi, byte [rdi]
	
	cmp rsi, ' '
	je IsEqualAssignment
	
	cmp rsi, ';'
	je IsNumbAssignment
	
	cmp rsi, 0xa
	je notFinishedError
	
	mov [symb + rax], si          ; записываем число во временную переменную
	inc rdi
	inc rax
	jmp isAssignment

IsEqualAssignment:
	call isEqual
	cmp rbx, 0
	je notFinishedError
	
	inc rdi
	mov rsi, ''
	mov [symb], rsi
	mov rax, 0
	jmp isAssignment

IsNumbAssignment:
	call isNumb
	cmp rbx, 0
	je numbError
	
	call printNumb
	
	inc rdi
	movzx rsi, byte [rdi]
	
	cmp rsi, 0xa
	je printRight
	
	cmp rsi, ' '
	jne overWrittenError
	
	whileSpace:
		inc rdi
		movzx rsi, byte [rdi]
		
		cmp rsi, 0xa
		je printRight
		
		cmp rsi, ' '
		je whileSpace

	jmp overWrittenError

overWrittenError:
	push rdi
	push rax
	push rsi
	
	mov rax, STDOUT
	mov rdi, STDOUT
	mov rsi, OverWrittenError
	mov rdx, lenOWE
	syscall
	
	call EnterOut
	pop rsi
	pop rax
	pop rdi
	
	jmp new


printNumb:
	push rdi
	push rax
	push rsi
	
	mov rax, STDOUT
	mov rdi, STDOUT
	mov rsi, NumbMsg
	mov rdx, lenNM
	syscall
	
	pop rax
	push rax
	
	mov rdx, rax
	mov rax, STDOUT
	mov rdi, STDOUT
	mov rsi, symb
	syscall
	
	call EnterOut
	pop rsi
	pop rax
	pop rdi
	
	ret

numbError:
	push rdi
	push rax
	push rsi
	
	mov rax, STDOUT
	mov rdi, STDOUT
	mov rsi, NumbError
	mov rdx, lenNE
	syscall
	
	call EnterOut
	pop rsi
	pop rax
	pop rdi
	
	jmp new	
	
isCase:
	push rsi
	mov si, [CaseWord]

	cmp si, [symb]
	je case
	
	jmp notCase
	
	notCase:
		mov rbx, 0
		pop rsi
		ret
	
	case:
		mov rbx, 1
		pop rsi
		ret

callCasePath:
	add [count_of_case], word 1
	mov rsi, ''
	mov [symb], rsi
	mov rax, 0
	call casePath

casePath:
	casePathCycle:
		movzx rsi, byte [rdi]

		cmp rsi, ' '
		je callIsVar
		
		cmp rsi, 0xa
		je notFinishedError

		mov [symb + rax], si          ; записываем число во временную переменную
		inc rdi
		inc rax
		jmp casePathCycle

callIsVar:
	inc rdi
	call isVar	
	cmp rbx, 1
	je callSkipOf
	
	jmp varCaseError

printVarCase:
	push rdi
	push rax
	push rsi
	
	mov rdx, lenCVM
	mov rax, STDOUT
	mov rdi, STDOUT
	mov rsi, CaseVarMsg
	syscall
	
	mov rdx, rax
	mov rax, STDOUT
	mov rdi, STDOUT
	mov rsi, symb - 1
	syscall
	
	pop rsi
	pop rax
	pop rdi	
	ret

varCaseError:
	push rdi
	push rax
	push rsi
	
	mov rax, STDOUT
	mov rdi, STDOUT
	mov rsi, VarCaseError
	mov rdx, lenVCE
	syscall
	
	call EnterOut
	pop rsi
	pop rax
	pop rdi
	
	jmp new
	
isVar:
	push rsi
	mov si, [CaseWord]

	cmp si, [symb]
	je notVar
	
	mov si, [EqualWord]

	cmp si, [symb]
	je notVar
	
	mov si, [OfWord]

	cmp si, [symb]
	je notVar
	
	mov si, [EndWord]

	cmp si, [symb]
	je notVar
	
	mov si, [EndAnotherWord]

	cmp si, [symb]
	je notVar
	
	call isNumb
	cmp rbx, 1
	je notVar
	
	jmp var
	
	notVar:
		mov rbx, 0
		pop rsi
		ret
	var:
		mov rbx, 1
		pop rsi
		ret

callSkipOf:
	call printVarCase
	
	mov rsi, ''
	mov [symb], rsi
	mov rax, 0
	
	jmp skipOf

skipOf:
	movzx rsi, byte [rdi]

	cmp rsi, ' '
	je callIsOf
	
	cmp rsi, 0xa
	je notFinishedError

	mov [symb + rax], si          ; записываем число во временную переменную
	inc rdi
	inc rax
	jmp skipOf

callIsOf:
	inc rdi
	call isOf

	mov rsi, ''
	mov [symb], rsi
	mov rax, 0
	
	cmp rbx, 1
	je numbAnalyzer
	
	jmp notFinishedError
	
isOf:
	push rsi
	mov si, [OfWord]

	cmp si, [symb]
	je is_of
	
	jmp notOf
	
	notOf:
		mov rbx, 0
		pop rsi
		ret
	
	is_of:
		mov rbx, 1
		pop rsi
		ret
	
numbAnalyzer:
	movzx rsi, byte [rdi]

	cmp rsi, ','
	je callIsNumb
	
	cmp rsi, ':'
	je callIsNumbLast           ; проверить на номер(вдруг последнее число не число)
	
	cmp rsi, 0xa
	je callIsFinalEnd
	
	cmp rsi, ';'
	je callIsEnd

	mov [symb + rax], si          ; записываем число во временную переменную
	inc rdi
	inc rax
	jmp numbAnalyzer

callIsNumb:
	inc rdi
	call isNumb
	
	cmp rbx, 1
	je callIsInArray

callIsInArray:
	call isInArray
	
	cmp rbx, 1
	je callPrintNumbCase
	
	jmp numbError
	
isInArray:
	push rsi
	push rdi
	push rax
	
	mov esi, symb
	call StrToInt64
	cmp ebx, 0
	jne StrToInt64.Error
	
	mov ebx, 0
	array_parse:
		movzx rsi, word [arr_of_gramm + 2 * ebx]
		
		cmp ax, si
		je inArray
		
		inc rdi
		inc rbx
		
		cmp rbx, [len_arr_gramm]		
		jle array_parse
	
	jmp notInArray
		
	inArray:
		mov rbx, 0
		pop rax
		pop rdi
		pop rsi
		ret
		
	notInArray:
		dec rbx
		mov [arr_of_gramm + 2 * rbx], ax
		inc word[len_arr_gramm]
		mov rbx, 1
		pop rax
		pop rdi
		pop rsi
		ret


callPrintNumbCase:
	call printNumbCase
	
	mov rsi, ''
	mov [symb], rsi
	mov rax, 0
	
	jmp numbAnalyzer

printNumbCase:
	push rdi
	push rax
	push rsi
	
	mov rax, STDOUT
	mov rdi, STDOUT
	mov rsi, NumbCaseMsg
	mov rdx, lenNCM
	syscall
	
	pop rax
	push rax
	
	mov rdx, rax
	mov rax, STDOUT
	mov rdi, STDOUT
	mov rsi, symb
	syscall
	
	call EnterOut
	pop rsi
	pop rax
	pop rdi
	
	ret

callIsNumbLast:
	;inc rdi
	call isNumb
	
	cmp rbx, 1
	je callIsInArrayLast
	
	jmp numbError

callIsInArrayLast:
	call isInArray
	
	cmp rbx, 1
	je lastNumbInBranch
	
	jmp numbError

lastNumbInBranch:
	push rdi
	push rax
	push rsi
	
	mov rax, STDOUT
	mov rdi, STDOUT
	mov rsi, NumbCaseMsg
	mov rdx, lenNCM
	syscall
	
	pop rax
	push rax
	
	mov rdx, rax
	mov rax, STDOUT
	mov rdi, STDOUT
	mov rsi, symb
	syscall	
	
	call EnterOut
	pop rsi
	pop rax
	pop rdi
	
	mov rsi, ''
	mov [symb], rsi
	mov rax, 0
	
	jmp callInBranch

isNumb:
	push rax
	push rdi
	push rsi
	mov [symb + rax], byte 0xa
	mov rdi, symb
	
	movzx rsi, byte [rdi]
	cmp rsi, '-'
	jne isNumbCycle
	
	inc rdi
	
	isNumbCycle:
		movzx rsi, byte [rdi]
		
		cmp rsi, 0xa
		je Numb
		
		cmp rsi, '0'
		jl notNumb
		
		cmp rsi, '9'
		jg notNumb
		
		inc rdi
		jmp isNumbCycle
	
	notNumb:
		mov rbx, 0
		pop rax
		pop rdi
		pop rsi
		ret
	
	Numb:
		mov rbx, 1
		pop rax
		pop rdi
		pop rsi
		ret

callInBranch:
	call inBranch
	
	inc rdi
	movzx rsi, byte [rdi]
	cmp rsi, 0xa
	je callIsFinalEnd
	
	;inc rdi
	movzx rsi, byte [rdi]
	cmp rsi, ' '
	je callIncRdi
	
	jmp numbAnalyzer

callIncRdi:
	inc rdi
	jmp numbAnalyzer

inBranch:
	add rdi, 2
	
	mov rsi, ''
	mov [symb], rsi
	mov rax, 0
	
	jmp branchCycle

	branchCycle:
		movzx rsi, byte [rdi]

		cmp rsi, ';'
		je endOfBranch          ; путь на проверку на присваивание
		
		cmp rsi, ' '
		je whatWordInBranch
		
		cmp rsi, 0xa
		je notFinishedError

		mov [symb + rax], si          ; записываем число во временную переменную
		inc rdi
		inc rax
		jmp branchCycle
	
	endOfBranch:
		call isVar
		cmp rbx, 1
		je notFinishedError
		
		whileSpaceBranch:
			inc rdi
			movzx rsi, byte [rdi]
			
			cmp rsi, ' '
			je whileSpaceBranch
		
		dec rdi
		mov rsi, ''
		mov [symb], rsi
		mov rax, 0
		
		ret
	
	whatWordInBranch:
		inc rdi
		
		call isCase
		cmp rbx, 1
		je callCasePathBranch
		
		call isVar
		cmp rbx, 0
		je varError
		
		;inc rdi
		jmp isAssignmentBranch
		
	callCasePathBranch:
		add [count_of_case], word 1
		mov rsi, ''
		mov [symb], rsi
		mov rax, 0
		call casePathBranch
		
		call isEndCheck
		cmp rbx, 1
		je endOfBranch
		
		mov rsi, ''
		mov [symb], rsi
		mov rax, 0
		jmp branchCycle
	
	casePathBranch:
		push ax
		push rsi
		push rbx
		push rcx
		
		mov rbx, [len_arr_gramm]
		pushArray:
			mov ax, [arr_of_gramm + 2 * rbx]
			push ax
			
			dec rbx
			cmp rbx, 0
			jge pushArray
		
		mov rsi, arr_of_gramm
		mov rcx, [len_arr_gramm]
		mov rbx, 0
		clrBranch:
			mov word [arr_of_gramm + 2 * rbx], ''
			
			inc rbx
			cmp rbx, rcx
			jne clrBranch
		
		mov rbx, [len_arr_gramm]
		push rbx
		mov [len_arr_gramm], word 0
		
		call casePath
		pop rbx
		mov [len_arr_gramm], rbx
		
		mov rbx, 0
		popArray:
			pop ax
			mov [arr_of_gramm + 2 * rbx], ax
			
			inc rbx
			cmp rbx, [len_arr_gramm]
			jle popArray
			
		pop rcx
		pop rbx
		pop rsi
		pop ax	
		ret
		

isAssignmentBranch:
	call printVar
	mov rsi, ''
	mov [symb], rsi
	mov rax, 0
	
	jmp callIsAssignment

callIsAssignment:
	movzx rsi, byte [rdi]
	
	cmp rsi, ' '
	je callIsEqualAssignment
	
	cmp rsi, ';'
	je callIsNumbAssignment
	
	mov [symb + rax], si          ; записываем число во временную переменную
	inc rdi
	inc rax
	jmp callIsAssignment

callIsEqualAssignment:
	call isEqual
	cmp rbx, 0
	je notFinishedError
	
	inc rdi
	mov rsi, ''
	mov [symb], rsi
	mov rax, 0
	jmp callIsAssignment

callIsNumbAssignment:
	call isNumb
	cmp rbx, 0
	je NumbError
	
	call printNumb
	jmp branchCycle

callIsEnd:
	inc rdi
	movzx rsi, byte [rdi]
	cmp rsi, 0xa
	je callIsFinalEnd
	
	dec rdi
	call isEnd
	inc rdi
	ret

callIsFinalEnd:
	call isEnd
	
	dec rdi
	movzx rsi, byte [rdi]
	cmp rsi, ';'
	jne notFinishedError
	
	mov rbx, [count_of_case]
	cmp bx, [count_of_end]
	je printRight
	
	jmp notEnoughEndsError

notEnoughEndsError:
	push rdi
	push rax
	push rsi
	
	mov rdx, lenNEEE
	mov rax, STDOUT
	mov rdi, STDOUT
	mov rsi, NotEnoughEndsError
	syscall
	
	call EnterOut
	pop rsi
	pop rax
	pop rdi	
	
	pop rsi
	pop rax
	pop rdi
	
	jmp new

isEndCheck:
	mov si, [EndWord]

	cmp si, [symb]
	je endCheck
	
	jmp notEndCheck
	
	endCheck:
		mov rbx, 1
		ret
	
	notEndCheck:
		mov rbx, 0
		ret

isEnd:
	mov si, [EndWord]

	cmp si, [symb]
	je end
	
	jmp notEnd
	
	end:
		add [count_of_end], word 1
		ret
	
	notEnd:
		ret

isEqual:
	push rsi
	mov si, [EqualWord]

	cmp si, [symb]
	je equal
	
	jmp notEqual
	
	notEqual:
		mov rbx, 0
		pop rsi
		ret
	
	equal:
		mov rbx, 1
		pop rsi
		ret

printRight:
	mov rax, STDOUT        ; вывод
	mov rdi, STDOUT
	mov rsi, RightMsg
	mov rdx, lenRM
	syscall
	
	call EnterOut
	
	jmp new

new:
	call EnterOut
	jmp _start

exit:	
	mov rax, 60
	xor rdi, rdi
	syscall
