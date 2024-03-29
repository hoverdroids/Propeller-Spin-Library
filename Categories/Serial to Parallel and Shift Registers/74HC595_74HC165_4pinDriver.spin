{{
OBEX LISTING:
  http://obex.parallax.com/object/441

  Control the Parallax Digital I/O Board via (SPI) serial connection with just 4 pins.
  Allows reading inputs and controlling relays using 1 cog. Controls the 74HC595 and 74HC165 IC

  Was DigitalIO4pinDriver.spin
}}
{{
**********************************************
*  Parallax DIGITAL I/O BOARD 4pin Driver    *
*  Author: Adrian Schwartzmann               *
*                                            *
*   See end of file for terms of use.        *
*                                            *
* This will let you control the              *
* Digital I/O board with just 4 pins.        *
**********************************************

This was made to control the Parallax Digital I/O Board Kit
It controls the HC165 and HC595 shift registers via serial conection sharing the I/O and Clock pins
The 4 pins used are for Clock, I/O, Enable HC165 and Enable HC595 

Pin Out
________________________________
VDD                 to  3.3v
DIN & DATA_RLY      to  PIN_DataIO
SCLK_IN & SCLK_RLY  to  PIN_Clock
LOAD_IN             to  PIN_HC165
LAT_RLY             to  PIN_HC595
VSS                 to  Ground
/OE_RLY             to  Ground

}}
CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

VAR
  long stack[32] 
  long cog
  byte temp
  byte temp1
  
  long IN_Values_Address
  long OUT_Values_Address
  
PUB start(PIN_DataIO, PIN_Clock, PIN_HC595, PIN_HC165, IN_Values, OUT_Values)
  IN_Values_Address := IN_Values
  OUT_Values_Address := OUT_Values
  if cog~
    cogstop(cog)
  cog := cognew(main(PIN_DataIO, PIN_Clock, PIN_HC595, PIN_HC165, IN_Values_Address, OUT_Values_Address),@stack)


PUB in(pin) | value    'Get the Value of one of the Inputes in(0) will get you the value of IN1
  return (byte[IN_Values_Address] &|< pin)>>pin

PUB out(pin, value)     'Turn the Relays on and Off. out(0,1) turns relay 1 on out(0,0) turns relay 1 off        
  if value
     byte[OUT_Values_Address]|=|<pin    
  else
     byte[OUT_Values_Address]&=!|<pin
  
  

PRI main(PIN_DataIO, PIN_Clock, PIN_HC595, PIN_HC165, IN_Address, OUT_Address)
  'Setup IO Pins
  DIRA[PIN_Clock]   :=1
  DIRA[PIN_HC165]   :=1
  DIRA[PIN_HC595]   :=1

  OUTA[PIN_Clock]   :=0
  OUTA[PIN_HC595]   :=0
  OUTA[PIN_HC165]   :=0

  temp:=%00000000
  
  REPEAT 
'Read Values from HC165 chip
    DIRA[PIN_DataIO]  :=0
    clock(PIN_Clock)
    OUTA[PIN_HC165]   :=1     'Setting this high will put the first value in the HC165 shit register on DataIO pin
    REPEAT 8
      temp:=temp<<1             'shift the bits in temp to the left by 1
      temp|=inA[PIN_DataIO]     'get the value of the DataIO pin and assign it to the first bit in temp
      clock(PIN_Clock)          'send clock pluse, the next value in the shift register of the HC165 will be outputed on the DataIO pin
    OUTA[PIN_HC165]   :=0
    BYTE[IN_Address]:=temp
    
'Write Values to HC595 chip
    DIRA[PIN_DataIO]  :=1
    OUTA[PIN_DataIO]  :=0
    clock(PIN_Clock)
    temp:=BYTE[OUT_Address]><8  'Get the value from the OUT_REG flip it and place it in temp
    REPEAT 8
      OUTA[PIN_DataIO]:=temp    'Set the IO pin to the value on the first bit in temp
      temp:=temp>>1             'Shift temp to the right by one
      clock(PIN_Clock)           'send a clock pluse
    OUTA[PIN_HC595]:=1          'Set the LAT_RlY to high this will cause the HC595 to read the value from the shift register
    OUTA[PIN_HC595]:=0          'Done. Ready for next write


PRI clock(PIN_Clock)
  OUTA[PIN_Clock]:=1
  OUTA[PIN_Clock]:=0
DAT
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
