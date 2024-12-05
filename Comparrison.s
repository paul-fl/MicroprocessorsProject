#include <xc.inc>

extern	AHigh, Alow, BHigh, Blow, updwn, tarray
    
detectUp:
    ; Runs if first up detection is required
    movf ADRESH, AHigh  ; Set AHigh = ADRESH
    movf ADRESL, ALow   ; Set ALow = ADRESL
    movlw 0x04          ; Set BHigh = 0x04  ;This is our midpoint, 1250 mV
    movwf BHigh
    movlw 0xE2          ; Set BLow = 0xE2
    movwf BLow
    call CompareValues  ; Compare A and B
    cpfseq 0x01         ; Skip if W = 1
    BRA ADC_Read_Loop            ; Not a crossing, return to loop
    BRA CrossingFound   ; Crossing found, branch to handle
    
detectDown:
    ; Runs if first down detection is required
    movf ADRESH, BHigh  ; Set BHigh = ADRESH
    movf ADRESL, BLow   ; Set BLow = ADRESL
    movlw 0x04          ; Set AHigh = 0x04
    movwf AHigh
    movlw 0xE2          ; Set ALow = 0xE2
    movwf ALow
    call CompareValues  ; Compare A and B
    cpfseq 0x00         ; Skip if W = 0
    BRA ADC_Read_Loop           ; Not a crossing, return to loop
    BRA CrossingFound   ; Crossing found, branch to handle
    
CrossingFound:
    ; Crossing detected
    ; End timer
    ; Add time to time array at count and count+1
    ; Increment count by 2
    incf counter, F     ; Increment counter
    movlw (tarray-2)    ; Check if array is full
    cpfseq counter
    BRA calculateArrayFreq ; If full, branch to calculateArrayFreq
    ; Else reset timer
    BRA ADC_Read_Loop
    
    
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
