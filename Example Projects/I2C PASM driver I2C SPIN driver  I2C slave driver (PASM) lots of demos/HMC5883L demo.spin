{{
OBEX LISTING:
  http://obex.parallax.com/object/700

  Includes Spin-based and PASM-based open-drain and push-pull drivers, with methods for reading and writing any number of bytes, words, and longs in big-endian or little-endian format.  All drivers tested with the 24LC256 EEPROM, DS1307 real time clock, MMA7455L 3-axis accelerometer, L3G4200D gyroscope module, MS5607 altimeter module, and BMP085 pressure sensor.  Includes a demo programs for each.

  Also includes a polling routine that displays the device address and name of everything on the I2C bus.

  Also includes a slave object that runs in a PASM cog with a Spin handler, and provides 32 byte-sized registers for a master running on another device to write to and read from.  Tested okay up to 1Mbps (max speed of my PASM push-pull object).  Includes demo for the slave object.

  Newly added multi-master object that can share the bus with other masters, provided of course that the other masters also allow sharing.
}}
{{┌──────────────────────────────────────────┐
  │ HMC5883L demo using my I2C driver        │
  │ Author: Chris Gadd                       │
  │ Copyright (c) 2014 Chris Gadd            │
  │ See end of file for terms of use.        │
  └──────────────────────────────────────────┘
  
Demonstrates how to use the HMC5883L compass
                                                                                                                                                                                                          
}}                                                                                                                                                
CON
  _clkmode = xtal1 + pll16x                                                      
  _xinfreq = 5_000_000

  SCL = 28
  SDA = 29

CON
  
  COMPASS = $1E
' ────────────────────┬────────┬─────────────────┬──────────────────────────┬─────────────────┐
  Config_A = 00      '│  ----  │ 00 - 1 sample   │ 000 -  0.75Hz            │ 00 - Normal     │       
                     '│        │ 01 - 2 samples  │ 001 -  1.5               │ 01 - Positive   │         
                     '│        │ 10 - 4 samples  │ 010 -  3                 │ 10 - Negative   │        
                     '│        │ 11 - 8 samples  │ 011 -  7.5               │ 11 - Reserved   │        
                     '│        │                 │ 100 - 15                 │                 │ 
                     '│        │                 │ 101 - 30                 │                 │
                     '│        │                 │ 110 - 75                 │                 │
                     '│        │                 │ 111 - Reserved           │                 │
' ────────────────────┼────────┴─────────────────┼────────┬────────┬────────┼────────┬────────┤    
  Config_B = 01      '│      000 - Gain 1370     │  ----  │  ----  │  ----  │  ----  │  ----  │
                     '│      001 -      1090     │        │        │        │        │        │
                     '│      010 -       820     │        │        │        │        │        │
                     '│      011 -       660     │        │        │        │        │        │
                     '│      100 -       440     │        │        │        │        │        │
                     '│      101 -       390     │        │        │        │        │        │
                     '│      110 -       330     │        │        │        │        │        │
                     '│      111 -       230     │        │        │        │        │        │
' ────────────────────┼────────┬────────┬────────┼────────┼────────┼────────┼────────┴────────┤        
  Mode     = 02      '│   HS   │  ----  │  ----  │  ----  │  ----  │  ----  │ 00 - continuous │          
                     '│        │        │        │        │        │        │ 01 - single     │          
                     '│        │        │        │        │        │        │ 10 - idle       │          
                     '│        │        │        │        │        │        │ 11 - idle       │          
' ────────────────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┬────────┤    
  Data_X   = 03      '│        │        │        │        │        │        │        │        │
  Data_X_L = 04      '│        │        │        │        │        │        │        │        │
' ────────────────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┤    
  Data_Y   = 05      '│        │        │        │        │        │        │        │        │                    
  Data_Y_L = 06      '│        │        │        │        │        │        │        │        │                    
' ────────────────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┤    
  Data_Z   = 07      '│        │        │        │        │        │        │        │        │                    
  Data_Z_L = 08      '│        │        │        │        │        │        │        │        │                    
' ────────────────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┤    
  Status   = 09      '│  ----  │  ----  │  ----  │  ----  │  ----  │  ----  │  Lock  │  Ready │
' ────────────────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┤    
  Ident_A  = 10      '│    0   │    1   │    0   │    0   │    1   │    0   │    0   │    0   │         
  Ident_B  = 11      '│    0   │    0   │    1   │    1   │    0   │    1   │    0   │    0   │         
  Ident_C  = 12      '│    0   │    0   │    1   │    1   │    0   │    0   │    1   │    1   │
' ────────────────────┴────────┴────────┴────────┴────────┴────────┴────────┴────────┴────────┘   
                                                                                 
VAR
  word  compass_X, compass_Y, compass_Z

OBJ
  I2C  : "I2C Spin driver v1.4od"
  FDS  : "FullDuplexSerial"

PUB Main 
  FDS.start(31,30,0,115_200)
  waitcnt(cnt + clkfreq * 2)
  FDS.tx($00)

  I2C.init(SCL,SDA)

  if not ina[SCL]
    FDS.str(string("No pullup detected on SCL",$0D))                            
  if not ina[SDA]                                                               
    FDS.str(string("No pullup detected on SDA",$0D))
  if not ina[SDA] or not ina[SCL]
    FDS.str(string(" Use I2C Spin push_pull driver",$0D,"Halting"))                                                              
    repeat                                                                      

  if not \Compass_demo                                                          ' The Spin-based I2C drivers abort if there's no response
    FDS.str(string($0D,"HMC5883L not responding"))                              '  from the addressed device within 10ms
                                                                                ' An abort trap \ must be used somewhere in the calling code
                                                                                '  or bad things happen                                                     

PUB Compass_demo

  I2C.writeByte(COMPASS,CONFIG_A,%0_10_100_00)                                  ' 4 samples, 15Hz update, normal
  I2C.writeByte(COMPASS,MODE,$00)                                               ' Continuous sampling mode

  repeat
    get_measurements
    FDS.tx($00)
    FDS.str(string("X: "))
    FDS.dec(~~compass_X)
    FDS.str(string($0D,"Y: "))
    FDS.dec(~~compass_Y)
    FDS.str(string($0D,"Z: "))
    FDS.dec(~~compass_Z)

PRI get_measurements

  repeat until (I2C.readByte(COMPASS,STATUS) & $01)                             ' Wait until ready
  I2C.readWordsB(COMPASS,DATA_X,@compass_X,3)                                                

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
