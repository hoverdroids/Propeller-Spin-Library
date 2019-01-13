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

   File         (HoverDroids) SerialPorts 32Byte x8.spin
   Author       Chris Sprague
   E-mail       HoverDroids@gmail.com
   Website      HoverDroids.com

   Brief Description:
     Provide full duplex serial communications for 1 to 8 serial ports, in a more
     or less transparent way, so you have COM0 to COM7 to deal with instead.

   Version History
   1.0          01 10 2019

======================================================================
Derived from
----------------------------------------------------------------------
  (REF1)  TwelveSerialPorts32
  (REF2)  SerialPortBank0/1/2
  References are noted with the following format:

  [X]REF1 [ ]REF3               A version of the method is in found in
                                REF1 & REF3. The REF1 is used instead.
  [+]REF3                       REF3 has added this line vs other versions
  [-]REF1                       REF1 has removed this line vs other versions
  [M]REF1                       REF1 has modified this line vs other versions

----------------------------------------------------------------------
Description
----------------------------------------------------------------------
  COGS  USED:   2
  CTRAs USED:   TODO
  CTRBs USED:   TODO
  Stack Size:   TODO
  RX Buffer :   32Byte
  TX Buffer :   16Byte

  Baud rates per port in each COG:
  1 port up to 750kbps
  2 port up to 230kbps
  3 port up to 140kbps
  4 port up to 100kbps          Tested 4 ports to 115Kbps with 6MHz crystal

  Provide full duplex serial communications for 1 to 8 serial ports, in a more
  or less transparent way, so you have COM0 to COM7 to deal with instead.

  This is merely a wrapper for several "SerialPorts PByte Banks M-N" objects.

  This differs from REF1 in formatting, OBJ reference naming, and reduction of
  ports from 12 to 8. Use any of the following objects for a different number
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
  terminal: "(HoverDroids) SerialPorts 32Byte x8"

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
  com0:"(HoverDroids) SerialPorts 32Byte Banks 0-3"
  com1:"(HoverDroids) SerialPorts 32Byte Banks 4-7"

VAR
  long bb

PUB AddPortNoHandshake(port,rxpin,txpin,mode,baudrate)  'REF1
{ Method Info in (HoverDroids) SerialPorts PByte Banks M-N }
  return AddPort(port,rxpin,txpin,-1,-1,0,mode,baudrate)

PUB AddPort(port,rxpin,txpin,ctspin,rtspin,rtsthreshold,mode,baudrate)  'REF1
{ Method Info in (HoverDroids) SerialPorts PByte Banks M-N }
  bb := (port >> 2)
  if (bb == 0)
    return com0.AddPort((port & 3),rxpin,txpin,ctspin,rtspin,rtsthreshold,mode,baudrate)
  if bb == 1
    return com1.AddPort((port & 3),rxpin,txpin,ctspin,rtspin,rtsthreshold,mode,baudrate)

PUB Start  'REF1
{ Method Info in (HoverDroids) SerialPorts PByte Banks M-N }
  result:=com0.start
  result*=10
  result+=com1.start

PUB Stop  'REF1
{ Method Info in (HoverDroids) SerialPorts PByte Banks M-N }
  com0.stop
  com1.stop

PUB getCogID(port)  'REF1
{ Method Info in (HoverDroids) SerialPorts PByte Banks M-N }
  bb := (port >> 2)
  if bb == 0
    return com0.getCogID
  if bb == 1
    return com1.getCogID

PUB rxflush(port)  'REF1
{ Method Info in (HoverDroids) SerialPorts PByte Banks M-N }
  bb := (port >> 2)
  if bb == 0
    return com0.rxflush((port & 3))
  if bb == 1
    return com1.rxflush((port & 3))

PUB rxcheck(port) : rxbyte  'REF1
{ Method Info in (HoverDroids) SerialPorts PByte Banks M-N }
  bb := (port >> 2)
  if bb == 0
    return com0.rxcheck((port & 3))
  if bb == 1
    return com1.rxcheck((port & 3))

PUB rxtime(port,ms) : rxbyte  'REF1
{ Method Info in (HoverDroids) SerialPorts PByte Banks M-N }
  bb := (port >> 2)
  if bb == 0
    return com0.rxtime((port & 3),ms)
  if bb == 1
    return com1.rxtime((port & 3),ms)

PUB rx(port) : rxbyte  'REF1
{ Method Info in (HoverDroids) SerialPorts PByte Banks M-N }
  bb := (port >> 2)
  if bb == 0
    return com0.rx((port & 3))
  if bb == 1
    return com1.rx((port & 3))

