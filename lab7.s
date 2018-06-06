	AREA interrupts, CODE, READWRITE
	EXPORT lab7
	EXPORT FIQ_Handler
	EXPORT pin_connect_block_setup_for_uart0
	EXPORT interrupt_init
	EXPORT display_digit_on_7_seg
	EXPORT illuminateLEDs
	EXPORT illuminate_RGB_LED
	EXPORT output_string
	EXPORT output_character
	EXPORT update_score	
	EXPORT read_character
	EXPORT start_timers
	EXPORT update_level
	EXPORT read_string
	EXPORT stop_timers

	EXTERN decTime
	EXTERN printBoard
	EXTERN movePlayer
	EXTERN updateBoard
	EXTERN moveMother
	EXTERN generateMother
	EXTERN generatePlayerShot
	EXTERN moveShot
	EXTERN generateEnemyShot
	GET library7.s
enemyTimerFin = 5		
	ALIGN
currentEnemyTimer = 0
	ALIGN
mShipTimerEnd = 1
	ALIGN
mShipCurrent = 0
	ALIGN
currentGameTimer = 0
	ALIGN
onoffFlag = 1
	ALIGN
prompt = "Enter a 4 digit hexadecimal number. Press the interrupt button to pause the program, press q to exit",0
	ALIGN
seg_clear = "!!!!",0
	ALIGN
endpr = "Program ended",0	
	ALIGN
tempStorage = "1111",0	
	ALIGN
charBuf = " ",0
	ALIGN		
lab7	
	;Load initial values
	STMFD sp!, {lr}			;Store Link reg
	LDR r4,=input			;Load input
	LDR r3,=tailLoc			;Load tail location
	STR r4,[r3]				;Store input to tail location
	
EXIT
	;Load exit prompt and leave program
	LDR r4,=endpr			;Load exit prompt
	BL output_string		;Display output prompt
	LDMFD sp!, {lr}			;Load link reg
	BX lr					;Go back to whence you came
	
update_level
	STMFD sp!, {lr}
	LDR r1,=enemyTimerFin
	LDR r0,[r1]
	SUB r0,r0,#5
	STR r0,[r1]
	LDMFD sp!, {lr}
	BX lr
	
update_score
	STMFD sp!, {lr}
	LDR r3,[r0]
	LDR r4,=input
	STR r3,[r4]
	LDMFD sp!, {lr}
	BX lr
start_timers
	STMFD sp!, {r0-r1,lr}
	LDR r0,=0xE0004004
	LDR r1,[r0]
	ORR r1,r1,#1
	STR r1,[r0]
	LDR r0,=0xE0008004
	LDR r1,[r0]
	ORR r1,r1,#1
	STR r1,[r0]
	;UART Setup
	LDR r0,=0xE000c004
	LDR r1, [r0]
	ORR r1,r1,#1
	STR r1, [r0]
	LDMFD sp!, {r0-r1,lr}
	BX lr
stop_timers
	STMFD sp!, {r0-r1,lr}
	LDR r0,=0xE0004004
	LDR r1,[r0]
	BIC r1,r1,#1
	STR r1,[r0]
	LDR r0,=0xE0008004
	LDR r1,[r0]
	BIC r1,r1,#1
	STR r1,[r0]
	;UART Setup
	LDR r0,=0xE000c004
	LDR r1, [r0]
	BIC r1,r1,#1
	STR r1, [r0]
	LDMFD sp!, {r0-r1,lr}
	BX lr
handle_Char
	STMFD sp!, {lr}
	LDR r3,=charBuf
	LDRB r0,[r3]
	CMP r0,#119
	BEQ shoot
	CMP r0,#87
	BEQ shoot 
	CMP r0,#97
	BEQ move_player
	CMP r0,#65
	BEQ move_player
	CMP r0,#100
	BEQ move_player
	CMP r0,#68
	BEQ move_player
	
	LDR r0,=charBuf
	MOV r1,#32
	STRB r1,[r0]
	LDMFD sp!, {lr}
	BX lr
