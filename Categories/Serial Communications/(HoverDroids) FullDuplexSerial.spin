{

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

   File...... (HoverDroids) FullDuplexSerial.spin
   Purpose... A serial object for full duplex serial transmission between
              devices, that is an aggregate of all other variations of the
              FullDuplexSerial objects on OBEX.
   Author.... Chris Sprague
   E-mail.... HoverDroids@gmail.com

   Version History
   1.0          08 09 2016
   
======================================================================
Derived from 
----------------------------------------------------------------------
  (REF1)  FullDuplexSerial
  (REF2)  FullDuplexSerialPlus
  (REF3)  OBEX\Serial Router\FullDuplexSerialExt
  (REF4)  FullDuplexSerial64
  (REF5)  FullDuplexSerial_rr004
  (REF6)  Parallax Serial Terminal
  (REF7)  pcFullDuplexSerial

  References are noted with the following format:

  [X]REF1 [ ]REF3               A version of the method is in found in
                                REF1 & REF3. The REF1 is used instead.
  [+]REF3                       REF3 has added this line vs other versions
  [-]REF1                       REF1 has removed this line vs other versions
  [M]REF1                       REF1 has modified this line vs other versions

----------------------------------------------------------------------
Program Description
----------------------------------------------------------------------
  COGS  USED:   TODO
  CTRAs USED:   TODO
  CTRBs USED:   TODO
  STACK SIZE:   TODO

  This is a compilation of many of the most popular serial objects on
  OBEX. The objective is to have a single serial object that works for
  all of the state purposes. This isn't difficult because most objects
  are copies of previous objects with edits to buffer sizes and
  additional methods for specific purposes.

----------------------------------------------------------------------
Usage
----------------------------------------------------------------------
  To use this object in your code, declare it as shown below:

  OBJ
  terminal: "(HoverDroids) FullDuplexSerial"

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
}

OBJ
  strings:"(HoverDroids) String Utils"

CON
  'From REF3
  'REF1 had bufflength = 16; REF3 changed bufflength to a variable value
  bufflength = 128 '64 ' must be a multiple of 2 and fit in a byte!!!                                                             '[+]REF3

CON                                                                                                                               '[+]REF2
{
  Parallax Serial Terminal Constants
  ----------------------------------------------------------------------
}
  HOME     =   1
  CRSRXY   =   2
  CRSRLF   =   3
  CRSRRT   =   4
  CRSRUP   =   5
  CRSRDN   =   6
  BELL     =   7
  BKSP     =   8
  TAB      =   9
  LF       =   10
  CLREOL   =   11
  CLRDN    =   12
  CR       =   13
  CRSRX    =   14
  CRSRY    =   15
  CLS      =   16

VAR                                                                                                                               '[X]REF1 [ ]REF2 [ ]REF3 [ ]REF4
  long  cog                     'cog flag/id

  long  rx_head                 '9 contiguous longs
  long  rx_tail
  long  tx_head
  long  tx_tail
  long  rx_pin
  long  tx_pin
  long  rxtx_mode
  long  bit_ticks
  long  buffer_ptr

  byte  rx_buffer[bufflength]           'receive buffer                                                                           '[M]REF3
  byte  tx_buffer[bufflength]           'transmit buffer                                                                          '[M]REF3

PUB start(rxpin, txpin, mode, baudrate) : okay                                                                                    '[ ]REF1 [ ]REF2 [X]REF3 [ ]REF4
{
  Descr : Start serial driver - starts a cog.

          This method is different in REF1 and REF3. The difference is that REF3 keeps trying to
          start until a new cog is freed while REF1 tries once and gives up if it failed.
          Hence, the REF3 version is used

  Input : rxpin:the physical pin to receive data from
          txpin:the physical pin to transmit data over
          mode:how the serial port will operate
               mode bit 0 = invert rx
               mode bit 1 = invert tx
               mode bit 2 = open-drain/source tx
               mode bit 3 = ignore tx echo on rx
          baudrate:the rate at which data is transfered on this serial port

  Return: returns false if no cog available
}
  stop
  longfill(@rx_head, 0, 4)
  longmove(@rx_pin, @rxpin, 3)
  bit_ticks := clkfreq / baudrate
  buffer_ptr := @rx_buffer
  repeat                                                                                                                          '[M]REF3
    okay := cog := cognew(@entry, @rx_head) + 1
  until okay                                                                                                                      '[M]REF3

