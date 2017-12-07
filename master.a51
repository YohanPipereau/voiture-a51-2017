; Microcontrolleur ma�tre
; Remi & Yohan


;	Variables ------------------------------------------------------------------

dir     		    bit     P1.4   ; commande de direction
mot    			 bit     p1.5   ; commande du moteur
tir    			 bit     p3.5   ; vers P3.4 esclave pour tir
ledmC  			 bit     p1.0   ; indique �C en marche (led allumee si p1.0 = 0)
bp0     			 bit     p1.1   ; calibrage, ralentir, bouton rouge
bp1    			 bit     p1.2   ; calibrage, acc�l�rer, bouton vert
capg   			 bit     p1.7   ; capteur gauche avant
capd   			 bit     p1.6   ; capteur droit avant
serie_rx			 bit	   P3.0   ; bit en r�ception de la laison s�rie
capt_ar			 bit		P3.2   ; capteur IR arri�re -> mesure vitesse rotation
rx_ir				 bit		P3.3	 ; r�ception infrarouge transmise � l'esclave



