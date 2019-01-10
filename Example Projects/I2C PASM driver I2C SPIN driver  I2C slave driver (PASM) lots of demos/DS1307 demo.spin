{{
OBEX LISTING:
  http://obex.parallax.com/object/700

  Includes Spin-based and PASM-based open-drain and push-pull drivers, with methods for reading and writing any number of bytes, words, and longs in big-endian or little-endian format.  All drivers tested with the 24LC256 EEPROM, DS1307 real time clock, MMA7455L 3-axis accelerometer, L3G4200D gyroscope module, MS5607 altimeter module, and BMP085 pressure sensor.  Includes a demo programs for each.

  Also includes a polling routine that displays the device address and name of everything on the I2C bus.

  Also includes a slave object that runs in a PASM cog with a Spin handler, and provides 32 byte-sized registers for a master running on another device to write to and read from.  Tested okay up to 1Mbps (max speed of my PASM push-pull object).  Includes demo for the slave object.

  Newly added multi-master object that can share the bus with other masters, provided of course that the other masters also allow sharing.
}}
{{┌──────────────────────────────────────────┐
  │ DS1307 real time clock demo              │
  │ Author: Chris Gadd                       │
  │ Copyright (c) 2015 Chris Gadd            │
  │ See end of file for terms of use.        │
  └──────────────────────────────────────────┘
  
               DS1307  5V  3.3V                                                                                                                                                                                
   32.768KHz  ┌───────┐                                                                                                                                                                                    
     ┌┤├─────┤X1  +5V├─┘    10KΩ                                                                                                                                                                           
     └────────┤X2  SQW├───┼─┼─┻─                                                                                                                                                                               
            ┌─┤Vbt SCL├───┻─┼─  I2C Clock                                                         CONTROL REGISTER 07h                                                                                         
            ┣─┤Gnd SDA├─────┻─  I2C Data                                                                                                                                                                       
             └───────┘                                                                           Bit 7: Output Control (OUT). This bit controls the output level of the SQW/OUT pin when                      
                                                                                                   the square-wave output is disabled. If SQWE = 0, the logic level on the SQW/OUT pin is   
   ┌───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┬──────────┬───────┐    1 if OUT = 1 and is 0 if OUT = 0. On initial application of power to the device, this    
   │ADDRESS│ BIT 7 │ BIT 6 │ BIT 5 │ BIT 4 │ BIT 3 │ BIT 2 │ BIT 1 │ BIT 0 │ FUNCTION │ RANGE │    bit is typically set to a 0.                                                             
   ├───────┼───────┼───────┴───────┴───────┼───────┴───────┴───────┴───────┼──────────┼───────┤                                                                                             
   │  00h  │ Halt  │      10 Seconds       │             Seconds           │ Seconds  │ 00-59 │   Bit 4: Square-Wave Enable (SQWE). This bit, when set to logic 1, enables the oscillator   
   ├───────┼───────┼───────────────────────┼───────────────────────────────┼──────────┼───────┤    output. The frequency of the square-wave output depends upon the value of the RS0 and    
   │  01h  │   0   │      10 Minutes       │             Minutes           │ Minutes  │ 00-59 │    RS1 bits. With the square-wave output set to 1Hz, the clock registers update on the      
   ├───────┼───────┼───────┬───────┬───────┼───────────────────────────────┼──────────┼───────┤    falling edge of the square wave. On initial application of power to the device, this                                                               
   │       │       │  12   │ 10h   │ 10    │                               │          │ 1-12  │    bit is typically set to a 0.                                                             
   │  02h  │   0   ├───────┼───────┤ Hour  │             Hours             │ Hours    │ +AM/PM│                                                                                             
   │       │       │  24   │ PM/AM │       │                               │          │ 00-23 │   Bits 1 and 0: Rate Select (RS[1:0]). These bits control the frequency of the square-wave  
   ├───────┼───────┼───────┼───────┼───────┼───────┬───────────────────────┼──────────┼───────┤    output when the square-wave output has been enabled. The following table lists the       
   │  03h  │   0   │   0   │   0   │   0   │   0   │     Day               │ Day      │ 01-07 │    square-wave frequencies that can be selected with the RS bits. On initial application    
   ├───────┼───────┼───────┼───────┴───────┼───────┴───────────────────────┼──────────┼───────┤    of power to the device, these bits are typically set to a 1.                             
   │  04h  │   0   │   0   │   10 Date     │             Date              │ Date     │ 01-31 │   ┌─────┬─────┬────────────────┬──────┬─────┐                                               
   ├───────┼───────┼───────┼───────┬───────┼───────────────────────────────┼──────────┼───────┤   │ RS1 │ RS0 │ SQW/OUT OUTPUT │ SQWE │ OUT │                                               
   │  05h  │   0   │   0   │   0   │ 10Mon │             Month             │ Month    │ 01-12 │   ├─────┼─────┼────────────────┼──────┼─────┤                                               
   ├───────┼───────┴───────┴───────┴───────┼───────────────────────────────┼──────────┼───────┤   │  0  │  0  │       1Hz      │   1  │  X  │                                               
   │  06h  │            10 Year            │             Year              │ Year     │ 00-99 │   │  0  │  1  │     4.096KHz   │   1  │  X  │                                               
   ├───────┼───────┬───────┬───────┬───────┼───────┬───────┬───────┬───────┼──────────┼───────┤   │  1  │  0  │     8.192KHz   │   1  │  X  │                                               
   │  07h  │  OUT  │   0   │   0   │ SQWE  │   0   │   0   │  RS1  │  RS0  │ Control  │  ---  │   │  1  │  1  │    32.768KHz   │   1  │  X  │                                               
   ├───────┼───────┴───────┴───────┴───────┴───────┴───────┴───────┴───────┼──────────┼───────┤   │  X  │  X  │        0       │   0  │  0  │                                               
   │08h-3Fh│                                                               │ RAM 56x8 │00h-FFh│   │  X  │  X  │        1       │   0  │  1  │                                               
   └───────┴───────────────────────────────────────────────────────────────┴──────────┴───────┘   └─────┴─────┴────────────────┴──────┴─────┘                                               
                                                                                                  
}}                                                                                                                                                
CON
  _clkmode = xtal1 + pll16x                                                    
  _xinfreq = 5_000_000

  SCL = 28
  SDA = 29

