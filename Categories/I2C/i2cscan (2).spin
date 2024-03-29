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
│ I2CScan 1.0                              │
│ Author: Tim Moore                        │               
│ Copyright (c) 2008> Tim Moore            │               
│ See end of file for terms of use.        │                
│ Based on code by James Burrows           │                
│                                          │                
│ Modified to support SMBus timing         │                
└──────────────────────────────────────────┘
}}
OBJ
  uarts         : "pcFullDuplexSerial4FC"               '1 COG for 4 serial ports

PUB i2cScan(i2cSCL) | value, ackbit, i2cSlaveCounter, i2cAddress
' Scan the I2C Bus and debug the LCD
  uarts.strln(0,string("Scanning I2C Bus...."))
   
  ' initialize variables
  i2cSlaveCounter := 0
   
  ' i2c Scan - scans all the address's on the bus
  ' sends the address byte and listens for the device to ACK (hold the SDA low)
  ' Skip address 0 sinces its the broadcast address and multiple devices can respond
  repeat i2cAddress from 1 to 127
    value :=  i2cAddress << 1 | 0
    ackbit := Check(i2cSCL,value)
     
    if ackbit==false
      'uarts.str(0,string("NAK "))
    else
      ' show the scan 
      uarts.str(0,string("Scan Addr :  %"))    
      uarts.bin(0,value,8)
      uarts.putc(0," ")
      uarts.bin(0,i2cAddress,8)
      uarts.str(0,string(",  ACK"))                  
       
      ' the device has set the ACK bit 
      i2cSlaveCounter ++
      waitcnt(clkfreq/4+cnt)
       
      uarts.putc(0,13)
     
    ' slow the scan so we can read it.    
    'waitcnt(clkfreq/10 + cnt)
   
  ' update the counter
  uarts.str(0,string("i2cScan found "))
  uarts.dec(0,i2cSlaveCounter)
  uarts.strln(0,string(" devices!"))

PRI Check(SCL,deviceAddress) : ackbit | SDA, ob, d
'' send the deviceAddress and listen for the ACK
' All the code is inlined here to meet the SMBus SCL low timing constraints
'
  SDA := SCL + 1
  d := deviceAddress << 24

  'Need this for MLX90614
  outa[SCL]~~
  dira[SDA]~~
  dira[SCL]~~
  outa[SDA]~
  outa[SDA]~~

  'Do it twice since MLX90614 doesn't respond 1st time always
  outa[SCL]~~                                           ' Initially drive SCL HIGH
  dira[SCL]~~
  outa[SDA]~~                                           ' Initially drive SDA HIGH
  dira[SDA]~~
  outa[SDA]~                                            ' Now drive SDA LOW
  ob := (d <-= 1) & 1 
  outa[SCL]~                                            ' Leave SCL LOW
  repeat 8                                              ' Output data to SDA
    outa[SDA] := ob
    outa[SCL]~~                                         ' Toggle SCL from LOW to HIGH to LOW
    ob := (d <-= 1) & 1 
    outa[SCL]~
  dira[SDA]~                                            ' Set SDA to input for ACK/NAK
  outa[SCL]~~
  ackbit := ina[SDA] == 0                               ' Sample SDA when SCL is HIGH
  outa[SCL]~
  dira[SCL]~                                            ' Now let them float
  dira[SDA]~                                            ' If pullups present, they'll stay HIGH

  d := deviceAddress << 24

  outa[SCL]~~                                           ' Initially drive SCL HIGH
  dira[SCL]~~
  outa[SDA]~~                                           ' Initially drive SDA HIGH
  dira[SDA]~~
  outa[SDA]~                                            ' Now drive SDA LOW
  ob := (d <-= 1) & 1 
  outa[SCL]~                                            ' Leave SCL LOW
  repeat 8                                              ' Output data to SDA
    outa[SDA] := ob
    outa[SCL]~~                                         ' Toggle SCL from LOW to HIGH to LOW
    ob := (d <-= 1) & 1 
    outa[SCL]~
  dira[SDA]~                                            ' Set SDA to input for ACK/NAK
  outa[SCL]~~
  ackbit |= ina[SDA] == 0                               ' Sample SDA when SCL is HIGH, accept either ack
  outa[SCL]~
  dira[SCL]~                                            ' Now let them float
  dira[SDA]~                                            ' If pullups present, they'll stay HIGH

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