PUB try(rxpin, txpin, mode, baudrate, attempts) : okay                                                                            '[X]REF3
{
  Descr : Start serial driver - starts a cog

  Input : rxpin:the physical pin to receive data from
          txpin:the physical pin to transmit data over
          mode:how the serial port will operate
               mode bit 0 = invert rx
               mode bit 1 = invert tx
               mode bit 2 = open-drain/source tx
               mode bit 3 = ignore tx echo on rx
          baudrate:the rate at which data is transfered on this serial port

  Return: returns false if no cog available
}
  stop
  longfill(@rx_head, 0, 4)
  longmove(@rx_pin, @rxpin, 3)
  bit_ticks := clkfreq / baudrate
  buffer_ptr := @rx_buffer

  repeat
    okay := cog := cognew(@entry, @rx_head) + 1
  until okay or (--attempts == 0)

  return okay


pub RXbufferAddress                                                                                                               '[X]REF3
{
  Descr : Get the address of the rx_buffer.
          in case we want to copy it over as a string

  Input : N/A

  Return: The address of the first byte of the rx_buffer
}
  return @rx_buffer

pub TXbufferAddress                                                                                                               '[X]REF3
{
  Descr : Get the address of the tx_buffer
          in case we want to copy it over as a string

  Input : N/A

  Return: The address of the first byte of the tx_buffer
}
  return @tx_buffer

pub started                                                                                                                       '[X]REF3
{
  Descr : Determine if the cog that is responsible for serial comms has been started

  Input : N/A

  Return: 0 if it hasn't been, a positive value otherwise
}
  return cog

PUB stop                                                                                                                          '[ ]REF1 [ ]REF2 [X]REF3 [ ]REF4
{
  Descr : Stop the cog that is responsible for serial comms.
          This will free a cog.
          REF[3] method used because it flushes the tx and rx buffers after stopping the cog

  Input : N/A

  Return: N/A
}
  if cog
    cogstop(cog~ - 1)
  longfill(@rx_head, 0, 9)

  dira[tx_pin]~                                                                                                                   '[M]REF3
  flush                                                                                                                           '[M]REF3

PUB rxflush                                                                                                                       '[X]REF1 [ ]REF2 [-]REF3 [ ]REF4
{
  Descr : Flush the rx buffer

  Input : N/A

  Return: N/A
}
  repeat while rxcheck => 0

PUB flush                                                                                                                         '[X]REF3
{
  Descr : Flush the rx and tx buffers

  Input : N/A

  Return: N/A
}
  bytefill(@rx_buffer, 0, bufflength)
  bytefill(@tx_buffer, 0, bufflength)

PUB stopnoflush                                                                                                                   '[X]REF3
{
  Descr : Stop the serial driver without flushing the tx and rx buffers, just in case we need to preserve
          them as static strings for some reason.

          This frees a cog.

  Input : N/A

  Return: N/A
}
  repeat until tx_tail == tx_head ' wait until TX buffer is all out
  if cog
    cogstop(cog~ - 1)
  longfill(@rx_head, 0, 9)
  dira[tx_pin]~

PUB rxcheck : rxbyte                                                                                                              '[ ]REF1 [ ]REF2 [X]REF3 [ ]REF4
{
  Descr : Check if a byte is received (never waits).
          REF3 method used because it allows for different buffer lengths while REF1 assumed a buffer
          size of 16 bytes
  Input : N/A

  Return: -1 if no byte received, $00..$FF if byte was received
}
  rxbyte--
  if rx_tail <> rx_head
    rxbyte := rx_buffer[rx_tail]
    rx_tail := (rx_tail + 1) & constant(bufflength - 1)                                                                           '[M]REF3


