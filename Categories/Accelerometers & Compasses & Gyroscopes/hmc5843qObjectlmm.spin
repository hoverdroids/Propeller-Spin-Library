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
│ HMC5843 Driver 1.2                       │
│ Author: Tim Moore                        │               
│ Copyright (c) Sept 2009 Tim Moore        │               
│ See end of file for terms of use.        │                
└──────────────────────────────────────────┘

  3-axis compass

  I2C address is %0011_1100

  Datasheet for HMC5843
  http://www.ssec.honeywell.com/magnetic/datasheets/HMC5843.pdf

  Breakout board available from Sparkfun.com
  http://www.sparkfun.com/commerce/product_info.php?products_id=9371

  Note: To get correct readings I needed to place a 100uF cap in parallel to C3 on the Sparkfun breakout board

  Fixed 3d bearing calculation (June 2010)
  Added Calibration code (June 2010)
        During initialization does a calibration and then adjusts any results using the calibration data
  Added Inline PASM GetData routine (June 2010)
}}
CON
  'I2C registers for the HMC5843
  HMC5843_CONFIG_A              = $00
  HMC5843_CONFIG_B              = $01
  HMC5843_MODE                  = $02
  HMC5843_DATA_X_MSB            = $03
  HMC5843_DATA_X_LSB            = $04
  HMC5843_DATA_Y_MSB            = $05
  HMC5843_DATA_Y_LSB            = $06
  HMC5843_DATA_Z_MSB            = $07
  HMC5843_DATA_Z_LSB            = $08
  HMC5843_STATUS                = $09
  HMC5843_ID_A                  = $0A
  HMC5843_ID_B                  = $0B
  HMC5843_ID_C                  = $0C

OBJ
  uarts         : "pcFullDuplexSerial4FC"               '1 COG for 4 serial ports

  i2cObject     : "basic_i2c_driver"                    '0 COG

  trig          : "imumathq"                            '0 Cog

#ifdef LMM
  lmm           : "SpinLMM"                             '0 Cog

  i2clmm        : "i2clmm"                              '0 Cog
#endif

VAR
  long i2ctable                                         'this needs to be 1st
  long oldX, oldY, oldZ, first, FourFive                'filtered x,y,z
  long nocal, gx, gy, gz, xo, yo, zo                    'gains x,y,z; offsets x,y,z

PUB Init(i2cSCL, _deviceAddress, _FourFive)
'' Checks for a HMC5843 and intializes it
'' returns true if found else false
#ifdef LMM
  i2ctable := i2clmm.GetOffsets
