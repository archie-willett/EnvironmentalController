#include <xc.inc>

global	KeyPad_init, KeyPad_wait, delay_x1ms, KeyPad_check
global	GoalTemp_Dec_H, GoalTemp_Dec_L, Print
extrn	GLCD_delay_x4us, GLCD_delay_ms, UART_Transmit_Byte
extrn	UART_Send_Temperature, UART_Transmit_Message
extrn	Convert_GoalTemp_Dec2Hex, GLCD_Print_Goal_Temperature
    
    
    
psect	udata_acs   ; named variables in access ram
counter:    ds 1    ; reserve one byte for a counter variable
KeyPadVal:	ds 1   ; reserve 1 byte for variable
delay_count:	ds 1    ; reserve one byte for counter in the delay routine
KeyPad_checkbit: ds 1
HH:	ds 1
HL:	ds 1
LH:	ds 1
LL:	ds 1
GoalTemp_Dec_L:	ds 1
GoalTemp_Dec_H:	ds 1
KeyPad_delay: ds 1

psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x400)
Array_InputTemperature:    ds 18 ; reserve 18 bytes for message data
Array_Confirm:		   ds 26 ; reserve 18 bytes for message data

psect	data    
	; ******* myTable, data in programme memory, and its length *****
Table_InputTemperature:
	db	'I','n','p','u','t',' ','T','e','m','p','e','r','a','t','u','r'
	db	'e',0x0a
					; message, plus carriage return
	Table_InputTemperature_l   EQU	18	; length of data
	align	2
Table_Confirm:
	db	'C','o','n','f','i','r','m',0x0A
	db	'Y','e','s',' ','(','A',')',' ','/',' ','N','o',' ','(','B',')'
	db	0x0A, 0x0A
					; message, plus carriage return
	Table_Confirm_l   EQU	26	; length of data
	align	2
	
psect	KeyPad_code, class=CODE 
KeyPad_init:
	setf	TRISE, A
	clrf	LATE, A
	banksel PADCFG1
	bsf	REPU
	banksel 0
KeyPad_InputTemp_init:
	lfsr	0, Array_InputTemperature	; Load FSR0 with address in RAM	
	movlw	low highword(Table_InputTemperature)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(Table_InputTemperature)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(Table_InputTemperature)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	Table_InputTemperature_l	; bytes to read
	movwf 	counter, A		; our counter register
InputTemp_message_read_loop: 	
	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	InputTemp_message_read_loop		; keep going until finished
KeyPad_Confirm_init:
	lfsr	0, Array_Confirm	; Load FSR0 with address in RAM	
	movlw	low highword(Table_Confirm)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(Table_Confirm)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(Table_Confirm)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	Table_Confirm_l	; bytes to read
	movwf 	counter, A		; our counter register
Confirm_message_read_loop: 	
	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	Confirm_message_read_loop		; keep going until finished
	return
	
KeyPad_confirm:
	movlw	0x02
	movwf	KeyPad_checkbit, A
	movlw	0x00
	movwf	KeyPad_delay, A
	bra	KeyPad_loop
KeyPad_check:
	movlw	0x01
	movwf	KeyPad_checkbit, A
	movlw	0x00
	movwf	KeyPad_delay, A
	bra	KeyPad_loop
KeyPad_wait:
	movlw	0x00
	movwf	KeyPad_checkbit, A
	movlw	0x7F
	movwf	KeyPad_delay, A
	bra	KeyPad_loop
KeyPad_loop:
	movf	KeyPad_delay, W, A
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
	bra	KeyPad_Check_Button
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
	
KeyPad_Check_Button:
	movlw	0x02
	cpfseq	KeyPad_checkbit, A
	bra	KeyPad_CheckC
KeyPad_CheckA:
	movlw	01111110B
	subwf	KeyPadVal, W, A
	bnz	KeyPad_CheckB
	retlw	0x00
KeyPad_CheckB:
	movlw	01111011B
	subwf	KeyPadVal, W, A
	bnz	KeyPad_loop
	retlw	0x01
KeyPad_CheckC:
	movlw	01110111B
	cpfseq	KeyPadVal, A
	return
	bra	KeyPad_InputTemp

KeyPad_InputTemp:
	movlw	Table_InputTemperature_l	; output message to UART
	lfsr	2, Array_InputTemperature
	call	UART_Transmit_Message
temperature_input:
	movlw	0xFF
	call	GLCD_delay_ms
	call	KeyPad_wait
	movwf	HL, A
	call	UART_Transmit_Byte
	movlw	0x30
	subwf	HL, F, A
	movff	HL, GoalTemp_Dec_H, A
	
	call	KeyPad_wait
	movwf	LH, A
	call	UART_Transmit_Byte
	movlw	0x30
	subwf	LH, F, A
	
	movlw   '.'
	call    UART_Transmit_Byte
	
	call	KeyPad_wait
	movwf	LL, A
	call	UART_Transmit_Byte
	movlw	0x30
	subwf	LL, F, A
	
	swapf	LH, W, A
	iorwf	LL, F, A
	movff	LL, GoalTemp_Dec_L, A
	
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
Confirm:
	movlw	Table_Confirm_l	; output message to UART
	lfsr	2, Array_Confirm
	call	UART_Transmit_Message
	call	KeyPad_confirm
	sublw	0x01
	bz	KeyPad_InputTemp
	call	Convert_GoalTemp_Dec2Hex
Print:
	call	GLCD_Print_Goal_Temperature
	return
	
Delay_10us:
	movlw	0x50
	movwf	delay_count, A
Delay_10us_loop:
	decfsz	delay_count, A	; decrement until zero
	bra	Delay_10us_loop
	return





