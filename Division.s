#include <xc.inc>   
;CONFIG  XINST = OFF           ; Extended Instruction Set (Disabled)


global DIV_H, DIV_M, DIV_L, DIVISOR_H, DIVISOR_L, Q_H, Q_M, Q_L
global Division_24_16
    
psect   udata_acs          ; Define a data section in access RAM
; Reserve storage for Dividend (24-bit)
   
DIV_H:      ds 1            ; High byte of dividend
DIV_M:      ds 1            ; Middle byte of dividend
DIV_L:      ds 1            ; Low byte of dividend
    
; Reserve storage for Divisor (16-bit)
DIVISOR_H:  ds 1            ; High byte of divisor
DIVISOR_L:  ds 1            ; Low byte of divisor

; Reserve storage for Quotient (24-bit)
Q_H:        ds 1            ; High byte of quotient
Q_M:        ds 1            ; Middle byte of quotient
Q_L:        ds 1            ; Low byte of quotient
    
    ; Reserve storage for Remainder (16-bit)
REM_H:      ds 1            ; High byte of remainder
REM_L:      ds 1            ; Low byte of remainder
    
    ; Reserve storage for Temporary and Counter Registers
TEMP:       ds 1            ; Temporary register
COUNT:      ds 1            ; Loop counter, initialized to 24
    
    
		; *** Initialization ***
    
psect   Division_code,class=CODE                ; Switch to code section

Division_24_16:
    
    ; Clear Quotient Registers
CLRF    Q_H, A                ; Clear quotient high byte
CLRF    Q_M, A                ; Clear quotient middle byte
CLRF    Q_L, A                ; Clear quotient low byte
    
    ; Clear Remainder Registers
CLRF    REM_H, A            ; Clear remainder high byte
CLRF    REM_L, A               ; Clear remainder low byte
    
    
    ; Initialize Loop Counter to 24 bits since we have a 24 bit divisor 
MOVLW   24                  ; Load literal value 24 into W
MOVWF   COUNT, A               ; Move W to COUNT

    ; *** Division Loop Start ***
    
Division_Loop:
    
; -------------------------------------------------------------
; 1. Shift Remainder Left by 1 Bit
; -------------------------------------------------------------
bcf	    STATUS, 0, A           ; Clear the Carry flag before shifting
rlcf    REM_L, F, A            ; Shift REM_L left, MSB into Carry
rlcf    REM_H, F, A            ; Shift REM_H left, incorporating Carry
    
;LSB of the remainder is now 0
      
; -------------------------------------------------------------
; 2. Bring Down the Next Bit from the Dividend
; -------------------------------------------------------------
; Shift the Dividend left to get the next bit into Carry
bcf	    STATUS, 0, A           ; Clear the Carry flag before shifting
rlcf     DIV_L, F, A            ; Shift DIV_L left, MSB into Carry
rlcf     DIV_M, F, A            ; Shift DIV_M left, incorporating Carry
rlcf     DIV_H, F, A            ; Shift DIV_H left, incorporating Carry
;carry at this point contains the MSB of the dividend 

;if the MSB is 1: set the least significant bit of the remainder to 1
;otherwise leave it be 0
;we effectively shift the MSB of the dividend into the LSB of the carry

btfsc   STATUS, 0, A
bsf     REM_L, 0, A

; -------------------------------------------------------------
; 3. Compare with Divisor and Possibly Subtract
; -------------------------------------------------------------
; Attempt remainder = remainder - divisor

movf    DIVISOR_L, W, A
subwf   REM_L, F, A
    
;the carry bit in the STATUS register will be cleared to indicate a borrow occurred
movf    DIVISOR_H, W, A
subwfb  REM_H, F, A
    
; If no borrow occurred, remainder >= divisor, so remainder is updated and quotient bit = 1
; If borrow occurred, remainder < divisor, restore remainder and quotient bit = 0
btfsc   STATUS, 0, A    ; C=1 means no borrow
goto    No_Borrow
    
; Borrow occurred -> restore remainder
movf    DIVISOR_L, W, A
addwf   REM_L, F, A
movf    DIVISOR_H, W, A
addwfc  REM_H, F, A
bcf     STATUS, 0, A    ; Set carry=0 to indicate quotient bit = 0
goto    Set_Quotient_Bit

No_Borrow:
    ; No borrow -> remainder is already adjusted and carry=1
bsf     STATUS, 0, A
    
Set_Quotient_Bit:
; -------------------------------------------------------------
; 4. Shift Quotient Left and Incorporate New Bit
; -------------------------------------------------------------
; The carry flag now holds the new quotient bit
rlcf    Q_L, F, A
rlcf    Q_M, F, A
rlcf    Q_H, F, A

; -------------------------------------------------------------
; 5. Loop Control
; -------------------------------------------------------------
decfsz  COUNT, F, A
goto    Division_Loop
    
return 