#endif

  FourFive := _FourFive
  result := true
  i2cObject.start(i2cSCL)
  i2cObject.write(i2cSCL,_deviceAddress | 0)
  i2cObject.write(i2cSCL,HMC5843_ID_A)
  i2cObject.restart(i2cSCL)
  i2cObject.write(i2cSCL,_deviceAddress | 1)
  if i2cObject.read(i2cSCL,i2cObject#ACK) <> "H"
    result := false
  if i2cObject.read(i2cSCL,i2cObject#ACK) <> "4"
    result := false
  if i2cObject.read(i2cSCL,i2cObject#NAK) <> "3"
    result := false
  i2cObject.stop(i2cSCL)

  byte[@configs] := byte[@configm] := _deviceAddress

  if result == true
    result := Idle(i2cSCL)
  if result == true
    result := Config(i2cSCL, 0, 0)

  if result == true                                                             'init the filter values
    first := true
    result := GetData(i2cSCL, _deviceAddress, @oldX, @oldY, @oldZ)              'force a read even if status is wrong - sometimes needed to reset status
    if result == false
      result := GetData(i2cSCL, _deviceAddress, @oldX, @oldY, @oldZ)

  if result == true
    first := true
    DoCalibration(i2cSCL, _deviceAddress)                                       'now calibrate the compass
    result := nocal
    if result == true
{
      uarts.str(0, string("HMC5843 Calibration data: "))
      uarts.dec(0, gx)
      uarts.tx(0, " ")
      uarts.dec(0, gy)
      uarts.tx(0, " ")
      uarts.dec(0, gz)
      uarts.tx(0, " ")
      uarts.dec(0, xo)
      uarts.tx(0, " ")
      uarts.dec(0, yo)
      uarts.tx(0, " ")
      uarts.dec(0, zo)
      uarts.tx(0, 13)
}
      result := Config(i2cSCL, 0, 0)                            'continous/no strap
  first := false

PRI Config(i2cSCL, strap, one)
''
'
  byte[@configm+2] := $18 | strap
  byte[@configm+4] := $00 | one
  result := Write(i2cSCL, @configm, 5)
  waitcnt(clkfreq/100 + cnt)

PRI Idle(i2cSCL)
''
'
  result := Write(i2cSCL, @configs, 3)
  waitcnt(clkfreq/100 + cnt)

PRI Write(i2cSCL, Ptr, N) : resp | i
''
'
  i2cObject.start(i2CSCL)
  repeat i from 0 to N-1
    resp |= i2cObject.write(i2cSCL,byte[Ptr+i])
  i2cObject.stop(i2cSCL)
  return resp==0

DAT
configm byte  0, HMC5843_CONFIG_A, $18, $00, $00
configs byte  0, HMC5843_MODE, $02

PRI PartCalibration(i2cSCL, _deviceAddress, direction) | resp, cx, cy, cz
''
'' Enable HMC5843 calibration mode, either +ve or -ve and get the values
'
  nocal := 0
  Idle(i2cSCL)
  if (result := Config(i2cSCL, direction, 1)) == true
    nocal := GetData(i2cSCL, _deviceAddress, @gx, @gy, @gz)

PRI DoCalibration(i2cSCL, _deviceAddress)
''
'' Calibrates the compass - i.e. find the offset and gains of the axis
''  Get calibration reading for +ve and -ve straps and use those to estimate
''  gain and offset per axis
'
  PartCalibration(i2cSCL, _deviceAddress, 2)                                    '-ve strap calibration
  if nocal
    longmove(@xo, @gx, 3)                                                       'save the -ve calibration results
    PartCalibration(i2cSCL, _deviceAddress, 1)                                  '+ve strap calibration
    xo += gx                                                                    '2x offset is difference between +ve and -ve results
    yo += gy
    zo += gz
    xo ~>= 1                                                                    '1/2 the difference is the offset
    yo ~>= 1
    zo ~>= 1
    gx -= xo                                                                    'remove offset from +ve and thats the gain
    gy -= yo
    gz -= zo
  return @nocal

PRI Read16(i2cSCL)
  result := (i2cObject.read(i2cSCL,i2cObject#ACK) << 8) | (i2cObject.readns(i2cSCL,i2cObject#ACK) & $ff)
  ~~result

PRI GetI2CData(i2cSCL, _deviceAddress, XPtr, YPtr, ZPtr) | s

  i2cObject.start(i2cSCL)
  result |= i2cObject.write(i2cSCL,_deviceAddress | 0)
  result |= i2cObject.write(i2cSCL,HMC5843_STATUS)
  i2cObject.restart(i2cSCL)
  result |= i2cObject.write(i2cSCL,_deviceAddress | 1)
  s := i2cObject.read(i2cSCL,i2cObject#NAK)
  i2cObject.stop(i2cSCL)
  if (s =>5)                                            '5 means data available, 6/7 means read partial occurred and registers locked from updates
    i2cObject.start(i2cSCL)
    result |= i2cObject.write(i2cSCL,_deviceAddress | 1)
    long[XPtr] := Read16(i2cSCL)
    long[YPtr] := Read16(i2cSCL)
    long[ZPtr] := (i2cObject.read(i2cSCL,i2cObject#ACK) << 8) | (i2cObject.read(i2cSCL,i2cObject#NAK) & $ff)
    ~~long[ZPtr]
    i2cObject.stop(i2cSCL)
  if result == 0
    return s
  else
    return 0

PRI ProcessData(s, lx, ly, lz, XPtr, YPtr, ZPtr)

  if (s == 5)                                                                 'data available status good
    if (first == false)                                                       'do we need to filter the readings
      if (lx > -4096) AND (ly > -4096) AND (lz > -4096)                       'ADC under/overrun
        if (lx < $800) AND (ly < $800) AND (lz < $800)                        'Seem to sometimes get results that are not correct, filter out
          oldX := lx '(oldX*7 + lx) ~> 3
          oldY := ly '(oldY*7 + ly) ~> 3
          oldZ := lz '(oldZ*7 + lz) ~> 3
          if nocal <> 0
            long[XPtr] := ((oldX-xo)*891)/gx                                  '891 = 0.55*1620
            long[YPtr] := ((oldY-yo)*891)/gy
            long[ZPtr] := ((oldZ-zo)*891)/gz
          else

            long[XPtr] := oldX
            long[YPtr] := oldY
            long[ZPtr] := oldZ
        else
          result |= 1
      else
        result |= 1
    else
      if nocal <> 0
        long[XPtr] := ((lx-xo)*891)/gx                                        '891 = 0.55*1620
        long[YPtr] := ((ly-yo)*891)/gy
        long[ZPtr] := ((lz-zo)*891)/gz
      else
        long[XPtr] := lx
        long[YPtr] := ly
        long[ZPtr] := lz
  else
    result |= 1
  return result==0

#ifndef LMM
PUB GetData(i2cSCL, _deviceAddress, XPtr, YPtr, ZPtr) | s, lx, ly, lz
'' Gets X, Y, Z data from HMC5843
'' returns false if no data available
'
  s := GetI2CData(i2cSCL, _deviceAddress, @lx, @ly, @lz)
  result := ProcessData(s, lx, ly, lz, XPtr, YPtr, ZPtr)

#else
PUB GetData(i2cSCL, _deviceAddress, XPtr, YPtr, ZPtr) | s, lx, ly, lz
'' Gets X, Y, Z data from HMC5843
'' returns false if no data available
'
           '    @lx _deviceAddress    i2cscl   i2ctable          pasm address
  s := bytecode($7F,    $68,             $64,   $40,       $C7 , @lmmgetdata,    $3c)
  if s & $0ffff00
#ifdef I2CDEBUG
    uarts.str(0, string("Com "))
    uarts.hex(0, s, 8)
    uarts.tx(0, 13)
#endif
    result := false
  else
    result := ProcessData(s, lx, ly, lz, XPtr, YPtr, ZPtr)

DAT
                        org 0
'stack contains
'  i2cscl
'  _deviceAddress
'  @lx

lmmgetdata              sub     lmm#dcurr,#4
                        rdlong  lmm#reg7,lmm#dcurr      'i2ctable

                        jmp     #lmm#icall              'i2c setup
                        long    I2CLMM#SETUP

                        sub     lmm#dcurr,#4
                        rdlong  lmm#reg18,lmm#dcurr     '@lx

                        mov     lmm#reg15, #HMC5843_STATUS 'status register   '
                        jmp     #lmm#icall
                        long    I2CLMM#READREGHEADER

                        shl     lmm#reg14, #16
                        mov     lmm#reg19, lmm#reg14

                        mov     lmm#reg14, #1           'read with NAK
                        jmp     #lmm#icall
                        long    I2CLMM#READ             'status

                        jmp     #lmm#icall
                        long    I2CLMM#STOP             'i2c stop

                        cmp     lmm#reg19, #0      wz

                        or      lmm#reg19, lmm#reg11
                        cmp     lmm#reg11, #5      wc   'if < 5 then return

        if_c_or_nz      wrlong  lmm#reg19,lmm#dcurr     'push status
        if_c_or_nz      add     lmm#dcurr,#4
        if_c_or_nz      jmp     #lmm#loop               'back to interpreter

                        jmp     #lmm#icall
                        long    I2CLMM#START            'i2c start

                        mov     lmm#reg14, #0           'init ack status
                        mov     lmm#reg11, lmm#a        'i2c address with read bit set
                        or      lmm#reg11, #1
                        jmp     #lmm#icall
                        long    I2CLMM#WRITE

                        shl     lmm#reg14, #8       wz
                        or      lmm#reg19, lmm#reg14

                        mov     lmm#reg14, #%100000     'read with ACK, NAK 6th read
                        jmp     #lmm#icall
                        long    I2CLMM#READWORDR
                        mov     lmm#reg15, lmm#reg17

                        jmp     #lmm#icall
                        long    I2CLMM#READWORDR
                        mov     lmm#reg16, lmm#reg17

                        jmp     #lmm#icall
                        long    I2CLMM#READWORDR

        if_z            wrlong  lmm#reg15, lmm#reg18    'write results out to hub addresses
                        add     lmm#reg18, #4
        if_z            wrlong  lmm#reg16, lmm#reg18
                        add     lmm#reg18, #4
        if_z            wrlong  lmm#reg17, lmm#reg18

                        mov     lmm#x, lmm#reg19        'push status and acks
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
│COPYRIGHT HOLD ERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,  │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}
