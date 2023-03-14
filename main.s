	#include <xc.inc>
extrn  GLCD_Setup, GLCD_Write_Data, GLCD_T, GLCD_m, GLCD_p, GLCD_Right, GLCD_c
extrn	GLCD_Left, GLCD_Both, GLCD_Set_Y, GLCD_Set_Page, GLCD_Clear_Display
extrn	GLCD_Space, GLCD_I, GLCD_lE, GLCD_M
extrn	GLCD_0,GLCD_1,GLCD_2,GLCD_3,GLCD_4,GLCD_5,GLCD_6,GLCD_7,GLCD_8,GLCD_9

psect	code, abs
	
main:
	org	0x0
	goto	setup

	org	0x100		    ; Main code starts here at address 0x100
setup:
	call	GLCD_Setup
	call	GLCD_Right
	movlw	0x28
	call	GLCD_Set_Y
graph:
	call	GLCD_T
	call	GLCD_m
	movlw	0x0
	call	GLCD_Write_Data
	call	GLCD_p
	;movlw	3
	;call	GLCD_Space
	movlw	0x0
	call	GLCD_Write_Data
	call	GLCD_Write_Data
	call	GLCD_Write_Data
	call	GLCD_c
time:
	call	GLCD_Left
	movlw	3
	call	GLCD_Set_Y
	call	GLCD_T
	movlw	0x0
	call	GLCD_Write_Data
	call	GLCD_I
	movlw	0x0
	call	GLCD_Write_Data
	call	GLCD_M
	movlw	0x0
	call	GLCD_Write_Data
	call	GLCD_lE
numbers:
	movlw	1
	call	GLCD_Set_Page
	movlw	0
	call	GLCD_Set_Y
	call	GLCD_0
	movlw	0x0
	call	GLCD_Write_Data
	call	GLCD_1
	movlw	0x0
	call	GLCD_Write_Data
	call	GLCD_2
	movlw	0x0
	call	GLCD_Write_Data
	call	GLCD_3
	movlw	0x0
	call	GLCD_Write_Data
	call	GLCD_4
	movlw	0x0
	call	GLCD_Write_Data
	call	GLCD_5
	movlw	0x0
	call	GLCD_Write_Data
	call	GLCD_6
	movlw	0x0
	call	GLCD_Write_Data
	call	GLCD_7
	movlw	0x0
	call	GLCD_Write_Data
	call	GLCD_8
	movlw	0x0
	call	GLCD_Write_Data
	call	GLCD_9
	
wait:	
	movlw	10
	bra	wait

	end	main
