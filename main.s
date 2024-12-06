#include <xc.inc>

; initialise 

extrn   Division_24_16

    
extrn	DIV_H, DIV_M, DIV_L, DIVISOR_H, DIVISOR_L, Q_H, Q_M, Q_L

     
psect udata_acs 




psect code, abs
rst: 	org 0x0
	goto	Division

Division:
    ;we expect 0000 0000 0000 0001 0000 0000 in total
    ;this means Q_H to be 0x0 Q_M to be 0x1 and Q_L to be 0x0
    
    movlw   10000000B		;test dividend 8,388,608
    movwf   DIV_H, A
    movlw   00000000B
    movwf   DIV_M, A
    movlw   00000000B
    movwf   DIV_L, A
    
    movlw   10000000B	;test divisor 32,768
    movwf   DIVISOR_H, A
    movlw   00000000B	
    movwf   DIVISOR_L, A
    
    
    
    call    Division_24_16 
    movf    Q_H, W, A
    movf    Q_M, W, A
    movf    Q_L, W, A
	

end	rst