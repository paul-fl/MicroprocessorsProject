#include <xc.inc>
    
global  UART_Setup, UART_Transmit_Message, UART_Transmit_Byte, UART_Write_Hex

psect	udata_acs   ; reserve data space in access ram
UART_counter: ds    1	    ; reserve 1 byte for variable UART_counter
UART_tmp:  ds	1
UART_hex_tmp:	ds  1
    
psect	uart_code, class=CODE
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
    call    UART_Write_Hex
    decfsz  UART_counter, A
    bra	    UART_Loop_message
    return

UART_Transmit_Byte:	    ; Transmits byte stored in W
    btfss   TX1IF	    ; TX1IF is set when TXREG1 is empty
    bra	    UART_Transmit_Byte
    movwf   TXREG1, A
    return

UART_Write_Hex:			; Writes byte stored in W as hex
	movwf	UART_hex_tmp, A
	swapf	UART_hex_tmp, W, A	; high nibble first
	call	UART_Hex_Nib
	movf	UART_hex_tmp, W, A	; then low nibble
UART_Hex_Nib:			; writes low nibble as hex character
	andlw	0x0F
	movwf	UART_tmp, A
	movlw	0x0A
	cpfslt	UART_tmp, A
	addlw	0x07		; number is greater than 9 
	addlw	0x26
	addwf	UART_tmp, W, A
	call	UART_Transmit_Byte ; write out ascii
	return	
    
end
