{{
OBEX LISTING:
  http://obex.parallax.com/object/700

  Includes Spin-based and PASM-based open-drain and push-pull drivers, with methods for reading and writing any number of bytes, words, and longs in big-endian or little-endian format.  All drivers tested with the 24LC256 EEPROM, DS1307 real time clock, MMA7455L 3-axis accelerometer, L3G4200D gyroscope module, MS5607 altimeter module, and BMP085 pressure sensor.  Includes a demo programs for each.

  Also includes a polling routine that displays the device address and name of everything on the I2C bus.

  Also includes a slave object that runs in a PASM cog with a Spin handler, and provides 32 byte-sized registers for a master running on another device to write to and read from.  Tested okay up to 1Mbps (max speed of my PASM push-pull object).  Includes demo for the slave object.

  Newly added multi-master object that can share the bus with other masters, provided of course that the other masters also allow sharing.
}}
{{┌──────────────────────────────────────────┐
  │ I2C push-pull SPIN driver           1.4pp│      This routine does not require the use of pull-up resistors on the SDA and SCL lines      
  │ Author: Chris Gadd                       │      Does not support clock-stretching by slave devices                                       
  │ Copyright (c) 2015 Chris Gadd            │      Runs entirely in SPIN                                                                    
  │ See end of file for terms of use.        │      Approximately 28Kbps                                                                     
  └──────────────────────────────────────────┘

  PUB methods:
    start(SCL,SDA)                                                    ' Start the I2C driver 
    stop
    write(DeviceID,RegisterAddress,SourceAddress,Number,Endian,Size)  ' Master method for all writes
     writeByte   (DeviceID,RegisterAddress,Data)                      '  Write a single byte
     writeWordL             "                                         '  Write a single little-endian word
     writeWordB             "                                         '  Write a single big-endian word
     writeLongL             "                                         '  Write a single little-endinal long
     writeLongB             "                                         '  write a single big-endian long
     writeBytes  (DeviceID,RegisterAddress,SourceAddress,Number)      '  Write many bytes
     writeWordsL            "                                         '  Write many little-endian words
     writeWordsB            "                                         '  Write many big-endian words
     writeLongsL            "                                         '  Write many little-endian longs
     writeLongsB            "                                         '  Write many big-endian longs
    read(DeviceID,RegisterAddress,DestAddress,Number,Endian,Size)     ' Master method for all reads
     readByte    (DeviceID,RegisterAddress)                           '  Read a single byte
     readWordL              "                                         '  Read a single little-endian word 
     readWordB              "                                         '  Read a single big-endian word    
     readLongL              "                                         '  Read a single little-endinal long
     readLongB              "                                         '  Read a single big-endian long
     readBytes   (DeviceID,RegisterAddress,DestAddress,Number)        '  Read many bytes                         
     readWordsL             "                                         '  Read many little-endian words           
     readWordsB             "                                         '  Read many big-endian words              
     readLongsL             "                                         '  Read many little-endian longs           
     readLongsB             "                                         '  Read many big-endian longs              

    arbitrary(Out_address,Out_count,In_address,In_count)              ' General purpose method for edge-cases - bytes are sent exactly as they're entered into the out_buffer
     readNext(DeviceID)                                               '  Send the deviceID with the read bit set, and return 1 byte
     command(DeviceID,command)                                        '  Send the deviceID and a single byte instruction, specifically for use with pressure sensors
     
    This routine performs ACK polling to determine when a device is ready.
    Routine will abort a transmission if no ACK is received within 10ms of polling - prevents I2C routine from stalling if a device becomes disconnected
    No other ACK testing is performed                                                                           ┌──────────────────────────────────────────┐
    All write methods return true if the operation was successful, false if no response                         │ if not I2C.writeByte(EEPROM,$0123,$01)   │
     -reads return the requested value                                                                          │   FDS.str(string("EEPROM not present"))  │
                                                                                                                └──────────────────────────────────────────┘
    This routine automatically uses two bytes when addressing an EEPROM.  The EEPROM is the only device, so far discovered, that uses two-byte addresses.
                 
}}                                                                                                                                                
CON
' Device codes
' Requires the un-shifted 7-bit device address.  The driver shifts the address and appends the read / write bit

  EEPROM = %101_0000            ' Device code for 24LC256 EEPROM with all chip select pins tied to ground
  RTC    = %110_1000            ' Device code for DS1307 real time clock
  ACC    = %001_1101            ' Device code for MMA7455L 3-axis accelerometer
  GYRO   = %110_1001            ' Device code for L3G4200D gyroscope (SDO to Vdd)
  ALT    = %111_0110            ' Device code for MS5607 altimeter (CS floating)

  _LITTLE = 0
  _BIG    = 1
  _BYTE   = 1
  _WORD   = 2
  _LONG   = 4
                                    
