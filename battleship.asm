##################################################### PLAY GUIDE ##################################################### 
#
#	Go to Tools -> Bitmap Display -> set "Display Height in Pixels" to 512 -> set
#	"Base address for display" to 0x10040000 (heap) -> adjust the bitmap display area
#	(the black area) to fit the screen -> Connect to MIPS.
#
#	Next, choose Assemble the current file and clear breakpoints -> Run the current program
#	Now you are all set, go to Run I/O to continue playing the game. Please enjoy!
#    
#	Note: while playing, the bitmap will display a 7x7 gird and please remember that the row/colum is 0 indexed.
#	      you can also review your game status and each player's move in "battleLog.txt" file.
#
###################################################################################################################### 
.data
	intro: .asciiz "How to play: each player takes a turn entering the coordinates of all his warships, after that each player in turn will enter the coordinates to shoot in the opponent's grid. \nWhoever hits all the positions containing the other player's warships first will win. \nBitmap display setting: Go to Tools -> Bitmap Display -> set \"Display Height in Pixels\" to 512 -> set \"Base address for display\" to 0x10040000 (heap) -> adjust the bitmap display area (the black area) to fit the screen -> Connect to MIPS."
	msg1: .asciiz "\nENTER SHIP INFOMATIONs OF PLAYER NO. "
	input: .space 8		# 8 cuz input = "a_b_c_d/0"
	targetCord: .space 4	# 4 cuz target coordinate = "a_b/0"
	formatError: .asciiz "\nERROR: Input must be at form \"a_b_c_d\" which a,b,c,d are intergers[0-6]. Please try again!"
	formatError2: .asciiz "\nERROR: Input must be at form \"a_b\" which a,b are intergers[0-6]. Please try again!"
	logicError: .asciiz "\nERROR: Ship's cordinates do not fit the ship's size. Please try again!"
	duplicateError: .asciiz "\nERROR: One/some spot(s) already be occupied. Please try again!"
	get4Ship: .asciiz "\nEnter coordinates of the bow and stern of 1 4x1 ship as the format below\n\"rowbow columnbow rowstern columnstern\": "
	get3Ship: .asciiz "\nEnter coordinates of the bow and stern of 2 3x1 ships as the format below\n\"rowbow columnbow rowstern columnstern\": "
	get2Ship: .asciiz "\nEnter coordinates of the bow and stern of 3 2x1 ships as the format below\n\"rowbow columnbow rowstern columnstern\": "
	turnMsg1: .asciiz "\nPlayer 1's turn. "
	turnMsg2: .asciiz "\nPlayer 2's turn. "
	playStart: .asciiz "Preparation phase completed. Start the game!"
	endMsg1: .asciiz "PLAYER 1 HAS WON!"
	endMsg2: .asciiz "PLAYER 2 HAS WON!"
	getTargetCord: .asciiz "Enter your target coordinate \"x y\": "
	hit:	.asciiz "\nHIT!"
	noHit:	.asciiz "\nNOT HIT!"
	endl: .asciiz "\n"
	changingMsg: .asciiz "Your turn is finished!"
	clear:  .asciiz "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
	fileName: .asciiz "battleLog.txt"
	arr1: .space 49
	arr2: .space 49
	# 7x7 matriz of player 1 will be stored in s0, player 2 one will be in s1
.data 0x10040000
	frameBuffer: .space 0x40000 # 512 wide x 512 high pixels
.text
	li $v0, 55
	la $a0, intro
	li $a1, 1
	syscall
	######################################## OPEN LOG FILE ######################################## 
	li $v0, 13
	la $a0, fileName
	li $a1, 1
	li $a2, 0
	syscall
	move $k1, $v0					# k1 contains file descriptor
	################################################################################################ 
	li $k0, 1					# k0 = 1 -> get player 1's info else get player2's info
	li $v0, 15       				# write turnMsg1 to flie
 	move $a0, $k1       
	la $a1, turnMsg1   
 	li $a2, 18       
 	syscall 				
	li $v0, 15       				
 	move $a0, $k1       
 	la $a1, endl   
 	li $a2, 1
 	syscall            
