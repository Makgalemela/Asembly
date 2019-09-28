
; author : 
; student number: 
; date : 22 - September - 2019
; course : Elen2006




.INCLUDE "./M328Pdef.inc"


;......... Interrupt and reset vector addresses ........
	.org 0x0000
		jmp Main
	.org 0x0012
		jmp FourSeconds
	.org 0x001A 
		jmp four
	
		/*
	.org 0x0014
		jmp RAISING_EDGE
	.org 0x0004
		jmp wireTouched
	.org 0x0008
		jmp sleepMode
	.org 0x0012
		jmp countUp*/

Main:

	.def K_region = R21 
	.def k_region_correct = R21
	.der Random = R28
;....... Stack Initialization.......................
	ldi R20, HIGH(RAMEND)
	out SPH, R20
	ldi R20, LOW(RAMEND)
	out SPL, R20
;....... Stack Initialization End..................

TIMER1_SETUP:
			clr R16
			ldi R16 , 0b00000000
			sts TCCR1A ,R16
			ldi R16 , 0B11000101
			sts TCCR1B , R16
			ldi R16 , 0b00000011
			sts TIMSK1 ,R16

			ldi R16 , 0b00001111						
			sts TCCR2B , R16
			ldi R16, 0b00000001
			sts  TIMSk2 , R16

			ldi R16 ,  0
			sts TCNT1L , R16
			ldi R16 ,  0
			sts TCNT1H , R16
		
			ldi R16 ,  0
			sts TCNT2 , R16

			cbi DDRB , 0
			sei


Display_LED:
			clr r16
			ldi R16 , 0b000000
			out DDRC , R16

			sbi DDRD , 7			
			sbi DDRD , 6				
			sbi DDRD , 5


TRIGGER:
	sbi portd , 5
	rcall DELAY_10us
	cbi portd , 5


RAISING_EDGE:	in R16 , TIFR1
				sbrs R16 , ICF1
				rjmp RAISING_EDGE
				out TIFR1 , R16
				lds R25 , ICR1L
				ldi R16 , 0B00000101
				sts TCCR1B , R16
			
FALLING_EDGE:	in R16 , TIFR1
				sbrs R16 , ICF1
				rjmp FALLING_EDGE
				lds R26 , ICR1L
				out TIFR1 , R16
	
GET_K_REGION:
				sub R26 , R25
				ldi R25 ,2
	
DIVISION_By2:
				INC K_region
				SUB R26 , R25
				BRCC DIVISION_By2
				DEC  K_region
				
						
here:
	out PORTC , K_region
	rjmp here



four:
	//cbi portd ,6
	reti


FourSeconds :
		push R29
		in R29 , sreg
		push R29
									
		inc R17
		cpi R17 , 30																	
		BRNE L2
		cbi portd ,7												
	L2:	
		inc Random 
		cpi Random  ,12
	L3:								
		pop R29
		out  sreg , R29
		pop R29
		reti


Play_Mode:
	sei

DELAY_10us:
    ldi  r18, 53
L1: dec  r18
    brne L1
    nop
ret