VAR
  byte  scl
  byte  sda

PUB init(clk_pin, data_pin) 
  scl := clk_pin
  sda := data_pin
  outa[sda] := 1
  dira[sda] := 1
  outa[scl] := 1
  dira[scl] := 1

PUB write(deviceID,registerAddress,dataAddress,number,endian,type) | temp     '' Write any number of big or little-endian bytes, words, or longs
  if send_start(deviceID,registerAddress)
    if type == _BYTE                                                                                                             
      endian := _LITTLE                                                                                                          
    repeat number                                                                                                                
      if number == 1                                                                                                             
        temp := dataAddress                                                     '  Use the immediate value for single writes     
      else                                                                                                                       
        case type                                                                                                                
          _LONG : temp := long[dataAddress]                                     '  Otherwise use the value from an array         
          _WORD : temp := word[dataAddress]                                                                                      
          _BYTE : temp := byte[dataAddress]
        dataAddress += type                                                     '    big-word       big-long     little-word   little-long
      if type == _WORD and endian == _BIG                                       '  $00_00_12_34   $12_34_56_78  $00_00_43_12  $78_56_34_12
        temp <<= 16                                                             '  $12_34_00_00                                  
      repeat type                                                                                                                
        if endian == _LITTLE                                                                                                     
          I2C_write(temp)                                                                                                        
          temp >>= 8                                                                                                             
        else 'endian == _BIG                                                                                                     
          temp <-= 8                                                            '  $34_00_00_12   $34_56_78_12                   
          I2C_write(temp)
    I2C_stop
    return true                                                                                         

PUB writeByte(deviceID,registerAddress,data)                                    '' Write a single byte from an immediate value
  return write(deviceID,registerAddress,data,1,_LITTLE,_BYTE)
  
PUB writeBytes(deviceID,registerAddress,dataAddress,number)                     '' Write many bytes from an array
  return write(deviceID,registerAddress,dataAddress,number,_LITTLE,_BYTE)

PUB writeWordL(deviceID,registerAddress,data)                                   '' Write a single little-endian word      
  return write(deviceID,registerAddress,data,1,_LITTLE,_WORD)                                                                                
                                                                                                                          
PUB writeWordB(deviceID,registerAddress,data)                                   '' Write a single big-endian word         
  return write(deviceID,registerAddress,data,1,_BIG,_WORD)                                                                                
                                                                                                                          
PUB writeWordsL(deviceID,registerAddress,dataAddress,number)                    '' Write many little-endian words         
  return write(deviceID,registerAddress,dataAddress,number,_LITTLE,_WORD)                                                                                
                                                                                                                          
PUB writeWordsB(deviceID,registerAddress,dataAddress,number)                    '' Write many big-endian words            
  return write(deviceID,registerAddress,dataAddress,number,_BIG,_WORD)                                                                                
                                                                                                                          
PUB writeLongL(deviceID,registerAddress,data)                                   '' Write a single little-endian long      
  return write(deviceID,registerAddress,data,1,_LITTLE,_LONG)                                                                                
                                                                                                                          