PLAYER2:
	beq $k0, 1, SLEEP
	li $v0, 15       				# write turnMsg2 to flie
 	move $a0, $k1       
	la $a1, turnMsg2   
 	li $a2, 18       
 	syscall 
 	li $v0, 15       				
 	move $a0, $k1  
 	la $a1, endl   
 	li $a2, 1
 	syscall  
	li $v0, 55
	la $a0, changingMsg
	li $a1, 1
	syscall
	li $v0, 4
	la $a0, clear
	syscall
SLEEP:
	######################################## UI SETUP ######################################## 
	# clear the display in black
	la $s0, frameBuffer 		# load frame buffer address
	li $s1, 0x40000 		# save 512*512 pixels
	li $s2, 0	 		# load black color
draw_background:
	sw $s2, 0($s0)
	addi $s0, $s0, 4 		# advance to next pixel position in display
	addi $s1, $s1, -1 		# decrement number of pixels
	bnez $s1, draw_background 	# repeat while number of pixels is not zero
draw_row:
	la $s0, frameBuffer
	li $s1, 0x000000FF 		# load blue color
	li $s2, 73728			# ini = s2
	li $t0, 0			# i = 0
	li $t1, 0			# j = 0
	li $t2, 0			# k = 0
	FOR1:
		beq $t0, 8, draw_col
		FOR2:
			bne $t1, 8, FOR3
			li $t1, 0		# if j == 8 then ++i and j = 0
			addi $t0, $t0, 1
			j FOR1
			FOR3:
				bne $t2, 512, DRAW 	# while k < 8 draw row
				li $t2, 0		
				addi $t1, $t1, 1
				j FOR2
				DRAW:
					mul $t3, $t2, 4
					mul $t4, $t0, $s2
					add $t3, $t3, $t4
					mul $t5, $t1, 2048
					add $t3, $t3, $t5
					add $t3, $t3, $t4
					add $t3, $t3, $s0
					sw $s1, 0($t3)		# arr + k*4(each pixel) + i*ini(each box) + j*2048 (each row)
					addi $t2, $t2, 1
					j FOR3  
draw_col:
	li $s2, 144			
	li $t0, 0			# i = 0
	li $t1, 0			# j = 0
	li $t2, 0			# k = 0
	FOR4:
		beq $t0, 8, START_GETTING_INPUT
		FOR5:
			bne $t1, 8, FOR6
			li $t1, 0		# if j == 8 then ++i and j = 0
			addi $t0, $t0, 1
			j FOR4
			FOR6:
				bne $t2, 512, DRAW1 	# while k < 512 draw col
				li $t2, 0		
				addi $t1, $t1, 1
				j FOR5
				DRAW1:
					mul $t3, $t1, 4
					mul $t4, $t0, $s2
					add $t3, $t3, $t4
					mul $t5, $t2, 2048
					add $t3, $t3, $t5
					add $t3, $t3, $t4
					add $t3, $t3, $s0
					sw $s1, 0($t3)		
					addi $t2, $t2, 1
					j FOR6  
	###################################################################################################### 
	# start getting ships info
START_GETTING_INPUT:
	li $v0, 4
	la $a0, msg1
	syscall
	li $v0, 1
	move $a0, $k0
	syscall
	li $v0, 4
	la $a0, endl
	syscall
	#########################################\\SET UP PLAY GRID\\####################################################
	beq $k0, 2, TEMP15
	la $s0, arr1
	j TEMP16
	TEMP15:
	la $s0, arr2
	TEMP16:
	# array initization
	li $t0, 0					# i = 0
	li $t1, 0					# j = 0
	OUTER_LOOP:
		beq $t0, 7, EXIT_OUTER_LOOP		# if i == 7 then finish
		li $t1, 0				# j = 0
		INNER_LOOP:
			# we can access arr[i][j] by arr[i * 7 + j]
			mul $t2, $t0, 7			# get i * 7 (7 = 1 * 7 = total bytes in a row or col)
			add $t2, $t2, $t1		# get i * 7 + j
			add $t3, $s0, $t2		# get address arr[i * 7 + j] to t3
			#move $t4, $zero		# set t4 = 0 (MAY BE REMOVED LATER)
			sb $zero, 0($t3)		# arr[i][j] = 0
			addi $t1, $t1, 1		# ++j
			bne $t1, 7, INNER_LOOP		# if j < 7 then continue lopping
			addi $t0, $t0, 1		# if j == 7 then ++i and j = 0
			j OUTER_LOOP
	EXIT_OUTER_LOOP:
	#########################################\\GET PLAYER's GRID COORDINATE\\####################################################
	# GET USER's INPUT:
	# a3 will be the length of the ship's
	# a2 will be the number of ships
	# a1 will be the number of ships (const)
	li $a3, 4
	li $a2, 1					# these are default settings
	li $a1, 1