PUB rxtime(ms) : rxbyte | t                                                                                                       '[X]REF1 [ ]REF2 [ ]REF3 [ ]REF4
{
  Descr : Wait a given number of milliseconds for a byte to be received

  Input : ms:the number of milliseconds to wait for a byte

  Return: -1 if no byte received, $00..$FF if a byte was received
}
  t := cnt
  repeat until (rxbyte := rxcheck) => 0 or (cnt - t) / (clkfreq / 1000) > ms

PUB rx : rxbyte                                                                                                                   '[X]REF1 [ ]REF2 [ ]REF3 [ ]REF4
{
  Descr : Receive a byte (will wait for byte)

  Input : N/A

  Return: $00..$FF after a byte is received
}
  repeat while (rxbyte := rxcheck) < 0

PUB tx(txbyte)                                                                                                                    '[ ]REF1 [ ]REF2 [X]REF3 [ ]REF4
{
  Descr : Send a byte (may wait for room in buffer)
          REF3 method used because it allows for different buffer lengths while REF1 assumed a buffer
          size of 16 bytes

  Input : txbyte:the byte to transmit

  Return: ...
}
  repeat until (tx_tail <> (tx_head + 1) & constant(bufflength - 1))                                                              '[M]REF3
  tx_buffer[tx_head] := txbyte
  tx_head := (tx_head + 1) & constant(bufflength - 1)                                                                             '[M]REF3

  if rxtx_mode & %1000
    rx

pub txsize                                                                                                                        '[X]REF3
{
  Descr : Get the size of the transmission data, in bytes

  Input : N/A

  Return: The size of the transmission data, in bytes
}
  return tx_tail - tx_head

pub txwait                                                                                                                        '[X]REF3
{
  Descr : Make sure buffer is sent

  Input : N/A

  Return: N/A
}
  repeat until tx_tail == tx_head

PUB str(stringptr)                                                                                                                '[X]REF1 [ ]REF2 [ ]REF3 [ ]REF4
{
  Descr : Send the ZERO TERMINATED string that has its first byte located at stringptr

  Input : stringptr:the address of the first byte of the string

  Return: N/A
}
  repeat strsize(stringptr)
    tx(byte[stringptr++])

PUB getstr(stringptr) | index                                                                                                     '[X]REF2
{
  Descr : Gets zero terminated string and stores it, starting at the stringptr memory address.
          ie. Listen to the rx pin for characters and store each in the string's bytes
          until a carriage return is received.Then, terminate the string with a zero

  Input : stringptr:the address of the first byte of the string

  Return: Nothing is returned, but use the stringptr that was passed into this method to read
          the string.
}
  index~
  repeat until ((byte[stringptr][index++] := rx) == 13)
  byte[stringptr][--index]~

PUB crlf                                                                                                                          '[X]REF3
{
  Descr : Send CRLF (may wait for room in buffer), ie transmit both a carriage return
  and linefeed/new line character

  Input : N/A

  Return: N/A
}
  tx(13)
  tx(10)

PUB hex(value, digits)                                                                                                            '[X]REF1 [ ]REF2 [ ]REF3 [ ]REF4
{
  Descr : Transmit a value in hexadecimal form

  Input : value:the variable to transmit as hex
          digits:the number of digits to show when transmitting the variable

  Return: N/A
}
  value <<= (8 - digits) << 2
  repeat digits
    tx(lookupz((value <-= 4) & $F : "0".."9", "A".."F"))

PUB GetHex : value | tempstr[11]                                                                                                  '[X]REF2
{
  Descr : Gets hexadecimal character representation of a number from the terminal
          ie. Listen to the rx pin for characters and store each in a temp string's bytes
          until a carriage return is received.Then, convert the string to a HEX value.

  Input : N/A

  Return: The corresponding value
}
  GetStr(@tempstr)
  value := strings.StrToHex(@tempstr)

