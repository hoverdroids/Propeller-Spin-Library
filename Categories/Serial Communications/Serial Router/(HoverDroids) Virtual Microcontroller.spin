{

======================================================================
 
  Copyright (C) 2016 HoverDroids(TM)

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

   File......
   Purpose...
   Author.... Chris Sprague
   E-mail.... HoverDroids@gmail.com
   Started... MM DD YYYY
   Updates... MM DD YYYY
   
======================================================================

----------------------------------------------------------------------
Derived from 
----------------------------------------------------------------------
  (REF1)  SpinObject1
  (REF2)  SpinObject2
  (REF3)  SpinObject3

  Different usage of references in code are list off the right side of the screen
  with the following format:

  [X]REF1 [ ]REF3               A version of the method is in found in
                                REF1 & REF3. The REF1 is used instead.
  [+]REF3                       REF3 has added this line vs other versions
  [-]REF1                       REF1 has removed this line vs other versions
  [M]REF1                       REF1 has modified this line vs other versions
----------------------------------------------------------------------
Program Description
----------------------------------------------------------------------

----------------------------------------------------------------------
Usage
----------------------------------------------------------------------
  To use this object in your code, declare it as shown below:

  OBJ
  objNickName:"Object Name"

  SomeMethod
  objNickName.objMethod(input1,...,inputN)

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
}



CON
'TODO add this as the description of this object
' =================================================================================================
'
' Auxilliary cog functions here.
' This can be treated pretty much like a normal standalone microcontroller.
' Exception:
'       use aux0_com for serial output and, to xmit,
'       do aux0_txflag~~
'       for serial receive, use reacttopacket
'       and read aux0_buffer_rx.
'
' Note that a blocking function is OK and will not impair the rest of the router! (see example)
'
' =================================================================================================

OBJ
  terminal: "(HoverDroids) FullDuplexSerial"
  vmc_tx: "(HoverDroids) Virtual Microcontroller TX Buffer"

CON

  ' The number of ports you want to use, up to 12, not including debug port. Port info listed below,
  ' It's best to set the input and output pins to -1 to indicate the pins aren't being used, but only
  ' numbuffers indicates the number of buffers to use. ie if numbuffers = 2 and port1 has pins=-1, an
  ' error will be thrown and if numbuffers = 1 and port1 has valid pins, only port1 will be used.
  ' MUST be in CON block...it's referenced by the Serial Router
  numbuffers = 1

VAR
  long addr_txflag
  long addr_rx

PUB start(addr_vmc_rxbuffer, addr_vmc_buffer_tx, buffersize, addr_vmc_txflag)
  'Just a test...REMOVE
  'vmc_tx.str(string("@12@start vmc1"))

  addr_txflag:=addr_vmc_txflag    'Save the reference to the txflag in order to transmit data from any method here

  addr_rx:=addr_vmc_rxbuffer  'Save the referece to the rx buffer in order to read from it from any method

  terminal.start(byte[@inputpins+12],byte[@outputpins+12],byte[@inversions+12],long[@baudrates+12*4])    ' high speed port gets special treatment (update: should it?)

  vmc_tx.init(addr_vmc_buffer_tx,buffersize) ' virtual com port for aux0_ device

  vmc_tx.str(string("@12@start vmc2"))
  byte[addr_vmc_txflag]~~'[0]:=1

PUB aux0_Activities|char1
{
  This is where your main code should go, except for reactions to received packets. Put those
  in aux_ReactToPacket instead.

  Note: This is passing the address of the transmit flag, not the flag itself. This is because
        the Serial Router is monitoring a specific value in memory and not the changing of the
        value that is passed into this method.

        So, use byte[@addr_aux0_txflag]~~ to tell the Serial Router to transmit the TX Buffer

  EX. Use of transmitting data from the Virtual Microcontroller
  vmc_tx.str(String("YourString"))                      'set string in tx buffer
  byte[@addr_aux0_txflag]~~                             'tell the Serial Router to send whatever is in the TX Buffer

byte[@MyStr][0]
}
  'vmc_tx.str(string("@12@Hello"))
  'byte[@addr_txflag]~~
  'vmc_tx.str(string("@12@activity"))
  'byte[@addr_txflag][0]:=1
  'waitcnt(clkfreq*2+cnt)

  vmc_tx.str(string("@12@Activity",13))
  byte[addr_txflag]~~
  waitcnt(clkfreq*2+cnt)

PUB aux0_ReactToPacket'(PacketAddr,FromWhere)
{
This is where your code should react to data that is received.
}
  vmc_tx.str(string("@12@React",13))
  byte[addr_txflag]~~
  'byte[@addr_txflag][0]:=1

PUB addr_inputpins
  return @inputpins

PUB addr_outputpins
  return @outputpins

PUB addr_baudrates
  return @baudrates

PUB addr_inversions
  return @inversions

PUB addr_defaultroute
  return @defaultroute

PUB rxcheck
  return terminal.rxcheck

PUB zap(how)
  return vmc_tx.zap(how)

PUB tx(txbyte)
  return terminal.tx(txbyte)

DAT
  'Here is the device number breakdown for the router
        '
        'Device 0 - 11 : Physical devices ... that are attached to physical pins
        '              : Do NOT use 30 & 31 for physical devices unless you know what you're doing!!!
        'Device 12     : Terminal ... to interface with developer
        'Device 13     : Router   ... data sent here can be used to configure the router or relaying data to other devices
        'Device 14     : The Virtual Microcontroller ... ie a project's main interface for interacting with other devices

  'Here is the device number breakdown when stealth mask is used. Stealth masking means that device router
  'heading are removed before sending to a given device so that only the data is sent. This allows devices
  'that don't know about the router to transfer data over the serial router
  '
        'Device 50 - 61: Physical devices
        'Device 62     : Terminal
        'Device 63     : Router
        'Device 64     : The Virtual Microcontroller

  'Device num         0      1       2      3      4       5     6     7      8      9      10     11     term      device num
  inputpins      byte 14,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    31      ' Hardware input pin
  outputpins     byte 15,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    30      ' Hardware output pin
  inversions     byte %0000, %0000, %0000, %0000, %0000, %0011, %0011, %0011, %0011, %0011, %0011, %0011, %0000   ' Signal flags (open collector, inversion etc.)
  baudrates      long 9600,  9600,  9600,  9600,  9600,  9600,  9600,  9600,  9600,  9600,  9600,  9600,  115200  ' Baud rate
  defaultroute   byte 12,    12,    12,    12,    12,    12,    12,    12,    12,    12,    12,    12,    13      ' Default route for each port

