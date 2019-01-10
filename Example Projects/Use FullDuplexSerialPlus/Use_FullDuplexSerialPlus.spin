{{DS00 Laser Range Finder Comms
This object connects the Propeller to the DS00 using one serial line (no UI) and the prop then connects to the
Parallax serial terminal using another serial line.  All the prop is doing is acting as the middle man
by taking DS00 data from its TX line and feeding it to the PST screen, and allowing a user to command the
DS00 using the PST UI.



}}


CON
        _clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 6_000_000
       

        'PST data
        PST_RX_PIN=31
        PST_TX_PIN=30
        PST_Baud=57600

VAR
  Byte myByte          'this can store a single byte
  Byte MyByteArray[10] 'this can store 10 bytes (i.e. a string of 10 characters)
  Byte myMsgArray[5]   'this is to store the first four characters
  byte i              'counter

OBJ

  Debug              :"FullDuplexSerialPlus"
   
PUB Main
'-------[Initialization]------------
dira[PST_RX_PIN]:=0
dira[PST_TX_PIN]:=1
dira[20]:=1 'this will be used to blink an LED

Debug.start(PST_RX_PIN,PST_TX_PIN,0,PST_Baud)

'----[Main code]--------------
waitcnt(clkfreq*8+cnt)
Debug.tx(16)
Debug.Str(String(13,"Initialization Complete"))
  
myByte:=0

repeat
  'Debug.Str(String(13,"Decimal Test value:  "))
  'myByte:=Debug.getDec          'this waits until a number character is entered in terminal then an enter is sent; it then converts the ascii character to number
  'Debug.Str(String(13))
  'Debug.Dec(myByte)
  'repeat 2
    'Debug.Str(string(13))
  Debug.Str(String(13,"String Test value:  "))
  myByte:=Debug.getStr(@MyByteArray)  'this will wait for a string and then CR are entered; it then stores each character of the string into a byte, starting at the given address
  Debug.Str(String(" "))
  Debug.tx(myByteArray[0])'this should display only the first character(byte) in the array
  Debug.str(string(" "))
  Debug.Str(@myByteArray)
  Debug.str(string(" "))
  'Debug.tx(myByteArray[4])
  'fix the display issue
  debug.str(string(" string size")) 'note that the number zero does not terminate a string; only the null value of 0 does
  debug.dec(strsize(@myByteArray))
  '--note--
  'when calling an element array that is still blank will does not send correctly to the terminal; once the input has first reached the correct length, all will print after that
  'Debug.str(string(" "))
  'Debug.tx(myByteArray[10])
  '---Note---
  'going past the last element in the string byte array causes a freek out (stack overflow?)
  'Debug.str(string(" "))
  '---NOTE---
  'debug.str(string("if you do not clear the values in the arrary, they will remain as they were!"))
  'debug.str(string(" "))
  'myByteArray:=0
  'debug.str(string("after clearing, my byte array is: "))
  ''debug.str(@myByteArray)

  'get the end number of a stringwith character beginings
  debug.str(string(13, "Your Code number?", 13))
  debug.getstr(@myByteArray)
  debug.str(string("your number was: "))
  debug.str(@myByteArray[4])
  i:=0
  repeat 4
    myMsgArray[i]:=myByteArray[i]
    i++
  myMsgArray[4]:=0
  debug.str(string(13,"your msg was: "))
  debug.str(@myMsgArray)
  if strcomp(@myMsgArray,@Str1)
    outa[20]:=1
    waitcnt(clkfreq+cnt)
    !outa[20]
  'outa[20]:=1
  'waitcnt(clkfreq+cnt)
  '!outa[20]
  debug.str(13)
  i:=0
  repeat 4
    myMsgArray[i]:=0
    i++
    
  'if strcomp(MyByteArray[0],string("A"))
    'Debug.Str(string(13,"Yah for A"))
    'Debug.str(13)
    'repeat 10
      '!outa[20]
      'waitcnt(clkfreq/10+cnt)
DAT
Str1 byte "cmmd",0
  
  
