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
│ Shiftin version 1.0                      │
│ Author:  Michael du Plessis              │               
│ Copyright (c)   2011  Optimho            │               
│ See end of file for terms of use.        │                
└──────────────────────────────────────────┘
This program is ideally for the Parallax DIGITAL I/O Board
 It should be able to be used with any device that makes use of the 74HC165 Parralel to Serial Register

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
 

 long INStack[32] 
 long cogon, cog
 byte bit
 byte bitr
 
obj
        
PUB start(SCLK_IN,LOAD_IN,DIN,IN_REG_Address)
  
'' Start - starts a cog
'' returns false if no cog available

''  IN_REG_Address    - this is the input register, and should be the same as the inputs applied to the IO Board
''  SCLK_IN,LOAD_IN,DIN are the CPU pins that these outputs and inputs are wired to.
''  Start - starts a cog
''  returns false if no cog available

  stop
  cogon := (cog := cognew(SHIFTin(SCLK_IN,LOAD_IN,DIN,IN_REG_Address),@INStack)) > 0     
  


PUB stop

'' Stop - frees a cog

  if cogon~
    cogstop(cog)

 
PUB SHIFTin (SCLK_IN,LOAD_IN, DIN,IN_REG_Address) 'Call Shift out to read a value into place holder 
  

  DIRA[SCLK_IN]:=%1                       ''Prepare pin to be Synchrounous clock 
  DIRA[LOAD_IN]:=%1                       ''Prepare this pin to be the Load Input pin
  DIRA[DIN]:=%0                           ''Prepare this pin to be the Data input pin
  inA[DIN]:=0                             ''Clear the DIN Register

  OUTA[LOAD_IN]:=1                        ''Instruct the  74HC165 to  read data
  CLOCK (SCLK_IN)
repeat   
   OUTA[LOAD_IN]:=0                        ''The following lines reads 8bits of data from 74HC165 into the IN_REG_Address register
   CLOCK (SCLK_IN)
   OUTA[LOAD_IN]:=1
   bitR:=bit<<8 
   REPEAT 8
     bit:=bit<<1
     bit|=inA[DIN]
     CLOCK (SCLK_IN)
     'DELAY
     
  bit:=bit    
  byte[IN_REG_Address]:=bit

      


PUB DELAY                      ''slow things down a bit if needed
'waitcnt(cnt+clkfreq/100)      '
return

PUB CLOCK (SCLK_IN)              ''Toggle the Clock line 
OUTA[SCLK_IN]:=1
'DELAY
OUTA[SCLK_IN]:=0
'DELAY
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
