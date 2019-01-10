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
pub IsDigit(char)
    return (char > constant("0"-1) and char < constant("9"+1))  
pub startswith(StringAddr1,StringAddr2) | t1,t2  ' allow comparing if String1 is bigger than String2: useful for parametered commands

    t1 := strsize(StringAddr1)
    t2 := strsize(StringAddr2)
    if t1==t2
       return strcomp(StringAddr1,StringAddr2)
    if t1>t2
       result:=byte[StringAddr1+t2]~
       t1:=strcomp(StringAddr1,StringAddr2)
       byte[StringAddr1+t2]:=result
       return t1

pub upcase(ByteVal)
'' go to uppercase, 1 character -- that's all it does (used in parsing)
    if (ByteVal > constant("a"-1) and ByteVal < constant("z"+1))
         return (ByteVal-$20)
    return ByteVal
    
pub StupidNumberParser(StringAddr) ' only for 00000 to 99999 but for what we're doing here, it's enough
    result~~
    if IsDigit(byte[StringAddr+0])
      result:=byte[StringAddr+0] - "0"
     if IsDigit(byte[StringAddr+1])
       result:=result*10 + byte[StringAddr+1] - "0"
      if IsDigit(byte[StringAddr+2])
        result:=result*10 + byte[StringAddr+2] - "0"
       if IsDigit(byte[StringAddr+3])
         result:=result*10 + byte[StringAddr+3] - "0"
        if IsDigit(byte[StringAddr+4])
          result:=result*10 + byte[StringAddr+4] - "0"
    'com.dec(0,result)