MAIN:
	beqz $a2, MINUS_LENGTH
	beq $a3, 4, GET4_SHIP
	beq $a3, 3, GET3_SHIP
	beq $a3, 2, GET2_SHIP
	MINUS_LENGTH:
	sub $a3, $a3, 1
	beq $a3, 1, GET_PLAYER2
	addi $a2, $a1, 1
	addi $a1, $a1, 1
	beq $a3, 3, GET3_SHIP
	beq $a3, 2, GET2_SHIP
	#############################################################################################
	GET4_SHIP:
		la $a0, get4Ship
		j GET_INPUT
	GET3_SHIP:
		la $a0, get3Ship
		j GET_INPUT
	GET2_SHIP:
		la $a0, get2Ship
		j GET_INPUT
	GET_INPUT:
	li $v0, 4
	syscall
	
	move $s2, $a1
	li $v0, 8	
	li $a1, 8
	la $a0, input
	syscall
	move $a1, $s2
	
	la $s1, input
	li $t0, 0
	li $t7, 0					# t7 counts how many number occur in the input
	addi $sp, $sp, -4				# open stack to store a, b, c and d
	FIND_FORMAT_ERROR:
		add $t1, $s1, $t0
		lb $t2, 0($t1)
		beq $t2, 35, END_PROGRAM		# End the program urgently by typing "#"
		beq $t2, 32, INCREASE			# if t2 = 32 (space) then skip
		
		sltiu $t9, $t2, 48
		sgtu $t9, $t2, 54			# if t2 < 0 (48 in ACSII) or t2 > 54 (6 in ASCII) then raise error	
		beq $t9, 1, RAISE_FORMAT_ERROR		
		
		beq $t2, 10, RAISE_FORMAT_ERROR		# if t2 = 10 then found endl->raise error 
		
		add $t6, $sp, $t7
		sb $t2, 0($t6) 
		addi $t7, $t7, 1			# ++count
		
		beq $t0, 6, INCREASE			# if thats the end of the input then skip the error under
		lb $t8, 1($t1)
		bne $t8, 32, RAISE_FORMAT_ERROR		# if input[i] is a valid number and input[i+1] is also a number then error				
	INCREASE:
		addi $t0, $t0, 1
		beq $t0, 7, CONTINUE
		j FIND_FORMAT_ERROR
	RAISE_FORMAT_ERROR:
		addi $sp, $sp, -1
		sb $a1, 0($sp)
		li $v0, 55
		la $a0, formatError
		li $a1, 0
		syscall
		lb $a1, 0($sp)
		addi $sp, $sp, 1
		li $v0, 4
		la $a0, endl
		syscall
		sb $zero, 0($sp)				# restore stack if input is invalid
		sb $zero, 1($sp)
		sb $zero, 2($sp)
		sb $zero, 3($sp)
		addi $sp, $sp, 4
		j MAIN
	CONTINUE:
	bne $t7, 4, RAISE_FORMAT_ERROR			# if there is not 4 numbers in the input then raise error
	#############################################################################################
	
	LOGIC_CHECK:
	lb $s4, 0($sp)
	lb $s5, 1($sp)
	lb $s6, 2($sp)
	lb $s7, 3($sp)
	sb $zero, 0($sp)				
	sb $zero, 1($sp)
	sb $zero, 2($sp)
	sb $zero, 3($sp)
	addi $sp, $sp, 4				# return stack back to normal
	
	li $t0, 0
	sub $s3, $a3, 1					# s3 = n - 1
	
	bne $s4, $s6, TEMP3	
	bge $s5, $s7, TEMP1				# when s4 == s6 (a == c)
	j TEMP2
	TEMP1:	sub $t2, $s5, $s7			# s5 > s7
		move $t3, $s7 
		move $s6, $s5				
		move $s5, $t3
		j END1
	TEMP2:	sub $t2, $s7, $s5			# s5 < s7
		move $s6, $s7
	END1:
		seq $t0, $t2, $s3
		beqz $t0, CONTINUE2
		li $t9, 0				# X Write Mode = 0 
		j CONTINUE3				# if (a == c && |b-d| = n-1 then the input is valid
		
	CONTINUE2:
	li $t0, 0
	TEMP3:
	bne $s5, $s7, RAISE_LOGIC_ERROR
	bge $s4, $s6, TEMP4				# when s5 == s7
	j TEMP5
	TEMP4: 	sub $t2, $s4, $s6
		move $s5, $s6				
		move $s6, $s4
		j END2 
	TEMP5:	sub $t2, $s6, $s4
		move $s5, $s4
	END2:
		seq $t0, $t2, $s3
		beqz $t0, RAISE_LOGIC_ERROR
		move $s4, $s7
		li $t9, 1				# Y Write Mode = 1 
		j CONTINUE3				# if (b == d && |a-c| = n-1 then the input is valid
	RAISE_LOGIC_ERROR:
		addi $sp, $sp, -1
		sb $a1, 0($sp)
		li $v0, 55
		la $a0, logicError
		li $a1, 0
		syscall
		lb $a1, 0($sp)
		addi $sp, $sp, 1
		li $v0, 4
		la $a0, endl
		syscall
		j MAIN
	RAISE_DUPLICATE_ERROR:
		addi $sp, $sp, -1
		sb $a1, 0($sp)
		li $v0, 55
		la $a0, duplicateError
		li $a1, 0
		syscall
		lb $a1, 0($sp)
		addi $sp, $sp, 1
		li $v0, 4
		la $a0, endl
		syscall
		j MAIN		
	CONTINUE3:
	# check if there are ships share one same place in the matrix
	# Convention: s4 contain (a=c) or (b=d)
	#	      s5 is from pointer, s6 is to pointer
	# Duplicate check:
	sub $s4, $s4, 0x30
	sub $s5, $s5, 0x30
	sub $s6, $s6, 0x30
	li $t0, 0					# checking flag (= 0 when check duplicate, = 1 when write data)
	li $s7, 1					
	move $t1, $s5					# idx = t1 = s5 (free s5)
	DUPLICATE_LOOP:					# looping from arr[s4][s5] to arr[s4][s6] or arr[s5][s4] to arr[s6][s4]
		beq $t9, 1, WRITE_MODE_Y		# as from arr[s4 * 7 + s5] to arr[s4 * 7 + s6] or
		move $s2, $s4				#    from arr[s5 * 7 + s4] to arr[s6 * 7 + s4]
		move $s3, $t1				# the two "move" line is the arguments to DRAW_SQUARE funciton
		mul $t8, $s4, 7				
		add $t2, $t8, $t1 	
		j TEMP7		
		WRITE_MODE_Y:
		move $s2, $t1
		move $s3, $s4	
		mul $t8, $t1, 7	
		add $t2, $s4, $t8
		TEMP7:			
		add $t3, $s0, $t2
		lb $t4, 0($t3)
		bnez $t0, WRITE_MODE
		bnez $t4, RAISE_DUPLICATE_ERROR		# check mode
		j TEMP6
		WRITE_MODE:
		sb $s7, 0($t3)  
		jal DRAW_SQUARE
		TEMP6:
		addi $t1, $t1, 1
		bgt $t1, $s6, EXIT_DUPLICATE_LOOP
		j DUPLICATE_LOOP
	EXIT_DUPLICATE_LOOP:
	beqz $t0, TURN_ON_WRITE_MODE
	j CONTINUE4
	TURN_ON_WRITE_MODE:
	li $t0, 1
	move $t1, $s5
	j DUPLICATE_LOOP
	CONTINUE4:
	sub $a2, $a2, 1 
	jal WRITE_SHIP_TO_FILE
	j MAIN
