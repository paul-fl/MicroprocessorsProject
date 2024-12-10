#include <xc.inc>


extrn	DIV_H, DIV_M, DIV_L, DIVISOR_H, DIVISOR_L, Q_H, Q_M, Q_L
extrn	Division_24_16
global	Averaging, FreqArray, AverageH, AverageL
    



psect udata_acs   ; Reserve data space in Access RAM

SumH:  ds 1      ; High byte of the sum
SumM:  ds 1	;Medium byte of sum
SumL:  ds 1      ; Low byte of the sum

AverageL:  ds 1      ; Average result
AverageM:  ds 1
AverageH:  ds 1
AverageRemH:      ds 1            ; High byte of remainder
AverageRemL:      ds 1            ; Low byte of remainder

DivisorH:  ds 1            ; High byte of divisor
DivisorL:  ds 1            ; Low byte of divisor

Length:      ds 1            ; Loop counter
Pointer:    ds 1
    
global	Pointer, Length

psect average_code, class=CODE


Averaging:

    movlw   5                        
    movwf   Length, A
    clrf    DIV_H, A
    clrf    DIV_M, A
    clrf    DIV_L, A
    clrf    DIVISOR_H, A
    clrf    DIVISOR_L, A
    clrf    AverageH, A
    clrf    AverageL, A
    movlw   FreqArray	; Moves FreqArray's address into Pointer
    movwf   Pointer, A
    movlw   FreqArray
    addwf   Length, A  ; This gives the endpoint of the array
    incf    Length, A  ; The condition checks for one after length position
 
AveragingLoop:
    movlw   0x00
    movwf   FSR0H
    movf    Pointer, W, A   ; Load high byte into nedium
    movwf   FSR0L
    movf    INDF0, W, A
    addwf   DIV_M, F, A          ;  Add to the medium byte of the sum
    btfsc   STATUS, 0, A 			; Check for carry
    incf    DIV_H, F, A          ;  Add carry to the high byte

    movlw   0x00
    movwf   FSR0H
    incf    Pointer, F, A
    movf    Pointer, W, A	; Load low byte
    movwf   FSR0L
    movf    INDF0, W, A
    addwf   DIV_L, F, A          ; Add to the low byte of the sum
    btfsc   STATUS, 0, A                  ; Check for carry
    incf    DIV_M, F, A          ; Add carry to the medium byte
    
    movlw   0x10
    movwf   INDF0

    ; Decrement counter twice and check Counter
    incf    Pointer, F, A
    movf    Length, W
    cpfseq  Pointer ; If pointer == W (Length), skip
    bra	    AveragingLoop   ; Adds next value
    bra	    Division	; Full so do division

; Divide the 24 bit sums by 4 bit (10) but suing 24/16 bit code 
;DIVIDE

Division:
    movlw   0x0
    movwf   DIVISOR_H, A
    movlw   0x03
    movwf   DIVISOR_L, A
    call    Division_24_16
    movf    Q_M, W, A
    movwf   AverageH, A
    movf    Q_L, W, A
    movwf   AverageL, A
    
    return