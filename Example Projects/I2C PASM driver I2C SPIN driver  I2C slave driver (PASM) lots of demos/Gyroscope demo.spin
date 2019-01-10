{{
OBEX LISTING:
  http://obex.parallax.com/object/700

  Includes Spin-based and PASM-based open-drain and push-pull drivers, with methods for reading and writing any number of bytes, words, and longs in big-endian or little-endian format.  All drivers tested with the 24LC256 EEPROM, DS1307 real time clock, MMA7455L 3-axis accelerometer, L3G4200D gyroscope module, MS5607 altimeter module, and BMP085 pressure sensor.  Includes a demo programs for each.

  Also includes a polling routine that displays the device address and name of everything on the I2C bus.

  Also includes a slave object that runs in a PASM cog with a Spin handler, and provides 32 byte-sized registers for a master running on another device to write to and read from.  Tested okay up to 1Mbps (max speed of my PASM push-pull object).  Includes demo for the slave object.

  Newly added multi-master object that can share the bus with other masters, provided of course that the other masters also allow sharing.
}}
{{┌──────────────────────────────────────────┐
  │ L3G4200D Gyroscope demo                  │
  │ Author: Chris Gadd                       │
  │ Copyright (c) 2015 Chris Gadd            │
  │ See end of file for terms of use.        │
  └──────────────────────────────────────────┘
  
Demonstrates how to use the L3G4200D gyroscope 

          27911
     ┌────────────┐                      
     │        Int2├  Module has            
     │        Int1├  internal pull-ups     
     │         SDO├                        
     │ SDA/SDI/SDO├─────── I2C Data       
     │         SCL├─────── I2C Clock      
     │          CS├                        
     │         VIN├                                            
     │         Gnd├                                            
     └────────────┘
}}
CON
  _clkmode = xtal1 + pll16x                                                    
  _xinfreq = 5_000_000

  SCL  = 28
  SDA  = 29

CON
  GYRO          = $69 ' 7-bit device ID
'┌────────────┬──────────┬────────────────────────────┬─────────┬─────────┬─────────┬─────────┬─────────┬─────────┬─────────┬─────────┐
'│ Name       │ Address  │      Definition            │  BIT 7  │  BIT 6  │  BIT 5  │  BIT 4  │  BIT 3  │  BIT 2  │  BIT 1  │  BIT 0  │
'├────────────┼──────────┼────────────────────────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤                       
' Reserved      = $00-0E │       Reserved             │   ---   │   ---   │   ---   │   ---   │   ---   │   ---   │   ---   │   ---   │                       
  WHO_AM_I      = $0F  ' │        "Who am I" value    │    1    │    1    │    0    │    1    │    0    │    0    │    1    │    1    │                       