GET_PLAYER2:
	beq $k0, 2, CONTINUE5
	addi $k0, $k0, 1
	j PLAYER2
CONTINUE5:
	li $v0, 55					# print massege that the game has started
	la $a0, playStart
	li $a1, 1
	syscall
	li $v0, 15    					# write to file starting massege
	move $a0, $k1  
	la $a1, playStart   
	li $a2, 44       
	syscall      
	li $v0, 15    					
	move $a0, $k1  
	la $a1, endl   
	li $a2, 1       
	syscall 
	la $s2, frameBuffer 		# load frame buffer address
	li $s3, 0x40000 		# save 512*512 pixels
	li $s4, 0	 		# load black color
reset_background2:
	sw $s4, 0($s2)
	addi $s2, $s2, 4 		# advance to next pixel position in display
	addi $s3, $s3, -1 		# decrement number of pixels
	bnez $s3, reset_background2 	# repeat while number of pixels is not zero
	
	la $s0, arr1						# after getting 2 players's ship infos, the adrress of 2 array
	la $s1, arr2						# located at s0 = arr1, s1 = arr2
	li $s4, 16						# s4 and s5 are the total number of spots to be destroyed 
	li $s5, 16						# 16 = 1x4 + 2x3 + 3x2 
	li $k0, 1			# k0 = 1 ->get player 1 target else k0 = 2-> get playere 2 target
