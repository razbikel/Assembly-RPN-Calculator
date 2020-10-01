section .data
    curr: dd 0               ; index for the next empty place in stack
    debug: dd 0              ; flag for debug mode , will change to 1 when activated
    num_of_operations: dd 0  ; munber of operations that was done (successful amd unsuccessful)
    flag_insuff: dd 0        ; flag for know if insuff error was printed for not free memory 
    carry_of_add: dd 0       ; carry flag for addition func
    end_num1: dd 0           ; flag for know if we arrived to the end of num 1 in addition
    end_num2: dd 0           ; flag for know if we arrived to the end of num 2 in addition
    valid_Y: dd 0            ; flag for know if Y_error was printed
    Y: dd 0                  ; for power operation- keep value of Y
    num_of_ones: dd 0        ; for counting the number of 1 bits in 'n' operation
    is_first_node: dd 0      ; flag for division func to know if we are in first node
    

section .rodata
    line_down: db 10, 0      ;\n format
    str: db "%s", 10, 0	     ; format string
    str2: db "%s", 0         ; format string without \n
    str3: db "%X", 10, 0     ; format HEXA with \n
    str4: db "%X", 0	     ; format HEXA without \n
    calc: db "calc: ", 0  
    overflow: db "Error: Operand Stack Overflow",10 ,0
    insuff: db "Error: Insufficient Number of Arguments on Stack",10 ,0 
    getsError: db "Error: gets function return an error",10 ,0
    Y_error: db "wrong Y value" ,10 ,0

section .bss
    stack: resd 5           ; allocates 4 bytes * 5 for the oprations stack     
    input: resb 80          ; keep the pointer to the string
    head: resd 32           ; pointer that will keep the address of head of list for free memory in the end
    last_node: resd 32      ; pointer that will keep the address of the place in the last node that was entered that we want to save there the next node
    

section .text
align 16
    global main
    extern printf
    extern fflush
    extern malloc
    extern calloc
    extern free
    extern gets
    extern fgets
    ;File types
    extern stdin
    extern stdout
    extern stderr


; macro arg = number of operands should be in the stack
; checks if there are enough operands in stack, if not prints error and changes flag_insuff
%macro check_insuff 1                 
        mov ecx, [curr]              
        cmp ecx, %1                             ; compare between the curr and the argument
        jnb %%end_check_insuff                  ; jump if curr is not below the argument
        mov dword [flag_insuff], 1              ; changing the insuff flag
        push insuff                             ; push seconed argument for printf
        call printf                             ; print overflow error string
	add esp, 4                              ; "make pop" for the printf arguments
	%%end_check_insuff:
%endmacro


; count in node's data the number of 1 bits and adds it to num_of_ones variable
%macro count_ones_in_node 0          
        mov ebx, 4                              ; ebx will be counter of the loop to shift right 4 times (becuase F = 1111)
        %%count_loop:                           ;
        shr dl , 1                              ; for the lsb in carry flag
        jnc %%not_count                         ; if there is no 1 bit , we dont want to increace num_of_ones
        add dword [num_of_ones], 1              ; if there is carry after shift right it says that 1 was there so we add it to the counter
        %%not_count:
        dec ebx                                 ; decrement the loop counter by 1
        cmp ebx, 0                              ; check if the loop happend 4 times
        jnz %%count_loop                        ; if not , go back to count_loop
%endmacro


; do the begining of the power and power_fruction cases
%macro begin_power 0
        check_insuff 2                     ; check if there are two operands to do the addition
        cmp dword [flag_insuff], 1         ; checking if insuff flag is 1 so we cant do the addition
        jz %%change_flag_insuff_tozero_p
        call my_pop
        mov eax, [head]                    ; move X to eax
        call my_pop
        mov ebx, [head]                    ; move Y to ebx
        
        push ebx                           ; backup ebx before duplicate
        push eax                           ; backup eax before duplicate
        call list_to_num                   ; convert the Y list to decimal number , and put it in [Y]
        pop eax                            ; restore eax X
        pop ebx                            ; restore ebx Y
        
        cmp dword [valid_Y], 1             ; check if there was an error
        jnz %%continue_power                ; if not, we want to continue
                                           ; if yes, we want to put X and Y back in stack
        mov [head], ebx                    ; put in head the Y for duplicate it for put it back in stack
        push eax                           ; backup eax before duplicate
        push ebx                           ; backup ebx before duplicate
        call my_duplicate                  ; duplicate Y (which is not in stack now) , for put it in the top of the stack
        pop ebx                            ; restore ebx  - Y
        pop eax                            ; restore eax - X
        mov [head], eax                    ; put in head the X for duplicate it for put it back in stack
        push eax                           ; backup eax before duplicate
        push ebx                           ; backup ebx before duplicate
        call my_duplicate                  ; duplicate X (which is not in stack now) , for put it in the top of the stack
        pop ebx                            ; restore ebx  - Y
        pop eax                            ; restore eax - X
        
        ; free_X_Y
        mov dword [head], eax              ; put in head X for free 
        call free_memory_node              ;
        mov dword [head], ebx              ; put in head Y for free
        call free_memory_node              ; 
        mov dword [valid_Y], 0
        
        %%change_flag_insuff_tozero_p:
        mov dword [flag_insuff], 0
        jmp main_loop
        
        %%continue_power:
