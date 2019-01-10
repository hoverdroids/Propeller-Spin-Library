{{
OBEX LISTING:
  http://obex.parallax.com/object/419

  Full featured autopilot for boats, planes and rovers. Tested over 3 years. You can see the videos under Spiritplumber on youtube. This version does not contain the graphical console, but text i/o is possible and fairly easy to do.

  Other versions are maintained here http://robots-everywhere.com/portfolio/navcom_ai/ and may be downloaded there. If you intend to use this commercially, please see licensing information on that page.

  A note: It is possible to build functional drone bombers or similar with this. You the downloader are explicitly denied permission to do so. If you want to build autonomous weapons do your own homework, or better yet, go get your head examined.

  Videos of the drones in action!

  http://www.youtube.com/watch?v=5wJHj3hOcuI
  http://www.youtube.com/watch?v=diAZD68Y3Cw
  http://www.youtube.com/watch?v=AIbPvxf3hrk
  http://www.youtube.com/watch?v=en5TCSHZDyY
  http://www.youtube.com/watch?v=Dd1R-WeGWkU
  http://www.youtube.com/watch?v=9m6H5se6-nE
}}
''************************************
''* Int or Float  <->  Strings v 1.2 *
''* Single-precision IEEE-754        *
''* (C) 2006 Parallax, Inc.          *
''* Modified by Matteo K Borri       *
''* added str->float and str->int    *
''************************************

'' v1.0 - 01 May 2006 - original version
'' v1.1 - 12 Jul 2006 - added FloatToFormat routine
'' v1.2 - 02 Nov 2006 - trimmed the fat & added integer support


VAR

'  long  p, notdone, v2, ww, value, point, i, width
'  long  positive_chr, negative_chr, positive_chr 
  byte  float_string[20]
  byte  localflag ' used to mark negative zeros from positive zeros when parsing floating point numbers of magnitude less than 1

OBJ
  ' The F object can be FloatMath, Float32 or Float32Full depending on the application
  m : "DynamicMathLib (2)"
  
pub init
    bytefill (@float_string[0], 0, 20)
    m.forceslow
pub fast
    m.allowfast

pub last
    float_string[19]~
    return @float_string
pub stop
    init
        
PUB FloatToFormatPN(single, fwidth, dp, pc, nc) : stringptr | w2, i, p', float_string, float_string1, float_string2, float_string3, float_string4, float_string5

''Convert floating-point number to formatted string
''
''  entry:
''      Single = floating-point number
''      width = width of field
''      dp = number of decimal points
''
''  exit:
''      StringPtr = pointer to resultant z-string
''
''  asterisks are displayed for format errors 
''  leading blank fill is used

  ' get string pointer
  stringptr := p := @float_string

  ' width must be 1 to 9, dp must be 0 to width-1
  w2 := fwidth  :=  fwidth #> 1 <# 18
  dp := dp #> 0 <# (fwidth - 2)
  if dp > 0
    w2--
  if single & $8000_0000 or pc
    w2--

  ' get positive scaled integer value
  i := m.FRound(m.FMul(single & $7FFF_FFFF , tenf[dp])) ' m.FFloat(teni[dp])))

  if i => teni[w2]
    ' if format error, display asterisks
    repeat while fwidth
      if --fwidth == dp
          byte[p++] := "."
      else
        byte[p++] := "*" 
    byte[p]~

  else
    ' store formatted number
    p += fwidth
    byte[p]~

    repeat fwidth
      byte[--p] := i // 10 + "0"
      i /= 10
      if --dp == 0
          byte[--p] := "."
      if i == 0 and dp < 0
        quit

    ' store sign      
    if single & $80000000
      byte[--p] := nc
    elseif pc
      byte[--p] := pc
    ' leading blank fill
    repeat while p <> stringptr
      byte[--p] := " "
      
PUB FloatToFormat(single, fwidth, dp)
    return FloatToFormatPN(single,fwidth,dp," ","-")

