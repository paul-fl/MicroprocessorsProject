#include <xc.inc>

; initialise 
global	AHigh, ALow, BHigh, BLow    ;define global variables to be used by Comparrison
    
extrn	UART_Setup, UART_Transmit_Message   ;external UART subroutines
extrn   Keypad_Setup, Keypad_Read, Keypad_Check	    ; external Keypad subroutines
extrn	LCD_Setup, LCD_Write_Message, LCD_Send_Byte_D, LCD_Clear_Display ; external LCD subroutines
extrn	ADC_Setup, ADC_Read		   ; external ADC subroutines
extrn	Timer_Setup, Timer_Read, TurnOnTimer1, TurnOffTimer1		;external timer subroutines
extrn   Division_24_16

extrn	CompareValues
    
extrn   Note1, Note2, Target_FreqH, Target_FreqL
extrn	DIV_H, DIV_M, DIV_L, DIVISOR_H, DIVISOR_L, Q_H, Q_M, Q_L

     
psect udata_acs 
counter:    ds 1    ; Reserve one byte for a counter variable
delay_count:	ds 1    ; Reserve one byte for counter in the delay routine
keypad_status:	ds 1
ArrayCounter: ds 1  ; Reserve 1 byte for keeping track of position in the frequency array

updown:     ds 1          ; Boolean: 1 for up, 0 for down
AHigh:      ds 1          ; High byte of A
ALow:       ds 1          ; Low byte of A
BHigh:      ds 1          ; High byte of B
BLow:       ds 1          ; Low byte of B
FreqArray:  ds 20         ; Frequency array: 10 16-bit values
Spectrum:   ds 10


psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x400)
myArray:    ds 0x80 ; reserve 128 bytes for message data
    
psect data
prompt:
	db	'S','e','l','e','c','t',' ','N','o','t','e',0x0a
					; message, plus carriage return
	prompt_1   EQU	12	; length of data
	align	2

frequencyLookupTable:
	db	82, 110, 147, 196, 247, 330 ; Frequencies (MAKE THESE MATCH IN THE KEYPAD)
	
psect code, abs
rst: 	org 0x0
	goto	setup

int_hi:	org  0x0008
	goto	interrupt_handler 
 
setup:	
	
	bcf	CFGS	; Point to Flash program memory  
	bsf	EEPGD 	; Access Flash program memory
	
	movlw	0x00	; Initialize updown to 0 at the beginning
	movwf	updown, A
	movlw   0x00	; Set PORTF to an output
	movwf   TRISF, A
	
	movlw	0x00	; Init array counter to 0
	movwf	
	
	call	UART_Setup	; setup UART
	call	LCD_Setup	; setup LCD
	call	ADC_Setup	; setup ADC
	call    Keypad_Setup    ; setup Keypad 
	call	Timer_Setup	; setup Timer
	
	goto	LCD_prompt
	
LCD_prompt:
	
prompt_load:
    
	lfsr	0, myArray	; Load FSR0 with address in RAM	
	movlw	low highword(prompt)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(prompt)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(prompt)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	prompt_1		; bytes to read
	movwf 	counter, A		; our counter register
	
prompt_load_loop: 	
    
	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	prompt_load_loop		; keep going until finished
		
	movlw	prompt_1-1	; output message to LCD
				; don't send the final carriage return to LCD
	lfsr	2, myArray
	call	LCD_Write_Message
	;call	LCD_Clear_Display

wait_keypad:
    call    delay
    call    Keypad_Check	    ;check if the keypad is on '1' or off '0'
    movwf   keypad_status, A

    btfsc   keypad_status, 0, A
    goto    output_keypad		;if on, read the keypad
    goto    wait_keypad		;else keep checking
    
output_keypad:
    call    LCD_Clear_Display
    call    Keypad_Read        ; Read the keypad input

    movf    Note1, w, A
    call    LCD_Send_Byte_D 
    movf    Note2, w, A
    call    LCD_Send_Byte_D 
	