%endmacro

; check if debug and if yes print the node we pushed
%macro print_debug 0          
        cmp dword [debug], 1
        jnz %%end_print_debug
        call my_peek
        call print_list
        %%end_print_debug:
%endmacro


main:

        push ebp
	mov ebp, esp	
        pushad
        
        mov edx, dword [ebp+8]                  ; move argc to ebx
        cmp edx, 2                              ; check if argc is less then 2 (it says that argv size is 1)
        jb call_myCalc                          ; if argc is less then 2 we are not in dbug mode and want to go to myCalc func
        mov ecx, dword [ebp+12]                 ; move the pointer to argv[] to eax
        
        check_debug:
        
	mov ebx, [ecx+4]
	cmp byte [ebx],'-'                     ; check if we see "-"
	jnz call_myCalc
	inc ebx
	cmp byte [ebx],'d'                     ; check if we see "d"
	jnz call_myCalc
	mov dword [debug], 1                   ; we saw "-d" so the debug mode is activated
        
        
        call_myCalc:   
        call myCalc
        
        ;print num_of_operations
        push dword [num_of_operations]          ; push num_of_operations- second arg for printf
        push str3                               ; push format hexa with \n
        call printf 
        add esp,8                               ; "make pop" for printf arguments
        
        free_loop:                              ; loop for free all linked list that have last in the stack                           
        cmp dword [curr], 0                     ; compare zero to the curr, if its 0 we dont have what to free 
        jz end_main                             ; 
        call my_pop                             ; poping the first operand from stack and reducing curr
        call free_memory_node                   ; free the operand we poped
        jmp free_loop
        
        end_main:
        popad			
	mov esp, ebp	
	pop ebp
	ret

