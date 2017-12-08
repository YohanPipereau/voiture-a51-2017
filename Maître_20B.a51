;µC Maître : Gère l'asservissement en vitesse et en position, il s'arrête (ou ralentit) si l'esclave
;a besoin de tirer (bit tir)
;===============================DECLARATION DES VARIABLES===============================
; Capteurs (le capteur arrière est relié à l'interruption 0) :
captG				bit		P1.7						;Capteur Gauche
captD				bit		P1.6						;Capteur Droit

; Commandes, la gestion du PWM est faite par un timer mais ce sont bien
; 2 pins différentes qui rélisent la commande :
direction		bit		P1.4						;Pour PWM de direction
moteur			bit		P1.5						;Pour PWM de vitesse
initAcc			bit		P1.2						;Pour initialiser la vitesse
initDec			bit		P1.1
tir				bit		P3.5						;Reliée à l'esclave, cette donnée est régulièrement lue
															;pour savoir s'il on doit s'arrêter pour pouvoir tirer 

; Variables de références Timer0; on va tout droit (1500) et vite, puisque l'on démarre (1000 ??) :
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
				
				ORG		0003h                ;int0, relié au capteur arrière
				ljmp		incVitesse
				
				ORG		000Bh                ;timer0, utilisé pour le PWM
				ljmp		PWMDir
				
				ORG		0013h						;int1, relié à rien
				
				ORG		001Bh						;timer1, utilisé pour la série
				ljmp		majVitesse
				
				ORG		0023h						;liaison serie en mode réception uniquement
				ljmp		message
				
;---------------------------------------------------------------------------------------
;Sous-programmes d'interruption
				ORG		0030h
;---------------------------------------------------------------------------------------
;Int0 : Mise à jour pour le calcul de vitesse 
incVitesse:
				djnz		r1, continue			;On compte tout simplement le nombre de fronts descendants dans un registre sur 20 ms
continue:									
				RETI
				
;---------------------------------------------------------------------------------------
;Timer0 : Gestion du PWM : on gère le timer par étape, en utilisant un registre qui indique quelle est l'étape à gérer
;Etape 0 : début du PWM, on charge dans le timer0 la valeur du PWM direction, on met le bit direction à 1 et on incrémente le compteur d'étape
;Etape 1 : on charge le complément à 2.5ms de la valeur du PWM de drection dans le timer0, met le bit de direction à 0 et on incrémente le compteur d'étape
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
;Liaison Série
message:
				RETI
				
;====================================SOUS-PROGRAMMES====================================
;---------------------------------------------------------------------------------------
;Initialisation : capture de la vitesse calibrée via les boutons poussoir + initialisation des timers +... ??
;---------------------------------------------------------------------------------------
;Tourner à droite
;---------------------------------------------------------------------------------------
;Tourner à gauche
;---------------------------------------------------------------------------------------
;Accélérer
;---------------------------------------------------------------------------------------
;Décelerer
;==================================PROGRAMME PRINCIPAL==================================
; Découpé en trois parties : initialisation, boucle d'asservissement, et fin
debut:
				END
