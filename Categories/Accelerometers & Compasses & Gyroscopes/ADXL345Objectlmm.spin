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
│ ADXL345 Driver 1.0                       │
│ Author: Tim Moore                        │               
│ Copyright (c) 2010  Tim Moore            │               
│ See end of file for terms of use.        │                
└──────────────────────────────────────────┘

  ADXL345 I2C address is %0011_1010 or %1010_0110 

  Sparkfun do a simple breakout board for these sensor
  http://www.sparkfun.com/commerce/product_info.php?products_id=9156
}}
CON
  'All the I2C registers for the ADXL345
  ADXL345_ID                        = $00
  ADXL345_BW_RATE                   = $2C
  ADXL345_POWER_CTL                 = $2D
  ADXL345_DATA_FORMAT               = $31
  ADXL345_OUTX_L                    = $32
  ADXL345_OUTX                      = $33
  ADXL345_OUTY_L                    = $34
  ADXL345_OUTY                      = $35
  ADXL345_OUTZ_L                    = $36
  ADXL345_OUTZ                      = $37
  ADXL345_FIFO_CTL                  = $38
  
OBJ
  uarts       : "pcFullDuplexSerial4FC"                 '1 COG for 4 serial ports

  i2cObject   : "basic_i2c_driver"

#ifdef LMM
  lmm         : "SpinLMM"

  i2clmm      : "i2clmm"                                '0 Cog
#endif

VAR
  long  i2ctable

PUB Init(i2cSCL, _deviceAddress)
''Starts sensor, sets range, etc
'
#ifdef LMM
  i2ctable := i2clmm.GetOffsets
#endif

  if i2cObject.ReadLocation(i2cSCL, _deviceAddress, ADXL345_ID) == %1110_0101
    i2cObject.WriteLocation(i2cSCL, _deviceAddress, ADXL345_POWER_CTL, %0000_0000)   'Standby mode
    i2cObject.WriteLocation(i2cSCL, _deviceAddress, ADXL345_POWER_CTL, %0000_1000)   'Measurement mode
    SetRange(i2cSCL, _deviceAddress, 16)
    i2cObject.WriteLocation(i2cSCL, _deviceAddress, ADXL345_BW_RATE, %0000_1010)     '100Hz
    i2cObject.WriteLocation(i2cSCL, _deviceAddress, ADXL345_POWER_CTL, %0000_1000)
    i2cObject.WriteLocation(i2cSCL, _deviceAddress, ADXL345_FIFO_CTL, %0000_0000)    'bypass mode
    result := true

PUB SetRange(i2cSCL, _deviceAddress, range) | ctrl
''Sets range to ±2G, ±4G, ±8G or ±16G
'
  case range
    2: ctrl := %00
    4: ctrl := %01
    8: ctrl := %10
    16: ctrl := %11
    other: ctrl := %00
  i2cObject.WriteLocation(i2cSCL, _deviceAddress, ADXL345_DATA_FORMAT, ctrl | %0000_1000) 'Full res
  
#ifndef LMM
PUB GetAcceleration(i2cSCL, _deviceAddress, XPtr, YPtr, ZPtr)
''get x, y, z acceleration
'
  i2cObject.start(i2cSCL)
  i2cObject.write(i2cSCL,_deviceAddress | 0)
  i2cObject.write(i2cSCL,ADXL345_OUTX_L)
  i2cObject.restart(i2cSCL)
  i2cObject.write(i2cSCL,_deviceAddress | 1)
  LONG[XPtr] := Read16(i2cSCL)
  LONG[YPtr] := Read16(i2cSCL)
  result := i2cObject.read(i2cSCL,I2COBJECT#ACK) & $ff
  result |= (i2cObject.read(i2cSCL,I2COBJECT#NAK) << 8)
  LONG[ZPtr] := ~~result
  i2cObject.stop(i2cSCL)
  result := true

PRI Read16(i2cSCL)
''
  result := i2cObject.read(i2cSCL,I2COBJECT#ACK) & $ff
  result |= (i2cObject.read(i2cSCL,I2COBJECT#ACK) << 8)
  result := ~~result

#else
PUB GetAcceleration(i2cSCL, _deviceAddress, XPtr, YPtr, ZPtr) | xl, yl, zl
''get x, y, z acceleration
'
                '    @xl   _deviceAddress    i2cscl  i2ctable          pasm address
  result := bytecode($7B,    $68,             $64,   $40,        $C7 , @lmmgetdata,    $3c)

  if result == 0
    long[xptr] := xl
    long[yptr] := yl
    long[zptr] := zl
    result := true
  else
#ifdef I2CDEBUG
    uarts.str(0, string("Acc "))
    uarts.hex(0, result, 8)
    uarts.tx(0, 13)
#endif
    result := false

DAT
                        org 0

'stack contains
'  i2ctable
'  i2cscl
'  _deviceAddress
'  @lx

lmmgetdata              sub     lmm#dcurr,#4
                        rdlong  lmm#reg7,lmm#dcurr     'i2ctable

                        jmp     #lmm#icall             'i2c start
                        long    I2CLMM#SETUP

                        sub     lmm#dcurr,#4
                        rdlong  lmm#reg18,lmm#dcurr     '@lx

                        mov     lmm#reg14, #0           'init ack status
                        mov     lmm#reg15, #ADXL345_OUTX_L   '
                        jmp     #lmm#icall
                        long    I2CLMM#READREGHEADER
                        mov     lmm#reg19, lmm#reg14    'save acks

                        mov     lmm#reg14, #%100000     'read with ACK, NAK 6th read
                        jmp     #lmm#icall
                        long    I2CLMM#READWORD
                        mov     lmm#reg15, lmm#reg17

                        jmp     #lmm#icall
                        long    I2CLMM#READWORD
                        mov     lmm#reg16, lmm#reg17    'save

                        jmp     #lmm#icall
                        long    I2CLMM#READWORD         'last read will be NAK and i2cstop

                        cmp     lmm#reg19, #0       wz  'all writes acked

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
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}
