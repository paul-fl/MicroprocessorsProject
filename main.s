#include <xc.inc>

; Initialise 
; Define global variables to be used by comparison
global	AHigh, ALow, BHigh, BLow    
    
; UART subroutines
extrn	UART_Setup, UART_Transmit_Message   
    
; Keypad subroutines
extrn   Keypad_Setup, Keypad_Read, Keypad_Check	  

; LCD subroutines
extrn	LCD_Setup, LCD_Write_Message, LCD_Send_Byte_D, LCD_Clear_Display 
    
; ADC subroutines
extrn	ADC_Setup, ADC_Read		  

; Timer subroutines
extrn	Timer_Setup, Timer_Read, Timer_On, Timer_Off, Timer_Reset		

; 16 bit arithmetic and logic functions
extrn   Division_24_16
extrn	Compare_Values

; Various external variables
extrn   Note1, Note2, targetFreqH, targetFreqL
extrn	DIV_H, DIV_M, DIV_L, DIVISOR_H, DIVISOR_L, Q_H, Q_M, Q_L
extrn	TimerH, TimerL

     
psect udata_acs 
counter:	ds 1    ; Reserve one byte for a counter variable
delay_count:	ds 1    ; Reserve one byte for counter in the delay routine
keypad_status:	ds 1
arrayCounter:	ds 1	; Reserve 1 byte for keeping track of position in the frequency array

upDown:		ds 1        ; Boolean: 1 for up, 0 for down
AHigh:	        ds 1        ; High byte of A
ALow:		ds 1        ; Low byte of A
BHigh:		ds 1        ; High byte of B
BLow:		ds 1        ; Low byte of B
FreqArray:	ds 20       ; Frequency array: 10 16-bit values
Spectrum:	ds 10	    ; Spectrum of the drequencies measured 10 bins of counts


psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x400)
messageArray:   ds 0x80 ; reserve 128 bytes for message data
    
psect data
prompt:
    db	'S','e','l','e','c','t',' ','N','o','t','e',0x0a ; Message plus return
    prompt_1	EQU  12  ; Length of data
    align	2

frequencyLookupTable:
    db	82, 110, 147, 196, 247, 330 ; Frequencies (MAKE THESE MATCH IN THE KEYPAD)
	
psect code, abs
rst:	org 0x0
    goto    setup

int_hi:	org 0x0008
    goto	interrupt_handler 
 
setup:	
    bcf	    CFGS	; Point to Flash program memory  
    bsf	    EEPGD 	; Access Flash program memory
    movlw   0x00	; Initialize updown to 0 at the beginning
    movwf   upDown, A
    movlw   0x00	; Set PORTF to an output
    movwf   TRISF, A
    movlw   0x00	; Init array counter to 0
    movwf   arrayCounter, A
    
    call    UART_Setup	; setup UART
    call    LCD_Setup	; setup LCD
    call    ADC_Setup	; setup ADC
    call    Keypad_Setup    ; setup Keypad 
    call    Timer_Setup	; setup Timer, timer is off 
	
; LCD_Prompt
    
prompt_load:
    lfsr    0, messageArray ; Load FSR0 with address in RAM	
    movlw   low highword(prompt)    ; Address of data in PM
    movwf   TBLPTRU, A	    ; Load upper bits to TBLPTRU
    movlw   high(prompt)    ; Address of data in PM
    movwf   TBLPTRH, A	    ; Load high byte to TBLPTRH
    movlw   low(prompt)	    ; Address of data in PM
    movwf   TBLPTRL, A	    ; Load low byte to TBLPTRL
    movlw   prompt_1	    ; Bytes to read
    movwf   counter, A	    ; Our counter register
	
prompt_load_loop: 	
    tblrd*+			; One byte from PM to TABLAT, increment TBLPRT
    movff   TABLAT, POSTINC0	; Move data from TABLAT to (FSR0), inc FSR0	
    decfsz  counter, A		; Count down to zero
    bra	prompt_load_loop	; Keep going until finished
    movlw	prompt_1-1	; Output message to LCD
				; Don't send the final carriage return to LCD
    lfsr	2, messageArray
    call	LCD_Write_Message
    ;call	LCD_Clear_Display