PUB bin(value, digits)                                                                                                            '[X]REF1 [ ]REF2 [ ]REF3 [ ]REF4
{
  Descr : Transmit a value in binary form

  Input : value:the variable to transmit as binary
          digits: the number of digits to show when transmitting the variable

  Return: N/A
}
  value <<= 32 - digits
  repeat digits
    tx((value <-= 1) & 1 + "0")

PUB GetBin : value | tempstr[11]                                                                                                  '[X]REF2
{
  Descr : Gets binary character representation of a number from the terminal
          ie. Listen to the rx pin for characters and store each in a temp string's bytes
          until a carriage return is received.Then, convert the string to a binary value.

  Input : N/A

  Return: The corresponding value
}
  GetStr(@tempstr)
  value := strings.StrToBin(@tempstr)

PUB dec(value) | i, x                                                                                                             '[X]REF1 [ ]REF2 [ ]REF3 [ ]REF4
                                                                                                                                  '[M]REF1
{
  Descr : Transmit a value in decimal form.
          REF1 method used because it appears that it was had the newest update despite being
          an older file. Seemingly, REF3 was written with an older version of REF1 and didn't
          update the dec method during the last update to the file.
          Also, the difference is explained in REF1, and quoted below:
          Update fixed bug in dec method causing largest negative value (-2,147,483,648) to be output
          as -0

  Input : value: the variable to transmit as a decimal

  Return: N/A
}
  x := value == NEGX                                                                                                              '[M]REF1
  if value < 0                                          'Check for max negative
    value := ||(value+x)                                'If negative, make positive; adjust for max negative'and output sign                                                                                                          '[M]REF1
    tx("-")

  i := 1_000_000_000                                    'Initialize divisor

  repeat 10                                             'Loop for 10 digits
    if value => i
                                                       'If non-zero digit, output digit; adjust for max negative and digit from
      tx(value / i + "0" + x*(i == 1))                  'flag non-zero found                                                      '[M]REF1
      value //= i
      result~~
    elseif result or i == 1                                                                                                       '[M]REF1
      tx("0")                                           'If zero digit (or only digit) output it                                  '[M]REF1
    i /= 10                                             'Update divisor

PUB GetDec : value | tempstr[11]                                                                                                  '[X]REF2
{
  Descr : Gets decimal character representation of a number from the terminal
          ie. Listen to the rx pin for characters and store each in a temp string's bytes
          until a carriage return is received.Then, convert the string to a decimal value.

  Input : N/A

  Return: The corresponding value
}
  GetStr(@tempstr)
  value := strings.StrToDec(@tempstr)

DAT                                                                                                                               '[ ]REF1 [ ]REF2 [X]REF3 [ ]REF4

'***********************************
'* Assembly language serial driver *
'***********************************
{
'This driver is different in REF1 and REF3. The differences is that REF3 accounts for
' a variance in the buffer length while REF1 assumed it to be 16 bytes. Hence, the REF3
' version is used
}
                        org
'
'
' Entry
'
entry                   mov     t1,par                  'get structure address
                        add     t1,#4 << 2              'skip past heads and tails

                        rdlong  t2,t1                   'get rx_pin
                        mov     rxmask,#1
                        shl     rxmask,t2

                        add     t1,#4                   'get tx_pin
                        rdlong  t2,t1
                        mov     txmask,#1
                        shl     txmask,t2

                        add     t1,#4                   'get rxtx_mode
                        rdlong  rxtxmode,t1

                        add     t1,#4                   'get bit_ticks
                        rdlong  bitticks,t1

                        add     t1,#4                   'get buffer_ptr
                        rdlong  rxbuff,t1
                        mov     txbuff,rxbuff
                        add     txbuff,#bufflength                                                                                '[M]REF3

                        test    rxtxmode,#%100  wz      'init tx pin according to mode
                        test    rxtxmode,#%010  wc
        if_z_ne_c       or      outa,txmask
        if_z            or      dira,txmask

                        mov     txcode,#transmit        'initialize ping-pong multitasking
