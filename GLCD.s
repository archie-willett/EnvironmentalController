#include <xc.inc>

global  GLCD_Setup, GLCD_Write_Data
psect	udata_acs   ; named variables in access ram
GLCD_cnt_l:	ds 1	; reserve 1 byte for variable LCD_cnt_l
GLCD_cnt_h:	ds 1	; reserve 1 byte for variable LCD_cnt_h
GLCD_cnt_ms:	ds 1	; reserve 1 byte for ms counter
GLCD_tmp:	ds 1	; reserve 1 byte for temporary use
GLCD_countery:	ds 1	; reserve 1 byte for counting through nessage
GLCD_counterx:  ds 1	;

PSECT	udata_acs_ovr,space=1,ovrld,class=COMRAM
GLCD_hex_tmp:	ds 1    ; reserve 1 byte for variable LCD_hex_tmp

	GLCD_CS1 EQU 0	; column left
	GLCD_CS2 EQU 1	; column right
    	GLCD_RS	EQU 2	; LCD register select bit
	GLCD_RW EQU 3
	GLCD_E	EQU 4	; LCD enable bit
	RST EQU	5

psect	glcd_code,class=CODE
    
GLCD_Setup:
	clrf    LATB, A
	movlw   00000000B	    ; RB0:5 all outputs
	movwf	TRISB, A
	movlw   4
	clrf    LATD, A

	clrf	TRISD, A
	movlw   4
	call	GLCD_delay_ms	; wait 40ms for LCD to start up properly

	bcf	LATB, RST, A
	bsf	LATB, RST, A
	bcf	LATB, GLCD_CS1, A   ;set column 1 on	
	bcf	LATB, GLCD_CS2, A   ;set column 2 on

	movlw	00111110B	; display off
	call	GLCD_Instruction
	movlw	1		; wait 40us
	call	GLCD_delay_x4us
	
	call	GLCD_Clear_Display
	
	movlw	01000000B	;y address
	call	GLCD_Instruction
	movlw	1
	call	GLCD_delay_x4us
	
	movlw	10111000B	;set page
	call	GLCD_Instruction
	movlw	1
	call	GLCD_delay_x4us

	movlw	00111111B	; display on
	call	GLCD_Instruction
	movlw	1		; wait 40us
	call	GLCD_delay_x4us
	
	
	
	return

GLCD_Clear_Display:
	movlw	0
	movwf	GLCD_countery, A
GLCD_Loop:
	movlw	10111000B
	addwf	GLCD_countery, W, A
	call	GLCD_Instruction
	movlw	1		; wait 40us
	call	GLCD_delay_x4us
	call	GLCD_Clear_x
	incf	GLCD_countery
	movlw	8
	cpfseq	GLCD_countery, A
	bra	GLCD_Loop
	return
	
GLCD_Clear_x:
	movlw	64
	movwf	GLCD_counterx, A
GLCD_x_Loop:
	movlw	0x00
	call	GLCD_Write_Data
	decfsz	GLCD_counterx, A
	bra	GLCD_x_Loop
	return

GLCD_Write_Data:
	movwf	LATD, A
	bsf	LATB, GLCD_RS, A    ; take RS high (select data register)
	bcf	LATB, GLCD_RW, A    ; take RW low (select write operation)
	nop
	nop
	call	GLCD_Enable	    ; send enable pulse	
	nop
	nop
	bcf	LATB, GLCD_RS, A
	movlw	2
	call	GLCD_delay_ms
	return
	
GLCD_Instruction:
	movwf	LATD, A
	bcf	LATB, GLCD_RS, A    ; take RS low (select instruction register)
	bcf	LATB, GLCD_RW, A    ; take RW low (select write operation)
	nop
	nop
	call	GLCD_Enable	; send enable pulse
	nop
	nop
	bsf	LATB, GLCD_RS, A
	bsf	LATB, GLCD_RW, A
	movlw	1
	call	GLCD_delay_x4us
	call	GLCD_delay_x4us
	return
	
GLCD_Set_Page:
	movwf	GLCD_tmp, A
	movlw	10111000B
	addwf	GLCD_tmp, W, A
	call	GLCD_Instruction
	movlw	1		; wait 40us
	call	GLCD_delay_x4us
	return
    
GLCD_Set_Y:
	movwf	GLCD_tmp, A
	movlw	01000000B
	addwf	GLCD_tmp, W, A
	call	GLCD_Instruction
	movlw	1   	; wait 40us
	call	GLCD_delay_x4us
	return
	
GLCD_Left:
	bcf	LATB, GLCD_CS1, A   ;set column 1 on	
	bsf	LATB, GLCD_CS2, A   ;set column 2 off
	return
	
GLCD_Right:
	bsf	LATB, GLCD_CS1, A   ;set column 1 off	
	bcf	LATB, GLCD_CS2, A   ;set column 2 on
	return
	
GLCD_Both:
	bcf	LATB, GLCD_CS1, A   ;set column 1 on	
	bcf	LATB, GLCD_CS2, A   ;set column 2 on
	return
    
GLCD_Enable:	    ; pulse enable bit LCD_E for 1000ns
        bcf	LATB, GLCD_E, A	    ; Writes data to LCD	
        nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bsf	LATB, GLCD_E, A	    ; Take enable high	
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bcf	LATB, GLCD_E, A	    ; Writes data to LCD
	return	
	
GLCD_delay_ms:		    ; delay given in ms in W
	movwf	GLCD_cnt_ms, A
glcdlp2:	movlw	250	    ; 1 ms delay
	call	GLCD_delay_x4us	
	decfsz	GLCD_cnt_ms, A
	bra	glcdlp2
	return	
	
GLCD_delay_x4us:		    ; delay given in chunks of 4 microsecond in W
	movwf	GLCD_cnt_l, A	; now need to multiply by 16
	swapf   GLCD_cnt_l, F, A	; swap nibbles
	movlw	0x0f	    
	andwf	GLCD_cnt_l, W, A ; move low nibble to W
	movwf	GLCD_cnt_h, A	; then to LCD_cnt_h
	movlw	0xf0	    
	andwf	GLCD_cnt_l, F, A ; keep high nibble in LCD_cnt_l
	call	GLCD_delay
	return	
	
GLCD_delay:			; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
glcdlp1:	decf 	GLCD_cnt_l, F, A	; no carry when 0x00 -> 0xff
	subwfb 	GLCD_cnt_h, F, A	; no carry when 0x00 -> 0xff
	bc 	glcdlp1		; carry, then loop again
	return			; carry reset so return

end







