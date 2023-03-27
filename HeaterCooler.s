#include <xc.inc>

global	Heater_Setup, OnOff_Controller, Fan_PWM_Interrupt_Setup
global	Fan_PWM_Interrupt, P_Controller
    
extrn	TempVal_Hex_H, TempVal_Hex_L, GoalTemp_Hex_H, GoalTemp_Hex_L
extrn	H1, L1, H2, L2, res0, res1

psect	udata_acs   ; named variables in access ram
OnOff_Switch:	    ds 1 ; bit 0 - On/Off Controller
Proportional_Bit:   ds 1
Proportional_Bit_Interrupt:	ds 1
P_Controller_OnOff_Switch:	ds 1
PWM_Interrupt_Counter_Period:   ds 1
PWM_Interrupt_Counter_Duty:	ds 1


	
PSECT	udata_acs_ovr,space=1,ovrld,class=COMRAM
proportional_L: ds 1
proportional_H:	ds 1
integral_L:	ds 1
integral_H:	ds 1
derivative_L:	ds 1
derivative_H:	ds 1
res_L:		ds 1
res_H:		ds 1
	    
	    OnOff_Threshold EQU	10  ;	threshold to activate is 1 degree
	    K_P_L EQU 0x00
	    K_P_H EQU 0x00
	    K_I_L EQU 0x00
	    K_I_H EQU 0x00
	    K_D_L EQU 0x00
	    K_D_H EQU 0x00
 
	    IN0	  EQU 0
	    IN1	  EQU 1
	    
psect	heater_cooler_code,class=CODE

Heater_Setup:
	clrf	LATH, A
	clrf	TRISH, A
	return
 
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
	btfsc	LATH, 0, A
	bra	Controller_On
	bra	Controller_Off
Controller_On:
	movff	TempVal_Hex_L, L1, A
	movff	TempVal_Hex_H, H1, A
	movff	GoalTemp_Hex_L, L2, A
	movff	GoalTemp_Hex_H, H2, A
	bra	Compare_Temp_vs_Goal
Controller_Off:
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
	btg	LATH, 0, A
	return
	

P_Controller:
	movff	TempVal_Hex_L, L2, A
	movff	TempVal_Hex_H, H2, A
	movff	GoalTemp_Hex_L, L1, A
	movff	GoalTemp_Hex_H, H1, A
	call	Subtraction_16bit
	bn	P_Controller_Turn_Off
P_Controller_Turn_On:
	movff	res0, Proportional_Bit, A
	btfsc	TMR0IE
	return
	bsf	TMR0IE
	clrf	PWM_Interrupt_Counter_Duty, A
	clrf	PWM_Interrupt_Counter_Period, A
	return
P_Controller_Turn_Off:
	clrf	Proportional_Bit, A
	btfss	TMR0IE
	return
	bcf	TMR0IE
	clrf	PWM_Interrupt_Counter_Duty, A
	clrf	PWM_Interrupt_Counter_Period, A
	return
	
Fan_PWM_Interrupt_Setup:
	movlw	11000010B   ; interrupts every 128us
	movwf	T0CON, A
	bsf	GIE
	movlw	0x02
	movwf	Proportional_Bit, A
	movwf	Proportional_Bit_Interrupt, A
	clrf	PWM_Interrupt_Counter_Duty, A
	clrf	PWM_Interrupt_Counter_Period, A
	bsf	TMR0IE
	return
	
	
Fan_PWM_Interrupt:
	incf	PWM_Interrupt_Counter_Duty, A
	incf	PWM_Interrupt_Counter_Period, A
	clrf	WREG, A
	cpfsgt	Proportional_Bit_Interrupt, A
	bra	Fan_PWM_Interrupt_Turn_Off_Fan
	movf	Proportional_Bit_Interrupt, W, A
	cpfseq	PWM_Interrupt_Counter_Duty, A
	bra 	Fan_PWM_Interrupt_Period
Fan_PWM_Interrupt_Turn_Off_Fan:
 	bcf	LATH, 0, A
Fan_PWM_Interrupt_Period:
	movlw	31
	cpfseq	PWM_Interrupt_Counter_Period, A
	bra	Fan_PWM_Interrupt_Reset
Fan_PWM_Interrupt_Turn_On_Fan:
	bsf	LATH, 0, A
	movff	Proportional_Bit, Proportional_Bit_Interrupt, A
	clrf	PWM_Interrupt_Counter_Duty, A
	clrf	PWM_Interrupt_Counter_Period, A
Fan_PWM_Interrupt_Reset:
	bcf	TMR0IF
	retfie	f

	
	
