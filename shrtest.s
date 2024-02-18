		rel	; Compile
		dsk shrhello.l	; Save Name
		mx %00
		phk	; Set Data Bank to Program Bank
		plb	; Always do this first!
CH           	EQU   $24			; cursor Horiz
CV           	EQU   $25			; cursor Vert
ROW		EQU	$FA	; row/col in text screen
COLUMN		EQU	$FB
CHAR		EQU	$FC	; char/pixel to plot
PROGRESS 	EQU	$FD	; write to main or alt
PLOTROW		EQU	$FE	; row/col in text page
PLOTCOLUMN	EQU	$FF

TT		equ	$F4
dx		equ	$E0
dy		equ	$E2
sx		equ	$E4
sy		equ	$E6
err		equ	$E8	
er2		equ	$EA
penx		equ	$EC
peny		equ	$EE
tx		equ	$F0			
ty		equ	$F2

STACK         equ $100

TXTPG0        equ $0400
TXTPG1        equ $0800
EXITDOS       equ $03D0

KEY          	EQU $C000
C80STOREOFF  	EQU $C000
C80STOREON   	EQU $C001
RAMWRTAUX    	EQU $C005
RAMWRTMAIN   	EQU $C004
SET80VID     	EQU $C00D       ;enable 80-column display mode (WR-only)
ALTCHAR 	EQU $C00F		; enables alternative character set - mousetext
STROBE       	EQU $C010
RDVBLBAR     	EQU $C019       ;not VBL (VBL signal low
VBL          	EQU $C02E
SPEAKER      	EQU $C030
LORES        	EQU $C050
TXTSET       	EQU $C051
MIXCLR       	EQU $C052
MIXSET       	EQU $C053
TXTPAGE1     	EQU $C054
ALTTEXTOFF	EQU $C054
TXTPAGE2     	EQU $C055
ALTTEXT		EQU $C055
SETAN3       	EQU $C05E       ;Set annunciator-3 output to 0
STROUT		EQU $DB3A 		;Y=String ptr high, A=String ptr low

CLRLORES     	EQU $F832
ROMINIT      	EQU $FB2F
VTAB         	EQU $FC22       ; Sets the cursor vertical position (from CV)
HOME		EQU $FC58			; clear the text screen
WAIT		EQU $FCA8 
RDKEY         	EQU $FD0C
COUT          	equ $FDED
OUTPORT      	equ $FE95
ROMSETKBD    	EQU $FE89
ROMSETVID    	EQU $FE93

	org $803	; starting address

Start
		lda #"*"
                sta PLOTCHAR
		lda #1
		sta peny
                sta penx
		jsr PLOTCHAR

		lda #2
		sta peny
                sta penx
		jsr PLOTCHAR
                
                lda #3
                sta peny
                sta penx 
                lda #5
                ldy #10
                ldx #10
                jsr lineto

		jmp Start	; endless loop

;................................................................
WaitKey	
wait		lda 	$c000			; 
		bpl 	wait			; 
		sta 	$c010			; 
		rts
;................................................................
; storage for the drawing routines
pencolor	da	1

;................................................................
; MoveTo -
moveto
			stx	penx				;
			sty	peny				;
			rts						;
;................................................................

; LineTo - A pencolor, X -> X1, Y -> Y1, penx -> X0, peny -> Y0
;        - exit: penx, peny = X1, Y1 (setup for next call)
;        - uses ZP: dx:E0-1, dy:E2-3, sx:E4-5, sy:E6-7, err:E8-9, e2: ea-b
lineto
			sta	pencolor			;
			stx	tx					;
			sty	ty					;
; int dx = abs (x1 - x0); int sx = x0 < x1 ? 1 : -1;
			txa						; x1 -> A
			sec						;
			sbc	penx				; A = x1 - x0
			bcc	l2_sx1			; x0 < x1 ?
			pha						;
			lda	#1					;
			sta	sx					; x0 < x1 -> sx = 1
			jmp	l2_absx			;
l2_sx1
			pha						;
			lda	#$ff			;
			sta	sx					; x0 > x1 -> sx = -1
l2_absx
			pla						;
			and	#$7f			; ABS(x1-x0)
			sta	dx					; -> dx
; int dy = -abs(y1 - y0); int sy = y0 < y1 ? 1 : -1;
			lda	ty			; y1 -> A
			sec						;
			sbc	peny			; A = y1 - y0
			bcc	l2_sy1			; y0 < y1 ?
			pha						;
			lda	#1					;
			sta	sy					; y0 < y1 -> yx = 1
			jmp	l2_absy			;
l2_sy1
			pha						;
			lda	#$ff			;
			sta	sy					; y0 > y1 -> yx = -1
l2_absy
			pla						;
			ora	#$80			; -ABS(x1-x0)
			sta	dy					; -> dy
; int err = dx + dy
			lda	dx
			clc						;
			adc	dy					;
			sta	err				;
; int e2
; while (true)
l2_while
; plot (x0, y0)
			ldx	penx				; "x0"
			ldy	peny				; "y0"	
			lda	pencolor			;
			jsr	PLOTCHAR            ; plot it
; if (x0==x1 && y0==y1) break
			lda	tx					;
			cmp	penx				;
			bne	l2_skip1			; x1 != x0
			lda	ty					;
			cmp	peny				;
			beq	l2_break			; x1 == x0 && y1 == y0 -> break;
l2_skip1
; er2 = 2 * err
			lda	err				;
			asl						; err * 2
			sta	er2				;
; if ( er2 >= dy )
			cmp	dy					;
			bpl	l2_skip2			;
; 	if ( x0 == x1 ) break
			lda	tx					;
			cmp	penx				;
			beq	l2_break			; (x1 == x0)
; err = err + dy
			lda	err				;
			clc						;
			adc	dy					;
			sta	err				;
; x0 = x0 + sx
			lda	penx				;
			clc						;
			adc	sx					;
			sta	penx				;
l2_skip2
; if ( er2 <= dx )
			lda	er2				;
			cmp	dx					;
			bmi	l2_while			;
; 	if ( y0 == y1 ) break
			lda	ty					;
			cmp	peny				;
			beq	l2_break			; (y1 == y0)
; err = err + dx
			lda	err				;
			clc						;
			adc	dx					;
			sta	err				;
; y0 = y0 + sy
			lda	peny				;
			clc						;
			adc	sy					;
			sta	peny				;
; end while
			jmp	l2_while			;
l2_break
; return, leave penx, peny with cur pos
			lda	tx					;
			sta	penx				;
			lda	ty					;
			sta	peny				;
			rts
;................................................................
; SetPenColor - 
setpencolor
			sta	pencolor			;
			rts					;
                        
;**************************************************
;* Awesome PRNG thx to White Flame (aka David Holz)
;**************************************************
GetRand
                  lda   _randomByte
                  beq   :doEor
                  asl
                  bcc   :noEor
:doEor            eor   #$1d
:noEor            sta   _randomByte
                  rts
_randomByte       da    0

GetRandLow
                  lda   _randomByte2
                  beq   :doEor1
                  asl
                  bcc   :noEor1
:doEor1           eor   #$1d
:noEor1           sta   _randomByte2
                  cmp   #$80
                  bcs   :hot
                  lda   #$0
                  rts
:hot              lda   #$04
                  rts

_randomByte2      da    0
;................................................................
PLOTCHAR	nop
		LDY peny
                nop
		LDA LoLineTableL,Y
                nop
		STA TT
                nop
		LDA LoLineTableH,Y
                nop
		STA TT+1       		; now word/pointer at $0+$1 points to line 
		LDY penx
		LDA CHAR		; this would be a byte with two pixels
		STA (TT),Y  
		RTS

;**************************************************
;* Lores/Text lines - digarok/flapple
;**************************************************
Lo01                 equ   $400
Lo02                 equ   $480
Lo03                 equ   $500
Lo04                 equ   $580
Lo05                 equ   $600
Lo06                 equ   $680
Lo07                 equ   $700
Lo08                 equ   $780
Lo09                 equ   $428
Lo10                 equ   $4a8
Lo11                 equ   $528
Lo12                 equ   $5a8
Lo13                 equ   $628
Lo14                 equ   $6a8
Lo15                 equ   $728
Lo16                 equ   $7a8
Lo17                 equ   $450
Lo18                 equ   $4d0
Lo19                 equ   $550
Lo20                 equ   $5d0
;* the "plus four" lines
Lo21                 equ   $650
Lo22                 equ   $6d0
Lo23                 equ   $750
Lo24                 equ   $7d0

LoLineTableH      hex 0404050506060707
                  hex 0404050506060707
                  hex 0404050506060707
LoLineTableL      hex 0080008000800080
                  hex 28a828a828a828a8
                  hex 50d050d050d050d0
MainAuxMap
                  hex   00080109020A030B040C050D060E070F
                  hex   80888189828A838B848C858D868E878F
                  hex   10181119121A131B141C151D161E171F
                  hex   90989199929A939B949C959D969E979F
                  hex   20282129222A232B242C252D262E272F
                  hex   A0A8A1A9A2AAA3ABA4ACA5ADA6AEA7AF
                  hex   30383139323A333B343C353D363E373F
                  hex   B0B8B1B9B2BAB3BBB4BCB5BDB6BEB7BF
                  hex   40484149424A434B444C454D464E474F
                  hex   C0C8C1C9C2CAC3CBC4CCC5CDC6CEC7CF
                  hex   50585159525A535B545C555D565E575F
                  hex   D0D8D1D9D2DAD3DBD4DCD5DDD6DED7DF
                  hex   60686169626A636B646C656D666E676F
                  hex   E0E8E1E9E2EAE3EBE4ECE5EDE6EEE7EF
                  hex   70787179727A737B747C757D767E777F
                  hex   F0F8F1F9F2FAF3FBF4FCF5FDF6FEF7FF
