#include <xc.inc>

global  GLCD_Setup, GLCD_Write_Data, GLCD_Tb, GLCD_m, GLCD_p, GLCD_Right, GLCD_c
global	GLCD_Left, GLCD_Both, GLCD_Set_Y, GLCD_Set_Page, GLCD_Clear_Display
global	GLCD_Space, GLCD_lE, GLCD_I, GLCD_M, GLCD_axis, GLCD_Tt ; GLCD_Bar
global	GLCD_3,GLCD_0,GLCD_5;,GLCD_1,GLCD_2,GLCD_4,GLCD_6,GLCD_7,GLCD_8,GLCD_9
global	GLCD_Compare, GLCD_Full_Bar, GLCD_bc, GLCD_delay_x4us, GLCD_delay_ms
global	GLCD_Update_Bars, GLCD_Update_Bars_Setup

extrn	Avg16val_and_Calibrate, current_temperature
extrn	h1, l1
    
psect	udata_acs   ; named variables in access ram
GLCD_cnt_l:	ds 1	; reserve 1 byte for variable LCD_cnt_l
GLCD_cnt_h:	ds 1	; reserve 1 byte for variable LCD_cnt_h
GLCD_cnt_ms:	ds 1	; reserve 1 byte for ms counter
GLCD_tmp:	ds 1	; reserve 1 byte for temporary use
GLCD_loc:	ds 1	; reserve 1 byte to track y position
GLCD_bar_loc:	ds 1	; reserve 1 byte to track beginning of bar
GLCD_comp_h:	ds 1
GLCD_comp_l:	ds 1
temp_hex_h:	ds 1
temp_hex_l:	ds 1
GLCD_comp_counter:   ds 1
GLCD_graph_line:    ds 1
GLCD_bar_height:    ds 1

GLCD_update_bars_inc: ds 1
GLCD_update_bars_new: ds 1
GLCD_update_bars_counter: ds 1

psect	udata_bank3 ; reserve data anywhere in RAM (here at 0x400)
GLCD_Bar_Values:   ds 20
    
PSECT	udata_acs_ovr,space=1,ovrld,class=COMRAM
GLCD_hex_tmp:	ds 1    ; reserve 1 byte for variable LCD_hex_tmp
GLCD_countery:	ds 1	; reserve 1 byte for counting through nessage
GLCD_counterx:  ds 1	;
;GLCD_update_bars_inc: ds 1
;GLCD_update_bars_new: ds 1
;GLCD_update_bars_counter: ds 1
    
	GLCD_CS1 EQU 0	; column left
	GLCD_CS2 EQU 1	; column right
    	GLCD_RS	EQU 2	; LCD register select bit
	GLCD_RW EQU 3
	GLCD_E	EQU 4	; LCD enable bit
	RST EQU	5

psect	glcd_code,class=CODE
    
GLCD_Setup:
	clrf    LATB, A
	clrf	TRISB, A
	movlw   4
	clrf    LATD, A
	clrf	TRISD, A
	movlw   4
	call	GLCD_delay_ms	; wait 40ms for LCD to start up properly

	bcf	LATB, RST, A
	bsf	LATB, RST, A
	call	GLCD_Both

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
	incf	GLCD_countery, A
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
	incf	GLCD_loc, A
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
	movwf	GLCD_loc, A
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

GLCD_Tt:
	movlw	00000001B
	call	GLCD_Write_Data
	movlw	00000001B
	call	GLCD_Write_Data
	movlw	00011111B
	call	GLCD_Write_Data
	movlw	00000001B
	call	GLCD_Write_Data
	movlw	00000001B
	call	GLCD_Write_Data
	return

GLCD_Tb:
	movlw	00001000B
	call	GLCD_Write_Data
	movlw	00001000B
	call	GLCD_Write_Data
	movlw	11111000B
	call	GLCD_Write_Data
	movlw	00001000B
	call	GLCD_Write_Data
	movlw	00001000B
	call	GLCD_Write_Data
	return
	