'
'
' Receive
'
receive                 jmpret  rxcode,txcode           'run a chunk of transmit code, then return

                        test    rxtxmode,#%001  wz      'wait for start bit on rx pin
                        test    rxmask,ina      wc
        if_z_eq_c       jmp     #receive

                        mov     rxbits,#9               'ready to receive byte
                        mov     rxcnt,bitticks
                        shr     rxcnt,#1
                        add     rxcnt,cnt

:bit                    add     rxcnt,bitticks          'ready next bit period

:wait                   jmpret  rxcode,txcode           'run a chuck of transmit code, then return

                        mov     t1,rxcnt                'check if bit receive period done
                        sub     t1,cnt
                        cmps    t1,#0           wc
        if_nc           jmp     #:wait

                        test    rxmask,ina      wc      'receive bit on rx pin
                        rcr     rxdata,#1
                        djnz    rxbits,#:bit

                        shr     rxdata,#32-9            'justify and trim received byte
                        and     rxdata,#$FF
                        test    rxtxmode,#%001  wz      'if rx inverted, invert byte
        if_nz           xor     rxdata,#$FF

                        rdlong  t2,par                  'save received byte and inc head
                        add     t2,rxbuff
                        wrbyte  rxdata,t2
                        sub     t2,rxbuff
                        add     t2,#1
                        and     t2,#(bufflength - 1)    '$0F                                                                         '[M]REF3
                                                        ' makes sure tail stays between 0 and 15: change to
                                                        ' inc/dec tx/rx buffer (keep rxtx a multiple of 2!)
                        wrlong  t2,par

                        jmp     #receive                'byte done, receive next byte
'
'
' Transmit
'
transmit                jmpret  txcode,rxcode           'run a chunk of receive code, then return

                        mov     t1,par                  'check for head <> tail
                        add     t1,#2 << 2
                        rdlong  t2,t1
                        add     t1,#1 << 2
                        rdlong  t3,t1
                        cmp     t2,t3           wz
        if_z            jmp     #transmit

                        add     t3,txbuff               'get byte and inc tail
                        rdbyte  txdata,t3
                        sub     t3,txbuff
                        add     t3,#1
                        and     t3,#(bufflength - 1)    '$0F                                                                      '[M]REF3
                                                        ' makes sure tail stays between 0 and 15: change to
                                                        ' inc/dec tx/rx buffer (keep rxtx a multiple of 2!)
                        wrlong  t3,t1

                        or      txdata,#$100            'ready byte to transmit
                        shl     txdata,#2
                        or      txdata,#1
                        mov     txbits,#11
                        mov     txcnt,cnt

:bit                    test    rxtxmode,#%100  wz      'output bit on tx pin according to mode
                        test    rxtxmode,#%010  wc
        if_z_and_c      xor     txdata,#1
                        shr     txdata,#1       wc
        if_z            muxc    outa,txmask
        if_nz           muxnc   dira,txmask
                        add     txcnt,bitticks          'ready next cnt

:wait                   jmpret  txcode,rxcode           'run a chunk of receive code, then return

                        mov     t1,txcnt                'check if bit transmit period done
                        sub     t1,cnt
                        cmps    t1,#0           wc
        if_nc           jmp     #:wait

                        djnz    txbits,#:bit            'another bit to transmit?

                        jmp     #transmit               'byte done, transmit next byte
'
'
' Uninitialized data
'
t1                      res     1
t2                      res     1
t3                      res     1

rxtxmode                res     1
bitticks                res     1

rxmask                  res     1
rxbuff                  res     1
rxdata                  res     1
rxbits                  res     1
rxcnt                   res     1
rxcode                  res     1

txmask                  res     1
txbuff                  res     1
txdata                  res     1
txbits                  res     1
txcnt                   res     1
txcode                  res     1      '
        
