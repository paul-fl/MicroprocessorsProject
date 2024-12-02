#include <xc.inc>

global AVERAGE_Setup, AVERAGE_Calculate, DIV24_16u

psect udata_acs   ; Reserve data space in Access RAM
FREQ_VALUES: ds 14     ; Circular buffer for 7 slots (2 bytes each for 16-bit frequency)
TEMP_SUM_H:  ds 1      ; High byte of the sum
TEMP_SUM_L:  ds 1      ; Low byte of the sum
PTR:         ds 1      ; Circular buffer pointer
AVG_RESULT:  ds 2      ; Average result (16 bits: low and high bytes)
COUNT:       ds 1      ; Loop counter for summing

psect average_code, class=CODE

; Setup routine: Initializes the pointer and clears the average result
AVERAGE_Setup:
    clrf    PTR, A           ; Initialize the circular buffer pointer to 0
    clrf    AVG_RESULT, A    ; Clear low byte of the average
    clrf    AVG_RESULT + 1, A; Clear high byte of the average
    return

; Averaging calculation routine
AVERAGE_Calculate:
    ; Store the quotient (frequency result) in the circular buffer
    movf    ACCdLO, W, A              ; Load low byte of quotient
    movwf   FREQ_VALUES + PTR, A      ; Store low byte in the buffer
    movf    ACCdHI, W, A              ; Load high byte of quotient
    movwf   FREQ_VALUES + PTR + 1, A  ; Store high byte in the buffer

    ; Increment the pointer by 2 to account for the 2-byte slots
    incf    PTR, A
    incf    PTR, A

    ; Check if pointer exceeds buffer size (14 for 7 slots × 2 bytes each)
    movlw   14                        ; Total buffer size in bytes
    subwf   PTR, W, A                 ; Subtract PTR from 14
    btfsc   STATUS, Z                 ; If zero, reset the pointer, status bit is only set to 1 if the subtraction leads to 0 or below.
    clrf    PTR, A                    ; Reset PTR to 0

    ; Clear the sum registers for summing
    clrf    TEMP_SUM_H, A
    clrf    TEMP_SUM_L, A

    ; Initialize counter for summing loop
    movlw   7                         ; Loop 7 times (one for each slot)
    movwf   COUNT, A

SUM_LOOP:
    ; Load the next frequency value from the buffer (low and high bytes)
    movf    FREQ_VALUES + COUNT - 2, W, A ; Load low byte
    addwf   TEMP_SUM_L, F, A          ; Add to the low byte of the sum
    btfsc   STATUS, C                 ; Check for carry
    incf    TEMP_SUM_H, F, A          ; Add carry to the high byte

    movf    FREQ_VALUES + COUNT - 1, W, A ; Load high byte
    addwf   TEMP_SUM_H, F, A          ; Add to the high byte of the sum

    ; Decrement counter and loop again
    decfsz  COUNT, F, A
    bra     SUM_LOOP

    ; Divide the sum by 7 to compute the average
    clrf    ACCcLO, A                 ; Clear higher byte of dividend (24-bit alignment)
    movf    TEMP_SUM_L, W, A
    movwf   ACCdLO, A                 ; Low byte of dividend
    movf    TEMP_SUM_H, W, A
    movwf   ACCdHI, A                 ; High byte of dividend
    movlw   7                         ; Load divisor (7)
    movwf   ACCbLO, A
    clrf    ACCbHI, A                 ; Clear high byte of divisor
    call    DIV24_16u                 ; Call division subroutine

    ; Store the result (average) in AVG_RESULT
    movf    ACCdLO, W, A              ; Load low byte of quotient (average)
    movwf   AVG_RESULT, A             ; Store in AVG_RESULT low byte
    movf    ACCdHI, W, A              ; Load high byte of quotient (average)
    movwf   AVG_RESULT + 1, A         ; Store in AVG_RESULT high byte
    return
