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

   File...... (HoverDroids)Virtual Microcontroller
   Purpose... TODO
   Author.... Chris Sprague
   E-mail.... HoverDroids@gmail.com
   Started... 08 09 2016
   Updates... 08 09 2016
   
======================================================================

----------------------------------------------------------------------
Derived from 
----------------------------------------------------------------------
  (REF1)  OBEX\Serial Router\stringoutput_external_buffer

----------------------------------------------------------------------
Program Description
----------------------------------------------------------------------
  This acts like a virtual microcontroller when being used by the
  Serial Router

----------------------------------------------------------------------
Usage
----------------------------------------------------------------------
  To use this object in your code, declare it as shown below:

  OBJ
  vmc:"Virtual Microcontroller"

  SomeMethod
  vmc.vmcMethod(input1,...,inputN)

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
VAR
  'From REF1
  long bufptr
  long bufaddr
  long bufsize
  long addr_txflag

PUB init(BufferAddress, BufferSize, addr_tx_flag)                                              'From REF1
{
  Descr : Call this method from your main code before using this object. It will initialize
          the output buffer that is used for transmitting data from the this Virtual uController
          to other serial devices.
          Trashes bigstring, so be careful

  Input : string1addr:the address of the first byte of the first string
          string2addr:the address of the first byte of the second string

  Return: The address of the concatenated string in the buffer
}
  'Save this address in oder to indicate the the tx buffer should be transmitted by the Serial
  'Router during the next transmission cycle
  addr_txflag:=addr_tx_flag

  bufptr~
  bufaddr:=BufferAddress
  if (BufferSize < 0)
    bufsize:=strsize(BufferAddress) ' try to autodetect
  else
    bufsize:=BufferSize
  zap(0)

PUB string_concat(string1addr, string2addr)                                     'From REF1
{
  Descr : Concatenate string2 onto string1.
          Trashes bigstring, so be careful

  Input : string1addr:the address of the first byte of the first string
          string2addr:the address of the first byte of the second string

  Return: The address of the concatenated string in the buffer
}
  result := strsize(string1addr)
  bytemove(bufaddr, string1addr, result)
  bytemove(bufaddr[result], string2addr, strsize(string2addr) + 1)
  result := bufaddr
  return

PUB substring(string1addr, length)                                              'From REF1
{
  Descr : Copy part of string1 to the buffer. This will then terminate the substring
          with a zero as required by most methods.
          Trashes bigstring, careful.

  Input : string1addr:the address of the first byte of the string to start copying
          length:the number of characters to copy from the first byte copied

  Return: The address of the resulting string in the buffer
}
  bytemove(bufaddr, string1addr, length)
  byte[bufaddr+length] := 0 ' cap the string
  result := bufaddr

PUB tx(txbyte)                                                                  'From REF1
{
  Descr : Add a single byte to the transmit buffer and advance the end-of-buffer pointer.
          This will add a single byte to the buffer and advance the end-of-buffer pointer only
          if buffer is not full. If it's full, the byte is not added.

  Input : txbyte:The byte to be added to the buffer

  Return: True if out of buffer space; false otherwise.
}
  if (bufptr => bufsize)
    return true            'TODO what should we do here?
  byte[bufaddr+bufptr++]:=txbyte
  return false

PUB zap(how)                                                                    'From REF1
{
  Descr : Fill the entire buffer with the same byte.
          Always set the last position to 0 to remain compatible with other string functions.

  Input : how:The byte to use when filling all bytes of the buffer

  Return: False...always...Chris doesn't know why TODO
}
  bytefill(bufaddr,how,bufsize)'how,bufsize)
  'byte[bufaddr+bufsize-1]~
  bufptr~
  return false

PUB remaining                                                                    'From REF1
{
  Descr : Get the number of bytes remaining in the tx buffer

  Input : N/A

  Return: The number of bytes remaining in the tx buffer
}
  return bufsize-bufptr

PUB buf                                                                         'From REF1
{
  Descr : Get the buffer address; ie the address of the first byte in memory that is reserved
          for the tx buffer

  Input : N/A

  Return: The address of the first byte of the tx buffer
}
  return bufaddr

