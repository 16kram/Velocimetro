;************************************************************************************************
;*			    Programa velocimetro/cuenta km   Version 2                          *
;*               (R)2003, Realizado en el 2003 por Esteban Porqueras Araque                     *
;*                      Escrito para el microcontrolador 16f84                                  *
;************************************************************************************************


;************************************************************************************************
;*                     CARACTERISTICAS TECNICAS DEL PROGRAMA CUENTA/KM                          *
;*                                     Version 2                                                *
;* Distancia maxima visualizable en el display: 999.999 Km                                      *
;* Velocidad maxima visualizable en el display: 999.99999 Km/h                                  *
;* Velocidad maxima computable por el programa: 2359 Km/h                                       *
;* Maxima distancia recorrida en un paso: 2.56 mts                                              *
;* Maxima distancia recorrida en un paso por segundo: 655 mts/s                                 *
;* Error de precision en la cuenta de los kilometros: -2.56mts cada paso en el peor de los casos*
;*                                                    -1 cm cada paso en el mejor de los casos  *
;*                                                                                              *
;************************************************************************************************

;************************************************************************************************
;*				   Circuito Mx-84                                               *
;*         (R)2003, Circuito realizado en el 2003 por Esteban Porqueras Araque	                *
;*                                                                                              *
;* Tension de alimentacion: 9-12V                                                               *
;* Consumo medio: 8mA                                                                           *
;* Microcontrolador: Pic 16f84                                                                  *
;* Display: LM020L, Microcontrolador HD44780                                                    *
;*                                                                                              *
;************************************************************************************************


;Nota para programador del 16f84: Todos los fusibles a 0 y el Oscilador en Xt.


;*********************** Registros internos del microcontrolador*********************************

PORTA	EQU	05H
PORTB	EQU	06H
TRISA	EQU	85H
TRISB	EQU	86H
STATUS	EQU	03H
OPCION	EQU	81H
C	EQU	00H
Z	EQU	02H
PC	EQU	02H     
RBPU	EQU	07H; Bit de las resistencias de polarizacion de la puerta B
EEIE	EQU	06H
EEDATA	EQU	08H
EEADR	EQU	09H
EECON1	EQU	08H
EEIF	EQU	04H
INDF	EQU	00H
STATUS	EQU	03H
FSR	EQU	04H
RP0	EQU	05H
TMR0	EQU	01H
REG_OPTION	EQU	81H
WREN	EQU	02H
EECON2	EQU	89H
WR	EQU	01H


TOCS	EQU	05H; Fuente de reloj para TMR0 (1=PULSOS POR TOCK1 CONTADOR), (0=RELOJ INTERNO FOSC/4 TEMPORIZADOR).
TOSE	EQU	04H; Tipo de flanco activo del TOCK1 (1=INCREMENTO DE TMR0 CADA FLANCO DESCENDENTE), (0=INCREMENTO DE TMR0 CADA FLANCO ASCENDENTE).
PSA	EQU	03H; Asignacion del divisor de frecuencia (1=SE LE ASIGNA AL WDT), (0=SE LE ASIGNA AL TMR0)



;********************************* Registros del programa *********************


;Los registros (28-2B) contienen el valor de la velocidad.
;Los registros (2C-2F) contienen el valor de la cuenta de kilometros.
;Los registros (3B-3F) contienen los valores en BCD para visualizarlos por el LCD.

CONT_MUTE	EQU	1EH
REG_CONTADOR4	EQU	1FH
SOUND_DELAY1	EQU	20H
SOUND_DELAY2	EQU	21H
TIEMPO	EQU	22H
FREQ	EQU	23H
BUFFER_SONIDO	EQU	24H
PASOS	EQU	25H
CONTSOUND	EQU	26H
BUFFER_STATUS	EQU	27H
BUFFER_W	EQU	30H
BANDERA	EQU	31H
BUFFER_X	EQU	32H
CONT_X36	EQU	33H
REG_CONTADOR	EQU	34H
CONTADOR_TMR0	EQU	35H
REG_CONTADOR2_TMR0	EQU	36H
REG_CONTADOR3_TMR0	EQU	37H
CONTADOR_SCR	EQU	38H
CONTADOR3	EQU	39H
CONTADOR_NL	EQU	3AH

BCD_0	EQU	3FH
BCD_1	EQU	3EH
BCD_2	EQU	3DH
BCD_3	EQU	3CH
BCD_4	EQU	3BH

CONT_3	EQU	40H
BUFFER	EQU	41H
CONT_DELAY1	EQU	42H
CONT_DELAY2	EQU	43H
TEMPORAL	EQU	44H
CONTADOR	EQU	45H
ACARREO	EQU	46H
CONT	EQU	47H
BYTE_0	EQU	4EH
BYTE_1	EQU	4CH
BYTE_2	EQU	4AH
BYTE_3	EQU	48H