GET_TARGET_CORDINATE:
	# endgame checking
	bne $s4, 0, TEMP8
	la $a0, endMsg2
	j ANNOUNCE_WINNER
	TEMP8: 
	bne $s5, 0, TEMP9 
	la $a0, endMsg1
	j ANNOUNCE_WINNER	
	TEMP9:
	#clear screen
	li $v0, 4
	la $a0, clear
	syscall
	# START GETTING COORDINATES
	bne $k0, 1, TEMP10				
	li $k0, 2
	la $a0, turnMsg1 
	j TEMP11
	TEMP10:
	li $k0, 1
	la $a0, turnMsg2
	TEMP11:
	li $v0, 4
	syscall 
	
	li $v0, 15    					# write turnMsg to file
	move $a1, $a0   
	move $a0, $k1 
	li $a2, 18       
	syscall
TEMP12:	
	li $v0, 4
	la $a0, getTargetCord
	syscall
	li $v0, 8
	la $a0, targetCord
	li $a1, 4
	syscall
	# target coordiate valid check, if not valid go back to TEMP12
	la $t0, targetCord
	li $t1, 0
	li $t5, 0					# number counter of the coordinate (the input maybe valid if t5 = 2)
	addi $sp, $sp, -2				# open stack to store a and b
	
	# edge case for detecting error
	lb $t8, 2($t0)
	beq $t8, 32, RAISE_TARGET_FORMAT_ERROR		# if last char
	lb $t8, 0($t0)
	beq $t8, 32, RAISE_TARGET_FORMAT_ERROR
	TARGET_VALID_CHECK:
		add $t2, $t0, $t1
		lb $t3, 0($t2)
		beq $t3, 35, END_PROGRAM		# End the program urgently by typing "#"
		beq $t3, 32, INCREASE2			# skip the " " (space) character
		beq $t3, 10, RAISE_TARGET_FORMAT_ERROR 	
		blt $t3, 48, RAISE_TARGET_FORMAT_ERROR
		bgt $t3, 54, RAISE_TARGET_FORMAT_ERROR
		add $t4, $sp, $t5
		sb $t3, 0($t4)				# store a, b to stack
		addi $t5, $t5, 1
		INCREASE2:
		addi $t1, $t1, 1
		beq $t1, 3, EXIT_TARGET_VALID_CHECK
		j TARGET_VALID_CHECK
	EXIT_TARGET_VALID_CHECK:
	bne $t5, 2, RAISE_TARGET_FORMAT_ERROR
	j TARGET_LOGIC_CHECK
	RAISE_TARGET_FORMAT_ERROR:
	li $v0, 55
	la $a0, formatError2
	li $a1, 0
	syscall
	li $v0, 4
	la $a0, endl
	syscall
	sb $zero, 0($sp)
	sb $zero, 1($sp)
	addi $sp, $sp, 2
	j TEMP12 
	########
	TARGET_LOGIC_CHECK:	
	li $v0, 15    					# write target coordinate to file   
	move $a0, $k1 
	la $a1, targetCord
	li $a2, 4       
	syscall
	# target coordiate logic check
	lb $s6, 0($sp)						
	lb $s7, 1($sp)
	sub $s6, $s6, 0x30
	sub $s7, $s7, 0x30
	sb $zero, 0($sp)				
	sb $zero, 1($sp)
	addi $sp, $sp, 2
	beq $k0, 2, TEMP13					# here player 1 will have k0 = 2 and player 2 will have k0 = 1
	move $t0, $s0						# player 1
	j TEMP14
	TEMP13:
	move $t0, $s1						# player 2
	TEMP14:
	mul $s6, $s6, 7						# now t0 contain base address of the other player's ship array
	add $s6, $s6, $s7					# and s6 contain a, s7 contain b
	add $s6, $s6, $t0
	lb $t1, 0($s6)
	bne $t1, 1, NOT_HIT
	HIT:
	li $v0, 4
	la $a0, hit
	syscall
	
	li $v0, 15    						# Write hit to file
	move $a0, $k1  
	la $a1, hit   
	li $a2, 5       
	syscall      
	
	li $v0, 32
	la $a0, 2000						# system sleeps for 2 seconds for each choosing action
	syscall
	sb $0, 0($s6)
		beq $k0, 1, PLAYER1_HIT
		j PLAYER2_HIT
		PLAYER1_HIT:
		addi $s4, $s4, -1
		j GET_TARGET_CORDINATE
		PLAYER2_HIT:
		addi $s5, $s5, -1
		j GET_TARGET_CORDINATE
	NOT_HIT:
	li $v0, 4
	la $a0, noHit
	syscall
	
	li $v0, 15    						# Write no hit to file
	move $a0, $k1  
	la $a1, noHit   
	li $a2, 9       
	syscall   
	
	li $v0, 32
	la $a0, 1500					# system sleeps for 1,5 seconds
	syscall
	########
	# GO BACK
	j GET_TARGET_CORDINATE
	########
	################################################## HELPER FUNCTIONS ################################################## 
