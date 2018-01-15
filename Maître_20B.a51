;soustraction et addition sur 16 bits
;commande du moteur et du servo de direction
;l'action sur un bouton poussoir met le bit a 0
;au debut les roues sont droites et le moteur est a l'arrˆt
;l'appui sur BP1 provoque(progressivement) l'acceleration et le braquage des roues a gauche la led s'allume
;l'appui sur BP0 provoque(progressivement) a deceleration et le braquage des roues a droite la led s'eteind
dir     		    bit     P1.4   ; commande de direction
mot    			 bit     p1.5   ; commande du moteur
tir    			 bit     p3.5   ; commande du tir
ledmC  			 bit     p1.0   ; indique æC en marche (led allumee si p1.0 = 0)
bp0     			 bit     p1.1   ; pour l'etalonnage et calibrage
bp1    			 bit     p1.2   ; pour calibrage
capg   			 bit     p1.7   ; capteur gauche
capd   			 bit     p1.6   ; capteur droit

;bit de flag
finint 			 bit     	6dh    ; indicateur de preparation du timer0
 
; declaration des octets
; valeurs de reference a charger dans Timer0
vd1h			equ		0fah		;(65536-1500)			
vd1l			equ		24h		;
vdr1h			equ		0fch		;(65536-1000)
vdr1l			equ		18h
vm1h			equ		0fah		;(65536-1310)
vm1l        equ		0e2h
vmr1h			equ		0c0h		;(65536-16190)
vmr1l			equ		0c2h

;memoires recevant les valeurs a charger dans Timer0 
;pour realiser les durees de:

vd2l			equ		7fh		; la direction
vd2h			equ		7eh
vdr2l			equ		7dh		; reste de la direction
vdr2h			equ		7ch
vm2l			equ		7bh		; du moteur
vm2h			equ		7ah
vmr2l			equ		79h		; reste du moteur
vmr2h			equ		78h

vth0			equ		6eh		; memoire intermediaire recevant les valeurs
vtl0			equ		6fh		; a transferer dans th0 et tl0

;mémoire permettant de stocker une indication de la vitesse
vitesse		equ		6ah		; nombre de raies en 1s
cmpt			equ		6bh 		; compte nombre de cycle de 20s
cmdvit		equ		6ch		; commande de vitesse
cmdvitrec	equ		5fh		; commande à mettre lorsque l'on accélère

;mémoire utilisée pour information de la liason série
sdata			equ		50h		; emplacement de stockage des données laision série

;----------------------------------------------------------------------
; plage des interruptions

				org		0000h			;reset
				ljmp		debut
				
				org		0003h			;interruption int0 pour capteur arrière
				inc		r5				; inc compteur de raies
				reti

				org		000Bh			;interruption timer0
				ljmp		pinttimer0

				org		0013h			;interruption int1
                              	         
				org		001Bh			;interruption timer1 

				org		0023h			;interruption liaison serie
				cpl		ledmC
				ljmp		sreception  ;réception série

				org		0030h
						
;-------------------------------------------------------------------
;programme d'interruption du Timer0. La periode set de 20ms separee en 4 durees:
;d= direction de 1 a 2ms, /d= reste de la direction pour completer a 2,5ms,
;m= moteur de 1 a 2ms, /m= reste du moteur pour completer a 17,5ms.

pinttimer0:
				push		psw
				push		acc

				; Ici, r0 controle le type d'action a effectuer.

tr0a0: 
				cjne		r0,#0,tr0a1		; direction
				mov		vtl0,vd2l
				mov		vth0,vd2h
				mov		r0,#1
				setb		dir
				sjmp		relancet0

tr0a1:  
				cjne		r0,#1,tr0a2		; complément de la direction
       		mov		vtl0,vdr2l
        		mov		vth0,vdr2h
        		mov		r0,#2
       		clr     	dir
       		sjmp		relancet0

tr0a2:  
				cjne		r0,#2,tr0a3		; moteur
       		mov		vtl0,vm2l
        		mov		vth0,vm2h
        		mov		r0,#3
				setb		mot
        		sjmp		relancet0

tr0a3:  
				mov		vtl0,vmr2l		; complément du moteur
				mov		vth0,vmr2h
				clr		mot
				mov		r0,#0
				setb		finint    		;pp peut traiter des nouvelles valeurs

relancet0:
				clr		tr0      ; arret du timer
				mov		a,tl0    ; lecture de la valeur … charger
				add		a,#08		; addition avec le reste du timer
				addc		a,vtl0   ; valeur … ajuster
				mov		tl0,a    ; chargement du poids faible du timer0
				mov		a,vth0   ; lecture de la valeur … charger dans th0
				addc		a,th0    ; pour tenir compte du d‚bordement
				mov		th0,a    ; chargement du poids fort du timer0
				setb		tr0      ; lancement du timer

