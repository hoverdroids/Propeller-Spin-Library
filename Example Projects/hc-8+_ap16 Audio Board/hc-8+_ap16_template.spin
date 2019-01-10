'' =================================================================================================
''
''   File....... hc-8+_ap16_template.spin
''   Purpose.... Standard programming template for EFX-TEK HC-8+
''   Author..... Jon "JonnyMac" McPhalen
''               Copyright (c) 2011-2012 Jon McPhalen
''               -- see below for terms of use
''   E-mail.....  
''   Started.... 
''   Updated.... 16 AUG 2012
''
'' =================================================================================================


con

  PCB_REV = "C"


con

  _clkmode = xtal1 + pll16x
  _xinfreq = 6_000_000                                          ' 5MHz crystal

  CLK_FREQ = ((_clkmode - xtal1) >> 6) * _xinfreq
  MS_001   = CLK_FREQ / 1_000
  US_001   = CLK_FREQ / 1_000_000
  

con

  RX1     = 31                                                  ' programming / debug port
  TX1     = 30
  
  SDA     = 29                                                  ' eeprom
  SCL     = 28

  OUT_EN  = 27                                                  ' outputs enable pin (low)     
  
  SIO     = 26                                                  ' TTL serial io
  
  RX2     = 23                                                  ' RS-485 port
  RX2_EN  = 22
  TX2_EN  = 21
  TX2     = 20

  R_LED   = 18                                                  ' bi-color LED
  G_LED   = 17

  OUT7    = 15                                                  ' outputs
  OUT6    = 14   
  OUT5    = 13 
  OUT4    = 12
  OUT3    = 11
  OUT2    = 10   
  OUT1    =  9 
  OUT0    =  8
          
  OPT_BR  =  7                                                  ' options swithes
  OPT_A1  =  6   
  OPT_A0  =  5
  OPT_SM  =  4

  DMX_A8  =  3                                                  ' high-bit off DMX address

  DO_165  =  2                                                  ' control lines for 74x165
  CLK_165 =  1 
  LD_165  =  0


  ' for EFX-TEK GameOn adapter module (#99001)

  WII_DAT =  OPT_A0
  WII_CLK =  OPT_SM 

  
  ' for EFX-TEK uSD adapter module (#99002)
  ' -- must open all option switches when installed

  SD_CS   =  OPT_BR                                       
  SD_DI   =  OPT_A1  
  SD_CLK  =  OPT_A0  
  SD_DO   =  OPT_SM


con

   #0, OFF, RED, GRN, YEL                                       ' for r/g led

   #0, NOCON, RX, TX, RXTX                                      ' for rs-485

   #0, LSBFIRST, MSBFIRST                                       ' for 74x165 shift-register                                               


con

   #1, HOME, GOTOXY, #8, BKSP, TAB, LF, CLREOL, CLRDN, CR       ' PST formmatting control
  #14, GOTOX, GOTOY, CLS


obj

  term  : "fullduplexserial64"                                  ' terminal IO
  rr    : "realrandom"                                          ' real random from hardware
  prng  : "efx_prng"                                            ' pseudo-random number generator
  outs  : "efx_pwm8"                                            ' pwm driver for outputs
  audio : "Simple_Serial"   '"fullduplexserial64"                                  ' serial for AP-16+ coms
      

var
byte statusByte[2]

dat

Version                 byte    "???", 0



pub main | check

  'setup_io                                                      ' configure HC-8 io pins

  'term.start(RX1, TX1, %0000, 115_200)                          ' start terminal

  'rr.start                                                      ' load hardware randomizer
  'prng.seed(rr.random, rr.random, rr.random, rr.random, rr.random)  
  'rr.stop                                                       ' unload hardware randomize

  'outs.start(8, OUT0)                                           ' start led driver

  'term.rxflush
  'term.rx  
  'term.tx(CLS)

  'term.str(string("HC-8+ <--> AP-16+ Demo", CR, CR))

  'ap16_setup(SIO, 38_400)
  ap16_setup(SIO,2400)
  ap16_version(%00)

  'term.str(string("Version = "))
  'term.str(@Version)
  'term.tx(CR)
  'term.tx(CR)
  'repeat
    'term.str(string("Playing AMBIENT.WAV", CR)) 
    ap16_wav(%00, string("cadence"), 1)
    'waitcnt(clkfreq*10+cnt)
    'term.str(string("Playing Crawling.wav",CR))
    'ap16_wav(%00,string("crawl"),1)
     
    'repeat
      'pause(100)
      'check := ap16_status(%00)
      'term.bin(check, 8)
      'term.tx(CR)
    'until ((check & $80) == $00)
   
 


