;�C Esclave : G�re l'�cran LCD, l'alarme, le laser, et la communication IR avec l'exterieur
;il donne un signal au ma�tre lorsqu'il a besoin de tirer
;Si jamais vous avez des questions sur ce squelette, demandez � R�my
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
				
				ORG		0003h						;int0, mapp�e sur rien
				ORG		000Bh						;timer0
				ORG		0013h						;int1, mapp�e sur rien
				ORG		001Bh						;timer1, utilis� pour la s�rie
				ORG		0023h						;lisaison serie (utilise le timer1) : d�clench�e lors de la fin de r�ception d'un octet
				ljmp		intSerie					;ou lors de la fin de transmission d'un octet
;---------------------------------------------------------------------------------------
;Sous-programmes d'interruption
				ORG		0030h
;---------------------------------------------------------------------------------------
;S�rie : lorsque l'on est en r�ception, on stocke le message dans la RAM -> initialiser le registre pointeur (R0 ici) qui determine
;l'addresse � laquelle le message sera stock�
intSerie:
				jb			ri,reception
				jb			ti,transmission
				ljmp		finSerie
				
reception:
				clr		a
				mov		a,sbuf
				cjne		a,#30h,sauvegardeCarac	;Si le caract�re correspond � une fin de ligne, on ne le sauvegarde pas (si ?)
				ljmp		finSerie						;code ASCII correspondant � une fin de ligne � v�rifi�
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
;S�rie
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

;initialise les drapeaux d'interruption et leur priorit�s
init_interruption:
				setb		ea
				setb		es
				RET
				
;initialisation de la s�rie (addresse de stockage des messages des dans la RAM, activation r�ception,...)
initialisation:
				lcall		config_lserie
				lcall		init_interruption
				mov		r0,#40h						;initialisation du pointeur � 40h
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