restit:
				pop		acc
				pop		psw

				reti

;----------------------------------------------
;réception des données en liaison série

sreception:
				mov		a,sbuf
				mov		@r1,a		; stockage de la valeur de sduf dans a
				clr		ri 		; lance réception
				reti
				
;----------------------------------------------
;asservissement en vitesse

asserv_vit:
				lcall		sousmot	;augmentation de la durée du PWM moteur
				ret
;-----------------------------------------------
;augmentation de la durée moteur selon R7
sousmot: 								 		
				clr		c
				mov		a,vm2l
				subb		a,r7
				mov		vm2l,a
				mov		a,vm2h
				subb		a,#00h
				mov		vm2h,a 
restmot2:
				clr		c
				mov		a,vmr2l
				add		a,r7
				mov		vmr2l,a
				mov		a,vmr2h
				addc		a,#00h
				mov		vmr2h,a
				ret
;-------------------------------------------------------------------
;diminution de la duree moteur selon r7
; Ici, on fait (vm2 + r7). vm2 est 16bit, r7 est 8bit.
addmot:
				clr		c
				mov		a,vm2l
				add		a,r7
				mov		vm2l,a
				mov		a,vm2h
				addc		a,#00h
				mov		vm2h,a
restmot3:
				clr		c
				mov		a,vmr2l
				subb		a,r7
				mov		vmr2l,a
				mov		a,vmr2h
				subb		a,#00h
				mov		vmr2h,a
				ret 
;--------------------------------------------------------------------
;virage a gauche selon R6
virgauche:
				clr		c
				mov		a,vd2l
				add		a,r6
				mov		vd2l,a
				mov		a,vd2h
				addc		a,#00h
				mov		vd2h,a
restdir3:
				clr		c
				mov		a,vdr2l
				subb		a,r6
				mov		vdr2l,a
				mov		a,vdr2h
				subb		a,#00h
				mov		vdr2h,a
				ret
;----------------------------------------------------------------------
;virage a droite selon R6
virdroite:
				clr		c
				mov		a,vd2l
				subb		a,r6
				mov		vd2l,a
				mov		a,vd2h
				subb		a,#00h
				mov		vd2h,a 
restdir4:
				clr		c
				mov		a,vdr2l
				add		a,r6
				mov		vdr2l,a
				mov		a,vdr2h
				addc		a,#00h
				mov		vdr2h,a
				ret
				
;----------------------------------------------------------------------
;nombre de fois 20ms : on gère ici tout ce qu'on souhaite faire à la fin d'une commande (via le flag finint)
;test pour savoir si on peut modifier les valeurs de vd2l, vd2h
durecom:										 ; gère r3 =  Nb de commandes soit r3*20ms
 				jnb		finint,durecom
				clr		finint
				djnz		r3,durecom 		 ; r3 contient le Nb de commandes 
				ret
			
