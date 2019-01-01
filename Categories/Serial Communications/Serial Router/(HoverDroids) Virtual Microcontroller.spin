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
  long addr_rx
  long buffersize

PUB start(addr_vmc_rxbuffer, addr_vmc_buffer_tx, buffer_size, addr_vmc_txflag)

  addr_rx:=addr_vmc_rxbuffer  'Save the referece to the rx buffer in order to read from it from any method
  buffersize:=buffer_size

  terminal.start(byte[@inputpins+12],byte[@outputpins+12],byte[@inversions+12],long[@baudrates+12*4])    ' high speed port gets special treatment (update: should it?)
  vmc_tx.init(addr_vmc_buffer_tx, buffer_size, addr_vmc_txflag) ' virtual com port for aux0_ device

  init

PRI init
{
  If you'd like to initialize the device pins, baud, inversions, and default routes, it's
  best to do it here or in DAT.

  But, if you must configure it here, do something like the following:



  '

}
  'For all other other router settings, the following can be used:
  'Set the output level to 2, ie

  'Set router to show inter-device communications AND data
  vmc_tx.sendStr(String("@14@L2"))

  'Set router

PUB Main|char1
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
  'BAD!!!
  '---------------------
  'The message header and first piece of  data is added to the tx buffer,
  'including the <cr>, but buffer is not sent. Then, the rest of the data is added
  'to the tx buffer. Finally, the entire tx buffer is sent
  'NOTICE: If you look at the terminal screen then you will see that only the first
  '   line of data is received correctly.This is because the data has a <cr> which tells
  '   the router that it's the end of the current information....true?
  '   Also...the @12@ header only applies to data up to a <cr> and so the second set of
  '   data is not given the @12@ header which routes it to a different location since
  '   we set a different default route
  '   TODO maybe try to show this with stealth instead; not sure what I'm trying to show
  vmc_tx.str(String("@12@Main Program Block...initial data...)",13))
  vmc_tx.sendStr(String("...secondary data...",13))'I proved that this is never seen
  waitcnt(clkfreq+cnt)

  'Also notice that the address stripping only happens for the first 4 bytes of the string
  'and after that @##@ is just part of the data, not a command

  'How to show more data...
  'waitcnt(clkfreq*2+cnt)'give the terminal long enough to not have problems displaying messages correctly
  'vmc_tx.str(String("@12@Main Program Block...initial data...)",13))
  'vmc_tx.send'force the string to be sent
  'waitcnt(clkfreq*2+cnt)'still nothing
  'and now the individual command to send what ever is in the buffer
  'vmc_tx.sendStr(String("...secondary data...",13))'I proved that this is never seen

  'Send a single string with <cr>

  'Build a string, then send it from dev#14(vmc)
  'Build a string, then send it from dev#14(vmc)
  vmc_tx.str(String("@12@Inside Main Program Block..."))
  vmc_tx.str(String("From dev#14 to dev#12..."))
  vmc_tx.sendStr(String("i.e. from VMC to Term"))
  waitcnt(clkfreq+cnt)

  'Notice that there is no need to send the <cr>, it is taken care of by sendStr and send

  'Build a string, then send it from dev#14(vmc)
  vmc_tx.str(String("@12@Still Inside Main Program Block..."))
  vmc_tx.str(String("From dev#"))
  vmc_tx.dec(14)
  vmc_tx.str(String(" to dev#"))
  vmc_tx.dec(12)
  vmc_tx.str(String("..."))
  vmc_tx.str(String("...using some hex:"))
  vmc_tx.hex($FF,2)
  vmc_tx.send
  waitcnt(clkfreq+cnt)
  'GOOD
  '---------------------

  'Send bla bla
  'vmc_tx.str(String("@12@Main Program Block)",13))
  'vmc_tx.sendStr(String("Dev#14(VMC) to Dev#12(Term",13))
  'sendStr("@12@To terminal(dev#12) from Virtual Microcontroller(dev#14)")
  'waitcnt(clkfreq*2+cnt)

PUB ReactToPacket'(PacketAddr,FromWhere)
{
  Descr : Use this block to respond to data that is received.

          The data is stored in main memory starting at addr_rx.
          To access the first byte of data use

          tempVar:=byte[addr_rx]
                        ^do NOT use the @ symbol since addr_rx already holds the address

          In order to transmit data from this method, use sendDec, sendStr, or sendHex

  Input : PacketAddr:
          FromWhere:

  Return: N/A
}
  'Just an example, delete if you wish...

  'We are just going to print the entire rx buffer to the terminal


  'str(String("@12@Inside of ReactToPacket",13))
  'str(String("
  'sendStr(String("@12@To terminal(dev#12) from Virtual Microcontroller(dev#14)",13))

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