PUB IntToFormatPN(vv, wt, pt, pc, nc) : stringptr | p, notdone, v2, w2, value, point, i, width 

  stringptr := p := @float_string
  point := teni[pt-1]
  w2 := wt
  width := teni[w2]
  if point
     width := teni[--w2]

  notdone~' := 0
  value := vv

  if value < 0
    -value
    byte[p++]:=(nc)
    width := teni[--w2]
  elseif pc 
    byte[p++]:=(pc)
    width := teni[--w2]
  
  v2 := value

  if width and value > width
      if vv < 0 or pc
         p--
      repeat wt
         byte[p++]:=("*")
  else

   i := 1_000_000_000

   repeat 10
    
    if point == i
      byte[p++]:=(".")

    if value => i
      byte[p++]:=(value / i + "0")
      value //= i
      notdone~~

    elseif notdone or (i == 1) or point => i
      byte[p++]:=("0")

'    elseif width > v2
'      byte[p++]:=(" ")


    i /= 10

  if wt > p
     repeat
        byte[p++] := " "
     until width == p

  byte[p]~' := 0
  stringptr := p := @float_string


PUB IntToFormat(vv, wt, pt)
    return IntToFormatPN(vv,wt,pt,0,"-")
    
PUB fpa(val,decpoint)
    return IntToFormatPN(val, 0, decpoint," ","-")

PUB dec(value)
  return IntToFormatPN(value, 0, 0," ","-")

pub indecdegrees(value)
'  return fpa(((value*10)+3)/6,6)
  return IntToFormatPN(((value*10)+3)/6, 0, 6,false,"-")