END_PROGRAM:
	###############################################################
	# write winner to file
	li $v0, 15    
	move $a0, $k1  
	la $a1, endl  
	li $a2, 1       
	syscall  
	li $v0, 15    
	move $a1, $s0
	move $a0, $k1    
	li $a2, 17       
	syscall  
	# Close the file 
	li $v0, 16       
	move $a0, $k1      
	syscall           
	###############################################################
	li $v0, 10
	syscall
ANNOUNCE_WINNER:
	li $v0, 55
	la $a1, 1
	syscall 
	move $s0, $a0
	j END_PROGRAM
DRAW_SQUARE:
	addi $sp, $sp, -24				
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	sw $s3, 12($sp)
	sw $t0, 16($sp)
	sw $t1, 20($sp)
	sw $t2, 24($sp)
	
	la $s0, frameBuffer
	li $s1, 0x00ffffff
	mul $s2, $s2, 72
	mul $s3, $s3, 72
	addi $s2, $s2, 24
	addi $s3, $s3, 24
	mul $s2, $s2, 2048
	mul $s3, $s3, 4
	add $s2, $s3, $s2
	add $s2, $s0, $s2

	li $t0, 0			# i = 0
	li $t1, 0			# j = 0
	FOR7:
		beq $t0, 32, GO_BACK
		li $t1, 0 
		FOR8:
			add $t2, $s2, $t1
			sw $s1, 0($t2)
			addi $t1, $t1, 4
			bne $t1, 128, FOR8
			addi $s2, $s2, 2048
			addi $t0, $t0, 1
			j FOR7
GO_BACK:			
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	lw $s3, 12($sp)
	lw $t0, 16($sp)
	lw $t1, 20($sp)
	lw $t2, 24($sp)
	addi $sp, $sp, 24
	jr $ra

WRITE_SHIP_TO_FILE:
	addi $sp, $sp, -4
	sb $a0, 0($sp)
	sb $a1, 1($sp)
	sb $a2, 2($sp)
	sb $a3, 3($sp)
	li $v0, 15    
	move $a0, $k1  
	la $a1, input   
	li $a2, 8       
	syscall      
	li $v0, 15       				
 	move $a0, $k1       
	la $a1, endl  
	li $a2, 1       
	syscall 
	lb $a0, 0($sp)
	lb $a1, 1($sp)
	lb $a2, 2($sp)
	lb $a3, 3($sp)
	addi $sp, $sp, 4
	jr $ra
