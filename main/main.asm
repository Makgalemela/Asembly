
; author : 
; student number: 
; date : 22 - September - 2019
; course : Elen2006


.INCLUDE "./M328Pdef.inc"


;......... Interrupt and reset vector addresses ........
	.org 0x0000
		jmp Main
	.org 0x0002
		jmp Test_mode	
	.org 0x0004
		jmp Play_Mode
	.org 0x0012
		jmp Delay_Gen
	.org 0x001A 
		jmp Delay_4s
	
Main:

	.def K_region = R21 
	.def k_region_correct = R24
	.def Random = R19
;....... Stack Initialization.......................
	ldi R20, HIGH(RAMEND)
	out SPH, R20
	ldi R20, LOW(RAMEND)
	out SPL, R20
;....... Stack Initialization End..................

TIMER1_SETUP_And_other_Interrups:
			clr R16
			ldi R16 , 0b00000000
			sts TCCR1A ,R16
			ldi R16 , 0B11000101
			sts TCCR1B , R16
			
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
			ldi R16 ,0
			sts  GPIOR1 , R16

			ldi R16 , 0b00001111
			sts EICRA , R16						
			ldi R16 , 0b00000011
			out EIMSK , R16						
			sei


;---------------------------setting up the I/0 pins-------------------------------------------------------
Display_LED:
			clr r16
			ldi R16 , 0b000000
			out DDRC , R16

			sbi DDRD , 7				; Green LED	
			sbi DDRD , 6				; RED LED
			sbi DDRD , 5				; ORANGED LED
			sbi DDRD , 4				; TRIGGER PIN

			cbi DDRB , 0				; Echo Pin , using Imput capture mode of TIMER 1
			cbi DDRB , 3				; PlayMode button
			cbi DDRB , 2				; Test Mode Button			
		
		

wait_here:
		rjmp wait	
;-----------------------------Setting up Input capture mode-------------------------------------------------
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

;--------------------------------- Getting the period--------------------------------------------------------
GET_K_REGION:
				sub R26 , R25
				ldi R25 ,2
;--------------------------------Deividing the preiod by two-----------------------------------------
DIVISION_By2:
				INC K_region
				SUB R26 , R25
				BRCC DIVISION_By2
				DEC  K_region

		wait:
			rjmp wait

;----------------------------------------Main loop that drives test mode of the Game--------------------------

Test_mode :
	rcall	RESET_ALL					
	Test:
	pop R16
	out PORTC , K_region
	rcall Trigger
	rjmp RAISING_EDGE

;---------------------------------------Timer1 four seconds delay ----------------------------------------
Delay_4s:
		sei
		push R16
		in R16 , sreg
		push R16
		lds R16 , GPIOR2
		sbrs R16, 1
		rjmp Test

		ldi R16 , 0b00000000
		sbi portd, 7
		cpse R16, r26
		rjmp TO
		sts TIMSK1 ,R16
		sub K_region, k_region_correct
		cpi K_region ,0
		BRNE Red
		sbi portd ,7
		rcall score_
		rjmp TO
Red :
		sbi portd , 6
		rcall decScore
TO:
		clr R17
		clr R16
		clr K_region
		pop R16
		out  sreg , R16
		pop R16
		rjmp L8


;----------------his loop has two functions---------------------------------------------
; Generate time based random numbers
; and time the Led time out

Delay_Gen : 
			sei
			push R29
			in R29 , sreg
			push R29
			inc R17 
			cpi R17, 61
			BRNE L2
			clr R17
			cbi portd , 7
			cbi portd , 6
			cbi portd , 5
		L2:					
			inc Random						; For each and every overflow timer2 a count is made 
			cpi Random  , 12																	
			BRNE L3 
			clr Random						; count reset to one when random become equal to 12
			inc Random	
		L3:								
			pop R29
			out  sreg , R29
			pop R29
			reti

;--------------------------The main loop for the playing mode-----------------------------
Play_Mode:
		ldi r16, 0b00000001
		sts  GPIOR2 , R16
		rcall	RESET_ALL	
	L8:	sei
		mov k_region_correct , Random
		push R16
		lds R16 , GPIOR1
		cpi R16 , 6
		BREQ GAMEOVER
		rcall Trigger
		inc R16
		sts GPIOR1 , R16
		pop R16
	L4:
		jmp RAISING_EDGE



;----------The loop that send signal to trigger pin and set timer---------------------------- 
TRIGGER:
		sbi portd , 4
		rcall DELAY_10us
		cbi portd , 4
		ldi R16 , 0b00000011
		sts TIMSK1 ,R16
		ret

;--------------------------------------Delay for sending trigger signal-----------------------
; The delay is a hardcoded 10us
DELAY_10us:
			ldi  r18, 53
		L1: dec  r18
			brne L1
			nop
			ret

;-------------------------Game over-----------------------------------------------
; The game overloop displays the attained score and displays red led if the score is negative
;
;
GAMEOVER:
		lds k_region_correct , GPIOR0
		sbrc K_region_correct , 7
		sbi portd , 6
	L12:
		out PORTC, k_region_correct
		rjmp L12

;----------------------------SCORE CAPTURE---------------------------------------
; The game consist of 12, K-region and the max score is 12 points, 
; displaying the score on PORTC is sufficient
; This is for decrementing the score
decScore:
		push R16
		in R16, sreg
		push R16
		lds R16, GPIOR0							; Using General Purpose register 0 to store the score value
		Dec R16
		pop R16
		out sreg , R16
		pop R16
		ret

; This is the logic for incrementing the score
Score_:
		push R16
		in R16, sreg
		push R16
		lds R16, GPIOR0
		inc R16
		cpi R16 , 9
		BREQ L9
		inc R16
		sts GPIOR0 , R16
		sbrc  R16 , 3
		clr R16
	L10:
		pop R16
		out sreg , R16
		pop R16
		ret
	L9: clr R16
		ldi R16 , 16
		sts GPIOR0 , R16
		rjmp L10
;---------------------Reset all interactive registers---------------------------------------------------
	RESET_ALL :
			clr K_region
			clr k_region_correct
			clr R16
			sts GPIOR0, K_region
			sts GPIOR1, K_region
			sts GPIOR2, K_region
			ret
			
;..........................................................END HERE..............................