wait_keypad:
    call    delay
    call    Keypad_Check	; Check if the keypad is on '1' or off '0'
    movwf   keypad_status, A

    btfsc   keypad_status, 0, A
    goto    output_keypad	; If on, read the keypad
    goto    wait_keypad		; Else keep checking
    
output_keypad:
    call    LCD_Clear_Display
    call    Keypad_Read        ; Read the keypad input

    movf    Note1, w, A
    call    LCD_Send_Byte_D 
    movf    Note2, w, A
    call    LCD_Send_Byte_D 

call Timer_On	; Initial timer on before loop starts
    
ADC_read_loop:
    call    ADC_Read        ; Call ADC read function (ADRESH, ADRESL)
    movf    upDown, w, A    ; Move updown boolean into W
    cpfseq  0x01, A         ; Compare W with 0x01 (check for up)
    bra	    detect_down      ; Branch to detectDown if not up
    bra	    detect_up        ; Branch to detectUp if up
    
detect_up:
    ; Runs if first up detection is required
    movf    ADRESH, w, A    ; Set AHigh = ADRESH
    movwf   AHigh, A
    movf    ADRESL, w, A    ; Set ALow = ADRESL
    movwf   ALow, A
    movlw   0x04	    ; Set BHigh = 0x04  ;This is our midpoint, 1250 mV
    movwf   BHigh, A
    movlw   0xE2	    ; Set BLow = 0xE2
    movwf   BLow, A
    call    Compare_Values  ; Compare A and B
    cpfseq  0x01, A         ; Skip if W = 1
    bra	    ADC_read_loop   ; Not a crossing, return to loop
    bra	    up_crossing_found   ; Crossing found, branch to handle
    
detect_down:
    ; Runs if first down detection is required
    movf    ADRESH, w, A    ; Set BHigh = ADRESH
    movwf   BHigh, A
    movf    ADRESL, w, A    ; Set BLow = ADRESL
    movwf   BLow, A
    movlw   0x04	    ; Set AHigh = 0x04
    movwf   AHigh, A
    movlw   0xE2	    ; Set ALow = 0xE2
    movwf   ALow, A
    call    Compare_Values  ; Compare A and B
    cpfseq  0x00, A         ; Skip if W = 0
    bra	    ADC_read_loop   ; Not a crossing, return to loop
    bra	    down_crossing_found   ; Crossing found, branch to handle
    
up_crossing_found:
    movlw   0x00
    movwf   upDown  ; It will now look for a down
    bra	    crossing_found

down_crossing_found:
    movlw   0x01
    movwf   upDown  ; It will now look for an up
    bra	    crossing_found
    
crossing_found:	; Crossing detected
    call    Timer_Read
    call    Timer_Off
    ; Setting up division
    movf    TimerH, W, A    ; Use timer value as denominator
    movwf   DIVISOR_H, A
    movf    TimerL, W, A
    movwf   DIVISOR_L, A
    movlw   0x1E	    ; Numerator is 2E6
    movwf   DIV_H, A
    movlw   0x84
    movwf   DIV_M, A
    movlw   0x80
    movwf   DIV_L, A
    
    ; Perform division operation. This yields a frequency
    call    Division_24_16  ; Writes quotient into Q_H, Q_M, and Q_L
    
    ; Move the frequency (quotient) into FreqArray
	; Freq in 0-500 range means 9 bit (round to 16 bit) number
	; Store high and low bit in high low high low pattern
    
    movlw   Q_M, A  ; Move medium of quotient into freq high position
    movwf   FreqArray + arrayCounter  ; Counter begins at 0
    movlw   Q_L, A  ; Quotient low is frequency low
    movwf   FreqArray + arrayCounter + 1    ; Put into position after high byte
    incf    arrayCounter, A ; Because dealing with 2 byte chunks, inc by 2
    incf    arrayCounter, A
    movlw   0x20    ; Checking if the array is full if count == length
    cpfseq  arrayCounter    ; If ==, do averaging operation; else, go to preloop to reset timer for next crossing
    bra	    preloop	; This resets the timer and starts next detection
    bra	    array_ops	; Averages things
    
