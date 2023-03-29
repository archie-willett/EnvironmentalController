#include <xc.inc>
    
global	Mult_16x16,   Mult_24x8, DCon4Dig, Convert_Hex_ASCII
global	Avg16val_and_Calibrate
global	U1, H1, L1, H2, L2, res0, res1
global	TempVal_Dec_H, TempVal_Dec_L, TempVal_Hex_H, TempVal_Hex_L
global	Convert_GoalTemp_Dec2Hex, GoalTemp_Hex_H, GoalTemp_Hex_L
global	Collect_and_Process_Temperature, Collect_Initial_Temperature

extrn	ADC_Read
extrn	delay_x1ms
extrn	GoalTemp_Dec_H, GoalTemp_Dec_L ; , Print
extrn	GLCD_Print_Goal_Temperature, GLCD_Current_Temperature

    
psect	udata_acs   ; named variables in access ram
U1:	ds 1
H1:	ds 1
L1:	ds 1
H2:	ds 1
L2:	ds 1
TempVal_Dec_H: ds 1
TempVal_Dec_L: ds 1
TempVal_Hex_H:	ds 1
TempVal_Hex_L:	ds 1
GoalTemp_Hex_L:	ds 1
GoalTemp_Hex_H:	ds 1
    
PSECT	udata_acs_ovr,space=1,ovrld,class=COMRAM
res3:	ds 1
res2:	ds 1
res1:	ds 1
res0:	ds 1
avg_count: ds 1
avg_res_H: ds 1
avg_res_L: ds 1
hex_asc_temp: ds 1
dec_hex_temp: ds 1
    dec_L   EQU 0x8A
    dec_H   EQU 0x41
    cal_L   EQU 0x66
    cal_H   EQU 0x01
    
psect	multiplier_code, class=CODE

Mult_16x16:
	movf	L1, W, A
	mulwf	L2, A
	movff	PRODH, res1, A
	movff	PRODL, res0, A
	 
	movf	H1, W, A
	mulwf	H2, A
	movff	PRODH, res3, A
	movff	PRODL, res2, A
	   
	movf	L1, W, A
	mulwf	H2, A
	movf	PRODL, W, A
	addwf	res1, F, A
	movf	PRODH,	W, A
	addwfc	res2, F, A
	clrf	WREG, A
	addwfc	res3, F, A
	
	movf	H1, W, A
	mulwf	L2, A
	movf	PRODL, W, A
	addwf	res1, F, A
	movf	PRODH,	W, A
	addwfc	res2, F, A
	clrf	WREG, A
	addwfc	res3, F, A
	
	return

Mult_24x8:
	movf	L1, W, A
	mulwf	L2, A
	movff	PRODH, res1, A
	movff	PRODL, res0, A
	  
	movf	U1, W, A
	mulwf	L2, A
	movff	PRODH, res3, A
	movff	PRODL, res2, A
	
	movf	H1, W, A
	mulwf	L2, A
	movf	PRODL, W, A
	addwf	res1, F, A
	movf	PRODH,	W, A
	addwfc	res2, F, A
	clrf	WREG, A
	addwfc	res3, F, A
	
	return

Collect_and_Process_Temperature:
	call	Avg16val_and_Calibrate
	call	DCon4Dig
	return

Collect_Initial_Temperature:
	call	Collect_and_Process_Temperature
	movff	TempVal_Dec_H, GoalTemp_Dec_H, A
	movff	TempVal_Dec_L, GoalTemp_Dec_L, A
	movff	TempVal_Hex_H, GoalTemp_Hex_H, A
	movff	TempVal_Hex_L, GoalTemp_Hex_L, A
	call	GLCD_Print_Goal_Temperature
	call	GLCD_Current_Temperature
	return
	
DCon4Dig: 
	movff	TempVal_Hex_H, H1, A
	movff	TempVal_Hex_L, L1, A
	movlw	dec_L
	movwf	L2, A
	movlw	dec_H
	movwf	H2, A
	call	Mult_16x16
	
	movlw	0x10
	mulwf	res3, A
	movff	PRODL, TempVal_Dec_H, A
	;
	movff	res2, U1, A
	movff	res1, H1, A
	movff	res0, L1, A
	movlw	0x0A
	movwf	L2, A
	call	Mult_24x8
	
	movf	res3, W, A
	addwf	TempVal_Dec_H, F, A
	;
	movff	res2, U1, A
	movff	res1, H1, A
	movff	res0, L1, A
	call	Mult_24x8
	
	movlw	0x10
	mulwf	res3, A
	movff	PRODL, TempVal_Dec_L, A
	
	movff	res2, U1, A
	movff	res1, H1, A
	movff	res0, L1, A
	call	Mult_24x8
	
	movf	res3, W, A
	addwf	TempVal_Dec_L, F, A
	
	return

Convert_Hex_ASCII:
	movwf	hex_asc_temp, A
	movlw	0x0A
	cpfslt	hex_asc_temp, A
	addlw	0x07		; number is greater than 9 
	addlw	0x26
	addwf	hex_asc_temp, W, A
	return
	
Avg16val_and_Calibrate:
	clrf	H1, A
	clrf	L1, A
	movlw	0x10
	movwf	avg_count, A
	lfsr	0, 0x10
	lfsr	1, 0x20
Average_loop:
	call	ADC_Read
	movlw	100
	call	delay_x1ms
	movf	ADRESL, W, A
	nop
	addwf	L1, F, A
	movf	ADRESH, W, A
	nop
	addwfc	H1, F, A
	decfsz	avg_count, A
	bra	Average_loop	
Divide_x16:
	movlw	0xF0
	andwf	L1, F, A
	swapf	L1, F, A
	swapf	H1, F, A
	andwf	H1, W, A
	addwf	L1, F, A
	movlw	0x0F
	andwf	H1, F, A
Calibrate:
	movlw	cal_L
	movwf	L2, A
	movlw	cal_H
	movwf	H2, A
	call	Mult_16x16
	movff	res2, TempVal_Hex_H, A
	movff	res1, TempVal_Hex_L, A
	return
	
Dec2Hex_Converter:
	movlw	100
	mulwf	H1, A
	movff	PRODL, res0, A
	movff	PRODH, res1, A
	
	movff	L1, dec_hex_temp, A
	swapf	dec_hex_temp, F, A
	movlw	0x0F
	andwf	dec_hex_temp, F, A
	movlw	10
	mulwf	dec_hex_temp, A
	movf	PRODL, W, A
	addwf	res0, F, A
	movf	PRODH, W, A
	addwfc	res1, F, A
	
	movff	L1, dec_hex_temp, A
	movlw	0x0F
	andwf	dec_hex_temp, W, A
	addwf	res0, F, A
	clrf	WREG, A
	addwfc	res1, F, A
	return

Convert_GoalTemp_Dec2Hex:
	movff	GoalTemp_Dec_H, H1, A
	movff	GoalTemp_Dec_L, L1, A
	call	Dec2Hex_Converter
	movff	res0, GoalTemp_Hex_L, A
	movff	res1, GoalTemp_Hex_H, A
	return