; func that read from the keyboard what the user entered and call the right func to do the correct operation    
myCalc:

        push ebp
	mov ebp, esp	
	pushad	
	
	main_loop:
	
            push calc                           ; push seconed argument for printf
            push str2                           ; push first argument for printf
            call printf                         ; print calc
            add esp,8                           ; "make pop" for the printf arguments
            
            push input                          ; push the input string for keep the input from the user
            call gets                           ; read from keyboard
            add esp, 4                          ; "make pop" for the printf arguments
            
            cmp eax, '\0'                       ; check if the gets func returns \0
            jz print_gets_error                 ; if yes, we print an error messege
            
	    cmp byte [input], 'q'               ; check if the user want to exit
	    jz end_myCalc                       ; if yes, we end the loop
	    
	    ; inc num of operations by one
	    mov eax, [num_of_operations] 
	    inc eax                       
	    mov [num_of_operations], eax
	    
	    cmp byte [input], '+'            
	    jz unsigned_addition

	    cmp byte [input], 'p'
	    jz pop_and_print
	    
	    cmp byte [input], 'd'
	    jz duplicate
	    
	    cmp byte [input], '^'
	    jz power  
	    
	    cmp byte [input], 'v'
	    jz power_fruction
	    
	    cmp byte [input], 'n'
	    jz number_of_ones
	    
	    ; dec num of operations by one if we need to push num and not do operation
	    mov eax, [num_of_operations] 
	    dec eax                       
	    mov [num_of_operations], eax
	    
	    jmp call_my_push
	    
	    print_gets_error:
	    push getsError                     ; push argument for printf - error messege
	    call printf  
	    add esp, 4                         ; "make pop" for printf arguments
	    jmp main_loop  
	    
	    unsigned_addition:
	    check_insuff 2                     ; check if there are two operands to do the addition
	    cmp dword [flag_insuff], 1         ; checking if insuff flag is 1 so we cant do the addition
	    jz change_flag_insuff_tozero       ; if yes (flag_insuff=1), jump to change it to zero for the next operations
	    call my_pop                        ; if not (flag_insuff=0), we pop two operands from the stack
	    mov eax, [head]                    ; save num2 in eax
	    call my_pop                        ; 
	    mov ebx, [head]                    ; save num1 in ebx
	    push eax                           ; push second num for seconed arg to my_addition
	    push ebx                           ; push first num for first arg to my_addition
	    call my_addition                   ; call my_addition for add the two nums and push it to the stack 
	    add esp, 8                         ; pop arguments
	    mov dword [head], eax              ; move num2 to [head] for free the list of it
	    call free_memory_node
	    mov dword [head], ebx              ; move num1 to [head] for free the list of it
	    call free_memory_node
	    
	    jmp main_loop

	    pop_and_print:
            call my_pop                        ; poping the next operand from stack
            cmp dword [flag_insuff], 1         ; checking if insuff flag is 1 
            jz change_flag_insuff_tozero       ; if insuff flag is 1 then we dont have node to print so we just want to go back to main loop and change flag_insuff to 0
            call print_list           ; printing the node and free the place on heap of it
            call free_memory_node
            jmp main_loop
            change_flag_insuff_tozero:
            mov dword [flag_insuff], 0          
            jmp main_loop 
            
            duplicate:
            call my_peek                       ; put in head the adress of the list to duplicate
            call my_duplicate
            
            jmp main_loop                      ; after finish duplicate go back to main loop
            
            power:
            begin_power                        ; call to the macro that check if there are insuff operands in stack and if y is valid
            
            mov [head], eax                    ; put in head X for duplicate it
            push eax                           ; backup eax before duplicate
            push ebx                           ; backup ebx before duplicate
            call my_duplicate                  ; duplicate X (which is not in stack now) , for put it in the top of the stack
            pop ebx                            ; restore ebx - Y
            pop eax                            ; restore eax - X
        
            call my_power                      ; if not , Y is valid and continue with ^ operation
            
            ; free_X_Y
            mov dword [head], eax              ; put in head X for free 
	    call free_memory_node              ;
	    mov dword [head], ebx              ; put in head Y for free
	    call free_memory_node              ; 
            
            jmp main_loop
            
            power_fruction:
            begin_power
            
            mov [head], eax                    ; put in head X for duplicate it
            push eax                           ; backup eax before duplicate
            push ebx                           ; backup ebx before duplicate
            call my_duplicate                  ; duplicate X (which is not in stack now) , for put it in the top of the stack
            pop ebx                            ; restore ebx - Y
            pop eax                            ; restore eax - X
            
            call my_peek                       ; put in head X that in the stack
            call my_division
            
            ; free_X_Y
            mov dword [head], eax              ; put in head X for free 
	    call free_memory_node              ;
	    mov dword [head], ebx              ; put in head Y for free
	    call free_memory_node              ; 
            
            jmp main_loop
            
            number_of_ones:
            call my_pop                        ;
            mov eax, [head]                    ; put in eax the adress of the list of the number we want to count ones
            mov ecx, [head]                    ; put in ecx the adress of the list of the number we want to count ones
            ones_loop:
            mov edx, 0
            mov dl, byte [eax]                 ; put in edx the data of the node
            count_ones_in_node                 ; call macro which count num of ones in node (loop of 4 times), and keep result in [num_of_ones]
            inc eax                            ; put eax to point on the adress of the next node
            cmp dword [eax], 0                 ; to check if its the last node
            jz end_ones_loop                   ; if there is no other nodes , go out from the loop for push the result
            mov eax, [eax]                     ; if there is more nodes , put eax to point the adress of the next node
            jmp ones_loop                      ; go back to ones_loop, when eax point the next node
            
            end_ones_loop:
            call push_decimal
            mov dword [num_of_ones], 0         ; put 0 in counter for next operation 'n'
            mov dword [head], ecx              ; put ecx in head for free 
	    call free_memory_node              ;
            
            jmp main_loop
	    
            call_my_push:
            call my_push
            jmp main_loop

        end_myCalc:
	popad			
	mov esp, ebp	
	pop ebp
	ret
        
; push to the next node number (arg of the func) in the top linked list in stack 
my_push_next_node:

        push ebp
        mov ebp, esp	
        pushad
        pushfd
        
        mov ecx, [ebp+8]        ; puts in ecx the num to enter to the new node
        
        mov dword ebx, [last_node]    ; keep the pointer of the last node of the first num in stack
            
        malloc_next_node:
            mov edx, 5          ; argument for malloc - every node size is 5
            push ecx            ; backup register before malloc
            push ebx            ; backup register before malloc
            push edx            ; the argument for calling malloc - size for allocating
            call malloc         ;
            add esp, 4          ; "make pop" for the argument of malloc 
            pop ebx             ; restore after malloc
            pop ecx             ; restore after malloc
            mov [ebx],eax       ; move the return value from malloc (pointer to the new node) to the first place of the list
            mov [eax], ecx      ; enter the digit of the input to the node in the linked list
            inc eax             ; mov eax to point the place to put the next node address
            mov dword [last_node], eax
            mov ebx, eax        ; enter ebx the adress that we want to enter the next pointer
            
            mov dword edx, 0          ; for enter 0 in the last in node pointer in the list
            mov dword [ebx], edx ; move the 0
           
        popfd
        popad			
	mov esp, ebp	
	pop ebp
	ret        
        
