#include <xc.inc>
    
global	GLCD_Temp_Val_setup, GLCD_Current_Temperature
    
extrn	  DCon4DigH, DCon4DigL, GLCD_Write_Data ;h1, l1, 
    
psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x400)
NumberArray:    ds 0x1E ; reserve 30 bytes for numbers

    
PSECT	udata_acs_ovr,space=1,ovrld,class=COMRAM
GLCD_temp_compare:	    ds 1
GLCD_temp_compare_counter:  ds 1
GLCD_temp_compare_inc:  ds 1
counter:    ds 1    ; reserve one byte for a counter variable

psect	data    
	; ******* myTable, data in programme memory, and its length *****
NumberTable:
	db	11111000B, 10001000B, 11111000B
	db	00010001B, 00011111B, 00010000B
	db	00011101B, 00010101B, 00010111B
	db	00010001B, 00010101B, 00011111B
	db	00000111B, 00000100B, 00011110B
	db	00010111B, 00010101B, 00011101B
	db	00011111B, 00010101B, 00011101B
	db	00000001B, 00011001B, 00000111B
	db	00011111B, 00010101B, 00011111B
	db	00000111B, 00000101B, 00011111B
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
	movlw	NumberTable_l	; bytes to read
	movwf 	counter, A		; our counter register
loop: 	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	loop		; keep going until finished
	return

GLCD_Current_Temperature:
	movff	DCon4DigH, GLCD_temp_compare, A
	movlw	0x0F
	andwf	GLCD_temp_compare, F, A
	call	GLCD_Current_Temp_Compare
	
	movff	DCon4DigL, GLCD_temp_compare, A
	movlw	0xF0
	andwf	GLCD_temp_compare, F, A
	swapf	GLCD_temp_compare, F, A
	call	GLCD_Current_Temp_Compare
	
	movlw	00010000B
	call	GLCD_Write_Data
	movlw	00000000B
	call	GLCD_Write_Data
	
	movff	DCon4DigL, GLCD_temp_compare, A
	movlw	0x0F
	andwf	GLCD_temp_compare, F, A
	call	GLCD_Current_Temp_Compare
	return
	
GLCD_Current_Temp_Compare:
	lfsr	0, NumberArray
	movlw	0x03
	mulwf	GLCD_temp_compare, A
	movff	PRODL, GLCD_temp_compare_inc, A
	movlw	0x04
	movwf	GLCD_temp_compare_counter, A
GLCD_Current_Temp_Compare_Loop:
	movf	GLCD_temp_compare_inc, W, A
	movf	PLUSW0, W, A
	decfsz	GLCD_temp_compare_counter, A
    	bra	GLCD_Current_Temp_Compare_Loop_Continue
	bra	GLCD_Current_Temp_Compare_Loop_End
GLCD_Current_Temp_Compare_Loop_Continue:
	call	GLCD_Write_Data
	incf	GLCD_temp_compare_inc, A
	bra	GLCD_Current_Temp_Compare_Loop
GLCD_Current_Temp_Compare_Loop_End:
	movlw	0
	call	GLCD_Write_Data
	return
	