GLCD_m:
	movlw	00011100B
	call	GLCD_Write_Data
	movlw	000000100B
	call	GLCD_Write_Data
	movlw	00011100B
	call	GLCD_Write_Data
	movlw	000000100B
	call	GLCD_Write_Data
	movlw	00011100B
	call	GLCD_Write_Data
	return

GLCD_p:
	movlw	01111100B
	call	GLCD_Write_Data
	movlw	00010100B
	call	GLCD_Write_Data
	movlw	00011100B
	call	GLCD_Write_Data
	return	
	
GLCD_c:
	movlw	00000010B
	call	GLCD_Write_Data
	movlw	00000000B
	call	GLCD_Write_Data
	movlw	00001100B
	call	GLCD_Write_Data
	movlw	00010010B
	call	GLCD_Write_Data
	movlw	00010010B
	call	GLCD_Write_Data
	return
	
GLCD_bc:
	movlw	00001000B
	call	GLCD_Write_Data
	movlw	00000000B
	call	GLCD_Write_Data
	movlw	00110000B
	call	GLCD_Write_Data
	movlw	01001000B
	call	GLCD_Write_Data
	movlw	01001000B
	call	GLCD_Write_Data
	return

GLCD_I:
	movlw	11111000B
	call	GLCD_Write_Data
	return	
	
GLCD_lE:
	movlw	11111000B
	call	GLCD_Write_Data
	movlw	10101000B
	call	GLCD_Write_Data
	movlw	10101000B
	call	GLCD_Write_Data
	return
	
GLCD_M:
	movlw	11111000B
	call	GLCD_Write_Data
	movlw	00010000B
	call	GLCD_Write_Data
	movlw	11100000B
	call	GLCD_Write_Data
	movlw	00010000B
	call	GLCD_Write_Data
	movlw	11111000B
	call	GLCD_Write_Data
	return
	
GLCD_axis:
	movlw	00010001B
	call	GLCD_Write_Data
	movlw	00010001B
	call	GLCD_Write_Data
	movlw	00010001B
	call	GLCD_Write_Data
	movlw	00000001B
	call	GLCD_Write_Data
	movlw	00000001B
	call	GLCD_Write_Data
	return
	
GLCD_Space:
	movwf	GLCD_cnt_ms, A
space_loop:
	movlw	0x0
	call	GLCD_Write_Data
	decfsz	GLCD_cnt_ms, A
	bra	space_loop
	return
;GLCD_1:
;	movlw	00010001B
;	call	GLCD_Write_Data
;	movlw	00011111B
;	call	GLCD_Write_Data
;	movlw	00010000B
;	call	GLCD_Write_Data
;	movlw	00000000B
;	call	GLCD_Write_Data
;	return
;GLCD_2:
;	movlw	00011101B
;	call	GLCD_Write_Data
;	movlw	00010101B
;	call	GLCD_Write_Data
;	movlw	00010111B
;	call	GLCD_Write_Data
;	movlw	00000000B
;	call	GLCD_Write_Data
;	return
GLCD_3:
	movlw	00010001B
	call	GLCD_Write_Data
	movlw	00010101B
	call	GLCD_Write_Data
	movlw	00011111B
	call	GLCD_Write_Data
	movlw	00000000B
	call	GLCD_Write_Data
	return
;GLCD_4:
;	movlw	00000111B
;	call	GLCD_Write_Data
;	movlw	00000100B
;	call	GLCD_Write_Data
;	movlw	00011110B
;	call	GLCD_Write_Data
;	movlw	00000000B
;	call	GLCD_Write_Data
;	return
GLCD_5:	
	movlw	00010111B
	call	GLCD_Write_Data
	movlw	00010101B
	call	GLCD_Write_Data
	movlw	00011101B
	call	GLCD_Write_Data
	movlw	00000000B
	call	GLCD_Write_Data
	return
