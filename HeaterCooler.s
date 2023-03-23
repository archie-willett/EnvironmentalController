#include <xc.inc>

extrn	TempVal_Hex_H, TempVal_Hex_L, GoalTemp_Hex_H, GoalTemp_Hex_L
extrn	H1, L1, H2, L2, res0, res1

psect	udata_acs   ; named variables in access ram
OnOff_Switch:	    ds 1 ; bit 0 - On/Off Controller, bit 1 - P Controller
Proportional_Bit:   ds 1
P_Controller_OnOff_Switch: ds 1

	
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
 
	    DEN	  EQU 0
	    IN0	  EQU 1
	    
psect	heater_cooler_code,class=CODE

;Heater_Setup:
;	bcf	TRISJ, IN0, A
;	bsf	TRISJ, DEN, A
;	return
 
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
	btfsc	OnOff_Switch, 1, A
	bra	Controller_On
	bra	Controller_Off
Controller_Off:
	movff	TempVal_Hex_L, L1, A
	movff	TempVal_Hex_H, H1, A
	movff	GoalTemp_Hex_L, L2, A
	movff	GoalTemp_Hex_H, H2, A
	bra	Compare_Temp_vs_Goal
Controller_On:
	movff	TempVal_Hex_L, L2, A
	movff	TempVal_Hex_H, H2, A
	movff	GoalTemp_Hex_L, L1, A
	movff	GoalTemp_Hex_H, H1, A
	bra	Compare_Temp_vs_Goal
Compare_Temp_vs_Goal:		    ;Off-On when Temp < GoalTemp - 2
	movlw	OnOff_Threshold	    ;On-Off when Temp > GoalTemp + 2
	subwf	L2, F, A
	clrf	WREG, A
	subwfb	H2, F, A
	call	Subtraction_16bit
	bnn	Switch_OnOff
	return
Switch_OnOff:
	btg	OnOff_Switch, 0, A
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
P_Controller_Turn_Off:
	clrf	Proportional_Bit, A
	return
	
	



