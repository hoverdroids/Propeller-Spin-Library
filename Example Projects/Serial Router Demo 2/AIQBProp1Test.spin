{Object_Title_and_Purpose}


CON
        _clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 6_000_000
         pin=21

         one=     %00010100
         two=     %10110011
         three=   %10110110
         four=    %11010100
         five=    %11100110
         six=     %11100111
         seven=   %00110100
         eight=   %11110111
         nine=    %11110100
         zero=    %01110111

         ten=     %00101000  
         twenty=  %11001101
         thirty=  %01101101
         fourty=  %00101011
         fifty=   %01100111
         sixty=   %11100111
         seventy= %00101100
         eighty=  %11101111
         ninety=  %00101111
         hundred= %11101110
var
long number[10]
long number2[10]
byte count

PUB public_method_name
dira[0..7]:=  %11111111
dira[16..23]:=%11110111

number[0]:=hundred
number[1]:=ten
number[2]:=twenty
number[3]:=thirty
number[4]:=fourty
number[5]:=fifty
number[6]:=sixty
number[7]:=seventy
number[8]:=eighty
number[9]:=ninety

number2[0]:=zero
number2[1]:=one
number2[2]:=two
number2[3]:=three
number2[4]:=four
number2[5]:=five
number2[6]:=six
number2[7]:=seven
number2[8]:=eight
number2[9]:=nine
  
repeat
  outa[0..7]:=byte[@numberTest][count]
  outa[16..23]:=number2[count]
  count++
  if count==10
    count:=0
  waitcnt(clkfreq+cnt)

DAT

numberTest byte %00101000, %11001101, %01101101, %00101011, %01100111, %11100111, %00101100, %11101111, %00101111, %11101110
  