; push new list to the top of the stack with one node
my_push_new_list:

        push ebp
        mov ebp, esp	
        pushad
        pushfd
        
        mov ecx, [ebp+8]       ; puts in ecx the num to enter to the new node

        cmp dword [curr], 5    ; check if we have reached to max size of stack
        jz ErrorOverflow1
        
        
        mov eax, [curr]    ; keep the index in eax
        mov ebx, stack     ; put in ebx the 
        curr_adress_loop_1:  ; loop for finding the adress of the next empty place in stack
        cmp eax, 0         ; check if eax is 0 
        jz malloc_first_node      
        add ebx, 4         ; move ebx to point the next cell in the stack
        dec eax            ; decrease eax for lekadem the loop
        jmp curr_adress_loop_1
            
        malloc_first_node:
            mov edx, 5          ; argument for malloc - every node size is 5
            push ecx            ; backup register before malloc
            push ebx            ; backup register before malloc
            push edx            ; the argument for calling malloc - size for allocating
            call malloc         ;
            add esp, 4          ; "make pop" for the argument of malloc 
            pop ebx             ; restore after malloc
            pop ecx             ; restore after malloc
            mov [ebx],eax       ; move the return value from malloc (pointer to the new node) to the first place of the list
            mov [eax], ecx      ; enter the 2 digits of the input to the node in the linked list
            inc eax
            mov dword [last_node], eax
            mov ebx, eax        ; enter ebx the adress that we want to enter the next pointer

            
            mov edx, [curr]     ; move the stack index to register for increment
            inc edx             ; increace the index +1
            mov [curr], edx
            
            mov edx, 0          ; for enter 0 in the last in node pointer in the list
            mov dword [ebx], edx ; move the 0
        
            jmp end_push1
            

        ErrorOverflow1:
        push overflow          ; push seconed argument for printf
        call printf            ; print overflow error string
	add esp,4              ; "make pop" for the printf arguments
        
        end_push1:
        popfd
        popad			
	mov esp, ebp	
	pop ebp
	ret
    
; when counting num_of_ones we count it in decimal so we want to convert it to hexa num and push it to stack 
push_decimal:

        push ebp
        mov ebp, esp	
        pushad
        
        mov eax, [num_of_ones] ; put in eax the num of ones
        mov ebx,16             ; put divisor in ebx , for convert the decimal counter to hexa
        div ebx                ; put in eax the division and in edx the sheerit
        push edx               ; arguemnt for my_push_new_list
        call my_push_new_list  ;
        add esp, 4             ; pop the arguemnt
        push_decimal_loop:
        mov edx, 0
        cmp eax, 0             ; check if we num_of_ones was divied until it made 0
        jz end_decimal         ; if yes , jump to end_decimal
        mov ebx, 16            ; divisor
        div ebx                ; put in eax the division and in edx the sheerit
        push edx               ; argument for my_push_next_node
        call my_push_next_node ;
        add esp, 4             ; pop the arguemnt
        jmp push_decimal_loop  ; 
        
        print_debug

        end_decimal:
        popad			
	mov esp, ebp	
	pop ebp
	ret

; push input (num that the user entered) in top of the stack
my_push:

        push ebp
        mov ebp, esp	
        pushad	

        cmp dword [curr], 5    ; check if we have reached to max size of stack
        jz ErrorOverflow
        
        mov ecx, input         ; move the input pointer to ecx for moving right and reach the LSB
        
        LSB_loop:              ; count the length of the number and change the pointer ecx to the lsb
            cmp byte [ecx], 0  ; check if we see null termination
            jz initializeList  ; if null termination , out from the loop
            inc ecx            ; move right on the number
            jmp LSB_loop       ; if not null termination , go back to the start of the loop
            
        initializeList:
            mov eax, [curr]    ; keep the index in eax
            mov ebx, stack     ; put in ebx the 
            curr_adress_loop:  ; loop for finding the adress of the next empty place in stack
            cmp eax, 0         ; check if eax is 0 
            jz malloc_loop      
            add ebx, 4         ; move ebx to point the next cell in the stack
            dec eax            ; decrease eax for lekadem the loop
            jmp curr_adress_loop
            
        malloc_loop:
            dec ecx             ; move the pointer on the input right 
            mov edx, 5          ; argument for malloc - every node size is 5
            push ecx            ; backup register before malloc
            push ebx            ; backup register before malloc
            push edx            ; the argument for calling malloc - size for allocating
            call malloc         ;
            add esp, 4          ; "make pop" for the argument of malloc 
            pop ebx             ; restore after malloc
            pop ecx             ; restore after malloc
            mov [ebx],eax       ; move the return value from malloc (pointer to the new node) to the previus place in the linked list
            mov edx, 0
            mov dl,byte [ecx]   ; move 1 byte of data to edx
            cmp edx, 64         ; to check if its number or letter
            jg big_letter       ; jump if greater then 64 = 'A' - 1
            sub edx, 48         ; if it is number
            jmp continue
            big_letter:
            sub edx, 55         ; if its is letter
            continue:
            mov [eax], edx      ; enter the 2 digits of the input to the node in the linked list
            inc eax
            mov ebx, eax        ; enter ebx the adress that we want to enter the next pointer
            cmp ecx, input     ; to check if we reached to the msb of the input
            jnz malloc_loop     ; if not , go back to the loop
            
            mov edx, [curr]     ; move the stack index to register for increment
            inc edx             ; increace the index +1
            mov [curr], edx
            
            mov edx, 0          ; for enter 0 in the last in node pointer in the list
            mov dword [ebx], edx ; move the 0
            jmp end_push
            

        ErrorOverflow:
        push overflow          ; push seconed argument for printf
        call printf            ; print overflow error string
	add esp,4              ; "make pop" for the printf arguments
	
        
        end_push:
        print_debug
        popad			
	mov esp, ebp	
	pop ebp
	ret