;******************************************************************************
;*                              PROGRAMA PRINCIPAL                            *
;******************************************************************************
   

	ORG 00H
	GOTO START

	ORG	04H
	GOTO	RSI; Salta a la rutina para dar servicio a la interrupcion.

	ORG 05H
START	
	BCF	BANDERA,0; Prohibe la ejecucion de la rutina GRABA_EEPROM
	BCF	BANDERA,1; Prohibe la ejecucion de la rutina SELEC_PASO
	BCF	BANDERA,2; Prohibe la ejecucion de la rutina BORRA KM
	BSF	BANDERA,7; Habilita la ejecucion de la rutina VISUALIZA_KM
	CALL	LCD_INIC
	CALL	START_DISP
	CALL	MSG_INICIO
	CALL	MUSICA
	CALL	CONFIGTECLA
	CALL	BORRASUMA
	CALL	BORRAKM
SIGUE	
	CALL	SELEC_PASO
	CALL	CALCULAKM
	CALL	BORRA_KM
	CALL	DSP_VELOCIMETRO
	CALL	DSP_CUENTAKM
	GOTO	SIGUE
	
	SLEEP


;******************************* Tablas de datos ************************************************


MENSAJE
	ADDWF	PC,1
	DT	"   (R)2003 por Esteban P.A. Rev.2 --> Computer MX-84",0
SOLFA
	ADDWF	PC,1
	DT	D'119',D'119',D'112',D'106',D'100',D'94',D'89',D'84',D'79',D'75',D'71',D'67',D'63',D'59'

TEMPO
	ADDWF	PC,1
	DT	D'26',D'26',D'27',D'29',D'31',D'33',D'34',D'37',D'39',D'41',D'44',D'46',D'49',D'52'

NOTAS_MUSICALES
	ADDWF	PC,1
	DT	D'4',D'4',D'6',D'6',D'8',D'8',D'5',D'5',0xFF,D'8',D'8',D'8',D'6',D'6',D'4',D'4',D'8',D'8',0xFF,D'9',D'10',0



;******************************************************************************
;*                            Rutina Suma                                     *
;* Suma los cuatro sumandos pares, con los cuatro sumandos impares de los     *
;* registros (48h-4fh), dejando el resultado en los cuatro registros impares. *
;*                                                                            *
;******************************************************************************
                      
SUMA	CLRF	ACARREO
	MOVLW	4FH
	MOVWF	FSR
	MOVLW	04H
	MOVWF	CONT
	
BUCLE	MOVF	ACARREO,0
	ADDWF	INDF,1
	MOVLW	0X01
	ANDWF	STATUS,0
	MOVWF	ACARREO
	MOVF	INDF,0
	DECF	FSR,1
	ADDWF	INDF,1
	MOVLW	0X01
	ANDWF	STATUS,0
	IORWF	ACARREO,1
	DECF	FSR,1
	DECFSZ	CONT,1
	GOTO	BUCLE
	RETURN


;******************************************************************************
;*                            Rutina BorraSuma                                *
;* Llamando a la rutina BorraSuma se borran los sumandos superior e inferior  *
;* de los registros (48h-4fh), y llamando a la rutina BorraSumando            *
;* se borra el sumando inferior.                                              *
;*                                                                            *
;******************************************************************************

BORRASUMA	CLRF	0x4E
		CLRF	0x4C
		CLRF	0x4A
		CLRF	0x48
BORRASUMANDO	CLRF	0x4F
		CLRF	0x4D
		CLRF	0x4B
		CLRF	0x49
		RETURN


;******************************************************************************
;*                            Rutina Bits32_bcd                               *
;* Realiza la conversion de binario a bcd, de los cuatro bytes de los         *
;* registros impares (48h-4fh), dejando el resultado en en los 5 bytes        * 
;* de los registros (3bh-3fh).                                                *
;******************************************************************************

BITS32_BCD
	BCF	STATUS,0
	CLRF	CONTADOR
	BSF	CONTADOR,5
	CLRF	BCD_0
	CLRF	BCD_1
	CLRF	BCD_2
	CLRF	BCD_3
	CLRF	BCD_4
LOOP_32
	RLF	BYTE_0,1
	RLF	BYTE_1,1
	RLF	BYTE_2,1
	RLF	BYTE_3,1
	RLF	BCD_0,1
	RLF	BCD_1,1
	RLF	BCD_2,1
	RLF	BCD_3,1
	RLF	BCD_4,1
	DECFSZ	CONTADOR,1
	GOTO	AJUSTE
	RETURN
AJUSTE	MOVLW	BCD_4
	MOVWF	FSR
	CALL	AJUSTE_BCD
	INCF	FSR,1
	CALL	AJUSTE_BCD
	INCF	FSR,1
	CALL	AJUSTE_BCD
	INCF	FSR,1
	CALL	AJUSTE_BCD
	INCF	FSR,1
	CALL	AJUSTE_BCD
	GOTO	LOOP_32