preloop:
    call    Timer_Reset	; Resets timer counter to 0
    call    Timer_On	; Start timer again for next crossing
    bra	    ADC_read_loop
    
array_ops: ; Performs all calculations on array to get frequency and on the frequency
    ; AVERAGE THE ARRAY ### Assuming output is in averageHigh and averageLow
    bra	LED_output  ; Compares the average to target and outputs to LEDs
    
LED_output: ; Outputs sharp, flat, and in-tune ot PORTF
    ; Assume 2 Hz uncertainty around target
    ; Is A (av freq) > B (target + 2)? Yes is sharp; else check lower bound
    movlw   averageHigh, A
    movwf   AHigh
    movlw   averageLow, A
    movwf   ALow
    movlw   targetFreqH, A
    movwf   BHigh
    movlw   targetFreqL, A
    movwf   BLow
    ; w/ possible target freqs, \pm 2 will not roll over to high --> BLow only
    movlw   0x02
    addwf   BLow    ; Adds the 2 Hz to the upper bound
    call    Compare_Values  ; retw 1 if sharp, else more checks
    cpfseq  0x01    ; Skips if sharp (==1)
    bra	    check_flat	; More checks to determine if is flat or tuned
    bra	    sharp   ; Outputs sharp to PORTF
    
check_flat: ; Part of LED_output
    ; Only occurs if freq is less than top band
    ; Is A (av freq) > B (target - 2)? Yes is tuned; else flat
    movlw   averageHigh, A
    movwf   AHigh
    movlw   averageLow, A
    movwf   ALow
    movlw   targetFreqH, A
    movwf   BHigh
    movlw   targetFreqL, A
    movwf   BLow
    ; w/ possible target freqs, \pm 2 will not roll over to high --> BLow only
    subwf   BLow    ; Subtract 2 from BLow
    call    Compare_Values  ; retw 1 if in-tune, less than means flat
    cpfseq  0x01    ; Skips if in-tune
    bra	    flat
    bra	    tuned
    
sharp: ; Runs if sharp detected
    movlw   00000100B
    movwf   PORTF   ; Outputs to LED
    bra	    array_ops2    
flat:
    movlw   00000001B
    movwf   PORTF   ; Outputs to LED
    bra	    array_ops2
tuned:
    movlw   00000010B
    movwf   PORTF   ; Outputs to LED
    bra	    array_ops2
    
array_ops2: 
    ; Now that tuning status returned to LEDs, increment relevant bin counter
    ; Bin index can be found via floor division by bin freq interval
    ; 10 bins for 0 to 500 Hz means 50 Hz interval
    ; Repurpose earlier division
    ; Setting up division with frequency (averageHigh/Low) as numerator and 0x32 as denominator
    movlw   0x00    ; Use 0x32 as denominator
    movwf   DIVISOR_H, A
    movlw   0x32
    movwf   DIVISOR_L, A
    movlw   0x00	    ; Numerator is average frequency
    movwf   DIV_H, A
    movf    averageHigh, W, A	; averageHigh can be mid here
    movwf   DIV_M, A
    movf    averageLow, W, A	; averageLow is low (duh!)
    movwf   DIV_L, A
    
    call    Division_24_16  ; Calls the division --> Q_H, Q_M, Q_L
    ; The quotient will be only in low
    
    ; Increment relevant bin by one
    incf    Spectrum + Q_L
    
    ; ### bra to UART export code for spectrum
   
    bra	    preloop ; Resets timer to get ready for next reading
    
    
    
    
    
    
    
    

    
    
 

  


	
	
	
	


	
delay:	
	decfsz	delay_count, A	; decrement until zero
	bra	delay
	return

	
	end	rst