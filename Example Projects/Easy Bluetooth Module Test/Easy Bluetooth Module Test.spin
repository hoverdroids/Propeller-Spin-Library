{{---------------[title]---------------------
Read analog and convert to digital using ADC}}


CON
        _clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 5_000_000

        RX_PIN=14
        TX_PIN=15
        Baud=9600

        MSBPOST=BS2_Functions#MSBPOST
        CLS=16 'This won't let me reference the constant in FDSP

VAR
  Byte myByte

OBJ
  BS2_Functions      : "BS2_Functions"
  Debug              : "FullDuplexSerialPlus"
   
PUB Main
'-------[Initialization]------------
'the EBT module is waiting for a byte to establish a connection; press any ky
'in the top window pane of the debug to do this
dira[RX_PIN]:=0
dira[TX_PIN]:=1

Debug.start(TX_PIN,RX_PIN,0,Baud)
waitcnt(clkfreq*2+cnt)
Debug.tx(16)

waitcnt(clkfreq*3+cnt)

repeat until myByte<>=0
  myByte:=Debug.getDec
Debug.Str(String("You made it!"))
  
myByte:=0

repeat
  Debug.Str(String("Enter a decimal value:  "))
  myByte:=Debug.getDec
  Debug.Str(String(13, "You Entered", 13,"---------"))
  Debug.Str(String(13, "Decimal:  "))
  Debug.Dec(myByte)
  Debug.Str(String(13,"Hexadecimal:  "))
  Debug.Hex(myByte,8)
  Debug.Str(string(13, "Binary:  "))
  Debug.Bin(myByte,32)
  repeat 2
    Debug.Str(string(13))


