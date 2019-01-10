{{DS00 Laser Range Finder Comms
This object connects the Propeller to the DS00 using one serial line (no UI) and the prop then connects to the
Parallax serial terminal using another serial line.  All the prop is doing is acting as the middle man
by taking DS00 data from its TX line and feeding it to the PST screen, and allowing a user to command the
DS00 using the PST UI.



}}


CON
        _clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 5_000_000
       

        'PST data
        PST_RX_PIN=31
        PST_TX_PIN=30
        PST_Baud=57600

VAR
  Byte myByte
  Byte MyByteArray[ 11 ]

OBJ

  Debug              :"FullDuplexSerialPlus"
   
PUB Main
'-------[Initialization]------------
dira[PST_RX_PIN]:=0
dira[PST_TX_PIN]:=1

Debug.start(PST_RX_PIN,PST_TX_PIN,0,PST_Baud)

'----[Main code]--------------
waitcnt(clkfreq*2+cnt)
Debug.tx(16)
Debug.Str(String(13,"Initialization Complete"))
  
myByte:=0

repeat
  Debug.Str(String(13,"Decimal Test value:  "))
  myByte:=Debug.getDec
  Debug.Str(String(13))
  Debug.Dec(myByte)
  repeat 2
    Debug.Str(string(13))
  Debug.Str(String(13,"String Test value:  "))
  myByte:=Debug.getStr(MyByteArray)
  Debug.Str(String(13))
  Debug.Str(myByte)
  
  