PUB str(stringptr)                                                              'From REF1
{
  Descr : Add a ZERO TERMINATED string to the tx buffer, without sending it.
          String(""): it's also possible to pass String("your string")

  Input : stringptr:The pointer to a ZERO TERMINATED string

  Return: True if out of buffer space; false otherwise
}
  'Exit with the size of the string if the string's first byte is zero
  result := strsize(stringptr)
  if byte[stringptr] == 0
    return

  'The first byte of the string is not zero, so add every possible byte
  'to the tx buffer
  repeat result
    if tx(byte[stringptr++])
      return true
  return false

PUB sendStr(stringptr)
{
  Descr : Add a ZERO TERMINATED string to the tx buffer. Then indicate to the
          Serial Router that the tx buffer should be transmitted during the next
          transmission cycle.
          String(""): it's also possible to pass String("your string")

  Input : stringptr:The pointer to a ZERO TERMINATED string

  Return: True if out of buffer space; false otherwise
}
  result:=str(stringptr)
  send
  return result

PUB dec(value) | i, x                                                           'From REF1
{
  Descr : Convert a value to its decimal representation and add that representation
          to the tx buffer,without sending it. This is useful for gradually
          buiding the data in the output buffer

  Input : value:The value to be converted to a decimal string

  Return: True if out of buffer space; false otherwise
}
  x := value == NEGX                                                            'Check for max negative
  if value < 0
    value := ||(value+x)                                                        'If negative, make positive; adjust for max negative
    tx("-")                                                                     'and output sign

  i := 1_000_000_000                                                            'Initialize divisor

  repeat 10                                                                     'Loop for 10 digits
    if value => i
      if tx(value / i + "0" + x*(i == 1))
        return true                                                             'If non-zero digit, output digit; adjust for max negative
      value //= i                                                               'and digit from value
      result~~                                                                  'flag non-zero found
    elseif result or i == 1
      if tx("0")
        return true                                                                'If zero digit (or only digit) output it
    i /= 10                                                                     'Update divisor

  return false

PRI sendDec(value)
{
  Descr : Convert a value to its decimal representation and add that representation
          to the tx buffer. Then indicate to the Serial Router that the tx buffer
          should be transmitted during the next transmission cycle

  Input : value:The value to be converted to a decimal string

  Return: True if out of buffer space; false otherwise
}
  result:=dec(value)
  send
  return result

PUB hex(value, digits)                                                          'From REF1
{
  Descr : Convert a value to its hex representation and add that representation
          to the tx buffer,without sending it. This is useful for gradually
          buiding the data in the output buffer

  Input : value:The value to be converted to a hex string
          digits: The number of digits to print (e.g. 2 digits shows FF)

  Return: True if out of buffer space; false otherwise
}

  value <<= (8 - digits) << 2
  repeat digits
    if tx(lookupz((value <-= 4) & $F : "0".."9", "A".."F"))
       return true
  return false

PRI sendHex(value,digits)
{
  Descr : Convert a value to its hex representation and add that representation
          to the tx buffer. Then indicate to the Serial Router that the tx buffer
          should be transmitted during the next transmission cycle

  Input : value:The value to be converted to a hex string
          digits: The number of digits to print (e.g. 2 digits shows FF)

  Return: True if out of buffer space; false otherwise
}
  result:=hex(value, digits)
  send
  return result

PUB bin(value, digits)                                                          'From REF1
{
  Descr : Convert a value to its binary representation and add that representation
          to the tx buffer,without sending it. This is useful for gradually buiding
          the data in the output buffer

  Input : value:the value to be converted to binary string
          digits: The number of digits to print (e.g. 2 digits shows 10)

  Return: True if out of buffer space; false otherwise
}
  value <<= 32 - digits
  repeat digits
    if tx((value <-= 1) & 1 + "0")
       return true
  return false

PUB sendBin(value, digits)
{
  Descr : Convert a value to its binary representation and add that representation
          to the tx buffer. Then indicate to the Serial Router that the tx buffer
          should be transmitted during the next transmission cycle

  Input : value:the value to be converted to binary string
          digits: The number of digits to print (e.g. 2 digits shows 10)

  Return: True if out of buffer space; false otherwise
}
  result:=bin(value, digits)
  send
  return result

PUB send
{
  Descr : Indicate to the Serial Router that the tx buffer
          should be transmitted during the next transmission cycle

  Input : N/A

  Return: N/A
}
  byte[addr_txflag]~~

