;µC Esclave : Gère l'écran LCD, l'alarme, le laser, et la communication IR avec l'exterieur
;il donne un signal au maître lorsqu'il a besoin de tirer
;Si jamais vous avez des questions sur ce squelette, demandez à Rémy
;===============================DECLARATION DES VARIABLES===============================
; Laser & Sirene
laser				bit		P1.2
sirene			bit		P1.3

; LCD
lcd_data			equ		P2

;=====================================INTERRUPTIONS=====================================
;---------------------------------------------------------------------------------------
;Mapping des interruptions
				ORG		0000h						;Au reset
				ljmp		debut
				
				ORG		0003h						;int0, mappée sur rien
				ORG		000Bh						;timer0
				ORG		0013h						;int1, mappée sur rien
				ORG		001Bh						;timer1, utilisé pour la série
				ORG		0023h						;lisaison serie (utilise le timer1) : déclenchée lors de la fin de réception d'un octet
				ljmp		intSerie					;ou lors de la fin de transmission d'un octet
;---------------------------------------------------------------------------------------
;Sous-programmes d'interruption
				ORG		0030h
;---------------------------------------------------------------------------------------
;Série : lorsque l'on est en réception, on stocke le message dans la RAM -> initialiser le registre pointeur (R0 ici) qui determine
;l'addresse à laquelle le message sera stocké
intSerie:
				jb			ri,reception
				jb			ti,transmission
				ljmp		finSerie
				
reception:
				clr		a
				mov		a,sbuf
				cjne		a,#30h,sauvegardeCarac	;Si le caractère correspond à une fin de ligne, on ne le sauvegarde pas (si ?)
				ljmp		finSerie						;code ASCII correspondant à une fin de ligne à vérifié
sauvegardeCarac:
				mov		@r0,a
				inc		r0
				ljmp		finSerie
		
transmission:
finSerie:
				clr		ri
				clr		ti
				RETI
;====================================SOUS-PROGRAMMES====================================
;---------------------------------------------------------------------------------------
;Série
config_lserie:
				mov		a,tmod
				anl		a,#0Fh
				orl		a,#20h
				mov		tmod,a
				mov 		scon,#40h
				mov		th1,#0E6h
				mov		tl1,#0E6h
				setb		tr1
				RET

;initialise les drapeaux d'interruption et leur priorités
init_interruption:
				setb		ea
				setb		es
				RET
				
;initialisation de la série (addresse de stockage des messages des dans la RAM, activation réception,...)
initialisation:
				lcall		config_lserie
				lcall		init_interruption
				mov		r0,#40h						;initialisation du pointeur à 40h
				setb		ren
				RET

;---------------------------------------------------------------------------------------
;Sous-programme LCD		
;==================================PROGRAMME PRINCIPAL==================================
debut:
				lcall initialisation
attente:	
				sjmp		attente
				END
