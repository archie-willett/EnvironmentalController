#include <xc.inc>
    
global  UART_Setup, UART_Transmit_Message, UART_Send_Temperature
extrn	Convert_Hex_ASCII, DCon4DigH, DCon4DigL

psect	udata_acs   ; reserve data space in access ram
UART_counter: ds    1	    ; reserve 1 byte for variable UART_counter

PSECT	udata_acs_ovr,space=1,ovrld,class=COMRAM
UART_hex_tmp:	    ds 1    ; reserve 1 byte for variable UART_hex_tmp
UART_tmp:	    ds 1
UART_high_low_nib:  ds 1


psect	uart_code,class=CODE
UART_Setup:
    bsf	    SPEN	; enable
    bcf	    SYNC	; synchronous
    bcf	    BRGH	; slow speed
    bsf	    TXEN	; enable transmit
    bcf	    BRG16	; 8-bit generator only
    movlw   103		; gives 9600 Baud rate (actually 9615)
    movwf   SPBRG1, A	; set baud rate
    bsf	    TRISC, PORTC_TX1_POSN, A	; TX1 pin is output on RC6 pin
					; must set TRISC6 to 1
    return

UART_Transmit_Message:	    ; Message stored at FSR2, length stored in W
    movwf   UART_counter, A
UART_Loop_message:
    movf    POSTINC2, W, A
    call    UART_Transmit_Byte
    decfsz  UART_counter, A
    bra	    UART_Loop_message
    return

UART_Transmit_Byte:	    ; Transmits byte stored in W
    btfss   TX1IF	    ; TX1IF is set when TXREG1 is empty
    bra	    UART_Transmit_Byte
    movwf   TXREG1, A
    return
    
UART_Send_Temperature:
    movf    DCon4DigH, W, A
    call    UART_Write_Hex_Nib_Low
    movf    DCon4DigL, W, A
    call    UART_Write_Hex_Nib_High
    movlw   '.'
    call    UART_Transmit_Byte
    movf    DCon4DigL, W, A
    call    UART_Write_Hex_Nib_Low
    movlw   0xBA
    call    UART_Transmit_Byte
    movlw   'C'
    call    UART_Transmit_Byte
    movlw   0x0D
    call    UART_Transmit_Byte
    movlw   0x0A
    call    UART_Transmit_Byte
    return
    

UART_Write_Hex_Nib_High:
    movwf   UART_hex_tmp, A
    movlw   0x01
    movwf   UART_high_low_nib, A
    bra	    UART_Write_Hex
UART_Write_Hex_Nib_Low:
    movwf   UART_hex_tmp, A
    movlw   0x00
    movwf   UART_high_low_nib, A
    bra	    UART_Write_Hex
UART_Write_Hex_Byte:
    movwf   UART_hex_tmp, A
    movlw   0x02
    movwf   UART_high_low_nib, A
    bra	    UART_Write_Hex
UART_Write_Hex:
    movlw   0x01
    cpfseq  UART_high_low_nib, A
    call    UART_Hex_Nib_Low
    movlw   0x00
    cpfseq  UART_high_low_nib, A
    call    UART_Hex_Nib_High
    return
UART_Hex_Nib_High:
    swapf   UART_hex_tmp, W, A
    call    UART_Hex_Nib
    return
UART_Hex_Nib_Low:
    movf    UART_hex_tmp, W, A
    call    UART_Hex_Nib
    return
UART_Hex_Nib:
    andlw   0x0F
    call    Convert_Hex_ASCII
    call    UART_Transmit_Byte
    return
end



