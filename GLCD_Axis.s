#include <xc.inc>
extrn   GLCD_Setup, GLCD_Write_Data, GLCD_Tt, GLCD_m, GLCD_p, GLCD_Right, GLCD_c
extrn	GLCD_Left, GLCD_Both, GLCD_Set_Y, GLCD_Set_Page, GLCD_Clear_Display
extrn	GLCD_Space, GLCD_I, GLCD_lE, GLCD_M, GLCD_axis, GLCD_Tb ; GLCD_Bar
extrn	GLCD_3,GLCD_0,GLCD_5;,GLCD_1,GLCD_2,GLCD_4,GLCD_6,GLCD_7,GLCD_8,GLCD_9
extrn	GLCD_Compare, GLCD_Full_Bar, GLCD_bc
 
global	GLCD_Setup_Axis

PSECT	udata_acs_ovr,space=1,ovrld,class=COMRAM
page_counter:	ds 1	; reserve 1 byte for counting through nessage	

    
    
psect	glcd_axis_code, class=CODE
GLCD_Setup_Axis:
temperature:
	call	GLCD_Left
	call	GLCD_3
	call	GLCD_5
	movlw	0x0
	call	GLCD_Write_Data
	call	GLCD_c
axis:	
	movlw	1
	movwf	page_counter, A
Axis_Loop:
	movf	page_counter, W, A
	call	GLCD_Set_Page
	movlw	0
	call	GLCD_Set_Y
	call	GLCD_axis
	incf	page_counter, A
	movlw	7
	cpfseq	page_counter, A
	bra	Axis_Loop
bottom_line:
	movlw	7
	call	GLCD_Set_Page
	movlw	0
	call	GLCD_Set_Y
	movlw	00000001B
	call	GLCD_Write_Data
	movlw	10001001B
	call	GLCD_Write_Data
	movlw	11111001B
	call	GLCD_Write_Data
	movlw	10000001B
	call	GLCD_Write_Data
	movlw	00000001B
	call	GLCD_Write_Data
	call	GLCD_0
	call	GLCD_bc
time:
	movlw	7
	call	GLCD_Set_Page
	movlw	57
	call	GLCD_Set_Y
	call	GLCD_Tb
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
current_temperature_setup:
	movlw	0
	call	GLCD_Set_Page
	call	GLCD_Set_Y
	call	GLCD_Tt
	call	GLCD_m
	movlw	0x0
	call	GLCD_Write_Data
	call	GLCD_p
	movlw	36
	call	GLCD_Set_Y
	call	GLCD_c
	return

