#include <xc.inc>
    
global Keypad_Setup, Keypad_Read, Keypad_Check
global Note1, Note2
global targetFreqH, targetFreqL

global combineddata, test
  
psect	udata_acs   ; reserve data space in access ram
Keypad_counter: ds    1	    ; reserve 1 byte for variable UART_counter
Keypad_Value: ds 1
Keypad_Value_Row: ds  1
Keypad_Value_Col: ds  1
combineddata: ds 1
Note1:	ds 1
Note2:	ds 1
targetFreqH: ds 1
targetFreqL: ds 1 
    
test: ds 1
    
psect	Keypad_code,class=CODE
Keypad_Setup:
    banksel	PADCFG1
    bsf		REPU
    clrf	LATE, A		; Write 0s to the LATE
    clrf	TRISD, A
    return
    
Keypad_Check:
    call	Keypad_Setup_Row
    call	Keypad_Read_Row
    call	Keypad_Setup_Col
    call	Keypad_Read_Col
    movf	Keypad_Value_Row, W, A
    iorwf	Keypad_Value_Col, W, A
    
    movwf	test, A
    movf	test, w, A

    movlw   0xFF                     ; Load 0xFF into W
    cpfseq  test, A             ; Compare W with combineddata
    goto    Pressed   
    goto    NotPressed

Pressed:
    retlw   '1'

NotPressed:
    retlw   '0'
 
Keypad_Read:
    call	Keypad_Setup_Row
    call	Keypad_Read_Row
    call	Keypad_Setup_Col
    call	Keypad_Read_Col
    movf	Keypad_Value_Row, W, A
    iorwf	Keypad_Value_Col, W, A
    movwf	PORTD, A
    movwf	test, A
    bra		test_E2
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
   
test_E2: ; button 1
    movlw   11101110B	
    cpfseq  test, A	
    bra	    test_A2
    movlw   'E'
    movwf   Note1, A
    movf    Note1, w, A
    movlw    '2'
    movwf   Note2, A
    movlw   0x00
    movwf   targetFreqH, A
    movlw   01010010B
    movwf   targetFreqL, A
    
    return
   
test_A2:    ;button 2
    movlw   11101101B
    cpfseq  test, A
    bra	    test_D3
    movlw   'A'
    movwf   Note1, A
    movlw    '2'
    movwf   Note2, A
    movlw   0x00
    movwf   targetFreqH, A
    movlw   01101110B
    movwf   targetFreqL, A
    return
    
test_D3:    ;button 3
    movlw   11101011B	
    cpfseq  test, A	
    bra	    test_G3
    movlw   'D'
    movwf   Note1, A
    movlw    '3'
    movwf   Note2, A
    movlw   0x00
    movwf   targetFreqH, A
    movlw   10010011B
    movwf   targetFreqL, A
    return
    
test_G3: ;button F
    movlw   11100111B	
    cpfseq  test, A	
    bra	    test_B3
    movlw   'G'
    movwf   Note1, A
    movlw    '3'
    movwf   Note2, A
    movlw   0x00
    movwf   targetFreqH, A
    movlw   11000100B
    movwf   targetFreqL, A
    return
    
test_B3: ;button 4
    movlw   11011110B
    cpfseq  test, A
    bra	    test_E4
    movlw   'B'
    movwf   Note1, A
    movlw    '3'
    movwf   Note2, A
    movlw   0x00
    movwf   targetFreqH, A
    movlw   11110111B
    movwf   targetFreqL, A    
    return
    
test_E4:    ;button 5
    movlw   11011101B
    cpfseq  test, A
    bra	    invalid
    movlw   'E'
    movwf   Note1, A
    movlw    '4'
    movwf   Note2, A
    movlw   00000001B
    movwf   targetFreqH, A
    movlw   01001010B
    movwf   targetFreqL, A   
    return

invalid:
    return
    
    
Keypad_Delay:	    
    movlw   0xFF
    movwf   Keypad_counter, A
Keypad_Delay_Loop:
    decfsz  Keypad_counter, A
    bra	    Keypad_Delay_Loop
    return