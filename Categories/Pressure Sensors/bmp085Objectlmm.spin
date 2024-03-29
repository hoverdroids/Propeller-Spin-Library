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
┌──────────────────────────────────────────┐
│ BMP085 Driver 1.0                        │
│ Author: Tim Moore                        │               
│ Copyright (c) May 2010 Tim Moore         │               
│ See end of file for terms of use.        │                
└──────────────────────────────────────────┘

  I2C addresses is %1110_1110

  breakout board availble (http://www.sparkfun.com/commerce/product_info.php?products_id=9694)

  Note: GetPressureTemp and GetPressureTempA are only usable from a single Cog. Calling from multiple Cogs will confuse the state machine
}}

OBJ
  uarts       : "pcFullDuplexSerial4FC"                 '1 COG for 4 serial ports

  i2cObject   : "basic_i2c_driver"                      '0 Cog
  umath :       "umath"                                 '0 Cog

#ifdef LMM
  lmm         : "SpinLMM"

  i2clmm      : "i2clmm"                                '0 Cog
#endif

VAR
  long i2ctable
  long ac1, ac2, ac3, ac4, ac5, ac6, b1, b2, mb, mc, md 'see the datasheet for what these mean
  long state, time, temput
  long delaysl[4]

PUB Init(i2cSCL, _deviceAddress) | ptr, i, t
''initializes BMP085
''reads in sensor coefficients etc. from eeprom
'
  state := 0
  delaysl[0] := clkfreq/222                                                     '4.5ms
  delaysl[1] := clkfreq/133                                                     '7.5ms
  delaysl[2] := clkfreq/74                                                      '13.5ms
  delaysl[3] := clkfreq/39                                                      '25.5ms

#ifdef LMM
  i2ctable := i2clmm.GetOffsets
#endif

  result := true
  'read all the coefficient and sensor values from eeprom
  ptr := @ac1
  repeat i from $AA to $BE step 2
    t := i2cObject.readLocation16(i2cSCL, _deviceAddress, i)
    if t == 0 OR t == $ffff
      result := false
    if i < $B0 OR i > $B4                                                       'sign extend correctly, note ac4, ac5, ac6 are not sign extended
      ~~t
    long[ptr] := t
    ptr += 4

PUB GetPressureTemp(i2cSCL, _deviceAddress, mode, TempPtr, PressurePtr)
' Temp in 0.1°C
' Pressure in Pa
'
  repeat until result == true
    if (result := GetPressureTempA(i2cSCL, _deviceAddress, mode, TempPtr, PressurePtr)) == false
      waitcnt(delaysl[mode&3] + cnt)                                            '4.5ms/7.5/13.5/25.5

PRI Convert(ut, up, mode, TempPtr, PressurePtr) | x1, x2, b5, b6, x3, b3, p, b4, th
''
  x1 := ((ut - ac6) * ac5) ~> 15
  x2 := (mc << 11) / (x1 + md)
  b5 := x1 + x2
  long[TempPtr] := (b5 + 8) ~> 4

  b6 := b5 - 4000
  x1 := (b2 * ((b6 * b6) ~> 12)) ~> 11
  x2 := (ac2 * b6) ~> 11
  x3 := x1 + x2
  b3 := ((((ac1 << 2) + x3) << mode) + 2) ~> 2

  x1 := (ac3 * b6) ~> 13
  x2 := (b1 * ((b6 * b6) ~> 12)) ~> 16
  x3 := ((x1 + x2) + 2) ~> 2

  'b4 := (ac4 * (x3 + 32768)) >> 15                                             'unsigned 32 bit multiple
  b4 := umath.multdiv(ac4, (x3 + 32768), 32768)

  'b7 := (up - b3) * (50000 >> mode)                                            'unsigned 32 bit multiple
  'if b7 & $80000000
  '  p := (b7 / b4) << 1
  'else
  '  p := (b7 * 2) / b4
  p := umath.multdiv((up - b3), (100000 >> mode), b4)

  th := p ~> 8
  x1 := th * th
  x1 := (x1 * 3038) ~> 16
  x2 := (-7357 * p) ~> 16
  long[PressurePtr] := p + ((x1 + x2 + 3791) ~> 4)

