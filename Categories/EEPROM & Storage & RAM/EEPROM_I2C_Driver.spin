{{
OBEX LISTING:
  http://obex.parallax.com/object/419

  Full featured autopilot for boats, planes and rovers. Tested over 3 years. You can see the videos under Spiritplumber on youtube. This version does not contain the graphical console, but text i/o is possible and fairly easy to do.

  Other versions are maintained here http://robots-everywhere.com/portfolio/navcom_ai/ and may be downloaded there. If you intend to use this commercially, please see licensing information on that page.

  A note: It is possible to build functional drone bombers or similar with this. You the downloader are explicitly denied permission to do so. If you want to build autonomous weapons do your own homework, or better yet, go get your head examined.

  Videos of the drones in action!

  http://www.youtube.com/watch?v=5wJHj3hOcuI
  http://www.youtube.com/watch?v=diAZD68Y3Cw
  http://www.youtube.com/watch?v=AIbPvxf3hrk
  http://www.youtube.com/watch?v=en5TCSHZDyY
  http://www.youtube.com/watch?v=Dd1R-WeGWkU
  http://www.youtube.com/watch?v=9m6H5se6-nE
}}
'' Basic I2C Routines  Version 1.1
'' Written by Michael Green and copyright (©) 2007
'' Permission is given to use this in any program for the Parallax
'' Propeller processor as long as this copyright notice is included.

'' This is a minimal version of an I2C driver in SPIN.  It assumes
'' that the SDA pin is one higher than the SCL pin.  It assumes that
'' neither the SDA nor the SCL pins have pullups, so drives both.

'' These routines are primarily intended for reading and writing EEPROMs.
'' The low level I2C are provided for use with other devices, but the
'' read/write byte routines assume a standard I2C serial EEPROM with a
'' 16 bit device address register, paged writes, and acknowledge polling.

'' All of these read/write routines accept an EEPROM address up to 19
'' bits (512K) even though the EEPROM addressing scheme normally allows
'' for only 16 bits of addressing.  The upper 3 bits are used as part of
'' the device select code and these routines will take the upper 3 bits
'' of the address and "or" it with the supplied device select code bits
'' 3-1 which are used to select a particular EEPROM on an I2C bus.  There
'' are two schemes for selecting 64K "banks" in 128Kx8 EEPROMs.  Atmel's
'' 24LC1024 EEPROMs allow simple linear addressing up to 256Kx8 ($00000
'' to $3FFFF).  Microchip's 24LC1025 allows for up to 512Kx8, but in two
'' areas: $00000 to $3FFFF and $40000 to $7FFFF.  Each EEPROM provides
'' a 64K "bank" in each area.  See the device datasheets for details.

'' This will work with the boot EEPROM and does not require a pull-up
'' resistor on the SCL line (but does on the SDA line ... about 4.7K to
'' +3.3V).  According to the Philips I2C specification, both pull-ups
'' are required.  Many devices will tolerate the absence of a pull-up
'' on SCL.  Some may tolerate the absence of a pull-up on SDA as well.

'' Initialize may have to be called once at the beginning of your
'' program.  Sometimes an I2C device is left in an invalid state.  This
'' will reset the device to a known state so it will respond to the I2C
'' start transition (sent out by the i2cStart routine).

'' To read from or write to an EEPROM on pins 28/29 like the boot EEPROM:

'' CON
''   eepromAddress = $7000

'' VAR
''   byte buffer[32]

'' OBJ
''   i2c : "Minimal_I2C_Driver"