;GLCD_6:
;	movlw	00011111B
;	call	GLCD_Write_Data
;	movlw	00010101B
;	call	GLCD_Write_Data
;	movlw	00011101B
;	call	GLCD_Write_Data
;	movlw	00000000B
;	call	GLCD_Write_Data
;	return
;GLCD_7:
;	movlw	00000001B
;	call	GLCD_Write_Data
;	movlw	00011001B
;	call	GLCD_Write_Data
;	movlw	00000111B
;	call	GLCD_Write_Data
;	movlw	00000000B
;	call	GLCD_Write_Data
;	return
;GLCD_8:	
;	movlw	00011111B
;	call	GLCD_Write_Data
;	movlw	00010101B
;	call	GLCD_Write_Data
;	movlw	00011111B
;	call	GLCD_Write_Data
;	movlw	00000000B
;	call	GLCD_Write_Data
;	return
;GLCD_9:
;	movlw	00000111B
;	call	GLCD_Write_Data
;	movlw	00000101B
;	call	GLCD_Write_Data
;	movlw	00011111B
;	call	GLCD_Write_Data
;	movlw	00000000B
;	call	GLCD_Write_Data
;	return
GLCD_0:
	movlw	11111000B
	call	GLCD_Write_Data
	movlw	10001000B
	call	GLCD_Write_Data
	movlw	11111000B
	call	GLCD_Write_Data
	movlw	00000000B
	call	GLCD_Write_Data
	return

GLCD_Partial_Bar:
	movwf	GLCD_bar_height, A
	movlw	9
	movwf	GLCD_counterx, A
GLCD_Bar_Loop:
	movf	GLCD_bar_height, W, A
	call	GLCD_Write_Data
	decfsz	GLCD_counterx, A
	bra	GLCD_Bar_Loop
	return
	
GLCD_Full_Bar:
	movlw	9
	movwf	GLCD_counterx, A
GLCD_Full_Bar_Loop:
	movlw	0xff
	call	GLCD_Write_Data
	decfsz	GLCD_counterx, A
	bra	GLCD_Full_Bar_Loop
	return
	
GLCD_Clear_Bar_Page:
	movlw	11
	movwf	GLCD_counterx, A
GLCD_Clear_Bar_Loop:	
	movlw	0x0
	call	GLCD_Write_Data
	decfsz	GLCD_counterx, A
	bra	GLCD_Clear_Bar_Loop
	return
	
GLCD_Clear_Bar:
	decf	GLCD_comp_counter, A
	movf	GLCD_comp_counter, W, A
	call	GLCD_Set_Page
	movlw	1
	cpfsgt	GLCD_comp_counter, A
	bra	GLCD_Clear_Bar
	call	GLCD_Clear_Bar_Page
	return
	
GLCD_Compare:
    	movf	h1, W, A
	movwf	temp_hex_h, A
	movf	l1, W, A
	movwf	temp_hex_l, A
	movff	GLCD_loc, GLCD_bar_loc, A
	movlw	0x6E
	movwf	GLCD_comp_l, A
	clrf	GLCD_comp_h, A
	movlw	0x07
	movwf	GLCD_comp_counter, A
GLCD_Compare_Loop:
	decf	GLCD_comp_counter, F, A
	movlw	0x32
	addwf	GLCD_comp_l, F, A
	movlw	0x00
	addwfc	GLCD_comp_h, F, A
	movf	GLCD_comp_h, W, A
	cpfsgt	temp_hex_h, A	    ;   ADC temperature higher byte (hex)
	goto	GLCD_Compare_Loop_Higher
	call	GLCD_Print_Full_Bar
	bra	GLCD_Compare_Loop
GLCD_Compare_Loop_Higher:
	cpfseq	temp_hex_h, A
	goto	GLCD_Compare_Small
GLCD_Compare_Loop_Lower:
	movf	GLCD_comp_l, W, A
	cpfsgt	temp_hex_l, A	    ;   ADC temperature lower byte (hex)
	bra	GLCD_Compare_Small
	call	GLCD_Print_Full_Bar
	bra	GLCD_Compare_Loop
GLCD_Compare_Small:
	movlw	0x32		    
	subwf	GLCD_comp_l, F, A   
	movlw	0x00
	subwfb	GLCD_comp_h, F, A
	movlw	00000000B
	movwf	GLCD_graph_line, A
	movf	GLCD_comp_h, W, A
	cpfsgt	temp_hex_h, A
	bra	GLCD_Compare_Remainder_Lower
	bra	GLCD_Compare_Small_Loop
