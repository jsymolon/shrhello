********************************************
* p16 launcher demo
* launches 2nd system file, stays dormant
* then revived
* Merlin Assembler
********************************************
			mx		%00				; full 16-bit mode
			rel						; relocatable output
			dsk	p16.launch.l	;

PRODOS	equ	$e100a8			; prodos 16 entry
KYBD		equ	$c000				;
STROBE	equ	$c010				;
COUT		equ	$fded
SCREEN	equ	$000400			; line 1
SCREEN2	equ	$000500
SCREEN3	equ	$000580
SCREEN4	equ	$000600

entry		phk						; program bank
			plb						; set data

print		ldx	#$00				; 
loop		lda	mssg,x			; get char
			beq	getkey			; end of msg
			stal	SCREEN,x			;
			inx						;
			inx						;
			bne	loop				;

			lda	#0 				; ROM routines need DBR = 0
			pha
			plb 
getkey	
			lda	KYBD				;
			and	#$ff				;
			cmp	#$80				;
			bcc	getkey			;
			bit	STROBE			;

chk		cmp	#"0"				; quit to rom
			beq	quit0				;
			cmp	#"1"				; quit to rom
			beq	quit1				;
			cmp	#"2"				; quit to rom
			beq	quit2				;
			cmp	#"3"				; quit to rom
			beq	quit3				;

tryagn	jml	getkey			;

quit0		jsl	PRODOS			;
			da		$29				; quit code
			adrl	parmbl0			; parm block
			bcs	error				;
			brk						; severe error stop

quit1		jsl	PRODOS			;
			da		$29				; quit code
			adrl	parmbl1			; parm block
			bcs	error				;
			brk						; severe error stop

quit2		jsl	PRODOS			;
			da		$29				; quit code
			adrl	parmbl2			; parm block
			bcs	error				;
			brk						; severe error stop

quit3		jsl	PRODOS			;
			da		$29				; quit code
			adrl	parmbl3			; parm block
			bcs	error				;
			brk						; severe error stop

parmbl0	adrl	name0				; ptr to pathname
flag0		da		$00				;

parmbl1	adrl	$0000				; ptr to pathname
flag1		da		$00				;

parmbl2	adrl	name1				; ptr to pathname
flag2		da		$00				;

parmbl3	adrl	name1				; ptr to pathname
flag3		da		$00				;

error		brk

mssg		asc	"Press 0, 1, 2, or 3 ->" ; must be even # (16-bit)
			da		$0000

* 0 - quit to rom restart
* 1 - quit to prev program
* 2 - launch p16
* 3 - launch p16 and return when done

name0		dfb	1					; len of 0
			asc	"X"				;
name1		dfb	namend-name1-1 ; len of path
			asc	"P16.SYSTEM"	; test file
namend	
