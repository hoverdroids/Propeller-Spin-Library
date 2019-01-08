{{
OBEX LISTING:
  http://obex.parallax.com/object/520

  Assumptions -- @ is delimiter char, <cr> is end of packet char / begin buffering next packet char. Max packet length is 256 bytes if you want more there's room :)

  Router checks the first 4 bytes of a packet: if they match the regexpr, it's an address, if not send the packet to the default destination for that port. regexpr is delimiter, digit, digit, delimiter. (So port 0 must be addressed as @00@, @0@ is invalid).

  Ports 00 to 11 are device ports. Max baud rate is 57600. OK to have fewer than 11 port, frees up cogs & hardware pins.

  Port 12 is the terminal port. Max baud rate is 230400.

  Port 13 is the router itself and commands can be sent to it.

  Port 14 is the remaining cogs on the Propeller chip and can be addressed as a separate device, if some hardware pins aren't used, this acts as an extra microcontroller that can be used to read ADCs, control motors and what not. 2 cogs are currently free (if using all serial ports).

  Examples:

  If device 4 sends Hello_There to device 0, it would do so like this:

  @00@Hello_There<cr>

  Device 0 would receive this:

  @04@Hello_There@<cr>

  If logging is set, the terminal would receive @04>00@<cr> (logging set to 1) or @04>00@Hello_There@<cr> (logging set to 2)

  Adding 50 to the port address (so @50@ to @64@ ) sends out the packet "stealthily", that is, without the origin address prefix. So if any device sends@00@Boo!<cr>then device 0 would receiveBoo!<cr>

  In addition, if a device sends out a packet without addressinformation, it will be delivered to that device's defaultdestination.

  These two things + a bit of configuration from the terminal allow using devices that cannot be made aware of the addressing protocol at all (such as GPSs).

  The router at the moment only executes two commands, as follows:

  R:nReboot, N can be any number.

  L:xSets logging level to terminal to 0, 1 or 2.

  D:xx>yySets default destination for port xx to port yy. OK to use stealthing with yy (it will do nothing if used with xx). Thus the terminal can decide what talks to what in realtime.

  There is ample room to make the microcontroller do other things if desired :) Interfacing given our components is done thru resistors since signal inversion can be defined in software. Baud rates are NOT limited to standard bauds (so a baudrate of say 24000 is fine).

  This was done for the PhoneSat group at NASA-AMES if anyone cares, so it will into space in a few months :)

  UPDATE: Uses improved serial objects from http://forums.parallax.com/showthread.php?129714-Tim-Moore-s-pcFullDuple...(512-byte)-rx-buffer

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