#ifndef LMM
PUB GetPressureTempA(i2cSCL, _deviceAddress, mode, TempPtr, PressurePtr) | up
' mode is oversampling setting
'   0 - 1 sample every 4.5ms
'   1 - 2 samples every 7.5ms
'   2 - 4 samples every 13.5ms
'   3 - 8 samples every 25.5ms
' Temp in 0.1°C
' Pressure in Pa
'
  mode &= 3                                                                     'make sure 0-3
  case state
    0:
      i2cObject.WriteLocation(i2cSCL, _deviceAddress, $f4, $2e)                 'request for temp
      time := cnt
      state++
    1:
      if (cnt-time) > delaysl[0]                                                '4.5ms
        temput := i2cObject.readLocation16(i2cSCL, _deviceAddress, $F6)

        i2cObject.WriteLocation(i2cSCL, _deviceAddress, $f4, $34|(mode<<6))     'request for pressure
        time := cnt
        state++

    2:
      if (cnt-time) > delaysl[mode]                                             '4.5ms/7.5/13.5/25.5
        up := i2cObject.readLocation24(i2cSCL, _deviceAddress, $F6)
        up >>= (8 - mode)
        state := 0
        Convert(temput, up, mode, TempPtr, PressurePtr)
        result := true

#else
PUB GetPressureTempA(i2cSCL, _deviceAddress, mode, TempPtr, PressurePtr) | up, temp
' mode is oversampling setting
'   0 - 1 sample every 4.5ms
'   1 - 2 samples every 7.5ms
'   2 - 4 samples every 13.5ms
'   3 - 8 samples every 25.5ms
' Temp in 0.1°C
' Pressure in Pa
'
  mode &= 3                                                                     'make sure 0-3
  case state
    0:
              '   _deviceAddress    i2cscl   i2ctable           pasm address
      up := bytecode($68,             $64,   $40,        $C7 , @lmmgetdata1,    $3c)

      if up == 0                                                                'error occured, restart operation
        time := cnt
        state++
#ifdef I2CDEBUG
      else
        uarts.str(0, string("P0 "))
        uarts.hex(0, up, 8)
        uarts.tx(0, 13)
#endif
    1:
      if (cnt-time) > delaysl[0]                                                '4.5ms
        temp := $34|(mode<<6)

                     '    temp  _deviceAddress    i2cscl   i2ctable                    pasm address
        temput := bytecode($7C,       $68,          $64,   $40,         $C7 , $80|(@lmmgetdata2>>8), @lmmgetdata2,    $3c)

        if temput & $FFFF0000
#ifdef I2CDEBUG
          uarts.str(0, string("P1 "))
          uarts.hex(0, temput, 8)
          uarts.tx(0, 13)
#endif
          state := 0                                                            'error occured, restart operation
        else
          time := cnt
          state++

    2:
      if (cnt-time) > delaysl[mode]                                             '4.5ms/7.5/13.5/25.5
                    ' _deviceAddress   i2cscl  i2ctable             pasm address
        up := bytecode($68,             $64,   $40,        $C7 , $80|(@lmmgetdata3>>8), @lmmgetdata3,    $3c)

        if up & $FF000000
#ifdef I2CDEBUG
          uarts.str(0, string("P2 "))
          uarts.hex(0, up, 8)
          uarts.tx(0, 13)
#endif
          state := 0                                                            'error occured, restart operation
        else
          up >>= (8 - mode)
          state := 0
          Convert(temput, up, mode, TempPtr, PressurePtr)
          result := true

DAT
                        org 0
'stack contains
'  i2cscl
'  _deviceAddress
'  @lx

