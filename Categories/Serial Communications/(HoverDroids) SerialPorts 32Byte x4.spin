{{

======================================================================

  Copyright (C) 2016 - 2019 HoverDroids(TM)

  Licensed under the Creative Commons Attribution-ShareAlike
  International License, Version 4.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://creativecommons.org/licenses/by-sa/4.0/legalcode

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

======================================================================

   File...... (HoverDroids) SerialPorts 32Byte x4.spin
   Purpose... Provide full duplex serial communications for 1 to 4 serial ports, in a more
              or less transparent way, so you have COM0 to COM3 to deal with instead.

   Author.... Chris Sprague
   E-mail.... HoverDroids@gmail.com

   Version History
   1.0          01 10 2019

======================================================================
Derived from
----------------------------------------------------------------------
  (REF1)  TwelveSerialPorts32

  References are noted with the following format:

  [X]REF1 [ ]REF3               A version of the method is in found in
                                REF1 & REF3. The REF1 is used instead.
  [+]REF3                       REF3 has added this line vs other versions
  [-]REF1                       REF1 has removed this line vs other versions
  [M]REF1                       REF1 has modified this line vs other versions

----------------------------------------------------------------------
Program Description
----------------------------------------------------------------------
  COGS  USED:   1
  CTRAs USED:   TODO
  CTRBs USED:   TODO
  Stack Size:   TODO
  RX Buffer :   32Byte
  TX Buffer :   16Byte

  Provide full duplex serial communications for 1 to 4 serial ports, in a more
  or less transparent way, so you have COM0 to COM3 to deal with instead.

  This differs from REF1 in formatting, OBJ reference naming, and reduction of
  ports from 12 to 4. Use any of the following objects for a different number
  of ports and buffer sizes (as well as # of cogs required):
        1COG                       2COGs                      3COGs
        - SerialPorts 32Byte x4    - SerialPorts 32Byte x8    - SerialPorts 32Byte x12
        - SerialPorts 128Byte x4   - SerialPorts 128Byte x8   - SerialPorts 128Byte x12
        - SerialPorts 512Byte x4   - SerialPorts 512Byte x8   - SerialPorts 512Byte x12
----------------------------------------------------------------------
Usage
----------------------------------------------------------------------
  To use this object in your code, declare it as shown below:

  OBJ
  terminal: "(HoverDroids) SerialPorts 32Byte x4"

  SomeMethod
  terminal.objMethod(input1,...,inputN)

----------------------------------------------------------------------
Usage Notes
----------------------------------------------------------------------
  It is highly recommend that Brad's Spin Tool (BST) is used as the IDE
  when using the HoverDroids library objects. This is because it provides
  an option for removing unused methods at compile time in order to reduce
  the size of the binary file. This can be done by:

  Tools->Compiler Preferences->Eliminate Unused Spin Methods

  When using this object, BST, and eliminating unused spin methods, ensure
  that your code calls at least one method in this object or else errors
  will be thrown at compile time.

  The Propeller Tool is not recommended when using the HoverDroids library
  objects because it doesn't provide the optimization mentioned above.
  Hence, this aggregation of code will certainly increase the size of your
  binary to an unnecessary degree.

----------------------------------------------------------------------
Notes from REF1: TwelveSerialPorts32
----------------------------------------------------------------------
  This deals with having 3 cogs connected to 4 serial ports each in a more or less
  transparent way, so you have COM0 to COM3 to deal with instead.

}}

CON
  SECONDARY_BUFFER_SIZE = 256

OBJ
  com0:"SerialPortBank0"

VAR
  long bb

PUB AddPortNoHandshake(port,rxpin,txpin,mode,baudrate) ' for compatibility with fullduplexserial
  return AddPort(port,rxpin,txpin,-1,-1,0,mode,baudrate)

PUB AddPort(port,rxpin,txpin,ctspin,rtspin,rtsthreshold,mode,baudrate)
    bb := (port >> 2)
  if (bb == 0)
    return com0.AddPort((port & 3),rxpin,txpin,ctspin,rtspin,rtsthreshold,mode,baudrate)
  else
    return -1

PUB Start
  result:=com0.start
  result*=10

PUB Stop
  com0.stop

PUB getCogID(port)
  bb := (port >> 2)
  if bb == 0
    return com0.getCogID
  else
    return com2.getCogID

PUB rxflush(port)
  bb := (port >> 2)
  if bb == 0
    return com0.rxflush((port & 3))
  else
    return -1

PUB rxcheck(port) : rxbyte
  bb := (port >> 2)
  if bb == 0
    return com0.rxcheck((port & 3))
  else
    return -1

PUB rxtime(port,ms) : rxbyte 
  bb := (port >> 2)
  if bb == 0
    return com0.rxtime((port & 3),ms)
  else
    return -1

PUB rx(port) : rxbyte
  bb := (port >> 2)
  if bb == 0
    return com0.rx((port & 3))
  else
    return -1

PUB tx(port,txbyte)
  bb := (port >> 2)
  if bb == 0
    return com0.tx((port & 3),txbyte)
  else
    return -1

PUB txflush(port)
  bb := (port >> 2)
  if bb == 0
    return com0.txflush((port & 3))
  else
    return -1

PUB str(port,stringptr)
  bb := (port >> 2)
  if bb == 0
    return com0.str((port & 3),stringptr)
  else
    return -1

PUB dec(port,value) 
  bb := (port >> 2)
  if bb == 0
    return com0.dec((port & 3),value)
  else
    return -1

PUB hex(port,value, digits)
  bb := (port >> 2)
  if bb == 0
    return com0.hex((port & 3),value,digits)
  else
    return -1

PUB bin(port,value, digits)
  bb := (port >> 2)
  if bb == 0
    return com0.bin((port & 3),value,digits)
  else
    return -1

PUB newline(port)
  bb := (port >> 2)
  if bb == 0
    return com0.str((port & 3),@crlf)
  else
    return -1

dat
crlf byte 13,10,0
