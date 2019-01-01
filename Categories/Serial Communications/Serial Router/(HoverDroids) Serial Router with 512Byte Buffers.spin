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
   Started... 08 09 2016
   Updates... 08 09 2016
   
======================================================================

----------------------------------------------------------------------
Derived from 
----------------------------------------------------------------------
  (REF1)  OBEX\Serial Router\nasa router firmware example 12sp

----------------------------------------------------------------------
Program Description
----------------------------------------------------------------------

----------------------------------------------------------------------
Usage
----------------------------------------------------------------------
  To use this object in your code, declare it as shown below:

  OBJ
  router:"(HoverDroids)Serial Router"

  SomeMethod
  router.objMethod(input1,...,inputN)

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

OBJ
  com   : "TwelveSerialPorts512"        'Sets size of primary RX buffer.
  utils : "(HoverDroids) Serial Router Utils"
  vmc   : "(HoverDroids) Virtual Microcontroller"

CON

  ' 0..11 are the port addresses
  term           = 12               ' terminal address...ie the terminal a developer uses to interacts with prop
  router         = 13               ' if we get this address in, it means it's a command for the router, so handle
                                    ' accordingly.
  aux0_cog1      = 14               ' if we get this address in, it means it's a command for the auxilliary cog, so
                                    ' handle accordingly.
  devnull        = 99               ' guaranteed /dev/null for any conceivable reason
  stealthmask    = 50               ' This + address means "deliver the packet without sending information", useful
                                    ' for devices that don't know about the router, e.g. NMEA devices. 0 disables.
                                    ' Do not overlap ports or you'll miss the first stealthed x ports.

  buffersize  = com#SECONDARY_BUFFER_SIZE
  delimchar   = "@"                 ' address delimiter
  termichar   = 13                  ' packet delimiter
  termichar2  = 10                  ' packet delimiter

