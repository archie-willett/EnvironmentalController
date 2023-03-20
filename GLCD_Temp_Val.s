#include <xc.inc>
    
    
    
psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x400)
NumberArray:    ds 0x1E ; reserve 30 bytes for numbers
    
PSECT	udata_acs_ovr,space=1,ovrld,class=COMRAM
GLCD_temp_compare:	    ds 1
GLCD_temp_compare_counter:  ds 1

psect	data    
	; ******* myTable, data in programme memory, and its length *****
NumberTable:
	db	11111000B, 10001000B, 11111000B,
		00010001B, 00011111B, 00010000B,
		00011101B, 00010101B, 00010111B,
		00010001B, 00010101B, 00011111B,
		00000111B, 00000100B, 00011110B,
		00010111B, 00010101B, 00011101B,
		00011111B, 00010101B, 00011101B,
		00000001B, 00011001B, 00000111B,
		00011111B, 00010101B, 00011111B,
		00000111B, 00000101B, 00011111B
	NumberTable_l   EQU	30	; length of data
	align	2
    
psect	glcd_temp_val_code,class=CODE

	; ******* Programme FLASH read Setup Code ***********************
GLCD_Temp_Val_setup:	
	bcf	CFGS	; point to Flash program memory  
	bsf	EEPGD 	; access Flash program memory
	lfsr	0, NumberArray	; Load FSR0 with address in RAM	
	movlw	low highword(NumberTable)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(NumberTable)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(NumberTable)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	myTable_l	; bytes to read
	movwf 	counter, A		; our counter register
loop: 	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	loop		; keep going until finished

GLCD_Current_Temperature:
	movff	GLCD_Current_Temp_h, GLCD_temp_compare, A
	movlw	0x0F
	andwf	GLCD_temp_compare, A
	call	GLCD_Current_Temp_Compare
	
	movff	GLCD_Current_Temp_l, GLCD_temp_compare, A
	movlw	0xF0
	andwf	GLCD_temp_compare, A
	call	GLCD_Current_Temp_Compare
	
	movlw	10000000B
	call	GLCD_Write_Data
	
	movff	GLCD_Current_Temp_l, GLCD_temp_compare, A
	movlw	0x0F
	andwf	GLCD_temp_compare, A
	call	GLCD_Current_Temp_Compare
	return
	
GLCD_Current_Temp_Compare:
	lfsr	0, NumberArray
	movlw	0x03
	mulwf	GLCD_temp_compare, A
	movf	PRODL, A
	lfsr	0, PLUSW0
	movlw	0x03
	movwf	GLCD_temp_compare_counter, A
GLCD_Current_Temp_Compare_Loop:
	movf	POSTINC0, W, A
	decfsz	GLCD_temp_compare_counter, A
	call	GLCD_Write_Data
	movlw	0
	call	GLCD_Write_Data
	return
	