AJUSTE_BCD
	MOVF	INDF,0
	ADDLW	0x03
	MOVWF	TEMPORAL
	BTFSC	TEMPORAL,3
	MOVWF	INDF
	MOVF	INDF,0
	ADDLW	0x30
	MOVWF	TEMPORAL
	BTFSC	TEMPORAL,7
	MOVWF	INDF
	RETURN




;******************************* Programa del display lcd *********************


START_DISP
	MOVLW	10H; TURN OFF THE DISPLAY
	CALL	LCD_COMANDO
	MOVLW	01H; CLEAR THE DISPLAY
	CALL	LCD_COMANDO
	MOVLW	06H; SET CURSOR MOVE DIRECTION
	CALL	LCD_COMANDO
	MOVLW	0CH; ENABLE DISPLAY/CURSOR
	CALL	LCD_COMANDO
	MOVLW	1FH; MOVE CURSOR / SHIFT DISPLAY
	CALL	LCD_COMANDO
	MOVLW	02H; RETURN CURSOR AND LCD TO HOME POSITION
	CALL 	LCD_COMANDO 
	RETURN


;****************** Rutinas lcd HD44780 para 4 bits de datos ******************


	
PAUSA5MS
	CLRF	CONT_DELAY1
	MOVLW	07H
	MOVWF	CONT_DELAY2
BUCLEX	DECFSZ	CONT_DELAY1,1
	GOTO	BUCLEX
	DECFSZ	CONT_DELAY2,1
	GOTO	BUCLEX
	RETURN

LCD_COMANDO
	BCF	PORTA,0; LCD MODO COMANDOS
	MOVWF	BUFFER
	CALL	LCD_CHEQUEA
	SWAPF	BUFFER,0
	MOVWF	PORTB
	CALL	LCD_HABILITA
	MOVF	BUFFER,0
	MOVWF	PORTB
	CALL	LCD_HABILITA
	RETURN

LCD_CARACTER
	BCF	PORTA,0; LCD MODO COMANDOS
	MOVWF	BUFFER
	CALL	LCD_CHEQUEA
	BSF	PORTA,0; LCD MODO CARACTERES
	SWAPF	BUFFER,0
	MOVWF	PORTB
	CALL	LCD_HABILITA
	MOVF	BUFFER,0
	MOVWF	PORTB
	CALL	LCD_HABILITA
	RETURN

LCD_HABILITA
	BSF	PORTA,2
	NOP
	BCF	PORTA,2
	RETURN

LCD_CHEQUEA
	BSF	PORTA,1; LCD MODO LECTURA
	BSF	STATUS,RP0
	MOVLW	0FFH
	MOVWF	TRISB
	BCF	STATUS,RP0
	BSF	PORTA,2
BUCLE2	BTFSC	PORTB,3
	GOTO	BUCLE2
	BCF	PORTA,2
	BSF	STATUS,RP0
	MOVLW	B'11110000'
	MOVWF	TRISB
	BCF	STATUS,RP0
	BCF	PORTA,1; LCD MODO ESCRITURA
	RETURN


;************************************************************************************************
;*                           Inicializa el display lcd                                          * 
;* CONFIGURA RA4/TOCK1 COMO ENTRADA DE DATOS PARA EL CONTADOR TOCK1.                            *
;* CONFIGURA RA3 COMO SALIDA PARA EL ALTAVOZ.                                                   *
;************************************************************************************************


LCD_INIC
	BSF	STATUS,RP0
	MOVLW	B'11110000'; CONFIGURA PORTB
	MOVWF	TRISB
	MOVLW	B'11110000'; CONFIGURA PORT A
	MOVWF	TRISA
	BCF	STATUS,RP0
	CLRF	PORTA; PUERTO A=0
	BSF	STATUS,RP0
	BSF	REG_OPTION,TOCS; CONFIGURA TMR0
	BSF	REG_OPTION,TOSE; CONFIGURA TMR0
	BSF	REG_OPTION,PSA; CONFIGURA TMR0
	BCF	STATUS,RP0
	CALL	PAUSA5MS
	CALL	PAUSA5MS
	CALL	PAUSA5MS
	MOVLW	03H
	MOVWF	PORTB
	CALL	LCD_HABILITA
	CALL	PAUSA5MS
	MOVLW	03H
	MOVWF	PORTB
	CALL	LCD_HABILITA
	CALL	PAUSA5MS
	MOVLW	03H
	MOVWF	PORTB
	CALL	LCD_HABILITA
	CALL	PAUSA5MS
	MOVLW	02H
	MOVWF	PORTB
	CALL	LCD_HABILITA
	CALL	PAUSA5MS
	RETURN



;***************************** Mensaje de inicio ************************************************


MSG_INICIO
	CLRF	CONTADOR3
	CLRF	CONTADOR_NL