PUB tx(port,txbyte)  'REF1
{ Method Info in (HoverDroids) SerialPorts PByte Banks M-N }
  bb := (port >> 2)
  if bb == 0
    return com0.tx((port & 3),txbyte)
  if bb == 1
    return com1.tx((port & 3),txbyte)

PUB txflush(port)  'REF1
{ Method Info in (HoverDroids) SerialPorts PByte Banks M-N }
  bb := (port >> 2)
  if bb == 0
    return com0.txflush((port & 3))
  if bb == 1
    return com1.txflush((port & 3))

PUB str(port,strAddr)  'REF1
{ Method Info in (HoverDroids) SerialPorts PByte Banks M-N }
  bb := (port >> 2)
  if bb == 0
    return com0.str((port & 3),strAddr)
  if bb == 1
    return com1.str((port & 3),strAddr)

PUB strln(port,strAddr)  'REF2
{ Method Info in (HoverDroids) SerialPorts PByte Banks M-N }
  bb := (port >> 2)
  if bb == 0
    return com0.strln((port & 3),strAddr)
  if bb == 1
    return com1.strln((port & 3),strAddr)

PUB dec(port,value)  'REF1
{ Method Info in (HoverDroids) SerialPorts PByte Banks M-N }
  bb := (port >> 2)
  if bb == 0
    return com0.dec((port & 3),value)
  if bb == 1
    return com1.dec((port & 3),value)

PUB decx(port,value, digits) | i  'REF2
{ Method Info in (HoverDroids) SerialPorts PByte Banks M-N }
  bb := (port >> 2)
  if bb == 0
    return com0.decx((port & 3),value)
  if bb == 1
    return com1.decx((port & 3),value)

PUB decl(port,value,digits,flag) | i, x  'REF2
{ Method Info in (HoverDroids) SerialPorts PByte Banks M-N }
  bb := (port >> 2)
  if bb == 0
    return com0.decl((port & 3),value)
  if bb == 1
    return com1.decl((port & 3),value)

PUB hex(port,value, digits)  'REF1
{ Method Info in (HoverDroids) SerialPorts PByte Banks M-N }
  bb := (port >> 2)
  if bb == 0
    return com0.hex((port & 3),value,digits)
  if bb == 1
    return com1.hex((port & 3),value,digits)

PUB ihex(port,value, digits)  'REF2
{ Method Info in (HoverDroids) SerialPorts PByte Banks M-N }
  bb := (port >> 2)
  if bb == 0
    return com0.ihex((port & 3),value,digits)
  if bb == 1
    return com1.ihex((port & 3),value,digits)

PUB bin(port,value, digits)  'REF1
{ Method Info in (HoverDroids) SerialPorts PByte Banks M-N }
  bb := (port >> 2)
  if bb == 0
    return com0.bin((port & 3),value,digits)
  if bb == 1
    return com1.bin((port & 3),value,digits)

PUB padchar(port, count, txbyte)  'REF2
{ Method Info in (HoverDroids) SerialPorts PByte Banks M-N }
  bb := (port >> 2)
  if bb == 0
    return com0.padchar((port & 3), count, txbyte)
  if bb == 1
    return com1.padchar((port & 3), count, txbyte)

PUB ibin(port,value, digits)  'REF2
{ Method Info in (HoverDroids) SerialPorts PByte Banks M-N }
  bb := (port >> 2)
  if bb == 0
    return com0.ibin((port & 3),value,digits)
  if bb == 1
    return com1.ibin((port & 3),value,digits)

PUB putc(port,txbyte)  'REF2
{ Method Info in (HoverDroids) SerialPorts PByte Banks M-N }
  bb := (port >> 2)
  if bb == 0
    return com0.putc((port & 3),txbyte)
  if bb == 1
    return com1.putc((port & 3),txbyte)

PUB newline(port)  'REF1
{ Method Info in (HoverDroids) SerialPorts PByte Banks M-N }
  bb := (port >> 2)
  if bb == 0
    return com0.newline((port & 3))
  if bb == 1
    return com1.newline((port & 3))

PUB cls(port)  'REF2
{ Method Info in (HoverDroids) SerialPorts PByte Banks M-N }
  bb := (port >> 2)
  if bb == 0
    return com0.cls((port & 3))
  if bb == 1
    return com1.cls((port & 3))

PUB getc(port)  'REF2
{ Method Info in (HoverDroids) SerialPorts PByte Banks M-N }
  bb := (port >> 2)
  if bb == 0
    return com0.getc((port & 3))
  if bb == 1
    return com1.getc((port & 3))

DAT
  crlf byte 13,10,0
