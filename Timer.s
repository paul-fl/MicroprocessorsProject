#include <xc.inc>
   
    
global Timer_Setup, TurnOnTimer1, TurnOffTimer1, Timer_Read
    
psect	udata_acs
TimerL: ds 1
TimerH: ds 1
	
psect	Timer_code,class=CODE

 ; Set up Timer1 with instruction clock (FOSC/4) as the clock source
Timer_Setup:   
    movlw 00110111
    movwf T1CON, A
    return
    
; Code to turn Timer1 on or off
TurnOnTimer1:
    movlw 00110111
    movwf T1CON, A      ; Set TMR1ON bit to enable Timer1
    return

TurnOffTimer1:
    movlw 00110110
    movwf T1CON, A          ; Clear TMR1ON bit to disable Timer1
    return
   
Timer_Read:
    movf    TMR1L, w, A
    movwf   TimerL, A
    movf    TMR1H, w, A
    movwf   TimerH, A
    return