COGE_LETRA
	MOVF	CONTADOR_NL,0
	SUBLW	10H
	BTFSC	STATUS,Z
	CALL	SCROLL
	MOVF	CONTADOR_NL,0
	SUBLW	08H
	BTFSC	STATUS,Z
	CALL	LINEA_DOS
	MOVF	CONTADOR3,0
	CALL	MENSAJE
	IORLW	00H
	BTFSC	STATUS,Z
	RETURN
	CALL	LCD_CARACTER
	INCF	CONTADOR3,1
	INCF	CONTADOR_NL,1
	GOTO	COGE_LETRA

LINEA_DOS
	MOVLW	B'10101000'
	CALL	LCD_COMANDO
	RETURN

SCROLL
	MOVLW	0FH
	SUBWF	CONTADOR3,1
	CLRF	CONTADOR_NL
	MOVLW	D'100'
	MOVWF	CONTADOR_SCR

BUCLE_SCR
	CALL	PAUSA5MS
	DECFSZ	CONTADOR_SCR,1
	GOTO	BUCLE_SCR
	MOVLW	01H
	CALL	LCD_COMANDO
	RETURN


;*********************************** Rutina CALCULAKM *******************************************
;*                                                                                              *
;* Recoge los pulsos captados por TOCK1 durante 1 segundo                                       * 
;* y calcula la velocidad en Km/h y los kilometros recorridos.                                  *
;* deja los resultados de velocidad en los                                                      *
;* registros (28h-2fh).                                                                         *
;* Deja los resultados de kilometros recorridos en los                                          * 
;* registros (2Ch-2Fh).                                                                         *
;*                                                                                              *
;************************************************************************************************ 

CALCULAKM
	CALL	BORRASUMA
PAUSA1S	CLRF	CONTADOR_TMR0
	MOVLW	D'13'
	MOVWF	REG_CONTADOR2_TMR0
	MOVLW	D'100'
	MOVWF	REG_CONTADOR3_TMR0
	CLRF	TMR0
SCAN	
	DECFSZ	CONTADOR_TMR0,1
	GOTO	SCAN
	DECFSZ	REG_CONTADOR2_TMR0,1
	GOTO	SCAN
	MOVLW	D'13'
	MOVWF	REG_CONTADOR2_TMR0
	DECFSZ	REG_CONTADOR3_TMR0,1
	GOTO	SCAN
FINSCAN
	MOVF	TMR0,0
	MOVWF	BUFFER_X; Deja el valor de TMR0 en el registro BUFFER_X.

;Carga el registro PASO(00h EEPROM) en el primer sumando de la rutina SUMA
;para ser multiplicado por el valor de TMR0.
	BCF	STATUS,RP0
	MOVLW	00; Primer registro EEPROM de datos.
	MOVWF	EEADR
	BSF	STATUS,RP0
	BSF	EECON1,0
	BCF	STATUS,RP0
	MOVF	EEDATA,0
	MOVWF	REG_CONTADOR
MULTIPLICA
	MOVF	BUFFER_X,0
	MOVWF	0x4F; Deja el valor del BUFFER en el primer sumando de la rutina SUMA.
	CALL	SUMA
	CALL	BORRASUMANDO
	DECFSZ	REG_CONTADOR,1
	GOTO	MULTIPLICA

;Carga el resultado de (TMR0xPASO) en los registros del velocimetro(28h-2Bh) 
;para mas adelante ser multiplicado por 36.
	MOVF	0x4E,0
	MOVWF	0x2B
	MOVF	0x4C,0
	MOVWF	0x2A
	MOVF	0x4A,0
	MOVWF	0x29
	MOVF	0x48,0
	MOVWF	0x28
	  	
;Carga los registros de la cuenta de km(2C-2F) en el primer sumando del 
;registro suma, para ser sumado con el resultado de (TMR0xPASO), y el 
;resultado es cargado en los registros de la cuenta de km(2C-2F).
	MOVF	0x2F,0
	MOVWF	0x4F
	MOVF	0x2E,0
	MOVWF	0x4D
	MOVF	0x2D,0
	MOVWF	0x4B
	MOVF	0x2C,0
	MOVWF	0x49
	CALL	SUMA
	MOVF	0x4E,0
	MOVWF	0x2F
	MOVF	0x4C,0
	MOVWF	0x2E
	MOVF	0x4A,0
	MOVWF	0x2D
	MOVF	0x48,0
	MOVWF	0x2C

;Recupera (TMR0xPASO) de los registros (28-2B) los pone en el primer sumando
;de los registros de la rutina SUMA los multiplica por 36, y los guarda en
;los registros del velocimetro (28-2B).
	CALL	BORRASUMA
	MOVLW	D'36'
	MOVWF	CONT_X36
BUCLE_X36
	MOVF	0x2B,0
	MOVWF	0x4F
	MOVF	0x2A,0
	MOVWF	0x4D
	MOVF	0x29,0
	MOVWF	0x4B
	MOVF	0x28,0
	MOVWF	0x49
	CALL	SUMA
	CALL	BORRASUMANDO
	DECFSZ	CONT_X36,1
	GOTO	BUCLE_X36
	MOVF	0x4E,0
	MOVWF	0x2B
	MOVF	0x4C,0
	MOVWF	0x2A
	MOVF	0x4A,0
	MOVWF	0x29
	MOVF	0x48,0
	MOVWF	0x28
	RETURN