; put the top operand in stack to [head] and decreace curr by one
my_pop:

        push ebp
        mov ebp, esp	
        pushad
        
        check_insuff 1                ; check if there is operand to pop 
        cmp dword [flag_insuff], 1    ; check what the result from the check
        jz end_pop                    ; if insuff flag is 1 going to end pop
        
        dec ecx                       ; put in ecx the current index where to pop
        mov edx, [stack+ecx*4]        ; put in edx the adress of the first node in the list
        mov [head], edx               ; keep the pointer of the head of the list for free the memory in the end

        ; move the stack index to the next node 
        mov edx, [curr]               ; move the stack index to register for decrement
        dec edx                       ; decreace the index -1 , and in the next push it will run over the list we wanted to pop
        mov [curr], edx               ; put the decreaced index back in curr
        
        end_pop:
        popad			
	mov esp, ebp	
	pop ebp
	ret

; print the [head] (what we poped) and free the memory alocated of his linked list
print_list:

        push ebp
        mov ebp, esp	
        pushad
        
        mov eax, 0                    ; counter how much bytes we will push in the assembly stack for pop them in the print num loop
        mov edx, [head]               ; put in edx the pointer to the node we nead to print

        push_list_loop:               ; loop for push every node 1 byte data to assembly stack
        mov ebx, 0                    ; enter zeroes in ebx for storing the data
        mov bl,byte [edx]             ; move 1 byte of data to ebx
        push ebx                      ; push the data to assembly stack
        inc eax                       ; increace the counter by 1
        inc edx                       ; put in edx the pointer of the current node to the next node in the list 
        cmp dword [edx] , 0           ; check if the adress of next node is 0 , which mean there is no another node
        jz print_num_loop                ; if yes , there is no more nodes so go out of the loop
        mov edx,[edx]                 ; put in edx the adress of the next node
        jmp push_list_loop            ; if not, go back to the loop
        
        print_num_loop:               ; loop for printing the number in the right order
	cmp eax, 0                    ; if eax=0 so we dont have more characters to print and we want to print \n
	jz print_linedown
	pop ebx                       ; poping data of the node that we pushed in push_list_loop
	push eax		      ; backup register before printf
	push ebx		      ; push the data of the node arg for printf
	push str4                     ; push format string argument for printf
        call printf 
        add esp,8                     ; "make pop" for the printf arguments
	pop eax                       ; restore after printf
	dec eax			      ; we have in eax the num of characters we pushed so we decreasing it every time we print the node
	jmp print_num_loop            ; if we arrived here we need to continue with the loop

	print_linedown:               ; print \n
	push line_down                ; format \n
	call printf      
	add esp, 4                    ; "make pop" for the printf arguments
        
        popad			
	mov esp, ebp	
	pop ebp
	ret
	
; free the [head] (what we poped) 
free_memory_node:
        
        push ebp
        mov ebp, esp	
        pushad

        mov ebx, [head]               ; keep the adress of the head of the list in ebx
        mov edx, [head]               ; will keep the adress of the next node
        
        free_memory_loop:
        inc edx                       ; keep in edx the adress for the next node
        cmp dword [edx], 0            ; check if the adress of next node is 0 , which mean there is no another node
        jz end_free                   ; if it was the last node , jump to end pop
        mov edx,[edx]                 ; put in edx the adress of the next node
        push edx                      ; backup edx before free
        push ebx                      ; push the argument for free - the adress of the node to free
        call free                     ; free the current node memory allocated in malloc
        add esp, 4                    ; "make pop" for the argument of free 
        pop edx                       ; restore edx after free
        mov ebx, edx                  ; put in ebx the adress of the next node
        jmp free_memory_loop          ; continue the loop with the next node , which her address now stored in ebx

        end_free:
        ;remove the last node 
        push ebx                      ; push the argument for free - the adress of the node to free 
        call free
        add esp,4                     ; "make pop" for the argument of free
        popad			
	mov esp, ebp	
	pop ebp
	ret

; put in [head] the top operand in stack
my_peek:

        push ebp
        mov ebp, esp	
        pushad
        
        mov ecx, [curr]
        dec ecx                       ; put in ecx the current index where to pop
        mov edx, [stack+ecx*4]        ; put in edx the adress of the first node in the list
        mov [head], edx               ; keep the pointer of the head of the list for free the memory in the end
        
        popad			
	mov esp, ebp	
	pop ebp
	ret

