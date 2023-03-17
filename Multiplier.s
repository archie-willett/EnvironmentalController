#include <xc.inc>
    
global	Mult_16x16,   Mult_24x8, DCon4Dig, Convert_Hex_ASCII
global	Avg16val_and_Calibrate
global	u1, h1, l1, h2, l2, DCon4DigH, DCon4DigL
    
extrn	ADC_Read
extrn	delay_x1ms

    
psect	udata_acs   ; named variables in access ram
u1:	ds 1
h1:	ds 1
l1:	ds 1
h2:	ds 1
l2:	ds 1
DCon4DigH: ds 1
DCon4DigL: ds 1
MultiplierResult_High:	ds 1
MultiplierResult_Low:	ds 1
    
PSECT	udata_acs_ovr,space=1,ovrld,class=COMRAM
res3:	ds 1
res2:	ds 1
res1:	ds 1
res0:	ds 1
avg_count: ds 1
avg_res_h: ds 1
avg_res_l: ds 1
hex_asc_temp: ds 1
    dec_l   EQU 0x8A
    dec_h   EQU 0x41
    cal_l   EQU 0x66
    cal_h   EQU 0x01
    
psect	multiplier_code, class=CODE

Mult_16x16:
	movf	l1, W, A
	mulwf	l2, A
	movff	PRODH, res1, A
	movff	PRODL, res0, A
	 
	movf	h1, W, A
	mulwf	h2, A
	movff	PRODH, res3, A
	movff	PRODL, res2, A
	   
	movf	l1, W, A
	mulwf	h2, A
	movf	PRODL, W, A
	addwf	res1, F, A
	movf	PRODH,	W, A
	addwfc	res2, F, A
	clrf	WREG, A
	addwfc	res3, F, A
	
	movf	h1, W, A
	mulwf	l2, A
	movf	PRODL, W, A
	addwf	res1, F, A
	movf	PRODH,	W, A
	addwfc	res2, F, A
	clrf	WREG, A
	addwfc	res3, F, A
	
	return

Mult_24x8:
	movf	l1, W, A
	mulwf	l2, A
	movff	PRODH, res1, A
	movff	PRODL, res0, A
	  
	movf	u1, W, A
	mulwf	l2, A
	movff	PRODH, res3, A
	movff	PRODL, res2, A
	
	movf	h1, W, A
	mulwf	l2, A
	movf	PRODL, W, A
	addwf	res1, F, A
	movf	PRODH,	W, A
	addwfc	res2, F, A
	clrf	WREG, A
	addwfc	res3, F, A
	
	return

DCon4Dig: 
	;movff	ADRESH, h1, A	;switched which lines were commented in this block
	;movff	ADRESL, l1, A
	movlw	dec_l
	movwf	l2, A
	movlw	dec_h
	movwf	h2, A
	call	Mult_16x16
	
	movlw	0x10
	mulwf	res3, A
	movff	PRODL, DCon4DigH, A
	;
	movff	res2, u1, A
	movff	res1, h1, A
	movff	res0, l1, A
	movlw	0x0A
	movwf	l2, A
	call	Mult_24x8
	
	movf	res3, W, A
	addwf	DCon4DigH, F, A
	;
	movff	res2, u1, A
	movff	res1, h1, A
	movff	res0, l1, A
	call	Mult_24x8
	
	movlw	0x10
	mulwf	res3, A
	movff	PRODL, DCon4DigL, A
	
	movff	res2, u1, A
	movff	res1, h1, A
	movff	res0, l1, A
	call	Mult_24x8
	
	movf	res3, W, A
	addwf	DCon4DigL, F, A
	
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
	clrf	h1, A
	clrf	l1, A
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
	;movwf	POSTINC1, A
	;movlw	0xA7
	addwf	l1, F, A
	movf	ADRESH, W, A
	nop
	;movwf	POSTINC0, A
	;movlw	0x01
	addwfc	h1, F, A
	decfsz	avg_count, A
	bra	Average_loop	
Divide_x16:
	movlw	0xF0
	andwf	l1, F, A
	swapf	l1, F, A
	swapf	h1, F, A
	andwf	h1, W, A
	addwf	l1, F, A
	movlw	0x0F
	andwf	h1, F, A
Calibrate:
	movlw	cal_l
	movwf	l2, A
	movlw	cal_h
	movwf	h2, A
	call	Mult_16x16
	movff	res2, h1, A
	movff	res1, l1, A
;	movlw	cal_offset_l
;	subwfb	h1, F, A
	return
	
	
	






