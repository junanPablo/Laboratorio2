;*******************************************************************************
;                                                                              *
;    Filename: LABORATORIO 2
;    Date: 09/02/2018
;    File Version: 1
;    Author: Juan Pablo Merck, 13076
;*******************************************************************************
;*******************************************************************************
;----------PALABRA DE CONFIGURACION----------
;*******************************************************************************
#include "p16f887.inc"

; CONFIG1
; __config 0x20D4
 __CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
; CONFIG2
; __config 0x3FFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF

;*******************************************************************************
;------------- VARIABLES -------------
;*******************************************************************************
GPR_VAR        UDATA
    CONT25ms         RES        1
    almacena1        RES        1
    almacena2        RES        1
    const	     RES	1
    CONT1         RES        1      
    CONT2         RES        1     

;*******************************************************************************
;------------- Reset Vector -----------------
;*******************************************************************************
RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program

;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************
MAIN_PROG CODE                      ; let linker place main program
START
 
;*******************************************************************************
; ------------------- CONFIGURATION ------------------
;*******************************************************************************
;config osccon para tener los 8 MHz
  ;accediendo al banco 1
    BCF STATUS , RP1	
    BSF STATUS, RP0
    ;colocando la senial a 8MHz
    BSF OSCCON, IRCF2
    BSF OSCCON, IRCF1
    BSF OSCCON, IRCF0
    ;BCF OSCCON, OSTS;configurando al relejor interno
    BSF OSCCON, SCS;config a oscilador interno
    
 ;config puerto D Como salidas para los dos contadores de 4 bits
    ;config TRISD
    MOVLW B'00000000'
    MOVWF TRISD;outputs <7:0>
    ;accediendo al banco 0
    BCF STATUS , RP1	
    BCF STATUS, RP0
    ;limpiando PORTD
    CLRF PORTD
    
;config puerto B como entradas
    ;accediendo al banco 1
    BCF STATUS , RP1	
    BSF STATUS, RP0
    ;config TRISB
    MOVLW b'00000011'
    MOVWF TRISB; RB inputs<1:0> y outputs <7:2>
    ;accediendo al banco 3
    BSF STATUS , RP1	
    BSF STATUS, RP0
    MOVLW B'00000000'
    MOVWF ANSELH ;colocando como canal digital
    MOVWF ANSEL; colocando como canal digital
    ;accediendo al banco 0
    BCF STATUS , RP1	
    BCF STATUS, RP0
    ;limpiando PORTB
    CLRF PORTB
    CALL INITTMR0;llamando a etiqueta
    ;accediendo al banco 0
    BCF STATUS , RP1	
    BCF STATUS, RP0
    CLRF PORTB
     
;*******************************************************************************
; ------------------- MAIN PROGRAM ----------------
;*******************************************************************************
LOOP:
    
    ;----------------------------------------------
    ;contador ascente automatico
    INCF PORTD, F
    CALL CheckT0IF
    ;haciendo que solo se enciendan los primeros 4 bits del registro D <0:3>
    MOVF PORTD, W;moviendo el valor actual de pueto
    MOVWF almacena1
    ANDLW B'00001111' ;conciderando los primeros 4 bits del puerto D
    SUBLW B'00001111' ; restando 
    BTFSC STATUS, Z ;if(z==HIGH){ejecutar limpa}else{salta limpia y ejecutar LOOP}
    CALL Limpia
    
    MOVLW B'00010000';constante que servira para incremetar o restar el segundo contador de 4 bits que es manual
    MOVWF const
    
    ;---------------------------------------------
    ;contador con botones ascendente y descendente
    BTFSC PORTB,0
    CALL Aumento
    
    BTFSC PORTB,1
    CALL Decremento
    MOVF PORTD,W;moviendo los 4 bits mas significativos <7:4>
    MOVWF almacena2
    
    ;verifica para cuando hay desborde
    ANDLW B'11110000';eliminando los bits que no me interesan
    SUBLW B'11110000';restando
    BTFSC STATUS,Z
    CALL Limpia2
    
    ;verifica para cuando llega a 0000xxxx
    MOVF almacena2,W
    ANDLW B'11110000';eliminando los bits que no me interesan
    SUBLW B'00000000';restando
    BTFSC STATUS,Z
    CALL Limpia2
    
    ;verificar cuando son iguales
    MOVLW B'00001111'
    ANDWF almacena1,1
    MOVLW B'11110000';and a almacena1 y guardandolo en almacena1
    ANDWF almacena2,1;haciendo una And a almacena2 y guardandolo en almacena2
    SWAPF almacena2,0;cambio de los nibbles y guardado en W
    SUBWF almacena1,0
    BTFSC STATUS,Z
    CALL LED
    
    GOTO LOOP
;*******************************************************************************
; ------------------- FUNCIONES ----------------
;*******************************************************************************   
    
INITTMR0:
    ;Config OPTION_REG
    ;accediendo al banco 1
    BCF STATUS , RP1	
    BSF STATUS, RP0
    ;Configurando el registro OPTION_REG
    BCF OPTION_REG, T0CS;modo temporizador
    BCF OPTION_REG, PSA;asignando prescaler a TMR0
    ;colocando preescaler de 1:256
    BSF OPTION_REG, PS2
    BSF OPTION_REG, PS1
    BSF OPTION_REG, PS0
    ;accediendo al banco 0
    BCF STATUS , RP1	
    BCF STATUS, RP0
    ;colocando el valor de 25 al N de la ecuacion
    MOVLW .61
    MOVWF TMR0; cargamos el valor de N que es de 25
    BCF INTCON, T0IE
    RETURN
    
CheckT0IF:
    ;accediendo al banco 0
    BCF STATUS , RP1	
    BCF STATUS, RP0
    
    BTFSS INTCON, T0IF
    GOTO CheckT0IF
    BCF INTCON, T0IF
    MOVLW .61
    MOVWF TMR0
    INCF CONT25ms,F
    MOVF CONT25ms,W
    SUBLW .4
    BTFSS STATUS,Z
    GOTO CheckT0IF
    CLRF CONT25ms    
    RETURN

Limpia:;funcion que setea en cero los primeros 4 bits para el contador automatico
    BCF PORTD,0
    BCF PORTD,1
    BCF PORTD,2
    BCF PORTD,3
    RETURN
    
Aumento:;funcion para la cual aumentara 1 bit con el boton1
    BTFSC PORTB,0
    GOTO Aumento
    MOVF const,W
    ADDWF PORTD,F
    RETURN
Decremento:;funcion para la cual decrementa 1 bit con el boton2
    BTFSC PORTB,1
    GOTO Decremento
    MOVF const,W
    SUBWF PORTD,F
    RETURN
Limpia2:;funcion que setea en cero los 4 bits mas significativos<7:4>
    BCF PORTD,4
    BCF PORTD,5
    BCF PORTD,6
    BCF PORTD,7
    RETURN  
LED:
    BSF PORTB,2
    CALL Frec
    CALL Frec
    BCF PORTB,2
    CALL Frec
    CALL Frec
    RETURN
Frec:;frecuencia con la que empieza a parpadear el led por default 
    CALL Delay
    RETURN

    ;Funcion para tiempo de espera
Delay:
    MOVLW .100
    MOVWF CONT2
    
    Restar1:
	MOVLW .255
	MOVWF CONT1
    Restar2:
	DECFSZ CONT1, F
	GOTO Restar2
	DECFSZ CONT2, F
	GOTO Restar1
    RETURN    
    END
    
    
    