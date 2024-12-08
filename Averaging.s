#include <xc.inc>


extrn	DIV_H, DIV_M, DIV_L, DIVISOR_H, DIVISOR_L, Q_H, Q_M, Q_L
extrn	Division_24_16
global	array_ops, FreqArray, AverageH, AverageL
    



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

CounterSum:      ds 1            ; Loop counter, initialized to 24


psect average_code, class=CODE


array_ops:

    movlw   20                        
    movwf   CounterSum, A
    movf    FreqArray + CounterSum - 1, W, A	; Load low byte
    addwf   DIV_H, F, A          ;  Add to the low byte of the sum
    btfsc   STATUS, 0, A 			; Check for carry
    incf    DIV_M, F, A          ;  Add carry to the medium byte

    movf    FreqArray + CounterSum , W, A ; Load medium byte
    addwf   DIV_M, F, A          ; Add to the medium byte of the sum
    btfsc   STATUS, 0, A                  ; Check for carry
    incf    DIV_H, F, A          ; Add carry to the high byte

    ; Decrement counter twice and check Counter
    decf    CounterSum, F, A
    decfsz  CounterSum, A
    bra	    array_ops
    bra	    Division

; Divide the 24 bit sums by 4 bit (10) but suing 24/16 bit code 
;DIVIDE

Division:
    movlw   0x0
    movwf   DIVISOR_H, A
    movlw   0xA
    movwf   DIVISOR_L, A
    call    Division_24_16
    movf    Q_M, W
    movwf   AverageH, A
    movf    Q_L, W
    movwf   AverageL, A
    
    return