;------------------------------------------
; Pour le moment, voilà comment fonctionne le programme : debut configure le PWM et la série, et se bloque
; dans la boucle reglage, qui vérifie l'état des boutons poussoir, et ralentit & tourne à droite/ décelere & tourne à gauche
; (Le programme durecom attend simplement d'une durée r3*20ms)
;
; Ces actions sont executées par les sous-programmes accelere/decelere/tournedroite, etc... qui appellent respectivement
; addmot/sousmot/vidroite, etc qui change les valeurs des PWM en fonction de r6 pour la direction, r7 pour la vitesse
;
; Les sous-programmes accelere/decelere, etc... vérifient ensuite si les valeurs mise à jour sont bien dans les bornes,
; et modifie la valeur si ce n'est pas le cas.
;
; La led change d'état à chaque fois que l'on appuie sur l'un des boutons
debut:
				mov		sp,#30h				; pour sortir de la zone de banque
				mov		tmod,#01h			; T0 16bits
				lcall		config_ls			; configuration de la liaison série (timers,...)
				setb		it0					; active INT0 sur front descendant
				clr		dir 
				clr		mot
				clr		finint				; pas de fin d'interruption
; validation des interruptions du timer 0
				setb		et0					; enable intteruption timer0
				setb		ex0					; autorise interruptions INT0
        		setb		ea						; enable all ,validation generale
        		setb		es						; autorise interruption série
        		clr		pt0					; interruption timer0 en priorit‚ 0 (priorité basse)
        		clr		px0					; interruption int0 en priorité 0 (priotrité basse mais > timer0)	 
        		clr		ledmC

        		setb		ren					; autorise reception serie
        		mov		r1,#sdata			; initialisation du pointeur pour la réception série
        		mov		sdata,#0
        		mov		r5,#0					; initialisation mesure vitesse roue arrière
        		mov		vitesse,#0			; initialisation de la vitesse à 0
        		mov		cmdvit,#6			; initialisation de la commande de vitesse
        		mov		cmpt,#51				; initialise le compteur de cycle seconde
        		mov		r6,#25				; increment pour la direction
        		mov		r7,#3					; increment pour la vitesse
				mov		vd2l,#vd1l			; chargement de la valeur de repos 1500æs
				mov		vd2h,#vd1h			; pour la direction
				mov		vdr2l,#vdr1l		; chargement du complement (1000us)a 2,5ms
				mov		vdr2h,#vdr1h		; pour la direction 
				mov		vm2l,#vm1l			; chargement de la valeur de repos
				mov		vm2h,#vm1h			; pour le moteur
				mov		vmr2l,#vmr1l		; complement moteur
				mov		vmr2h,#vmr1h
				mov		r0,#0					; debut du traitement des signaux dir et mot
				mov		th0,#0FFh			; pour lancement du timer 0 premiŠre fois
				mov		tl0,#0F0h			; pour lancement du timer 0 premiŠre fois
				setb		tr0					; lancement du timer0
													; ensuite le timer se relance tout seul
				mov		r3,#1       		; 1x20ms = 20ms
				lcall		durecom    
reglage:											;réglage vitesse selon boutons poussoirs
				mov		a,p1
				rrc		a
				rrc		a						; recuperation de BP0 dans Carry
				jnc		ralentir				; si BP0 = 0 decelerer
				rrc		a						; r‚cup‚ration de BP1
				jnc		augmenter			; si BP1 = 0 accelerer
				mov		a,sdata
				; Decommente pour utiliser la balise IR !!!!!!!
				cjne		a,#30h,reglage    ; vérifie si l'on a recu 0 de la part de l'esclave, ce qui indique que l'on doit démarrer*
				;...................
				sjmp		asserv				; attente de l'appui sur un bouton
ralentir:										; augmente la commande de vitesse
				cpl		ledmc
				dec		cmdvit
				mov		r3,#25
				lcall		durecom
				sjmp		reglage
augmenter:										; diminue la commande de vitesse
				cpl		ledmc
				inc		cmdvit
				mov		r3,#25
				lcall		durecom
				sjmp		reglage
asserv:												;boucle d'asservissement de direction et de vitesse
				mov		cmdvitrec,cmdvit
				mov		sdata,#0
boucle_20ms:										;vérification de mesure de la vitesse à la fin de chaque 20 ms.
				jb			capg,droitecall		;tourne à gauche si le capteur gauche détecte du noir
				jb			capd,gauchecall		;tourne à droite si le capteur droit détecte du noir
				sjmp		toutdroitcall
gauchecall:
				lcall		tournegauche 
				sjmp		continue
droitecall:
				lcall		tournedroite
				sjmp     continue
toutdroitcall:
				lcall		toutdroit				;si jamais on ne detecte pas de sortie de piste, on revient vers le tout droit !
continue:
				mov		a,sdata
				cjne		a,#34h,verif0			;vérifie si l'on a recu 4 de la part de l'esclave
				mov		cmdvit,#2				;dans ce cas on ralenti à 2 tics/sec, sinon on vérifie si on a 0 (accélere)
				mov		sdata,#0
				sjmp		scontinue
verif0:		
				cjne		a,#30h,verif1			;si on a recu 0, c'est qu'il faut réaccélérer à l'ancienne vitesse (contenue dans cmdvitrec)
				mov		cmdvit,cmdvitrec
				mov		sdata,#0
				sjmp		scontinue
verif1:												;vérifie si on a reçu 1 --> on s'arrête
				cjne		a,#31h,scontinue
				mov		vm2h,#vm1h				;met les valeurs de PWM initiale pour arreter le vehicule
				mov		vm2l,#vm1l
				mov		vmr2h,#vmr1h
				mov		vmr2l,#vmr1l
				mov		sdata,#0
boucleverif1:
				sjmp		boucleverif1			;boucle d'arrêt
scontinue:
   			djnz		cmpt,fin_20ms			;décrémente le compteur et passe à l'instruction du dessous au bout des 1secondes
				mov		vitesse,r5				;déplace R5 (nombre de raies / secondes) dans vitesse
				mov		r5,#0						;réinitialise r5 à 0 pour le prochain cycle de 1sec
				mov		cmpt,#51					;remet le compteur des 1s à 51 pour 50 passages dans durecom
				mov		a,vitesse     		 	;preparation pour cjne
				cjne		a,cmdvit,differend 	;C=1 si A<8, C=0 si A>=8; compare la vitesse avec la commande de vitesse (désirée)
egal: 												;égal à la commande
     			sjmp		boucle_20ms
differend:
				jc			inf_commande_vit  	; La vitesse est trop faible -> augmente-là
				lcall		decelere 				; La vitesse est trop elevee -> décremente
				sjmp		boucle_20ms
inf_commande_vit: 								;actions à réaliser lorsque vitesse trop élevée
				lcall		accelere					;FONCE DANS MR LEBEGUE
				sjmp		boucle_20ms
fin_20ms:									
   			mov		r3,#1						;Attente de la fin du cycle de 20ms après lcall durecom
   			lcall		durecom
   			sjmp		boucle_20ms
	
;--------------------------------------------------------------------
;deceleration: diminuer la duree m de l'impulsion moteur revient a augmenter
;la valeur vm a charger dans Timer 0: vm=(65536-m)
decelere:			
				lcall		addmot					; calcul des valeurs a charger dans T0
				mov		a,vm2h					; test a la valeur max de vm
				cjne		a,#0fch,diffh2			; saut si vm2h different de 0fch
				mov		a,vm2l
				cjne		a,#18h,diffl2
				ljmp		sortie_dec
diffl2:
				jc			sortie_dec
				sjmp		suph2
diffh2:
				jc			sortie_dec
suph2:
				mov		vm2h,#0fch				; chargement des valeurs max
				mov		vm2l,#18h				; (65536-1000)=64536d=fc18h
				mov		vmr2h,#0bfh				; reste du moteur
				mov		vmr2l,#8ch				; (65536-16500)=49036d=bf8ch
												
sortie_dec:	            																	
				ret
				
;-------------------------------------------------------------
;acceleration: augmenter la duree m de l'impulsion moteur revient a
;diminuer la valeur vm a charger dans Timer0: vm=(65536-m)

accelere:
				lcall		sousmot					;calcul des valeurs a charger dans T0
				mov		a,vm2h					; test a la valeur min de vm
				cjne		a,#0f8h,diffh1
				mov		a,vm2l
				cjne		a,#30h,diffl1

diffh1:
				jc			infh1
				ljmp		sortie_acc
diffl1:
				jc			infh1
				ljmp		sortie_acc
infh1:
				mov		vm2h,#0f8h				; chargement de la valeur min 
				mov		vm2l,#30h				;(65536-2000)=63536d=f830h
				mov		vmr2h,#0c3h				; reste de l'impulsion 
				mov		vmr2l,#74h				;(65536-15500)=50036d=c374h

sortie_acc:												
        		ret
        		
;------------------------------------------------------------------------
tournedroite:
       		lcall		virdroite				; calcul des valeurs a charger dans T0
            mov		a,vd2h
            cjne		a,#0f8h,diffh3			; si vd2h < sup, c=1
            mov		a,vd2l
            cjne		a,#0a8h,diffl3
            sjmp		sortie_droite3
diffl3:
				jc			suph3
				sjmp		sortie_droite3
diffh3:
				jc			suph3
				sjmp		sortie_droite3
suph3:
				mov		vd2h,#0f8h				; chargement de la valeur max de l'impulsion
				mov		vd2l,#0a8h				; (65536-1880)
				mov		vdr2h,#0fdh				; reste de l'impulsion 
				mov		vdr2l,#94h 
				
sortie_droite3:
				ret
				
;-------------------------------------------------------------------------					
tournegauche:
				lcall		virgauche				; calcul des valeurs a charger dans T0
				mov		a,vd2h
				cjne		a,#0fbh,diffh4			; si vd2h < inf, c=1 donc on modifie (jmp infh4)
				mov		a,vd2l
				cjne		a,#0a9h,diffl4
diffh4:
				jc			sortie_gauche2
				sjmp		infh4
diffl4:
				jc			sortie_gauche2
infh4:
				mov		vd2h,#0fbh				; chargement des valeurs min
				mov		vd2l,#0a9h				; (65536-1120)
				mov		vdr2h,#0fah				; reste de l'impulsion
				mov		vdr2l,#09ch
	
sortie_gauche2:
				ret
				
;--------------------------------------------------------------------------
toutdroit:
				mov		vd2h,#vd1h
				mov		vd2l,#vd1l
				mov		vdr2h,#vdr1h
				mov		vdr2l,#vdr1l	
				ret
				
;--------------------------------------------------------------------------

config_ls:
				mov		a,tmod					; on met un commentaire pour faire genre
				anl		a,#0Fh 					; garde les valeurs de timer0
				orl		a,#20h 					; timer1 8bits avec rechargement
				mov		tmod,a
				mov		scon,#40h				; mode asynchrone 1 start, 8 bits, 1 stop selon timer1
				mov		th1,#0e6h 				; timer1 de 1200 bauds
				mov		tl1,#0e6h		 
				setb		tr1
				
				ret

;--------------------------------------------------------------------------
        		end