CON

  RTC = $68                                                                     ' 7-bit device ID for the DS1307
  #0,Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday
  #0,January,February,March,April,May,June,July,August,September,October,November,December

VAR
  byte  seconds, minutes, hours, day, date, month, year

OBJ
  I2C  : "I2C Spin driver v1.4od"
  FDS  : "FullDuplexSerial"

PUB Main 
  FDS.start(31,30,0,115_200)
  waitcnt(cnt + clkfreq * 2)
  FDS.tx($00)

  if not ina[SCL]
    FDS.str(string("No pullup detected on SCL",$0D))                            
  if not ina[SDA]                                                               
    FDS.str(string("No pullup detected on SDA",$0D))
  if not ina[SDA] or not ina[SCL]
    FDS.str(string(" Use I2C Spin push_pull driver",$0D,"Halting"))                                                              
    repeat                                                                      

  I2C.init(SCL,SDA)

  if not \DS1307_demo                                                           ' The Spin-based I2C drivers abort if there's no response
    FDS.str(string($0D,"DS1307 not responding"))                                '  from the addressed device within 10ms
                                                                                ' An abort trap \ must be used somewhere in the calling code
                                                                                '  or bad things happen if the I2C device fails to respond                  

PRI DS1307_demo | Idx, t, n
  
  FDS.str(string("Enter year (00-99): "))
  year := input_value
  FDS.str(string("Enter month (01-12): "))
  month := input_value
  FDS.str(string("Enter day of month (01-31): "))
  date := input_value
  FDS.str(string("Enter day of week (1 - 7) (Sunday = 1): "))
  day := input_value  
  FDS.str(string("Enter hour (01-23): "))
  hours := input_value
  FDS.str(string("Enter minutes (00-59): "))
  minutes := input_value
  FDS.str(string("Enter seconds (00-59): "))
  seconds := input_value
  I2C.writeBytes(RTC,$00,@seconds,7)

  t := cnt
  repeat
    waitcnt(t += clkfreq)
    I2C.readBytes(RTC,$00,@seconds,7)
    FDS.tx($00)

    FDS.str(lookup(Day:string("Sunday"),string("Monday"),string("Tuesday"),string("Wednesday"),string("Thursday"),string("Friday"),string("Saturday")))
    FDS.tx(" ")
    if Month => $10
      Month -= $06
    FDS.str(lookup(Month:string("January"),string("February"),string("March"),string("April"),string("May"),string("June"),string("July"),string("August"),string("September"),string("October"),string("November"),string("December")))
    FDS.tx(" ")
    FDS.hex(Date,2)
    FDS.str (string(", "))
    FDS.hex($2000 + (year),4)
    FDS.tx(" ")
    if hours & %0100_0000                                                       ' 12-hour time
      FDS.hex(hours & %0001_1111,2)
      FDS.tx(":")
      FDS.hex(minutes,2)
      FDS.tx(":")
      FDS.hex(seconds,2)
      FDS.tx(" ")
      if hours & %0010_0000
        FDS.str(string("pm"))
      else
        FDS.str(string("am"))
    else                                                                        ' 23-hour time
      FDS.hex(hours & %0011_1111,2)
      FDS.tx(":")
      FDS.hex(minutes,2)
      FDS.tx(":")
      FDS.hex(seconds,2)                     

PRI Input_value | n

  n := 0
  repeat until n == $0D
    n := fds.rx
    if n => "0" and n =< "9"
      result := result << 4 + (n - "0")

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
