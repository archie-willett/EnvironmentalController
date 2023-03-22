#include <xc.inc>


extrn	TempVal_Hex_H, TempVal_Hex_L, GoalTemp_Hex_H, GoalTemp_Hex_L
extrn	H1, L1, H2, L2

psect	udata_acs   ; named variables in access ram
OnOff_Bit:	    ds 1
Proportional_Bit:   ds 1
	
	
PSECT	udata_acs_ovr,space=1,ovrld,class=COMRAM
proportional_L: ds 1
proportional_H:	ds 1
integral_L:	ds 1
integral_H:	ds 1
derivative_L:	ds 1
derivative_H:	ds 1
res_L:		ds 1
res_H:		ds 1
	    
	    OnOff_Threshold EQU	20  ;	threshold to activate is 2 degrees
	    K_P_L EQU 0x00
	    K_P_H EQU 0x00
	    K_I_L EQU 0x00
	    K_I_H EQU 0x00
	    K_D_L EQU 0x00
	    K_D_H EQU 0x00
	    
psect	heater_cooler_code,class=CODE

Addition_16bit:
	movf	L1, W, A
	addwf	L2, W, A
	movwf	res0, A
	movf	H1, W, A
	addwfc	H2, W, A
	movwf	res1, A
	return
	
Subtraction_16bit:
	movf	L1, W, A
	subwf	L2, W, A
	movwf	res0, A
	movf	H1, W, A
	subwfb	H2, W, A
	movwf	res1, A
	return

OnOff_Controller:
	movlw	0
	cpfseq	OnOff_Bit
	bra	Controller_On
	bra	Controller_Off
Controller_Off:
	movff	TempVal_Hex_L, L2, A
	movff	TempVal_Hex_H, H2, A
	movff	GoalTemp_Hex_L, L1, A
	movff	GoalTemp_Hex_H, H1, A
	bra	Compare_Temp_vs_Goal
Controller_On:
	movff	TempVal_Hex_L, L1, A
	movff	TempVal_Hex_H, H1, A
	movff	GoalTemp_Hex_L, L2, A
	movff	GoalTemp_Hex_H, H2, A
	bra	Compare_Temp_vs_Goal
Compare_Temp_vs_Goal:
	movlw	OnOff_Threshold
	addwf	L1, F, A
	clrf	WREG, A
	addwfc	H1, F, A
	call	Subtraction_16bit
	bn	OnOff_Switch
	return
OnOff_Switch:
	btg	OnOff_Bit, 0, A
	return
	

P_Controller:
	movff	TempVal_Hex_L, L1, A
	movff	TempVal_Hex_H, H1, A
	movff	GoalTemp_Hex_L, L2, A
	movff	GoalTemp_Hex_H, H2, A
	call	Subtraction_16bit
	bn	P_Controller_Off
	movff	res0, Proportional_Bit, A
	return
P_Controller_Off:
	clrf	Proportional_Bit, A
	return
	
	



