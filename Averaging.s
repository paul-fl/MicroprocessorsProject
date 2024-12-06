    #include <xc.inc>

    global AVERAGE_Setup, AVERAGE_Calculate, DIV24_16u

    psect udata_acs   ; Reserve data space in Access RAM
    Freq_values: ds 20     ; Circular buffer for 7 slots (2 bytes each for 16-bit frequency)
    Sum_H:  ds 1      ; High byte of the sum
    Sum_M:  ds 1	;Medium byte of sum
    Sum_L:  ds 1      ; Low byte of the sum
    Pointer:  ds 1      ; Circular buffer pointer
    AverageL:  ds 1      ; Average result
    AverageM:  ds 1
    AverageH:  ds 1
    Average_RemH:      ds 1            ; High byte of remainder
    Average_RemL:      ds 1            ; Low byte of remainder
    Counter_sum:  ds 1		; Loop counter for summing
    DIVISOR_H:  ds 1            ; High byte of divisor
    DIVISOR_L:  ds 1            ; Low byte of divisor
      
    TEMP:       ds 1            ; Temporary register
    COUNT:      ds 1            ; Loop counter, initialized to 24
    

    psect average_code, class=CODE

    Average_Setup:
	clrf    Pointer        ; Initialize the circular pointer to 0
	clrf    AverageL   ; Clear low byte of the average
	clrf    AverageH  ; Clear high byte of the average
	return

    Loading_Loop:
	movf    Q_L, W                ; Load the low byte of frequency
	movwf   Freq_values + Pointer 
	incf    Pointer, F           
	movf    Q_M, W                ; Load the high byte of frequency 
	movwf   Freq_values + Pointer             

	; Check if pointer exceeds buffer size (20 for 10 slots × 2 bytes each)
	movlw   20                        
	subwf   Pointer, W               
	btfsc   STATUS, Z   ; If zero, reset the pointer, status bit is only set to 1 if the subtraction leads to 0 or below.
	goto	Loading_Loop
	
	clrf    Pointer, A                    ; Reset pointer to 0
	
Sum_Loop:

    movlw   20                        
    movwf   counter_sum, A
    movf    Freq_values + Counter - 1, W, A ; Load low byte
    addwf   Sum_L, F, A          ; Add to the low byte of the sum
    btfsc   STATUS, C                 ; Check for carry
    incf    Sum_M, F, A          ; Add carry to the medium byte

    movf    req_values + Counter , W, A ; Load medium byte
    addwf   Sum_M, F, A          ; Add to the medium byte of the sum
    btfsc   STATUS, C                 ; Check for carry
    incf    Sum_H, F, A          ; Add carry to the medium byte

    ; Decrement counter twice and check Counter
    decf  counter_sum, F, A
    decfsz counter_sum
    bra   Sum_Loop

    ; Divide the 24 bit sums by 8 bit (10) but suing 24/16 bit code 
    ;DIVIDE
    
Divsion:

    ; Reserve storage for Remainder (16-bit)
    ; Clear Quotient Registers
CLRF    Q_H                 ; Clear quotient high byte
CLRF    Q_M                 ; Clear quotient middle byte
CLRF    Q_L                 ; Clear quotient low byte
    
    ; Clear Remainder Registers
CLRF    REM_H               ; Clear remainder high byte
CLRF    REM_L               ; Clear remainder low byte
    
    ; Set up the dividend (2,000,000)
movlw   Sum_H        ; Load the high byte 
movwf   DIVIDEND_H  ; Store in the high byte register

movlw   Sum_M       ; Load the middle byte 
movwf   DIVIDEND_M  ; Store in the middle byte register

movlw   Sum_L        ; Load the low byte 
movwf   DIVIDEND_L  ; Store in the low byte register

MOVLW	0xA		    ; VALUE OF 10
MOVWF   DIVISOR_L           ; Store in DIVISOR_L
    
MOVLW	0x0         
MOVWF   DIVISOR_H           ; Store in DIVISOR_H
    
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