con

  { ------------------------------- }
  {                                 }
  {  A P - 1 6 +   R O U T I N E S  } 
  {                                 }
  { ------------------------------- }


pub ap16_setup(pin, baud)

'' Start audio serial driver on pin at baud (half-duplex true mode)

  audio.init(pin,pin,baud)'audio.start(pin, pin, %1100, baud)
  pause(10)
  'audio.rxflush


pub ap16_version(addr) | idx

'' Returns version string from AP-16+ at addr

  audio.str(string("!AP16"))
  audio.tx(byte[%00])'(addr)
  audio.tx("V")
  'audio.rxflush

  repeat idx from 0 to 2
    byte[@Version][idx] := audio.rx'audio.rxtime(25)


pub ap16_status(addr)

'' Returns AP-16+ status byte

  audio.str(string("!AP16"))
  audio.tx(addr)
  audio.tx("G")
  'audio.rxflush

  return audio.rx'audio.rxtime(25)


pub ap16_playing(addr) | status

'' Returns playing status from AP-16+ at addr

  return ((ap16_status(addr) & %1000_0000) > 0)
    
    
pub ap16_sfx(addr, sfx, rpts)

'' Plays SFX file on AP-16+ at addr

  audio.str(string("!AP16"))
  audio.tx(addr)
  audio.str(string("PS"))
  audio.tx(sfx)
  audio.tx(rpts)   


pub ap16_aux(addr, aux, rpts)

'' Plays AUX file on AP-16+ at addr

  audio.str(string("!AP16"))
  audio.tx(addr)
  audio.str(string("PA"))
  audio.tx(aux)
  audio.tx(rpts)


pub ap16_wav(addr, spntr, rpts)

'' Plays WAV file (name at spntr) on AP-16+ at addr

  audio.str(string("!AP16"))
  audio.tx(addr)
  audio.str(string("PW"))
  audio.str(spntr)
  audio.tx(13)      
  audio.tx(rpts)
   

pub ap16_stop(addr)

'' Stops AP-16+ at addr

  audio.str(string("!AP16"))
  audio.tx(addr)
  audio.tx("X")  

      
con

  { --------------------------------- }
  {                                   }
  {  S U P P O R T   R O U T I N E S  } 
  {                                   }
  { --------------------------------- }


var

  long  lastscan                                                ' ttl/DMX input scan


pub setup_io

'' Configure for basic IO control

  outa[OUT7..OUT0] := %0000_0000                                ' clear outputs
  dira[OUT7..OUT0] := %1111_1111                                ' output mode                                  
  low(OUT_EN)                                                   ' enable 74x245 

  high(LD_165)                                                  ' setup x165 io pins
  low(CLK_165)
  input(DO_165)
  
  set_rs485(NOCON)                                              ' RS-485 off


pub pause(ms) | t

'' Delay program in milliseconds

  if (ms < 1)                                                   ' delay must be at least 1
    return
  else
    t := cnt - 1792                                             ' sync with system counter
    repeat ms                                                   ' run delay
      waitcnt(t += MS_001)


pub high(pin)

'' Makes pin output and high

  outa[pin] := 1
  dira[pin] := 1


pub low(pin)

'' Makes pin output and low

  outa[pin] := 0
  dira[pin] := 1


pub toggle(pin)

'' Toggles output pin

  !outa[pin]                                                    ' invert state
  dira[pin] := 1  
  

pub input(pin)

  dira[pin] := 0

  return ina[pin]


pub ttl_pin | btns