;******************************************************************************
;*                                   BorraKm                                  *
;* Pone a 0 los registros (2C-2F) del cuenta kilometros.                      *
;*                                                                            *
;******************************************************************************


BORRAKM	CLRF	0x2C
	CLRF	0x2D
	CLRF	0x2E
	CLRF	0x2F
	RETURN



;******************************************************************************
;* DSP_CUENTAKM: Muestra en la pantalla lcd los kilometros recorridos.        *
;******************************************************************************
;Registros de visualizacion (3B-3F)

DSP_CUENTAKM
	MOVF	0x2F,0
	MOVWF	0x4E
	MOVF	0x2E,0
	MOVWF	0x4C
	MOVF	0x2D,0
	MOVWF	0x4A
	MOVF	0X2C,0
	MOVWF	0X48
	CALL	BITS32_BCD
	BTFSS	BANDERA,7
	RETURN
	MOVLW	01H; BORRA LA PANTALLA
	CALL	LCD_COMANDO
	MOVLW	0x04; Numero de bytes a visualizar.
	MOVWF	REG_CONTADOR
	MOVLW	0x3C; Primer registro a visualizar.
	MOVWF	FSR
	MOVLW	'C'
	CALL	LCD_CARACTER
	MOVLW	'N'
	CALL	LCD_CARACTER
	MOVLW	'T'
	CALL	LCD_CARACTER
	MOVLW	'1'
	CALL	LCD_CARACTER
	MOVLW	' '
	CALL	LCD_CARACTER
VISUALIZA
	SWAPF	INDF,0
	ANDLW	0x0F
	ADDLW	D'48'
	CALL	LCD_CARACTER
	MOVLW	0x03
	SUBWF	REG_CONTADOR,0
	BTFSC	STATUS,2
	CALL	PUNTODECIMAL
	MOVF	INDF,0
	ANDLW	0x0F
	ADDLW	D'48'
	CALL	LCD_CARACTER
	INCF	FSR,1
	DECFSZ	REG_CONTADOR,1
	GOTO	VISUALIZA
	MOVLW	'K'
	CALL	LCD_CARACTER
	MOVLW	'm'
	CALL	LCD_CARACTER
	RETURN

PUNTODECIMAL
	CALL	LINEA_DOS
	MOVLW	'.'
	CALL	LCD_CARACTER
	RETURN


;******************************************************************************
;* DSP_VELOCIMETRO: Muestra en la pantalla lcd la velocidad en km/h.          *
;******************************************************************************
;Registros de visualizacion (3B-3F).

DSP_VELOCIMETRO
	MOVF	0x2B,0
	MOVWF	0x4E
	MOVF	0x2A,0
	MOVWF	0x4C
	MOVF	0x29,0
	MOVWF	0x4A
	MOVF	0X28,0
	MOVWF	0X48
	CALL	BITS32_BCD
	BTFSC	BANDERA,7
	RETURN
	MOVLW	01H; BORRA LA PANTALLA
	CALL	LCD_COMANDO
	MOVLW	0x03; Numero de bytes a visualizar.
	MOVWF	REG_CONTADOR
	MOVLW	0x3D; Primer byte a visualizar.
	MOVWF	FSR
	MOVLW	'V'
	CALL	LCD_CARACTER
	MOVLW	'E'
	CALL	LCD_CARACTER
	MOVLW	'L'
	CALL	LCD_CARACTER
	MOVLW	' '
	CALL	LCD_CARACTER
VISUALIZA_VEL
	SWAPF	INDF,0
	ANDLW	0x0F
	ADDLW	D'48'
	CALL	LCD_CARACTER
	MOVLW	02H
	SUBWF	REG_CONTADOR,0
	BTFSC	STATUS,2
	CALL	PUNTODECIMAL_VEL
	MOVF	INDF,0
	ANDLW	0x0F
	ADDLW	D'48'
	CALL	LCD_CARACTER
	INCF	FSR,1
	DECFSZ	REG_CONTADOR,1
	GOTO	VISUALIZA_VEL
	MOVLW	' '
	CALL	LCD_CARACTER
	MOVLW	'K'
	CALL	LCD_CARACTER
	MOVLW	'm'
	CALL	LCD_CARACTER
	MOVLW	'/'
	CALL	LCD_CARACTER
	MOVLW	'h'
	CALL	LCD_CARACTER
	RETURN

PUNTODECIMAL_VEL
	MOVLW	'.'
	CALL	LCD_CARACTER
	CALL	LINEA_DOS
	RETURN




;*******************************************************************************	
;* Rutina CONFIGTECLA: Configura el teclado y habilita las interrupciones.     *                
;*******************************************************************************


