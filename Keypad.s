#include <xc.inc>

global	KeyPad_init, KeyPad_wait, delay_x1ms, KeyPad_check, CheckH, CheckL
extrn	GLCD_delay_x4us, GLCD_delay_ms, UART_Transmit_Byte
extrn	UART_Send_Temperature, UART_Transmit_Message
    
    
    
psect	udata_acs   ; named variables in access ram
counter:    ds 1    ; reserve one byte for a counter variable
KeyPadVal:	ds 1   ; reserve 1 byte for variable
delay_count:	ds 1    ; reserve one byte for counter in the delay routine
KeyPad_checkbit: ds 1
hh:	ds 1
hl:	ds 1
lh:	ds 1
ll:	ds 1
CheckH: ds 1
CheckL: ds 1

psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x400)
myArray:    ds 0x80 ; reserve 128 bytes for message data

psect	data    
	; ******* myTable, data in programme memory, and its length *****
myTable:
	db	'I','n','p','u','t',' ','T','e','m','p','e','r','a','t','u','r'
	db	'e',0x0a
					; message, plus carriage return
	myTable_l   EQU	18	; length of data
	align	2
	
psect	KeyPad_code, class=CODE 
KeyPad_init:
	setf	TRISE, A
	clrf	LATE, A
	banksel PADCFG1
	bsf	REPU
	banksel 0
	return
KeyPad_check:
	movlw	0x01
	movwf	KeyPad_checkbit, A
	bra	KeyPad_loop
KeyPad_wait:
	movlw	0x00
	movwf	KeyPad_checkbit, A
	bra	KeyPad_loop
KeyPad_loop:
	;call	LCD_clear
	movlw	0x7F
	call	GLCD_delay_ms
	movlw	0x0F
	movwf	TRISE, A
	movlw	0x01
	call	GLCD_delay_x4us
	movff	PORTE,	KeyPadVal, A
	movlw	0xF0
	movwf	TRISE, A
	movlw	0x01
	call	GLCD_delay_x4us
	movf	PORTE, W, A
	addwf	KeyPadVal, f, A
	movlw	0x00
	cpfseq	KeyPad_checkbit, A
	bra	KeyPad_CheckC
	movlw	0xFF
	cpfseq	KeyPadVal, A
	bra	KeyPad_buttons
	bra	KeyPad_wait
KeyPad_buttons:
	movlw	0x8F
	call	GLCD_delay_ms
KeyPad_button1:
	movlw	11101110B
	subwf	KeyPadVal, W, A
	bnz	KeyPad_button2
	retlw	'1'
KeyPad_button2:
	movlw	11101101B
	subwf	KeyPadVal, W, A
	bnz	KeyPad_button3
	retlw	'2'
KeyPad_button3:
	movlw	11101011B
	subwf	KeyPadVal, W, A
	bnz	KeyPad_buttonF
	retlw	'3'
KeyPad_buttonF:
	movlw	11100111B
	subwf	KeyPadVal, W, A
	bnz	KeyPad_button4
	retlw	'F'
KeyPad_button4:
	movlw	11011110B
	subwf	KeyPadVal, W, A
	bnz	KeyPad_button5
	retlw	'4'
KeyPad_button5:
	movlw	11011101B
	subwf	KeyPadVal, W, A
	bnz	KeyPad_button6
	retlw	'5'
KeyPad_button6:
	movlw	11011011B
	subwf	KeyPadVal, W, A
	bnz	KeyPad_buttonE
	retlw	'6'
KeyPad_buttonE:
	movlw	11010111B
	subwf	KeyPadVal, W, A
	bnz	KeyPad_button7
	retlw	'E'
KeyPad_button7:
	movlw	10111110B
	subwf	KeyPadVal, W, A
	bnz	KeyPad_button8
	retlw	'7'
KeyPad_button8:
	movlw	10111101B
	subwf	KeyPadVal, W, A
	bnz	KeyPad_button9
	retlw	'8'
KeyPad_button9:
	movlw	10111011B
	subwf	KeyPadVal, W, A
	bnz	KeyPad_buttonD
	retlw	'9'
KeyPad_buttonD:
	movlw	10110111B
	subwf	KeyPadVal, W, A
	bnz	KeyPad_buttonA
	retlw	'D'
KeyPad_buttonA:
	movlw	01111110B
	subwf	KeyPadVal, W, A
	bnz	KeyPad_button0
	retlw	'A'
KeyPad_button0:
	movlw	01111101B
	subwf	KeyPadVal, W, A
	bnz	KeyPad_buttonB
	retlw	'0'
KeyPad_buttonB:
	movlw	01111011B
	subwf	KeyPadVal, W, A
	bnz	KeyPad_buttonC
	retlw	'B'
KeyPad_buttonC:
	movlw	01110111B
	subwf	KeyPadVal, W, A
	bnz	KeyPad_wait
	retlw	'C'
	
KeyPad_CheckC:
	movlw	01110111B
	cpfseq	KeyPadVal, A
	return
	call	KeyPad_InputTemp
	return

KeyPad_InputTemp:
	lfsr	0, myArray	; Load FSR0 with address in RAM	
	movlw	low highword(myTable)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(myTable)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(myTable)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	myTable_l	; bytes to read
	movwf 	counter, A		; our counter register
message_loop: 	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	message_loop		; keep going until finished
	movlw	myTable_l	; output message to UART
	lfsr	2, myArray
	call	UART_Transmit_Message
temperature_input:
	call	KeyPad_wait
	call	UART_Transmit_Byte
	movwf	hl, A
	movlw	0x30
	subwf	hl, F, A
	movff	hl, CheckH
	call	KeyPad_wait
	call	UART_Transmit_Byte
	movwf	lh, A
	movlw	0x30
	subwf	lh, F, A
	movlw   '.'
	call    UART_Transmit_Byte
	call	KeyPad_wait
	call	UART_Transmit_Byte
	movwf	ll, A
	movlw	0x30
	subwf	ll, F, A
	swapf	lh, W, A
	iorwf	ll, F, A
	movff	ll, CheckL
	movlw   0xBA
	call    UART_Transmit_Byte
	movlw   'C'
	call    UART_Transmit_Byte
	movlw   0x0D
	call    UART_Transmit_Byte
	movlw   0x0A
	call    UART_Transmit_Byte
	movlw   0x0A
	call    UART_Transmit_Byte
	return
	
Delay_10us:
	movlw	0x50
	movwf	delay_count, A
Delay_10us_loop:
	decfsz	delay_count, A	; decrement until zero
	bra	Delay_10us_loop
	return





