	#include <xc.inc>
extrn  GLCD_Setup, GLCD_Write_Data, GLCD_T, GLCD_m, GLCD_p, GLCD_Right, GLCD_c
extrn	GLCD_Left, GLCD_Both, GLCD_Set_Y, GLCD_Set_Page, GLCD_Clear_Display
extrn	GLCD_Space, GLCD_I, GLCD_lE, GLCD_M, GLCD_axis
extrn	GLCD_0,GLCD_1,GLCD_2,GLCD_3,GLCD_4,GLCD_5,GLCD_6,GLCD_7,GLCD_8,GLCD_9

psect	code, abs
	
main:
	org	0x0
	goto	setup

	org	0x100		    ; Main code starts here at address 0x100
setup:
	call	GLCD_Setup
temperature:
	call	GLCD_Left
	call	GLCD_T
	call	GLCD_m
	movlw	0x0
	call	GLCD_Write_Data
	call	GLCD_p
	movlw	0x0
	call	GLCD_Write_Data
	call	GLCD_Write_Data
	call	GLCD_Write_Data
	call	GLCD_c
axis:
	movlw	1
	call	GLCD_Set_Page
	movlw	0
	call	GLCD_Set_Y
	call	GLCD_axis
	movlw	2
	call	GLCD_Set_Page
	movlw	0
	call	GLCD_Set_Y
	call	GLCD_axis
time:
	movlw	7
	call	GLCD_Set_Page
	movlw	57
	call	GLCD_Set_Y
	call	GLCD_T
	movlw	0x0
	call	GLCD_Write_Data
	call	GLCD_I
	movlw	0x0
	call	GLCD_Right
	movlw	7
	call	GLCD_Set_Page
	movlw	0x0
	call	GLCD_Set_Y
	call	GLCD_Write_Data
	call	GLCD_M
	movlw	0x0
	call	GLCD_Write_Data
	call	GLCD_lE
	
wait:	
	movlw	10
	bra	wait

	end	main