; adds two numbers (args of the function) byte by byte
my_addition:

        push ebp
        mov ebp, esp	
        pushad
        
        mov edx, [ebp+8]                    ; puts in edx the pointer for first num for addition 
        mov ecx, [ebp+12]                   ; puts in ecx the pointer for second num for addition
        
        mov ebx, 0                          ; move zeroes to the registers for enter the nums
        mov eax, 0 
        mov bl, byte [edx]                  ; mov the data of the first node in the first num to ebx
        mov al, byte [ecx]                  ; mov the data of the first node in the second num to eax
        add ebx, eax                        ; adds the two datas
        cmp ebx, 15                         ; compare between bl and F=15 for know if there is carry
        jna make_new_list                   ; jna = jmp not above
        mov dword [carry_of_add], 1         ; if there is carry so we put in carry_of_add 1
        sub ebx, 16                         ; if there is a carry sub from the result 16 (base 16)
        
        make_new_list:
        push ebx                            ; argument for my_push_new_list
        call my_push_new_list               ; create new list in the stack and push the first char 
        add esp, 4                          ; pop the argument for my_push_new_list
        inc edx                             ; make edx to point the adress of the next node to check if its the last one
        cmp dword [edx], 0                  ; check if the adress is zeroes (last node)
        jz change_num1_1                    ; if yes , change the flag of num1 to 1
        mov edx, [edx]                      ; move edx to point to next node
        jmp move_num2_2                     ;
        change_num1_1:                      ;
        mov dword [end_num1], 1             ; change the flag of num1 to 1
        dec edx                             ; make edx to point back to the data
        move_num2_2:                        ;
        inc ecx                             ; make ecx to point the adress of the next node to check if its the last one
        cmp dword [ecx], 0                  ; check if the adress is zeroes (last node)
        jz change_num2_2                    ; if yes , change the flag of num1 to 1
        mov ecx, [ecx]                      ; move ecx to point to next node
        jmp addition_loop
        change_num2_2:
        mov dword [end_num2], 1             ; change the flag of num2 to 1
        dec ecx                             ; make ecx to point back to the data
        
        
        addition_loop:
        mov ebx, 0                          ; move zeroes to the registers for enter the nums
        mov eax, 0                          ; move zeroes to the registers for enter the nums
        cmp dword [end_num1], 1             ; check if we have reached to the end of the first num linked list
        jz  end_of_first_num                ; if yes , jump the end_of_first_num case
        cmp dword [end_num2], 1             ; check if we have reached to the end of the second num linked list- thats happen if we didnt arrived to the end of the first num
        jz end_of_second_num                ; jump the end_of_seconed_num case
        
        mov bl, byte [edx]                  ; mov the data of the current node in the first num to eax
        cmp dword [carry_of_add], 1         ; check if we have carry 
        jnz add_second_num                  ; if not , we dont increace ebx
        inc ebx                             ; adds the carry
        add_second_num:
        mov al, byte [ecx]                  ; mov the data of the current node in the second num to ebx
        add ebx, eax                        ; adds the two datas
        jmp end_cases_nums                  ; skip the others cases and jump to end_cases_nums
        
        end_of_first_num:  
        cmp dword [end_num2], 1             ; check if we have reached to the end of the second num linked list
        jz check_carry                      ; if yes , end the loop 
        mov bl, byte [ecx]                  ; mov the data of the current node in the second num to eax
        cmp dword [carry_of_add], 1         ; check if there is carry
        jnz end_cases_nums                  ; if not , we dont increace ebx , and jump the end_cases_nums
        inc ebx                             ; adds the carry
        jmp end_cases_nums                  ; skip the others cases and jump to end_cases_nums
        
        end_of_second_num:
        mov bl, byte [edx]                 ; mov the data of the current node in the second num to eax
        cmp dword [carry_of_add], 1        ; check if there is carry
        jnz end_cases_nums                 ; if not , dont increace ebx , and jump the end_cases_nums
        inc ebx                            ; adds the carry
        
        
        end_cases_nums:
        cmp ebx, 15                         ; compare between bl and F=15 for know if there is carry
        jna not_carry                       ; jna = jmp not above
        mov dword [carry_of_add], 1         ; if there is carry so we put in carry_of_add 1
        sub ebx, 16                         ; if there is a carry sub from the result 16 (base 16)
        jmp push_next_node                  ; skip the not_carry and jump
        not_carry:
        mov dword [carry_of_add], 0         ; there is no carry , so change it to 0
        push_next_node:                     ; 
        push ebx                            ; push the argument for my_push_next_node
        call my_push_next_node              ;
        add esp, 4                          ; pop the argument for my_push_next_node
        
        move_num1:
        inc edx                             ; increace edx to point to the address of the next node 
        cmp dword [edx], 0                  ; check if we have reached to the end of the first num linked list
        jz change_num1                      ; if yes , change the end_num1 flag
        mov edx, [edx]                      ; move edx to point to next node
        jmp move_num2                       ;

        
        change_num1:
        mov dword [end_num1], 1             ; change the end_num1 flag
        dec edx                             ; make edx to point back to the data
        
        move_num2:
        inc ecx                             ; increace ecx to point to the address of the next node
        cmp dword [ecx], 0                  ; check if we have reached to the end of the second num linked list
        jz change_num2                      ; if yes , change the end_num2 flag
        mov ecx, [ecx]                      ; move ecx to point to next node
        jmp addition_loop                   ;
        
        change_num2:
        mov dword [end_num2], 1             ; change the end_num2 flag
        dec ecx                             ; make ecx to point back to the data
        
        jmp addition_loop                   ; end of loop :)
        
        
        check_carry:                        ;
        cmp dword [carry_of_add], 1         ; check if there is carry (outside the loop)
        jnz end_add                         ; if not , finish
        mov ebx, 1                          ; if yes , put in ebx 1 
        push ebx                            ; argument for the my_push_next_node
        call my_push_next_node              ; 
        add esp, 4                          ; pop the argument
        
        
        end_add:
        print_debug
        mov dword [end_num1], 0             ; put 0 in the flags for the next addition
        mov dword [end_num2], 0             ; put 0 in the flags for the next addition
        mov dword [carry_of_add], 0         ; put 0 in the flags for the next addition
        popad			
	mov esp, ebp	
	pop ebp
	ret
	
