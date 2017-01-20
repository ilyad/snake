#!/bin/bash

template="randomize-usr-30000.sna" &&
z80asm a.asm &&
let sna_offset=30000-16384+27 &&
a_bin_len=$(wc -c a.bin | awk '{print $1}') &&
let tail=49179-$sna_offset-$a_bin_len &&
( head -c $sna_offset $template &&
  cat a.bin &&
  tail -c $tail $template ) > a.sna &&
wc -c a.sna &&
wc -c a.bin

