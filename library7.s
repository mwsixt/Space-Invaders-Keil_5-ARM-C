	AREA	library, CODE, READWRITE
	
U0LSR EQU 0x14			; UART0 Line Status Register
PINSEL0 EQU 0xE002C000
PINSEL1 EQU 0xE002C004
IO0DIR EQU 0xE0028008
IO1DIR EQU 0xE0028018
IO0SET EQU 0xE0028004
IO1SET EQU 0xE0028014
IO0CLR EQU 0xE002800C
IO1CLR EQU 0xE002801C
IO0PIN EQU 0xE0028000
IO1PIN EQU 0xE0028010

WHITE EQU 0x26
RED EQU 0x2
GREEN EQU 0x20
BLUE EQU 0x4
PURPLE EQU 0x6
YELLOW EQU 0x22
RGBOFF EQU 0x0	

ledErr = "Error, Please enter a 4 bit binary string ",0
	ALIGN
rgbErr = "Error, Please enter w,r,g,b,y,or p for a color choice ",0
	ALIGN
segErr = "Error, Please enter a hexadecimal bit ",0
	ALIGN
segPrompt = "Which segment would you like to show? (1-4)",0
	ALIGN
segPos = 4
	ALIGN
tailLoc = "11111111",0
	ALIGN	
input = "4f5f",0
	ALIGN