INTCON	EQU	0BH; REGISTRO DE INTERRUPCIONES
GIE	EQU	07H; ACTIVACION GLOBAL INTERRUPCIONES (1=CONCEDIDO EL PERMISO DE INTERRPCIONES, 0=NO CONCEDIDO)
RBIE	EQU	03H; ACTIVACION DE LA INT PUERTA B (1=ACTIVADA, 0=DESACTIVADA).
RBIF	EQU	00H; SEÑALIZADOR DE ESTADO PUERTA B (1= CAMBIA DE ESTADO CUALQUIER LINEA 7-4 RB, 0=NINGUNA HA CAMBIADO).

CONFIGTECLA
	BSF	STATUS,RP0
	BCF	REG_OPTION,RBPU; ACTIVA LAS RESISTENCIAS DE POLARIZACION.
	BCF	STATUS,RP0
	BSF	INTCON,GIE
	BSF	INTCON,RBIE
	BSF	INTCON,EEIE
	RETURN




;************************************************************************************************	
;*                   RUTINA DE SERVICIO PARA LA INTERRUPCION                                    *
;************************************************************************************************



;******************************** COMIENZO DE LA RUTINA RSI *******************

RSI
	MOVWF	BUFFER_W
	SWAPF	STATUS,0
	MOVWF	BUFFER_STATUS

;******************************************************************************
; Comprueba si se esta grabando algun dato en la EEPROM


	BTFSS	BANDERA,0
	GOTO	CONTINUA_RSI
	BCF	EECON1,EEIF
	GOTO	FINRSI

CONTINUA_RSI
	
;************************************ GENERA UN BEEP ********************************************
;*  En la rutina Beep no se utiliza la rutina PAUSE5MS para no desbordar la pila del programa.  *
;************************************************************************************************

	MOVLW	D'8'
	MOVWF	CONTSOUND
SONIDO	BSF	PORTA,3
	CLRF	CONT_DELAY1
	MOVLW	07H
	MOVWF	CONT_DELAY2
BUCLEX2	DECFSZ	CONT_DELAY1,1
	GOTO	BUCLEX2
	DECFSZ	CONT_DELAY2,1
	GOTO	BUCLEX2
	BCF	PORTA,3
	CLRF	CONT_DELAY1
	MOVLW	07H
	MOVWF	CONT_DELAY2
BUCLEX3	DECFSZ	CONT_DELAY1,1
	GOTO	BUCLEX3
	DECFSZ	CONT_DELAY2,1
	GOTO	BUCLEX3
	DECFSZ	CONTSOUND,1
	GOTO	SONIDO

;******************************************************************************

; Comprueba si se pulsa alguna tecla.
	
	BTFSS	PORTB,7
	CALL	TEST
	BTFSS	PORTB,7
	BSF	BANDERA,7
	BTFSS	PORTB,6
	BCF	BANDERA,7
	BTFSS	PORTB,5
	BSF	BANDERA,1
	BTFSS	PORTB,4
	BSF	BANDERA,2             
	
	BCF	INTCON,RBIF; Pone a 0 la bandera RBIF de las puertas (RB7-RB4).

;******************************** FIN DE LA RUTINA RSI ************************

FINRSI	SWAPF	BUFFER_STATUS,0
	MOVWF	STATUS
	SWAPF	BUFFER_W,1
	SWAPF	BUFFER_W,0
	RETFIE

;******************************************************************************



;********************************** Rutina SELEC_PASO *************************
	

SELEC_PASO
	BTFSS	BANDERA,1
	RETURN
	BCF	INTCON,RBIE
	MOVLW	01H
	CALL	LCD_COMANDO
	MOVLW	'C'
	CALL	LCD_CARACTER
	MOVLW	'a'
	CALL	LCD_CARACTER
	MOVLW	'm'
	CALL	LCD_CARACTER
	MOVLW	'b'
	CALL	LCD_CARACTER
	MOVLW	'i'
	CALL	LCD_CARACTER
	MOVLW	'a'
	CALL	LCD_CARACTER
	MOVLW	'r'
	CALL	LCD_CARACTER
	MOVLW	' '
	CALL	LCD_CARACTER
	CALL	LINEA_DOS
	MOVLW	'e'
	CALL	LCD_CARACTER
	MOVLW	'l'
	CALL	LCD_CARACTER
	MOVLW	' '
	CALL	LCD_CARACTER
	MOVLW	'p'
	CALL	LCD_CARACTER
	MOVLW	'a'
	CALL	LCD_CARACTER
	MOVLW	's'
	CALL	LCD_CARACTER
	MOVLW	'o'
	CALL	LCD_CARACTER
	MOVLW	'?'
	CALL	LCD_CARACTER
	MOVLW	03H
	CALL	PLAY
	MOVLW	0AH
	CALL	PLAY
CHEQUEA	BTFSS	PORTB,4
	GOTO	ESCAPE
	BTFSC	PORTB,5
	GOTO	CHEQUEA
