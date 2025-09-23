  .section ".text.init","ax",@progbits
  .globl _start
  .align 2
_start:
# prepare registers
lui     t6, 0x8000
slli    t6, t6, 32
srli    t6, t6, 28
addi    s6, t6, 0x100

# load tainted data
ld a2, 0(s6)
# prepare register dump signal
li a1, 0x10

# execute non-ct instruction
div a2, a2, a1
fence
sd a2, 0(a1)
fence
sd s6, 0(a1)
fence

# request stop
li a1, 0x00
sd a1, 0(a1)
fence
stop:
j stop