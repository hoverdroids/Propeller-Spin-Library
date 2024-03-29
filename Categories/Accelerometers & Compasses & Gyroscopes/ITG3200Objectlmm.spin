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
│ ITG3200 Driver 1.1                       │
│ Author: Tim Moore                        │               
│ Copyright (c) May 2010  Tim Moore        │               
│ See end of file for terms of use.        │                
└──────────────────────────────────────────┘

  Increased filtering for QuadCopter
        set to ~500samples per sec with 98Hz low pass filter

  ITG3200 I2C address is %1101_0000 or %1101_0010 

  Added Inline PASM GetData routine (June 2010)
}}
CON
  'All the I2C registers for the ITG-3200
  ITG3200_WHO_AM_I                  = $00
  ITG3200_SMPLRT_DIV                = $15
  ITG3200_DLPF_FS                   = $16
  ITG3200_INT_CFG                   = $17
  ITG3200_INT_STATUS                = $1A
  ITG3200_TEMP_OUT_H                = $1B
  ITG3200_TEMP_OUT_L                = $1C
  ITG3200_GYRO_XOUT_H               = $1D
  ITG3200_GYRO_XOUT_L               = $1E
  ITG3200_GYRO_YOUT_H               = $1F
  ITG3200_GYRO_YOUT_L               = $20
  ITG3200_GYRO_ZOUT_H               = $21
  ITG3200_GYRO_ZOUT_L               = $22
  ITG3200_PWR_MGM                   = $3E      
  
OBJ
  uarts       : "pcFullDuplexSerial4FC"                 '1 COG for 4 serial ports

  i2cObject   : "basic_i2c_driver"                      '0 Cog

#ifdef LMM
  lmm         : "SpinLMM"

  i2clmm      : "i2clmm"                                '0 Cog
#endif

VAR
  long i2ctable                                         'pointer to i2c lmm jump table
  long zx, zy, zz

PUB Init(i2cSCL, _deviceAddress)
''Starts sensor, sets range, etc
'
#ifdef LMM
  i2ctable := i2clmm.GetOffsets                                                                          'get lmm i2c jump table
#endif

  zx := zy := zz := 0
  i2cObject.WriteLocation(i2cSCL, _deviceAddress, ITG3200_PWR_MGM, %1000_0000)                           'reset to defaults
  waitcnt(clkfreq/20 + cnt)                                                                              '50ms
  i2cObject.WriteLocation(i2cSCL, _deviceAddress, ITG3200_DLPF_FS, %0001_1010)                           '2000/sec, 1Khz, 98Hz low pass
  i2cObject.WriteLocation(i2cSCL, _deviceAddress, ITG3200_SMPLRT_DIV, %0000_0011)                        '4 samples per sample
  i2cObject.WriteLocation(i2cSCL, _deviceAddress, ITG3200_PWR_MGM, %0000_0001)                           'PLL with X Gyro reference
  i2cObject.WriteLocation(i2cSCL, _deviceAddress, ITG3200_INT_CFG, %0000_0001)                           'Enable data ready status
  i2cObject.readLocation(i2cSCL, _deviceAddress, ITG3200_INT_STATUS)                                     'reset data ready
  if ((GetID(i2cSCL, _deviceAddress)<<1)&$FC) == (_deviceAddress & $FC)                                  'check device id
    result := true

PUB SetZero(i2cSCL, _deviceAddress) | xl, yl, zl, t, xt, yt, zt
'' calculate current device values as a zero point on the device
'
  longfill(@xt, 0, 3)
  longfill(@zx, 0, 3)
  repeat 100
    repeat 100
      if GetGyro(i2cSCL, _deviceAddress, @xl, @yl, @zl, @t) <> 0                                        'wait until new reading
        quit
      waitcnt(clkfreq/300 + cnt)                                                                        '3.3ms
    xt += xl
    yt += yl
    zt += zl
    waitcnt(clkfreq/300 + cnt)                                                                          '3.3ms
  xt /= 100
  yt /= 100
  zt /= 100
  longmove(@zx, @xt, 3)                                                                                 'save initial zero values
  
PUB GetID(i2cSCL, _deviceAddress)
' contains %110_100 in bits 6-1, i.e. I2C address >> 1
'
  result := i2cObject.readLocation(i2cSCL, _deviceAddress, ITG3200_WHO_AM_I)

