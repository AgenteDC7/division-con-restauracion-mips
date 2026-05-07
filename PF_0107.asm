.data
Entrada_str:	.asciiz "Algoritmo de división con Restauración\n"
Cociente_str:	.asciiz "Cociente:"
Resto_str:	.asciiz "Resto:"
Dividendo_str:	.asciiz "Dividendo:"
Divisor_str:	.asciiz "Divisor:"
errorDividendo: .asciiz "Error: Dividendo fuera de rango"
errorDivisor: .asciiz "Error: Divisor fuera de rango"
errorCero: .asciiz "Error: División entre cero"
P_str: .asciiz "P:"
Iteració_str: .asciiz "Iteración\tP_HI\t\tP_LO\n"


.macro print_tab
li $a0, '\t'		# Imprimimos l�nea en blanco
li $v0, 11
syscall
.end_macro

.macro print_salto
li $a0, '\n'		# Imprimimos l�nea en blanco
li $v0, 11
syscall
.end_macro
		
.text
main:
	#Imprimimos el texto para pedir el dividendo
	li $v0, 4
	la $a0, Dividendo_str
	syscall
	
	#Guardamos el dividendo en $s0
	li $v0, 5
	syscall
	move $s0, $v0
	
	#Comprobamos si el dividendo es positivo y cabe en 16 bits
	bltz $s0, error_dividendo
	li $t0 65535 #65535 es el mayor valor representable en 16 bits
	bgt $s0, $t0, error_dividendo
	
	#Imprimimos el texto para pedir el divisor
	li $v0, 4
	la $a0, Divisor_str
	syscall
	
	#Guardamos el divisor en $s1
	li $v0, 5
	syscall
	move $s1, $v0
	
	
	#Comprobamos que el divisor sea positivo, distinto de cero y cabe en 16 bits
	bltz $s1, error_divisor
	li $t0 65535
	bgt $s1, $t0, error_divisor
	beqz $s1, error_divisor_cero
	
	print_salto 
	
	#Imprimimos el título
	li $v0, 4
	la $a0,  Entrada_str
	syscall 
	
	print_salto
	
	#Guardamos los parámetros antes de llamar a la función
	move $a0, $s0
	move $a1, $s1
	jal divisionR
	
	#Movemos a $s2 el resto y a $s3 el cociente
	move $s2, $v0
	move $s3, $v1
	
	print_salto
	
	#Imprimios el resto
	li $v0, 4
	la $a0, Resto_str
	syscall

	print_tab
	li $v0, 1
	move $a0, $s3
	syscall
	print_salto 

	#Imprimimos el cociente
	li $v0, 4
	la $a0, Cociente_str
	syscall

	print_tab
	li $v0, 1
	move $a0, $s2
	syscall
	print_salto 
	
	#Saltamos al final
	j fin

divisionR:

	#Reservamos espacio en la pila para guardar los datos
	addi $sp, $sp, -16
	sw $ra, 12($sp)
	sw $s7, 8($sp)
	sw $s0, 4($sp)
	sw $s1, 0($sp)
	
	#Guardamos en $s7 el dividendo y en la parte superior de $s0 el divisor
	move $s7, $a0
	sll $s0, $a1, 16
	
	#Imprimimos el dividendo (P)
	li $v0, 4
	la $a0, P_str
	syscall
	
	print_tab
	
	move $a0, $s7
	jal printB
	print_salto
	
	#Imprimimos el divisor
	li $v0, 4
	la $a0, Divisor_str
	syscall
	
	
	move $a0, $s0
	jal printB
	print_salto
	
	#Imprimimos la cabecera del algoritmo
	print_salto
	li $v0, 4
	la $a0, Iteració_str
	syscall
	
	#Usamos $s1 como contador
	li $s1, 1

bucle_division:
	#Desplazamos P 1 lugar a la izquierda
	sll $s7, $s7, 1
	
	#PHi = PHi - Divisor
	subu $s7, $s7, $s0
	
	#Si P es menor que cero lo restauramos
	bltz $s7, restaurar_P
	
	#Si no, ntroducimos un 1 en el bit menos significativo
	ori $s7, $s7, 1
	j fin_paso_algoritmo

restaurar_P:
	#PHi = PHi + Divisor
	addu $s7, $s7, $s0
	
fin_paso_algoritmo:
	
	#Imprimimos el número de iteración
	li $v0, 1
	move $a0, $s1
	syscall
	
	print_tab
	
	#Imprimir P
	move $a0, $s7
	jal printB

	print_salto

	#Subimos el contador y comprobamos si ya lo hemos hecho 16 veces
	addi $s1, $s1, 1
	li $t0, 16
	ble $s1, $t0, bucle_division
	
	#Siya los hemos hecho 16 veces, guardamos los 16 bits menos significativas (Cociente) en $v0
	andi $v0, $s7, 0xFFFF
	
	#Guardamos los 16 más significativos (Resto) en $v1
	srl $v1, $s7, 16
	
	
	#Restauramos los registros y vaciamos la pila
	lw $s1, 0($sp)
	lw $s0, 4($sp)
	lw  $s7, 8($sp)
	lw $ra, 12($sp)

	addi $sp, $sp, 16

	jr $ra


printB:
    	#Usamos registros temporales para no usar la pila
    	move $t0, $a0
    	#Usamos $t1 como contador           
  	li $t1, 32              

bucle_printB:
   	#Si hemos llegado a la mitad imprimimos un espacio
    	beq $t1, 16, imprimir_espacio

continuar_printB:
    	#Extremos el bit más significativo
    	srl $t2, $t0, 31        #
    
  	#Imprimimos ese bit
    	li $v0, 1              
    	move $a0, $t2          
    	syscall                 
    
    	#Preparamos el siguiente bit moviendo un bit a la izquierda
    	sll $t0, $t0, 1 
    
    	addi $t1, $t1, -1       # Restamos 1 al contador de bits impresos
    	bgtz $t1, bucle_printB  # Si aún quedan bits, ($t1 > 0) repetimos el bucle
    
   	#Volvemos a la dirección de retorno
   	jr $ra

imprimir_espacio:
    	#Imprimimos un espacio
    	li $v0, 11             
    	li $a0, ' '             
    	syscall
    	
    	#Continuamos con el bucle
    	j continuar_printB

	


#Control de errores

error_dividendo:

    	li $v0, 4
    	la $a0, errorDividendo
    	syscall
    	print_salto
    	j fin

error_divisor:
    	li $v0, 4
    	la $a0, errorDivisor
    	syscall
    	print_salto
    	j fin

error_divisor_cero:
    	li $v0, 4
    	la $a0, errorCero
    	syscall
    	print_salto	
	
fin:
	li $v0, 10
	syscall
...............................
...............................
...............................
