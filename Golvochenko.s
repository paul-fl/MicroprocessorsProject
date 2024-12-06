#include <xc.inc> 
    
global FXD2416U
global	AARGB0, AARGB1, AARGB2 ;Dividend
global	BARGB0, BARGB1 ;Divisor
global	AARGB0, AARGB1, AARGB2 ;quotient

psect   udata_acs
  
REMB0:	ds 1
REMB1:	ds 1
LOOPCOUNT:	ds 1
AARGB0:	ds 1
AARGB1:	ds 1
AARGB2:	ds 1
BARGB0:	ds 1
BARGB1:	ds 1

FXD2416U:
        CLRF	REMB0              ; Clear remainder low byte
        CLRF	REMB1              ; Clear remainder high byte
        MOVLW	24               ; Set loop count for 24 bits
        MOVWF	LOOPCOUNT
	
LOOPU2416:
        RLCF AARGB2, W          ; Shift dividend left to move next bit to remainder
        RLCF AARGB1, F          ; Shift dividend mid-byte
        RLCF AARGB0, F          ; Shift dividend low-byte

        RLCF REMB1, F           ; Shift carry (next dividend bit) into remainder
        RLCF REMB0, F

        RLCF AARGB2, F          ; Finish shifting the dividend, save carry in AARGB2.0
                                ; Since remainder can be 17-bit long in some cases
                                ; This bit will also serve as the next result bit
         
        MOVF BARGB1, W          ; Subtract divisor from 16-bit remainder
        SUBWF REMB1, F          ; Subtract higher byte
        MOVF BARGB0, W          ;
        BTFSS STATUS, 0         ; Check for carry (borrow)
        INCFSZ BARGB0, W        ; Increment W if no carry
        SUBWF REMB0, F          ; Subtract lower byte

; Handling the 17th bit of the remainder stored in AARGB2.0
; If no borrow occurred, overwrite AARGB2.0 with 1 (no borrow).
; Otherwise, AARGB2.0 already holds the correct final borrow value.

        BTFSC STATUS, 0         ; If no borrow after 16-bit subtraction
        BSF AARGB2, 0           ; Set AARGB2.0 to 1 to indicate no borrow
                                ; If borrow occurred, AARGB2.0 already holds the final value.

        BTFSC AARGB2, 0         ; If no borrow after 17-bit subtraction
        GOTO UOK46LL            ; Skip remainder restoration

        ADDWF REMB0, F          ; Restore higher byte of remainder (W contains the value subtracted earlier)
        MOVF BARGB1, W          ; Restore lower byte of remainder
        ADDWF REMB1, F          ; Add W back to the remainder

UOK46LL:
        DECFSZ LOOPCOUNT, F     ; Decrement loop counter
        GOTO LOOPU2416          ; Repeat loop if not zero

        RETURN