' request for temp
'  i2cObject.WriteLocation(i2cSCL, _deviceAddress, $f4, $2e)
'
lmmgetdata1             sub     lmm#dcurr,#4
                        rdlong  lmm#reg7,lmm#dcurr      'i2ctable

                        jmp     #lmm#icall              'i2c setup
                        long    I2CLMM#SETUP

                        mov     lmm#reg14, #0           'init ack status
                        mov     lmm#reg11, lmm#a        'i2c address
                        jmp     #lmm#icall
                        long    I2CLMM#WRITEADDR

                        rdlong  lmm#reg11, lmm#lmm_pc
                        long    $00002ef4               'write $2e to reg $f4
                        mov     lmm#reg15, #%110        'write 2 byts followed by stop
                        jmp     #lmm#icall
                        long    I2CLMM#WRITEMBYTE

                        mov     lmm#x, lmm#reg14        'push status and acks
                        jmp     #lmm#fretx              'return back to interpreter after pushing x

DAT
                        org 0
' read temp
' request for pressure
'  temput := i2cObject.readLocation16(i2cSCL, _deviceAddress, $F6)
'  i2cObject.WriteLocation(i2cSCL, _deviceAddress, $f4, $34|(mode<<6))
'
lmmgetdata2             sub     lmm#dcurr,#4
                        rdlong  lmm#reg7,lmm#dcurr      'i2ctable

                        jmp     #lmm#icall              'i2c setup
                        long    I2CLMM#SETUP

                        sub     lmm#dcurr,#4
                        rdlong  lmm#reg18,lmm#dcurr     'temp

                        mov     lmm#reg15, #$f6
                        jmp     #lmm#icall
                        long    I2CLMM#READREGHEADER
                        mov     lmm#reg16, lmm#reg14    'save ack bits

                        mov     lmm#reg14, #%10         'read with ACK, NAK 2th read
                        jmp     #lmm#icall
                        long    I2CLMM#READWORDR
                        shl     lmm#reg17, #16          'remove sign extension
                        shr     lmm#reg17, #16

                        mov     lmm#reg14, lmm#reg16    'restore ack bits
                        mov     lmm#reg11, lmm#a        'i2c address
                        jmp     #lmm#icall
                        long    I2CLMM#WRITEADDR

                        mov     lmm#reg11, lmm#reg18
                        shl     lmm#reg11, #8
                        or      lmm#reg11, #$f4
                        mov     lmm#reg15, #%110        'write 2 byts followed by stop
                        jmp     #lmm#icall
                        long    I2CLMM#WRITEMBYTE

                        shl     lmm#reg14, #16
                        or      lmm#reg17, lmm#reg14

                        mov     lmm#x, lmm#reg17        'push status and acks
                        jmp     #lmm#fretx              'return back to interpreter after pushing x

DAT
                        org 0
' read pressure
'  up := i2cObject.readLocation24(i2cSCL, _deviceAddress, $F6)
'
lmmgetdata3             sub     lmm#dcurr,#4
                        rdlong  lmm#reg7,lmm#dcurr      'i2ctable

                        jmp     #lmm#icall              'i2c setup
                        long    I2CLMM#SETUP

                        mov     lmm#reg15, #$f6
                        jmp     #lmm#icall
                        long    I2CLMM#READREGHEADER
                        mov     lmm#reg16, lmm#reg14    'save ack bits

                        mov     lmm#reg14, #%100        'read with ACK, NAK 3rd read
                        jmp     #lmm#icall
                        long    I2CLMM#READ             'status

                        shl     lmm#reg11, #16
                        mov     lmm#reg15, lmm#reg11    'save and shift

                        jmp     #lmm#icall
                        long    I2CLMM#READWORDR
                        shl     lmm#reg17, #16          'remove sign extend
                        shr     lmm#reg17, #16
                        or      lmm#reg15, lmm#reg17    'merge with previous read

                        shl     lmm#reg16, #24
                        or      lmm#reg15, lmm#reg16

                        mov     lmm#x, lmm#reg15        'push status and acks
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
