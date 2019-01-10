{Object_Title_and_Purpose}


CON
        _clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 5_000_000

VAR
  long  pin
  long one,two,three,four,five,six,seven,eight,nine,zero
   
PUB prop2_test

one:=%00101000
two:=%11001101
three:=%01101101
four:=%00101011
five:=%01100111
six:=%11100111
seven:=%00101100
eight:=%11101111
nine:=%00101111
zero:=%11101110

dira[0..7]:=%11111111
dira[16..23]:=%11111111
dira[24..31]:=%11111111
repeat
  outa[0..7]:=one
  outa[23..16]:=one
  outa[24..31]:=%01111111
  waitcnt(clkfreq/2+cnt)
  outa[0..7]:=two
  outa[23..16]:=two
  outa[24..31]:=%10111111 
  waitcnt(clkfreq/2+cnt)
  outa[0..7]:=three
  outa[23..16]:=three
  outa[24..31]:=%11011111 
  waitcnt(clkfreq/2+cnt)
  outa[0..7]:=four
  outa[23..16]:=four
  outa[24..31]:=%11101111
  waitcnt(clkfreq/2+cnt)
  outa[0..7]:=five
  outa[23..16]:=five
  outa[24..31]:=%11110111
  waitcnt(clkfreq/2+cnt)
  outa[0..7]:=six
  outa[23..16]:=six
  outa[24..31]:=%11111011
  waitcnt(clkfreq/2+cnt)
  outa[0..7]:=seven
  outa[23..16]:=seven
  outa[24..31]:=%11111101
  waitcnt(clkfreq/2+cnt)
  outa[0..7]:=eight
  outa[23..16]:=eight
  outa[24..31]:=%11111110
  waitcnt(clkfreq/2+cnt)
  outa[0..7]:=nine
  outa[23..16]:=nine
  outa[24..31]:=%11111100
  waitcnt(clkfreq/2+cnt)
  outa[0..7]:=zero
  outa[23..16]:=zero
  outa[24..31]:=%111110-10
  waitcnt(clkfreq/2+cnt)
  

