#include <xc.inc>   


global DIV_H, DIV_M, DIV_L, DIVISOR_H, DIVISOR_L, Q_H, Q_M, Q_L
global Division_24_16
    
psect   data          ; Define a data section in access RAM
; Reserve storage for Dividend (24-bit)
   
DIV_H      ds 1            ; High byte of dividend
DIV_M      ds 1            ; Middle byte of dividend
DIV_L      ds 1            ; Low byte of dividend
    
; Reserve storage for Divisor (16-bit)
DIVISOR_H  ds 1            ; High byte of divisor
DIVISOR_L  ds 1            ; Low byte of divisor

; Reserve storage for Quotient (24-bit)
Q_H        ds 1            ; High byte of quotient
Q_M        ds 1            ; Middle byte of quotient
Q_L        ds 1            ; Low byte of quotient
    
    ; Reserve storage for Remainder (16-bit)
REM_H      ds 1            ; High byte of remainder
REM_L      ds 1            ; Low byte of remainder
    
    ; Reserve storage for Temporary and Counter Registers
TEMP       ds 1            ; Temporary register
COUNT      ds 1            ; Loop counter, initialized to 24
    
    
    ; *** Initialization ***
    
psect   code                ; Switch to code section

Division_24_16:
    
    ; Clear Quotient Registers
CLRF    Q_H                 ; Clear quotient high byte
CLRF    Q_M                 ; Clear quotient middle byte
CLRF    Q_L                 ; Clear quotient low byte
    
    ; Clear Remainder Registers
CLRF    REM_H               ; Clear remainder high byte
CLRF    REM_L               ; Clear remainder low byte
    
    
    ; Initialize Loop Counter to 24 bits since we have a 24 bit divisor 
MOVLW   24                  ; Load literal value 24 into W
MOVWF   COUNT               ; Move W to COUNT

    ; *** Division Loop Start ***
    
Division_Loop:
    
    ; -------------------------------------------------------------
    ; 1. Shift Remainder Left by 1 Bit
    ; -------------------------------------------------------------
    CLRC                        ; Clear the Carry flag before shifting
    RLF     REM_L, F            ; Shift REM_L left, MSB into Carry
    RLF     REM_H, F            ; Shift REM_H left, incorporating Carry
    
    ; -------------------------------------------------------------
    ; 2. Bring Down the Next Bit from the Dividend
    ; -------------------------------------------------------------
    ; Shift the Dividend left to get the next bit into Carry
    RLF     DIV_L, F            ; Shift DIV_L left, MSB into Carry
    RLF     DIV_M, F            ; Shift DIV_M left, incorporating Carry
    RLF     DIV_H, F            ; Shift DIV_H left, incorporating Carry
    
    ; Now, Carry contains the next bit from the Dividend
    ; Shift the new bit into the LSB of the Remainder
    RLF     REM_L, F            ; Shift REM_L left, bring in new bit
    RLF     REM_H, F            ; Shift REM_H left, incorporating Carry
    
    ; -------------------------------------------------------------
    ; 3. Subtract Divisor from Remainder if Possible
    ; -------------------------------------------------------------
    ; Attempt to subtract Divisor from Remainder
    MOVF    DIVISOR_L, W        ; Move Divisor Low byte to W
    SUBWF   REM_L, F            ; Subtract W from REM_L, store in REM_L
    MOVF    DIVISOR_H, W        ; Move Divisor High byte to W
    SUBWFB  REM_H, F            ; Subtract W and Borrow from REM_H, store in REM_H
    
    ; Check if subtraction resulted in a negative value (Borrow occurred)
    BTFSC   STATUS, C           ; If Carry is set, no Borrow occurred
    GOTO    Set_Carry_For_Quotient   ; Proceed to set quotient bit
    
    ; Subtraction failed; restore original Remainder
    MOVF    DIVISOR_L, W        ; Move Divisor Low byte to W
    ADDWF   REM_L, F            ; Add W back to REM_L to restore
    MOVF    DIVISOR_H, W        ; Move Divisor High byte to W
    ADDWFC  REM_H, F            ; Add W and Carry back to REM_H to restore
    
    CLRC                        ; Clear Carry flag (Quotient bit = 0)
    GOTO    Shift_Quotient      ; Proceed to shift quotient
    
Set_Carry_For_Quotient:
    BSF     STATUS, C           ; Set Carry flag (Quotient bit = 1)
    
Shift_Quotient:
    ; -------------------------------------------------------------
    ; 4. Shift Quotient Left by 1 Bit and Incorporate New Bit
    ; -------------------------------------------------------------
    RLF     Q_L, F              ; Shift Q_L left, MSB into Carry
    RLF     Q_M, F              ; Shift Q_M left, incorporating Carry
    RLF     Q_H, F              ; Shift Q_H left, incorporating Carry
    
    ; -------------------------------------------------------------
    ; 5. Loop Control
    ; -------------------------------------------------------------
    DECFSZ  COUNT, F            ; Decrement COUNT; if zero, exit loop
    GOTO    Division_Loop       ; Repeat loop for next bit
    
    ; *** Division Complete ***
    
END_DIVISION:
    ; move results, clear temp registers
    ; The Quotient is in Q_H:Q_M:Q_L
    ; The Remainder is in REM_H:REM_L
    
    return                    

; *****************************************************************************
; * End of Multi-byte Division Algorithm                                      *
; *****************************************************************************
 
	