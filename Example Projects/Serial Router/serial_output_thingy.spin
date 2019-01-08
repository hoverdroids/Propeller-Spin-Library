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

obj com:"Simple_Serial v1.3"




var
long serialstack[30]
long cog
long derp
long baud
dat
string1 byte "This is device ",0
string2 byte ", packet ",0
string3 byte ", payload ",0
string4 byte 13,10,0
pub start(herp, bd)
stop
if (herp == 0)
   return false

derp := herp
baud := bd
result~
repeat
  cog := result := cognew(serialdebugloop, @serialstack) + 1
until result


pub stop
if cog
   cogstop(cog~ -1)




pri serialdebugloop | device, packet


packet~
repeat
  device~
  packet++
  repeat 15
   if (derp > device)
     com.init(device*2,device*2+1,baud)
     com.str(@string1)
     dec(device)
     com.str(@string2)
     dec(packet)
     com.str(@string3)
     dec(?result//100)
     com.str(@string4)
   device++
   
   {
  if (derp > 0)
   com.init(0,1,baud)
   byte[@id] := "0"
   com.str(@stringtosend)

  if (derp > 1)
   com.init(2,3,baud)
   byte[@id] := "1"
   com.str(@stringtosend)

  if (derp > 2)
   com.init(4,5,baud)
   byte[@id] := "2"
   com.str(@stringtosend)

  if (derp > 3)
   com.init(6,7,baud)
   byte[@id] := "3"
   com.str(@stringtosend)

  if (derp > 4)
   com.init(8,9,baud)
   byte[@id] := "4"
   com.str(@stringtosend)
   }


PUB dec(value) | i

'' Print a decimal number

  if value < 0
    -value
    com.tx("-")

  i := 1_000_000_000

  repeat 10
    if value => i
      com.tx(value / i + "0")
      value //= i
      result~~
    elseif result or i == 1
      com.tx("0")
    i /= 10
