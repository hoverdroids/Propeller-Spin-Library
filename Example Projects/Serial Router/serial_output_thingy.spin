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