read_character
	LDR r1,=0xE000C000		;Load Base Address 
	LDRB r3,[r1,#U0LSR]		;Load Line Status Register 
	AND r2,r3,#1			;And 1st bit of Line status register with one 
	CMP r2,#0				;Compare result with false
	BEQ read_character		;If false, repeat until status changes
	MOV r0,r3				;Copy line status register to temp register
	LDRB r0,[r1] 			;Load base with temp register	
	MOV r1,r0
	BX lr
	
output_character
	LDR r1,=0xE000C000		;r1 = Base register
	LDRB r3,[r1,#U0LSR]		;Load Line Status register to r3
	AND r2,r3,#32			;Anding 5th bit of line status register and storing in result
	CMP r2,#0				;Compare result to 0
	BEQ output_character	;If val at line status register=0, loop back to start
	STR r0,[r1]				;Else, Load value of receiver buffer register with line status register
	BX lr
	
read_string
	STMFD sp!, {r0-r5,lr}
	LDR r4,=input			;Set head to predefined value
	MOV r5,r4				;Set tail to head
	LDR r1,=0xE000C000		;Set r1 to UART base address
read_loop		
	BL read_character		;Goto read character sub
	BL output_character		;Goto output character sub
	CMP r0,#13				;Is char enter?
	BNE not_end				;If not, then skip next step
	MOV r0,#0				;Change read char to null
not_end
	STRB r0,[r5]			;Store char to tail
	ADD r5,r5,#1			;Increment tail
	CMP r0,#0				;Is char null?
	BNE read_loop			;If not, loop 
	MOV r0, #10				;Else, store char to vertical tab
	STR r0,[r1]				;Output vertical tab
	MOV r0, #13				;Store char to carriage return
	STR r0,[r1]				;Output carriage return
	MOV r5,r4				;Set tail to head
	LDMFD sp!, {r0-r5,lr}			;Restore link register
	BX lr
	
output_string
	STMFD SP!,{lr} 			;Store link address
	MOV r4,r0
	LDRB r0,[r4]			;Load value from head
	LDR r1,=0xE000C000		;Set r1 to UART base
output_string_loop
	BL output_character		;Goto output_character with link
	ADD r4,r4,#1			;Increment tail to next mem location
	LDRB r0,[r4]			;Load head with char
	CMP r0,#0				;Compare r0 with null
	BEQ output_string_end	;If so, goto end
	B output_string_loop	;Else, goto loop
output_string_end
	MOV r0, #10				;Store char as vert tab
	STR r0,[r1]				;Output vert tab
	MOV r0, #13				;Store char as carriage return
	STR r0,[r1]				;Output carr return
	MOV r5,r4
	MOV r0,r4
	LDMFD sp!, {lr}			;load link address
	BX lr					;Link back
	
display_digit_on_7_seg
	STMFD SP!,{lr}			;Store link register
	;r4 begining r5 end
	MOV r6,#0				;Store 0 to r6
	LDR r3,=segPos			;Sets r3 to equal location of segment position counter
	LDRB r7,[r3]			;Sets r7 to value of segment position counter
	CMP r7,#4				;Is seg pos counter 4?
	BNE dglup				;If not goto loop
	LDR r3,=tailLoc			;If it is, load tail location into r3
	STR r4,[r3]				;Store head to tail location
dglup
	LDR r3,=tailLoc			;Set r3 to location of tail location
	LDR r5,[r3]				;Load tail location into r5
	
	LDRB r3,[r5]			;Load char
	
	CMP r3,#0
	BEQ tisNull
	CMP r3,#35				;Is char #?
	BEQ tisInit				;Goto init
	
	LDR r9,=IO0SET
	LDRH r9,[r9]
	LDR r1,=IO0CLR			;Load clear register
	LDR r2,=46976			;Clear all segs
	STR r2,[r1]				;Store to clear register
	CMP r3,#33				;Is char !?
	BEQ tisClear			;Goto clear
	
	CMP r3,#0x30			;Is char 1-9 or A-F (not case sensitive)
	BEQ tis0				;Goto respective label
	CMP r3,#0x31		
	BEQ tis1
	CMP r3,#0x32
	BEQ tis2
	CMP r3,#0x33
	BEQ tis3
	CMP r3,#0x34
	BEQ tis4
	CMP r3,#0x35
	BEQ tis5
	CMP r3,#0x36
	BEQ tis6
	CMP r3,#0x37
	BEQ tis7
	CMP r3,#0x38
	BEQ tis8
	CMP r3,#0x39
	BEQ tis9
	CMP r3,#0x41
	BEQ tisA
	CMP r3,#0x61
	BEQ tisA
	CMP r3,#0x42
	BEQ tisB
	CMP r3,#0x62
	BEQ tisB
	CMP r3,#0x43
	BEQ tisC
	CMP r3,#0x63
	BEQ tisC
	CMP r3,#0x44
	BEQ tisD
	CMP r3,#0x64
	BEQ tisD
	CMP r3,#0x45
	BEQ tisE
	CMP r3,#0x65
	BEQ tisE
	CMP r3,#0x46
	BEQ tisF
	CMP r3,#0x66
	BEQ tisF				
	B tisInv				;If anything else, goto err
	LDMFD sp!, {lr}			;Restore link register
	BX lr					;Go back to whence you came
tisInit
	LDR r6,=32768			;Load g segment
	B sevenSegCont
tisInv
	MOV r6,r9				;If invalid value, ignore it
	B sevenSegCont
tisNull
	LDR r3,=tailLoc			;Load r3 with tailLoc location
	SUB r5,r5,#1			;Subtract r5 by 1
	STR r5,[r3]				;Store to tailLoc
	
	LDMFD sp!, {lr}			;Load link reg 
	BX lr					;Leave program
tisClear
	LDR r6,=0				;Load 0
	B sevenSegCont
tis0
	LDR	r6, =14208		;14208 turns a,b,c,d,e,f on
	B sevenSegCont
tis1
	LDR	r6, =0x300			;768 turns b&c on
	B sevenSegCont
tis2
	LDR	r6, =0x9580			;48512 turns a,b,g,e,d on
	B sevenSegCont
tis3
	LDR	r6, =0x8780			;40832 turns a,b,c,d,g on
	B sevenSegCont
tis4
	LDR	r6, =0xA300			;41728 turns b,c,f,g on
	B sevenSegCont
tis5
	LDR	r6, =0xA680			;42624 turns a,c,d,f,g on
	B sevenSegCont
tis6
	LDR	r6, =0xB680			;46720 turns a,c,d,e,f,g on
	B sevenSegCont
tis7
	LDR	r6, =0x380			;896 turns a,b,c on
	B sevenSegCont
tis8
	LDR	r6, =0xB780			;46976 turns all of them on
	B sevenSegCont
tis9
	LDR	r6, =0xA380			;41856 turns a,b,c,f,g on
	B sevenSegCont
tisA
	LDR r6, =0xB380			;45952 turns a,b,c,e,f,g on
	B sevenSegCont
tisB
	LDR r6, =0xB600			;46592 turns c,d,e,f,g on
	B sevenSegCont
tisC
	LDR r6, =0x3480			;13440 turns a,d,e,f on
	B sevenSegCont
tisD
	LDR r6, =0x9700			;38656 turns b,c,d,g on
	B sevenSegCont
tisE
	LDR r6, =0xB480			;46208 turns a,d,e,f,g on
	B sevenSegCont
tisF
	LDR r6, =0xB080			;45184 turns a,e,f,g on
	B sevenSegCont
sevenSegCont
	B sevenSegFin
	;LDRB r3,[r4,#1]			;Load next char
	;CMP r3,#49				;Is char 1-4?
	;BLE segsel1				;Goto respective segsel
	;CMP r3,#50
	;BEQ segsel2
	;CMP r3,#51
	;BEQ segsel3
	;CMP r3,#52
	;BEQ segsel4
	;CMP r3,#53
	;BEQ segsel5
	;B segsel1
sevenSegFin	
	LDR r1,=IO0DIR			;Load direction chooser
	LDR r3,[r1]
	LDR r8,=2490368
	AND r3,r3,r8
	LDR r2,=46976			;Set reg to all segs
	ADD r2,r2,r7			;Add desired digit
	ADD r2,r2,r3
	STR r2,[r1]				;Store to direction
	MOV r2,r6				;Load desired segment value
	LDR r1,=IO0SET			;Load set register
	STR r2,[r1]				;Store to set reg
	
	LDRB r3,[r5,#1]			;Load r3 with location of tail+1
	CMP r3,#0				;Is it 0?
	BNE INCR				;If not goto INCR
	
	LDR r3,=segPos			;Set r3 to segment position
	MOV r7,#4				;Set r7 to 4
	STRB r7,[r3]			;Store 4 to segment position
sevenSegExit	
	LDMFD sp!, {lr}			;Restore Link address
	BX lr					;Link back

INCR
	LDR r3,=segPos			;Load segPos location
	ADD r7,r7,r7			;double r7 to get next seg,[r1]
	STRB r7,[r3]			;Store new segPos
	
	LDR r3,=tailLoc			;Load tailLoc location
	ADD r5,r5,#1			;Increment r5
	STR r5,[r3]				;Store in tailLoc 
	B sevenSegExit			;Exit
seg_err
	LDR r4,=segErr			;Load error prompt
	BL output_string		;Output prompt
	BL read_string			;Scan for input
	B display_digit_on_7_seg;Rerun subroutine	

;segsel1	
	;LDR r7,=4				;Set desired digit 1
	;B sevenSegFin			;Goto Fin
;segsel2	
	;LDR r7,=8				;Set desired digit 2
	;B sevenSegFin			;Goto Fin
;segsel3	
	;LDR r7,=16				;Set desired digit 3
	;B sevenSegFin			;Goto Fin
;segsel4	
	;LDR r7,=32				;Set desired digit 4
	;B sevenSegFin			;Goto Fin 
;segsel5	
	;LDR r7,=60				;Set desired digit all
	;B sevenSegFin			;Goto Fin	
	
illuminate_RGB_LED
	STMFD SP!,{r0-r12,lr}			;Store link register
color_select
	CMP r0,#119				;Is val=w?
	BEQ white				;Goto white
	CMP r0,#114				;Is val=r?
	BEQ red					;Goto red
	CMP r0,#103				;Is val=g?
	BEQ green				;Goto green
	CMP r0,#98				;Is val=b?
	BEQ blue				;Goto blue
	CMP r0,#121				;Is val=y?
	BEQ yellow				;Goto yellow
	CMP r0,#112				;Is val=p?
	BEQ purple				;Goto purple
	B rgb_err				;Else, goto error
white
	LDR r0,=WHITE			;Val=WHITE
	B rgb_cont				;Goto cont
green
	LDR r0,=GREEN			;Val=GREEN
	B rgb_cont				;Goto cont
red
	LDR r0,=RED				;Val=RED
	B rgb_cont				;Goto cont
blue
	LDR r0,=BLUE			;Val=BLUE
	B rgb_cont				;Goto cont
yellow
	LDR r0,=YELLOW			;Val=YELLOW
	B rgb_cont				;Goto cont
purple
	LDR r0,=PURPLE			;Val=PURPLE
	B rgb_cont				;Goto cont
rgb_cont
	LDR r1,=PINSEL1			;Select pinsel1
	MOV r2,#1				;store 1
	STRB r2,[r1]			;Write 1 to pinsel1
	LDR r1,=IO0DIR			;Load IO0DIR
	STRB r0,[r1]			;Store val
	LDMFD sp!, {r0-r12,lr}			;Restore Link address

	BX lr					;Go back to whence you came
rgb_err
	LDR r4,=rgbErr			;load error prompt
	BL output_string		;Output prompt
	B illuminate_RGB_LED	;Goto subroutine start


read_from_push_btns
	STMFD SP!,{lr}			;Store link register
	MOV r0,#0x40000001		;Goto arbitrary readable memory
	LDR r1,=IO1DIR			;Load direction reg
	LDR r2,[r1]				;Load data at direction reg
	AND r2,r2,#0			;Invert
	STR r2,[r1]				;Store back
	LDR r1,=IO1PIN			;Load pin register
	LDRB r2,[r1,#2]			;Load pin reg offset by 2
	LSR r2,r2,#4			;Left shift by 4
	RSB r2,r2,#15			;Subtract 15
	
	MOV r6,#0				;Set r6 to 0
	AND r7,r2,#8			;Check 3rd bit
	CMP r7,#1				;Is it 1?
	BNE stage_two			;If not, Goto stage two
	ADD r6,r6,#1			;Add 1 to r6
stage_two
	AND r7,r2,#4			;Check 2nd bit
	CMP r7,#1				;Is it 1?
	BNE stage_three			;If not, Goto stage three
	ADD r6,r6,#2			;Add 2
stage_three		
	AND r7,r2,#2			;Check 1st bit
	CMP r7,#1				;Is it 1?
	BNE stage_four			;If not, Goto stage four
	ADD r6,r6,#4			;Add 4
stage_four
	AND r7,r2,#1			;Check 0th bit
	CMP r7,#1				;is it 1?
	BNE stage_fin			;If not, Goto fin
	ADD r6,r6,#8			;Add 8
stage_fin
	;MOV r2,r6
	CMP r2,#9				;Is r2 9 or less?
	BLE btn_digit			;Goto digit selector
	CMP r2,#15				;is r2 A-F?
	BLE btn_letter			;Goto Letter
	LDMFD sp!, {lr}			;Restore link register
	BX lr					;Go back to whence you came
btn_digit
	ADD r2,r2,#48			;Get Ascii value of digit
	STRB r2,[r0]			;Store to val
	ADD r0,r0,#1			;Increment val
	B btn_end				;Goto end
btn_letter
	MOV r3,#49				;Set reg to 1 ascii code
	STRB r3,[r0]			;Store to val
	ADD r0,r0,#1			;Increment val
	ADD r2,r2,#38			;Get ascii value of remaining
	STRB r2,[r0]			;Store to val
	ADD r0,r0,#1			;Increment val
btn_end
	MOV r3,#0				;Store 0
	STRB r3,[r0]			;Store to val
	LDRB r0,[r4]			;Store val to string head
	BL output_string		;Output val
	LDMFD sp!, {lr}			;Restore link register
	BX lr					;Go back to whence you came


illuminateLEDs
	STMFD SP!,{r0-r12,lr}			;Store link register
	MOV r4,r0
	MOV r3,#0				;Set place counter to 0
	MOV r6,#0				;Set total to 0
bit_loop
	LDRB r5,[r4]			;Load register with value in string head
	CMP r5,#48				;Is val 0?
	BEQ led_cont			;Goto cont
	CMP r5,#49				;Is val 1?
	BEQ led_cont			;Goto cont
	B led_err				;Else, goto error
led_cont	
	SUB r5,r5,#48			;Get actual value from ascii value
	LSL r5,r5,r3			;Shift value by place counter
	ADD r3,r3,#1			;Increment place counter
	ADD r6,r6,r5			;Add actual value to total
	ADD r4,r4,#1			;Increment tail by 1 
	CMP r3,#3				;Is place counter 3?
	BLE bit_loop			;If less than or equal, goto loop
	LDR r1,=PINSEL1			;Load pinsel1
	MOV r2,#1				;Load 1
	STRB r2,[r1]			;Store 1 to pinsel1
	LDR r1,=IO1DIR			;Load direction chooser
	MOV r2,r6				;Load desired pin(2) 
	STRB r2,[r1]			;Store pin to direction
led_end	
	LDMFD sp!, {r0-r12,lr}			;Restore link register
	BX lr					;Go back to whence you came
led_err
	LDR r4,=ledErr			;Load error prompt
	BL output_string		;output prompt
	BX lr					;Go back to whence you came


UART_init
	STMFD SP!,{lr}
	MOV r3,#131				;Copy 131 to r3
	STRB r3,[r1,#0xC]		;Store r1+0xC to 131
	MOV r3,#120				;Copy 120 to r3
	STRB r3,[r1]			;Store 120 to r1
	MOV r3,#0				;Copy 0 to r3
	STRB r3,[r1,#0x4]		;Store 0 to r1+0x4
	MOV r3,#3				;Copy 3 to r3
	STRB r3,[r1,#0xC]		;Store 3 to r1+0xC
	LDMFD SP!, {lr}			; Restore register lr from stack	
	BX lr					;Go back to whence you came
	END