ADC_Read_Loop:
    call    ADC_Read       ; Call ADC read function (ADRESH, ADRESL)
    movf    updown, w, A         ; Move updown boolean into W
    cpfseq  0x01, A         ; Compare W with 0x01 (check for up)
    BRA	    detectDown      ; Branch to detectDown if not up
    BRA	    detectUp        ; Branch to detectUp if up
    
detectUp:
    ; Runs if first up detection is required
    movf    ADRESH, w, A  ; Set AHigh = ADRESH
    movwf   AHigh, A
    movf    ADRESL, w, A   ; Set ALow = ADRESL
    movwf   ALow, A
    movlw   0x04          ; Set BHigh = 0x04  ;This is our midpoint, 1250 mV
    movwf   BHigh, A
    movlw   0xE2          ; Set BLow = 0xE2
    movwf   BLow, A
    call    CompareValues  ; Compare A and B
    cpfseq  0x01, A         ; Skip if W = 1
    BRA	    ADC_Read_Loop            ; Not a crossing, return to loop
    BRA	    CrossingFound   ; Crossing found, branch to handle
    
detectDown:
    ; Runs if first down detection is required
    movf    ADRESH, w, A  ; Set BHigh = ADRESH
    movwf   BHigh, A
    movf    ADRESL, w, A   ; Set BLow = ADRESL
    movwf   BLow, A
    movlw   0x04          ; Set AHigh = 0x04
    movwf   AHigh, A
    movlw   0xE2          ; Set ALow = 0xE2
    movwf   ALow, A
    call    CompareValues  ; Compare A and B
    cpfseq  0x00, A         ; Skip if W = 0
    BRA	    ADC_Read_Loop           ; Not a crossing, return to loop
    BRA	    CrossingFound   ; Crossing found, branch to handle
    
CrossingFound:
    ; Crossing detected
    call    Timer_Read
    call    TurnOffTimer1
    ; inputs for division
    movf    TimerH, W, A
    movwf    Divisor_H, A
    movf    TimerL, W, A
    movwf   Divisor_L, A
    movlw   0x1E
    movwf   DIV_H
    movlw   0x84
    movwf   DIV_M
    movlw   0x80
    movwf   DIV_L
    
    call    Division_24_16
    movlw   Q_M	;Move medium of quotient into high of frequency at correct array element
    movwf   FreqArray + ArrayCounter  ; Counter begins at 0; HIGH LOW HIGH LOW PATTERN
    movlw   Q_L	
    movwf   FreqArray + ArrayCounter + 1
    incf    ArrayCounter
    incf    ArrayCounter
    movlw   0x20    ; Checking if the array is full if countt == length
    cpfseq  ArrayCounter    ; If ==, do averaging operation; else, go to preloop to reset timer for next crossing
    bra	    preloop ; This resets the timer
    bra	    arrayOps	; Averages things
    
preloop:
    ; //reset timer
    
    bra ADC_Read_Loop
    
 

  
 calculateArrayFreq:
    ; Calculate average time
    ; Calculate frequency
    ; Call frequency into low function
    ; Compare with target call function
    ; Output to LEDs
    ; Send binary data via UART
    ; Reset times
    ;BRA ADC_Read_Loop

	
	
	
	
interrupt_handler:
 ;   call    Keypad_Read        ; Read the keypad input
  ;  call    LCD_Send_Byte_D    ; Display the byte on the LCD

   ; retfie  f                      ; Return from interrupt
    
main:
    ;call take data (up to 7 data points)
    ;call analysis
    ;calls outputting code
    ;call/loop back to taking data

 loop:
	; read from ADC
	; detect first crossing
	; start timer
	; detect second crossing
	; pull timer value
	
delay:	
	decfsz	delay_count, A	; decrement until zero
	bra	delay
	return

	
	end	rst