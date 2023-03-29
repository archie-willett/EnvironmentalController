#include <xc.inc>
global	current_temperature
	
extrn   GLCD_Setup, UART_Setup, ADC_Setup, GLCD_Update_Bars_Setup
extrn	GLCD_Setup_Axis, GLCD_Temp_Val_setup
extrn	UART_Send_Temperature, GLCD_Current_Temperature, GLCD_Update_Bars
extrn	Collect_and_Process_Temperature, Collect_Initial_Temperature
extrn	KeyPad_check, KeyPad_init
extrn	Heater_Setup, OnOff_Controller, P_Controller, Fan_PWM_Interrupt

	
psect	code, abs
	
main:
	org	0x0
	goto	setup
	org	0x100		    
setup:
	call	GLCD_Setup
	call	ADC_Setup
	call	UART_Setup
	call	GLCD_Setup_Axis
	call	GLCD_Temp_Val_setup
	call	GLCD_Update_Bars_Setup
	call	KeyPad_init
	call	Heater_Setup
	call	Collect_Initial_Temperature
current_temperature:
	call	OnOff_Controller
	call	KeyPad_check
	call	Collect_and_Process_Temperature
	call	UART_Send_Temperature
	call	GLCD_Current_Temperature
bar:
	goto	GLCD_Update_Bars
	movlw	0
	goto	current_temperature
	
wait:	
	movlw	10
	bra	wait

	end	main
