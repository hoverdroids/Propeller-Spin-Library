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

   File...... (HoverDroids) Serial Router Virtual Microcontroller
   Purpose... A virtual microcontroller for
   Author.... Chris Sprague
   E-mail.... HoverDroids@gmail.com
   Started... 08 11 2016
   Updates... 08 11 2016
   
======================================================================

----------------------------------------------------------------------
Program Description
----------------------------------------------------------------------

----------------------------------------------------------------------
Usage
----------------------------------------------------------------------
  This object is meant to be used with one of the following project structures:

  (HoverDroids) Serial Router Main with 32Byte Buffers
        (HoverDroids) Serial Router with 32Byte Buffers
                (HoverDroids) Serial Router Virtual Microcontroller

  OR

  (HoverDroids) Serial Router Main with 128Byte Buffers
        (HoverDroids) Serial Router with 128Byte Buffers
                (HoverDroids) Serial Router Virtual Microcontroller

  OR

  (HoverDroids) Serial Router Main with 512Byte Buffers
        (HoverDroids) Serial Router with 512Byte Buffers
                (HoverDroids) Serial Router Virtual Microcontroller

  Steps:
  1. Create a new folder in Microsoft Windows
  2. Download the libraries from HoverDroids GitHub
  3. SEtup stuff


  OBJ
    vmc:"(HoverDroids) Serial Router Virtual Microcontroller"

  Main
    'Create rx and tx buffers of size=buffersize. Also create a variable for
    'monitoring the tx transmit request status.
    vmc.start(addr_vmc_rxbuffer, addr_vmc_txbuffer, buffersize, addr_vmc_txflag)

    'The calling object is
    'responsible for transmitting the entire tx buffer when the flag=1
    'and then resetting the flag=0. It is also responsible for monitoring
    'and managing the reception of data, storing it in the rx buffer,
    'and calling vmc.ReactToPacket



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

PUB start(addr_vmc_rxbuffer, addr_vmc_txbuffer, buffer_size, addr_vmc_txflag)

  addr_rx:=addr_vmc_rxbuffer  'Save the referece to the rx buffer in order to read from it from any method
  buffersize:=buffer_size

  terminal.start(byte[@inputpins+12],byte[@outputpins+12],byte[@inversions+12],long[@baudrates+12*4])    ' high speed port gets special treatment (update: should it?)
  vmc_tx.init(addr_vmc_txbuffer, buffer_size, addr_vmc_txflag) ' virtual com port for aux0_ device

  init

PRI init
{
  Descr : Use this method to customize the router configuration at startup
          Keep this blank to keep deafult configuration.

  Input : N/A

  Return: N/A
}

PUB Main|char1
{
  Descr : Use this method for your main code. Blocking code is allowed and doesn't interfere
          with the router.

          Use ReactToPacket to handle received packets.

  Input : N/A

  Return: N/A
}

PUB ReactToPacket'(PacketAddr,FromWhere)
{
  Descr : Use this handle received packets

  Input : N/A

  Return: N/A
}

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
  inputpins      byte -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    31      ' Hardware input pin
  outputpins     byte -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    30      ' Hardware output pin
  inversions     byte %0000, %0000, %0000, %0000, %0000, %0011, %0011, %0011, %0011, %0011, %0011, %0011, %0000   ' Signal flags (open collector, inversion etc.)
  baudrates      long 9600,  9600,  9600,  9600,  9600,  9600,  9600,  9600,  9600,  9600,  9600,  9600,  115200  ' Baud rate
  defaultroute   byte 12,    12,    12,    12,    12,    12,    12,    12,    12,    12,    12,    12,    13      ' Default route for each port

