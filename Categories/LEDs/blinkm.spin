{{
OBEX LISTING:
  http://obex.parallax.com/object/278

  These are I2C drivers for

  HMC5843 tri-axis compass
  ITG-3200 tri-axis gyro
  ADXL345 tri-axis accelerometer
  BMP085 pressure sensor
  BLINKM RGB led
  They use the SpinLMM object for inline PASM.
}}
{{
  ┌────────────────────────────────────────────────────────┐
  │ LED Indicator code for Quad bot framework              │
  │ Author: Tim Moore                                      │
  │ Copyright (c) June 2010 Tim Moore                      │
  │ See end of file for terms of use.                      │
  └────────────────────────────────────────────────────────┘

  Supports LED indicator API, translates to using blinkm
}}

CON
  FLASH         = 2                                     '1Hz flash
  ON            = 1
  OFF           = 0

OBJ
  i2cObject   : "basic_i2c_driver"                      '0 Cog - I2C driver

#ifdef LMM
  lmm         : "SpinLMM"                               '0 Cog

  i2clmm      : "i2clmm"                                '0 Cog
#endif

VAR
  long i2ctable
  byte red, green, blue
  byte cred, cgreen, cblue
  long flashtime

PUB Init(i2cSCL, Addr, invert)
''
#ifdef LMM
  i2ctable := i2clmm.GetOffsets
#endif

  i2cObject.start(i2cSCL)                               'start condition    send SCL pin number
  i2cObject.write(i2cSCL, Addr)                         'send address $09 plus write bit '0'
  i2cObject.write(i2cSCL, "o")                          'stop any scripts running
  i2cObject.stop(i2cSCL)                                'stop condition

  longfill(@red, OFF, 3)
  SetBlinkm(i2cSCL, Addr, 0, 0, 0)

PUB SetLED(i2cSCL, Addr, invert, No, State)
''
'' Quad led indicator
''  No which led to turn on - translates to color
''  State - on, off or flash
''  Invert is ignored
'
  case No
    0:
      if red <> State
        red := State
        cred := (State <> OFF)
        result := true
    1:
      if green <> State
        green := State
        cgreen := (State <> OFF)
        result := true
    2:
      if blue <> State
        blue := State
        cblue := (State <> OFF)
        result := true

  if result
    if (red == FLASH) OR (green == FLASH) OR (blue == FLASH)
      flashtime := cnt
    SetBlinkm(i2cSCL, Addr, cred, cgreen, cblue)

PUB Update(i2cSCL, Addr)

  if (cnt-flashtime) > clkfreq
    flashtime := cnt
    if red == FLASH
      result := true
      cred := NOT cred
    if green == FLASH
      result := true
      cgreen := NOT cgreen
    if blue == FLASH
      result := true
      cblue := NOT cblue
    if result
      SetBlinkm(i2cSCL, Addr, cred, cgreen, cblue)

#ifndef LMM
PUB SetBlinkm(i2cSCL, Addr, _red, _green, _blue)
   i2cObject.start(i2cSCL)                              'start condition    send SCL pin number
   i2cObject.write(i2cSCL, Addr)                        'send address $09 plus write bit '0'
   i2cObject.write(i2cSCL, "n")                         'set to color
   i2cObject.write(i2cSCL, _red)                        'value for red channel
   i2cObject.write(i2cSCL, _blue)                       'value for blue channel
   i2cObject.write(i2cSCL, _green)                      'value for green channel
   i2cObject.stop(i2cSCL)                               'stop condition

#else
PUB SetBlinkm(i2cSCL, Addr, _red, _green, _blue)

  result := (_green << 24) | (_blue << 16) | (_red << 8)
                '    color   Addr        i2cscl  i2ctable          pasm address
  result := bytecode($60,    $68,         $64,   $40,        $C7 , @lmmsetdata,    $3c)

DAT
                        org 0

'stack contains
'  i2ctable
'  i2cscl
'  _deviceAddress
'  _red
'  _green
'  _blue

lmmsetdata              sub     lmm#dcurr,#4
                        rdlong  lmm#reg7,lmm#dcurr      'i2ctable

                        jmp     #lmm#icall              'i2c start
                        long    I2CLMM#SETUP

                        sub     lmm#dcurr,#4
                        rdlong  lmm#reg17,lmm#dcurr     'colors

                        mov     lmm#reg14, #0           'init ack status
                        mov     lmm#reg11, lmm#a        'i2c address
                        jmp     #lmm#icall
                        long    I2CLMM#WRITEADDR

                        mov     lmm#reg11, lmm#reg17    '
                        or      lmm#reg11, #"n"
                        mov     lmm#reg15, #%11000      'write 4 bytes followed by stop
                        jmp     #lmm#icall
                        long    I2CLMM#WRITEMBYTE

                        mov     lmm#x, lmm#reg14        'push acks
                        jmp     #lmm#fretx              'return back to interpreter after pushing x
#endif
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
