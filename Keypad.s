#include <xc.inc>
    
global  Keypad_Setup, Keypad_Read

psect	udata_acs   ; reserve data space in access ram
Keypad_counter: ds    1	    ; reserve 1 byte for variable UART_counter
Keypad_Value: ds 1
Keypad_Value_Row: ds  1
Keypad_Value_Col: ds  1
combineddata: ds 1
    
    
psect	Keypad_code,class=CODE
Keypad_Setup:
    banksel	PADCFG1
    bsf		REPU
    clrf	LATE, A		; Write 0s to the LATE
    clrf	TRISD
    return
    
Keypad_Read:
    call	Keypad_Setup_Row
    call	Keypad_Read_Row
    call	Keypad_Setup_Col
    call	Keypad_Read_Col
    movf	Keypad_Value_Row, W, A
    iorwf	Keypad_Value_Col, W, A
    movwf	PORTD
    movwf	combineddata
    bra		test_1
    return
    
    
Keypad_Setup_Row:
    movlw	0xF0		;Set TRISE to 0x0F (0-3 as input, 4-7 as output)
    movwf	TRISE, A
    call	Keypad_Delay	; wait 10ms for Keypad output pins voltage to settle
    return
    
Keypad_Setup_Col:
    movlw	0x0F		;Set TRISE to 0xF0 (0-3 as output, 4-7 as input)
    movwf	TRISE, A
    call	Keypad_Delay	; wait 10ms for Keypad output pins voltage to settle
    return
    
Keypad_Read_Row:
	movf	PORTE, W, A	; Read PORTE to determine the logic levels on PORTE 0-3
	movwf	Keypad_Value_Row, A
	return

Keypad_Read_Col:
	movf	PORTE, W, A	; Read PORTE to determine the logic levels on PORTE 4-7
	movwf	Keypad_Value_Col, A
	return
   
test_1:
    movlw   11100111B	
    cpfseq  combineddata	
    bra	    test_2
    retlw   '1'
test_2:
    movlw   11101011B
    cpfseq  combineddata	
    bra	    test_3
    retlw   '2'
test_3:
    movlw   11101101B	
    cpfseq  combineddata	
    bra	    test_F
    retlw   '3'
test_F:
    movlw   11101110B	
    cpfseq  combineddata	
    bra	    test_4
    retlw   'F'
test_4:
    movlw   11010111B
    cpfseq  combineddata	
    bra	    test_5
    retlw   '4'	
test_5:
    movlw   11101011B
    cpfseq  combineddata	
    bra	    test_6
    retlw   '5'
test_6:
    movlw   11011101B	
    cpfseq  combineddata
    bra	    test_E
    retlw   '6'
test_E:
    movlw   11011110B
    cpfseq  combineddata	
    bra	    test_7
    retlw   'E'
test_7:
    movlw   10110111B	
    cpfseq  combineddata	
    bra	    test_8
    retlw   '7'
test_8:
    movlw   10111011B
    cpfseq  combineddata	
    bra	    test_9
    retlw   '8'
test_9:
    movlw   10111101B
    cpfseq  combineddata	
    bra	    test_D
    retlw   '9'
test_D:
    movlw   10111110B
    cpfseq  combineddata	
    bra	    test_A
    retlw   'D'
test_A:
    movlw   01110111B
    cpfseq  combineddata	
    bra	    test_0
    retlw   'A'
test_0:
    movlw   01111011B
    cpfseq  combineddata	
    bra	    test_B
    retlw   '0'
test_B:
    movlw   01111101B
    cpfseq  combineddata	
    bra	    test_C
    retlw   'B'
  
test_C:
    movlw   01111110B
    cpfseq  combineddata	
    bra	    invalid
    retlw   'C'

invalid:
    bra	  Keypad_Read  
    
    
Keypad_Delay:	    
    movlw   0xFF
    movwf   Keypad_counter, A
Keypad_Delay_Loop:
    decfsz  Keypad_counter, A
    bra	    Keypad_Delay_Loop
    return