TECLAP	BTFSS	PORTB,5
	GOTO	TECLAP
	MOVLW	03H
	CALL	PLAY
	MOVLW	04H
	CALL	PLAY
	MOVLW	0CH
	CALL	PLAY
;Recupera el dato del primer registro de la EEPROM y lo carga en 
;el registro PASOS.
	BCF	STATUS,RP0
	MOVLW	00; Primer registro EEPROM de datos.
	MOVWF	EEADR
	BSF	STATUS,RP0
	BSF	EECON1,0
	BCF	STATUS,RP0
	MOVF	EEDATA,0
	MOVWF	PASOS
OTRAVEZ	
	MOVLW	01H
	CALL	LCD_COMANDO; BORRA LA PANTALLA LCD.
	MOVLW	'P'
	CALL	LCD_CARACTER
	MOVLW	'a'
	CALL	LCD_CARACTER
	MOVLW	's'
	CALL	LCD_CARACTER
	MOVLW	'o'
	CALL	LCD_CARACTER
	MOVLW	'='
	CALL	LCD_CARACTER
	MOVF	PASOS,0
	MOVWF	0x4E
	CALL	BITS32_BCD
	MOVLW	0x3E; Dos ultimos bytes de los registros de visualizacion.
	MOVWF	FSR
VISUALIZA_PASO
	MOVF	INDF,0
	ADDLW	D'48'
	CALL	LCD_CARACTER
	INCF	FSR,1
	SWAPF	INDF,0
	ANDLW	0x0F
	ADDLW	D'48'
	CALL	LCD_CARACTER
	MOVF	INDF,0
	ANDLW	0x0F
	ADDLW	D'48'
	CALL	LCD_CARACTER
	CALL	LINEA_DOS
	MOVLW	'c'
	CALL	LCD_CARACTER
	MOVLW	'm'
	CALL	LCD_CARACTER
COMPRUEBATECLA
	BTFSS	PORTB,4
	GOTO	BORRAPASO
	BTFSS	PORTB,6                                                                                                                       
	GOTO	INCREMENTAPASO
	BTFSS	PORTB,7
	GOTO	DECREMENTAPASO
	BTFSC	PORTB,5
	GOTO	COMPRUEBATECLA
PULSADA	BTFSS	PORTB,5
	GOTO	PULSADA


;********************************* Rutina GRABA_EEPROM ************************


GRABA_EEPROM
	BSF	BANDERA,0
	MOVLW	00H
	MOVWF	EEADR
	MOVF	PASOS,0
	MOVWF	EEDATA
	BSF	STATUS,RP0; ESCRIBE EN LA EEPROM DE DATOS EL VALOR DEL PASO.
	BSF	EECON1,WREN
	BCF	INTCON,GIE
	MOVLW	55H
	MOVWF	EECON2
	MOVLW	D'170'
	MOVWF	EECON2
	BSF	EECON1,WR
	BSF	INTCON,GIE
	SLEEP
	BCF	EECON1,WREN
	BCF	STATUS,RP0
	MOVLW	0BH
	CALL	PLAY
	MOVLW	05H
	CALL	PLAY
	MOVLW	04H
	CALL	PLAY
	MOVLW	03H
	CALL	PLAY
	BCF	BANDERA,0
	BCF	BANDERA,1
	CLRF	PASOS
	BSF	INTCON,RBIE
	RETURN


;*********************** Rutinas INCREMENTAPASO y DECREMENTAPASO **************


INCREMENTAPASO
PULSADO1
	BTFSS	PORTB,6
	GOTO	PULSADO1
	INCF	PASOS,1
	MOVLW	0DH
	CALL	PLAY
	GOTO	OTRAVEZ


DECREMENTAPASO
PULSADO2
	BTFSS	PORTB,7
	GOTO	PULSADO2
	DECF	PASOS,1
	MOVLW	0BH
	CALL	PLAY
	GOTO	OTRAVEZ

BORRAPASO
PULSADO3
	BTFSS	PORTB,4
	GOTO	PULSADO3
	CLRF	PASOS
	MOVLW	09H
	CALL	PLAY
	GOTO	OTRAVEZ


;********************************* RUTINA PLAY ********************************



PLAY	
	MOVWF	BUFFER_SONIDO
	CALL	SOLFA
	MOVWF	FREQ
	MOVF	BUFFER_SONIDO,0
	CALL	TEMPO
	MOVWF	TIEMPO
SOUND	BSF	PORTA,3
	CALL	DELAY
	BCF	PORTA,3
	CALL	DELAY
	DECFSZ	TIEMPO,1
	GOTO	SOUND
	RETURN

DELAY	MOVF	FREQ,0
	MOVWF	SOUND_DELAY2
CICLO2	MOVLW	0AH
	MOVWF	SOUND_DELAY1
CICLO1	DECFSZ	SOUND_DELAY1,1
	GOTO	CICLO1
	DECFSZ	SOUND_DELAY2,1
	GOTO	CICLO2
	RETURN



