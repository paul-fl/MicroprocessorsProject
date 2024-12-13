#include <xc.inc>
    
global  clear_spectrum
global	spectrum_length, spectrum_pointer
extrn	Spectrum

psect	udata_acs   ; reserve data space in access ram
spectrum_length:   ds 1
spectrum_pointer:   ds 1
    
    
psect	uart_code, class=CODE
clear_spectrum:
    movlw   Spectrum
    movwf   spectrum_pointer, A
    movlw   Spectrum
    movwf   spectrum_length, A
    movlw   10
    addwf   spectrum_length, A

clear_spectrum_loop:
    movlw   0x00
    movwf   FSR0H, A
    movf    spectrum_pointer, W, A
    movwf   FSR0, A
    clrf    INDF0, A
    incf    spectrum_pointer, A
    movf    spectrum_length, W, A
    cpfseq  spectrum_pointer, A
    goto    clear_spectrum_loop
    return 
    
end
