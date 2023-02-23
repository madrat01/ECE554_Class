##################################
# ASM file for testing the SPART #
# Author: Aidan McEllistrem      #
##################################



### Peripheral Addresses:
# 0xC004: TX/RX buffer access: reads from RX circular queue and
#         writes to TX circular queue
# 0xC005: Status Register (read only, returns # of entries)
#         [7:4]: # entries remaining in tx queue
#         [3:0]: # entries filled in rx queue
# 0xC006: DBL baud rate division buffer low byte
# 0xC007: DBH baud rate division buffer high byte

### VT100 Escape Codes:
# ^[[2J   Clear Screen
# ^[E     Move to next line

### Register Uses:
# R1      CONST: 0xC004  TX/RX peripheral address
# R2      Temporary variable
# R3      String pointer
# R4      CONST: 0x0001  Increment amount (1)
# R5      CONST: 0x000D  <CR>
# R6      CONST: 0x0009  BUFFER_MAX_SIZE
# R10     Return address save (NO STACK)
# R14     Temporary variable for .WaitStatusReg, used as size of register
# R15     Return address

# Load constants
llb R3, 0x00 # starting address
lhb R3, 0x00
llb R4, 0x01 # increment amount
llb R5, 0x0D # <CR>
llb R6, 0x09 # max # of entries in buffer
llb R11,0x0F # bitmask for lower 4 bytes

# Set baud rate at 0xC006 and 0xC007 to standard 115200 (0x01B2)
llb R1, 0x04
lhb R1, 0xC0
llb R2, 0xB2
sw  R2, R1, 2
llb R2, 0x01
sw  R2, R1, 3

# Clear screen
jal .ClearScreen

# Reposition cursor to top left
jal .CursorHome

# Offset a bit down for display purposes
jal .NextLine
jal .NextLine
jal .NextLine

# Print "Hello World" (can only send 9 entries to the buffer at once,
# will stick to 8 for safety)
jal .Tab
jal .Tab
jal .Hello_
jal .World

# Position cursor on next line
jal .NextLine
# Poll status register, read in character
# starting at 0x0000 (any below 0xC000 is free)
.PollName:
  # stall until has a character
  # (bottom four bits of status reg == 15)
  # (mem[0xC0005] & 0x0F) != 0
  lw  R14, R1, 1
  and R14, R14, R11
  b   eq, .PollName
  # get character from RX buffer
  lw  R2, R1, 0
  # store in memory 
  sw  R2, R3, 0

  # wait for send buffer to be empty
  jal .WaitRXStatusReg
  # increment pointer for next char
  add R3, R3, R4
  # last char wasn't <CR> (0x0D)? Keep polling then
  sub R2, R2, R5
  b   neq, .PollName
  # store null terminator
  llb R2, 0x00
  lhb R2, 0x00
  sw  R2, R3, 0

llb R3, 0x00 # reset starting address
# Print "Hello <name>"
jal .Tab
jal .Hello_

.PrintName:
  # get character from 0x0000 at start
  lw  R2, R3, 0
  # inc to next
  add R3, R3, R4
  # send to TX buffer
  sw  R2, R1, 0

  # Check flags
  sll R14, R2, 0
  # repeat till we get a 0 (null terminator)
  b   neq, .PrintName


# Wait forever once done
.done:
  b   uncond, .done

#############
# Functions #
#############store

.WaitStatusReg:
  # Grab status value (assumed that R1 points to 0xC004)
  lw  R14, R1, 1
  # Shift bits [7:4] to [3:0] (>>4)
  srl R14, R14, 4
  # Subtract 8 from R14,
  # Return when there are 8 entries available for TX
  llb R13, 0x08
  sub R14, R14, R13 
  b   neq, .WaitStatusReg
  jr  R15


.WaitRXStatusReg:
  lw  R14, R1, 1
  and R14, R14, R11
  b   neq, .WaitRXStatusReg
  jr  R15

##########################
# """String Constants""" #
##########################

# Must call a poll to status register to wait for an empty buffer

# Send ^[[2J
.ClearScreen:
  llb R2, 0x1B
  sw  R2, R1, 0
  llb R2, 0x5B
  sw  R2, R1, 0
  llb R2, 0x32
  sw  R2, R1, 0
  llb R2, 0x4A
  sw  R2, R1, 0
  sll R10, R15, 0 
  jal .WaitStatusReg
  sll R15, R10, 0
  jr  R15


# Send ^[[E
.CursorHome:
  llb R2, 0x1B
  sw R2, R1, 0
  llb R2, 0x5B
  sw R2, R1, 0
  llb R2, 0x48
  sw R2, R1, 0
  sll R10, R15, 0
  jal .WaitStatusReg
  sll R15, R10, 0
  jr R15


# Send exactly 8 spaces
.Tab:
  llb R14, 0x08
  TabLoop:
  llb R2, 0x20
  sw R2, R1, 0
  # Decrement 1
  sub R14, R14, R4
  b   neq, TabLoop
  sll R10, R15, 0
  jal .WaitStatusReg
  sll R15, R10, 0
  jr R15


# Send ^[Estore
.NextLine:
  llb R2, 0x1B
  sw  R2, R1, 0
  llb R2, 0x45
  sw  R2, R1, 0
  sll R10, R15, 0 
  jal .WaitStatusReg
  sll R15, R10, 0
  jr  R15


.Hello_:
  #"Hello "
  llb R2, 0x48
  sw  R2, R1, 0
  llb R2, 0x65
  sw  R2, R1, 0
  llb R2, 0x6C
  sw  R2, R1, 0
  llb R2, 0x6C
  sw  R2, R1, 0
  llb R2, 0x6F
  sw  R2, R1, 0
  llb R2, 0x20
  sw  R2, R1, 0
  sll R10, R15, 0 
  jal .WaitStatusReg
  sll R15, R10, 0
  jr  R15


.World:
  #"World"
  llb R2, 0x57
  sw  R2, R1, 0
  llb R2, 0x6F
  sw  R2, R1, 0
  llb R2, 0x72
  sw  R2, R1, 0
  llb R2, 0x6C
  sw  R2, R1, 0
  llb R2, 0x64
  sw  R2, R1, 0
  sll R10, R15, 0 
  jal .WaitStatusReg
  sll R15, R10, 0
  jr  R15