VAR
  'TODO
  'Change all aux_0 crap to vmc, for virtual micro controller

  ' auxilliary cog variables
  byte aux0_buffer_rx[buffersize]             ' receive buffer for aux0_ cog / virtual com port
  byte aux0_rxpad
  byte aux0_busyflag
  byte aux0_rxflag                           ' did anything come in?
  byte aux0_buffer_tx[buffersize]            ' transmit buffer for aux0_ cog / virtual com port
  byte aux0_txpad                            ' used by the aux0_ cog as "clear to send" tag
  byte aux0_txflag
  long aux0_cog
  long aux0_lastorigin
  byte aux0_started                          'initialized to 0, ie false, by default
  long aux0_stack[128]                       ' The aux0 methods are launched in a new cog in order to run functions in
                                             ' parallel with serial communications. This stack represents the reserved

  byte buffer[(buffersize+1)*vmc#numbuffers] ' includes padding
  long ptr[vmc#numbuffers]

  byte terminalbuffer[buffersize]             ' high speed port gets special treatment
  byte terminalpad
  long terminalptr
                                             ' space when launching the new cog
  long addr_inputpins
  long addr_outputpins
  long addr_baudrates
  long addr_inversions
  long addr_defaultroute

PUB start | temp, bufferbaseaddr, port  ' Main router code.

  'Get addresses to project-specific information stored in the
  'Virtual Microcontroller's DAT block
  addr_inputpins   := vmc.addr_inputpins
  addr_outputpins  := vmc.addr_outputpins
  addr_baudrates   := vmc.addr_baudrates
  addr_inversions  := vmc.addr_inversions
  addr_defaultroute:= vmc.addr_defaultroute

  'Start the Virtual Microcontroller and terminal port here
  vmc.start(@aux0_buffer_rx, @aux0_buffer_tx, buffersize, @aux0_txflag)

  'Start all the other ports here
  port~
  repeat vmc#numbuffers
    if (byte[addr_inputpins+port] < 32) and (byte[addr_outputpins+port] < 32)
      com.AddPortNoHandshake(port,byte[addr_inputpins+port],byte[addr_outputpins+port],byte[addr_inversions+port],long[addr_baudrates+port*4])
      port++
  com.start

  'Start Virtual Microcontroller cog here (if wanted). Add cogs to fit.
  repeat
    aux0_rxflag~
    aux0_cog := cognew(aux0_loop, @aux0_stack) + 1
  until aux0_cog

  'TODO REMOVE
  'aux0_txflag~~

  'Main loop
  repeat
    ' device ports
    port~
    repeat vmc#numbuffers
      bufferbaseaddr := port*buffersize
      temp := com.rxcheck(port)
      if (temp > 0)
        buffer[bufferbaseaddr+ptr[port]]:=temp
        ptr[port]++
        if (temp == termichar or temp == termichar2 or ptr[port] => buffersize)
          buffer[bufferbaseaddr+ptr[port]] := 0
          output(@buffer+bufferbaseaddr,port)
          ptr[port] := 0
      port++

      ' terminal port (checked every round)
      temp := vmc.rxcheck
      if (temp > 0)
        terminalbuffer[terminalptr++]:=temp
        if (temp == termichar or temp == termichar2 or terminalptr > buffersize)
          terminalbuffer[terminalptr]~
          output(@terminalbuffer,term)
          terminalptr~

      ' internal virtual serial port (ok to check every round: virtually free)
      if(aux0_txflag)
        output(@aux0_buffer_tx,(constant(aux0_cog1)))
        vmc.zap(0)
        aux0_txflag~

PRI aux0_loop ' auxiliary cog function. Should not need modifications.

  repeat
    vmc.Main  'the aux0_Activity will keep looping even though there are no received packets; the buffer is updated when a new message comes in
    if (aux0_rxflag) ' we got something in buffer
      aux0_rxflag~
      aux0_busyflag~~
      vmc.ReactToPacket'(@aux0_buffer_rx,aux0_lastorigin)
      aux0_busyflag~
  cogstop(aux0_cog~ - 1)

PRI ExecuteRouterCommand(CommandAddr, origin) : valid | cmdbyte, arg1, arg2 ' unrolled loops for speed here. use this to set verbosity, pins, baud rates etc. Can also set routing tables if we want to go that way. Synchronous, so it sehould be fast!
  valid~
  cmdbyte := utils.upcase(byte[CommandAddr])
  if cmdbyte == "L" 'Lx ' logging level
    if utils.isDigit(byte[CommandAddr+1])
      bigbrother := byte[CommandAddr+1]-"0"
      valid~~

  if cmdbyte == "R" 'reboot
    utils.BuildAddress(origin,@okstr,delimchar)
    output(@okstr,router)
    reboot

  if cmdbyte == "D" 'Dxx>yy ' default route for port x is y ( use stealthmask to strip!)
    if utils.isDigit(byte[CommandAddr+1]) and utils.isDigit(byte[CommandAddr+2]) and byte[CommandAddr+3] == ">" and utils.isDigit(byte[CommandAddr+4]) and utils.isDigit(byte[CommandAddr+5])
      arg1 := (byte[CommandAddr+1]-"0")*10
      arg1 += (byte[CommandAddr+2]-"0")

      arg2 := (byte[CommandAddr+4]-"0")*10
      arg2 += (byte[CommandAddr+5]-"0")

      byte[addr_defaultroute+arg1] := arg2 & $FF
      valid~~

  ' these are best set in hardware really...
  if cmdbyte == "B" 'Dxx:yyyy[-+] ' baud rate for port x is y
    if utils.isDigit(byte[CommandAddr+1]) and utils.isDigit(byte[CommandAddr+2]) and byte[CommandAddr+3] == ":" and utils.isDigit(byte[CommandAddr+4]) and utils.isDigit(byte[CommandAddr+5]) and utils.isDigit(byte[CommandAddr+6]) and utils.isDigit(byte[CommandAddr+7])
      arg1 := (byte[CommandAddr+1]-"0")*10
      arg1 += (byte[CommandAddr+2]-"0")

      arg2 := (byte[CommandAddr+3]-"0")*1000
      arg2 += (byte[CommandAddr+4]-"0")*100
      arg2 += (byte[CommandAddr+5]-"0")*10
      arg2 += (byte[CommandAddr+6]-"0")
      if byte[CommandAddr+8] == "-"
        byte[addr_inversions+arg1]:=%0011
    else
      byte[addr_inversions+arg1]:=%0000
      long[addr_baudrates+(arg1*4)] := arg2 & $FF
      valid~~

  if cmdbyte == "P" 'Pxx:yy:zz ' pins for port x are y and z
    if utils.isDigit(byte[CommandAddr+1]) and utils.isDigit(byte[CommandAddr+2]) and byte[CommandAddr+3] == ":" and utils.isDigit(byte[CommandAddr+4]) and utils.isDigit(byte[CommandAddr+5]) and byte[CommandAddr+6] == ":" and utils.isDigit(byte[CommandAddr+7]) and utils.isDigit(byte[CommandAddr+8])
      arg1 := (byte[CommandAddr+1]-"0")*10
      arg1 += (byte[CommandAddr+2]-"0")

      arg2 := (byte[CommandAddr+4]-"0")*10
      arg2 += (byte[CommandAddr+5]-"0")

      cmdbyte += (byte[CommandAddr+7]-"0")*10
      cmdbyte += (byte[CommandAddr+8]-"0")

      byte[addr_inputpins+(arg1*4)] := arg2 & $FF
      byte[addr_outputpins+(arg1*4)] := cmdbyte & $FF
      valid~~

  if (valid)
    utils.BuildAddress(origin,@okstr,delimchar)
    output(@okstr,router)

  else
    errcode:="U"
    utils.BuildAddress(origin,@errstr,delimchar)
    output(@errstr,router)

PRI output(StringAddr,origin) | size, address, dobbout, sta

  address := defaultaddress ' default to term. Could also default to bit bucket if desired?
  dobbout := (origin <> term)

  if byte[StringAddr] == delimchar and byte[StringAddr+3] == delimchar    ' we got an address indicator, so generate an address. Default is send to terminal. Invalid addresses will be sent to terminal.
    address := (byte[++StringAddr]-"0")*10
    address += (byte[++StringAddr]-"0")
    StringAddr+=2
    if (address > 99 or address < 0)
      address := defaultaddress ' default

  else
    if (dobbout==false)
      address := byte[addr_defaultroute + 12]
    elseif (origin > -1 and origin < vmc#numbuffers) ' no address? then default to the specified static routing table.
      address := byte[addr_defaultroute + origin]


  utils.removetermchar(StringAddr,termichar,termichar2)
  size := strsize(StringAddr)

  if (size < 1)
    return

  case address
    router:
      ExecuteRouterCommand(StringAddr,origin) ' no need to have an address in there because this is delivered locally

    aux0_cog1:
      CallAsyncCommand(StringAddr,origin)     ' no need to have an address in there because this is delivered locally

    ' devices 0 to 11
    0..constant(vmc#numbuffers-1):  ' the terminal may still want to know what goes on, so let's enable it to monitor things
      com.tx(address,delimchar)
      com.tx(address,"0"+origin/10)
      com.tx(address,"0"+origin//10)
      com.tx(address,delimchar)
      sta := StringAddr
      repeat size
        com.tx(address,utils.reformat(byte[sta++],address,doupcase,dolowcase))
      com.tx(address,delimchar)
      com.tx(address,termichar)

    ' terminal
    term:
      dobbout~
      vmc.tx(delimchar)
      vmc.tx("0"+origin/10)
      vmc.tx("0"+origin//10)
      vmc.tx(delimchar)
      sta := StringAddr
      repeat size
        vmc.tx(utils.reformat(byte[sta++],term,doupcase,dolowcase))
      vmc.tx(delimchar)
      vmc.tx(termichar)

    ' devices 0 to 11, with stealth mask
    stealthmask..constant(stealthmask+vmc#numbuffers-1):  ' the terminal may still want to know what goes on, so let's enable it to monitor things
      sta := StringAddr
      repeat size
        com.tx(address-stealthmask,utils.reformat(byte[sta++],address,doupcase,dolowcase))
      com.tx(address-stealthmask,termichar)

    ' terminal with stealth mask
    stealthmask+term:
      dobbout~
      sta := StringAddr
      repeat size
        vmc.tx(utils.reformat(byte[sta++],term,doupcase,dolowcase))
      vmc.tx(termichar)

    devnull: ' always nothing
    other: ' everything else: currently bit bucketed, unless terminal is monitoring it, see below

  if(dobbout and bigbrother)
    vmc.tx(delimchar)
    vmc.tx("0"+origin/10)
    vmc.tx("0"+origin//10)
    vmc.tx(">")
    vmc.tx("0"+address/10)
    vmc.tx("0"+address//10)
    if (bigbrother>1)
      vmc.tx(delimchar)
      sta := StringAddr
      repeat size
        vmc.tx(utils.reformat(byte[sta++],term,doupcase,dolowcase))
    vmc.tx(delimchar)
    vmc.tx(termichar)

PRI CallAsyncCommand(CommandAddr,origin)
  if (aux0_busyflag)                      ' synchronously say that the other core is busy
    utils.BuildAddress(@busystr,origin,delimchar)
    output(@busystr,aux0_cog1)
  else
    bytemove(@aux0_buffer_rx,CommandAddr,buffersize) ' deliver the command to the virtual com port
    aux0_lastorigin:=origin
    aux0_rxflag~~

DAT
  ' configuration options for the router
  defaultaddress byte term   ' where to send things we don't know what to do with
  doupcase       byte  0     ' if 1, convert lowercase letters to uppercase
  dolowcase      byte  0     ' if 1, convert uppercase letters to lowercase
  bigbrother     byte  1     ' 0 none, 1 terminal monitors inter-device exchange, 2 terminal
                             ' monitors that AND packet contents (useful to not have to send the
                             ' same packet twice

DAT
  ' premade sentences
  busystr byte "@__@BUSY",0
  errstr  byte "@__@ERR "
  errcode byte "_",0
  okstr   byte "@__@OK",0