#ifndef LMM
PUB GetGyro(i2cSCL, _deviceAddress, XPtr, YPtr, ZPtr, TempPtr) | status, t
''get x, y, z, temp acceleration
'
  i2cObject.start(i2cSCL)
  i2cObject.write(i2cSCL,_deviceAddress | 0)
  i2cObject.write(i2cSCL,ITG3200_INT_STATUS)
  i2cObject.restart(i2cSCL)
  i2cObject.write(i2cSCL,_deviceAddress | 1)  
  if (status := i2cObject.read(i2cSCL,I2COBJECT#ACK)) & 1
    LONG[TempPtr] := Read16(i2cSCL) + 23000                                                             '35*280 + 13200
    LONG[XPtr] := Read16(i2cSCL) - zx                                                                   'subtract zero values
    LONG[YPtr] := Read16(i2cSCL) - zy                                                                   'subtract zero values
    t := i2cObject.read(i2cSCL,I2COBJECT#ACK) << 8
    t |= (i2cObject.read(i2cSCL,I2COBJECT#NAK) & $ff)
    LONG[ZPtr] := ~~t - zz                                                                              'subtract zero values
    result := status
  else
    i2cObject.read(i2cSCL,I2COBJECT#NAK)
  i2cObject.stop(i2cSCL)
  result := true

PRI Read16(i2cSCL)
''
  result := i2cObject.read(i2cSCL,I2COBJECT#ACK) << 8
  result |= (i2cObject.read(i2cSCL,I2COBJECT#ACK) & $ff)
  'sign extend values
  ~~result

#else
PUB GetGyro(i2cSCL, _deviceAddress, XPtr, YPtr, ZPtr, TempPtr) | tl, xl, yl, zl
''get x, y, z, temp acceleration
'
                '    @tl   _deviceAddress    i2cscl   i2ctable         pasm address
  result := bytecode($7F,    $68,             $64,     $40,     $C7 , @lmmgetdata,    $3c)

  if (result & $FE) <> 0                                'gyro sometimes hangs - reset it
    i2cObject.Stop(i2cSCL)
    longmove(@xl, @zx, 3)                               'save initial zero values
    Init(i2cSCL, _deviceAddress)                        're-initialize the device
    longmove(@zx, @xl, 3)                               'restore zero values

  if (result == 1)
    LONG[TempPtr] := tl + 23000
    LONG[XPtr] := xl - zx
    LONG[YPtr] := yl - zy
    LONG[ZPtr] := zl - zz
    result := true
  else
#ifdef I2CDEBUG
    uarts.str(0, string("Gyro "))
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
'  @tl

lmmgetdata              sub     lmm#dcurr,#4
                        rdlong  lmm#reg7,lmm#dcurr      'i2ctable

                        jmp     #lmm#icall              'i2c setup
                        long    I2CLMM#SETUP

                        sub     lmm#dcurr,#4
                        rdlong  lmm#reg18,lmm#dcurr     '@tl

                        mov     lmm#reg15, #ITG3200_INT_STATUS 'status register   '
                        jmp     #lmm#icall
                        long    I2CLMM#READREGHEADER
                        mov     lmm#reg19, lmm#reg14    'save acks

                        mov     lmm#reg14, #0
                        jmp     #lmm#icall
                        long    I2CLMM#READ             'status

                        shl     lmm#reg19, #8       wz
                        or      lmm#reg19, lmm#reg11

                        mov     lmm#reg14, #%10000000   'read with ACK, NAK 8th read
                        jmp     #lmm#icall
                        long    I2CLMM#READWORDR
                        mov     lmm#reg15, lmm#reg17

                        jmp     #lmm#icall
                        long    I2CLMM#READWORDR
                        mov     lmm#reg16, lmm#reg17    'save

                        jmp     #lmm#icall
                        long    I2CLMM#READWORDR        'last read will be NAK and i2cstop
                        mov     lmm#reg20, lmm#reg17    'save

                        jmp     #lmm#icall
                        long    I2CLMM#READWORDR        'last read will be NAK and i2cstop

                        test    lmm#reg19, #1       wc

        if_z_and_c      wrlong  lmm#reg15, lmm#reg18    'write results out to hub addresses
                        add     lmm#reg18, #4
        if_z_and_c      wrlong  lmm#reg16, lmm#reg18
                        add     lmm#reg18, #4
        if_z_and_c      wrlong  lmm#reg20, lmm#reg18
                        add     lmm#reg18, #4
        if_z_and_c      wrlong  lmm#reg17, lmm#reg18

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
