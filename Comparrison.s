#include <xc.inc>

global	CompareValues
   
extrn	AHigh, ALow, BHigh, BLow
    

CompareValues:
    ; Checks if A > B; A, B are 16-bit
    movf BHigh, W
    cpfsgt AHigh        ; Compare AHigh with BHigh
    BRA CheckBHighGreater
    retlw 1             ; Return 1 if A > B
    
 CheckBHighGreater:
    movf AHigh, W
    cpfsgt BHigh        ; Compare BHigh with AHigh
    BRA CheckLowBytes
    retlw 0              ; Return 0 if B > A

 CheckLowBytes:
    ; Compare low bytes
    movf ALow, W
    cpfsgt BLow         ; Compare ALow with BLow
    retlw 1             ; Return 1 if A > B
    retlw 0             ; Return 0 if B > A
