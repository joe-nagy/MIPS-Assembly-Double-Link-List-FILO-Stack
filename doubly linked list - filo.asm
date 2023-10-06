# $s0 = Address of current node
# $s1 = Used for node creation
# $s2 = Removing user entered \n / deleting node
# $s3 = UNUSED
# $s4 = UNUSED
# $s5 = UNUSED
# $s6 = UNUSED
# $s7 = Head node's address (STATIC))
# $t0 = Address of previous node
# $t1 = Register used for printing
# $t2 = Register used for printing / traversing
# $t3 = Register used for printing/ message printing
# $t4 = Loop counter
# $t5 = UNUSED
# $t6 = UNUSED
# $t7 = UNUSED
# $t8 = User menu choice
# $t9 = List's size (STATIC)

.data
space: .asciiz ", "			# space for between list elements
prompt_menu: .asciiz "\n\nWhat do you want to do?\n\nI.   Push (Insert New Node to the end of list) = 1\nII.  Pop (Remove Last Node in list) = 2\nIII. Exit = -1\n"
user_message1: .asciiz "\nCurrent list: "
user_message2: .asciiz "\nWe popped the following item from the end of the list: "
user_message3: .asciiz "\nList is empty, there is nothing to pop / delete. We are going back to menu:"
user_prompt1: .asciiz "\nEnter a string no more than 16 characters: \n"


.macro PRINT_STRING(%x)
	li $v0, 4			# Service call 4 = print string
	move $a0, %x			# we move contents from $t4 to $a0
	syscall
.end_macro

.macro MENU()
	# Print menu uptions
  	li $v0, 4       	  		# System call 4 = print string
	la $a0, prompt_menu   	        	# Load the address of the menu string
    	syscall
    	# Read user input
    	li $v0, 5				# System call 5 = $v0 contains integer read
   	syscall
   	move $t8, $v0				# we store user choice in $t8
   	beq $t8, 1, LIST_ADD_NODE		# If user_menu_choice == 1 -> LIST_ADD_NODE
   	beq $t8, 2, LIST_POP			# If user_menu_choice == 1 -> LIST_ADD_NODE
   	beq $t8, -1, EXIT			# If user_menu_choice == -1 1 -> EXIT
   	
.end_macro 

.macro ENTER_NODE_VALUE()
  	li $v0, 4       	  		# System call 4 = print string
	la $a0, user_prompt1			# Load the address of the prompt string
    	syscall
    	la $a0, 4($s0)				# we save string to data field
    	li $a1, 32  				# Maximum number of characters to read
   	li $v0, 8				# System call 8 = read string
   	syscall	
   	
   	# when we read user input it contains \n, so we shall remove it
   	remove_new_line:	
    	lb $s2, ($a0) 				# s2 = *a0
    	beq $s2, '\n', end 			# if s2 == '\n' -> we stop
    	addi $a0, $a0, 1 			# a0++
    	j remove_new_line 
    	end:
   	sb $zero, ($a0) 			# overwrite '\n' with 0
   	

.end_macro 

.macro LIST_ADD_NODE()	
	li $a0, 24				# 24 bytes to allocate (4 previous address, 16 for string content, 4 for next address)
	li $v0, 9				# Service Call - 9 = sbrk (allocate heap memory)
	syscall					# $v0 contains address of allocated memory
	move $s0, $v0				# we move memory address requested to $s0	
	bgt $t9, $zero, LIST_NOT_EMPTY		# check if list is empty. $t9 is size of list. 		
	
	sw $zero, 0($s0)			# Headnode's previous node = Nullptr. Means we are the beginning of list
	ENTER_NODE_VALUE()
	sw $zero, 20($s0)			# Next node = Nullptr	
	add $t9, $t9, 1				# ++ list node counter
	move $s7, $s0				# creating head node's address
	move $t0, $s0				# This will be previous node's address when we create new node
	LIST_PRINT()
	MENU()
	
	LIST_NOT_EMPTY:
	ENTER_NODE_VALUE()
	sw $t0, 0($s0)				# we store previous node pointer in current node
	sw $s0, 20($t0)				# we store current node's pointer in previous node	

   	sw $zero, 20($s0)			# Next node = Nullptr			
	add $t9, $t9, 1				# ++ list node counter
	move $t0, $s0				# This will be previous node's address when we create new node
	LIST_PRINT()
	MENU()
.end_macro 

.macro EXIT ()
	li $v0, 10				# Service call 10 = exit
	syscall
.end_macro

.macro LIST_PRINT
  	li $v0, 4       	  		# System call 4 = print string
	la $a0, user_message1  	        	# Load the address of the user_message string
    	syscall
    	move $t1, $s7				# Initialize t1 with head node's address
	list_print_loop:
	 	la $a0, 4($t1)			# Load the address of the string in the current node to $t2
 		li $v0, 4       	  	# System call 4 = print string
		syscall
		
		la $a0, space			# Load the address of the space separator
		li $v0, 4       		# System call 4 = print string
		syscall
		
		lw $t3, 20($t1)
		
		beqz $t3, list_print_loop_done
		move $t1, $t3
		j list_print_loop
	list_print_loop_done:
.end_macro

.macro NODE_DELETE(%node_address)
	addi $t4, $t4, 5			# loop counter for zeroing out the node we are deleting
	move $s2, %node_address			# s2 = node address we want delete
	node_delete_loop:
	sw $zero, 0($s2)			# zeroing out all addresses of node
	addi $s2, $s2, 4			# increment address
	subi $t4, $t4, 1			# decreement loop counter
	bgtz $t4, node_delete_loop		# if loop counter > 0, we repeat loop
	subi $t9, $t9, 1			# we substract one from list size

.end_macro

.macro LIST_POP()
	beqz $t9, empty_list			# if list is empty there is nothing to delete
    	move $t1, $s7				# Initialize t1 with head node's address
	list_traverse:				# we are looking for the tail node
	 	lw $t2, 20($t1)			# Load address of the next node into t1
	 	add $t1, $t1, 24		# moveing to next node
		bgtz $t2, list_traverse		# if next node's address > 0 -> not tail node, move to next node
	la $t3, user_message2			# we load user message2
	PRINT_STRING($t3)			# we print user message2
	sub $t1, $t1, 24			# we are returning to the beginning of tail node
	la $t3, 4($t1)				# we load up string that we are about to delete for printing
	PRINT_STRING($t3)			# we print the string we are about to delete
	lw $t1, 0($t1)				# we return to previous node
	beqz $t1, it_is_head_node		# if previous node pointer == 0, we delete headnode
	move $t2, $t1				# set up temp address $t2 = $t1
	lw $t1, 20($t1)				# we move to the next node
	sw $zero, 20($t2)			# setting up node as tail node. Next node's pointer = nullptr
	NODE_DELETE($t1)			# we are passing the register containg the address of the node we are deleting
	j node_pop_finish			# we jump to the end of the code, skipping rest of code
	it_is_head_node:
	NODE_DELETE($s7)			# we just pass address of head node for deletion
	j node_pop_finish			# we jump to the end of the code, skipping rest of code	
	empty_list:				# this code to execute if list size == 0
	la $t3, user_message3			# we load user message3
	PRINT_STRING($t3)			# we print user message3
	node_pop_finish:
	
.end_macro

.text 	

MENU:
	MENU()
LIST_ADD_NODE:
	LIST_ADD_NODE()
LIST_POP:
	LIST_POP()
	beqz $t9, MENU				# if list is empty we are returning to menu	
	LIST_PRINT()
	MENU()
EXIT:
	EXIT()


	



