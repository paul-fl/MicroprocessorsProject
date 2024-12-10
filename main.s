#include <xc.inc>

; Initialise 
global	FreqArray
    
extrn   Division_24_16, Averaging

extrn   DIV_H, DIV_M, DIV_L, DIVISOR_H, DIVISOR_L, Q_H, Q_M, Q_L

psect udata_acs
 
FreqArray:  ds 6
arrayCounter: ds    1

psect code, abs
rst:    org 0x0
        goto    AveragingTest

AveragingTest:
    ; we expect 0000 0000 0000 0001 0000 0000 in total
    ; this means Q_H to be 0x0 Q_M to be 0x1 and Q_L to be 0x0
    
    movlw   0
    movwf   FreqArray, A
    movwf   FreqArray + 2, A
    movwf   FreqArray + 4, A
    movlw   1
    movwf   FreqArray + 1, A
    movwf   FreqArray + 3, A
    movwf   FreqArray + 5, A
    
    
    call    Averaging
    
    
    
    
end rst    ; end directive to mark the end of the program