'' PRI readIt
''   if i2c.ReadPage(i2c#BootPin, i2c#EEPROM, eepromAddress, @buffer, 32)
''     abort ' an error occurred during the read

'' PRI writeIt | startTime
''   if i2c.WritePage(i2c#BootPin, i2c#EEPROM, eepromAddress, @buffer, 32)
''     abort ' an error occured during the write
''   startTime := cnt ' prepare to check for a timeout
''   repeat while i2c.WriteWait(i2c#BootPin, i2c#EEPROM, eepromAddress)
''     if cnt - startTime > clkfreq / 10
''       abort ' waited more than a 1/10 second for the write to finish

'' Note that the read and write use something called paged reads/writes.
'' This means that any read using ReadPage must fit entirely in one
'' EEPROM if you have several attached to one set of pins.  For writes,
'' any write using i2cWritePage must fit entirely within a page of the
'' EEPROM.  Usually these pages are either 32, 64, 128 or 256 bytes in
'' size depending on the manufacturer and device type.  32 bytes is a
'' good limit for the number of bytes to be written at a time if you
'' don't know the specific page size (and the write must fit completely
'' within a multiple of the page size).  The WriteWait waits for the
'' write operation to complete.  Alternatively, you could wait for 5ms
'' since currently produced EEPROMs will finish within that time.

CON
   ACK      = 0                        ' I2C Acknowledge
   NAK      = 1                        ' I2C No Acknowledge
   Xmit     = 0                        ' I2C Direction Transmit
   Recv     = 1                        ' I2C Direction Receive
   BootPin  = 28                       ' I2C Boot EEPROM SCL Pin
   BootPin2 = 29
   EEPROM   = $A0                      ' I2C EEPROM Device Address

CON
   StartAddr = l#EEPROMStart'$8000'000
   EndAddr = l#EEPROMEnd
   NumTries = 20

con   MaxStructs = (EndAddr - StartAddr)/StructLength
    ' do not modify this -- it makes waypoints wrap around just to be safe.

obj
   l : "NavAI_Lib"

var

'byte long[constant(l#SensorDataAddress  + l#32]
'long CurWaypointInBuffer   


PUB Initialize(SCL) | SDA              ' An I2C device may be left in an
   SDA := SCL + 1                      '  invalid state and may need to be
   outa[SCL] := 1                       '   reinitialized.  Drive SCL high.
   dira[SCL] := 1
   dira[SDA]~' := 0                       ' Set SDA as input
   repeat 9
      outa[SCL]~' := 0                    ' Put out up to 9 clock pulses
      outa[SCL] := 1
      if ina[SDA]                      ' Repeat if SDA not driven high
         quit                          '  by the EEPROM

PUB Start(SCL) | SDA                   ' SDA goes HIGH to LOW with SCL HIGH
   SDA := SCL + 1
   outa[SCL]~~                         ' Initially drive SCL HIGH
   dira[SCL]~~
   outa[SDA]~~                         ' Initially drive SDA HIGH
   dira[SDA]~~
   outa[SDA]~                          ' Now drive SDA LOW
   outa[SCL]~                          ' Leave SCL LOW
  
PUB Stop(SCL) | SDA                    ' SDA goes LOW to HIGH with SCL High
   SDA := SCL + 1
   outa[SCL]~~                         ' Drive SCL HIGH
   outa[SDA]~~                         '  then SDA HIGH
   dira[SCL]~                          ' Now let them float
   dira[SDA]~                          ' If pullups present, they'll stay HIGH

PUB Write(SCL, data) : ackbit | SDA
'' Write i2c data.  Data byte is output MSB first, SDA data line is valid
'' only while the SCL line is HIGH.  Data is always 8 bits (+ ACK/NAK).
'' SDA is assumed LOW and SCL and SDA are both left in the LOW state.
   SDA := SCL + 1
   ackbit := 0 
   data <<= 24
   repeat 8                            ' Output data to SDA
      outa[SDA] := (data <-= 1) & 1
      outa[SCL]~~                      ' Toggle SCL from LOW to HIGH to LOW
      outa[SCL]~
   dira[SDA]~                          ' Set SDA to input for ACK/NAK
   outa[SCL]~~
   ackbit := ina[SDA]                  ' Sample SDA when SCL is HIGH
   outa[SCL]~
   outa[SDA]~                          ' Leave SDA driven LOW
   dira[SDA]~~

PUB Read(SCL, ackbit): data | SDA
'' Read in i2c data, Data byte is output MSB first, SDA data line is
'' valid only while the SCL line is HIGH.  SCL and SDA left in LOW state.
   SDA := SCL + 1
   data := 0
   dira[SDA]~                          ' Make SDA an input
   repeat 8                            ' Receive data from SDA
      outa[SCL]~~                      ' Sample SDA when SCL is HIGH
      data := (data << 1) | ina[SDA]
      outa[SCL]~
   outa[SDA] := ackbit                 ' Output ACK/NAK to SDA
   dira[SDA]~~
   outa[SCL]~~                         ' Toggle SCL from LOW to HIGH to LOW
   outa[SCL]~
   outa[SDA]~                          ' Leave SDA driven LOW
{
PUB ReadPage(SCL, devSel, addrReg, dataPtr, count) : ackbit
'' Read in a block of i2c data.  Device select code is devSel.  Device starting
'' address is addrReg.  Data address is at dataPtr.  Number of bytes is count.
'' The device select code is modified using the upper 3 bits of the 19 bit addrReg.
'' Return zero if no errors or the acknowledge bits if an error occurred.
   devSel |= addrReg >> 15 & %1110
   Start(SCL)                          ' Select the device & send address
   ackbit := Write(SCL, devSel | Xmit)
   ackbit := (ackbit << 1) | Write(SCL, addrReg >> 8 & $FF)
   ackbit := (ackbit << 1) | Write(SCL, addrReg & $FF)          
   Start(SCL)                          ' Reselect the device for reading
   ackbit := (ackbit << 1) | Write(SCL, devSel | Recv)
   repeat count - 1
      byte[dataPtr++] := Read(SCL, ACK)
   byte[dataPtr++] := Read(SCL, NAK)
   Stop(SCL)
   return ackbit

PUB WritePage(SCL, devSel, addrReg, dataPtr, count) : ackbit
'' Write out a block of i2c data.  Device select code is devSel.  Device starting
'' address is addrReg.  Data address is at dataPtr.  Number of bytes is count.
'' The device select code is modified using the upper 3 bits of the 19 bit addrReg.
'' Most devices have a page size of at least 32 bytes, some as large as 256 bytes.
'' Return zero if no errors or the acknowledge bits if an error occurred.  If
'' more than 31 bytes are transmitted, the sign bit is "sticky" and is the
'' logical "or" of the acknowledge bits of any bytes past the 31st.
   devSel |= addrReg >> 15 & %1110
   Start(SCL)                          ' Select the device & send address
   ackbit := Write(SCL, devSel | Xmit)
   ackbit := (ackbit << 1) | Write(SCL, addrReg >> 8 & $FF)
   ackbit := (ackbit << 1) | Write(SCL, addrReg & $FF)          
   repeat count                        ' Now send the data
      ackbit := ackbit << 1 | ackbit & $80000000 ' "Sticky" sign bit         
      ackbit |= Write(SCL, byte[dataPtr++])
   Stop(SCL)
   return ackbit

   

PUB ReadByte(SCL, devSel, addrReg) : data
'' Read in a single byte of i2c data.  Device select code is devSel.  Device
'' starting address is addrReg.  The device select code is modified using the
'' upper 3 bits of the 19 bit addrReg.  This returns true if an error occurred.
   if ReadPage(SCL, devSel, addrReg, @data, 1)
      return -1

PUB ReadWord(SCL, devSel, addrReg) : data
'' Read in a single word of i2c data.  Device select code is devSel.  Device
'' starting address is addrReg.  The device select code is modified using the
'' upper 3 bits of the 19 bit addrReg.  This returns true if an error occurred.
   if ReadPage(SCL, devSel, addrReg, @data, 2)
      return -1

PUB ReadLong(SCL, devSel, addrReg) : data
'' Read in a single long of i2c data.  Device select code is devSel.  Device
'' starting address is addrReg.  The device select code is modified using the
'' upper 3 bits of the 19 bit addrReg.  This returns true if an error occurred.
'' Note that you can't distinguish between a return value of -1 and true error.
   if ReadPage(SCL, devSel, addrReg, @data, 4)
      return -1


PUB WriteByte(SCL, devSel, addrReg, data)
'' Write out a single byte of i2c data.  Device select code is devSel.  Device
'' starting address is addrReg.  The device select code is modified using the
'' upper 3 bits of the 19 bit addrReg.  This returns true if an error occurred.
   if WritePage(SCL, devSel, addrReg, @data, 1)
      return true
   return false

PUB WriteWord(SCL, devSel, addrReg, data)
'' Write out a single word of i2c data.  Device select code is devSel.  Device
'' starting address is addrReg.  The device select code is modified using the
'' upper 3 bits of the 19 bit addrReg.  This returns true if an error occurred.
'' Note that the word value may not span an EEPROM page boundary.
   if WritePage(SCL, devSel, addrReg, @data, 2)
      return true
   return false

PUB WriteLong(SCL, devSel, addrReg, data)
'' Write out a single long of i2c data.  Device select code is devSel.  Device
'' starting address is addrReg.  The device select code is modified using the
'' upper 3 bits of the 19 bit addrReg.  This returns true if an error occurred.
'' Note that the long word value may not span an EEPROM page boundary.
   if WritePage(SCL, devSel, addrReg, @data, 4)
      return true
   return false
}
PUB WriteWait(SCL, devSel, addrReg) : ackbit
'' Wait for a previous write to complete.  Device select code is devSel.  Device
'' starting address is addrReg.  The device will not respond if it is busy.
'' The device select code is modified using the upper 3 bits of the 18 bit addrReg.
'' This returns zero if no error occurred or one if the device didn't respond.
   devSel |= addrReg >> 15 & %1110
   Start(SCL)
   ackbit := Write(SCL, devSel | Xmit)
   Stop(SCL)
   return ackbit

PUB SkipWaypoint (num)  ' actually just sets waypoint same as next waypoint, so it gets skipped automatically
   if  long[constant(l#SensorDataAddress  + l#CurWaypointInBuffer)] <> num+1
       repeat while ReadStruct(num+1)
   return WriteStruct(num)    

PUB EraseWaypoint(num) ' mark waypoint as unused
    return WriteWaypoint(num, INVALIDCOORD, INVALIDCOORD)
PUB WriteWaypoint (num, lat, lon) | err' this writes the waypoint as would be written by the operator

'PUB WritePage(SCL, devSel, addrReg, dataPtr, count) : ackbit
'i2c.WritePage(i2c#BootPin, i2c#EEPROM, $8000, @gpsstring, 32))
'' Write out a block of i2c data.  Device select code is devSel.  Device starting
'' address is addrReg.  Data address is at dataPtr.  Number of bytes is count.
'' The device select code is modified using the upper 3 bits of the 19 bit addrReg.
'' Most devices have a page size of at least 32 bytes, some as large as 256 bytes.
'' Return zero if no errors or the acknowledge bits if an error occurred.  If
'' more than 31 bytes are transmitted, the sign bit is "sticky" and is the
'' logical "or" of the acknowledge bits of any bytes past the 31st.
   {
   if  CurWaypointInBuffer <> num
       repeat while ReadStruct(num)
   }
' these ALL get updated AT THE SAME TIME, I don't care what else happens!
   long[constant(l#SensorDataAddress  + l#WantedLat)]   := lat
   long[constant(l#SensorDataAddress  + l#WantedLon)]   := lon
   long[constant(l#SensorDataAddress  + l#ReachedTime)] := -1.0
   long[constant(l#SensorDataAddress  + l#ReachedLat)]  := INVALIDCOORD 
   long[constant(l#SensorDataAddress  + l#ReachedLon)]  := INVALIDCOORD 
   long[constant(l#SensorDataAddress  + l#ReachedAlt)]  := NaN
   long[constant(l#SensorDataAddress  + l#ReachedHdg)]  := INVALIDANGLE
   long[constant(l#SensorDataAddress  + l#ReachedDist)] := NaN
   long[constant(l#SensorDataAddress  + l#CurWaypointInBuffer)] := num

   return WriteStruct(num)                           

PUB LogWaypoint (num) | t' this writes the waypoint as seen and recorded

   if  long[constant(l#SensorDataAddress  + l#CurWaypointInBuffer)] <> num
        t~~
        repeat
           t := ReadStruct(num)
        while t

   ' to call this, COMPARE AGAINST DISTANCE!!!!!  GetWaypointData(num, i2c#ReachedDist)  

' these ALL get updated AT THE SAME TIME, I don't care what else happens!
   long[constant(l#SensorDataAddress  + l#CurWaypointInBuffer)] := num
'   long[constant(l#SensorDataAddress  + l#WantedLat)]   := long[constant(l#SensorDataAddress  + l#WantedLat)]
'   long[constant(l#SensorDataAddress  + l#WantedLon)]   := long[constant(l#SensorDataAddress  + l#WantedLon)]
   long[constant(l#SensorDataAddress  + l#ReachedTime)] := long[constant(l#SensorDataAddress  + l#GPSTime)]
   long[constant(l#SensorDataAddress  + l#ReachedLat)]  := long[constant(l#SensorDataAddress  + l#lat)] 
   long[constant(l#SensorDataAddress  + l#ReachedLon)]  := long[constant(l#SensorDataAddress  + l#lon)] 
   long[constant(l#SensorDataAddress  + l#ReachedAlt)]  := long[constant(l#SensorDataAddress  + l#alt)]
   long[constant(l#SensorDataAddress  + l#ReachedHdg)]  := long[constant(l#SensorDataAddress  + l#heading)]
   long[constant(l#SensorDataAddress  + l#ReachedDist)] := long[constant(l#SensorDataAddress  + l#distance)]

   return WriteStruct(num)

pub PreloadWaypoint(num)
    if  long[constant(l#SensorDataAddress  + l#CurWaypointInBuffer)] <> num
        repeat while ReadStruct(num)

PUB GetWaypointData(num,item) |t, timeout             ' invoke example: GetWaypointData(1,i2c#WantedLat)
    if  long[constant(l#SensorDataAddress  + l#CurWaypointInBuffer)] <> num
        t~~
        timeout~
        repeat 
           t := ReadStruct(num)
           if (timeout++ > NumTries)
               return -0.0
        while t
    return long[constant(l#SensorDataAddress  + l#WantedLat) + item]

PUB GetWaypointLat(num)
    return GetWaypointData(num, WantedLat)

PUB GetWaypointLon(num)
    return GetWaypointData(num, WantedLon)

PUB WaypointVisited(num) 


    if (GetWaypointData(num, ReachedLat) == INVALIDCOORD) or (GetWaypointData(num, ReachedLon) == INVALIDCOORD)
       return false
    return true   


{
PUB GetWaypointTime(num)
    return GetWaypointData(num, ReachedTime)

PUB GetWaypointRLat(num)
    return GetWaypointData(num, ReachedLat)

PUB GetWaypointRLon(num)
    return GetWaypointData(num, ReachedLon)

PUB GetWaypointRAlt(num)
    return GetWaypointData(num, ReachedAlt)

PUB GetWaypointRHdg(num)
    return GetWaypointData(num, ReachedHdg)

PUB GetWaypointDist(num)
    return GetWaypointData(num, ReachedDist)
}

pub WriteStruct(slot) : ackbit | addr 

    addr := StartAddr + ((slot // MaxStructs) * StructLength) ' if we were about to go past the end of memory, wrap around so we always return something useful

    ackbit~~' := WritePage(BootPin, EEPROM, addr, constant(l#SensorDataAddress + l#WantedLat), StructLength) 
    long[constant(l#SensorDataAddress  + l#CurWaypointInBuffer)] := slot
    repeat
       ackbit := WritePage(BootPin, EEPROM, addr, constant(l#SensorDataAddress + l#WantedLat), StructLength) 
    while ackbit

{
   devSel := EEPROM
   addrReg := StartAddr + (slot*StructLength)

   devSel |= addrReg >> 15 & %1110
   Start(BootPin)                          ' Select the device & send address
   ackbit := Write(BootPin, devSel | Xmit)
   ackbit := (ackbit << 1) | Write(BootPin, addrReg >> 8 & $FF)
   ackbit := (ackbit << 1) | Write(BootPin, addrReg & $FF)          
   c~
   repeat StructLength                        ' Now send the data
      ackbit := ackbit << 1 | ackbit & $80000000 ' "Sticky" sign bit         
      ackbit |= Write(BootPin, byte[constant(l#SensorDataAddress + l#WantedLat) + c++])
   Stop(BootPin)

   long[constant(l#SensorDataAddress  + l#CurWaypointInBuffer)] := slot

   
   return ackbit
}
PUB ReadStruct(slot) : ackbit | addr

    addr := StartAddr + ((slot // MaxStructs) * StructLength)  ' if we were about to go past the end of memory, wrap around so we always return something useful

    ackbit := ReadPage(BootPin, EEPROM, addr, constant(l#SensorDataAddress + l#WantedLat), StructLength) 
    long[constant(l#SensorDataAddress  + l#CurWaypointInBuffer)] := slot

{

   devSel := EEPROM
   addrReg := StartAddr + (slot*StructLength)

   devSel |= addrReg >> 15 & %1110
   Start(BootPin)                          ' Select the device & send address
   ackbit := Write(BootPin, devSel | Xmit)
   ackbit := (ackbit << 1) | Write(BootPin, addrReg >> 8 & $FF)
   ackbit := (ackbit << 1) | Write(BootPin, addrReg & $FF)          
   Start(BootPin)                          ' Reselect the device for reading
   ackbit := (ackbit << 1) | Write(BootPin, devSel | Recv)
   c~
   repeat constant(StructLength - 1)
      byte[constant(l#SensorDataAddress + l#WantedLat) + c++] := Read(BootPin, ACK)
   byte[constant(l#SensorDataAddress + l#WantedLat) + c] := Read(BootPin, NAK)
   Stop(BootPin)

   long[constant(l#SensorDataAddress  + l#CurWaypointInBuffer)] := slot

   return ackbit

}   

PUB ReadPage(SCL, devSel, addrReg, dataPtr, count) : ackbit
'' Read in a block of i2c data.  Device select code is devSel.  Device starting
'' address is addrReg.  Data address is at dataPtr.  Number of bytes is count.
'' The device select code is modified using the upper 3 bits of the 19 bit addrReg.
'' Return zero if no errors or the acknowledge bits if an error occurred.
   devSel |= addrReg >> 15 & %1110
   Start(SCL)                          ' Select the device & send address
   ackbit := Write(SCL, devSel | Xmit)
   ackbit := (ackbit << 1) | Write(SCL, addrReg >> 8 & $FF)
   ackbit := (ackbit << 1) | Write(SCL, addrReg & $FF)          
   Start(SCL)                          ' Reselect the device for reading
   ackbit := (ackbit << 1) | Write(SCL, devSel | Recv)
   repeat count - 1
      byte[dataPtr++] := Read(SCL, ACK)
   byte[dataPtr++] := Read(SCL, NAK)
   Stop(SCL)
   return ackbit

PUB WritePage(SCL, devSel, addrReg, dataPtr, count) : ackbit
'' Write out a block of i2c data.  Device select code is devSel.  Device starting
'' address is addrReg.  Data address is at dataPtr.  Number of bytes is count.
'' The device select code is modified using the upper 3 bits of the 19 bit addrReg.
'' Most devices have a page size of at least 32 bytes, some as large as 256 bytes.
'' Return zero if no errors or the acknowledge bits if an error occurred.  If
'' more than 31 bytes are transmitted, the sign bit is "sticky" and is the
'' logical "or" of the acknowledge bits of any bytes past the 31st.
   devSel |= addrReg >> 15 & %1110
   Start(SCL)                          ' Select the device & send address
   ackbit := Write(SCL, devSel | Xmit)
   ackbit := (ackbit << 1) | Write(SCL, addrReg >> 8 & $FF)
   ackbit := (ackbit << 1) | Write(SCL, addrReg & $FF)          
   repeat count                        ' Now send the data
      ackbit := ackbit << 1 | ackbit & $80000000 ' "Sticky" sign bit         
      ackbit |= Write(SCL, byte[dataPtr++])
   Stop(SCL)
   return ackbit

   
con
        NaN             =       $7FFF_FFFF ' used to mean invalid value in floating point
        INVALIDANGLE    =       400.0 ' i.e. more than 360
        INVALIDCOORD    =       2147483647 ' invalid coordinate obviously (as in, more than 180degs)


con

' waypoint structure

StructLength = 32

WantedLat = 0
WantedLon = 4
ReachedTime = 8
ReachedLat = 12
ReachedLon = 16
ReachedAlt = 20
ReachedHdg = 24
ReachedDist = 28

{
4       long    latitude (wished): invalid coord means waypoint not used
4       long    longitude (wished): invalid coord means waypoint not used
4       float   UTC time waypoint touched: negative means not touched, used to check for bogus data
4       long    latitude (reached)
4       long    longitude (reached)
4       float   altitude/depth(reached)
4       float   heading waypoint was touched at (use for error estimate)
4       float   distance waypoint was touched at (use for error estimate)
--------
32 bytes
}
