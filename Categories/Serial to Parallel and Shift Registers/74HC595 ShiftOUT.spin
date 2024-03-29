{{
OBEX LISTING:
  http://obex.parallax.com/object/442

  This Program is used to shift Data in and out data of the Parallax Digital IO Board.

  The Parallax Digital I/O Board makes use of two shift registers, namely the 74HC595 (Serial to Parallel) and the 74HC165 (Parallel to Serial) Shift registers. This program starts two cogs to handle shifting-out(SHiftOUT) and shifting-in(ShiftIN) data simultaneously.This is by no means the most optimised design and uses 6 I/O pins and 2 cogs to run. But on the upside it should be fast as data can be read and written at the same time.

  Version 1.1 has a small fix to the output relays.In the previous version relay 8 would pickup if you shifted 1 into the register - now relay 1 will pick up.

  Version 2.2 edited out some delays to speed things up.Remove the edits if you want to slow things down. It is easier seeing how things work when they go slower - feel free to play.
}}
{{
                         
┌──────────────────────────────────────────┐
│ Shiftout version 1.0                     │
│ Author:  Michael du Plessis              │               
│ Copyright (c)   2011  Optimho            │               
│ See end of file for terms of use.        │                
└──────────────────────────────────────────┘
 This program is ideally for the Parallax DIGITAL I/O Board
 It should be able to be used with any device that makes use of the 74HC595 Serial to Parallel Register
Pin Definitions for 2x5 Header
__________________________________________________________________________________  
Pin      Name          Function
__________________________________________________________________________________
1        V+            Relay Power (output to host controller)
2        VDD           Logic Power (input from host controller)
3        DIN           Serial Data In from 74HC165 (output to host controller)
4        DATA_RLY      Serial Data Out to 74HC595 (input from host microcontroller)
5        SCLK_IN       Synchronous Serial Clock (input from host microcontroller)
6        SCLK_RLY      Synchronous Serial Clock (input from host microcontroller)
7        LOAD_IN       Load Inputs (input from host microcontroller)
8        LAT_RLY       Latch Relay Output (input from host microcontroller)
9        VSS Ground
10      /OE_RLY      Relay Output Enable (input from host microcontroller) Active Low



}}
CON
    _clkmode = xtal1 + pll16x
    _clkfreq = 5_000_000

VAR 
 long OutStack[60] 
 long cogon, cog
 byte counter
 byte bit
obj
  
      
PUB start(SCLK_RLY,LAT_RLY,DATA_RLY,OE_RLY,OUT_REG)

''  OUT_REG    - this is the data that is sent to the output relays   (OUT_REG = 1 will output relay 1 and 128 will output relay 8)
''  SCLK_RLY,LAT_RLY,DATA_RLY,OE_RLY are the CPU pins that these outputs and inputs are wired to.
''  Start - starts a cog
''  returns false if no cog available
''


  stop
  cogon := (cog := cognew(SHIFTout (SCLK_RLY,LAT_RLY, DATA_RLY,OE_RLY, OUT_REG) ,@OutStack)) > 0
  


PUB stop

'' Stop - frees a cog

  if cogon~
    cogstop(cog)

PUB SHIFTout (SCLK_RLY,LAT_RLY, DATA_RLY,OE_RLY,OUT_REG)        'Call SHIFTout to write a value from an Output Register

  DIRA[SCLK_RLY]:=%1                                            'SCLK_RLY synchronous serial clock.
  DIRA[LAT_RLY]:=%1                                             'LAT_RLY Latch outputs (switch outputs on)
  DIRA[DATA_RLY]:=%1                                            'DATA_RLY is an output that outputs data to 74HC595
  DIRA[OE_RLY]:=%1                                              'LAT_RLY is an output that enables the output (enable outputs)
  
  OUTA[SCLK_RLY]:=0                                             'Initialis SCLK_RLY to 0
  OUTA[LAT_RLY]:=0                                              'Initialise LAT_RLY to 0
  OUTA[DATA_RLY]:=0                                             'Initialise DATA_RLY to 0
  OUTA[OE_RLY]:=0                                               'Initialise all to 0
  
repeat
  OUTA[OE_RLY]:=0                                                
  bit:=byte [OUT_REG]                                            'Swap the most significant bit with the lowest significant
  bit:=bit >< 8                                                  'This is so that bit 1 corresponds to relay 1
                                                                 '1 = relay 1 and 128 switches on relay 8.
               
  repeat 8
                                                      'Shift data into  74HC595's 8 output buffers, one bit at a time.
    OUTA[DATA_RLY]:=bit                                         '
    bit:=bit>>1

                                                   '
    CLOCK (SCLK_RLY)                                     'toggle clock line
  OUTA[LAT_RLY]:=1                                       'Latch Data into output buffer rising edge
  ''waitcnt(cnt+clkfreq/1)                               'Latch pulse delay - Include this line to slow things down 
  OUTA[LAT_RLY]:=0                                       'Latch Data into output buffer lower edge, relay should operate relays

PUB DELAY                      'slow things down a bit
''waitcnt(cnt+clkfreq/1)     '
return

PUB CLOCK (SCLK_IN)              'Toggle the Clock line 
OUTA[SCLK_IN]:=1 '1
''DELAY
OUTA[SCLK_IN]:=0
''DELAY
return


DAT
     {<end of object code>}
     
{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}  
