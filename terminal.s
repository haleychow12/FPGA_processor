init:
  adr r0, constants
  ldr r2, [r0, #8]
  adr r0, rollparams
  ldr r3, [r0, #12]
init2:
  mov r4, #255
  strb r4, [r2, #0]
  mov r4, #1
  add r2, r4
  cmp r2, r3
  blt init2
  mov r4, #255
  strb r4, [r2, #0]
start:
	adr r0, constants 
  mov r2, #0
  mov r13, r2 @ global line offset of block
loadkey:
	adr r0, constants 
	ldr r2, [r0, #0] @ keyboard addr
	ldr r2, [r2, #0] @ load keyboard 
  mov r5, #13 
  cmp r2, r5
  beq enter
  mov r5, #8 
  cmp r2, r5
  beq backspace
  mov r5, #32 
  cmp r2, r5
  beq space
  mov r5, #42 
  cmp r2, r5
  beq times
  mov r5, #43
  cmp r2, r5
  beq add
  mov r5, #45
  cmp r2, r5
  beq minus
  mov r5, #47
  cmp r2, r5
  beq divide
  mov r5, #61
  cmp r2, r5
  beq equals
  mov r5, #60
  cmp r2, r5
  blt numbers
  bgt letters

times:
  adr r0, symbolsmap
  mov r2, #0
  beq showblock
add:
  adr r0, symbolsmap
  mov r2, #8
  add r0, r2
  mov r2, #0
  beq showblock
minus:
  adr r0, symbolsmap
  mov r2, #16
  add r0, r2
  mov r2, #0
  beq showblock
divide:
  adr r0, symbolsmap
  mov r2, #24
  add r0, r2
  mov r2, #0
  beq showblock
equals:
  adr r0, symbolsmap
  mov r2, #32
  add r0, r2
  mov r2, #0
  beq showblock
space:
  adr r0, symbolsmap
  mov r2, #40
  add r0, r2
  mov r2, #0
  beq showblock
backspace:
  mov r2, #1
  mov r11, r2
  mov r2, r13
  beq backspace2
  mov r3, #1
  neg r3, r3
  add r2, r3
  mov r13, r2
backspace2:
  adr r0, symbolsmap
  mov r2, #40
  add r0, r2
  mov r2, #0
  beq showblock
enter:
  mov r2, #0
  beq rollup

numbers:
  mov r5, #48
  neg r5, r5
  add r2, r5
  mov r14, r2 @ loaded number
  mov r10, r2 @ loaded value
  add r10, r10
  add r10, r10
  add r10, r10 @ make the offset 8
  mov r2, r10 @ r1, r2 should be temp holders
  adr r0, numbersmap
  add r0, r2  @ start addr of current block's code
  mov r2, #0
  beq showblock

letters:
  mov r5, #95
  cmp r2, r5
  blt letters1
  bgt letters2
letters1:
  mov r5, #65
  neg r5, r5
  add r2, r5
  mov r5, #0
  beq letters3
letters2:
  mov r5, #97
  neg r5, r5
  add r2, r5
letters3:
  mov r10, r2 @ loaded value
  add r10, r10
  add r10, r10
  add r10, r10 @ make the offset 8
  mov r2, r10 @ r1, r2 should be temp holders
  adr r0, charactersmap
  add r0, r2  @ start addr of current block's code
  mov r2, #0
  beq showblock

start2: @ two stage branch to avoid branch out of range
  mov r2, #255 @ finish up last pixel
  strb r2, [r5, #0]
  mov r2, #0
  beq start

loadkey2:  @ two stage branch to get to load key
  mov r2, r11
  beq nobs
  mov r2, #0
  mov r11, r2
  mov r2, #1
  neg r2, r2
  mov r3, r13
  add r3, r2
  mov r13, r3
nobs:
  mov r2, #0
  beq loadkey 

showblock:
	adr r2, constants 
  ldr r6, [r2, #4] @ monitor last line addr
  mov r2, r13
  add r2, r2
  add r2, r2
  add r2, r2  
  add r6, r2  @ move to the right by block No * 8
  mov r2, #8  @ 8 lines in a block
  mov r8, r0
  add r8, r2  @ end addr of current block's code
showline:
  ldrb r3, [r0, #0] @ get data for one line
  mov r7, #0
  mov r4, #1
showbit:
  mov r2, r4 @ get the bit for each pixel in the line
  and r2, r3
  beq white
  mov r5, #0 @ black color
  beq paint
white:
  mov r5, #255 @ white color 
paint:
  strb r5, [r6, #0] @ put pixel color in memory
  add r4, r4
  mov r2, #1
  add r7, r2  @ advance line pixel counter
  add r6, r2  @ advance to next pixel in memory
  cmp r7, #8  
  bne showbit

  mov r2, #120
  add r6, r2
  mov r2, #1
  add r0, r2
  cmp r0, r8  @ see if got to the last line in block
  bne showline

  mov r2, #1
  add r13, r2
  mov r2, #16
  cmp r2, r13
  beq rollup

  mov r2, #0
  beq loadkey2
	halt

rollup:
  adr r0, rollparams
  ldr r2, [r0, #0] @ monitor roll up start
  mov r3, r2  @ read addr
  ldr r2, [r0, #4] @ monitor roll up interval
  neg r4, r2
  mov r5, r3
  add r5, r4  @ write addr = read addr - 0400
rollup1:
  ldrb r2, [r3, #0]
  strb r2, [r5, #0]
  mov r2, #0
  beq rollup3
rollup2:
  mov r2, #255
  strb r2, [r5, #0]
rollup3:
  mov r2, #1
  add r3, r2
  add r5, r2
  adr r0, rollparams
  ldr r2, [r0, #8] @ monitor roll up final1
  cmp r5, r2
  ble rollup1
  ldr r2, [r0, #12] @ monitor roll up final2
  cmp r5, r2
  blt rollup2
  beq start2 @ might have to do two jumps

.align 2
constants:
	.word 0xb000  @ keyboard start
	.word 0xfc00  @ monitor last line start
  .word 0xc000  @ start addr for initialization
rollparams:
	.word 0xc400  @ monitor roll up start
	.word 0x0400  @ monitor roll up interval
	.word 0xfc00  @ monitor roll up range
	.word 0xffff  @ monitor roll up range
symbolsmap:
  .word 0x1c2a0000 @ *
  .word 0x0000002a
  .word 0x3e080800 @ +
  .word 0x00000808
  .word 0x3c000000 @ -
  .word 0x00000000
  .word 0x08101000 @ /
  .word 0x00040408
  .word 0x003c0000 @ =
  .word 0x0000003c
  .word 0x00000000 @ Space
  .word 0x00000000
numbersmap:
  .word 0x6666663c @ 0
  .word 0x003c6666
  .word 0x18181c18 @ 1
  .word 0x00181818
  .word 0x3c60623c @ 2
  .word 0x007e0606
  .word 0x3e60603e @ 3
  .word 0x003e6060
  .word 0x66666666 @ 4
  .word 0x0060607e
  .word 0x3e06067e @ 5
  .word 0x003e6060
  .word 0x3e06067c @ 6
  .word 0x003c6666
  .word 0x1830607e @ 7
  .word 0x00181818
  .word 0x3c66663c @ 8
  .word 0x003c6666
  .word 0x7c66663c @ 9
  .word 0x003c6660
charactersmap:
  .word 0x7e66663c @ A
  .word 0x00666666
  .word 0x3e66663e @ B
  .word 0x003e6666
  .word 0x0606663c @ C
  .word 0x003c6606
  .word 0x6666663e @ D
  .word 0x003e6666
  .word 0x1e06067e @ E
  .word 0x007e0606
  .word 0x1e06067e @ F
  .word 0x00060606
  .word 0x7606663c @ G
  .word 0x003c6666
  .word 0x7e666666 @ H
  .word 0x00666666
  .word 0x18181818 @ I
  .word 0x00181818
  .word 0x60606060 @ J
  .word 0x003c6660
  .word 0x0e1e3666 @ K
  .word 0x0066361e
  .word 0x06060606 @ L
  .word 0x007e0606
  .word 0x6b7f7763 @ M
  .word 0x00636363
  .word 0x767e6e66 @ N
  .word 0x00666666
  .word 0x6666663c @ O
  .word 0x003c6666
  .word 0x3e66663e @ P
  .word 0x00060606
  .word 0x6666663c @ Q
  .word 0x006c3666
  .word 0x3e66663e @ R
  .word 0x0066361e
  .word 0x3c06663c @ S
  .word 0x003c6660
  .word 0x1818187e @ T
  .word 0x00181818
  .word 0x66666666 @ U
  .word 0x003c6666
  .word 0x66666666 @ V
  .word 0x00183c66
  .word 0x6b636363 @ W
  .word 0x00367f6b
  .word 0x183c6666 @ X
  .word 0x0066663c
  .word 0x3c666666 @ Y
  .word 0x00181818
  .word 0x1830607e @ Z
  .word 0x007e060c
