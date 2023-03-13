#include <xc.inc>
    
global	Mult_16x16,   Mult_24x8, DCon4Dig, Convert_Hex_ASCII
global	u1, h1, l1, h2, l2, DCon4DigH, DCon4DigL
    
psect	udata_acs   ; named variables in access ram
u1:	ds 1
h1:	ds 1
l1:	ds 1
h2:	ds 1
l2:	ds 1
DCon4DigH: ds 1
DCon4DigL: ds 1
    
PSECT	udata_acs_ovr,space=1,ovrld,class=COMRAM
res3:	ds 1
res2:	ds 1
res1:	ds 1
res0:	ds 1
hex_asc_temp: ds 1
    kl EQU 0x8A
    kh EQU 0x41
    
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

DCon4Dig: ; requires l1 and h1 to be set before calling
	movff	ADRESH, h1, A
	movff	ADRESL, l1, A
    
	movlw	kl
	movwf	l2, A
	movlw	kh
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
	
	
	