' Reserved      = $10-1F │       Reserved             │   ---   │   ---   │   ---   │   ---   │   ---   │   ---   │   ---   │   ---   │                       
  CTRL_REG1     = $20 '  │ Data rate, Bandwidth...    │   DR1   │   DR0   │   BW1   │   BW0   │   PD    │   Zen   │   Yen   │   Xen   │                       
  CTRL_REG_2    = $21  ' │ High pass filter selection │    0    │    0    │  HPM1   │  HPM1   │  HPCF3  │  HPCF2  │  HPCF1  │  HPCF0  │                       
  CTRL_REG_3    = $22  ' │ Interrupts                 │ I1Int1  │ I1_Boot │H_Lactive│  PP_OD  │ I2_DRDY │ I2_WTM  │ I2_ORun │ I2_Empty│                       
  CTRL_REG_4    = $23  ' │ Data transfer / Self test  │   BDU   │   BLE   │   FS1   │   FS0   │   ---   │   ST1   │   ST0   │   SIM   │                       
  CTRL_REG_5    = $24  ' │                            │  Boot   │ FIFO_EN │   ---   │  HPen   │INT1_Sel1│INT1_Sel0│OUT_Sel1 │OUT_Sel0 │                       
  REFERENCE     = $25  ' │ Reference value for ints   │  Ref[7] │  Ref[6] │  Ref[5] │  Ref[4] │  Ref[3] │  Ref[2] │  Ref[1] │  Ref[0] │  
  OUT_TEMP      = $26  ' │ Temperature data           │ Temp[7] │ Temp[6] │ Temp[5] │ Temp[4] │ Temp[3] │ Temp[2] │ Temp[1] │ Temp[0] │                                      
  STATUS_REG    = $27  ' │ ┌────────────────────────┐ │  ZYXOR  │   ZOR   │   YOR   │   XOR   │  ZYXDA  │   ZDA   │   YDA   │   XDA   │  
  OUT_X_L       = $28  ' │ │ MSB must be set for    │ │   ---   │   ---   │   ---   │   ---   │   ---   │   ---   │   ---   │   ---   │
  OUT_X_H       = $29  ' │ │  auto-increment to work│ │   ---   │   ---   │   ---   │   ---   │   ---   │   ---   │   ---   │   ---   │
  OUT_Y_L       = $2A  ' │ │  properly.             │ │   ---   │   ---   │   ---   │   ---   │   ---   │   ---   │   ---   │   ---   │
  OUT_Y_H       = $2B  ' │ │ To read registers $28  │ │   ---   │   ---   │   ---   │   ---   │   ---   │   ---   │   ---   │   ---   │
  OUT_Z_L       = $2C  ' │ │  through $2D, initial  │ │   ---   │   ---   │   ---   │   ---   │   ---   │   ---   │   ---   │   ---   │
  OUT_Z_H       = $2D  ' │ │  address must be set   │ │   ---   │   ---   │   ---   │   ---   │   ---   │   ---   │   ---   │   ---   │
  FIFO_CTRL_REG = $2E  ' │ │  to $A8.               │ │   FM2   │   FM1   │   FM0   │  WTM4   │  WTM3   │  WTM2   │  WTM1   │  WTM0   │
  FIFO_SRC_REG  = $2F  ' │ └────────────────────────┘ │   WTM   │  OVRN   │  EMPTY  │  FSS4   │  FSS3   │  FSS2   │  FSS1   │  FSS0   │
  INT1_CFG      = $30  ' │                            │  AND/OR │   LIR   │  ZHIE   │  ZLIE   │  YHIE   │  YLIE   │  XHIE   │  XLIE   │
  INT1_SRC      = $31  ' │        (read only)         │    0    │   IA    │   ZH    │   ZL    │   YH    │   YL    │   XH    │   XL    │
  INT1_TSH_XH   = $32  ' │ X-axis interrupt threshold │   ---   │ THSX14  │ THSX13  │ THSX12  │ THSX11  │ THSX10  │  THSX9  │  THSX8  │
  INT1_TSH_XL   = $33  ' │ X-axis interrupt threshold │  THSX7  │  THSX6  │  THSX5  │  THSX4  │  THSX3  │  THSX2  │  THSX1  │  THSX0  │  
  INT1_TSH_YH   = $34  ' │ Y-axis interrupt threshold │   ---   │ THSY14  │ THSY13  │ THSY12  │ THSY11  │ THSY10  │  THSY9  │  THSY8  │
  INT1_TSH_YL   = $35  ' │ Y-axis interrupt threshold │  THSY7  │  THSY6  │  THSY5  │  THSY4  │  THSY3  │  THSY2  │  THSY1  │  THSY0  │
  INT1_TSH_ZH   = $36  ' │ Z-axis interrupt threshold │   ---   │ THSZ14  │ THSZ13  │ THSZ12  │ THSZ11  │ THSZ10  │  THSZ9  │  THSZ8  │
  INT1_TSH_ZL   = $37  ' │ Z-axis interrupt threshold │  THSZ7  │  THSZ6  │  THSZ5  │  THSZ4  │  THSZ3  │  THSZ2  │  THSZ1  │  THSZ0  │
  INT1_DURATION = $38  ' │                            │  WAIT   │   D6    │   D5    │   D4    │   D3    │   D2    │   D1    │   D0    │
'└────────────┴──────────┴────────────────────────────┴─────────┴─────────┴─────────┴─────────┴─────────┴─────────┴─────────┴─────────┘
  ZYXDA         = $08  ' ZYXDA is set if STATUS_REG has new data  
                                                                                                                                              