'' Reads TTL header for 1-of-8 input
'' -- returns -1 (no input)
'' -- returns 0 to 7 for input on IN0 to IN7
''    * only one input allowed

  btns := ttl_inputs(true)                                      ' read ttl inputs

  if (bit_count(btns) == 1)                                     ' only one button pressed?
    return bit_pos(btns, 0)                                     '  yes, return button #
  else
    return -1                                                   '  none or bad input


pub ttl_inputs(rescan) 

'' Return TTL inputs status
'' -- updates global var "lastscan" if rescan is true

  if (rescan)
    lastscan := x165_in(16, MSBFIRST) | (ina[DMX_A8] << 16)     ' read in0..in7, dmx addresss
   
  return (lastscan & $FF)                                       ' return TTL input bits


pub dmx_address(rescan) 

'' Return DMX address switch setting
'' -- updates global var "lastscan" if rescan is true

  if (rescan)
    lastscan := x165_in(16, MSBFIRST) | (ina[DMX_A8] << 16)     ' read in0..in7, dmx addresss

  return (lastscan >> 8) & $01FF                                ' return DMX address bits
 

pub x165_in(bits, mode) | tmp165

'' Input value from 74x165(s)      
                                                                                          
  outa[LD_165] := 0                                             ' blip Shift/Load line    
  outa[LD_165] := 1                                                                         
                                                                                          
  tmp165 := 0                                                   ' clear workspace
  bits := 1 #> bits <# 32                                       ' limit to legal value         
  repeat bits                                                   ' read n bits         
    tmp165 := (tmp165 << 1) | ina[DO_165]                       ' get new bit             
    outa[CLK_165] := 1                                          ' blip clock              
    outa[CLK_165] := 0  

  if (mode == LSBFIRST)                                         ' LSBFIRST result?
    tmp165 ><= bits                                             ' reverse bits
   
  return tmp165
  

pub option_inputs

'' Returns state of option switch bits (%0000..%1111, all off to all on)

  dira[OPT_BR..OPT_SM] := %0000                                 ' force to input mode

  return !ina[OPT_BR..OPT_SM]                                   ' return state (1 = on)


pub set_rgled(state)

'' Sets R/G LED
'' -- direct control only
'' -- for red/green/yellow use "efx_rgled" driver and methods

  case state
    OFF : outa[R_LED..G_LED] := %00
    RED : outa[R_LED..G_LED] := %10
    GRN : outa[R_LED..G_LED] := %01
    YEL : outa[R_LED..G_LED] := %00                             ' yellow requires PASM driver

  dira[R_LED..G_LED] := %11
      

pub set_rs485(state)

'' Sets RS-485 RX and TX enable inputs

  case state
    NOCON : outa[RX2_EN..TX2_EN] := %10
    RX    : outa[RX2_EN..TX2_EN] := %00 
    TX    : outa[RX2_EN..TX2_EN] := %11   
    RXTX  : outa[RX2_EN..TX2_EN] := %01

  dira[RX2_EN..TX2_EN] := %11


pub bit_count(value) | bc

'' Returns # of bits set (1) in value

  bc := 0                                                       ' clear count
  repeat 32                                                     ' test all bits
    bc += (value & %1)                                          ' add bit value to count
    value >>= 1                                                 ' next bit

  return bc


pub bit_pos(value, mode)

'' Returns position of 1st bit set (0..31)
'' -- mode 0 to scan from lsb, mode 1 to scan from msb 
'' -- -1 = no bits set

  if (value == 0)                                               ' if no bits                                   
    return -1                                                   '  return -1

  else
    if (mode == 0)                                              ' check from LSB
      value ><= 32                                              '  flip for >|
      return (32 - >|value)
    else
      return (>|value - 1)


pub bit_val(value, pos)

'' Returns bit (0..1) from pos (0..31) in value 

  if ((pos => 0) and (pos =< 31))
    return (value >> pos) & 1
  else
    return 0

    
dat

{{

  Terms of Use: MIT License

  Permission is hereby granted, free of charge, to any person obtaining a copy of this
  software and associated documentation files (the "Software"), to deal in the Software
  without restriction, including without limitation the rights to use, copy, modify,
  merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to the following
  conditions:

  The above copyright notice and this permission notice shall be included in all copies
  or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
  PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
  OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 

}}      