interrupt_init       
	STMFD SP!, {r0-r1, lr}   ; Save registers 
		
	;Push button setup		 
	LDR r0, =0xE002C000
	LDR r1, [r0]
	ORR r1, r1, #0x20000000
	BIC r1, r1, #0x10000000
	STR r1, [r0]  ; PINSEL0 bits 29:28 = 10
	
	;timer0 setup
	LDR r0,=0xE0004014
	LDR r1,[r0]
	ORR r1,r1,#24
	BIC r1,r1,#7
	STR r1,[r0]
	
	;timer1 setup
	LDR r0,=0xE0008014
	LDR r1,[r0]
	ORR r1,r1,#24
	BIC r1,r1,#7
	STR r1,[r0]
	
	;Set up timer0 to run at 
	LDR r0,=0xE000401C
	LDR r1,=4608000
	STR r1,[r0]
	;LDR r0,=0xE0004004
	;LDR r1,[r0]
	;ORR r1,r1,#1
	;STR r1,[r0]
	
	;Set up timer1 to run at 500Hz
	LDR r0,=0xE000801C
	LDR r1,=18432
	STR r1,[r0]
	;LDR r0,=0xE0008004
	;LDR r1,[r0]
	;ORR r1,r1,#1
	;STR r1,[r0]
	
	; Classify sources as IRQ or FIQ
	LDR r0, =0xFFFFF000
	LDR r1, [r0, #0xC]
	LDR r2, =0x8070
	ORR r1, r1, r2 ; External Interrupt 1, UART 0, & Timer 0
	STR r1, [r0, #0xC]

	; Enable Interrupts
	LDR r0, =0xFFFFF000
	LDR r1, [r0, #0x10]
	LDR r2, =0x8070	
	ORR r1, r1, r2 ; External Interrupt 1
	STR r1, [r0, #0x10]

	; External Interrupt 1 setup for edge sensitive
	LDR r0, =0xE01FC148
	LDR r1, [r0]
	ORR r1, r1, #2  ; EINT1 = Edge Sensitive
	STR r1, [r0]

	; Enable FIQ's, Disable IRQ's
	MRS r0, CPSR
	BIC r0, r0, #0x40
	ORR r0, r0, #0x80
	MSR CPSR_c, r0

	LDMFD SP!, {r0-r1, lr} ; Restore registers
	BX lr             	   ; Return


FIQ_Handler
	STMFD SP!, {r0-r12, lr}   ; Save registers 


UARTINT0
	;Check for UART interrupt
	LDR r0,=0xE000C008		
	LDR r1, [r0]			
	TST r1,#1
	BNE TIMERINT0
	
	;Read string and check flag status
	BL read_character			;Read string
	LDR r3,=charBuf
	STRB r0,[r3]
	;If value is q, exit program
	B FIQ_Exit				;Goto interrupt exit
shoot
	LDR r1,=generatePlayerShot
	MOV lr,pc
	BX r1
	LDR r0,=charBuf
	MOV r1,#32
	STRB r1,[r0]
	LDMFD sp!, {lr}
	BX lr
move_player
	LDR r1,=movePlayer
	MOV lr,pc
	BX r1
	LDR r0,=charBuf
	MOV r1,#32
	STRB r1,[r0]
	LDMFD sp!, {lr}
	BX lr
	
TIMERINT0
	;Check for timer interrupt
	LDR r0, =0xE0004000 
	LDR r1, [r0]
	TST r1,#2
	BEQ TIMERINT1
	
	LDR r0,=enemyTimerFin
	LDR r0,[r0]
	LDR r1,=currentEnemyTimer
	LDR r1,[r1]
	CMP r0,r1
	BEQ doUpdateBoard
	ADD r0,r1,#1
	LDR r1,=currentEnemyTimer
	STRB r0,[r1]
	
	LDR r0,=mShipTimerEnd
	LDR r0,[r0]
	LDR r1,=mShipCurrent
	LDR r1,[r1]
	CMP r0,r1
	BEQ doMoveMShip
	ADD r0,r1,#1
	LDR r1,=mShipCurrent
	STRB r0,[r1]
	B timer0_cont
doMoveMShip
	MOV r0,#0
	LDR r1,=mShipCurrent
	STRB r0,[r1]
	LDR r1,=moveMother
	MOV lr,pc
	BX r1	
	B timer0_cont
doUpdateBoard
	MOV r0,#0
	LDR r1,=currentEnemyTimer
	STRB r0,[r1]
	LDR r1,=updateBoard
	MOV lr,pc
	BX r1
	B timer0_cont
	
timer0_cont	
	LDR r1,=generateMother
	MOV lr,pc
	BX r1
	
	LDR r1,=generateEnemyShot
	MOV lr,pc
	BX r1
	
	BL handle_Char
	
	LDR r1,=moveShot
	MOV lr,pc
	BX r1
	
	LDR r1,=printBoard
	MOV lr,pc
	BX r1
timer0_exit
	;Clear interrupt
	LDR r0,=0xE0004000			
	LDR r1, [r0]
	ORR r1,r1,#2
	BIC r1,r1,#1
	STR r1,[r0]
	B FIQ_Exit
	
TIMERINT1
	;Check for timer interrupt
	LDR r0, =0xE0008000 
	LDR r1, [r0]
	TST r1,#2
	BEQ EINT1
		
	LDR r4,=input
	BL display_digit_on_7_seg
		
	LDR r0,= 825
	LDR r1,=currentGameTimer
	LDR r1,[r1]
	CMP r0,r1
	BEQ doCountTo1
	ADD r0,r1,#1
	LDR r1,=currentGameTimer
	STRH r0,[r1]
	B timer1_exit
doCountTo1
	MOV r0,#0
	LDR r1,=currentGameTimer
	STRH r0,[r1]
	LDR r1,=decTime
	MOV lr,pc
	BX r1	
timer1_exit
	;Clear interrupt
	LDR r0,=0xE0008000			
	LDR r1, [r0]
	ORR r1,r1,#2
	BIC r1,r1,#1
	STR r1,[r0]
	B FIQ_Exit	
EINT1		
	; Check for EINT1 interrupt
	LDR r0, =0xE01FC140
	LDR r1, [r0]
	TST r1, #2
	BEQ FIQ_Exit
	
	;Check flag status	
	LDR r3,=onoffFlag		;Load flag loc
	LDRB r12,[r3]			;Load flag
	CMP r12,#1				;Is flag 1?
	BEQ set_flag			;If so, goto set_flag
	
	;Reenable digit display with previous value
	MOV r12,#1				;Else, set reg to 1
	STR r12,[r3]
	
	LDR r0,=0xE0004004
	LDR r1,[r0]
	ORR r1,r1,#1
	STR r1,[r0]
	LDR r0,=0xE0008004
	LDR r1,[r0]
	ORR r1,r1,#1
	STR r1,[r0]

	MOV r0,#103
	BL illuminate_RGB_LED;
	; Clear Interrupt
	LDR r0, =0xE01FC140
	LDR r1, [r0]
	ORR r1, r1, #2		
	STR r1, [r0]
	B FIQ_Exit
	
set_flag
	;Store input and clear display
	MOV r12,#0			;Set reg to 0
	STRB r12,[r3]		;Store to flag
	
	LDR r0,=0xE0004004
	LDR r1,[r0]
	BIC r1,r1,#1
	STR r1,[r0]
	LDR r0,=0xE0008004
	LDR r1,[r0]
	BIC r1,r1,#1
	STR r1,[r0]
	
	MOV r0,#98
	BL illuminate_RGB_LED;
	; Clear Interrupt	
	LDR r0, =0xE01FC140
	LDR r1, [r0]
	ORR r1, r1, #2		
	STR r1, [r0]	
FIQ_Exit
	;Reload registers and exit interrupt mode
	LDMFD SP!, {r0-r12, lr}
	SUBS pc, lr, #4
		
pin_connect_block_setup_for_uart0
	STMFD sp!, {r0, r1, lr}
	LDR r0, =0xE002C000  ; PINSEL0
	LDR r1, [r0]
	ORR r1, r1, #5
	BIC r1, r1, #0xA
	STR r1, [r0]
	LDMFD sp!, {r0, r1, lr}
	BX lr

	END			