; duplicate the [head] and push it to the top of the stack        
my_duplicate:

        push ebp
        mov ebp, esp	
        pushad
        
        mov edx, [head]                     ; put in edx the adress of list that we want to duplicate
        mov bl, byte [edx]                  ; put the data of the first node in ebx
        push edx                            ; backup edx before my_push_new_list 
        push ebx                            ; argument for my_push_new_list
        call my_push_new_list               ; create the duplicate list in the next empty cell in the stack , and put the first data byte 
        add esp, 4                          ; pop the argument
        pop edx                             ; restore edx
        inc edx                             ; make edx to point the adress of the next node to check if its the last one
        cmp dword [edx], 0                  ; check if the adress is zeroes (last node)
        jz end_dup                          ; if there was only 1 node , go back to main loop
        
        dup_loop:                           ; if there is more than 1 node to duplicate
        mov edx, [edx]                      ; put in edx the adress of the next node
        mov bl, byte [edx]                  ; put in ebx the data
        push edx                            ; backup edx before my_push_next_node                            
        push ebx                            ; argument for my_push_next_node (the data)
        call my_push_next_node              ; create new node and put the data in it , and connect the new node to the duplicated list
        add esp, 4                          ; pop the arguemnt
        pop edx                             ; restore edx
        inc edx                             ; make edx to point the adress of the next node to check if its the last one
        cmp dword [edx], 0                  ; check if the adress is zeroes (last node)
        jnz dup_loop                        ; if its not the last node, go again to dup_loop and continue to the next ndoe
        
        end_dup:
        print_debug
        popad			
	mov esp, ebp	
	pop ebp
	ret
	
; change Y from list to number in [Y]
list_to_num:
       
        push ebp
        mov ebp, esp	
        pushad
            
        mov ecx, [head]                      ; puts in ecx the pointer to Y
        mov ebx, 0                           ; put zeroes in ebx for put there the value of Y
        calc_list:
        mov edx,0
        mov dl, byte [ecx]                   ; put in edx the data of the first node
        add ebx, edx                         ; add to ebx the data * 16^0
        second_add:
        inc ecx                              ; put in ecx the adress of the next node
        cmp dword [ecx], 0                   ; check if there is next node
        jz put_num                           ; if not , jump to put num
        mov ecx, [ecx]                       ; if yes, move ecx to point the next node
        push ebx                             ; backup ebx before mult
        mov dl, byte [ecx]                   ; put in edx the data of the seconed node (for mult)
        mov eax, 16                          ; put in eax 16^1 
        mul edx                              ; mult 16*data and put the reslut in eax
        pop ebx                              ; restore ebx 
        add ebx, eax                         ; put the result (in eax or edx) and put in ebx
        inc ecx                              ; put in ecx the adress of the next node
        cmp dword [ecx], 0                   ; check if there is another node
        jnz wrong_Y_error                    ; if yes , Y is bigger than C8 = 200 , error
        
        cmp ebx, 200                         ; there is only 2 nodes , check if bigger than 200
        jna put_num                          ; if not , jmp to put_num
        
        wrong_Y_error:                       ; go here if Y > 200 , or if there are more than 2 nodes
        mov dword [valid_Y], 1               ; change flag to one for notice that the error was printed
        push Y_error                         ; push seconed argument for printf
        call printf                          ; print Y_error string
        add esp, 4                           ; "make pop" for the printf arguments
        jmp end_num
        
        put_num:
        mov dword [Y], ebx                   ; put ebx in Y
        
        end_num:
        popad			
        mov esp, ebp	
        pop ebp
        ret

