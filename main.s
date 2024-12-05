#include <xc.inc>

; initialise 
global	AHigh, ALow, BHigh, BLow    ;define global variables to be used by Comparrison
    
extrn	UART_Setup, UART_Transmit_Message   ;external UART subroutines
extrn   Keypad_Setup, Keypad_Read, Keypad_Check	    ; external Keypad subroutines
extrn	LCD_Setup, LCD_Write_Message, LCD_Send_Byte_D, LCD_Clear_Display ; external LCD subroutines
extrn	ADC_Setup, ADC_Read		   ; external ADC subroutines

extrn	CompareValues
    
extrn   Note1, Note2, Target_FreqH, Target_FreqL

     
psect udata_acs 
counter:    ds 1    ; reserve one byte for a counter variable
delay_count:	ds 1    ; reserve one byte for counter in the delay routine
keypad_status:	ds 1

updwn:      ds 1          ; Boolean: 1 for up, 0 for down
AHigh:      ds 1          ; High byte of A
ALow:       ds 1          ; Low byte of A
BHigh:      ds 1          ; High byte of B
BLow:       ds 1          ; Low byte of B
tarray:     ds 20         ; Time array: 10 16-bit values
    

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
	
	bcf	CFGS	; point to Flash program memory  
	bsf	EEPGD 	; access Flash program memory
	
	movlw	0x00	; initialize updown to 0 at the beginning
	movwf	updwn
	
	call	UART_Setup	; setup UART
	call	LCD_Setup	; setup LCD
	call	ADC_Setup	; setup ADC
	call    Keypad_Setup    ; setup Keypad 
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
	call	delay
	call	Keypad_Check	    ;check if the keypad is on '1' or off '0'
	movwf	keypad_status
	
	btfsc	keypad_status, 0
	goto	output_keypad		;if on, read the keypad
	goto	wait_keypad		;else keep checking
    
output_keypad:
	call	LCD_Clear_Display
	call    Keypad_Read        ; Read the keypad input
	
	movf	Note1, w
	call    LCD_Send_Byte_D 
	movf	Note2, w
	call    LCD_Send_Byte_D 
	
ADC_Read_Loop:
	call	ADC_Read       ; Call ADC read function (ADRESH, ADRESL)
	movf	updwn, w         ; Move updwn boolean into W
	cpfseq	0x01         ; Compare W with 0x01 (check for up)
	BRA	detectDown      ; Branch to detectDown if not up
	BRA	detectUp        ; Branch to detectUp if up
    
detectUp:
    ; Runs if first up detection is required
    movf ADRESH, w  ; Set AHigh = ADRESH
    movwf   AHigh
    movf ADRESL, w   ; Set ALow = ADRESL
    movwf   ALow
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
    movf ADRESH, w  ; Set BHigh = ADRESH
    movwf   BHigh
    movf ADRESL, w   ; Set BLow = ADRESL
    movwf   BLow
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