PUB writeLongB(deviceID,registerAddress,data)                                   '' Write a single big-endian long         
  return write(deviceID,registerAddress,data,1,_BIG,_LONG)                                                                                
                                                                                                                          
PUB writeLongsL(deviceID,registerAddress,dataAddress,number)                    '' Write many little-endian longs         
  return write(deviceID,registerAddress,dataAddress,number,_LITTLE,_LONG)                                                                                
                                                                                                                          
PUB writeLongsB(deviceID,registerAddress,dataAddress,number)                    '' Write many big-endian longs            
  return write(deviceID,registerAddress,dataAddress,number,_BIG,_LONG)                                                                                

PUB read(deviceID,registerAddress,dataAddress,number,endian,type) | temp, count '' Read any number of big or little-endian bytes, words, or longs
  count := number * type
  if send_start(deviceID,registerAddress)
    I2C_start
    I2C_write(deviceID << 1 | 1)
    repeat number                                                               '  Loop for all bytes, words, or longs
      temp := 0
      repeat type                                                               '  Loop for all byte in a word or a long
        if endian == _BIG
          temp := temp << 8 | I2C_read                                          '  Read big-endians by shifting left
        else
          temp := I2C_read | temp -> 8                                          '  Read little-endians by rotating right
        if --count
          I2C_ack                                                               '  Send an ack if more bytes are to be read
        else
          I2C_nak                                                               '  Otherwise send a nak to stop reading
      if endian == _LITTLE and type == _LONG
        temp ->= 8                                                              '  Final shift for little-endians
      elseif endian == _LITTLE and type == _WORD
        temp <-= 8
      if number == 1
        result := temp                                                          '  Return an immediate result for single reads
      else
        case type
          _LONG : long[dataAddress] := temp                                     '  Store value in an array for multiple reads
          _WORD : word[dataAddress] := temp
          _BYTE : byte[dataAddress] := temp
        dataAddress += type
    I2C_stop
      
PUB readByte(deviceID,registerAddress)                                          '' Read a single byte and return an immediate result
  return read(deviceID,registerAddress,0,1,_LITTLE,_BYTE)
  
PUB readBytes(deviceID,registerAddress,dataAddress,number)                      '' Read many bytes and store in an array
  read(deviceID,registerAddress,dataAddress,number,_LITTLE,_BYTE)

PUB readWordL(deviceID,registerAddress)                                         '' Read a single little-endian word
  return read(deviceID,registerAddress,0,1,_LITTLE,_WORD)

PUB readWordB(deviceID,registerAddress)                                         '' Read a single big-endian word
  return read(deviceID,registerAddress,0,1,_BIG,_WORD)

PUB readWordsL(deviceID,registerAddress,dataAddress,number)                     '' Read many little-endian words
  read(deviceID,registerAddress,dataAddress,number,_LITTLE,_WORD)
  
PUB readWordsB(deviceID,registerAddress,dataAddress,number)                     '' Read many big-endian words
  read(deviceID,registerAddress,dataAddress,number,_BIG,_WORD)
  
PUB readLongL(deviceID,registerAddress)                                         '' Read a single little-endian long
  return read(deviceID,registerAddress,0,1,_LITTLE,_LONG)

PUB readLongB(deviceID,registerAddress)                                         '' Read a single big-endian long
  return read(deviceID,registerAddress,0,1,_BIG,_LONG)

PUB readLongsL(deviceID,registerAddress,dataAddress,number)                     '' Read many little-endian longs
  read(deviceID,registerAddress,dataAddress,number,_LITTLE,_LONG)
  
PUB readLongsB(deviceID,registerAddress,dataAddress,number)                     '' Read many big-endian longs
  read(deviceID,registerAddress,dataAddress,number,_BIG,_LONG)

