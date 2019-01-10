{{
OBEX LISTING:
  http://obex.parallax.com/object/116

  Uses usb-fs-host, gives the Propeller MULTIPLE shells or TCP sockets into an Android phone.

  The apk source is very basic in its behavior -- write to the Prop in the upper textbox, read from the Prop in the lower (using your favorite terminal app prop-side). The buttons send data to the serial ports. There are also commands for the prop to change the baud rate and use COM0 as a console or not, more are easy to add.

  If you want to use this for robot control, send me an email, there is better code that can be had :)

  This is based off microbridge for the arduino+usb host shield http://code.google.com/p/microbridge/

  Related videos:

  http://www.youtube.com/watch?v=QcR0ZG_7YC8
  http://www.youtube.com/watch?v=PfSSPTtacnk

  Tutorial: http://youtu.be/VATnrauwb7g
}}
VAR
long bufptr
long bufaddr
long bufsize

pub init(BufferAddress,BufferSize)
    bufptr~
    bufaddr:=BufferAddress
    if (BufferSize < 0)
       bufsize:=strsize(BufferAddress) ' try to autodetect
    else
       bufsize:=BufferSize
    zap(0)   
       {
pub string_concat(string1addr, string2addr) ' trashes bigstring, careful
   result := strsize(string1addr)
   bytemove(bufaddr, string1addr, result)
   bytemove(bufaddr[result], string2addr, strsize(string2addr) + 1)
   result := bufaddr
   return
pub substring(string1addr, length) ' trashes bigstring, careful 
   bytemove(bufaddr, string1addr, length)   
   byte[bufaddr+length] := 0 ' cap the string 
   result := bufaddr
   }                                                                         

PUB tx(txbyte) ' true if out of buffer space
    if (bufptr => bufsize)
      return true            ' what should we do here?
    byte[bufaddr+bufptr++]:=txbyte 
    return false

pub zap(how) ' zap with which character? Always set the last position to 0
    bytefill(bufaddr,how,bufsize)'how,bufsize)
    'byte[bufaddr+bufsize-1]~
    bufptr~
    return false
pub remaining
    return bufsize-bufptr
pub buf
    return bufaddr


PUB str(stringptr) ' true if out of buffer space

  result := strsize(stringptr)
'' Send string
  if byte[stringptr] == 0
     return                  

  repeat result
    if tx(byte[stringptr++])
       return true
  return false  

PUB dec(value) | i, x  ' true if out of buffer space

'' Print a decimal number

  x := value == NEGX                                                            'Check for max negative
  if value < 0
    value := ||(value+x)                                                        'If negative, make positive; adjust for max negative
    tx("-")                                                                     'and output sign

  i := 1_000_000_000                                                            'Initialize divisor

  repeat 10                                                                     'Loop for 10 digits
    if value => i                                                               
      if tx(value / i + "0" + x*(i == 1))
         return true                                          'If non-zero digit, output digit; adjust for max negative
      value //= i                                                               'and digit from value
      result~~                                                                  'flag non-zero found
    elseif result or i == 1
      if tx("0")
         return true                                                                'If zero digit (or only digit) output it
    i /= 10                                                                     'Update divisor

  return false
PUB hex(value, digits)  ' true if out of buffer space

'' Print a hexadecimal number

  value <<= (8 - digits) << 2
  repeat digits
    if tx(lookupz((value <-= 4) & $F : "0".."9", "A".."F"))
       return true
  return false


PUB bin(value, digits)  ' true if out of buffer space

'' Print a binary number

  value <<= 32 - digits
  repeat digits
    if tx((value <-= 1) & 1 + "0")
       return true
  return false
