#include <xc.inc>

global	Compare_Values
   
extrn	AHigh, ALow, BHigh, BLow
    
psect	Keypad_code,class=CODE

Compare_Values:
    ; Checks if A > B; A, B are 16-bit

    movf BHigh, W, A
    cpfsgt AHigh        ; Compare AHigh with BHigh
    BRA CheckBHighGreater
    retlw 1             ; Return 1 if A > B
    
 CheckBHighGreater:
    movf AHigh, W, A
    cpfsgt BHigh, A        ; Compare BHigh with AHigh
    BRA CheckLowBytes
    retlw 0              ; Return 0 if B > A

 CheckLowBytes:
    ; Compare low bytes
    movf ALow, W, A
    cpfsgt BLow, A         ; Compare ALow with BLow
    retlw 1             ; Return 1 if A > B
    retlw 0             ; Return 0 if B > A
