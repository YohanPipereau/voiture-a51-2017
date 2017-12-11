;�C Ma�tre : G�re l'asservissement en vitesse et en position, il s'arr�te (ou ralentit) si l'esclave
;a besoin de tirer (bit tir)
;===============================DECLARATION DES VARIABLES===============================
; Capteurs (le capteur arri�re est reli� � l'interruption 0) :
captG				bit		P1.7						;Capteur Gauche
captD				bit		P1.6						;Capteur Droit

; Commandes, la gestion du PWM est faite par un timer mais ce sont bien
; 2 pins diff�rentes qui r�lisent la commande :
direction		bit		P1.4						;Pour PWM de direction
moteur			bit		P1.5						;Pour PWM de vitesse
initAcc			bit		P1.2						;Pour initialiser la vitesse
initDec			bit		P1.1
tir				bit		P3.5						;Reli�e � l'esclave, cette donn�e est r�guli�rement lue
															;pour savoir s'il on doit s'arr�ter pour pouvoir tirer 

; Variables de r�f�rences Timer0; on va tout droit (1500) et vite, puisque l'on d�marre (1000 ??) :
dureeDirH		equ									;(65536-1500)
dureeDirL		equ									
dureeVitH		equ									;(65536-1000)
dureeVitL		equ									

; Variables Timer0 pour la direction : 2 variables de timers qui changent; 1 pour la 
; direction et 1 pour la vitesse :

;=====================================INTERRUPTIONS=====================================
;---------------------------------------------------------------------------------------
;Mapping des interruptions
				ORG		0000h						;Au reset
				ljmp		debut
				
				ORG		0003h                ;int0, reli� au capteur arri�re
				ljmp		incVitesse
				
				ORG		000Bh                ;timer0, utilis� pour le PWM
				ljmp		PWMDir
				
				ORG		0013h						;int1, reli� � rien
				
				ORG		001Bh						;timer1, utilis� pour la s�rie
				ljmp		majVitesse
				
				ORG		0023h						;liaison serie en mode r�ception uniquement
				ljmp		message
				
;---------------------------------------------------------------------------------------
;Sous-programmes d'interruption
				ORG		0030h
;---------------------------------------------------------------------------------------
;Int0 : Mise � jour pour le calcul de vitesse 
incVitesse:
				djnz		r1, continue			;On compte tout simplement le nombre de fronts descendants dans un registre sur 20 ms
continue:									
				RETI
				
;---------------------------------------------------------------------------------------
;Timer0 : Gestion du PWM : on g�re le timer par �tape, en utilisant un registre qui indique quelle est l'�tape � g�rer
;Etape 0 : d�but du PWM, on charge dans le timer0 la valeur du PWM direction, on met le bit direction � 1 et on incr�mente le compteur d'�tape
;Etape 1 : on charge le compl�ment � 2.5ms de la valeur du PWM de drection dans le timer0, met le bit de direction � 0 et on incr�mente le compteur d'�tape
;Etape 2 : on charge dans le timer0... bref, vous avez compris
; + calcul de vitesse
PWMDir:
				clr		tr0
				cjne		r0,#0,PWMFinDir
				setb		direction
				;TODO
				inc 		r0
				sjmp		PWMfin
PWMFinDir:
				cjne		r0,#1,PWMMot
				clr		direction
				;TODO
				inc		r0
				sjmp		PWMfin
PWMMot:
				cjne		r0,#2,PWMFinMot
				setb		moteur
				;TODO
				inc		r0
				sjmp		PWMfin
PWMFinMot:
				clr		moteur
				;TODO
				mov		r0,#0
PWMFin:
				RETI
				
;---------------------------------------------------------------------------------------
;Timer 1 : Calcul de la vitesse
majVitesse:
				RETI
				
;---------------------------------------------------------------------------------------
;Liaison S�rie
message:
				RETI
				
;====================================SOUS-PROGRAMMES====================================
;---------------------------------------------------------------------------------------
;Initialisation : capture de la vitesse calibr�e via les boutons poussoir + initialisation des timers +... ??

	org 		0030h	

timer40ms: ;timer �l�mentaire de 40 msecondes
	mov		a,tmod		;r�cup�re ancien timer
	mov		th1,			;fixe les poids fort du timer
	mov		tl1			;fixe les poids faible du timer
	anl		a,#10h		;utilisation du timer sur 16 bits avec horloge interne
	orl		tmod,a		;r��criture de tmod
	setb		tr1			;mise en marche du timer1
	ret
	
timer5s: ;timer de 5secondes
	mov		R1,#50		
boucletimer5s:
	djnz		R1,boucletimer5s
	lcall		timer40ms
	ret

	

; Programme principal --------------------------------------------------------

debut:
	setb		ea 		; autorise les interruptions
	setb		et1		;autorise l'interruption pour le timer0
	lcall		timer5s	;appel du timer pour initialiser dir et vitesse
init_vit_dir:
	jnb		initDec, decelerer_initDec
	jnb		initAcc, accelerer_initAcc	
	sjmp		init_vit_dir
accelerer_initAcc:  ;incr�mente le PWM avec bouton poussoir
	jnb		initDec,decelerer_initDec
	jc			decelerer_initDec ; Si d�passement de ffffh, on soustrait 100
	clr		C
	mov		A,dureeVitL
	add		A,#100		;ajoute 100 � dureeVitL
	mov		A,dureeVitH
	addc		A,#0			 ;ajout de l'�ventuel carry dans dureeVitH
	jc			decelerer_initDec	;en esp�rant que addc remette le carry � 0
	add		A,#100
	ljmp		init_vit_dir
decelerer_initDec: ; d�cr�mente le PWM avec bouton poussoir
	clr		C
	subb		dureeVitL,#100
	ljmp		init_vit_dir
	
fin:	;le programme de fin doit arr�ter le v�hicule et boucler
bouclefin:
	sjmp		fin

	
	END

;---------------------------------------------------------------------------------------
;Tourner � droite
;---------------------------------------------------------------------------------------
;Tourner � gauche
;---------------------------------------------------------------------------------------
;Acc�l�rer
;---------------------------------------------------------------------------------------
;D�celerer
;==================================PROGRAMME PRINCIPAL==================================
; D�coup� en trois parties : initialisation, boucle d'asservissement, et fin
debut:
				END
