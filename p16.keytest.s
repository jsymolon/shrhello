********************************************
			mx		%00				; full 16-bit mode
			rel						; relocatable output
			dsk	p16.keytest.l	;

PRODOS	equ	$e100a8			; prodos 16 entry
KYBD		equ	$c000				;
STROBE	equ	$c010				;
SCREEN	equ	$000400			; line 1

entry		phk						; program bank
			plb						; set data

			lda	#65
			ldx	#$00				; 
			stal	SCREEN,x			;

			lda	#0
			pha
			plb 
getkey	lda	KYBD				;
			and	#$00ff			;
			cmp	#$0080			;
			bcc	getkey			;
			stal	SCREEN,x			;
			cmp	#"Q"				;
			bne	getkey
			bit	STROBE			;

quit		jsl	PRODOS			;
			da		$29				; quit code
			adrl	parmbl			; parm block
			bcs	error				;
			brk						; severe error stop

parmbl	adrl	$0000				; ptr to pathname
flag		da		$00				;

error		brk

mssg		asc	"Please press a key -> " ; must be even # (16-bit)
			da		$0000