pub ParseNextCoord (inaddr, outaddr, negletter) : endaddr | degs, intmins, fracmins
' parses NMEA gps coordinates
  endaddr := inaddr
  endaddr += ParseNextInt(endaddr,@degs)
  intmins := (degs // 100) * 10000' minutes
  degs := (degs / 100) * constant(60*100*100)' degrees
  byte[--endaddr] := "0"                               ' ugly, but effective fix for GPS models that use a nonstandard number of digits 
  byte[--endaddr] := "@"                               ' ugly, but effective fix for GPS models that use a nonstandard number of digits 
  endaddr += ParseNextFloat(endaddr, @fracmins)
  fracmins := m.fround(m.fmul(10000.0,fracmins))
  
  if (byte[++endaddr] == negletter)
      long[outaddr] := 0 - degs - intmins - fracmins
  else
      long[outaddr] := degs + intmins + fracmins

  endaddr -= inaddr
  
pub ParseNextInt(StringAddress, ReturnValueAddress) | curs1, curs2, pointy, temp, sign


     temp~   ':= 0
     curs1~  ':= 0
     curs2~  ':= 0
     pointy~ ':= 0
     sign := 1
     'localflag~

     repeat
        'pointy := pointy + 1
        if (byte[StringAddress + ++pointy] == $00)
               return -1
        if (byte[StringAddress + pointy] == ".")
               long[ReturnValueAddress]~
               return 0
                      
     until (IsAsciiDigit(byte[StringAddress+pointy]) == true)' or byte[StringAddress+pointy] == "-")
     curs1 := pointy
     repeat
        ++pointy' := pointy + 1
     until (IsAsciiDigit(byte[StringAddress+pointy]) == false)
     curs2 := pointy 

     pointy := curs1
     repeat (curs2 - curs1)
       ' if (byte[StringAddress+pointy] == "-")
       '    sign := -1
       ' else
        if (temp < constant((posx/10)+1))
           temp := temp * 10 + (byte[StringAddress+pointy] - $30)
        else
           temp := posx 
        byte[StringAddress + pointy++] := "#"
'        pointy := pointy + 1

     if (byte [StringAddress + --curs1] == "-")
         byte [StringAddress + curs1  ] := "#"
         sign := -1
         if temp == 0
             localflag~~' := 1 
'     if (byte [StringAddress + --curs1] == "+")
'         byte [StringAddress + curs1  ] := "#"
'         sign := +1


     
     long[ReturnValueAddress] := (temp*sign)

     
     return pointy


pub ParseNextFloat(StringAddress, ReturnValueAddress) | beforedecimal, afterdecimal, dp1, dp2


     dp2 := dp1 := ParseNextInt(StringAddress, @beforedecimal)  ' tells me after how many digits i got the dec point
     beforedecimal := m.ffloat(beforedecimal)

     if (byte[StringAddress + dp1] == ".")
          byte[StringAddress + dp1] := "#"
          dp2 := ParseNextInt(StringAddress, @afterdecimal)  ' tells me after how many digits i got the end of the number
          afterdecimal := m.ffloat(afterdecimal)
     ' now dp2 - dp1 contain the number of digits after the dec point if any
          if (afterdecimal and (dp2 > ++dp1))
              afterdecimal := m.fmul(afterdecimal,tenfdiv[dp2 - dp1])'m.fdiv(afterdecimal, tenf[dp2 - dp1])
              beforedecimal := m.fadd(beforedecimal, afterdecimal)
     if localflag
           beforedecimal ^= $8000_0000' := m.fneg(beforedecimal)
           localflag~
           
     long[ReturnValueAddress] := beforedecimal
     
     return dp2          

{
con
food = POSX/10+1
pub ParseDegsIntoMins(StringAddress, ReturnValueAddress) | beforedecimal, afterdecimal, dp1, dp2, factor


     dp2 := dp1 := ParseNextInt(StringAddress, @beforedecimal)  ' tells me after how many digits i got the dec point
     beforedecimal *= (60 * 10_000)':= m.ffloat(beforedecimal)

     if (byte[StringAddress + dp1] == ".")
          byte[StringAddress + dp1] := "#"
          dp2 := ParseNextInt(StringAddress, @afterdecimal)  ' tells me after how many digits i got the end of the number
          'afterdecimal := m.ffloat(afterdecimal)
     ' now dp2 - dp1 contain the number of digits after the dec point if any
          if (afterdecimal and (dp2 > ++dp1))
              case (dp2-dp1)  'if (dp2 - dp1) < 4
               1: factor := constant(60 * 1000)
               2: factor := constant(60 * 100)
               3: factor := constant(60 * 10)
               4: factor := constant(60 * 1)
               5: factor := constant(6 * 1)

'               6: factor := constant(60 * 100)
 '              7: factor := constant(60 * 100)
  '             8: factor := constant(60 * 100)
   '            9: factor := constant(60 * 100)
               
              'afterdecimal := afterdecimal * (60 * 10_000) / (dp2-dp1)'m.fmul(afterdecimal,tenfdiv[dp2 - dp1])'m.fdiv(afterdecimal, tenf[dp2 - dp1])

              beforedecimal := afterdecimal + beforedecimal
     if localflag
           beforedecimal *= -1'
           localflag~
           
     long[ReturnValueAddress] := beforedecimal
     
     return dp2          
}
pub IsAsciiDigit(ByteVal)

   if (ByteVal > $2F and ByteVal < $3A)
       return true
   return false

pub upcase(ByteVal)
'' go to uppercase, 1 character -- that's all it does (used in parsing)

    if (ByteVal > constant("a"-1) and ByteVal < constant("z"+1))
         return (ByteVal-$20)

    return ByteVal
    
pub Contains(StringAddr, Check) : c ' checks if a string contains a character

 c~

 repeat strsize(StringAddr)
    if byte[StringAddr + c++] == ($FF & Check)
       return --c

 return -1

pub EncodeLong(LongVal) : stringptr | checksum 'EncodeNum(LongVal, floatiness) : stringptr | checksum

    ' Used to transfer a long or a float thru a serial link using only >ascii127 characters so as to not get mixed up with control or printable chars. 

'3 bit checksum, doesn't use floatiness

    checksum := ((((LongVal.byte[0] + LongVal.byte[1] + LongVal.byte[2] + LongVal.byte[3]) // 8) + 8) << 4)

'    checksum //= 8 ' 3-bit checksum since we wouldn't use it for anything
'    checksum += 8  ' add always-on bit to allow good xmit
'    checksum <<= 4 ' shift four so that it takes the upper 4 bits


                                
    float_string[0] := %10000000 | LongVal.byte[0] 
    float_string[1] := %10000000 | LongVal.byte[1] 
    float_string[2] := %10000000 | LongVal.byte[2] 
    float_string[3] := %10000000 | LongVal.byte[3] 

                               {
    float_string[4] := checksum                       ' upper 4 bits: checksum
    float_string[4] |=    (LongVal.byte[0] >> 7)      ' lower 4 bits: missing bits from long bytes
    float_string[4] |= 2 * (LongVal.byte[1] >> 7)     ' lower 4 bits: missing bits from long bytes
    float_string[4] |= 4 * (LongVal.byte[2] >> 7)     ' lower 4 bits: missing bits from long bytes
    float_string[4] |= 8 * (LongVal.byte[3] >> 7)     ' lower 4 bits: missing bits from long bytes
                                }

    float_string[4] := checksum + ( (LongVal.byte[0] >> 7) + 2*(LongVal.byte[1] >> 7) + 4*(LongVal.byte[2] >> 7) + 8*(LongVal.byte[3] >> 7))
    
    float_string[5]~

    stringptr := @float_string
{
pub EncodeLong(LongVal)
    return EncodeNum(LongVal,0)
pub EncodeFloat(FloatVal)
    return EncodeNum(FloatVal,1)

pub EncodeNum(LongVal, floatiness) : stringptr | checksum

    ' Used to transfer a long or a float thru a serial link using only >ascii127 characters so as to not get mixed up with control or printable chars. 


' 2 bit checksum, uses floatiness: we specify whether the datum is a float or an int

    if (floatiness)
        checksum := %10010000
    else
        checksum~

        
    checksum |= ((((LongVal.byte[0] + LongVal.byte[1] + LongVal.byte[2] + LongVal.byte[3]) // 4) + 4) << 5)

    'checksum //= 4 ' 2-bit checksum since we wouldn't use it for anything
    'checksum += 4  ' add always-on bit to allow good xmit
    'checksum <<= 5 ' shift five so that it takes the upper 3 bits
                                
    float_string[0] := %10000000 | LongVal.byte[0] 
    float_string[1] := %10000000 | LongVal.byte[1] 
    float_string[2] := %10000000 | LongVal.byte[2] 
    float_string[3] := %10000000 | LongVal.byte[3] 

                               {
    float_string[4] := checksum                       ' upper 4 bits: checksum
    float_string[4] |=    (LongVal.byte[0] >> 7)      ' lower 4 bits: missing bits from long bytes
    float_string[4] |= 2 * (LongVal.byte[1] >> 7)     ' lower 4 bits: missing bits from long bytes
    float_string[4] |= 4 * (LongVal.byte[2] >> 7)     ' lower 4 bits: missing bits from long bytes
    float_string[4] |= 8 * (LongVal.byte[3] >> 7)     ' lower 4 bits: missing bits from long bytes
                                }

    float_string[4] := checksum + ( (LongVal.byte[0] >> 7) + 2*(LongVal.byte[1] >> 7) + 4*(LongVal.byte[2] >> 7) + 8*(LongVal.byte[3] >> 7))
    
    float_string[5]~

    stringptr := @float_string
}
pub NMEAChecksum(stringaddr) : checksum
   checksum~
   stringaddr--
   repeat until byte[stringaddr++] == "$"  ' get to the dollar sign, first off
   repeat
     checksum ^= byte[stringaddr]
   until byte[++stringaddr] == "*"



DAT
padding long  0, 0
teni    long  1,   10,   100,   1_000,   10_000,   100_000,   1_000_000,   10_000_000,   100_000_000,   1_000_000_000,   2147483647,  2147483647
tenf    long  1.0, 10.0, 100.0, 1_000.0, 10_000.0, 100_000.0, 1_000_000.0, 10_000_000.0, 100_000_000.0, 1_000_000_000.0, 10_000_000_000.0, 100_000_000_000.0, 1_000_000_000_000.0
paddd2  long  0
tenfdiv long  1.0, 00.1, 00.01, 00.00_1, 00.00_01, 00.00_001, 00.00_000_1, 00.00_000_01, 00.00_000_001, 00.00_000_000_1, 00.00_000_000_01, 00.00_000_000_001, 00.00_000_000_000_1 