GLCD_Compare_Remainder_Lower:
	cpfsgt	temp_hex_l, A
	goto	GLCD_Empty_Bar		    
GLCD_Compare_Small_Loop:
	movlw	00000001B
	addwf	GLCD_graph_line, F, A
	rrncf	GLCD_graph_line, F, A
	movlw	0x05
	addwf	GLCD_comp_l, F, A
	movlw	0x00
	addwfc	GLCD_comp_h, F, A
	movf	GLCD_comp_h, W, A
	cpfsgt	temp_hex_h, A
	bra	GLCD_Compare_Small_Loop_Lower
	bra	GLCD_Compare_Small_Loop
GLCD_Compare_Small_Loop_Lower:
	movf	GLCD_comp_l, W, A
	cpfslt	temp_hex_l, A
	bra	GLCD_Compare_Small_Loop
	movf	GLCD_comp_counter, W, A
	call	GLCD_Set_Page
	movf	GLCD_bar_loc, W, A  ; not sure if you already did this
	call	GLCD_Set_Y  ; sets Y location to the same as start of bar
	movf	GLCD_graph_line, W, A
	call	GLCD_Partial_Bar
GLCD_Empty_Bar:
	movf	GLCD_bar_loc, W, A
	call	GLCD_Set_Y
	call	GLCD_Clear_Bar
	return

GLCD_Print_Full_Bar:
	movf	GLCD_comp_counter, W, A
	call	GLCD_Set_Page
	movf	GLCD_bar_loc, W, A  ; not sure if you already did this
	call	GLCD_Set_Y  ; sets Y location to the same as start of bar
	call	GLCD_Full_Bar ; prints one full block
	return

GLCD_Update_Bars_Setup:
	lfsr	1, GLCD_Bar_Values
	movlw	21
	movwf	GLCD_update_bars_counter, A
GLCD_Update_Bars_Setup_Loop:
	clrf	POSTINC1, A
	decfsz	GLCD_update_bars_counter, A
	bra	GLCD_Update_Bars_Setup_Loop
	return

GLCD_Update_Bars:
	lfsr	1, GLCD_Bar_Values
	movf	POSTINC1
	nop
	movf	POSTINC1
	nop
	lfsr	2, GLCD_Bar_Values
	movlw	0x02
	movwf	GLCD_update_bars_inc, A
	movlw	0x0A
	movwf	GLCD_update_bars_counter, A
	call	GLCD_Left
	movlw	9
	call	GLCD_Set_Y
GLCD_Update_Bars_Loop:
	movlw	0x05
	subwf	GLCD_update_bars_counter, W, A	
	bz	GLCD_Update_Bars_Page_Right
GLCD_Update_Bars_Loop_Main:
	movf	GLCD_update_bars_inc, W, A
	movff	POSTINC1, GLCD_update_bars_new, A
	nop
	;sublw	0x02
	movff	GLCD_update_bars_new, INDF2
	nop
	movff	POSTINC2, h1, A
	nop
	;incf	GLCD_update_bars_inc, A
	
	movf	GLCD_update_bars_inc, W, A
	movff	POSTINC1, GLCD_update_bars_new, A
	nop
	;sublw	0x02
	movff	GLCD_update_bars_new, INDF2
	nop
	movff	POSTINC2, l1, A
	nop
	;incf	GLCD_update_bars_inc, A
	
	decfsz	GLCD_update_bars_counter, A
	goto	GLCD_Update_Bars_Draw
	goto	GLCD_Update_Bars_New_Temp
GLCD_Update_Bars_Draw:
	call	GLCD_Compare
	goto	GLCD_Update_Bars_Loop
GLCD_Update_Bars_Page_Right:
	call	GLCD_Right
	movlw	0
	call	GLCD_Set_Y
	goto	GLCD_Update_Bars_Loop_Main
GLCD_Update_Bars_New_Temp:
	call	Avg16val_and_Calibrate
	movlw	0x0E
	movff	h1, POSTINC2
	nop
	movlw	0x0F
	movff	l1, POSTINC2
	nop
	call	GLCD_Compare
	movlw	0
	goto	current_temperature

end







