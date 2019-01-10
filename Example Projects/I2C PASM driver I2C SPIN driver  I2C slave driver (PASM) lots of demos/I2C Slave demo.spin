{{
OBEX LISTING:
  http://obex.parallax.com/object/700

  Includes Spin-based and PASM-based open-drain and push-pull drivers, with methods for reading and writing any number of bytes, words, and longs in big-endian or little-endian format.  All drivers tested with the 24LC256 EEPROM, DS1307 real time clock, MMA7455L 3-axis accelerometer, L3G4200D gyroscope module, MS5607 altimeter module, and BMP085 pressure sensor.  Includes a demo programs for each.

  Also includes a polling routine that displays the device address and name of everything on the I2C bus.

  Also includes a slave object that runs in a PASM cog with a Spin handler, and provides 32 byte-sized registers for a master running on another device to write to and read from.  Tested okay up to 1Mbps (max speed of my PASM push-pull object).  Includes demo for the slave object.

  Newly added multi-master object that can share the bus with other masters, provided of course that the other masters also allow sharing.
}}
{{┌──────────────────────────────────────────┐
  │ I2C slave demo                           │
  │ Author: Chris Gadd                       │
  │ Copyright (c) 2015 Chris Gadd            │
  │ See end of file for terms of use.        │
  └──────────────────────────────────────────┘

  This routine demonstrates the use of an I2C slave device running in a second cog
  The slave is started with the SCL and SDA pins, and a 7-bit device address
  
  For the demonstation, an I2C master running in one cog performs the writes and reads to and from the slave object. In actual use, the I2C master would be on some other device.
  The slave object simply writes received bytes into a 32-byte array, and reads them back out when requested.
  It is up to a higher-level object to determine that a byte has been written to the array and what to do with it.

}}                                                                                                                                                
CON
  _clkmode = xtal1 + pll16x                                                    
  _xinfreq = 5_000_000

  SDA_pin = 29
  SCL_pin = 28
  Bitrate = 1_000_000

OBJ
  master : "I2C PASM driver v1.8pp"
  slave  : "I2C slave v1.2"
  fds    : "FullDuplexSerial"

PUB Main | index, n, i
  master.Start(SCL_pin,SDA_pin,bitrate)
  slave.Start(SCL_pin,SDA_pin,$42)                                              ' Start the slave object with a device address of $42
  fds.Start(31,30,0,115_200)
  waitcnt(cnt + clkfreq)
  fds.Tx($00)

  fds.Str(string("This first section demonstrates how an I2C master running on another device (or another cog in this instance)",$0D,{
                }" is able to write to and read from the I2C slave object.",$0D,{
                }" Single writes, page writes, single reads, repeated reads, and page reads, and commands are all supported.",$0D))
  fds.Tx($0D)
  fds.Str(string("  Master.writeBytes(Slave_ID,0,@Test_data,8) writes 01 23 45 67 89 AB CD EF to the first eight slave registers.",$0D))
  master.writeBytes($42,$00,@Test_data,8)
  fds.Str(string("  Master.readByte(Slave_ID,0) returns "))
  fds.Hex(master.readByte($42,$00),2)                                           ' Read a single byte from slave register $00 and display it on the serial terminal
  fds.Tx($0D)
  fds.Str(string("  Master.readNext returns "))

  repeat 7
    fds.Hex(master.readNext($42),2)                                             ' Perform a repeated read to read the next seven bytes following the byte at address $00
    fds.Tx(" ")                                                                 '  and display each one on the serial terminal as it is read
  fds.Tx($0D)

' This section demonstrates how a prop running the slave object can operate on the registers

  fds.Str(string($0D,"The check method returns the index of the highest registers with new data.",$0D,{
                    }"  Subsequent checks return the next highest.",$0D,{
                    }"  New registers contain:",$0D,$09,"Reg",$09,"Data",$0D))
  index := slave.Check
  repeat while index > -1
    fds.Tx($09)
    fds.Hex(index,2)
    fds.Tx($09)
    fds.Hex(slave.Get(index),2)       
    fds.Tx($0D)
    index := slave.Check

  fds.Str(string($0D,"The checkReg method returns the contents of a specific register only if it has new data. Returns -1 otherwise.",$0D,{
                    }"  Master.writeByte(Slave_ID,31,$07) writes $07 into slave register 31",$0D))
  master.writeByte($42,31,$07)
  fds.Str(string("  Slave.checkReg(31) returns "))
  fds.Dec(Slave.checkReg(31))
  fds.Str(string($0D,"  Slave.checkReg(31) returns "))
  fds.Dec(Slave.checkReg(31))
  
  fds.Str(string($0D,$0D,"The get method retrieves a register regardless of whether it's new or not.",$0D,{
                        }"  Slave.get(31) still returns "))
  fds.Dec(slave.get(31))

  fds.Str(string($0D,$0D,"The put method writes data to the registers.",$0D,{
                        }"  Slave.put(0,$1F) puts $1F into register 0"))
  slave.Put(0,$1F)
  fds.Str(string($0D,"  Master.readByte(Slave_ID,0) returns $"))
  fds.Hex(master.readByte($42,$00),2)
  fds.Tx($0D)

  master.Command($42,$01)
  fds.Str(string($0D,"Flags methods can be used with the master.command method, which only sends ID and a register and no data.",$0D,{
                    }"  Master.command(slave_ID,$01) sets bit 1 of the flags variable",$0D,{
                    }"  Slave.checkFlags returns %"))
  fds.Bin(Slave.checkFlags,32)
  fds.Str(string($0D,"  Slave.checkFlag(1) returns "))
  if slave.CheckFlag(1)
    fds.Str(string("true."))
  else
    fds.Str(string("false."))


  fds.Str(string($0D,$0D,"The register method can be used for directly operating on the slave registers.",$0D,{
                 }"  byte[slave.register][12] := $FE stores $FE in slave register 12"))
  byte[slave.Register][12] := $FE                                               ' store $FE in slave register 12
  fds.Str(string($0D,"  FDS.hex(byte[slave.register][12] returns $"))
  fds.Hex(byte[slave.register][12],2)                                           ' retrieve register 12 from the slave and display on the serial terminal

                                                                                                                                                                                                                      
DAT                     org
Test_data               byte      $01,$23,$45,$67,$89,$AB,$CD,$EF

                        fit
     
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
