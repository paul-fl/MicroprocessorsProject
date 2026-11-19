# Microprocessors project (PIC assembly)

Firmware written in PIC assembly for Imperial's 3rd-year Microprocessors lab (2024). The device is a **spectrum analyser for tuning a guitar**: it samples the string's signal with the ADC, analyses its frequency and shows the result on an LCD, with keypad input.

Modules: `ADC.s` (sampling), `Spectrum.s`, `Averaging.s`, `Comparison.s`, `Division.s` (16-bit arithmetic), `Keypad.s`, `LCD.s`, `UART.s`, `Timer.s`, `main.s`.

Built with MPLAB X (`Makefile`, `nbproject/`).