VAR
  long  x_cal,y_cal,z_cal
  word  x_axis,y_axis,z_axis

OBJ
  I2C : "I2C Spin driver v1.4od"
  FDS : "FullDuplexSerial"

PUB Main 
  FDS.start(31,30,0,115_200)
  waitcnt(cnt + clkfreq * 2)
  FDS.tx($00)

  I2C.init(SCL,SDA)

  if not ina[SCL]
    FDS.str(string("No pullup detected on SCL",$0D))                            ' The 27911 gyroscope module has internal pullup resistors
  if not ina[SDA]                                                               '  on both SCL and SDA, shouldn't ever see this message
    FDS.str(string("No pullup detected on SDA",$0D))
  if not ina[SDA] or not ina[SCL]
    FDS.str(string(" Use I2C Spin push_pull driver",$0D,"Halting"))                                                              
    repeat                                                                      

  if not \Gyro_demo                                                             ' The Spin-based I2C drivers abort if there's no response
    FDS.str(string($0D,"Gyroscope not responding"))                             '  from the addressed device within 10ms
                                                                                ' An abort trap \ must be used somewhere in the calling code
                                                                                '  or bad things happen                                                     

PRI Gyro_demo | x, y, z, cx, cy, cz  

  configure_gyro
  calibrate_gyro
  calibrate_gyro

  cx := cy := cz := 0
  
  repeat
    repeat until read_gyro                                                                                                              
    x := (~~x_axis - x_cal) * 100 / 11429                                       ' From the datasheet: 250dps = 0.00875 dps/digit
    y := (~~y_axis - y_cal) * 100 / 11429                                       '  working out to ~114.29 counts / degree
    z := (~~z_axis - z_cal) * 100 / 11429                                       ' 500dps = 0.0175, 2000dps = 0.07                       
 
    FDS.Tx($00)
    FDS.Str(string("Instantaneous:",$0D))
    FDS.Str(string("X-Axis: "))
    FDS.Dec(x)
    FDS.Str(string($09,"Y-Axis: "))
    FDS.Dec(y)
    FDS.Str(string($09,"Z-Axis: "))
    FDS.Dec(z)
    FDS.Str(string($0D,$0D,"Cumulative:",$0D))
    FDS.Str(string("X-Axis: "))
    FDS.Dec((cx += x) / 37)
    FDS.Str(string($09,"Y-Axis: "))
    FDS.Dec((cy += y) / 37)
    FDS.Str(string($09,"Z-Axis: "))
    FDS.Dec((cz += z) / 37)
    
    waitcnt(cnt + clkfreq / 100)                                                ' This delay time affects the divisor in the cumulative calculations

PRI Read_gyro

  if I2C.readByte(GYRO,STATUS_REG) & ZYXDA                                      ' Check to see if new data is available for x, y, or z
    I2C.readWordsL(GYRO,OUT_X_L | $80,@x_axis,3)                                ' Read X, Y, and Z axis
    return true

PRI Configure_gyro

  I2C.writeByte(GYRO,CTRL_REG1,%0_10_0_1_1_1)                                   ' Place into power-down mode - my gyro doesn't reflect any changes unless power cycled first
                                                                                '  And even then, the first calibration is always incorrect
  I2C.writeByte(GYRO,CTRL_REG1,%0_10_1_1_1_1)                                   ' Enable all axis, 100Hz update
' I2C.writeByte(GYRO,CTRL_REG_3,$08)                                            ' Enable data ready signal - doesn't seem to be necessary for the flag
  I2C.writeByte(GYRO,CTRL_REG_4,$80)                                            ' Enable block data update, 250dps sensitivity

PRI Calibrate_gyro

  x_cal := 0
  y_cal := 0
  z_cal := 0
  
  repeat 32
    repeat until Read_gyro                                                
    x_cal += ~~x_axis
    y_cal += ~~y_axis
    z_cal += ~~z_axis

  x_cal /= 32
  y_cal /= 32
  z_cal /= 32

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
