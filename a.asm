; vim:syntax=z8a:

black:  equ 0
blue:   equ 1
red:    equ 2
magenta:equ 3
green:  equ 4
cyan:   equ 5
yellow: equ 6
white:  equ 7
bright: equ 1<<6
flash:  equ 1<<7

black_on_white: equ black+white*8
green_on_green: equ green*9
black_on_black: equ black*9
yellow_magenta: equ bright+flash+yellow+magenta*8
cyan_magenta: equ bright+flash+cyan+magenta*8

fruit_attr: equ cyan_magenta
 free_attr: equ black_on_white
snake_attr: equ green_on_green
 wall_attr: equ black_on_black
bloody_attr: equ bright+flash+red+yellow*8


org 30000
ATTR: equ 0x5800

  ld d, 35 ; initial speed
  exx
  
  ld a, wall_attr
  ld hl, ATTR
  ld de, ATTR+1
  ld bc, 32
  ld (hl), a
  LDIR

  ld de, ATTR+31+32
  ld (de), a

  inc de
  ld bc, 21*32 - 1
  LDIR

  ld d,h
  ld e,l
  inc de
  ld c, 32 ; b=0 already
  LDIR

  ld hl, ATTR+32*5+15
  ld a, snake_attr
  ld c, 32
  ld (hl),fruit_attr
  add hl,bc 
  push hl
  ld (hl),a
  add hl,bc 
  push hl
  ld (hl),a
  ld ix, 2
  add ix, sp

change_speed:
  exx
  ld a,b
  add d
  ld b,a
  jr nc, not_dec_de
  dec de
not_dec_de:
  push de
  exx
  pop de
read_ports:
  ; set C to keyboard port
  ; set B to '54321' row
  ld bc, 0x100 * %11110111 + 254
  ; read '5' key and shift it from bit 4 to bit 5
  in a, (c)
  rl a
  ; shift B to next row '67890'
  rl b
  ; read '67890' and append value of '5'
  in b, (c)
  and b
  ; set bits 11____11
  or %11000011

  ld hl, kbd_state
  ; save keyboard state to B
  ld b,a
  ; new key: now is 0 && last time was 1
  cpl a
  and (hl)
  ; save new state back to (kbd_state)
  ld (hl), b
  jr nz, new_key_pressed
  dec de
  ld a,d
  or e
  jr nz, read_ports

no_key_pressed:
  ld de, (direction)
  jr de_has_direction
new_key_pressed:
  push de ; the value will be used in 'randomize'
  ; A contains non zero "new key" mask
  ld de, -32 ; (D,E)=(ff,-32)
  and %11110111 ; UP is the last bit
  jr z, randomize
  ld e,d ; (D,E)=(ff,ff)=-1
  and %11011111 ; LEFT is the last bit
  jr z, randomize
  inc de ; DE=0
  inc de ; DE=1
  and %11111011 ; RIGHT is the last bit
  jr z, randomize
  ld e, 32 ; ok, it's DOWN
randomize:
  exx
  pop hl ; the time counter 'de' value saved above
  ld a,r
  xor c
  add l ; only using low half of old 'de' counter
  ld c,a
  exx
de_has_direction:
  ld (direction), de
  pop hl
  push hl
  add hl, de ; HL is the next position
  push hl ; making the snake longer!
  ; checking next position
  ld a, (hl)
  cp fruit_attr
  jr z, place_fruit
  cp free_attr
  jr z, clear_tail
  ld (hl), bloody_attr
  di
  halt
  rst 0 ; game over
clear_tail:
  ld l, (ix+0)
  ld h, (ix+1)
  ld (hl), free_attr
shift_snake:
  ; CF=0, because last jump was "jr z"
  ; thus not necessary to do "OR A,A"
  push ix
  pop hl
  ld d,h
  ld e,l
  sbc hl,sp ; CF=0, see above
  ld b,h
  ld c,l
  ld h,d
  ld l,e
  inc de
  dec hl
  LDDR
  pop hl ; making the snake shorter again!
draw_head:
  ld (hl), snake_attr

  JR change_speed

place_fruit:
  exx
try_again:
  ld a,r
  xor c
  ld c,a
  ld h, 0x58/2
  ld l,a
  add hl,hl
  ld a,(hl)
  cp free_attr
  jr nz, try_again
  ld (hl), fruit_attr
  exx
  jr draw_head 

  
kbd_state: db 0
direction: dw 32


end 