;************************************ RUTINA MUSICA ***************************
; Poniendo el valor 0xFF en la tabla de datos de NOTAS_MUSICALES 
; se obtiene una pausa de 0,5 segundos.


MUSICA
	CLRF	REG_CONTADOR4
CONTINUA
	MOVF	REG_CONTADOR4,0
	CALL	NOTAS_MUSICALES
	IORLW	00H
	BTFSC	STATUS,Z
	RETURN
	XORLW	0xFF
	BTFSC	STATUS,Z
	GOTO	MUTE
	XORLW	0xFF
	CALL	PLAY
CONT_PLAY
	INCF	REG_CONTADOR4,1
	GOTO	CONTINUA


MUTE	MOVLW	D'100'
	MOVWF	CONT_MUTE
PAUSA_MUTE
	CALL	PAUSA5MS
	DECFSZ	CONT_MUTE,1
	GOTO	PAUSA_MUTE
	GOTO	CONT_PLAY

;******************************* Rutina BORRA_KM ******************************



BORRA_KM
	BTFSS	BANDERA,2
	RETURN
	BCF	INTCON,RBIE
	MOVLW	01H
	CALL	LCD_COMANDO
	MOVLW	' '
	CALL	LCD_CARACTER
	MOVLW	'B'
	CALL	LCD_CARACTER
	MOVLW	'o'
	CALL	LCD_CARACTER
	MOVLW	'r'
	CALL	LCD_CARACTER
	MOVLW	'r'
	CALL	LCD_CARACTER
	MOVLW	'a'
	CALL	LCD_CARACTER
	MOVLW	'r'
	CALL	LCD_CARACTER
	MOVLW	' '
	CALL	LCD_CARACTER
	CALL	LINEA_DOS
	MOVLW	'l'
	CALL	LCD_CARACTER
	MOVLW	'o'
	CALL	LCD_CARACTER
	MOVLW	's'
	CALL	LCD_CARACTER
	MOVLW	' '
	CALL	LCD_CARACTER
	MOVLW	'K'
	CALL	LCD_CARACTER
	MOVLW	'm'
	CALL	LCD_CARACTER
	MOVLW	'?'
	CALL	LCD_CARACTER
	MOVLW	04H
	CALL	PLAY
	MOVLW	05H
	CALL	PLAY
	MOVLW	06H
	CALL	PLAY
	MOVLW	07H
	CALL	PLAY
NOPULSADA
	BTFSS	PORTB,4
	GOTO	ESCAPE
	BTFSC	PORTB,5
	GOTO	NOPULSADA
PULSADOB5
	BTFSS	PORTB,5
	GOTO	PULSADOB5
	CALL	BORRASUMA
	CALL	BORRAKM
	MOVLW	09H
	CALL	PLAY
	MOVLW	06H
	CALL	PLAY
	MOVLW	04H
	CALL	PLAY
	MOVLW	0AH
	CALL	PLAY
	BCF	BANDERA,2
	BSF	INTCON,RBIE
	RETURN


;******************************************************************************


ESCAPE
	BTFSS	PORTB,4
	GOTO	ESCAPE
	MOVLW	0AH
	CALL	PLAY
	MOVLW	09H
	CALL	PLAY
	MOVLW	08H
	CALL	PLAY
	MOVLW	0CH
	CALL	PLAY
	BCF	BANDERA,1
	BCF	BANDERA,2
	BSF	INTCON,RBIE
	RETURN



;******************************************************************************
;* Rutina Test: Visualiza por el lcd el estado logico del captador de la rueda*
;* que entra por la entrada RA4/T0CK1 del microcontrolador.                   *
;******************************************************************************


TEST	BTFSC	PORTB,5
	RETURN
BUCLE_TEST
	MOVLW	0x01; Borra la pantalla lcd.
	CALL	LCD_COMANDO
	MOVLW	'T'
	CALL	LCD_CARACTER
	MOVLW	'e'
	CALL	LCD_CARACTER
	MOVLW	's'
	CALL	LCD_CARACTER
	MOVLW	't'
	CALL	LCD_CARACTER
	MOVLW	':'
	CALL	LCD_CARACTER
	BTFSS	PORTA,4
	GOTO	TEST_0
	MOVLW	'O'
	CALL	LCD_CARACTER
	MOVLW	'n'
	CALL	LCD_CARACTER
	MOVLW	0x0C
	CALL	PLAY
TECLAFIN
	BTFSC	PORTB,4
	GOTO	BUCLE_TEST
	MOVLW	0x0C
	CALL	PLAY
	MOVLW	0x09
	CALL	PLAY
PULSAFIN
	BTFSS	PORTB,4
	GOTO	PULSAFIN
	RETURN

TEST_0	MOVLW	'O'
	CALL	LCD_CARACTER
	MOVLW	'f'
	CALL	LCD_CARACTER
	MOVLW	'f'
	CALL	LCD_CARACTER
	MOVLW	0x08
	CALL	PLAY
	GOTO	TECLAFIN


;******************************************************************************



	END