; calculate X*2^Y and push it to the stack by duplicate X and add it to itself Y times
my_power:

        push ebp
        mov ebp, esp	
        pushad
        
        mov dword ecx, [Y]           ; put Y in ecx , will be the counter for make the loop Y times
        cmp ecx, 0
        jz end_my_power
        
        power_loop:                  ; 
        call my_peek                 ; put in head the first operand in stack
        call my_duplicate            ; duplicate the first operand in stack , so we can add them
        call my_pop                  ; pop the duplicated operand
        mov eax, [head]              ; put the duplicated operand in eax
        call my_pop                  ; pop the original operand
        mov ebx, [head]              ; put the original operand in ebx
        push eax                     ; push poped num for seconed arg to my_addition
        push ebx                     ; push peeked num for first arg to my_addition
        call my_addition             ; add the original operand and his duplication, and put result in top of the stack (this will happen Y times)
        add esp, 8                   ; pop the arguemnts
        mov dword [head], eax        ; put in head the duplicated operand for free it
        call free_memory_node        ; free 
        mov dword [head], ebx        ; put in head the original operand for free it
        call free_memory_node        ; free
        dec ecx                      ; decrement ecx
        cmp ecx,0                    ; check if the counter is 0 - the loop was done Y times
        jnz power_loop               ; if not , go back to power_loop
        
        end_my_power:
        print_debug
        popad			
        mov esp, ebp	
        pop ebp
        ret

; calculate X*2^-Y buy do shift right to every node in X, Y times
my_division:

        push ebp
        mov ebp, esp	
        pushad
        
        mov dword ecx, [Y]           ; put Y in ecx, will be the counter for make the loop Y times
        cmp ecx, 0
        jz end_my_power
        
        
        division_loop:
        mov dword edx, [head]        ; put the head of X in edx
        cmp ecx, 0                   ; check if we have done the loop Y times
        jz end_my_division           ; if yes, finish loop
        mov dword [is_first_node],1  ; put 1 before start the loop moving on the list
        
        div_by_2_loop:
        mov ebx, 0
        mov bl, byte [edx]           ; move data of the node to ebx
        shr bl, 1                    ; divied the data by 2
        mov byte [edx], bl           ; move data after shr to the list (X)
        adc bh, 0                    ; put the carry in bh
        shl bh, 3                    ; make the carry to 8
        cmp dword [is_first_node], 1 ; check if this is first node (if yes dont add carry to the last node)
        jz continue_div
        push ecx                     ; backup ecx, because we want to keep in it temporary the data of the last node for add the carry
        mov cl, byte [eax]           ; move last node data to cl
        add cl, bh                   ; add the carry to the last node
        mov byte [eax], cl           ; move data after add carry to the list
        pop ecx                      ; restore ecx = [Y]
        
        continue_div:
        inc edx                      ; put in edx to point the adress of the next node
        cmp dword [edx], 0           ; check if its the last node
        jnz move_next_node           ; if not, go to move_next_node
        cmp bl, 0                    ; if the data of the last node is 0
        jnz end_div_by_2             ; go out div_by_2_loop
        cmp dword [is_first_node], 1 ; check if this is first node (if yes dont remove the node)
        jz end_my_division           ; if its the last node , but also the first and data is 0 , finish
        ; if we have got here we want to remove the node
        inc eax                      ; put eax to point the adress of the current node
        mov dword [eax], 0           ; put 0 in the adress of the next node
        dec edx                      ; put edx back to point the data of the current node
        mov dword [head],edx         ; free memory node use [head] , so we put edx (the node we want to delete)  in [head] 
        call free_memory_node        ; delete the last node
        call my_peek                 ; put X in [head] , because we change [head] for free 2 line above
        jmp end_div_by_2             ; if we here its case that we are the last node , but not the first so we want to dec Y and do div_by_2_loop again
        
        move_next_node:
        dec edx                      ; put edx to point the data of the current node
        mov eax, edx                 ; save the address of the curr node in eax for use it as the last node un the next iteration
        inc edx                      ; put edx to point to the address of the next node
        mov edx, [edx]               ; put in edx the address of the next node
        cmp dword [is_first_node], 1 ; check if this was the first node, if yes we want to change the flag 
        jnz div_by_2_loop
        ; change_is_first_node
        mov dword [is_first_node], 0 ; change the flag that its will sign that we are not at first node in next iteration
        jmp div_by_2_loop
        
        
        end_div_by_2:
        
        dec ecx                      ; lekadem the loop, decreace Y by 1
        jmp division_loop            ; 
        
        
        end_my_division:
        print_debug
        popad			
        mov esp, ebp	
        pop ebp
        ret