PUB arbitrary(out_address,out_count,in_address,in_count) | nak, t               '' Sends bytes exactly as they're entered into the out_address array
                                                                                '  If sending a device address, it must be shifted to 8 bits and a read/write bit appended  
  if out_count                                                                  
    nak := 1
    t := cnt + clkfreq / 100
    repeat while nak                                                            '  Perform ack-polling
      if cnt - t > 0
        abort false
      I2C_start
      nak := I2C_write(byte[out_address])
  repeat out_count - 1
    I2C_write(byte[++out_address])
  repeat in_count                                                               
    byte[in_address++] := I2C_read                                              
    if in_count-- > 1                                                           
      I2C_ack                                                                  
    else                                    
      I2C_nak                               
  I2C_stop
  return true                 
  
PUB command(device,comm)                                                        '' Write the deviceID and a single command byte.  Specifically used in pressures sensors
  send_start(device,comm)                                                       '  Send a start bit, device ID, and command
  I2C_stop                                                                      '  Send a stop bit
  return true
  
PUB readNext(device)                                                            '' Read the next byte.  Sends the Device ID with read bit set and returns one byte      
  I2C_start                                                                     
  I2C_write(device << 1 | 1)                                                    
  result := I2C_read                                                            
  I2C_nak                                                                       
  I2C_stop                                                                      

PRI send_start (device, address) | nak, t                                       '' Send a start bit, device ID with read/write, and the register address, performs ack polling

  nak := 1
  t := cnt                                                                      ' t is used to detect a timeout

  repeat while nak                                                              ' Perform ack-polling                                     
    if cnt - t > clkfreq / 100                                                  ' Check timeout
      abort false                                                               ' abort after 10ms if no ack is received 
    I2C_start                                                                   ' Send start bit and device ID                                                                                                                   
    nak := I2C_write(device << 1)                                               ' I2C_write method returns true if nak
' if device & %1111_1000 == EEPROM                                              ' This interferes with the ADXL345 alternate address of $53                                              
  if device == EEPROM                                              
    I2C_write(address >> 8)                                                     ' Send two register bytes if addressing an EEPROM at address $50 only
  I2C_write(address)
  return true
  
PRI I2C_start                                                                   '' Send a start bit
  outa[scl] := 1                                                                '  SCL               
  outa[sda] := 1                                                                '  SDA                 
  dira[sda] := 1                                                                                             
  outa[sda] := 0
  outa[scl] := 0

PRI I2C_write(data)                                                             '' Write one byte, returns ack(0)/nak(1)
                                                                                '    (Write)      (Read ACK or NAK)
  data <<= 24                                                                   '                                
  repeat 8                                                                      '  SCL             
    outa[sda] := data <-= 1                                                     '  SDA  ───────           
    outa[scl] := 1                                                                                                 
    outa[scl] := 0                                                                                             
                            
  dira[sda] := 0            
  outa[scl] := 1            
  result := ina[sda]                                                            ' result is true if NAK   
  outa[scl] := 0                                                               
  dira[sda] := 1                                                                
  
PRI I2C_read                                                                    '' Read one byte
  dira[sda] := 0                                                                '       (Read)     
  repeat 8                                                                      '                 
    outa[scl] := 1                                                              '  SCL     
    result := result << 1 | ina[sda]                                            '  SDA ───────    
    outa[scl] := 0                                                              ' return the read byte as result
    
PRI I2C_ack                                                                     '' Send an ack bit      
  dira[sda] := 1                                                                '  SCL  
  outa[sda] := 0                                                                '  SDA  
  outa[scl] := 1     
  outa[scl] := 0     

PRI I2C_nak                                                                     '' Send a nak bit
  outa[sda] := 1                                                                '  SCL 
  dira[sda] := 1                                                                '  SDA 
  outa[scl] := 1  
  outa[scl] := 0  

PUB I2C_stop                                                                    '' Send a stop bit
  outa[sda] := 0                                                                '  SCL 
  outa[scl] := 1                                                                '  SDA 
  outa[sda] := 1 
                                                                                
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
